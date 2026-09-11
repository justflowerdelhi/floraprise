/**
 * RetailPOSPage.tsx — Floraprise ERP Retail POS Main Screen
 *
 * Dedicated Retail View checkout interface:
 * - Florist-tailored 2-column layout (Product Catalog Grid + Fast Cart Panel)
 * - Shift enforcement & quick drawer management
 * - Fast barcode scanning & keyboard shortcuts (F2 Search, F4 Clear, F9 Pay)
 * - Instant tender checkout (Cash, UPI, Card, Split) with Change Due calculation
 * - Non-blocking thermal receipt printing
 * - Seamless view continuity with ERP Professional POS
 */

import React, { useState, useEffect, useCallback, useRef } from 'react';
import {
  Box,
  Snackbar,
  Alert,
  useTheme,
} from '@mui/material';
import { useShift } from '../ShiftContext';
import { useLocation as useLocationCtx } from '../../../core/location/LocationContext';
import ShiftOpenModal from '../ShiftOpenModal';
import ShiftCloseDrawer from '../ShiftCloseDrawer';
import RetailPOSShiftBar from './RetailPOSShiftBar';
import RetailPOSProductGrid from './RetailPOSProductGrid';
import RetailPOSCart from './RetailPOSCart';
import RetailPOSPaymentModal from './RetailPOSPaymentModal';
import type {
  RetailPOSProduct,
  RetailPOSCartItem,
  RetailPOSCustomer,
  OrderDto,
} from './retailPos.api';
import { fetchRetailPOSCatalog } from './retailPos.api';

