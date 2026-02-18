/**
 * PhoneOrder.tsx — Phone order entry with required customer info + shared cart
 *
 * Requires: customer name, phone, delivery date, delivery address, card message
 * Same cart engine, orderSource = "PHONE". Terminal-ready payment via PaymentModal.
 */
import React, { useState, useMemo, useEffect, useCallback } from 'react';
import {
  Box, Typography, TextField, Button, Grid, Chip, Card, CardContent,
  InputAdornment, Snackbar, Alert, MenuItem, Divider,
  useTheme, alpha,
} from '@mui/material';
import type { SxProps, Theme } from '@mui/material/styles';
import {
  Search as SearchIcon,
  Phone as PhoneIcon,
  Person as PersonIcon,
  CalendarToday as CalendarIcon,
  LocationOn as LocationIcon,
  Message as MessageIcon,
  Send as SendIcon,
  Celebration as OccasionIcon,
  Payment as PayIcon,
} from '@mui/icons-material';
import type { ProductCategory } from './OrderTypes';
import { MOCK_PRODUCTS, PRODUCT_CATEGORIES } from './OrderMockData';
import { OCCASIONS } from './OrderTypes';
import { useCart } from '../cart/CartContext';
import CartTable from '../cart/CartTable';
import CartSummaryPanel from '../cart/CartSummaryPanel';
import { fmtCurrency } from '../cart/CartUtils';
import PaymentModal from '../payments/PaymentModal';

