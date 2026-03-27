/**
 * POSLayout.tsx — Main POS layout for FloraPrice
 * Clean 3-zone layout: Category Sidebar | Product Grid | Cart Panel
 * 
 * Designed for high-speed checkout with Square/Shopify POS feel
 */
import React, { useState, useEffect, useCallback } from 'react';
import { Alert, Snackbar } from '@mui/material';
import { ShoppingCart as CartIcon } from '@mui/icons-material';
import POSTopBar from './POSTopBar';

import ProductGrid from './ProductGrid';
import POSCartPanel from './POSCartPanel';
import POSPaymentDrawer from './POSPaymentDrawer';
import POSCustomerDrawer from './POSCustomerDrawer';
import ShiftOpenModal from './ShiftOpenModal';
import ShiftCloseDrawer from './ShiftCloseDrawer';
import { useCart } from '../cart/CartContext';
import { useShift } from './ShiftContext';
import { useLocation as useLocationCtx } from '../../core/location/LocationContext';
import type { Product } from '../orders/OrderTypes';
import type { POSOrderType, POSCustomer, POSPaymentEntry, POSBillingInfo } from './POSTypes';
import { POS_SHORTCUTS } from './POSTypes';
import { searchProducts, normalizeProducts } from '../../api/product.api';
import { searchCustomers } from '../../api/customer.api';
import { fetchSellableFinishedGoods } from '../../api/order.api';
import { formatCurrency } from '../../core/i18n';

