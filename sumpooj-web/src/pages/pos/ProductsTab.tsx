/**
 * ProductsTab.tsx — Tab 2: Product Search + Cart
 *
 * Three-zone layout identical to the original POSScreen:
 *   CategorySidebar | ProductGrid | POSCartPanelV2
 *
 * Speed optimizations:
 *   - Auto-clear search & refocus after adding product
 *   - Barcode scan auto-adds instantly (no Enter needed)
 *   - Quick Quantity popup when adding same product twice
 *   - F2 focus search, F4 open payment, Esc clear cart
 */
import React, { useState, useCallback, useEffect, useRef } from 'react';
import { Alert, Snackbar } from '@mui/material';
import { Box, Chip } from '@mui/material';
import { POS_CATEGORIES } from './POSTypes';
import ProductGrid from './ProductGrid';
import POSCartPanelV2 from './POSCartPanelV2';
import POSCustomerDrawer from './POSCustomerDrawer';
import OrderIntentDropdown from './OrderIntentDropdown';
import { usePOS } from './POSContext';
import type { Product } from '../orders/OrderTypes';
import type { POSCustomer } from './POSCustomerTypes';
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
    updateQty,
    setCustomer,
    setOrderIntent,
    startPayment,
    resetCart,
    canEditCart,
    canCheckout,
  } = usePOS();

  // Refs
  const searchRef = useRef<HTMLInputElement>(null);

  // UI state
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCategory, setSelectedCategory] = useState('all');
  const [customerDrawerOpen, setCustomerDrawerOpen] = useState(false);
  const [snackbar, setSnackbar] = useState<{
    open: boolean;
    message: string;
    severity: 'success' | 'error' | 'info';
  }>({ open: false, message: '', severity: 'success' });

  // ─── Quick Quantity state ─────────────────────────────────
  const lastAddedRef = useRef<{ productId: string; time: number } | null>(null);
  const [quickQtyProduct, setQuickQtyProduct] = useState<Product | null>(null);
  const [quickQtyValue, setQuickQtyValue] = useState('');
  const quickQtyInputRef = useRef<HTMLInputElement>(null);

  // ─── Barcode scan detection ───────────────────────────────
  // Scanners type very fast (< 50ms between chars). Track rapid input.
  const scanBufferRef = useRef('');
  const scanTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const SCAN_CHAR_TIMEOUT = 60; // ms between chars to be considered a scan

  const showSnackbar = useCallback(
    (message: string, severity: 'success' | 'error' | 'info' = 'success') => {
      setSnackbar({ open: true, message, severity });
    },
    [],
  );

  // ─── Focus search helper ────────────────────────────────
  const focusSearch = useCallback(() => {
    searchRef.current?.focus();
    searchRef.current?.select();
  }, []);

  // ─── Add product (with auto-clear + refocus) ─────────────

  const handleAddProduct = useCallback(
    (product: Product) => {
      if (!canEditCart) {
        showSnackbar('Cart is locked during payment', 'error');
        return;
      }

      // Quick Quantity: if same product tapped again within 1.5s, show popup
      const now = Date.now();
      const last = lastAddedRef.current;
      if (
        last &&
        last.productId === product.id &&
        now - last.time < 1500
      ) {
        // Find current qty in cart
        const existing = state.items.find((i) => i.productId === product.id);
        setQuickQtyProduct(product);
        setQuickQtyValue(String((existing?.quantity ?? 1) + 1));
        lastAddedRef.current = null; // reset so third tap doesn't re-trigger
        // Focus the qty input after render
        setTimeout(() => quickQtyInputRef.current?.select(), 50);
        return;
      }

      addProduct(product);
      lastAddedRef.current = { productId: product.id, time: now };
      showSnackbar(`Added ${product.name}`, 'success');

      // Speed: clear search & refocus
      setSearchQuery('');
      requestAnimationFrame(focusSearch);
    },
    [addProduct, canEditCart, showSnackbar, focusSearch, state.items],
  );

  // ─── Quick Quantity confirm ───────────────────────────────

  const confirmQuickQty = useCallback(() => {
    if (!quickQtyProduct) return;
    const qty = parseInt(quickQtyValue, 10);
    if (isNaN(qty) || qty < 1) {
      setQuickQtyProduct(null);
      return;
    }
    const existing = state.items.find((i) => i.productId === quickQtyProduct.id);
    if (existing) {
      updateQty(existing.id, qty, quickQtyProduct);
    } else {
      addProduct(quickQtyProduct, qty);
    }
    showSnackbar(`${quickQtyProduct.name} × ${qty}`, 'success');
    setQuickQtyProduct(null);
    setQuickQtyValue('');
    requestAnimationFrame(focusSearch);
  }, [quickQtyProduct, quickQtyValue, state.items, updateQty, addProduct, showSnackbar, focusSearch]);

  const cancelQuickQty = useCallback(() => {
    setQuickQtyProduct(null);
    setQuickQtyValue('');
    requestAnimationFrame(focusSearch);
  }, [focusSearch]);

  // ─── Barcode lookup ───────────────────────────────────────

  const tryBarcodeAdd = useCallback(
    (code: string) => {
      const trimmed = code.trim();
      if (!trimmed) return false;
      const product = products.find(
        (p) =>
          p.barcode === trimmed ||
          p.internalBarcode === trimmed ||
          p.batchBarcode === trimmed ||
          p.finishedBarcode === trimmed,
      );
      if (product) {
        addProduct(product);
        showSnackbar(`Scanned: ${product.name}`, 'success');
        setSearchQuery('');
        requestAnimationFrame(focusSearch);
        return true;
      }
      return false;
    },
    [products, addProduct, showSnackbar, focusSearch],
  );

  const handleSearchSubmit = useCallback(() => {
    const query = searchQuery.trim();
    if (!query) return;
    if (tryBarcodeAdd(query)) return;
    // Not a barcode — keep search text for visual filtering
  }, [searchQuery, tryBarcodeAdd]);

  // ─── Search input change with barcode-scan detection ──────

  const handleSearchChange = useCallback(
    (e: React.ChangeEvent<HTMLInputElement>) => {
      const value = e.target.value;
      setSearchQuery(value);

      // Barcode scan detection: rapid chars finishing with a full code
      if (scanTimerRef.current) clearTimeout(scanTimerRef.current);

      // Accumulate into buffer
      scanBufferRef.current += value.slice(-1);

      scanTimerRef.current = setTimeout(() => {
        // Scanner finished — try the full buffer
        const code = scanBufferRef.current;
        scanBufferRef.current = '';
        if (code.length >= 6) {
          // Likely barcode — try auto-add
          tryBarcodeAdd(code);
        }
      }, SCAN_CHAR_TIMEOUT);
    },
    [tryBarcodeAdd],
  );

  // ─── Search input key handler ─────────────────────────────

  const handleSearchKeyDown = useCallback(
    (e: React.KeyboardEvent) => {
      if (e.key === 'Enter') {
        handleSearchSubmit();
      }
    },
    [handleSearchSubmit],
  );

  const handleCustomerSelect = useCallback(
    (customer: POSCustomer | null) => {
      setCustomer(customer);
      setCustomerDrawerOpen(false);
    },
    [setCustomer],
  );

  // ─── Global keyboard shortcuts ────────────────────────────

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      // Ignore if typing in an input/textarea (except our search)
      const tag = (e.target as HTMLElement)?.tagName;
      const isQuickQtyInput =
        quickQtyProduct && (e.target as HTMLElement) === quickQtyInputRef.current;

      if (e.key === 'F2') {
        e.preventDefault();
        focusSearch();
        return;
      }

      if (e.key === 'F4') {
        e.preventDefault();
        if (canCheckout) {
          startPayment();
        } else if (state.items.length > 0) {
          onNext();
        }
        return;
      }

      if (e.key === 'Escape') {
        // Close quick-qty popup first
        if (quickQtyProduct) {
          cancelQuickQty();
          return;
        }
        // Don't clear cart if user is in a dialog / drawer
        const isInModal = document.querySelector('[role="dialog"]');
        if (isInModal) return;
        if (state.items.length > 0) {
          e.preventDefault();
          resetCart();
          showSnackbar('Cart cleared', 'info');
          requestAnimationFrame(focusSearch);
        }
        return;
      }

      if (e.key === POS_SHORTCUTS.CUSTOMER) {
        e.preventDefault();
        setCustomerDrawerOpen(true);
      }
    };

    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [
    focusSearch,
    canCheckout,
    startPayment,
    state.items.length,
    resetCart,
    showSnackbar,
    onNext,
    quickQtyProduct,
    cancelQuickQty,
  ]);

  // ─── Render ─────────────────────────────────────────────

  const hasItems = state.items.length > 0;

  return (
    <div className="h-full flex flex-col overflow-hidden">
      {/* Intent Pill Selector — full width, strong highlight */}
      <div className="shrink-0 flex items-center px-4 py-2.5 border-b border-gray-200 bg-white">
        <OrderIntentDropdown
          value={state.orderIntent}
          onChange={setOrderIntent}
          hasItems={hasItems}
        />
      </div>

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
            ref={searchRef}
            type="text"
            autoFocus
            value={searchQuery}
            onChange={handleSearchChange}
            onKeyDown={handleSearchKeyDown}
            placeholder="Scan barcode or search product… (F2)"
            className="w-full h-10 pl-10 pr-3 text-sm border border-gray-200 rounded-lg
                       focus:outline-none focus:ring-2 focus:ring-purple-400 focus:border-transparent"
          />
        </div>

        {/* Shortcut hints */}
        <div className="hidden lg:flex items-center gap-1.5 text-[10px] text-gray-400">
          <kbd className="px-1.5 py-0.5 bg-gray-100 border border-gray-200 rounded font-mono">F4</kbd>
          <span>Pay</span>
          <kbd className="px-1.5 py-0.5 bg-gray-100 border border-gray-200 rounded font-mono ml-1">Esc</kbd>
          <span>Clear</span>
        </div>

        {/* Customer chip — amber border if no phone */}
        <button
          onClick={() => setCustomerDrawerOpen(true)}
          className={`flex items-center gap-2 h-10 px-4 border rounded-lg text-sm
                     hover:bg-gray-50 transition-colors ${
                       state.customer?.phone?.trim()
                         ? 'border-gray-200'
                         : 'border-amber-400 bg-amber-50'
                     }`}
        >
          <svg className="w-4 h-4 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
          </svg>
          <span className="text-gray-700 truncate max-w-[120px]">
            {state.customer ? state.customer.name : 'Customer'}
          </span>
          {hasItems && !state.customer?.phone?.trim() && (
            <span className="text-[10px] text-amber-600 font-medium">📱</span>
          )}
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

      {/* Horizontal Category Chips */}
      <Box
        sx={{
          display: 'flex',
          gap: 1.5,
          overflowX: 'auto',
          pb: 1,
          mb: 2,
          '&::-webkit-scrollbar': { display: 'none' },
        }}
      >
        {POS_CATEGORIES.map((category) => (
          <Chip
            key={category.id}
            label={category.name}
            clickable
            color={selectedCategory === category.id ? 'primary' : 'default'}
            onClick={() => setSelectedCategory(category.id)}
            sx={{
              fontSize: 14,
              height: 40,
              px: 2,
              fontWeight: 500,
              borderRadius: 3,
            }}
          />
        ))}
      </Box>

      {/* Product grid and cart panel, full width */}
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

      {/* Quick Quantity Popup — appears when same product tapped twice */}
      {quickQtyProduct && (
        <>
          <div
            className="fixed inset-0 bg-black/20 z-50"
            onClick={cancelQuickQty}
          />
          <div className="fixed top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 z-50
                          bg-white rounded-xl shadow-2xl border border-gray-200 p-4 w-64">
            <p className="text-sm font-medium text-gray-900 truncate mb-1">
              {quickQtyProduct.name}
            </p>
            <p className="text-xs text-gray-400 mb-3">Set quantity</p>
            <div className="flex items-center gap-2">
              <button
                onClick={() =>
                  setQuickQtyValue((v) => String(Math.max(1, (parseInt(v, 10) || 1) - 1)))
                }
                className="w-10 h-10 flex items-center justify-center border border-gray-200 rounded-lg
                           text-gray-600 hover:bg-gray-50 text-lg font-bold"
              >
                −
              </button>
              <input
                ref={quickQtyInputRef}
                type="number"
                min="1"
                value={quickQtyValue}
                onChange={(e) => setQuickQtyValue(e.target.value)}
                onKeyDown={(e) => {
                  if (e.key === 'Enter') confirmQuickQty();
                  if (e.key === 'Escape') cancelQuickQty();
                }}
                className="flex-1 h-10 text-center text-lg font-bold border border-gray-200 rounded-lg
                           focus:outline-none focus:ring-2 focus:ring-purple-400"
              />
              <button
                onClick={() =>
                  setQuickQtyValue((v) => String((parseInt(v, 10) || 0) + 1))
                }
                className="w-10 h-10 flex items-center justify-center border border-gray-200 rounded-lg
                           text-gray-600 hover:bg-gray-50 text-lg font-bold"
              >
                +
              </button>
            </div>
            <button
              onClick={confirmQuickQty}
              className="w-full mt-3 h-9 bg-purple-600 text-white text-sm font-semibold rounded-lg
                         hover:bg-purple-700 transition-colors"
            >
              Set Qty
            </button>
          </div>
        </>
      )}

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
