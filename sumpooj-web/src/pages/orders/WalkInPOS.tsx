/**
 * WalkInPOS.tsx — Point of Sale for walk-in customers
 *
 * Layout: Left (product search + categories) | Center (cart) | Right (summary + pay)
 * Features: barcode input, category filter, FIFO auto-batch, hold/resume, terminal payment
 */
import React, { useState, useMemo, useRef, useEffect, useCallback } from 'react';
import {
  Box, Typography, TextField, InputAdornment, Button, Chip,
  Card, CardContent, Grid, IconButton, Snackbar, Alert,
  Dialog, DialogTitle, DialogContent, DialogActions,
  useTheme, Divider, FormControl, InputLabel, Select, MenuItem,
} from '@mui/material';
import {
  Search as SearchIcon,
  QrCodeScanner as BarcodeIcon,
  PauseCircle as HoldIcon,
  PlayCircle as ResumeIcon,
  Payment as PayIcon,
  ShoppingCart as CartIcon,
} from '@mui/icons-material';
import type { Product, ProductCategory, OrderType } from './OrderTypes';
import { MOCK_PRODUCTS, PRODUCT_CATEGORIES } from './OrderMockData';
import { useCart } from '../cart/CartContext';
import CartTable from '../cart/CartTable';
import CartSummaryPanel from '../cart/CartSummaryPanel';
import { fmtCurrency } from '../cart/CartUtils';
import PaymentModal from '../payments/PaymentModal';
import { useTenant } from '../../core/tenant/TenantContext';
import { MOCK_VENDOR_FLORISTS } from './WireMockData';
import CustomerSearchBar, { type SelectedCustomer } from './CustomerSearchBar';
import QuickCreateCustomerModal from './QuickCreateCustomerModal';

