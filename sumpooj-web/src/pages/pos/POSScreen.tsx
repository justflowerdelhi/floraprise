/**
 * POSScreen.tsx — Main POS Screen using POSContext
 * 
 * Clean 3-zone layout: Category Sidebar | Product Grid | Cart Panel
 * Uses single cart architecture with lifecycle management
 * Optimized for 1440px desktop retail
 */
import React, { useState, useEffect, useCallback } from 'react';
import { Alert, Snackbar } from '@mui/material';
import POSTopBar from './POSTopBar';
import CategorySidebar from './CategorySidebar';
import ProductGrid from './ProductGrid';
import POSCartPanelV2 from './POSCartPanelV2';
import POSPaymentDrawerV2 from './POSPaymentDrawerV2';
import POSCustomerDrawer from './POSCustomerDrawer';
import { usePOS } from './POSContext';
import type { Product } from '../orders/OrderTypes';
import type { POSCustomer } from './POSTypes';
import { POS_SHORTCUTS } from './POSTypes';
import { searchProducts } from '../../api/product.api';
import { searchCustomers } from '../../api/customer.api';

const POSScreen: React.FC = () => {
  console.log('[DEBUG] POSScreen rendering');
  const {
    state,
    addProduct,
    setCustomer,
    setOrderType,
    startPayment,
    resetCart,
    canCheckout,
    canEditCart,
  } = usePOS();
  console.log('[DEBUG] usePOS result state:', state.lifecycle);

  // Data state
  const [products, setProducts] = useState<Product[]>([]);
  const [customers, setCustomers] = useState<POSCustomer[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState('');

  // UI state
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCategory, setSelectedCategory] = useState('all');
  const [customerDrawerOpen, setCustomerDrawerOpen] = useState(false);

  // Snackbar
  const [snackbar, setSnackbar] = useState<{
    open: boolean;
    message: string;
    severity: 'success' | 'error' | 'info';
  }>({
    open: false,
    message: '',
    severity: 'success',
  });

  // Load data on mount
  useEffect(() => {
    const loadData = async () => {
      setIsLoading(true);
      setError('');
      try {
        const [prodRes, custRes] = await Promise.all([
          searchProducts({ IsActive: true, PageSize: 500 }),
          searchCustomers({ PageSize: 500 }),
        ]);
        const prodItems = Array.isArray(prodRes) ? prodRes : prodRes.items ?? [];
        setProducts(prodItems);
        const custItems = Array.isArray(custRes) ? custRes : custRes.items ?? [];
        setCustomers(custItems);
      } catch (err) {
        console.error('POS data load failed:', err);
        setError('Failed to load POS data. Please refresh.');
      } finally {
        setIsLoading(false);
      }
    };
    loadData();
  }, []);

  // Keyboard shortcuts
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      // F9 - Quick checkout
      if (e.key === POS_SHORTCUTS.CHECKOUT && canCheckout) {
        e.preventDefault();
        startPayment();
      }
      // F8 - Clear cart
      if (e.key === POS_SHORTCUTS.CLEAR && canEditCart) {
        e.preventDefault();
        resetCart();
        showSnackbar('Cart cleared', 'info');
      }
      // F3 - Customer
      if (e.key === POS_SHORTCUTS.CUSTOMER) {
        e.preventDefault();
        setCustomerDrawerOpen(true);
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [canCheckout, canEditCart, startPayment, resetCart]);

  // Handlers
  const showSnackbar = useCallback(
    (message: string, severity: 'success' | 'error' | 'info' = 'success') => {
      setSnackbar({ open: true, message, severity });
    },
    []
  );

  const handleAddProduct = useCallback(
    (product: Product) => {
      if (!canEditCart) {
        showSnackbar('Cart is locked during payment', 'error');
        return;
      }
      addProduct(product);
      showSnackbar(`Added ${product.name}`, 'success');
    },
    [addProduct, canEditCart, showSnackbar]
  );

  const handleSearchSubmit = useCallback(() => {
    const query = searchQuery.trim();
    if (!query) return;

    const product = products.find(
      (p) =>
        p.barcode === query ||
        p.internalBarcode === query ||
        p.batchBarcode === query ||
        p.finishedBarcode === query
    );

    if (product) {
      handleAddProduct(product);
      setSearchQuery('');
    }
  }, [searchQuery, products, handleAddProduct]);

  const handleCustomerSelect = useCallback(
    (customer: POSCustomer | null) => {
      setCustomer(customer);
      setCustomerDrawerOpen(false);
    },
    [setCustomer]
  );

  // Format currency
  const formatCurrency = (amount: number) =>
    new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
    }).format(amount);

  return (
    <div className="h-full flex flex-col bg-gray-50 overflow-hidden">
      {/* Error Alert */}
      {error && (
        <Alert severity="error" className="m-4">
          {error}
        </Alert>
      )}

      {/* Top Bar */}
      <POSTopBar
        searchValue={searchQuery}
        onSearchChange={setSearchQuery}
        onSearchSubmit={handleSearchSubmit}
        selectedCustomer={state.customer}
        onCustomerClick={() => setCustomerDrawerOpen(true)}
        orderType={state.orderType}
        onOrderTypeChange={setOrderType}
        locationName={state.session.locationName}
        onLocationClick={() => {}}
        grandTotal={state.totals.grandTotal}
      />

      {/* Main Content - 3 Zone Layout */}
      <div className="flex-1 flex overflow-hidden">
        {/* Left: Category Sidebar (80px) */}
        <CategorySidebar
          selectedCategory={selectedCategory}
          onCategorySelect={setSelectedCategory}
        />

        {/* Center: Product Grid (flexible) */}
        <ProductGrid
          products={products}
          searchQuery={searchQuery}
          selectedCategory={selectedCategory}
          onAddProduct={handleAddProduct}
          isLoading={isLoading}
        />

        {/* Right: Cart Panel (320-384px) */}
        <POSCartPanelV2 products={products} />
      </div>

      {/* Payment Drawer */}
      <POSPaymentDrawerV2 />

      {/* Customer Drawer */}
      <POSCustomerDrawer
        open={customerDrawerOpen}
        onClose={() => setCustomerDrawerOpen(false)}
        customers={customers}
        selectedCustomer={state.customer}
        onSelectCustomer={handleCustomerSelect}
      />

      {/* Snackbar */}
      <Snackbar
        open={snackbar.open}
        autoHideDuration={2000}
        onClose={() => setSnackbar((prev) => ({ ...prev, open: false }))}
        anchorOrigin={{ vertical: 'bottom', horizontal: 'center' }}
      >
        <Alert
          severity={snackbar.severity}
          onClose={() => setSnackbar((prev) => ({ ...prev, open: false }))}
          sx={{ minWidth: 200 }}
        >
          {snackbar.message}
        </Alert>
      </Snackbar>

      {/* Cart Lifecycle Indicator (debug - remove in production) */}
      {process.env.NODE_ENV === 'development' && (
        <div className="fixed bottom-4 left-4 px-3 py-1 bg-gray-800 text-white text-xs rounded-full">
          Cart: {state.lifecycle} | Items: {state.items.length}
        </div>
      )}
    </div>
  );
};

export default POSScreen;