const PhoneOrder: React.FC = () => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';
  const bgColor = dk ? '#0f0f0f' : '#f8f9fa';

  const { state, addProduct, removeItem, updateQty, setDiscount, clearCart, setOrderSource } = useCart();

  // Customer info
  const [customerName, setCustomerName]       = useState('');
  const [customerPhone, setCustomerPhone]     = useState('');
  const [deliveryDate, setDeliveryDate]       = useState('');
  const [deliveryAddress, setDeliveryAddress] = useState('');
  const [cardMessage, setCardMessage]         = useState('');
  const [occasion, setOccasion]               = useState('');

  // Product search
  const [search, setSearch] = useState('');
  const [categoryFilter, setCategoryFilter] = useState<ProductCategory | ''>('');
  const [snackMsg, setSnackMsg] = useState('');
  const [payModalOpen, setPayModalOpen] = useState(false);
  const [paymentOrderId, setPaymentOrderId] = useState('');

  useEffect(() => { setOrderSource('PHONE'); }, [setOrderSource]);

  const filteredProducts = useMemo(() => {
    let list = MOCK_PRODUCTS;
    if (categoryFilter) list = list.filter((p) => p.category === categoryFilter);
    if (search.trim()) {
      const q = search.toLowerCase();
      list = list.filter(
        (p) => p.name.toLowerCase().includes(q) || p.sku.toLowerCase().includes(q),
      );
    }
    return list;
  }, [search, categoryFilter]);

  const fieldSx: SxProps<Theme> = dk
    ? {
        '& .MuiOutlinedInput-root': {
          color: '#e0e0e0',
          '& fieldset': { borderColor: 'rgba(255,255,255,0.15)' },
          '&:hover fieldset': { borderColor: 'rgba(255,255,255,0.3)' },
          '&.Mui-focused fieldset': { borderColor: theme.palette.primary.main },
        },
        '& .MuiInputLabel-root': { color: 'rgba(255,255,255,0.5)' },
      }
    : {};

  const isFormValid = customerName.trim() && customerPhone.trim() && deliveryDate && deliveryAddress.trim();

  const resetForm = useCallback(() => {
    clearCart();
    setCustomerName('');
    setCustomerPhone('');
    setDeliveryDate('');
    setDeliveryAddress('');
    setCardMessage('');
    setOccasion('');
  }, [clearCart]);

  const handleSubmit = () => {
    if (!isFormValid || state.items.length === 0) return;
    setSnackMsg(`Phone order created — ${fmtCurrency(state.totals.grandTotal)}`);
    resetForm();
  };

  const handleOpenPay = useCallback(() => {
    if (!isFormValid || state.items.length === 0) return;
    setPaymentOrderId(`phone_${Date.now()}`);
    setPayModalOpen(true);
  }, [isFormValid, state.items.length]);

  const handleFullyPaid = useCallback(() => {
    setPayModalOpen(false);
    setSnackMsg(`Phone order paid — ${fmtCurrency(state.totals.grandTotal)}`);
    resetForm();
  }, [resetForm, state.totals.grandTotal]);

  return (
    <Box sx={{ display: 'flex', height: '100vh', bgcolor: bgColor, overflow: 'hidden' }}>
      {/* ─── LEFT: Customer Info + Products ──────────────── */}
      <Box sx={{ width: 380, minWidth: 340, borderRight: `1px solid ${dk ? 'rgba(255,255,255,0.06)' : '#e0e0e0'}`, display: 'flex', flexDirection: 'column', overflow: 'hidden' }}>
        <Box sx={{ p: 2, pb: 1 }}>
          <Typography variant="h6" sx={{ fontWeight: 800, mb: 2 }}>
            📞 Phone Order
          </Typography>

          {/* Customer info form */}
          <Grid container spacing={1.5}>
            <Grid size={{ xs: 12 }}>
              <TextField
                required size="small" fullWidth label="Customer Name" value={customerName}
                onChange={(e) => setCustomerName(e.target.value)}
                slotProps={{ input: { startAdornment: <InputAdornment position="start"><PersonIcon sx={{ fontSize: 18 }} /></InputAdornment> } }}
                sx={fieldSx}
              />
            </Grid>
            <Grid size={{ xs: 12 }}>
              <TextField
                required size="small" fullWidth label="Phone" value={customerPhone}
                onChange={(e) => setCustomerPhone(e.target.value)}
                slotProps={{ input: { startAdornment: <InputAdornment position="start"><PhoneIcon sx={{ fontSize: 18 }} /></InputAdornment> } }}
                sx={fieldSx}
              />
            </Grid>
            <Grid size={{ xs: 6 }}>
              <TextField
                required size="small" fullWidth label="Delivery Date" type="date" value={deliveryDate}
                onChange={(e) => setDeliveryDate(e.target.value)}
                slotProps={{ inputLabel: { shrink: true }, input: { startAdornment: <InputAdornment position="start"><CalendarIcon sx={{ fontSize: 18 }} /></InputAdornment> } }}
                sx={fieldSx}
              />
            </Grid>
            <Grid size={{ xs: 6 }}>
              <TextField
                select size="small" fullWidth label="Occasion" value={occasion}
                onChange={(e) => setOccasion(e.target.value)}
                slotProps={{ input: { startAdornment: <InputAdornment position="start"><OccasionIcon sx={{ fontSize: 18 }} /></InputAdornment> } }}
                sx={fieldSx}
              >
                <MenuItem value="">None</MenuItem>
                {OCCASIONS.map((o) => <MenuItem key={o} value={o}>{o}</MenuItem>)}
              </TextField>
            </Grid>
            <Grid size={{ xs: 12 }}>
              <TextField
                required size="small" fullWidth label="Delivery Address" value={deliveryAddress}
                onChange={(e) => setDeliveryAddress(e.target.value)} multiline rows={2}
                slotProps={{ input: { startAdornment: <InputAdornment position="start"><LocationIcon sx={{ fontSize: 18 }} /></InputAdornment> } }}
                sx={fieldSx}
              />
            </Grid>
            <Grid size={{ xs: 12 }}>
              <TextField
                size="small" fullWidth label="Card Message" value={cardMessage}
                onChange={(e) => setCardMessage(e.target.value)} multiline rows={2}
                slotProps={{ input: { startAdornment: <InputAdornment position="start"><MessageIcon sx={{ fontSize: 18 }} /></InputAdornment> } }}
                sx={fieldSx}
              />
            </Grid>
          </Grid>
        </Box>

        <Divider sx={{ my: 1.5, borderColor: dk ? 'rgba(255,255,255,0.06)' : undefined }} />

        {/* Product search */}
        <Box sx={{ px: 2 }}>
          <TextField
            size="small" fullWidth placeholder="Search products..."
            value={search} onChange={(e) => setSearch(e.target.value)}
            slotProps={{ input: { startAdornment: <InputAdornment position="start"><SearchIcon sx={{ fontSize: 18 }} /></InputAdornment> } }}
            sx={{ mb: 1, ...fieldSx }}
          />
          <Box sx={{ display: 'flex', gap: 0.5, flexWrap: 'wrap', mb: 1 }}>
            <Chip label="All" size="small" onClick={() => setCategoryFilter('')}
              variant={categoryFilter === '' ? 'filled' : 'outlined'} color={categoryFilter === '' ? 'primary' : 'default'}
              sx={{ fontSize: '0.65rem' }} />
            {PRODUCT_CATEGORIES.map((c) => (
              <Chip key={c} label={c} size="small" onClick={() => setCategoryFilter(c === categoryFilter ? '' : c)}
                variant={categoryFilter === c ? 'filled' : 'outlined'} color={categoryFilter === c ? 'primary' : 'default'}
                sx={{ fontSize: '0.65rem' }} />
            ))}
          </Box>
        </Box>

        {/* Product list */}
        <Box sx={{ flex: 1, overflow: 'auto', px: 2, pb: 2 }}>
          {filteredProducts.map((p) => (
            <Card
              key={p.id}
              elevation={0}
              onClick={() => { addProduct(p); setSnackMsg(`Added ${p.name}`); }}
              sx={{
                mb: 0.5, cursor: 'pointer', py: 0.5, px: 1.5,
                bgcolor: dk ? '#1a1a2e' : '#fff',
                border: dk ? '1px solid rgba(255,255,255,0.04)' : '1px solid #f0f0f0',
                '&:hover': { bgcolor: dk ? alpha('#fff', 0.05) : alpha('#000', 0.02), borderColor: theme.palette.primary.main },
              }}
            >
              <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <Box>
                  <Typography variant="body2" sx={{ fontWeight: 600, fontSize: '0.82rem' }}>{p.name}</Typography>
                  <Typography variant="caption" sx={{ color: dk ? 'rgba(255,255,255,0.4)' : 'text.disabled' }}>{p.sku}</Typography>
                </Box>
                <Typography variant="body2" sx={{ fontWeight: 700, color: dk ? '#fdd835' : theme.palette.primary.main }}>
                  {fmtCurrency(p.sellingPrice)}
                </Typography>
              </Box>
            </Card>
          ))}
        </Box>
      </Box>

      {/* ─── CENTER: Cart ───────────────────────────────── */}
      <Box sx={{ flex: 1, display: 'flex', flexDirection: 'column', overflow: 'hidden' }}>
        <Box sx={{ p: 2, pb: 1 }}>
          <Typography variant="subtitle1" sx={{ fontWeight: 700 }}>
            Order Items ({state.totals.itemCount})
          </Typography>
        </Box>
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

      {/* ─── RIGHT: Summary + Submit ────────────────────── */}
      <Box sx={{
        width: 280, minWidth: 260,
        borderLeft: `1px solid ${dk ? 'rgba(255,255,255,0.06)' : '#e0e0e0'}`,
        display: 'flex', flexDirection: 'column', p: 2, gap: 2,
      }}>
        <CartSummaryPanel totals={state.totals} orderSource="PHONE" />

        <Divider sx={{ borderColor: dk ? 'rgba(255,255,255,0.06)' : undefined }} />

        {/* Validation summary */}
        {!isFormValid && (
          <Card elevation={0} sx={{ bgcolor: dk ? alpha(theme.palette.warning.dark, 0.1) : alpha(theme.palette.warning.light, 0.2), border: `1px solid ${alpha(theme.palette.warning.main, 0.3)}`, borderRadius: 1 }}>
            <CardContent sx={{ py: 1, '&:last-child': { pb: 1 } }}>
              <Typography variant="caption" sx={{ fontWeight: 600, color: theme.palette.warning.main }}>
                Required fields:
              </Typography>
              {!customerName.trim() && <Typography variant="caption" display="block" color="text.secondary">• Customer name</Typography>}
              {!customerPhone.trim() && <Typography variant="caption" display="block" color="text.secondary">• Phone number</Typography>}
              {!deliveryDate && <Typography variant="caption" display="block" color="text.secondary">• Delivery date</Typography>}
              {!deliveryAddress.trim() && <Typography variant="caption" display="block" color="text.secondary">• Delivery address</Typography>}
            </CardContent>
          </Card>
        )}

        <Button
          variant="contained"
          size="large"
          fullWidth
          startIcon={<PayIcon />}
          disabled={!isFormValid || state.items.length === 0}
          onClick={handleOpenPay}
          sx={{
            py: 1.5, fontWeight: 800, fontSize: '0.95rem',
            bgcolor: dk ? '#fdd835' : undefined,
            color: dk ? '#000' : undefined,
            '&:hover': { bgcolor: dk ? '#fbc02d' : undefined },
            '&.Mui-disabled': {
              bgcolor: dk ? 'rgba(255,255,255,0.08)' : undefined,
              color: dk ? 'rgba(255,255,255,0.3)' : undefined,
            },
          }}
        >
          Pay Now {state.totals.grandTotal > 0 ? fmtCurrency(state.totals.grandTotal) : ''}
        </Button>

        <Button
          variant="outlined"
          size="small"
          fullWidth
          startIcon={<SendIcon />}
          disabled={!isFormValid || state.items.length === 0}
          onClick={handleSubmit}
          sx={dk ? { borderColor: 'rgba(255,255,255,0.2)', color: '#e0e0e0' } : {}}
        >
          Create Order (Pay Later)
        </Button>

        <Button variant="outlined" size="small" fullWidth color="error"
          disabled={state.items.length === 0}
          onClick={() => { clearCart(); setSnackMsg('Cart cleared'); }}
        >
          Clear Cart
        </Button>
      </Box>

      {/* ─── Payment Modal ──────────────────────────────── */}
      <PaymentModal
        open={payModalOpen}
        onClose={() => setPayModalOpen(false)}
        orderId={paymentOrderId}
        grandTotal={state.totals.grandTotal}
        onFullyPaid={handleFullyPaid}
      />

      <Snackbar open={!!snackMsg} autoHideDuration={2500} onClose={() => setSnackMsg('')}
        anchorOrigin={{ vertical: 'bottom', horizontal: 'center' }}>
        <Alert severity="success" variant="filled" onClose={() => setSnackMsg('')}>{snackMsg}</Alert>
      </Snackbar>
    </Box>
  );
};

export default PhoneOrder;
