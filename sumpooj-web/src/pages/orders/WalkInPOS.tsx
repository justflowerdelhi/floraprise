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
  useTheme, Divider,
} from '@mui/material';
import {
  Search as SearchIcon,
  QrCodeScanner as BarcodeIcon,
  PauseCircle as HoldIcon,
  PlayCircle as ResumeIcon,
  Payment as PayIcon,
  ShoppingCart as CartIcon,
} from '@mui/icons-material';
import type { Product, ProductCategory } from './OrderTypes';
import { MOCK_PRODUCTS, PRODUCT_CATEGORIES } from './OrderMockData';
import { useCart } from '../cart/CartContext';
import CartTable from '../cart/CartTable';
import CartSummaryPanel from '../cart/CartSummaryPanel';
import { fmtCurrency } from '../cart/CartUtils';
import PaymentModal from '../payments/PaymentModal';

const WalkInPOS: React.FC = () => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';
  const bgColor = dk ? '#0f0f0f' : '#f8f9fa';

  const { state, addProduct, removeItem, updateQty, setDiscount, clearCart, holdOrder, resumeOrder, removeHeld, setOrderSource } = useCart();

  const [search, setSearch] = useState('');
  const [categoryFilter, setCategoryFilter] = useState<ProductCategory | ''>('');
  const [snackMsg, setSnackMsg] = useState('');
  const [holdDialogOpen, setHoldDialogOpen] = useState(false);
  const [holdLabel, setHoldLabel] = useState('');
  const [payModalOpen, setPayModalOpen] = useState(false);
  const [paymentOrderId, setPaymentOrderId] = useState('');
  const searchRef = useRef<HTMLInputElement>(null);

  // Set order source on mount
  useEffect(() => { setOrderSource('WALK_IN'); }, [setOrderSource]);

  // Product search (name, SKU, barcode)
  const filteredProducts = useMemo(() => {
    let list = MOCK_PRODUCTS;
    if (categoryFilter) list = list.filter((p) => p.category === categoryFilter);
    if (search.trim()) {
      const q = search.toLowerCase();
      list = list.filter(
        (p) =>
          p.name.toLowerCase().includes(q) ||
          p.sku.toLowerCase().includes(q) ||
          p.barcode.includes(q),
      );
    }
    return list;
  }, [search, categoryFilter]);

  const handleBarcodeSubmit = () => {
    const product = MOCK_PRODUCTS.find((p) => p.barcode === search.trim());
    if (product) {
      addProduct(product);
      setSearch('');
      setSnackMsg(`Added ${product.name}`);
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
    // Generate a temporary order ID for the payment session
    setPaymentOrderId(`pos_${Date.now()}`);
    setPayModalOpen(true);
  }, []);

  const handleFullyPaid = useCallback(() => {
    setPayModalOpen(false);
    setSnackMsg(`Order completed — ${fmtCurrency(state.totals.grandTotal)}`);
    clearCart();
  }, [clearCart, state.totals.grandTotal]);

  const ProductCard = ({ p }: { p: Product }) => (
    <Card
      elevation={dk ? 0 : 1}
      onClick={() => { addProduct(p); setSnackMsg(`Added ${p.name}`); }}
      sx={{
        cursor: 'pointer',
        bgcolor: dk ? '#1a1a2e' : '#fff',
        border: dk ? '1px solid rgba(255,255,255,0.06)' : '1px solid #eee',
        transition: 'all 0.15s',
        '&:hover': {
          transform: 'translateY(-2px)',
          boxShadow: dk ? '0 4px 16px rgba(0,0,0,0.4)' : '0 4px 16px rgba(0,0,0,0.08)',
          borderColor: theme.palette.primary.main,
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
            size="small"
            fullWidth
            placeholder="Search or scan barcode..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            onKeyDown={handleKeyDown}
            slotProps={{
              input: {
                startAdornment: (
                  <InputAdornment position="start">
                    <SearchIcon sx={{ fontSize: 20, color: dk ? 'rgba(255,255,255,0.4)' : undefined }} />
                  </InputAdornment>
                ),
                endAdornment: (
                  <InputAdornment position="end">
                    <IconButton size="small" onClick={handleBarcodeSubmit} title="Scan barcode">
                      <BarcodeIcon sx={{ fontSize: 20 }} />
                    </IconButton>
                  </InputAdornment>
                ),
              },
            }}
            sx={{
              mb: 1.5,
              '& .MuiOutlinedInput-root': dk
                ? { color: '#e0e0e0', '& fieldset': { borderColor: 'rgba(255,255,255,0.15)' } }
                : {},
            }}
          />

          {/* Category chips */}
          <Box sx={{ display: 'flex', gap: 0.5, flexWrap: 'wrap', mb: 1 }}>
            <Chip
              label="All"
              size="small"
              onClick={() => setCategoryFilter('')}
              variant={categoryFilter === '' ? 'filled' : 'outlined'}
              color={categoryFilter === '' ? 'primary' : 'default'}
              sx={{ fontSize: '0.7rem' }}
            />
            {PRODUCT_CATEGORIES.map((cat) => (
              <Chip
                key={cat}
                label={cat}
                size="small"
                onClick={() => setCategoryFilter(cat === categoryFilter ? '' : cat)}
                variant={categoryFilter === cat ? 'filled' : 'outlined'}
                color={categoryFilter === cat ? 'primary' : 'default'}
                sx={{ fontSize: '0.7rem' }}
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
        {/* Cart header + held orders */}
        <Box sx={{ p: 2, pb: 1, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
            <CartIcon sx={{ color: dk ? '#fdd835' : theme.palette.primary.main }} />
            <Typography variant="subtitle1" sx={{ fontWeight: 700 }}>
              Cart ({state.totals.itemCount} items)
            </Typography>
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
              size="small"
              variant="outlined"
              startIcon={<HoldIcon />}
              disabled={state.items.length === 0}
              onClick={() => setHoldDialogOpen(true)}
              sx={dk ? { borderColor: 'rgba(255,255,255,0.2)', color: '#e0e0e0' } : {}}
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
          />
        </Box>
      </Box>

      {/* ─── RIGHT: Summary + Pay ───────────────────────── */}
      <Box sx={{
        width: 280, minWidth: 260,
        borderLeft: `1px solid ${dk ? 'rgba(255,255,255,0.06)' : '#e0e0e0'}`,
        display: 'flex', flexDirection: 'column', p: 2, gap: 2,
      }}>
        <CartSummaryPanel totals={state.totals} orderSource="WALK_IN" />

        <Divider sx={{ borderColor: dk ? 'rgba(255,255,255,0.06)' : undefined }} />

        <Button
          variant="contained"
          size="large"
          fullWidth
          startIcon={<PayIcon />}
          disabled={state.items.length === 0}
          onClick={handleOpenPay}
          sx={{
            py: 1.5, fontWeight: 800, fontSize: '1rem',
            bgcolor: dk ? '#fdd835' : undefined,
            color: dk ? '#000' : undefined,
            '&:hover': { bgcolor: dk ? '#fbc02d' : undefined },
            '&.Mui-disabled': {
              bgcolor: dk ? 'rgba(255,255,255,0.08)' : undefined,
              color: dk ? 'rgba(255,255,255,0.3)' : undefined,
            },
          }}
        >
          Pay {state.totals.grandTotal > 0 ? fmtCurrency(state.totals.grandTotal) : ''}
        </Button>

        <Button
          variant="outlined"
          size="small"
          fullWidth
          color="error"
          disabled={state.items.length === 0}
          onClick={() => { clearCart(); setSnackMsg('Cart cleared'); }}
        >
          Clear Cart
        </Button>
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
      <PaymentModal
        open={payModalOpen}
        onClose={() => setPayModalOpen(false)}
        orderId={paymentOrderId}
        grandTotal={state.totals.grandTotal}
        onFullyPaid={handleFullyPaid}
      />

      {/* ─── Snackbar ───────────────────────────────────── */}
      <Snackbar
        open={!!snackMsg}
        autoHideDuration={2000}
        onClose={() => setSnackMsg('')}
        anchorOrigin={{ vertical: 'bottom', horizontal: 'center' }}
      >
        <Alert severity="success" variant="filled" onClose={() => setSnackMsg('')}>
          {snackMsg}
        </Alert>
      </Snackbar>
    </Box>
  );
};

export default WalkInPOS;
