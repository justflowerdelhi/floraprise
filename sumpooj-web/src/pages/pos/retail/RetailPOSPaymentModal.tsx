/**
 * RetailPOSPaymentModal.tsx — Fast checkout dialog for Retail POS
 *
 * Supports:
 * - Single-click tender methods: Cash, UPI, Card, Store Credit
 * - Quick cash preset chips (Exact, +50, +100, +500, +2000)
 * - Dynamic Change Due calculation
 * - Multi-tender split payment
 * - Non-blocking thermal receipt printing
 */

import React, { useState, useEffect, useMemo, useCallback } from 'react';
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Box,
  Typography,
  Button,
  TextField,
  Chip,
  IconButton,
  Alert,
  CircularProgress,
  Divider,
  Tab,
  Tabs,
  InputAdornment,
  alpha,
  useTheme,
} from '@mui/material';
import {
  Close as CloseIcon,
  Payments as CashIcon,
  QrCode as UpiIcon,
  CreditCard as CardIcon,
  CardGiftcard as StoreCreditIcon,
  CallSplit as SplitIcon,
  CheckCircle as SuccessIcon,
  Print as PrintIcon,
} from '@mui/icons-material';
import type {
  RetailPOSCartItem,
  RetailPOSCustomer,
  CreateOrderRequest,
  OrderDto,
  PosReceiptPayment,
} from './retailPos.api';
import {
  submitRetailPOSOrder,
  openReceiptWindow,
  printInWindow,
  printPosReceipt,
  getPosReceiptPrintMode,
} from './retailPos.api';
import { formatCurrency } from '../../../core/i18n';

interface RetailPOSPaymentModalProps {
  open: boolean;
  onClose: () => void;
  cartItems: RetailPOSCartItem[];
  customer: RetailPOSCustomer | null;
  locationId: string;
  orderIntent: 'TAKE_NOW' | 'PICKUP_LATER';
  discountAmount: number;
  onSaleSuccess: (order: OrderDto) => void;
}

type TenderTab = 'CASH' | 'UPI' | 'CARD' | 'STORE_CREDIT' | 'SPLIT';

