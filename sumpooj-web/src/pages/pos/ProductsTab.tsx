/**
 * ProductsTab.tsx — Tab 2: Product Search + Cart
 *
 * Three-zone layout identical to the original POSScreen:
 *   CategorySidebar | ProductGrid | POSCartPanelV2
 *
 * Also keeps the search bar, customer drawer, and keyboard shortcuts.
 */
import React, { useState, useCallback, useEffect } from 'react';
import { Alert, Snackbar } from '@mui/material';
import CategorySidebar from './CategorySidebar';
import ProductGrid from './ProductGrid';
import POSCartPanelV2 from './POSCartPanelV2';
import POSCustomerDrawer from './POSCustomerDrawer';
import { usePOS } from './POSContext';
import type { Product } from '../orders/OrderTypes';
import type { POSCustomer } from './POSTypes';
import { POS_SHORTCUTS } from './POSTypes';

// ─── Props ──────────────────────────────────────────────────

interface ProductsTabProps {
  products: Product[];
  customers: POSCustomer[];
  isLoading: boolean;
  /** Called when the user clicks "Next → Details" */
  onNext: () => void;
}

// ─── Component ──────────────────────────────────────────────

const ProductsTab: React.FC<ProductsTabProps> = ({
  products,
  customers,
  isLoading,
  onNext,
}) => {
  const {
    state,
    addProduct,
    setCustomer,
    canEditCart,
  } = usePOS();

  // UI state
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCategory, setSelectedCategory] = useState('all');
  const [customerDrawerOpen, setCustomerDrawerOpen] = useState(false);
  const [snackbar, setSnackbar] = useState<{
    open: boolean;
    message: string;
    severity: 'success' | 'error' | 'info';
  }>({ open: false, message: '', severity: 'success' });

  const showSnackbar = useCallback(
    (message: string, severity: 'success' | 'error' | 'info' = 'success') => {
      setSnackbar({ open: true, message, severity });
    },
    [],
  );

  // ─── Handlers ───────────────────────────────────────────

  const handleAddProduct = useCallback(
    (product: Product) => {
      if (!canEditCart) {
        showSnackbar('Cart is locked during payment', 'error');
        return;
      }
      addProduct(product);
      showSnackbar(`Added ${product.name}`, 'success');
    },
    [addProduct, canEditCart, showSnackbar],
  );

  const handleSearchSubmit = useCallback(() => {
    const query = searchQuery.trim();
    if (!query) return;
    const product = products.find(
      (p) =>
        p.barcode === query ||
        p.internalBarcode === query ||
        p.batchBarcode === query ||
        p.finishedBarcode === query,
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
    [setCustomer],
  );

  // ─── Keyboard shortcuts ─────────────────────────────────

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === POS_SHORTCUTS.CUSTOMER) {
        e.preventDefault();
        setCustomerDrawerOpen(true);
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, []);

  // ─── Render ─────────────────────────────────────────────

  const hasItems = state.items.length > 0;

  return (
    <div className="h-full flex flex-col overflow-hidden">
      {/* Search bar */}
      <div className="shrink-0 flex items-center gap-3 px-4 py-2 border-b border-gray-200 bg-white">
        {/* Search */}
        <div className="relative flex-1 max-w-md">
          <svg
            className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"
            />
          </svg>
          <input
            type="text"
            autoFocus
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            onKeyDown={(e) => e.key === 'Enter' && handleSearchSubmit()}
            placeholder="Scan barcode or search product…"
            className="w-full h-10 pl-10 pr-3 text-sm border border-gray-200 rounded-lg
                       focus:outline-none focus:ring-2 focus:ring-purple-400 focus:border-transparent"
          />
        </div>

        {/* Customer chip */}
        <button
          onClick={() => setCustomerDrawerOpen(true)}
          className="flex items-center gap-2 h-10 px-4 border border-gray-200 rounded-lg text-sm
                     hover:bg-gray-50 transition-colors"
        >
          <svg className="w-4 h-4 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
          </svg>
          <span className="text-gray-700 truncate max-w-[120px]">
            {state.customer ? state.customer.name : 'Customer'}
          </span>
        </button>

        {/* Next button */}
        <button
          onClick={onNext}
          disabled={!hasItems}
          className="h-10 px-5 bg-purple-600 text-white text-sm font-semibold rounded-lg
                     hover:bg-purple-700 transition-colors
                     disabled:bg-gray-300 disabled:cursor-not-allowed shrink-0"
        >
          Next →
        </button>
      </div>

      {/* 3-zone layout */}
      <div className="flex-1 flex overflow-hidden">
        <CategorySidebar
          selectedCategory={selectedCategory}
          onCategorySelect={setSelectedCategory}
        />
        <ProductGrid
          products={products}
          searchQuery={searchQuery}
          selectedCategory={selectedCategory}
          onAddProduct={handleAddProduct}
          isLoading={isLoading}
        />
        <POSCartPanelV2 products={products} />
      </div>

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
    </div>
  );
};

export default ProductsTab;
