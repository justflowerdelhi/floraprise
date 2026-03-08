import React, { useState, useCallback, useEffect, useRef } from "react";
import { Snackbar, Alert } from "@mui/material";
import { POS_CATEGORIES } from "./POSTypes";
import ProductGrid from "./ProductGrid";
import POSCartPanelV2 from "./POSCartPanelV2";
import POSCustomerDrawer from "./POSCustomerDrawer";
import OrderIntentDropdown from "./OrderIntentDropdown";
import { usePOS } from "./POSContext";
import type { Product } from "../orders/OrderTypes";
import type { POSCustomer } from "./POSCustomerTypes";
import { startBarcodeScanner } from "./utils/barcodeScanner";
import { getPOSCatalogCache } from "./utils/posCatalogCache";

interface ProductsTabProps {
  products: Product[];
  customers: POSCustomer[];
  isLoading: boolean;
  onNext: () => void;
}

type SnackbarState = {
  open: boolean;
  message: string;
  severity: "success" | "error" | "info";
};

const ProductsTab: React.FC<ProductsTabProps> = ({
  products,
  customers,
  isLoading,
  onNext
}) => {
  const {
    state,
    addProduct,
    updateQty,
    setCustomer,
    setOrderIntent
  } = usePOS();

  const searchRef = useRef<HTMLInputElement>(null);

  const [searchQuery, setSearchQuery] = useState("");
  const [selectedCategory, setSelectedCategory] = useState("all");
  const [customerDrawerOpen, setCustomerDrawerOpen] = useState(false);

  const [snackbar, setSnackbar] = useState<SnackbarState>({
    open: false,
    message: "",
    severity: "success"
  });

  const [quickQtyProduct, setQuickQtyProduct] = useState<Product | null>(null);
  const [quickQtyValue, setQuickQtyValue] = useState("");
  const quickQtyInputRef = useRef<HTMLInputElement>(null);

  const lastAddedRef = useRef<{ productId: string; time: number } | null>(null);

  // Barcode Scanner
  useEffect(() => {
    const stopScanner = startBarcodeScanner((barcode) => {
      const catalog = getPOSCatalogCache();
      const product = catalog.find(
        (p) =>
          p.barcode === barcode ||
          p.internalBarcode === barcode ||
          p.batchBarcode === barcode ||
          p.finishedBarcode === barcode
      );

      if (product) {
        addProduct(product);
        showSnackbar(`Scanned ${product.name}`);
      }
    });

    return stopScanner;
  }, []);

  const showSnackbar = useCallback(
    (message: string, severity: "success" | "error" | "info" = "success") => {
      setSnackbar({
        open: true,
        message,
        severity
      });
    },
    []
  );

  const focusSearch = () => {
    searchRef.current?.focus();
  };

  const handleAddProduct = (product: Product) => {
    const now = Date.now();
    const last = lastAddedRef.current;

    if (last && last.productId === product.id && now - last.time < 1500) {
      const existing = state.items.find((i) => i.productId === product.id);
      setQuickQtyProduct(product);
      setQuickQtyValue(String((existing?.quantity ?? 1) + 1));

      setTimeout(() => quickQtyInputRef.current?.focus(), 100);
      return;
    }

    addProduct(product);
    lastAddedRef.current = { productId: product.id, time: now };

    showSnackbar(`Added ${product.name}`);

    setSearchQuery("");
    focusSearch();
  };

  const confirmQuickQty = () => {
    if (!quickQtyProduct) return;

    const qty = parseInt(quickQtyValue);

    if (!qty) return;

    const existing = state.items.find(
      (i) => i.productId === quickQtyProduct.id
    );

    if (existing) {
      updateQty(existing.id, qty, quickQtyProduct);
    } else {
      addProduct(quickQtyProduct, qty);
    }

    setQuickQtyProduct(null);
    setQuickQtyValue("");
  };

  const cancelQuickQty = () => {
    setQuickQtyProduct(null);
    setQuickQtyValue("");
  };

  const handleCustomerSelect = (customer: POSCustomer | null) => {
    setCustomer(customer);
    setCustomerDrawerOpen(false);
  };

  const hasItems = state.items.length > 0;

  return (
    <div className="h-full flex flex-col overflow-hidden">

      {/* Order Type */}
      <div className="border-b bg-white px-4 py-2">
        <OrderIntentDropdown
          value={state.orderIntent}
          onChange={setOrderIntent}
          hasItems={hasItems}
        />
      </div>

      {/* Search */}
      <div className="border-b bg-white px-4 py-2 flex gap-3 items-center">

        <div className="relative flex-1 max-w-md">
          <input
            ref={searchRef}
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Scan barcode or search product"
            className="w-full h-10 pl-3 pr-3 border rounded-lg"
          />
        </div>

        <button
          onClick={() => setCustomerDrawerOpen(true)}
          className="h-10 px-4 border rounded-lg"
        >
          {state.customer ? state.customer.name : "Customer"}
        </button>

        <button
          onClick={onNext}
          disabled={!hasItems}
          className="h-10 px-4 bg-purple-600 text-white rounded-lg"
        >
          Next →
        </button>

      </div>

      {/* Categories */}
      <div className="flex gap-2 overflow-x-auto px-3 py-2 border-b bg-white">

        {POS_CATEGORIES.map((cat) => (
          <button
            key={cat.id}
            onClick={() => setSelectedCategory(cat.id)}
            className={`px-4 py-2 rounded-lg text-sm ${
              selectedCategory === cat.id
                ? "bg-purple-600 text-white"
                : "bg-gray-100"
            }`}
          >
            {cat.name}
          </button>
        ))}

      </div>

      {/* Main Layout */}
      <div className="flex-1 flex overflow-hidden">

        <ProductGrid
          products={products}
          searchQuery={searchQuery}
          selectedCategory={selectedCategory}
          onAddProduct={handleAddProduct}
          isLoading={isLoading}
        />

        <POSCartPanelV2 products={products} />

      </div>

      {/* Floating Cart Button (mobile only) */}
      <button
        onClick={() => setCustomerDrawerOpen(true)}
        className="fixed bottom-5 right-5 sm:hidden
        w-14 h-14 bg-purple-600 text-white rounded-full
        shadow-lg flex items-center justify-center text-xl"
      >
        🛒
      </button>

      {/* Customer Drawer */}
      <POSCustomerDrawer
        open={customerDrawerOpen}
        onClose={() => setCustomerDrawerOpen(false)}
        customers={customers}
        selectedCustomer={state.customer}
        onSelectCustomer={handleCustomerSelect}
        products={products}
        onAddProduct={addProduct}
      />

      {/* Quick Qty */}
      {quickQtyProduct && (
        <div className="fixed inset-0 bg-black/20 flex items-center justify-center">

          <div className="bg-white p-5 rounded-xl w-64">

            <h3 className="font-semibold mb-2">{quickQtyProduct.name}</h3>

            <input
              ref={quickQtyInputRef}
              value={quickQtyValue}
              onChange={(e) => setQuickQtyValue(e.target.value)}
              className="w-full border p-2 mb-3"
            />

            <div className="flex gap-2">

              <button
                onClick={confirmQuickQty}
                className="flex-1 bg-purple-600 text-white rounded p-2"
              >
                Set Qty
              </button>

              <button
                onClick={cancelQuickQty}
                className="flex-1 border rounded p-2"
              >
                Cancel
              </button>

            </div>

          </div>

        </div>
      )}

      {/* Snackbar */}
      <Snackbar
        open={snackbar.open}
        autoHideDuration={2000}
        onClose={() => setSnackbar({ ...snackbar, open: false })}
      >
        <Alert severity={snackbar.severity}>
          {snackbar.message}
        </Alert>
      </Snackbar>

    </div>
  );
};

export default ProductsTab;