export const RetailPOSPaymentModal: React.FC<RetailPOSPaymentModalProps> = ({
  open,
  onClose,
  cartItems,
  customer,
  locationId,
  orderIntent,
  discountAmount,
  onSaleSuccess,
}) => {
  const theme = useTheme();

  // Financial calculations
  const subtotal = useMemo(
    () => cartItems.reduce((sum, item) => sum + item.quantity * item.unitPrice, 0),
    [cartItems],
  );
  const effectiveDiscount = Math.min(subtotal, Math.max(0, discountAmount));
  const grandTotal = Math.max(0, subtotal - effectiveDiscount);

  // Active tender tab
  const [activeTab, setActiveTab] = useState<TenderTab>('CASH');

  // Cash state
  const [cashReceived, setCashReceived] = useState<string>('');

  // Split payment state
  const [splitCash, setSplitCash] = useState<string>('');
  const [splitUpi, setSplitUpi] = useState<string>('');
  const [splitCard, setSplitCard] = useState<string>('');

  // Transaction references
  const [txReference, setTxReference] = useState<string>('');

  // Submission state
  const [submitting, setSubmitting] = useState(false);
  const [submitError, setSubmitError] = useState<string | null>(null);
  const [idempotencyKey, setIdempotencyKey] = useState<string>(() =>
    typeof crypto !== 'undefined' && crypto.randomUUID ? crypto.randomUUID() : `pos-retail-${Date.now()}-${Math.random().toString(36).slice(2)}`
  );

  // Reset state when modal opens
  useEffect(() => {
    if (open) {
      setIdempotencyKey(typeof crypto !== 'undefined' && crypto.randomUUID ? crypto.randomUUID() : `pos-retail-${Date.now()}-${Math.random().toString(36).slice(2)}`);
      setActiveTab('CASH');
      setCashReceived(String(grandTotal));
      setSplitCash(String(Math.floor(grandTotal / 2)));
      setSplitUpi(String(grandTotal - Math.floor(grandTotal / 2)));
      setSplitCard('');
      setTxReference('');
      setSubmitError(null);
      setSubmitting(false);
    }
  }, [open, grandTotal]);

  // Quick cash amounts
  const numCashReceived = parseFloat(cashReceived) || 0;
  const changeDue = Math.max(0, numCashReceived - grandTotal);
  const balanceRemaining = Math.max(0, grandTotal - numCashReceived);

  // Quick preset helper
  const handleSetCashPreset = (amount: number) => {
    setCashReceived(String(amount));
  };

  const handleAddCashPreset = (addition: number) => {
    const current = parseFloat(cashReceived) || grandTotal;
    setCashReceived(String(current + addition));
  };

  // Build payments payload based on selected tab
  const getPaymentsPayload = useCallback((): PosReceiptPayment[] => {
    switch (activeTab) {
      case 'CASH':
        return [{ method: 'Cash', amount: grandTotal }];
      case 'UPI':
        return [{ method: 'Upi', amount: grandTotal }];
      case 'CARD':
        return [{ method: 'Card', amount: grandTotal }];
      case 'STORE_CREDIT':
        return [{ method: 'StoreCredit', amount: grandTotal }];
      case 'SPLIT': {
        const p: PosReceiptPayment[] = [];
        const c = parseFloat(splitCash) || 0;
        const u = parseFloat(splitUpi) || 0;
        const cd = parseFloat(splitCard) || 0;
        if (c > 0) p.push({ method: 'Cash', amount: c });
        if (u > 0) p.push({ method: 'Upi', amount: u });
        if (cd > 0) p.push({ method: 'Card', amount: cd });
        return p;
      }
      default:
        return [{ method: 'Cash', amount: grandTotal }];
    }
  }, [activeTab, grandTotal, splitCash, splitUpi, splitCard]);

  // Validation
  const isPaymentValid = useMemo(() => {
    if (grandTotal === 0) return true;
    if (activeTab === 'CASH') {
      return numCashReceived >= grandTotal;
    }
    if (activeTab === 'UPI' || activeTab === 'CARD' || activeTab === 'STORE_CREDIT') {
      return true;
    }
    if (activeTab === 'SPLIT') {
      const totalSplit =
        (parseFloat(splitCash) || 0) +
        (parseFloat(splitUpi) || 0) +
        (parseFloat(splitCard) || 0);
      return Math.abs(totalSplit - grandTotal) < 0.01;
    }
    return false;
  }, [activeTab, grandTotal, numCashReceived, splitCash, splitUpi, splitCard]);

  // Submission handler
  const handleCompleteSale = async () => {
    if (!isPaymentValid || submitting) return;

    // Pre-open print window during synchronous click gesture
    const printMode = getPosReceiptPrintMode();
    const receiptWin = openReceiptWindow();

    setSubmitting(true);
    setSubmitError(null);

    const payments = getPaymentsPayload();

    const orderPayload: CreateOrderRequest = {
      customerId: customer?.id || null,
      locationId: locationId || null,
      deliveryDate: null,
      deliveryAddress: null,
      deliveryPincode: null,
      recipientName: customer?.name || 'Walk-In Customer',
      recipientPhone: customer?.phone || null,
      cardMessage: null,
      deliveryPriority: 'STANDARD',
      timeSlot: null,
      orderSource: 'WALK_IN',
      orderIntent: orderIntent,
      pickupDate: null,
      pickupTimeSlot: null,
      deliveryFee: 0,
      discountAmount: effectiveDiscount,
      internalNotes: txReference ? `Ref: ${txReference}` : null,
      items: cartItems.map((item) => ({
        productId: item.product.id,
        productName: item.product.name,
        quantity: item.quantity,
        unitPrice: item.unitPrice,
        unit: 'pcs',
      })),
      payments: payments.map((p) => ({
        method: p.method,
        amount: p.amount,
      })),
    };

    try {
      const createdOrder = await submitRetailPOSOrder(orderPayload, idempotencyKey);

      // Trigger receipt printing
      try {
        const receiptInput = {
          orderNumber: createdOrder?.orderNumber,
          orderId: createdOrder?.id,
          customerName: customer?.name || 'Walk-In Customer',
          customerPhone: customer?.phone,
          items: cartItems.map((item) => ({
            name: item.product.name,
            quantity: item.quantity,
            unitPrice: item.unitPrice,
          })),
          payments: payments,
          subtotal: subtotal,
          discount: effectiveDiscount,
          deliveryFee: 0,
          grandTotal: grandTotal,
          paidTotal: grandTotal,
          balanceDue: 0,
        };

        if (receiptWin && !receiptWin.closed) {
          printInWindow(receiptWin, receiptInput, printMode);
        } else {
          printPosReceipt(receiptInput);
        }
      } catch (printErr) {
        console.warn('Receipt print dispatch error:', printErr);
      }

      onSaleSuccess(createdOrder);
      onClose();
    } catch (err: any) {
      if (receiptWin && !receiptWin.closed) receiptWin.close();
      console.error('POS Sale Submission Error:', err);
      const msg = err?.response?.data?.message || err?.message || 'Failed to complete sale. Please try again.';
      setSubmitError(msg);
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <Dialog open={open} onClose={submitting ? undefined : onClose} maxWidth="sm" fullWidth>
      <DialogTitle sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', pb: 1 }}>
        <Typography variant="h6" fontWeight={800}>
          Checkout & Payment
        </Typography>
        <IconButton size="small" onClick={onClose} disabled={submitting}>
          <CloseIcon />
        </IconButton>
      </DialogTitle>

      <DialogContent sx={{ display: 'flex', flexDirection: 'column', gap: 2, pt: 1 }}>
        {/* Total Banner */}
        <Box
          sx={{
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
            p: 2,
            borderRadius: 2,
            bgcolor: alpha(theme.palette.primary.main, 0.08),
            border: '1px solid',
            borderColor: alpha(theme.palette.primary.main, 0.2),
          }}
        >
          <Box>
            <Typography variant="caption" color="text.secondary" fontWeight={600} textTransform="uppercase">
              Amount Due
            </Typography>
            <Typography variant="h4" fontWeight={900} color="primary.main">
              {formatCurrency(grandTotal)}
            </Typography>
          </Box>
          <Box sx={{ textAlign: 'right' }}>
            <Typography variant="caption" color="text.secondary">
              {customer?.name || 'Walk-In'} • {orderIntent === 'TAKE_NOW' ? 'Take Now' : 'Pickup'}
            </Typography>
            <Typography variant="body2" color="text.secondary" fontWeight={500}>
              {cartItems.length} items
            </Typography>
          </Box>
        </Box>

        {submitError && (
          <Alert severity="error" onClose={() => setSubmitError(null)}>
            {submitError}
          </Alert>
        )}

        {/* Tender Tabs */}
        <Tabs
          value={activeTab}
          onChange={(_, val) => setActiveTab(val)}
          variant="fullWidth"
          sx={{
            borderBottom: 1,
            borderColor: 'divider',
            '& .MuiTab-root': { fontWeight: 700, fontSize: '0.8rem', textTransform: 'none' },
          }}
        >
          <Tab icon={<CashIcon sx={{ fontSize: 18 }} />} label="Cash" value="CASH" />
          <Tab icon={<UpiIcon sx={{ fontSize: 18 }} />} label="UPI" value="UPI" />
          <Tab icon={<CardIcon sx={{ fontSize: 18 }} />} label="Card" value="CARD" />
          <Tab icon={<SplitIcon sx={{ fontSize: 18 }} />} label="Split" value="SPLIT" />
          <Tab icon={<StoreCreditIcon sx={{ fontSize: 18 }} />} label="Credit" value="STORE_CREDIT" />
        </Tabs>

        {/* Tab Content: CASH */}
        {activeTab === 'CASH' && (
          <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
            <TextField
              label="Cash Tendered / Received"
              fullWidth
              autoFocus
              type="number"
              value={cashReceived}
              onChange={(e) => setCashReceived(e.target.value)}
              InputProps={{
                startAdornment: <InputAdornment position="start">₹</InputAdornment>,
              }}
              helperText={
                balanceRemaining > 0
                  ? `Need ₹${balanceRemaining.toFixed(2)} more`
                  : null
              }
              error={balanceRemaining > 0}
            />

            {/* Quick Cash Presets */}
            <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 1 }}>
              <Chip
                label={`Exact (${formatCurrency(grandTotal)})`}
                clickable
                color="primary"
                variant={numCashReceived === grandTotal ? 'filled' : 'outlined'}
                onClick={() => handleSetCashPreset(grandTotal)}
                sx={{ fontWeight: 700 }}
              />
              <Chip
                label="+₹50"
                clickable
                onClick={() => handleAddCashPreset(50)}
                sx={{ fontWeight: 600 }}
              />
              <Chip
                label="+₹100"
                clickable
                onClick={() => handleAddCashPreset(100)}
                sx={{ fontWeight: 600 }}
              />
              <Chip
                label="+₹500"
                clickable
                onClick={() => handleAddCashPreset(500)}
                sx={{ fontWeight: 600 }}
              />
              <Chip
                label="₹500 Note"
                clickable
                onClick={() => handleSetCashPreset(500)}
                sx={{ fontWeight: 600 }}
              />
              <Chip
                label="₹2,000 Note"
                clickable
                onClick={() => handleSetCashPreset(2000)}
                sx={{ fontWeight: 600 }}
              />
            </Box>

            {/* Change Calculation Box */}
            <Box
              sx={{
                p: 2,
                borderRadius: 2,
                bgcolor: changeDue > 0 ? alpha(theme.palette.success.main, 0.1) : 'background.default',
                border: '1px solid',
                borderColor: changeDue > 0 ? alpha(theme.palette.success.main, 0.3) : 'divider',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'space-between',
              }}
            >
              <Typography variant="subtitle1" fontWeight={700} color={changeDue > 0 ? 'success.dark' : 'text.secondary'}>
                Change Due to Customer:
              </Typography>
              <Typography variant="h5" fontWeight={900} color={changeDue > 0 ? 'success.dark' : 'text.primary'}>
                {formatCurrency(changeDue)}
              </Typography>
            </Box>
          </Box>
        )}

        {/* Tab Content: UPI */}
        {activeTab === 'UPI' && (
          <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2, textAlign: 'center', py: 1 }}>
            <Box
              sx={{
                p: 2.5,
                borderRadius: 2,
                bgcolor: alpha(theme.palette.info.main, 0.08),
                border: '1px dashed',
                borderColor: 'info.main',
              }}
            >
              <UpiIcon sx={{ fontSize: 44, color: 'info.main', mb: 1 }} />
              <Typography variant="subtitle1" fontWeight={700}>
                Collect {formatCurrency(grandTotal)} via Store QR
              </Typography>
              <Typography variant="caption" color="text.secondary">
                Have the customer scan your static or soundbox QR code
              </Typography>
            </Box>
            <TextField
              label="UPI Ref / UTR / Last 4 Digits (Optional)"
              fullWidth
              size="small"
              value={txReference}
              onChange={(e) => setTxReference(e.target.value)}
              placeholder="e.g. 402910..."
            />
          </Box>
        )}

        {/* Tab Content: CARD */}
        {activeTab === 'CARD' && (
          <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2, textAlign: 'center', py: 1 }}>
            <Box
              sx={{
                p: 2.5,
                borderRadius: 2,
                bgcolor: alpha(theme.palette.secondary.main, 0.08),
                border: '1px dashed',
                borderColor: 'secondary.main',
              }}
            >
              <CardIcon sx={{ fontSize: 44, color: 'secondary.main', mb: 1 }} />
              <Typography variant="subtitle1" fontWeight={700}>
                Swipe / Dip Card on POS Terminal: {formatCurrency(grandTotal)}
              </Typography>
              <Typography variant="caption" color="text.secondary">
                Process payment on EDC machine
              </Typography>
            </Box>
            <TextField
              label="Card Auth / Approval Code (Optional)"
              fullWidth
              size="small"
              value={txReference}
              onChange={(e) => setTxReference(e.target.value)}
              placeholder="e.g. 883921"
            />
          </Box>
        )}

        {/* Tab Content: STORE_CREDIT */}
        {activeTab === 'STORE_CREDIT' && (
          <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2, py: 1 }}>
            <Alert severity="info">
              Charging {formatCurrency(grandTotal)} to customer ledger account.
            </Alert>
            <TextField
              label="Notes / Authorization Reference"
              fullWidth
              size="small"
              value={txReference}
              onChange={(e) => setTxReference(e.target.value)}
              placeholder="e.g. Approved by Manager"
            />
          </Box>
        )}

        {/* Tab Content: SPLIT */}
        {activeTab === 'SPLIT' && (
          <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1.5 }}>
            <Typography variant="body2" color="text.secondary" fontWeight={500}>
              Enter payment breakdown across methods:
            </Typography>
            <TextField
              label="Cash Portion"
              fullWidth
              size="small"
              type="number"
              value={splitCash}
              onChange={(e) => setSplitCash(e.target.value)}
              InputProps={{ startAdornment: <InputAdornment position="start">₹</InputAdornment> }}
            />
            <TextField
              label="UPI Portion"
              fullWidth
              size="small"
              type="number"
              value={splitUpi}
              onChange={(e) => setSplitUpi(e.target.value)}
              InputProps={{ startAdornment: <InputAdornment position="start">₹</InputAdornment> }}
            />
            <TextField
              label="Card Portion"
              fullWidth
              size="small"
              type="number"
              value={splitCard}
              onChange={(e) => setSplitCard(e.target.value)}
              InputProps={{ startAdornment: <InputAdornment position="start">₹</InputAdornment> }}
            />

            {/* Split validation indicator */}
            {(() => {
              const entered =
                (parseFloat(splitCash) || 0) +
                (parseFloat(splitUpi) || 0) +
                (parseFloat(splitCard) || 0);
              const diff = grandTotal - entered;
              if (Math.abs(diff) < 0.01) {
                return (
                  <Alert severity="success" sx={{ py: 0.5 }}>
                    Split payments match grand total ({formatCurrency(grandTotal)})
                  </Alert>
                );
              }
              return (
                <Alert severity="warning" sx={{ py: 0.5 }}>
                  {diff > 0
                    ? `Remaining to allocate: ${formatCurrency(diff)}`
                    : `Overallocated by: ${formatCurrency(Math.abs(diff))}`}
                </Alert>
              );
            })()}
          </Box>
        )}
      </DialogContent>

      <DialogActions sx={{ p: 2, pt: 1 }}>
        <Button onClick={onClose} disabled={submitting} color="inherit">
          Cancel
        </Button>
        <Button
          variant="contained"
          color="primary"
          size="large"
          disabled={!isPaymentValid || submitting}
          onClick={handleCompleteSale}
          startIcon={submitting ? <CircularProgress size={18} color="inherit" /> : <PrintIcon />}
          sx={{
            fontWeight: 800,
            px: 3,
            py: 1,
            borderRadius: 2,
          }}
        >
          {submitting ? 'Processing...' : `COMPLETE & PRINT (${formatCurrency(grandTotal)})`}
        </Button>
      </DialogActions>
    </Dialog>
  );
};

export default RetailPOSPaymentModal;
