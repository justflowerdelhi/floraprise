/**
 * POSLayout.tsx — Main POS layout for FloraEdge
 * Clean 3-zone layout: Category Sidebar | Product Grid | Cart Panel
 * 
 * Designed for high-speed checkout with Square/Shopify POS feel
 */
import React, { useState, useEffect, useCallback, Fragment } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import { Alert, Snackbar, Box } from '@mui/material';
import TextField from '@mui/material/TextField';
import MenuItem from '@mui/material/MenuItem';
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
import type { POSOrderType, POSPaymentEntry, POSBillingInfo } from './POSTypes';
import type { POSCustomer } from './POSCustomerTypes';
import { POS_SHORTCUTS } from './POSTypes';
import { searchProducts, normalizeProducts } from '../../api/product.api';
import { searchCustomers } from '../../api/customer.api';

const POSLayout: React.FC = () => {
  const navigate = useNavigate();

    // Order details form state
    const [deliveryDetails, setDeliveryDetails] = useState({
      customerName: '',
      phone: '',
      address: '',
      deliveryDate: '',
      timeSlot: '',
    });
    const [pickupDetails, setPickupDetails] = useState({
      customerName: '',
      phone: '',
      pickupDate: '',
      pickupTime: '',
    });

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

  // Filter visible products for POS grid
  const visibleProducts = products.filter(p => {
    // @ts-expect-error: availableQuantity and trackInventory may come from API normalization
    if (!p.trackInventory) return true;
    // @ts-expect-error: availableQuantity may be missing
    if (typeof p.availableQuantity !== 'number') return true;
    // @ts-expect-error: availableQuantity may be missing
    return p.availableQuantity > 0;
  });

  // UI state
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCategory, setSelectedCategory] = useState('all');
  const [orderType, setOrderType] = useState<POSOrderType>('TAKE_NOW');

    // Order intent mapping (for demo, map POSOrderType to intent string)
    let orderIntent: 'Delivery' | 'PickupLater' | 'TakeNow' = 'TakeNow';
    if (orderType === 'DELIVERY') orderIntent = 'Delivery';
    else if (orderType === 'PICKUP_LATER') orderIntent = 'PickupLater';
  const [selectedCustomer, setSelectedCustomer] = useState<POSCustomer | null>(null);

  // Sidebar collapse logic for POS routes
  const location = useLocation();
  const isPOSRoute = location.pathname.startsWith('/pos') || location.pathname.startsWith('/walk-in') || location.pathname.startsWith('/sales');
  const [sidebarCollapsed, setSidebarCollapsed] = useState(isPOSRoute);

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
        let prodItems = Array.isArray(prodRes) ? prodRes : prodRes.items ?? [];
        // Inject mock products if API returns empty
        if (!prodItems || prodItems.length === 0) {
          prodItems = [
            {
              id: 'mock-1',
              name: 'Rose Bouquet',
              sku: 'RB-001',
              barcode: '1234567890123',
              category: { id: 'cat-1', name: 'Bouquets' },
              sellingPrice: 29.99,
              costPrice: 15.00,
              taxRate: 0.05,
              availableStock: 10,
              isPerishable: true,
              trackBatch: false,
              imageUrl: '',
              batches: [],
            },
            {
              id: 'mock-2',
              name: 'Orchid Arrangement',
              sku: 'OA-002',
              barcode: '9876543210987',
              category: { id: 'cat-2', name: 'Arrangements' },
              sellingPrice: 49.99,
              costPrice: 25.00,
              taxRate: 0.05,
              availableStock: 5,
              isPerishable: true,
              trackBatch: false,
              imageUrl: '',
              batches: [],
            },
            {
              id: 'mock-3',
              name: 'Succulent Pot',
              sku: 'SP-003',
              barcode: '5555555555555',
              category: { id: 'cat-3', name: 'Plants' },
              sellingPrice: 19.99,
              costPrice: 8.00,
              taxRate: 0.05,
              availableStock: 20,
              isPerishable: false,
              trackBatch: false,
              imageUrl: '',
              batches: [],
            },
          ];
        }
        setProducts(normalizeProducts(prodItems));
        const custItems = Array.isArray(custRes) ? custRes : custRes.items ?? [];
        setCustomers(custItems);
      } catch (err) {
        console.error('POS data load failed:', err);
        setError('Failed to load POS data. Please refresh.');
        // Fallback: always show mock products if error
        setProducts(normalizeProducts([
          {
            id: 'mock-1',
            name: 'Rose Bouquet',
            sku: 'RB-001',
            barcode: '1234567890123',
            category: { id: 'cat-1', name: 'Bouquets' },
            sellingPrice: 29.99,
            costPrice: 15.00,
            taxRate: 0.05,
            availableStock: 10,
            isPerishable: true,
            trackBatch: false,
            imageUrl: '',
            batches: [],
          },
          {
            id: 'mock-2',
            name: 'Orchid Arrangement',
            sku: 'OA-002',
            barcode: '9876543210987',
            category: { id: 'cat-2', name: 'Arrangements' },
            sellingPrice: 49.99,
            costPrice: 25.00,
            taxRate: 0.05,
            availableStock: 5,
            isPerishable: true,
            trackBatch: false,
            imageUrl: '',
            batches: [],
          },
          {
            id: 'mock-3',
            name: 'Succulent Pot',
            sku: 'SP-003',
            barcode: '5555555555555',
            category: { id: 'cat-3', name: 'Plants' },
            sellingPrice: 19.99,
            costPrice: 8.00,
            taxRate: 0.05,
            availableStock: 20,
            isPerishable: false,
            trackBatch: false,
            imageUrl: '',
            batches: [],
          },
        ]));
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
    // Create order via API
    const createOrder = async () => {
      try {
        const orderPayload = {
          customerId: selectedCustomer?.id || '',
          deliveryDate: billingInfo.deliveryDate || '',
          deliveryAddress: billingInfo.deliveryAddress || '',
          recipientName: billingInfo.recipientName || '',
          recipientPhone: billingInfo.recipientPhone || '',
          cardMessage: billingInfo.cardMessage || '',
          deliveryPriority: billingInfo.deliveryPriority || 'NORMAL',
          timeSlot: billingInfo.timeSlot || '',
          orderSource: 'WALK_IN',
          orderIntent: orderType,
          pickupDate: billingInfo.pickupDate || '',
          pickupTimeSlot: billingInfo.pickupTimeSlot || '',
          deliveryFee: billingInfo.deliveryFee || 0,
          discountAmount: billingInfo.discountAmount || 0,
          internalNotes: billingInfo.internalNotes || '',
          items: state.items.map(item => ({
            productId: item.productId,
            productName: item.productName,
            quantity: item.quantity,
            unitPrice: item.unitPrice,
            specialInstructions: (item as any).notes || null,
          })),
          orderStatus:
            orderType === 'TAKE_NOW'
              ? 'COMPLETED'
              : 'AWAITING_FULFILLMENT',
        };
        const { createOrder } = await import('../../api/order.api');
        const createdOrder = await createOrder(orderPayload);
        setPaymentDrawerOpen(false);
        clearCart();
        setSelectedCustomer(null);
        if (orderType !== 'TAKE_NOW') {
          navigate(`/orders/${createdOrder.id}/fulfillment`);
        } else {
          showSnackbar(
            `Order completed - ${new Intl.NumberFormat('en-US', {
              style: 'currency',
              currency: 'USD',
            }).format(state.totals.grandTotal)}`,
            'success'
          );
        }
      } catch (err) {
        setPaymentDrawerOpen(false);
        showSnackbar('Order creation failed. Please try again.', 'error');
      }
    };
    createOrder();
  }, [state.items, state.totals, clearCart, showSnackbar, orderType, navigate]);

  const handlePartialSave = useCallback((payments: POSPaymentEntry[], billingInfo: POSBillingInfo, paidAmount: number, remainingAmount: number) => {
    // Create order with balance via API
    const createOrderWithBalance = async () => {
      try {
        const orderPayload = {
          customerId: selectedCustomer?.id || '',
          deliveryDate: billingInfo.deliveryDate || '',
          deliveryAddress: billingInfo.deliveryAddress || '',
          recipientName: billingInfo.recipientName || '',
          recipientPhone: billingInfo.recipientPhone || '',
          cardMessage: billingInfo.cardMessage || '',
          deliveryPriority: billingInfo.deliveryPriority || 'NORMAL',
          timeSlot: billingInfo.timeSlot || '',
          orderSource: 'WALK_IN',
          orderIntent: orderType,
          pickupDate: billingInfo.pickupDate || '',
          pickupTimeSlot: billingInfo.pickupTimeSlot || '',
          deliveryFee: billingInfo.deliveryFee || 0,
          discountAmount: billingInfo.discountAmount || 0,
          internalNotes: billingInfo.internalNotes || '',
          items: state.items.map(item => ({
            productId: item.productId,
            productName: item.productName,
            quantity: item.quantity,
            unitPrice: item.unitPrice,
            specialInstructions: (item as any).notes || null,
          })),
        };
        const { createOrder } = await import('../../api/order.api');
        const createdOrder = await createOrder(orderPayload);
        setPaymentDrawerOpen(false);
        clearCart();
        setSelectedCustomer(null);
        if (orderType !== 'TAKE_NOW') {
          navigate(`/orders/${createdOrder.id}/fulfillment`);
        }
        showSnackbar(`Order saved - ${new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(remainingAmount)} balance due`, 'info');
      } catch (err) {
        setPaymentDrawerOpen(false);
        showSnackbar('Order creation failed. Please try again.', 'error');
      }
    };
    createOrderWithBalance();
  }, [clearCart, showSnackbar, orderType, navigate]);

  const handleUpdateQty = useCallback((lineId: string, qty: number, product: Product) => {
    updateQty(lineId, qty, product);
  }, [updateQty]);

  const handleRemoveItem = useCallback((lineId: string) => {
    removeItem(lineId);
  }, [removeItem]);

  return (
    <div className="h-screen flex flex-col bg-gray-50 overflow-hidden">
      {/* Only one POS Header row (search + order intent) */}
      <Box
        display="flex"
        alignItems="center"
        justifyContent="space-between"
        gap={2}
        sx={{
          px: 2,
          py: 1.5,
          borderBottom: '1px solid #eee',
          bgcolor: 'background.paper',
          minHeight: 56,
        }}
      >
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
          searchProps={{
            placeholder: 'Search products or scan barcode (F2)',
            sx: {
              borderRadius: 8,
              minHeight: 48,
              fontSize: 18,
              background: '#fff',
              border: 'none',
            },
          }}
          orderTypeProps={{
            sx: {
              borderRadius: 8,
              minHeight: 48,
              background: '#fff',
              fontSize: 16,
              border: 'none',
            },
          }}
          locationProps={{
            sx: {
              borderRadius: 8,
              minHeight: 48,
              background: '#fff',
              fontSize: 16,
              border: 'none',
            },
          }}
          closeShiftProps={{
            sx: {
              borderRadius: 8,
              minHeight: 48,
              background: '#fff',
              fontSize: 16,
              border: 'none',
            },
          }}
        />
      </Box>

      {/* ...existing code... */}
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

      {/* ...existing code... */}

      {/* Main Content */}
      <Box display="flex" flexDirection="row" sx={{ flex: 1, overflow: 'hidden', width: '100%', gap: 2 }}>
        <Box sx={{ flexGrow: 8, minWidth: 0, display: 'flex', flexDirection: 'column' }}>
          <ProductGrid
            products={visibleProducts}
            searchQuery={searchQuery}
            selectedCategory={selectedCategory}
            onAddProduct={handleAddProduct}
            isLoading={isLoading}
          />
        </Box>
        <Box sx={{ flexGrow: 4, minWidth: 0, display: 'flex', flexDirection: 'column' }}>
          <POSCartPanel
            items={state.items}
            totals={state.totals}
            products={products}
            onUpdateQty={handleUpdateQty}
            onRemoveItem={handleRemoveItem}
            onPayment={handlePayment}
          />
        </Box>
      </Box>

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
        products={products}
        onAddProduct={addProduct}
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
        >
          {snackbar.message}
        </Alert>
      </Snackbar>
    </div>
  );
};

export default POSLayout;
