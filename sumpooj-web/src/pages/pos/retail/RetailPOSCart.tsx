/**
 * RetailPOSCart.tsx — Florist Cart & Order Summary for Retail POS
 *
 * Provides:
 * - Customer selector (Walk-In vs Named Customer)
 * - Order intent selector (Take Now vs Pickup Later)
 * - Cart line items with quantity adjustments (+ / - / delete)
 * - Order discount calculator (Flat ₹ or %)
 * - Subtotal and Grand Total display
 * - Checkout button with payment modal trigger
 */

import React, { useState } from 'react';
import {
  Box,
  Typography,
  Button,
  IconButton,
  TextField,
  InputAdornment,
  Divider,
  Paper,
  Chip,
  Tooltip,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  alpha,
  useTheme,
} from '@mui/material';
import {
  Add as AddIcon,
  Remove as RemoveIcon,
  DeleteOutline as DeleteIcon,
  ShoppingCartOutlined as CartEmptyIcon,
  Person as PersonIcon,
  PersonAdd as AddPersonIcon,
  ShoppingBag as TakeNowIcon,
  Store as PickupIcon,
  Discount as DiscountIcon,
  Clear as ClearIcon,
  Payments as PayIcon,
} from '@mui/icons-material';
import type { RetailPOSCartItem, RetailPOSCustomer } from './retailPos.api';
import { quickCreateCustomer } from './retailPos.api';
import { formatCurrency } from '../../../core/i18n';

interface RetailPOSCartProps {
  cartItems: RetailPOSCartItem[];
  onUpdateQuantity: (productId: string, quantity: number) => void;
  onRemoveItem: (productId: string) => void;
  onClearCart: () => void;
  customer: RetailPOSCustomer | null;
  onSelectCustomer: (customer: RetailPOSCustomer | null) => void;
  orderIntent: 'TAKE_NOW' | 'PICKUP_LATER';
  onSelectOrderIntent: (intent: 'TAKE_NOW' | 'PICKUP_LATER') => void;
  discountAmount: number;
  onDiscountChange: (amount: number) => void;
  onOpenCheckout: () => void;
  isShiftOpen: boolean;
}

