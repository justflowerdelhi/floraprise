/**
 * POSScreen.tsx — Tab-Based POS Workflow
 */

import React, { useState, useEffect, useCallback } from "react";
import { Alert, Box, Typography, Button } from "@mui/material";
import { useNavigate } from "react-router-dom";

import { usePOS } from "./POSContext";
import { useAuth } from "../../auth/AuthContext";

import type { Product } from "../orders/OrderTypes";
import type { POSCustomer } from "./POSCustomerTypes";

import { searchProducts, normalizeProducts } from "../../api/product.api";
import { searchCustomers } from "../../api/customer.api";

import { fetchSellableFinishedGoods } from "../../api/order.api";
import { setPOSCatalogCache } from "./utils/posCatalogCache";

import { getActiveShift } from "../../api/shift.api";
import OpenShiftModal from "../../components/pos/OpenShiftModal";

import POSTabLayout, { type POSTab } from "./POSTabLayout";
import OrderTypeTab from "./OrderTypeTab";
import ProductsTab from "./ProductsTab";
import DetailsTab from "./DetailsTab";
import PaymentTab from "./PaymentTab";

const MOCK_CUSTOMERS: POSCustomer[] = [
  {
    id: "cust_001",
    tenantId: "tenant_001",
    name: "Meera Joshi",
    phone: "9876543210",
    email: "meera@example.com",
    preferredAddress: "123 Main St",
    createdAt: new Date().toISOString(),
    tags: ["NEW_CUSTOMER"],
    lifetimeValue: 10000,
    totalOrders: 2,
    averageOrderValue: 5000,
    referralCount: 0,
    loyaltyPoints: 100,
    loyaltyTier: "SILVER",
    loyaltyPointsEarned: 100,
    loyaltyPointsRedeemed: 0,
    totalProfit: 2000,
    profitMargin: 20,
    marketingConsent: true,
    lastOrderDate: new Date().toISOString(),
    notes: "First order",
  },
];

