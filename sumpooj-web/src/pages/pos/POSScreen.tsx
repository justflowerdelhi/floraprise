/**
 * POSScreen.tsx — Tab-Based POS Workflow
 *
 * Four-step tabs:
 *  1. Order Type  — choose TAKE_NOW / DELIVERY / PICKUP_LATER
 *  2. Products    — search, scan, build cart
 *  3. Details     — delivery/pickup forms (or skip for TAKE_NOW)
 *  4. Payment     — split-pay, complete transaction
 *
 * Tab gating: must complete each step before the next unlocks.
 */
import React, { useState, useEffect, useCallback } from 'react';
import { Alert } from '@mui/material';
import { usePOS } from './POSContext';
import type { Product } from '../orders/OrderTypes';
import type { POSCustomer } from './POSCustomerTypes';
import { searchProducts, normalizeProducts } from '../../api/product.api';
import { MOCK_PRODUCTS } from '../orders/OrderMockData';
import { searchCustomers } from '../../api/customer.api';
const MOCK_CUSTOMERS: POSCustomer[] = [
  {
    id: 'cust_001',
    tenantId: 'tenant_001',
    name: 'Meera Joshi',
    phone: '9876543210',
    email: 'meera@example.com',
    preferredAddress: '123 Main St',
    createdAt: new Date().toISOString(),
    tags: ['NEW_CUSTOMER'],
    lifetimeValue: 10000,
    totalOrders: 2,
    averageOrderValue: 5000,
    referralCount: 0,
    loyaltyPoints: 100,
    loyaltyTier: 'SILVER',
    loyaltyPointsEarned: 100,
    loyaltyPointsRedeemed: 0,
    totalProfit: 2000,
    profitMargin: 20,
    marketingConsent: true,
    lastOrderDate: new Date().toISOString(),
    notes: 'First order, prefers lilies.'
  },
  {
    id: 'cust_002',
    tenantId: 'tenant_001',
    name: 'Raj Kapoor',
    phone: '9988776655',
    email: 'raj@example.com',
    preferredAddress: '45 MG Road',
    createdAt: new Date().toISOString(),
    tags: ['REPEAT_CUSTOMER'],
    lifetimeValue: 20000,
    totalOrders: 5,
    averageOrderValue: 4000,
    referralCount: 1,
    loyaltyPoints: 200,
    loyaltyTier: 'GOLD',
    loyaltyPointsEarned: 200,
    loyaltyPointsRedeemed: 50,
    totalProfit: 5000,
    profitMargin: 25,
    marketingConsent: true,
    lastOrderDate: new Date().toISOString(),
    notes: 'VIP customer, likes orchids.'
  },
];
import POSTabLayout, { type POSTab } from './POSTabLayout';
import OrderTypeTab from './OrderTypeTab';
import ProductsTab from './ProductsTab';
import DetailsTab from './DetailsTab';
import PaymentTab from './PaymentTab';

const POSScreen: React.FC = () => {
  const {
    state,
    setOrderIntent,
    cancelPayment,
    intentErrors,
  } = usePOS();

  // ─── Data Loading ─────────────────────────────────────────
  const [products, setProducts] = useState<Product[]>([]);
  const [customers, setCustomers] = useState<POSCustomer[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState('');

  const loadData = useCallback(async () => {
    setIsLoading(true);
    setError('');
    // Use mock data for products and customers
    try {
      // Fallback: ensure availableStock is set for all products
      const normalizedProducts = MOCK_PRODUCTS.map(p => ({
        ...p,
        availableStock: typeof p.availableStock === 'number' ? p.availableStock : 999
      }));
      setProducts(normalizedProducts);
    } catch (err) {
      setError('Failed to load products.');
    }
    try {
      setCustomers(MOCK_CUSTOMERS as POSCustomer[]);
    } catch (err) {
      setError('Failed to load customers.');
    }
    setIsLoading(false);
  }, []);

  useEffect(() => {
    loadData();
  }, [loadData]);

  // ─── Tab State ────────────────────────────────────────────
  const [activeTab, setActiveTab] = useState<POSTab>(0);

  const hasIntent = !!state.orderIntent;
  const hasItems = state.items.length > 0;
  const detailsValid = intentErrors.length === 0;

  // Enabled: which tabs the user can click
  const tabEnabled: Record<POSTab, boolean> = {
    0: true,
    1: hasIntent,
    2: hasIntent && hasItems,
    3: hasIntent && hasItems && detailsValid,
  };

  // Completed: green check
  const tabCompleted: Record<POSTab, boolean> = {
    0: hasIntent,
    1: hasItems,
    2: detailsValid && hasItems,
    3: state.lifecycle === 'completed',
  };

  // ─── Navigation Helpers ───────────────────────────────────

  const goTo = useCallback(
    (tab: POSTab) => {
      // If leaving payment tab, cancel payment lifecycle
      if (activeTab === 3 && tab !== 3 && state.lifecycle === 'payment') {
        cancelPayment();
      }
      if (tabEnabled[tab]) setActiveTab(tab);
    },
    [activeTab, state.lifecycle, cancelPayment, tabEnabled],
  );

  // Auto-reset to tab 0 after a completed transaction
  useEffect(() => {
    if (state.lifecycle === 'idle' && state.items.length === 0 && activeTab !== 0) {
      setActiveTab(0);
    }
  }, [state.lifecycle, state.items.length, activeTab]);

  // ─── Render ───────────────────────────────────────────────

  return (
    <div className="h-full flex flex-col overflow-hidden bg-gray-50">
      {error && (
        <Alert
          severity="warning"
          className="mx-4 mt-2"
          onClose={() => setError('')}
          action={
            <button
              onClick={loadData}
              className="ml-2 px-3 py-1 text-xs font-semibold bg-amber-100 hover:bg-amber-200 rounded transition-colors"
            >
              Retry
            </button>
          }
        >
          {error}
        </Alert>
      )}

      <POSTabLayout
        activeTab={activeTab}
        onTabChange={goTo}
        tabEnabled={tabEnabled}
        tabCompleted={tabCompleted}
      >
        {/* Tab 1 — Order Type */}
        {activeTab === 0 && (
          <OrderTypeTab
            selected={state.orderIntent}
            onSelect={setOrderIntent}
            onNext={() => goTo(1)}
          />
        )}

        {/* Tab 2 — Products */}
        {activeTab === 1 && (
          <ProductsTab
            products={products}
            customers={customers}
            isLoading={isLoading}
            onNext={() => goTo(2)}
          />
        )}

        {/* Tab 3 — Details */}
        {activeTab === 2 && (
          <DetailsTab
            onNext={() => goTo(3)}
            onBack={() => goTo(1)}
          />
        )}

        {/* Tab 4 — Payment */}
        {activeTab === 3 && (
          <PaymentTab
            onBack={() => goTo(2)}
          />
        )}
      </POSTabLayout>

      {/* Cart Lifecycle Indicator (debug) */}
      {process.env.NODE_ENV === 'development' && (
        <div className="fixed bottom-4 left-4 px-3 py-1 bg-gray-800 text-white text-xs rounded-full z-50">
          Tab: {activeTab + 1} | Cart: {state.lifecycle} | Items: {state.items.length} | Intent: {state.orderIntent}
        </div>
      )}
    </div>
  );
};

export default POSScreen;
