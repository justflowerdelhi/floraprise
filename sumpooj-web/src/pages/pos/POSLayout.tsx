/**
 * POSLayout.tsx — Main POS layout for FloraEdge
 * Clean 3-zone layout: Category Sidebar | Product Grid | Cart Panel
 * 
 * Designed for high-speed checkout with Square/Shopify POS feel
 */
import React, { useState, useEffect, useCallback } from 'react';
import { Alert, Snackbar } from '@mui/material';
import POSTopBar from './POSTopBar';
import CategorySidebar from './CategorySidebar';
import ProductGrid from './ProductGrid';
import POSCartPanel from './POSCartPanel';
import POSPaymentDrawer from './POSPaymentDrawer';
import POSCustomerDrawer from './POSCustomerDrawer';
import { useCart } from '../cart/CartContext';
import type { Product } from '../orders/OrderTypes';
import type { POSOrderType, POSCustomer, POSPaymentEntry, POSBillingInfo } from './POSTypes';
import { POS_SHORTCUTS } from './POSTypes';
import { searchProducts } from '../../api/product.api';
import { searchCustomers } from '../../api/customer.api';

const POSLayout: React.FC = () => {
  // Cart context
  const { state, addProduct, updateQty, removeItem, clearCart, setOrderSource } = useCart();

  // Local state
  const [products, setProducts] = useState<Product[]>([]);
  const [customers, setCustomers] = useState<POSCustomer[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState('');

  // UI state
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCategory, setSelectedCategory] = useState('all');
  const [orderType, setOrderType] = useState<POSOrderType>('local');
  const [selectedCustomer, setSelectedCustomer] = useState<POSCustomer | null>(null);
  const [locationName] = useState('Main Store'); // TODO: From LocationContext

  // Drawer states
  const [paymentDrawerOpen, setPaymentDrawerOpen] = useState(false);
  const [paymentMethod, setPaymentMethod] = useState<'cash' | 'card' | 'split' | 'more'>('split');
  const [customerDrawerOpen, setCustomerDrawerOpen] = useState(false);

  // Snackbar
  const [snackbar, setSnackbar] = useState<{ open: boolean; message: string; severity: 'success' | 'error' | 'info' }>({
    open: false,
    message: '',
    severity: 'success',
  });

  // Load data
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

  // Set order source
  useEffect(() => {
    setOrderSource('WALK_IN');
  }, [setOrderSource]);

  // Keyboard shortcuts
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === POS_SHORTCUTS.CHECKOUT && state.items.length > 0) {
        e.preventDefault();
        handlePayment('split');
      }
      if (e.key === POS_SHORTCUTS.CLEAR) {
        e.preventDefault();
        clearCart();
        showSnackbar('Cart cleared', 'info');
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [state.items.length, clearCart]);

  // Handlers
  const showSnackbar = useCallback((message: string, severity: 'success' | 'error' | 'info' = 'success') => {
    setSnackbar({ open: true, message, severity });
  }, []);

  const handleAddProduct = useCallback((product: Product) => {
    addProduct(product);
    showSnackbar(`Added ${product.name}`, 'success');
  }, [addProduct, showSnackbar]);

  const handleSearchSubmit = useCallback(() => {
    // Barcode search - find exact match
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

  const handlePayment = useCallback((method: 'cash' | 'card' | 'split' | 'more') => {
    if (state.items.length === 0) return;
    setPaymentMethod(method);
    setPaymentDrawerOpen(true);
  }, [state.items.length]);

  const handlePaymentComplete = useCallback((payments: POSPaymentEntry[], billingInfo: POSBillingInfo) => {
    // TODO: Create order via API
    console.log('Payment complete:', { payments, billingInfo, items: state.items, totals: state.totals });
    setPaymentDrawerOpen(false);
    clearCart();
    setSelectedCustomer(null);
    showSnackbar(`Order completed - ${new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(state.totals.grandTotal)}`, 'success');
  }, [state.items, state.totals, clearCart, showSnackbar]);

  const handlePartialSave = useCallback((payments: POSPaymentEntry[], billingInfo: POSBillingInfo, paidAmount: number, remainingAmount: number) => {
    // TODO: Create order with balance via API
    console.log('Partial save:', { payments, billingInfo, paidAmount, remainingAmount });
    setPaymentDrawerOpen(false);
    clearCart();
    setSelectedCustomer(null);
    showSnackbar(`Order saved - ${new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(remainingAmount)} balance due`, 'info');
  }, [clearCart, showSnackbar]);

  const handleUpdateQty = useCallback((lineId: string, qty: number, product: Product) => {
    updateQty(lineId, qty, product);
  }, [updateQty]);

  const handleRemoveItem = useCallback((lineId: string) => {
    removeItem(lineId);
  }, [removeItem]);

  return (
    <div className="h-screen flex flex-col bg-gray-50 overflow-hidden">
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
        selectedCustomer={selectedCustomer}
        onCustomerClick={() => setCustomerDrawerOpen(true)}
        orderType={orderType}
        onOrderTypeChange={setOrderType}
        locationName={locationName}
        onLocationClick={() => {}} // TODO: Location switcher
        grandTotal={state.totals.grandTotal}
      />

      {/* Main Content */}
      <div className="flex-1 flex overflow-hidden">
        {/* Category Sidebar */}
        <CategorySidebar
          selectedCategory={selectedCategory}
          onCategorySelect={setSelectedCategory}
        />

        {/* Product Grid */}
        <ProductGrid
          products={products}
          searchQuery={searchQuery}
          selectedCategory={selectedCategory}
          onAddProduct={handleAddProduct}
          isLoading={isLoading}
        />

        {/* Cart Panel */}
        <POSCartPanel
          items={state.items}
          totals={state.totals}
          products={products}
          onUpdateQty={handleUpdateQty}
          onRemoveItem={handleRemoveItem}
          onPayment={handlePayment}
        />
      </div>

      {/* Payment Drawer */}
      <POSPaymentDrawer
        open={paymentDrawerOpen}
        onClose={() => setPaymentDrawerOpen(false)}
        grandTotal={state.totals.grandTotal}
        selectedCustomer={selectedCustomer}
        onComplete={handlePaymentComplete}
        onPartialSave={handlePartialSave}
        initialMethod={paymentMethod}
      />

      {/* Customer Drawer */}
      <POSCustomerDrawer
        open={customerDrawerOpen}
        onClose={() => setCustomerDrawerOpen(false)}
        customers={customers}
        selectedCustomer={selectedCustomer}
        onSelectCustomer={setSelectedCustomer}
      />

      {/* Snackbar */}
      <Snackbar
        open={snackbar.open}
        autoHideDuration={2000}
        onClose={() => setSnackbar(prev => ({ ...prev, open: false }))}
        anchorOrigin={{ vertical: 'bottom', horizontal: 'center' }}
      >
        <Alert 
          severity={snackbar.severity} 
          onClose={() => setSnackbar(prev => ({ ...prev, open: false }))}
          sx={{ minWidth: 200 }}
        >
          {snackbar.message}
        </Alert>
      </Snackbar>
    </div>
  );
};

export default POSLayout;