const POSScreen: React.FC = () => {
  const { state, setOrderIntent, cancelPayment, intentErrors } = usePOS();
  const { user } = useAuth();
  const navigate = useNavigate();

  // Platform admins have no company — POS requires company context
  const isPlatformAdmin = (user as any)?.role === 'PLATFORMSUPERADMIN';
  if (isPlatformAdmin) {
    return (
      <Box sx={{ p: 6, textAlign: 'center' }}>
        <Typography variant="h5" fontWeight={700} gutterBottom>
          POS Not Available
        </Typography>
        <Typography color="text.secondary" sx={{ mb: 3 }}>
          The Point of Sale requires a company context. Platform administrators
          do not have a company assigned.
        </Typography>
        <Button variant="contained" onClick={() => navigate('/admin/dashboard')}>
          Go to Admin Dashboard
        </Button>
      </Box>
    );
  }

  const [activeTab, setActiveTab] = useState<POSTab>(0);

  const [products, setProducts] = useState<Product[]>([]);
  const [customers, setCustomers] = useState<POSCustomer[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState("");

  const [activeShift, setActiveShift] = useState<any>(null);
  const [showShiftModal, setShowShiftModal] = useState(false);

  console.log("POS User:", user);
  console.log("Order intent:", state.orderIntent);

  // ─── Load Catalog ─────────────────────────────────────

  const loadData = useCallback(async () => {
    setIsLoading(true);

    try {
      const [productResult, finishedGoodsResult] = await Promise.all([
        searchProducts({ PageSize: 200, IsActive: true }).catch(() => []),
        fetchSellableFinishedGoods().catch(() => []),
      ]);

      const rawProducts = Array.isArray(productResult) ? productResult : productResult?.items ?? [];
      const rawFinishedGoods = Array.isArray(finishedGoodsResult)
        ? finishedGoodsResult
        : finishedGoodsResult?.items ?? finishedGoodsResult?.data ?? [];

      const normalizedProducts = normalizeProducts(rawProducts);

      const finishedGoodsProducts = rawFinishedGoods
        .map((fg: any) => {
        const finishedGoodsId = String(fg.id ?? fg.Id ?? '').trim();
        if (!finishedGoodsId) return null;

        return ({
        id: finishedGoodsId,
        name: fg.name || fg.recipeName || "Ready Bouquet",
        sku: fg.sku || fg.batchCode || fg.id,
        barcode: fg.barcode || fg.Barcode,
        finishedBarcode: fg.barcode || fg.Barcode,
        category: "Bouquets",
        sellingPrice: Number(fg.retailPrice ?? fg.RetailPrice) || Number(fg.sellingPrice) || 0,
        costPrice: Number(fg.costPrice ?? fg.CostPrice) || 0,
        taxRate: 0,
        availableStock: Number(fg.stockQuantity ?? fg.StockQuantity) || Number(fg.quantityAvailable) || 0,
        isPerishable: true,
        trackBatch: false,
        imageUrl: "",
        batches: [],
      } as Product);
      })
      .filter((fg: Product | null): fg is Product => fg !== null);

      const mergedProducts = [
        ...finishedGoodsProducts,
        ...normalizedProducts,
      ];

      setPOSCatalogCache(mergedProducts);
      setProducts(mergedProducts);
    } catch (err) {
      console.warn("Catalog load failed:", err);
    }

    try {
      const custResult = await searchCustomers({ PageSize: 200 });

      const rawCustomers =
        custResult?.items ??
        (Array.isArray(custResult) ? custResult : []);

      if (rawCustomers.length > 0) {
        setCustomers(rawCustomers);
      } else {
        setCustomers(MOCK_CUSTOMERS);
      }
    } catch {
      setCustomers(MOCK_CUSTOMERS);
    }

    setIsLoading(false);
  }, []);

  useEffect(() => {
    loadData();
  }, [loadData]);

  // ─── Auto Navigate Details ───────────────────────────

  useEffect(() => {
    if (
      (state.orderIntent === "DELIVERY" ||
       state.orderIntent === "PICKUP_LATER") &&
      state.items.length > 0
    ) {
      setActiveTab(2);
    }

    if (state.orderIntent === "TAKE_NOW") {
      setActiveTab(3);
    }
  }, [state.orderIntent, state.items.length]);

  // ─── Tab Logic ───────────────────────────────────────

  const hasIntent = !!state.orderIntent;
  const hasItems = state.items.length > 0;
  const detailsValid = intentErrors.length === 0;

  const requiresDetails =
    state.orderIntent === "DELIVERY" ||
    state.orderIntent === "PICKUP_LATER";

  const tabEnabled: Record<POSTab, boolean> = {
    0: true,
    1: true,
    2: hasItems,
    3: hasItems && (!requiresDetails || detailsValid),
  };

  const tabCompleted: Record<POSTab, boolean> = {
    0: hasIntent,
    1: hasItems,
    2: detailsValid && hasItems,
    3: state.lifecycle === "completed",
  };

  const goTo = useCallback(
    (tab: POSTab) => {
      if (activeTab === 3 && tab !== 3 && state.lifecycle === "payment") {
        cancelPayment();
      }
      if (tabEnabled[tab]) setActiveTab(tab);
    },
    [activeTab, state.lifecycle, cancelPayment, tabEnabled]
  );

  // ─── Shift Check ─────────────────────────────────────

  useEffect(() => {
    const checkShift = async () => {
      try {
const shift = await getActiveShift(user?.primaryLocationId ?? '');
if (shift) setActiveShift(shift);
else setShowShiftModal(true);
      } catch {
        setShowShiftModal(true);
      }
    };

    checkShift();
  }, []);

  // ─── Render ──────────────────────────────────────────

  return (
    <div className="h-full flex flex-col overflow-hidden bg-gray-50">

      {error && (
        <Alert severity="warning">{error}</Alert>
      )}

      {showShiftModal && (
        <Box
          sx={{
            position: "fixed",
            inset: 0,
            backgroundColor: "rgba(0,0,0,0.6)",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            zIndex: 9999,
          }}
        >
          <OpenShiftModal
            onOpened={(shift: any) => {
              setActiveShift(shift);
              setShowShiftModal(false);
            }}
          />
        </Box>
      )}

      <POSTabLayout
        activeTab={activeTab}
        onTabChange={goTo}
        tabEnabled={tabEnabled}
        tabCompleted={tabCompleted}
      >
        {activeTab === 0 && (
          <OrderTypeTab
            selected={state.orderIntent}
            onSelect={(intent) => {
              setOrderIntent(intent);
              if (intent === "DELIVERY" || intent === "PICKUP_LATER") {
                setActiveTab(2);
              }
              if (intent === "TAKE_NOW") {
                setActiveTab(3);
              }
            }}
            onNext={() => goTo(1)}
          />
        )}

        {activeTab === 1 && (
          <ProductsTab
            products={products}
            customers={customers}
            isLoading={isLoading}
            onNext={() => goTo(2)}
          />
        )}

        {activeTab === 2 && (
          <DetailsTab
            onNext={() => goTo(3)}
            onBack={() => goTo(1)}
          />
        )}

        {activeTab === 3 && (
          <PaymentTab
            onBack={() => goTo(2)}
          />
        )}
      </POSTabLayout>

      {process.env.NODE_ENV === "development" && (
        <div className="fixed bottom-4 left-4 px-3 py-1 bg-gray-800 text-white text-xs rounded-full">
          Tab {activeTab + 1} | Intent {state.orderIntent}
        </div>
      )}

    </div>
  );
};

export default POSScreen;