export const RetailPOSCart: React.FC<RetailPOSCartProps> = ({
  cartItems,
  onUpdateQuantity,
  onRemoveItem,
  onClearCart,
  customer,
  onSelectCustomer,
  orderIntent,
  onSelectOrderIntent,
  discountAmount,
  onDiscountChange,
  onOpenCheckout,
  isShiftOpen,
}) => {
  const theme = useTheme();

  // Customer quick-add modal state
  const [customerModalOpen, setCustomerModalOpen] = useState(false);
  const [custName, setCustName] = useState('');
  const [custPhone, setCustPhone] = useState('');
  const [creatingCust, setCreatingCust] = useState(false);

  // Discount input dialog / popover state
  const [discountModalOpen, setDiscountModalOpen] = useState(false);
  const [tempDiscount, setTempDiscount] = useState(String(discountAmount || ''));
  const [discountType, setDiscountType] = useState<'FLAT' | 'PERCENT'>('FLAT');

  // Calculations
  const subtotal = cartItems.reduce((sum, item) => sum + item.quantity * item.unitPrice, 0);
  const effectiveDiscount = Math.min(subtotal, Math.max(0, discountAmount));
  const grandTotal = Math.max(0, subtotal - effectiveDiscount);
  const totalItemCount = cartItems.reduce((sum, item) => sum + item.quantity, 0);

  const handleApplyDiscount = () => {
    const val = parseFloat(tempDiscount);
    if (isNaN(val) || val <= 0) {
      onDiscountChange(0);
    } else if (discountType === 'PERCENT') {
      const pctAmount = (subtotal * val) / 100;
      onDiscountChange(Math.round(pctAmount * 100) / 100);
    } else {
      onDiscountChange(val);
    }
    setDiscountModalOpen(false);
  };

  const handleSaveCustomer = async () => {
    if (!custName.trim()) return;
    try {
      setCreatingCust(true);
      const newCust = await quickCreateCustomer(custName.trim(), custPhone.trim() || undefined);
      onSelectCustomer(newCust);
      setCustomerModalOpen(false);
      setCustName('');
      setCustPhone('');
    } catch (err) {
      console.error('Failed to create customer:', err);
    } finally {
      setCreatingCust(false);
    }
  };

  return (
    <Paper
      variant="outlined"
      sx={{
        display: 'flex',
        flexDirection: 'column',
        height: '100%',
        borderRadius: 2,
        bgcolor: 'background.paper',
        overflow: 'hidden',
      }}
    >
      {/* 1. Header: Customer & Order Intent */}
      <Box sx={{ p: 1.5, borderBottom: '1px solid', borderColor: 'divider', bgcolor: alpha(theme.palette.primary.main, 0.02) }}>
        {/* Customer selection row */}
        <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', mb: 1 }}>
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
            <PersonIcon fontSize="small" color="action" />
            <Typography variant="body2" fontWeight={600}>
              {customer ? customer.name : 'Walk-In Customer'}
            </Typography>
            {customer?.phone && (
              <Typography variant="caption" color="text.secondary">
                ({customer.phone})
              </Typography>
            )}
          </Box>
          <Box sx={{ display: 'flex', gap: 0.5 }}>
            {customer && (
              <IconButton size="small" onClick={() => onSelectCustomer(null)} title="Reset to Walk-In">
                <ClearIcon fontSize="small" />
              </IconButton>
            )}
            <Button
              size="small"
              variant="text"
              startIcon={<AddPersonIcon sx={{ fontSize: 16 }} />}
              onClick={() => setCustomerModalOpen(true)}
              sx={{ textTransform: 'none', fontSize: '0.75rem', p: 0.5 }}
            >
              {customer ? 'Change' : '+ Add Customer'}
            </Button>
          </Box>
        </Box>

        {/* Order Intent Toggle */}
        <Box sx={{ display: 'flex', gap: 1 }}>
          <Chip
            icon={<TakeNowIcon sx={{ fontSize: '15px !important' }} />}
            label="Take Now"
            size="small"
            clickable
            color={orderIntent === 'TAKE_NOW' ? 'primary' : 'default'}
            variant={orderIntent === 'TAKE_NOW' ? 'filled' : 'outlined'}
            onClick={() => onSelectOrderIntent('TAKE_NOW')}
            sx={{ fontWeight: 600, flex: 1 }}
          />
          <Chip
            icon={<PickupIcon sx={{ fontSize: '15px !important' }} />}
            label="Pickup Later"
            size="small"
            clickable
            color={orderIntent === 'PICKUP_LATER' ? 'primary' : 'default'}
            variant={orderIntent === 'PICKUP_LATER' ? 'filled' : 'outlined'}
            onClick={() => onSelectOrderIntent('PICKUP_LATER')}
            sx={{ fontWeight: 600, flex: 1 }}
          />
        </Box>
      </Box>

      {/* 2. Cart Item List */}
      <Box
        sx={{
          flex: 1,
          overflowY: 'auto',
          p: 1.5,
          display: 'flex',
          flexDirection: 'column',
          gap: 1,
          '&::-webkit-scrollbar': { width: 6 },
          '&::-webkit-scrollbar-thumb': { bgcolor: 'divider', borderRadius: 3 },
        }}
      >
        {cartItems.length === 0 ? (
          <Box
            sx={{
              display: 'flex',
              flexDirection: 'column',
              alignItems: 'center',
              justifyContent: 'center',
              height: '100%',
              color: 'text.secondary',
              py: 6,
            }}
          >
            <CartEmptyIcon sx={{ fontSize: 48, color: 'text.disabled', mb: 1 }} />
            <Typography variant="body2" fontWeight={600}>
              Cart is empty
            </Typography>
            <Typography variant="caption" color="text.secondary" textAlign="center">
              Click items on the left or scan barcodes to begin sale
            </Typography>
          </Box>
        ) : (
          cartItems.map((item) => (
            <Box
              key={item.product.id}
              sx={{
                p: 1.25,
                borderRadius: 1.5,
                border: '1px solid',
                borderColor: 'divider',
                bgcolor: 'background.paper',
                display: 'flex',
                flexDirection: 'column',
                gap: 0.75,
              }}
            >
              {/* Top: Name & Remove */}
              <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                <Typography variant="body2" fontWeight={700} sx={{ lineHeight: 1.3, flex: 1, pr: 1 }}>
                  {item.product.name}
                </Typography>
                <IconButton
                  size="small"
                  color="error"
                  onClick={() => onRemoveItem(item.product.id)}
                  sx={{ p: 0.25, mt: -0.5, mr: -0.5 }}
                >
                  <DeleteIcon fontSize="small" />
                </IconButton>
              </Box>

              {/* Bottom: Price, Quantity Stepper, Line Total */}
              <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                <Typography variant="caption" color="text.secondary">
                  {formatCurrency(item.unitPrice)} each
                </Typography>

                {/* Quantity Controls */}
                <Box
                  sx={{
                    display: 'flex',
                    alignItems: 'center',
                    border: '1px solid',
                    borderColor: 'divider',
                    borderRadius: 1.5,
                    bgcolor: alpha(theme.palette.action.hover, 0.3),
                  }}
                >
                  <IconButton
                    size="small"
                    onClick={() => onUpdateQuantity(item.product.id, item.quantity - 1)}
                    sx={{ p: 0.5 }}
                  >
                    <RemoveIcon sx={{ fontSize: 14 }} />
                  </IconButton>
                  <Typography
                    variant="body2"
                    fontWeight={700}
                    sx={{ width: 28, textAlign: 'center', fontSize: '0.85rem' }}
                  >
                    {item.quantity}
                  </Typography>
                  <IconButton
                    size="small"
                    onClick={() => onUpdateQuantity(item.product.id, item.quantity + 1)}
                    sx={{ p: 0.5 }}
                  >
                    <AddIcon sx={{ fontSize: 14 }} />
                  </IconButton>
                </Box>

                {/* Line Total */}
                <Typography variant="subtitle2" fontWeight={800} color="text.primary">
                  {formatCurrency(item.quantity * item.unitPrice)}
                </Typography>
              </Box>
            </Box>
          ))
        )}
      </Box>

      {/* 3. Summary & Checkout Footer */}
      <Box sx={{ p: 2, borderTop: '1px solid', borderColor: 'divider', bgcolor: alpha(theme.palette.action.hover, 0.1) }}>
        {/* Subtotal */}
        <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 0.75 }}>
          <Typography variant="body2" color="text.secondary">
            Subtotal ({totalItemCount} {totalItemCount === 1 ? 'item' : 'items'})
          </Typography>
          <Typography variant="body2" fontWeight={600}>
            {formatCurrency(subtotal)}
          </Typography>
        </Box>

        {/* Discount Row */}
        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 1 }}>
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
            <Typography variant="body2" color="text.secondary">
              Discount
            </Typography>
            <Button
              size="small"
              variant="text"
              startIcon={<DiscountIcon sx={{ fontSize: 14 }} />}
              onClick={() => {
                setTempDiscount(String(discountAmount || ''));
                setDiscountModalOpen(true);
              }}
              sx={{ textTransform: 'none', fontSize: '0.7rem', p: 0.25 }}
            >
              {discountAmount > 0 ? 'Edit' : '+ Apply'}
            </Button>
          </Box>
          <Typography variant="body2" color={effectiveDiscount > 0 ? 'success.main' : 'text.secondary'} fontWeight={600}>
            {effectiveDiscount > 0 ? `-${formatCurrency(effectiveDiscount)}` : '₹0.00'}
          </Typography>
        </Box>

        <Divider sx={{ my: 1 }} />

        {/* Grand Total */}
        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', mb: 2 }}>
          <Typography variant="subtitle1" fontWeight={700}>
            Grand Total
          </Typography>
          <Typography variant="h5" fontWeight={900} color="primary.main">
            {formatCurrency(grandTotal)}
          </Typography>
        </Box>

        {/* Action Buttons */}
        <Box sx={{ display: 'flex', gap: 1 }}>
          {cartItems.length > 0 && (
            <Button
              variant="outlined"
              color="inherit"
              size="large"
              onClick={onClearCart}
              sx={{ textTransform: 'none', fontWeight: 600, borderRadius: 2 }}
            >
              Clear
            </Button>
          )}

          <Button
            variant="contained"
            color="primary"
            size="large"
            fullWidth
            disabled={cartItems.length === 0 || !isShiftOpen}
            onClick={onOpenCheckout}
            startIcon={<PayIcon />}
            sx={{
              textTransform: 'none',
              fontWeight: 800,
              fontSize: '1.05rem',
              py: 1.25,
              borderRadius: 2,
              boxShadow: '0 4px 14px rgba(0,0,0,0.12)',
            }}
          >
            {isShiftOpen ? `PAY ${formatCurrency(grandTotal)}` : 'Open Shift First'}
          </Button>
        </Box>
      </Box>

      {/* Customer Quick Add Dialog */}
      <Dialog open={customerModalOpen} onClose={() => setCustomerModalOpen(false)} maxWidth="xs" fullWidth>
        <DialogTitle sx={{ fontWeight: 700 }}>Add Customer</DialogTitle>
        <DialogContent sx={{ display: 'flex', flexDirection: 'column', gap: 2, pt: 1 }}>
          <TextField
            label="Customer Name"
            fullWidth
            autoFocus
            required
            value={custName}
            onChange={(e) => setCustName(e.target.value)}
          />
          <TextField
            label="Phone Number"
            fullWidth
            value={custPhone}
            onChange={(e) => setCustPhone(e.target.value)}
            placeholder="10-digit mobile"
          />
        </DialogContent>
        <DialogActions sx={{ p: 2 }}>
          <Button onClick={() => setCustomerModalOpen(false)} color="inherit">
            Cancel
          </Button>
          <Button
            variant="contained"
            onClick={handleSaveCustomer}
            disabled={!custName.trim() || creatingCust}
          >
            {creatingCust ? 'Saving...' : 'Set Customer'}
          </Button>
        </DialogActions>
      </Dialog>

      {/* Discount Dialog */}
      <Dialog open={discountModalOpen} onClose={() => setDiscountModalOpen(false)} maxWidth="xs" fullWidth>
        <DialogTitle sx={{ fontWeight: 700 }}>Apply Order Discount</DialogTitle>
        <DialogContent sx={{ display: 'flex', flexDirection: 'column', gap: 2, pt: 1 }}>
          <Box sx={{ display: 'flex', gap: 1 }}>
            <Chip
              label="Flat Amount (₹)"
              clickable
              color={discountType === 'FLAT' ? 'primary' : 'default'}
              variant={discountType === 'FLAT' ? 'filled' : 'outlined'}
              onClick={() => setDiscountType('FLAT')}
              sx={{ fontWeight: 600, flex: 1 }}
            />
            <Chip
              label="Percentage (%)"
              clickable
              color={discountType === 'PERCENT' ? 'primary' : 'default'}
              variant={discountType === 'PERCENT' ? 'filled' : 'outlined'}
              onClick={() => setDiscountType('PERCENT')}
              sx={{ fontWeight: 600, flex: 1 }}
            />
          </Box>
          <TextField
            label={discountType === 'FLAT' ? 'Discount Amount (₹)' : 'Discount Percentage (%)'}
            fullWidth
            autoFocus
            type="number"
            value={tempDiscount}
            onChange={(e) => setTempDiscount(e.target.value)}
            InputProps={{
              startAdornment: (
                <InputAdornment position="start">
                  {discountType === 'FLAT' ? '₹' : '%'}
                </InputAdornment>
              ),
            }}
          />
        </DialogContent>
        <DialogActions sx={{ p: 2 }}>
          <Button onClick={() => onDiscountChange(0)} color="inherit">
            Remove Discount
          </Button>
          <Button variant="contained" onClick={handleApplyDiscount}>
            Apply
          </Button>
        </DialogActions>
      </Dialog>
    </Paper>
  );
};

export default RetailPOSCart;