const POSLayout: React.FC = () => {
  // Cart context
  const { state, addProduct, updateQty, removeItem, clearCart, setOrderSource } = useCart();

  // Shift context
  const { activeShift, setCloseDrawerOpen } = useShift();

  // Location from global context
  const { currentLocation, currentLocationId, accessibleLocations, setCurrentLocationId } = useLocationCtx();
  const locationName = currentLocation?.name ?? 'No Location';

  // Local state
  const [products, setProducts] = useState<Product[]>([]);
  const [customers, setCustomers] = useState<POSCustomer[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState('');

  // UI state
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCategory, setSelectedCategory] = useState('all');
  const [orderType, setOrderType] = useState<POSOrderType>('TAKE_NOW');
  const [selectedCustomer, setSelectedCustomer] = useState<POSCustomer | null>(null);

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
        const [prodRes, custRes, finishedGoodsRes] = await Promise.all([
          searchProducts({ IsActive: true, PageSize: 500 }).catch(() => []),
          searchCustomers({ PageSize: 500 }).catch(() => []),
          fetchSellableFinishedGoods().catch(() => []),
        ]);
        const prodItems = Array.isArray(prodRes) ? prodRes : prodRes?.items ?? [];
        const normalized = normalizeProducts(prodItems);

        const finishedGoodsItems = (Array.isArray(finishedGoodsRes) ? finishedGoodsRes : [])
          .filter((fg: any) => !currentLocationId || fg.locationId === currentLocationId)
          .map((fg: any) => ({
            id: `FG-${fg.id}`,
            name: fg.name || fg.recipeName || 'Ready Bouquet',
            sku: fg.sku || fg.batchCode || fg.id,
            barcode: fg.barcode,
            finishedBarcode: fg.barcode,
            category: 'Bouquets',
            sellingPrice: Number(fg.retailPrice) || Number(fg.sellingPrice) || 0,
            costPrice: Number(fg.costPrice) || 0,
            taxRate: 0,
            availableStock: Number(fg.stockQuantity) || Number(fg.quantityAvailable) || 0,
            isPerishable: true,
            trackBatch: false,
            imageUrl: '',
            batches: [],
          } as Product));

        setProducts([...finishedGoodsItems, ...normalized]);
        const custItems = Array.isArray(custRes) ? custRes : custRes?.items ?? [];
        setCustomers(custItems);
      } catch (err) {
        console.error('POS data load failed:', err);
        setError('Failed to load POS data. Please refresh.');
      } finally {
        setIsLoading(false);
      }
    };
    loadData();
  }, [currentLocationId]);

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

  // Mobile cart drawer
  const [mobileCartOpen, setMobileCartOpen] = useState(false);

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
    // Create order via API
    const createOrder = async () => {
      try {
        const orderPayload = {
          customerId: selectedCustomer?.id || null,
          locationId: currentLocationId || null,
          deliveryDate: billingInfo.deliveryDate || null,
          deliveryAddress: billingInfo.deliveryAddress || null,
          recipientName: billingInfo.recipientName || null,
          recipientPhone: billingInfo.recipientPhone || null,
          cardMessage: billingInfo.cardMessage || null,
          deliveryPriority: billingInfo.deliveryPriority || 'NORMAL',
          timeSlot: billingInfo.timeSlot || null,
          orderSource: 'WALK_IN',
          orderIntent: orderType,
          pickupDate: billingInfo.pickupDate || null,
          pickupTimeSlot: billingInfo.pickupTimeSlot || null,
          deliveryFee: billingInfo.deliveryFee || 0,
          discountAmount: billingInfo.discountAmount || 0,
          internalNotes: billingInfo.internalNotes || null,
          items: state.items.map(item => ({
            productId: item.productId,
            quantity: item.quantity,
            unitPrice: item.unitPrice,
            productName: item.productName,
          })),
          payments: payments.map(p => ({
            method: p.method,
            amount: p.amount,
          })),
        };
        await import('../../api/order.api').then(({ createOrder }) => createOrder(orderPayload));
        setPaymentDrawerOpen(false);
        clearCart();
        setSelectedCustomer(null);
        showSnackbar(`Order completed - ${formatCurrency(state.totals.grandTotal)}`, 'success');
      } catch (err) {
        setPaymentDrawerOpen(false);
        showSnackbar('Order creation failed. Please try again.', 'error');
      }
    };
    createOrder();
  }, [state.items, state.totals, clearCart, showSnackbar, selectedCustomer, orderType, currentLocationId]);

  const handlePartialSave = useCallback((payments: POSPaymentEntry[], billingInfo: POSBillingInfo, paidAmount: number, remainingAmount: number) => {
    // Create order with balance via API
    const createOrderWithBalance = async () => {
      try {
        const orderPayload = {
          customerId: selectedCustomer?.id || null,
          locationId: currentLocationId || null,
          deliveryDate: billingInfo.deliveryDate || null,
          deliveryAddress: billingInfo.deliveryAddress || null,
          recipientName: billingInfo.recipientName || null,
          recipientPhone: billingInfo.recipientPhone || null,
          cardMessage: billingInfo.cardMessage || null,
          deliveryPriority: billingInfo.deliveryPriority || 'NORMAL',
          timeSlot: billingInfo.timeSlot || null,
          orderSource: 'WALK_IN',
          orderIntent: orderType,
          pickupDate: billingInfo.pickupDate || null,
          pickupTimeSlot: billingInfo.pickupTimeSlot || null,
          deliveryFee: billingInfo.deliveryFee || 0,
          discountAmount: billingInfo.discountAmount || 0,
          internalNotes: billingInfo.internalNotes || null,
          items: state.items.map(item => ({
            productId: item.productId,
            quantity: item.quantity,
            unitPrice: item.unitPrice,
            productName: item.productName,
          })),
          payments: payments.map(p => ({
            method: p.method,
            amount: p.amount,
          })),
        };
        await import('../../api/order.api').then(({ createOrder }) => createOrder(orderPayload));
        setPaymentDrawerOpen(false);
        clearCart();
        setSelectedCustomer(null);
        showSnackbar(`Order saved - ${formatCurrency(remainingAmount)} balance due`, 'info');
      } catch (err) {
        setPaymentDrawerOpen(false);
        showSnackbar('Order creation failed. Please try again.', 'error');
      }
    };
    createOrderWithBalance();
  }, [state.items, clearCart, showSnackbar, selectedCustomer, orderType, currentLocationId]);

  const handleUpdateQty = useCallback((lineId: string, qty: number, product: Product) => {
    updateQty(lineId, qty, product);
  }, [updateQty]);

  const handleRemoveItem = useCallback((lineId: string) => {
    removeItem(lineId);
  }, [removeItem]);

  return (
    <div className="h-screen flex flex-col bg-gray-50 overflow-hidden">
      {/* Shift guard — blocks POS when no active shift */}
      <ShiftOpenModal />

      {/* Shift close drawer */}
      <ShiftCloseDrawer />

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
        accessibleLocations={accessibleLocations}
        currentLocationId={typeof currentLocationId === 'string' ? currentLocationId : null}
        onLocationChange={setCurrentLocationId}
        grandTotal={state.totals.grandTotal}
        hasItems={state.items.length > 0}
        activeShift={activeShift ? {
          openingCash: activeShift.openingCash,
          openedAt: activeShift.openedAt,
          openedByName: activeShift.openedByName,
          transactionCount: activeShift.transactionCount,
          cashSales: activeShift.cashSales,
          totalRefunds: activeShift.totalRefunds,
          expectedCash: activeShift.expectedCash,
          cashDifference: activeShift.cashDifference,
        } : null}
        onCloseShift={() => setCloseDrawerOpen(true)}
      />

      {/* Main Content */}
      <div className="flex-1 flex overflow-hidden">
        {/* Product Grid — full width on mobile */}
        <ProductGrid
          products={products}
          searchQuery={searchQuery}
          selectedCategory={selectedCategory}
          onAddProduct={handleAddProduct}
          isLoading={isLoading}
          locationId={currentLocationId}
        />

        {/* Cart Panel — hidden on mobile, shown on md+ */}
        <div className="hidden md:flex">
          <POSCartPanel
            items={state.items}
            totals={state.totals}
            products={products}
            onUpdateQty={handleUpdateQty}
            onRemoveItem={handleRemoveItem}
            onPayment={handlePayment}
          />
        </div>
      </div>

      {/* Mobile Cart Floating Button — visible only on mobile when cart has items */}
      {state.items.length > 0 && !mobileCartOpen && (
        <button
          onClick={() => setMobileCartOpen(true)}
          className="md:hidden fixed bottom-6 left-1/2 -translate-x-1/2 z-40
                     flex items-center gap-2 px-6 py-3 bg-purple-600 text-white
                     rounded-full shadow-lg shadow-purple-200 active:scale-95 transition-transform"
        >
          <CartIcon className="w-5 h-5" />
          <span className="font-semibold">{state.items.length} items</span>
          <span className="text-purple-200">•</span>
          <span className="font-bold">{formatCurrency(state.totals.grandTotal)}</span>
        </button>
      )}

      {/* Mobile Cart Drawer — slides up from bottom */}
      {mobileCartOpen && (
        <div className="md:hidden fixed inset-0 z-50 flex flex-col">
          {/* Backdrop */}
          <div
            className="flex-shrink-0 bg-black/40"
            style={{ height: '60px' }}
            onClick={() => setMobileCartOpen(false)}
          />
          {/* Cart panel fills remaining space */}
          <div className="flex-1 bg-white rounded-t-2xl shadow-2xl flex flex-col overflow-hidden animate-slide-up">
            {/* Drag handle + close */}
            <div className="flex items-center justify-between px-4 pt-3 pb-2 border-b border-gray-100">
              <div className="flex items-center gap-2">
                <div className="w-8 h-1 bg-gray-300 rounded-full" />
              </div>
              <button
                onClick={() => setMobileCartOpen(false)}
                className="text-sm text-purple-600 font-medium px-3 py-1"
              >
                Done
              </button>
            </div>
            {/* Reuse cart panel */}
            <div className="flex-1 flex flex-col overflow-hidden">
              <POSCartPanel
                items={state.items}
                totals={state.totals}
                products={products}
                onUpdateQty={handleUpdateQty}
                onRemoveItem={handleRemoveItem}
                onPayment={(method) => {
                  setMobileCartOpen(false);
                  handlePayment(method);
                }}
              />
            </div>
          </div>
        </div>
      )}

      {/* Payment Drawer */}
      <POSPaymentDrawer
        open={paymentDrawerOpen}
        onClose={() => setPaymentDrawerOpen(false)}
        grandTotal={state.totals.grandTotal}
        selectedCustomer={selectedCustomer}
        customers={customers}
        onComplete={handlePaymentComplete}
        onPartialSave={handlePartialSave}
        initialMethod={paymentMethod}
        orderIntent={orderType}
      />

      {/* Customer Drawer */}
      <POSCustomerDrawer
        open={customerDrawerOpen}
        onClose={() => setCustomerDrawerOpen(false)}
        customers={customers}
        selectedCustomer={selectedCustomer}
        onSelectCustomer={setSelectedCustomer}
        products={products}
        onAddProduct={handleAddProduct}
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