const WalkInPOS: React.FC = () => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';
  const bgColor = dk ? '#0f0f0f' : '#f8f9fa';

  const { hasFeature } = useTenant();
  const wireEnabled = hasFeature('WIRE_MANAGEMENT');

  const { state, addProduct, removeItem, updateQty, setDiscount, setLineDiscount, clearCart, holdOrder, resumeOrder, removeHeld, setOrderSource, setOrderDiscount, clearOrderDiscount } = useCart();

  const [search, setSearch] = useState('');
  const [categoryFilter, setCategoryFilter] = useState<ProductCategory | ''>('');
  const [snackMsg, setSnackMsg] = useState('');
  const [holdDialogOpen, setHoldDialogOpen] = useState(false);
  const [holdLabel, setHoldLabel] = useState('');
  const [payModalOpen, setPayModalOpen] = useState(false);
  const [paymentOrderId, setPaymentOrderId] = useState('');
  const searchRef = useRef<HTMLInputElement>(null);

  const [orderType, setOrderType] = useState<OrderType>('LOCAL');
  const [vendorId, setVendorId] = useState('');
  const [vendorAmount, setVendorAmount] = useState(0);
  const [wireFee, setWireFee] = useState(0);
  const [sourceNetwork, setSourceNetwork] = useState('');
  const [commissionPercent, setCommissionPercent] = useState(10);
  const [lastScanTime, setLastScanTime] = useState(0);

  // Customer selection state
  const [selectedCustomer, setSelectedCustomer] = useState<SelectedCustomer | null>(null);
  const [createCustomerOpen, setCreateCustomerOpen] = useState(false);
  const [prefillPhone, setPrefillPhone] = useState('');

  // Auto-focus search on mount
  useEffect(() => {
    searchRef.current?.focus();
  }, []);

  // Set order source on mount
  useEffect(() => { setOrderSource('WALK_IN'); }, [setOrderSource]);

  useEffect(() => {
    if (!wireEnabled && orderType !== 'LOCAL') {
      setOrderType('LOCAL');
    }
  }, [wireEnabled, orderType]);

  // Product search (name, SKU, barcode for non-perishables)
  const filteredProducts = useMemo(() => {
    let list = MOCK_PRODUCTS;
    if (categoryFilter) list = list.filter((p) => p.category === categoryFilter);
    if (search.trim()) {
      const q = search.toLowerCase();
      list = list.filter(
        (p) =>
          p.name.toLowerCase().includes(q) ||
          p.sku.toLowerCase().includes(q) ||
          (!!p.barcode && !p.isPerishable && p.barcode.includes(q)),
      );
    }
    return list;
  }, [search, categoryFilter]);

  const handleBarcodeSubmit = () => {
    // Prevent duplicate rapid scans (300ms debounce)
    const now = Date.now();
    if (now - lastScanTime < 300) return;
    setLastScanTime(now);

    const product = MOCK_PRODUCTS.find((p) => !p.isPerishable && p.barcode === search.trim());
    if (product) {
      addProduct(product);
      setSearch('');
      setSnackMsg(`Added ${product.name}`);
      // Keep focus in search for continuous scanning
      searchRef.current?.focus();
    }
  };

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter') handleBarcodeSubmit();
  };

  const handleHold = () => {
    if (state.items.length === 0) return;
    holdOrder(holdLabel || `POS Hold`, undefined);
    setHoldDialogOpen(false);
    setHoldLabel('');
    setSnackMsg('Order held');
  };

  const handleOpenPay = useCallback(() => {
    if (orderType === 'INCOMING_NETWORK') return;
    // Generate a temporary order ID for the payment session
    setPaymentOrderId(`pos_${Date.now()}`);
    setPayModalOpen(true);
  }, [orderType]);

  const handleFullyPaid = useCallback(() => {
    setPayModalOpen(false);
    setSnackMsg(`Order completed — ${fmtCurrency(state.totals.grandTotal)}`);
    clearCart();
  }, [clearCart, state.totals.grandTotal]);

  const selectedVendor = useMemo(
    () => MOCK_VENDOR_FLORISTS.find((vendor) => vendor.id === vendorId) ?? null,
    [vendorId],
  );

  const customerPaid = state.totals.grandTotal;
  const outgoingProfit = customerPaid - vendorAmount - wireFee;
  const netReceived = Math.round((customerPaid * (1 - commissionPercent / 100)) * 100) / 100;
  const incomingProfit = netReceived - state.totals.totalCost;
  const localProfit = customerPaid - state.totals.totalCost;
  const showPayment = orderType !== 'INCOMING_NETWORK';

  const ProductCard = ({ p }: { p: Product }) => (
    <Card
      elevation={dk ? 0 : 1}
      onClick={() => { addProduct(p); setSnackMsg(`Added ${p.name}`); }}
      sx={{
        cursor: 'pointer',
        bgcolor: dk ? '#1a1a2e' : '#fff',
        border: dk ? '1px solid rgba(255,255,255,0.06)' : '1px solid #eee',
        transition: 'all 0.15s ease-out',
        minHeight: 80,
        '&:hover': {
          transform: 'translateY(-3px)',
          boxShadow: dk ? '0 6px 20px rgba(0,0,0,0.5)' : '0 6px 20px rgba(0,0,0,0.1)',
          borderColor: theme.palette.primary.main,
        },
        '&:active': {
          transform: 'scale(0.98)',
        },
      }}
    >
      <CardContent sx={{ py: 1.5, '&:last-child': { pb: 1.5 } }}>
        <Typography variant="body2" sx={{ fontWeight: 700, fontSize: '0.82rem', mb: 0.3 }} noWrap>
          {p.name}
        </Typography>
        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <Typography variant="caption" sx={{ color: dk ? 'rgba(255,255,255,0.4)' : 'text.disabled' }}>
            {p.sku}
          </Typography>
          <Typography variant="body2" sx={{ fontWeight: 700, color: dk ? '#fdd835' : theme.palette.primary.main }}>
            {fmtCurrency(p.sellingPrice)}
          </Typography>
        </Box>
        <Box sx={{ display: 'flex', justifyContent: 'space-between', mt: 0.5 }}>
          <Chip label={p.category} size="small" sx={{ fontSize: '0.65rem', height: 20 }} />
          <Typography variant="caption" sx={{ color: p.availableStock < 10 ? theme.palette.error.main : 'text.secondary' }}>
            Stock: {p.availableStock}
          </Typography>
        </Box>
      </CardContent>
    </Card>
  );

  return (
    <Box sx={{ display: 'flex', height: '100vh', bgcolor: bgColor, overflow: 'hidden' }}>
      {/* ─── LEFT: Products ─────────────────────────────── */}
      <Box sx={{ width: 340, minWidth: 300, borderRight: `1px solid ${dk ? 'rgba(255,255,255,0.06)' : '#e0e0e0'}`, display: 'flex', flexDirection: 'column', overflow: 'hidden' }}>
        {/* Header */}
        <Box sx={{ p: 2, pb: 1 }}>
          <Typography variant="h6" sx={{ fontWeight: 800, mb: 1.5 }}>
            🌸 Walk-In POS
          </Typography>

          {/* Search / Barcode */}
          <TextField
            inputRef={searchRef}
            size="medium"
            fullWidth
            placeholder="Search or scan barcode..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            onKeyDown={handleKeyDown}
            slotProps={{
              input: {
                sx: { fontSize: '1rem', py: 0.5 },
                startAdornment: (
                  <InputAdornment position="start">
                    <SearchIcon sx={{ fontSize: 22, color: dk ? 'rgba(255,255,255,0.4)' : undefined }} />
                  </InputAdornment>
                ),
                endAdornment: (
                  <InputAdornment position="end">
                    <IconButton size="medium" onClick={handleBarcodeSubmit} title="Scan barcode" sx={{ mr: -0.5 }}>
                      <BarcodeIcon sx={{ fontSize: 22 }} />
                    </IconButton>
                  </InputAdornment>
                ),
              },
            }}
            sx={{
              mb: 1.5,
              '& .MuiOutlinedInput-root': {
                minHeight: 48,
                ...(dk ? { color: '#e0e0e0', '& fieldset': { borderColor: 'rgba(255,255,255,0.15)' } } : {}),
              },
            }}
          />

          {/* Category chips - Touch friendly */}
          <Box sx={{ display: 'flex', gap: 0.75, flexWrap: 'wrap', mb: 1 }}>
            <Chip
              label="All"
              size="medium"
              onClick={() => setCategoryFilter('')}
              variant={categoryFilter === '' ? 'filled' : 'outlined'}
              color={categoryFilter === '' ? 'primary' : 'default'}
              sx={{ fontSize: '0.8rem', height: 36, px: 1, fontWeight: 600 }}
            />
            {PRODUCT_CATEGORIES.map((cat) => (
              <Chip
                key={cat}
                label={cat}
                size="medium"
                onClick={() => setCategoryFilter(cat === categoryFilter ? '' : cat)}
                variant={categoryFilter === cat ? 'filled' : 'outlined'}
                color={categoryFilter === cat ? 'primary' : 'default'}
                sx={{ fontSize: '0.8rem', height: 36, px: 1, fontWeight: 600 }}
              />
            ))}
          </Box>
        </Box>

        {/* Product grid */}
        <Box sx={{ flex: 1, overflow: 'auto', px: 2, pb: 2 }}>
          <Grid container spacing={1}>
            {filteredProducts.map((p) => (
              <Grid key={p.id} size={{ xs: 12 }}>
                <ProductCard p={p} />
              </Grid>
            ))}
            {filteredProducts.length === 0 && (
              <Grid size={{ xs: 12 }}>
                <Typography variant="body2" color="text.secondary" sx={{ py: 4, textAlign: 'center' }}>
                  No products match
                </Typography>
              </Grid>
            )}
          </Grid>
        </Box>
      </Box>

      {/* ─── CENTER: Cart ───────────────────────────────── */}
      <Box sx={{ flex: 1, display: 'flex', flexDirection: 'column', overflow: 'hidden' }}>
        {/* Customer Selection - Fast lookup */}
        <Box sx={{ px: 2, pt: 2, pb: 1 }}>
          <CustomerSearchBar
            selectedCustomer={selectedCustomer}
            onSelectCustomer={(customer) => {
              setSelectedCustomer(customer);
              if (customer) setSnackMsg(`Customer: ${customer.name}`);
            }}
            onCreateNew={(phone) => {
              setPrefillPhone(phone ?? '');
              setCreateCustomerOpen(true);
            }}
          />
        </Box>

        {/* Cart header + held orders */}
        <Box sx={{ p: 2, pb: 1, pt: 0, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
              <CartIcon sx={{ color: dk ? '#fdd835' : theme.palette.primary.main }} />
              <Typography variant="subtitle1" sx={{ fontWeight: 700 }}>
                Cart ({state.totals.itemCount} items)
              </Typography>
            </Box>
            {/* Selected customer badge */}
            {selectedCustomer && (
              <Chip
                label={selectedCustomer.name}
                size="small"
                color="success"
                variant="outlined"
                onDelete={() => setSelectedCustomer(null)}
                sx={{
                  fontWeight: 600,
                  fontSize: '0.75rem',
                  height: 26,
                  '& .MuiChip-deleteIcon': { fontSize: '1rem' },
                }}
              />
            )}
          </Box>
          <Box sx={{ display: 'flex', gap: 1 }}>
            {state.heldOrders.length > 0 && (
              <Chip
                icon={<ResumeIcon />}
                label={`${state.heldOrders.length} Held`}
                color="info"
                size="small"
                variant="outlined"
                sx={{ fontWeight: 600 }}
              />
            )}
            <Button
              size="medium"
              variant="outlined"
              startIcon={<HoldIcon />}
              disabled={state.items.length === 0}
              onClick={() => setHoldDialogOpen(true)}
              sx={{
                minHeight: 40,
                fontWeight: 600,
                ...(dk ? { borderColor: 'rgba(255,255,255,0.2)', color: '#e0e0e0' } : {}),
              }}
            >
              Hold
            </Button>
          </Box>
        </Box>

        {/* Held orders bar */}
        {state.heldOrders.length > 0 && (
          <Box sx={{ px: 2, pb: 1, display: 'flex', gap: 1, flexWrap: 'wrap' }}>
            {state.heldOrders.map((h) => (
              <Chip
                key={h.id}
                label={`${h.label} · ${fmtCurrency(h.totals.grandTotal)}`}
                color="info"
                size="small"
                onClick={() => { resumeOrder(h.id); setSnackMsg('Order resumed'); }}
                onDelete={() => removeHeld(h.id)}
                sx={{ fontWeight: 600, cursor: 'pointer' }}
              />
            ))}
          </Box>
        )}

        {/* Cart table */}
        <Box sx={{ flex: 1, overflow: 'auto', px: 2 }}>
          <CartTable
            items={state.items}
            products={MOCK_PRODUCTS}
            isPriceEditable={state.isPriceEditable}
            onUpdateQty={updateQty}
            onRemove={removeItem}
            onSetDiscount={setDiscount}
            onSetLineDiscount={setLineDiscount}
          />
        </Box>
      </Box>

      {/* ─── RIGHT: Summary + Pay ───────────────────────── */}
      <Box sx={{
        width: 300, minWidth: 280,
        borderLeft: `1px solid ${dk ? 'rgba(255,255,255,0.06)' : '#e0e0e0'}`,
        display: 'flex', flexDirection: 'column', overflow: 'hidden',
      }}>
        {/* Scrollable content area */}
        <Box sx={{ flex: 1, overflow: 'auto', p: 2, pb: 2, display: 'flex', flexDirection: 'column', gap: 2 }}>
        {wireEnabled && (
          <Card
            elevation={dk ? 0 : 1}
            sx={{
              bgcolor: dk ? '#1a1a2e' : '#fff',
              border: dk ? '1px solid rgba(255,255,255,0.08)' : 'none',
              borderRadius: 2,
            }}
          >
            <CardContent sx={{ pb: 2 }}>
              <Typography variant="subtitle2" sx={{ fontWeight: 700, mb: 1 }}>
                Order Type
              </Typography>
              <FormControl size="small" fullWidth>
                <InputLabel>Order Type</InputLabel>
                <Select
                  value={orderType}
                  label="Order Type"
                  onChange={(e) => setOrderType(e.target.value as OrderType)}
                >
                  <MenuItem value="LOCAL">Local</MenuItem>
                  <MenuItem value="OUTGOING_NETWORK">Outgoing Network</MenuItem>
                  <MenuItem value="INCOMING_NETWORK">Incoming Network</MenuItem>
                </Select>
              </FormControl>
            </CardContent>
          </Card>
        )}

        {wireEnabled && orderType === 'OUTGOING_NETWORK' && (
          <Card
            elevation={dk ? 0 : 1}
            sx={{
              bgcolor: dk ? '#1a1a2e' : '#fff',
              border: dk ? '1px solid rgba(255,255,255,0.08)' : 'none',
              borderRadius: 2,
            }}
          >
            <CardContent sx={{ pb: 2 }}>
              <Typography variant="subtitle2" sx={{ fontWeight: 700, mb: 1 }}>
                Outgoing Network Details
              </Typography>
              <FormControl size="small" fullWidth sx={{ mb: 1 }}>
                <InputLabel>Vendor Florist</InputLabel>
                <Select
                  value={vendorId}
                  label="Vendor Florist"
                  onChange={(e) => setVendorId(e.target.value)}
                >
                  {MOCK_VENDOR_FLORISTS.filter((v) => v.isActive).map((vendor) => (
                    <MenuItem key={vendor.id} value={vendor.id}>
                      {vendor.name} ({vendor.city})
                    </MenuItem>
                  ))}
                </Select>
              </FormControl>
              <TextField
                size="small"
                fullWidth
                type="number"
                label="Amount Sent to Vendor"
                value={vendorAmount}
                onChange={(e) => setVendorAmount(Number(e.target.value))}
                sx={{ mb: 1 }}
              />
              <TextField
                size="small"
                fullWidth
                type="number"
                label="Wire Fee"
                value={wireFee}
                onChange={(e) => setWireFee(Number(e.target.value))}
              />
              <Typography variant="caption" color="text.secondary" sx={{ display: 'block', mt: 1 }}>
                Inventory will not be deducted for outgoing network orders.
              </Typography>
            </CardContent>
          </Card>
        )}

        {wireEnabled && orderType === 'INCOMING_NETWORK' && (
          <Card
            elevation={dk ? 0 : 1}
            sx={{
              bgcolor: dk ? '#1a1a2e' : '#fff',
              border: dk ? '1px solid rgba(255,255,255,0.08)' : 'none',
              borderRadius: 2,
            }}
          >
            <CardContent sx={{ pb: 2 }}>
              <Typography variant="subtitle2" sx={{ fontWeight: 700, mb: 1 }}>
                Incoming Network Details
              </Typography>
              <TextField
                size="small"
                fullWidth
                label="Source Network"
                value={sourceNetwork}
                onChange={(e) => setSourceNetwork(e.target.value)}
                sx={{ mb: 1 }}
              />
              <TextField
                size="small"
                fullWidth
                type="number"
                label="Commission %"
                value={commissionPercent}
                onChange={(e) => setCommissionPercent(Number(e.target.value))}
              />
              <Typography variant="caption" color="text.secondary" sx={{ display: 'block', mt: 1 }}>
                Customer payment is handled by the network.
              </Typography>
            </CardContent>
          </Card>
        )}

        <CartSummaryPanel
          totals={state.totals}
          orderSource="WALK_IN"
          orderDiscount={state.orderDiscount}
          onApplyDiscount={setOrderDiscount}
          onRemoveDiscount={clearOrderDiscount}
        />

        <Card
          elevation={dk ? 0 : 1}
          sx={{
            bgcolor: dk ? '#1a1a2e' : '#fff',
            border: dk ? '1px solid rgba(255,255,255,0.08)' : 'none',
            borderRadius: 2,
          }}
        >
          <CardContent sx={{ pb: 2 }}>
            <Typography variant="subtitle2" sx={{ fontWeight: 700, mb: 1 }}>
              Profit Summary
            </Typography>
            <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 0.5 }}>
              <Typography variant="body2" color="text.secondary">Customer Paid</Typography>
              <Typography variant="body2" sx={{ fontWeight: 700 }}>{fmtCurrency(customerPaid)}</Typography>
            </Box>
            {orderType === 'OUTGOING_NETWORK' && (
              <>
                <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 0.5 }}>
                  <Typography variant="body2" color="text.secondary">Vendor Amount</Typography>
                  <Typography variant="body2" sx={{ fontWeight: 700 }}>{fmtCurrency(vendorAmount)}</Typography>
                </Box>
                <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 0.5 }}>
                  <Typography variant="body2" color="text.secondary">Wire Fee</Typography>
                  <Typography variant="body2" sx={{ fontWeight: 700 }}>{fmtCurrency(wireFee)}</Typography>
                </Box>
              </>
            )}
            {orderType === 'INCOMING_NETWORK' && (
              <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 0.5 }}>
                <Typography variant="body2" color="text.secondary">Net Received</Typography>
                <Typography variant="body2" sx={{ fontWeight: 700 }}>{fmtCurrency(netReceived)}</Typography>
              </Box>
            )}
            <Divider sx={{ my: 1, borderColor: dk ? 'rgba(255,255,255,0.08)' : undefined }} />
            <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
              <Typography variant="body2" color="text.secondary">Estimated Profit</Typography>
              <Typography variant="body2" sx={{ fontWeight: 800, color: theme.palette.success.main }}>
                {fmtCurrency(
                  orderType === 'OUTGOING_NETWORK'
                    ? outgoingProfit
                    : orderType === 'INCOMING_NETWORK'
                      ? incomingProfit
                      : localProfit
                )}
              </Typography>
            </Box>
            {orderType === 'OUTGOING_NETWORK' && selectedVendor && (
              <Typography variant="caption" color="text.secondary" sx={{ display: 'block', mt: 1 }}>
                Vendor: {selectedVendor.name}
              </Typography>
            )}
          </CardContent>
        </Card>
        </Box>

        {/* Sticky Total + Pay Section */}
        <Box
          sx={{
            p: 2,
            borderTop: `1px solid ${dk ? 'rgba(255,255,255,0.08)' : '#e0e0e0'}`,
            bgcolor: dk ? '#0a0a0f' : '#fafafa',
          }}
        >
          {/* Total Display */}
          <Box
            sx={{
              display: 'flex',
              justifyContent: 'space-between',
              alignItems: 'center',
              mb: 2,
              p: 2,
              borderRadius: 2,
              bgcolor: dk ? 'rgba(255,255,255,0.04)' : '#fff',
              border: `1px solid ${dk ? 'rgba(255,255,255,0.08)' : '#e0e0e0'}`,
            }}
          >
            <Typography variant="body1" sx={{ fontWeight: 600, color: dk ? 'rgba(255,255,255,0.7)' : 'text.secondary' }}>
              Total
            </Typography>
            <Typography
              sx={{
                fontWeight: 800,
                fontSize: '1.875rem',
                letterSpacing: '-0.02em',
                color: dk ? '#fdd835' : theme.palette.primary.main,
              }}
            >
              {fmtCurrency(state.totals.grandTotal)}
            </Typography>
          </Box>

          {showPayment ? (
            <Button
              variant="contained"
              size="large"
              fullWidth
              startIcon={<PayIcon />}
              disabled={state.items.length === 0}
              onClick={handleOpenPay}
              sx={{
                py: 2, fontWeight: 800, fontSize: '1.1rem',
                minHeight: 56,
                bgcolor: dk ? '#fdd835' : undefined,
                color: dk ? '#000' : undefined,
                transition: 'all 0.15s',
                '&:hover': {
                  bgcolor: dk ? '#fbc02d' : undefined,
                  transform: 'translateY(-2px)',
                  boxShadow: '0 4px 16px rgba(0,0,0,0.2)',
                },
                '&:active': {
                  transform: 'scale(0.98)',
                },
                '&.Mui-disabled': {
                  bgcolor: dk ? 'rgba(255,255,255,0.08)' : undefined,
                  color: dk ? 'rgba(255,255,255,0.3)' : undefined,
                },
              }}
            >
              Pay {state.totals.grandTotal > 0 ? fmtCurrency(state.totals.grandTotal) : ''}
            </Button>
          ) : (
            <Alert severity="info" sx={{ fontSize: '0.85rem' }}>
              Customer payment is handled by the wire network.
            </Alert>
          )}

          <Button
            variant="outlined"
            size="small"
            fullWidth
            color="error"
            disabled={state.items.length === 0}
            onClick={() => { clearCart(); setSnackMsg('Cart cleared'); }}
            sx={{ mt: 1.5, minHeight: 40 }}
          >
            Clear Cart
          </Button>
        </Box>
      </Box>

      {/* ─── Hold Dialog ────────────────────────────────── */}
      <Dialog open={holdDialogOpen} onClose={() => setHoldDialogOpen(false)} maxWidth="xs" fullWidth>
        <DialogTitle sx={{ fontWeight: 700 }}>Hold Order</DialogTitle>
        <DialogContent>
          <TextField
            autoFocus fullWidth size="small" label="Label (optional)"
            value={holdLabel} onChange={(e) => setHoldLabel(e.target.value)}
            placeholder="e.g., Customer name"
            sx={{ mt: 1 }}
          />
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setHoldDialogOpen(false)}>Cancel</Button>
          <Button variant="contained" onClick={handleHold}>Hold Order</Button>
        </DialogActions>
      </Dialog>

      {/* ─── Payment Modal (terminal-ready) ──────────── */}
      {showPayment && (
        <PaymentModal
          open={payModalOpen}
          onClose={() => setPayModalOpen(false)}
          orderId={paymentOrderId}
          grandTotal={state.totals.grandTotal}
          onFullyPaid={handleFullyPaid}
        />
      )}

      {/* ─── Quick Create Customer Modal ────────────── */}
      <QuickCreateCustomerModal
        open={createCustomerOpen}
        onClose={() => setCreateCustomerOpen(false)}
        prefillPhone={prefillPhone}
        onCreated={(customer) => {
          setSelectedCustomer(customer);
          setCreateCustomerOpen(false);
          setSnackMsg(`Customer created: ${customer.name}`);
          // Return focus to product search after customer added
          searchRef.current?.focus();
        }}
      />

      {/* ─── Snackbar ───────────────────────────────────── */}
      <Snackbar
        open={!!snackMsg}
        autoHideDuration={1500}
        onClose={() => setSnackMsg('')}
        anchorOrigin={{ vertical: 'bottom', horizontal: 'center' }}
        TransitionProps={{ timeout: { enter: 150, exit: 150 } }}
      >
        <Alert
          severity="success"
          variant="filled"
          onClose={() => setSnackMsg('')}
          sx={{ minWidth: 200, fontWeight: 600 }}
        >
          {snackMsg}
        </Alert>
      </Snackbar>
    </Box>
  );
};

export default WalkInPOS;