export const RetailPOSPage: React.FC = () => {
  const theme = useTheme();
  const { activeShift, loading: shiftLoading } = useShift();
  const { currentLocationId } = useLocationCtx();

  // Catalog State
  const [products, setProducts] = useState<RetailPOSProduct[]>([]);
  const [catalogLoading, setCatalogLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCategory, setSelectedCategory] = useState('All');

  // Cart State
  const [cartItems, setCartItems] = useState<RetailPOSCartItem[]>([]);
  const [customer, setCustomer] = useState<RetailPOSCustomer | null>(null);
  const [orderIntent, setOrderIntent] = useState<'TAKE_NOW' | 'PICKUP_LATER'>('TAKE_NOW');
  const [discountAmount, setDiscountAmount] = useState(0);

  // Modals & Drawers
  const [checkoutOpen, setCheckoutOpen] = useState(false);
  const [showShiftOpenModal, setShowShiftOpenModal] = useState(false);

  // Notifications
  const [snackbar, setSnackbar] = useState<{
    open: boolean;
    message: string;
    severity: 'success' | 'error' | 'info';
  }>({
    open: false,
    message: '',
    severity: 'success',
  });

  // Load product catalog
  const loadCatalog = useCallback(async () => {
    try {
      setCatalogLoading(true);
      const items = await fetchRetailPOSCatalog(currentLocationId);
      setProducts(items);
    } catch (err) {
      console.error('[RetailPOS] Failed to load catalog:', err);
      setSnackbar({
        open: true,
        message: 'Failed to load product catalog.',
        severity: 'error',
      });
    } finally {
      setCatalogLoading(false);
    }
  }, [currentLocationId]);

  useEffect(() => {
    loadCatalog();
  }, [loadCatalog]);

  // Add product to cart
  const handleAddToCart = useCallback((product: RetailPOSProduct) => {
    setCartItems((prev) => {
      const existingIdx = prev.findIndex((item) => item.product.id === product.id);
      if (existingIdx >= 0) {
        const updated = [...prev];
        const item = updated[existingIdx];
        updated[existingIdx] = {
          ...item,
          quantity: item.quantity + 1,
          lineTotal: (item.quantity + 1) * item.unitPrice,
        };
        return updated;
      }
      return [
        ...prev,
        {
          product,
          quantity: 1,
          unitPrice: product.price,
          lineTotal: product.price,
        },
      ];
    });
  }, []);

  // Update line item quantity
  const handleUpdateQuantity = useCallback((productId: string, quantity: number) => {
    if (quantity <= 0) {
      setCartItems((prev) => prev.filter((item) => item.product.id !== productId));
    } else {
      setCartItems((prev) =>
        prev.map((item) =>
          item.product.id === productId
            ? { ...item, quantity, lineTotal: quantity * item.unitPrice }
            : item,
        ),
      );
    }
  }, []);

  // Remove line item
  const handleRemoveItem = useCallback((productId: string) => {
    setCartItems((prev) => prev.filter((item) => item.product.id !== productId));
  }, []);

  // Clear cart
  const handleClearCart = useCallback(() => {
    setCartItems([]);
    setDiscountAmount(0);
  }, []);

  // Sale completed successfully
  const handleSaleSuccess = useCallback(
    (order: OrderDto) => {
      setSnackbar({
        open: true,
        message: `Order #${order?.orderNumber || order?.id?.slice(0, 8) || 'Confirmed'} completed successfully!`,
        severity: 'success',
      });
      handleClearCart();
      setCustomer(null);
      // Refresh catalog in background to update live stock counts
      loadCatalog();
    },
    [handleClearCart, loadCatalog],
  );

  // Global Barcode Scanning & Keyboard Shortcuts
  const barcodeBufferRef = useRef('');
  const lastKeyTimeRef = useRef(0);

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      // Shortcuts
      if (e.key === 'F4') {
        e.preventDefault();
        handleClearCart();
        return;
      }
      if (e.key === 'F9') {
        e.preventDefault();
        if (cartItems.length > 0 && activeShift) {
          setCheckoutOpen(true);
        }
        return;
      }

      // Barcode Scanner Listener: rapid keystrokes (< 50ms interval) ending with Enter
      const now = Date.now();
      const timeSinceLast = now - lastKeyTimeRef.current;
      lastKeyTimeRef.current = now;

      // Ignore input elements to avoid typing collisions
      const activeTag = (document.activeElement as HTMLElement)?.tagName?.toLowerCase();
      const isInput = activeTag === 'input' || activeTag === 'textarea';

      if (e.key === 'Enter') {
        const barcode = barcodeBufferRef.current.trim();
        barcodeBufferRef.current = '';
        if (barcode.length >= 3) {
          const matched = products.find(
            (p) =>
              (p.barcode && p.barcode.toLowerCase() === barcode.toLowerCase()) ||
              p.sku.toLowerCase() === barcode.toLowerCase(),
          );
          if (matched) {
            e.preventDefault();
            handleAddToCart(matched);
            setSnackbar({
              open: true,
              message: `Scanned: ${matched.name}`,
              severity: 'info',
            });
          }
        }
        return;
      }

      // If typed rapidly and is alphanumeric
      if (e.key.length === 1 && !e.ctrlKey && !e.altKey && !e.metaKey) {
        if (timeSinceLast > 100 && !isInput) {
          barcodeBufferRef.current = e.key;
        } else if (timeSinceLast <= 100) {
          barcodeBufferRef.current += e.key;
        }
      }
    };

    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [products, cartItems, activeShift, handleAddToCart, handleClearCart]);

  const isShiftOpen = Boolean(activeShift);

  return (
    <Box
      sx={{
        display: 'flex',
        flexDirection: 'column',
        height: 'calc(100vh - 84px)',
        p: { xs: 1, sm: 2 },
        bgcolor: 'background.default',
        boxSizing: 'border-box',
        overflow: 'hidden',
      }}
    >
      {/* 1. Header Shift & Operational Bar */}
      <RetailPOSShiftBar
        onOpenShiftModal={() => setShowShiftOpenModal(true)}
        onRefreshCatalog={loadCatalog}
        catalogLoading={catalogLoading}
      />

      {/* 2. Main POS Workspace: Product Grid (Left/Center) + Cart Panel (Right) */}
      <Box
        sx={{
          display: 'grid',
          gridTemplateColumns: { xs: '1fr', md: '1.4fr 1fr', lg: '1.6fr 1fr' },
          gap: 2,
          flex: 1,
          minHeight: 0,
          overflow: 'hidden',
        }}
      >
        {/* Left Column: Product Catalog Grid */}
        <Box sx={{ minHeight: 0, overflow: 'hidden' }}>
          <RetailPOSProductGrid
            products={products}
            loading={catalogLoading}
            onAddToCart={handleAddToCart}
            searchQuery={searchQuery}
            onSearchChange={setSearchQuery}
            selectedCategory={selectedCategory}
            onCategoryChange={setSelectedCategory}
          />
        </Box>

        {/* Right Column: Cart & Summary Panel */}
        <Box sx={{ minHeight: 0, overflow: 'hidden' }}>
          <RetailPOSCart
            cartItems={cartItems}
            onUpdateQuantity={handleUpdateQuantity}
            onRemoveItem={handleRemoveItem}
            onClearCart={handleClearCart}
            customer={customer}
            onSelectCustomer={setCustomer}
            orderIntent={orderIntent}
            onSelectOrderIntent={setOrderIntent}
            discountAmount={discountAmount}
            onDiscountChange={setDiscountAmount}
            onOpenCheckout={() => setCheckoutOpen(true)}
            isShiftOpen={isShiftOpen}
          />
        </Box>
      </Box>

      {/* 3. Fast Payment Modal */}
      <RetailPOSPaymentModal
        open={checkoutOpen}
        onClose={() => setCheckoutOpen(false)}
        cartItems={cartItems}
        customer={customer}
        locationId={currentLocationId || ''}
        orderIntent={orderIntent}
        discountAmount={discountAmount}
        onSaleSuccess={handleSaleSuccess}
      />

      {/* 4. Shift Guards & Drawers */}
      <ShiftOpenModal />
      <ShiftCloseDrawer />

      {/* 5. Notification Snackbar */}
      <Snackbar
        open={snackbar.open}
        autoHideDuration={4000}
        onClose={() => setSnackbar((prev) => ({ ...prev, open: false }))}
        anchorOrigin={{ vertical: 'bottom', horizontal: 'center' }}
      >
        <Alert
          severity={snackbar.severity}
          onClose={() => setSnackbar((prev) => ({ ...prev, open: false }))}
          sx={{ width: '100%', fontWeight: 600, borderRadius: 2 }}
        >
          {snackbar.message}
        </Alert>
      </Snackbar>
    </Box>
  );
};

export default RetailPOSPage;
