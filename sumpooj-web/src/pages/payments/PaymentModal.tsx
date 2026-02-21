/**
 * PaymentModal.tsx — POS split payment modal
 */
import React, { useEffect, useMemo, useState } from 'react';
import {
  Dialog, DialogTitle, DialogContent, DialogActions,
  Box, Typography, Button, TextField,
  Chip, Divider, CircularProgress,
  useTheme, alpha, IconButton,
} from '@mui/material';
import {
  AttachMoney as CashIcon,
  CreditCard as CardIcon,
  QrCode as UpiIcon,
  AccountBalanceWallet as StoreCreditIcon,
  DeleteOutline as RemoveIcon,
} from '@mui/icons-material';
import type { OrderPaymentEntry, OrderPaymentMethod } from '../orders/OrderTypes';
import { fmtPaymentAmount } from './PaymentUtils';

interface PaymentModalProps {
  open: boolean;
  onClose: () => void;
  orderId: string;
  grandTotal: number;
  orderSource?: string;
  /** Called when the full amount is covered */
  onFullyPaid?: (payments: OrderPaymentEntry[]) => void;
  /** Called when user saves with outstanding balance */
  onPartialSave?: (payments: OrderPaymentEntry[], totalPaid: number, balanceDue: number) => void;
  /** Pre-existing payments (for balance collection on partially paid orders) */
  existingPayments?: OrderPaymentEntry[];
  /** Whether customer name + phone are filled (required for partial saves) */
  customerValid?: boolean;
}

const METHOD_LABELS: Record<OrderPaymentMethod, string> = {
  CASH: 'Cash',
  CARD: 'Card',
  UPI: 'UPI',
  STORE_CREDIT: 'Store Credit',
};

const METHOD_ICONS: Record<OrderPaymentMethod, React.ReactElement> = {
  CASH: <CashIcon />,
  CARD: <CardIcon />,
  UPI: <UpiIcon />,
  STORE_CREDIT: <StoreCreditIcon />,
};

const PaymentModal: React.FC<PaymentModalProps> = ({
  open, onClose, orderId, grandTotal, onFullyPaid, onPartialSave, existingPayments, customerValid = true,
}) => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';

  const [method, setMethod] = useState<OrderPaymentMethod>('CASH');
  const [amount, setAmount] = useState('0');
  const [processing, setProcessing] = useState(false);
  const [warning, setWarning] = useState('');
  const [payments, setPayments] = useState<Array<OrderPaymentEntry & { id: string; _locked?: boolean }>>([]);

  const paidTotal = useMemo(
    () => payments.reduce((sum, payment) => sum + payment.amount, 0),
    [payments],
  );

  const remaining = useMemo(
    () => Math.max(0, Math.round((grandTotal - paidTotal) * 100) / 100),
    [grandTotal, paidTotal],
  );

  const canComplete = remaining === 0 && payments.length > 0 && !processing;

  useEffect(() => {
    if (!open) return;
    // If opening with existing payments (balance collection), pre-populate
    if (existingPayments && existingPayments.length > 0) {
      const priorTotal = existingPayments.reduce((s, p) => s + p.amount, 0);
      const initRemaining = Math.max(0, Math.round((grandTotal - priorTotal) * 100) / 100);
      setPayments(
        existingPayments.map((p, i) => ({ ...p, id: `existing_${i}`, _locked: true as const })),
      );
      setAmount(initRemaining > 0 ? initRemaining.toFixed(2) : '0');
    } else {
      setPayments([]);
      setAmount(grandTotal > 0 ? grandTotal.toFixed(2) : '0');
    }
    setMethod('CASH');
    setWarning('');
    setProcessing(false);
  }, [open, orderId, grandTotal, existingPayments]);

  const handleMethodSelect = (selectedMethod: OrderPaymentMethod) => {
    setMethod(selectedMethod);
    setAmount(remaining > 0 ? remaining.toFixed(2) : '0');
    setWarning('');
  };

  const handleAddPayment = () => {
    const parsedAmount = Number(amount);

    if (!Number.isFinite(parsedAmount) || parsedAmount <= 0) {
      setWarning('Enter a valid amount greater than 0.');
      return;
    }

    if (parsedAmount > remaining) {
      setWarning('Amount exceeds remaining balance. Overpayment is not allowed.');
      return;
    }

    setPayments((previousPayments) => [
      ...previousPayments,
      {
        id: `pay_${Date.now()}_${previousPayments.length}`,
        method,
        amount: Math.round(parsedAmount * 100) / 100,
      },
    ]);
    setWarning('');

    const nextRemaining = Math.max(0, Math.round((remaining - parsedAmount) * 100) / 100);
    setAmount(nextRemaining > 0 ? nextRemaining.toFixed(2) : '0');
  };

  const handleRemovePayment = (paymentId: string) => {
    setPayments((previousPayments) => previousPayments.filter((payment) => payment.id !== paymentId));
    setWarning('');
  };

  const handleComplete = () => {
    if (remaining !== 0 || processing) return;

    setProcessing(true);
    setWarning('');

    setTimeout(() => {
      setProcessing(false);
      onFullyPaid?.(payments.map(({ method: paymentMethod, amount: paymentAmount }) => ({ method: paymentMethod, amount: paymentAmount })));
    }, 700);
  };

  const handlePartialSave = () => {
    if (payments.length === 0 || remaining <= 0 || processing) return;

    setProcessing(true);
    setWarning('');

    setTimeout(() => {
      setProcessing(false);
      const allPayments = payments.map(({ method: m, amount: a }) => ({ method: m, amount: a }));
      onPartialSave?.(allPayments, paidTotal, remaining);
    }, 700);
  };

  return (
    <Dialog open={open} onClose={onClose} maxWidth="sm" fullWidth>
      {/* Loading Overlay */}
      {processing && (
        <Box
          sx={{
            position: 'absolute',
            inset: 0,
            bgcolor: 'rgba(0,0,0,0.5)',
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
            justifyContent: 'center',
            zIndex: 10,
            borderRadius: 'inherit',
          }}
        >
          <CircularProgress size={48} sx={{ color: '#fff' }} />
          <Typography sx={{ color: '#fff', mt: 2, fontWeight: 600 }}>Processing payment...</Typography>
        </Box>
      )}

      <DialogTitle sx={{ fontWeight: 800, pb: 1 }}>
        <Typography variant="h6" sx={{ fontWeight: 800 }}>Split Payment</Typography>
      </DialogTitle>

      <DialogContent dividers>
<<<<<<< HEAD
        {/* ─── Total at Top - Prominent Display ──────── */}
        <Box
          sx={{
            textAlign: 'center',
            py: 2,
            mb: 3,
            borderRadius: 2,
            bgcolor: dk ? alpha('#fff', 0.04) : alpha('#000', 0.02),
          }}
        >
          <Typography variant="overline" color="text.secondary" sx={{ letterSpacing: 1.5 }}>
            Order Total
          </Typography>
          <Typography
            sx={{
              fontWeight: 800,
              fontSize: '2.5rem',
              letterSpacing: '-0.02em',
              color: dk ? '#fdd835' : theme.palette.primary.main,
              lineHeight: 1.2,
            }}
          >
            {fmtPaymentAmount(grandTotal)}
          </Typography>
        </Box>

        {/* ─── Balance Summary ──────────────────────────── */}
=======
>>>>>>> 0bce1d340b81541ea96ee2e6f50c57e218312c38
        <Box
          sx={{
            display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 2, mb: 3,
            p: 2, borderRadius: 2,
            bgcolor: dk ? alpha('#fff', 0.03) : alpha('#000', 0.02),
          }}
        >
          <Box sx={{ textAlign: 'center' }}>
<<<<<<< HEAD
            <Typography variant="caption" color="text.secondary">Paid</Typography>
            <Typography variant="h6" sx={{ fontWeight: 800, color: theme.palette.success.main }}>
              {fmtPaymentAmount(approvedTotal)}
            </Typography>
=======
            <Typography variant="caption" color="text.secondary">Total</Typography>
            <Typography variant="h6" sx={{ fontWeight: 800 }}>{fmtPaymentAmount(grandTotal)}</Typography>
>>>>>>> 0bce1d340b81541ea96ee2e6f50c57e218312c38
          </Box>
          <Box sx={{ textAlign: 'center' }}>
            <Typography variant="caption" color="text.secondary">Remaining</Typography>
            <Typography
              variant="h6"
              sx={{ fontWeight: 800, color: remaining > 0 ? theme.palette.warning.main : theme.palette.success.main }}
            >
              {fmtPaymentAmount(remaining)}
            </Typography>
          </Box>
        </Box>

<<<<<<< HEAD
        {/* ─── Payment Input ───────────────────────────── */}
        {remaining > 0 && (
          <>
            {/* Method selector */}
            <Typography variant="subtitle2" sx={{ fontWeight: 700, mb: 1 }}>Payment Method</Typography>
            <ToggleButtonGroup
              value={method}
              exclusive
              onChange={(_, val: PaymentMethod | null) => val && setMethod(val)}
              fullWidth
              size="large"
              sx={{ mb: 2 }}
            >
              {(Object.keys(PAYMENT_METHOD_CONFIG) as PaymentMethod[]).map((m) => (
                <ToggleButton
                  key={m}
                  value={m}
                  sx={{
                    textTransform: 'none', fontWeight: 700, fontSize: '0.85rem',
                    gap: 0.75, py: 1.75, minHeight: 56,
                    transition: 'all 0.15s',
                    '&.Mui-selected': {
                      bgcolor: alpha(PAYMENT_METHOD_CONFIG[m].color, dk ? 0.25 : 0.15),
                      color: PAYMENT_METHOD_CONFIG[m].color,
                      borderColor: PAYMENT_METHOD_CONFIG[m].color,
                      transform: 'scale(1.02)',
                    },
                    '&:hover': {
                      transform: 'translateY(-2px)',
                    },
                  }}
                >
                  {METHOD_ICONS[m]}
                  {PAYMENT_METHOD_CONFIG[m].label}
                </ToggleButton>
              ))}
            </ToggleButtonGroup>

            {/* Amount */}
            <Box sx={{ display: 'flex', gap: 2, alignItems: 'flex-end', mb: 2 }}>
              <TextField
                label="Amount"
                type="number"
                size="medium"
                value={amount}
                onChange={(e) => setAmount(e.target.value)}
                placeholder={remaining.toString()}
                fullWidth
                slotProps={{
                  input: {
                    sx: { fontWeight: 700, fontSize: '1.25rem', py: 0.5 },
                  },
                }}
                helperText={`Remaining: ${fmtPaymentAmount(remaining)}`}
                sx={{
                  '& .MuiOutlinedInput-root': {
                    minHeight: 56,
                    ...(dk ? { color: '#e0e0e0', '& fieldset': { borderColor: 'rgba(255,255,255,0.15)' } } : {}),
                  },
                }}
              />
              <Button
                variant="contained"
                onClick={handleProcess}
                disabled={processing || effectiveAmount <= 0}
                sx={{
                  minWidth: 160, py: 1.5, minHeight: 52, fontWeight: 800, fontSize: '1rem',
                  bgcolor: PAYMENT_METHOD_CONFIG[method].color,
                  transition: 'all 0.15s',
                  '&:hover': {
                    bgcolor: alpha(PAYMENT_METHOD_CONFIG[method].color, 0.85),
                    transform: 'translateY(-2px)',
                    boxShadow: '0 4px 16px rgba(0,0,0,0.2)',
                  },
                  '&:active': {
                    transform: 'scale(0.98)',
                  },
                  '&.Mui-disabled': {
                    bgcolor: dk ? 'rgba(255,255,255,0.12)' : 'rgba(0,0,0,0.12)',
                  },
                }}
              >
                {processing ? <CircularProgress size={24} color="inherit" /> : 'Process'}
              </Button>
            </Box>

            {/* Terminal feedback */}
            {lastResult && (
              <Alert
                severity={lastResult.success ? 'success' : 'error'}
                icon={lastResult.success ? <ApprovedIcon /> : <DeclinedIcon />}
                sx={{ mb: 2, fontWeight: 600 }}
              >
                {lastResult.message}
              </Alert>
            )}
          </>
        )}

        {remaining <= 0 && (
          <Alert severity="success" sx={{ mb: 2, fontWeight: 600 }}>
            Order is fully paid!
          </Alert>
        )}

        {/* ─── Payment History ─────────────────────────── */}
        {payments.length > 0 && (
          <>
            <Divider sx={{ my: 2 }} />
            <Typography variant="subtitle2" sx={{ fontWeight: 700, mb: 1 }}>
              Payment History ({payments.length})
            </Typography>
            <TableContainer
              component={Paper}
              elevation={dk ? 0 : 1}
=======
        <Typography variant="subtitle2" sx={{ fontWeight: 700, mb: 1 }}>
          Payment Methods
        </Typography>
        <Box sx={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 1, mb: 2 }}>
          {(Object.keys(METHOD_LABELS) as OrderPaymentMethod[]).map((paymentMethod) => (
            <Button
              key={paymentMethod}
              variant={method === paymentMethod ? 'contained' : 'outlined'}
              onClick={() => handleMethodSelect(paymentMethod)}
              startIcon={METHOD_ICONS[paymentMethod]}
>>>>>>> 0bce1d340b81541ea96ee2e6f50c57e218312c38
              sx={{
                minHeight: 56,
                fontWeight: 700,
                textTransform: 'none',
              }}
            >
              {METHOD_LABELS[paymentMethod]}
            </Button>
          ))}
        </Box>

        <Box sx={{ display: 'flex', gap: 1, alignItems: 'flex-end', mb: 1.5 }}>
          <TextField
            label="Amount"
            type="number"
            size="small"
            value={amount}
            onChange={(event) => setAmount(event.target.value)}
            fullWidth
            slotProps={{
              input: {
                sx: { fontWeight: 700 },
              },
            }}
            helperText={`Default is remaining: ${fmtPaymentAmount(remaining)}`}
          />
          <Button
            variant="contained"
            onClick={handleAddPayment}
            disabled={remaining <= 0 || processing}
            sx={{
              minHeight: 48,
              px: 2.5,
              fontWeight: 700,
            }}
          >
            Add
          </Button>
        </Box>

        {warning && (
          <Typography variant="caption" sx={{ color: theme.palette.warning.main, display: 'block', mb: 2 }}>
            {warning}
          </Typography>
        )}

        <Divider sx={{ my: 2 }} />
        <Typography variant="subtitle2" sx={{ fontWeight: 700, mb: 1 }}>
          Added Payments
        </Typography>

        {payments.length === 0 && (
          <Typography variant="body2" color="text.secondary">
            No payments added yet.
          </Typography>
        )}

        {payments.map((payment) => (
          <Box
            key={payment.id}
            sx={{
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'space-between',
              p: 1.25,
              mb: 1,
              borderRadius: 1,
              border: `1px solid ${dk ? alpha('#fff', 0.12) : alpha('#000', 0.12)}`,
              opacity: payment._locked ? 0.6 : 1,
            }}
          >
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
              <Chip size="small" label={METHOD_LABELS[payment.method]} sx={{ fontWeight: 700 }} />
              <Typography variant="body2" sx={{ fontWeight: 700 }}>
                {fmtPaymentAmount(payment.amount)}
              </Typography>
              {payment._locked && (
                <Chip size="small" label="Previous" variant="outlined" sx={{ fontSize: '0.65rem' }} />
              )}
            </Box>
            {!payment._locked && (
              <IconButton size="small" color="error" onClick={() => handleRemovePayment(payment.id)}>
                <RemoveIcon fontSize="small" />
              </IconButton>
            )}
          </Box>
        ))}
      </DialogContent>

      <DialogActions sx={{ px: 3, py: 2, gap: 1, flexDirection: 'column', alignItems: 'stretch' }}>
        {onPartialSave && remaining > 0 && payments.length > 0 && !customerValid && (
          <Typography
            variant="caption"
            sx={{
              color: theme.palette.error.main,
              fontWeight: 600,
              textAlign: 'center',
              mb: 0.5,
            }}
          >
            Customer Name and Phone are required for partial payment orders.
          </Typography>
        )}
        <Box sx={{ display: 'flex', gap: 1, justifyContent: 'flex-end', width: '100%' }}>
          <Button onClick={onClose} sx={{ fontWeight: 600 }} disabled={processing}>Cancel</Button>
          {onPartialSave && remaining > 0 && payments.length > 0 && (
            <Button
              variant="outlined"
              color="warning"
              onClick={handlePartialSave}
              disabled={processing || !customerValid}
              sx={{ minHeight: 48, fontWeight: 700 }}
            >
              {processing ? <CircularProgress size={20} color="inherit" /> : 'Save as Partially Paid'}
            </Button>
          )}
          <Button
            variant="contained"
            onClick={handleComplete}
            disabled={!canComplete}
            sx={{ minHeight: 48, minWidth: 160, fontWeight: 700 }}
          >
            {processing ? <CircularProgress size={20} color="inherit" /> : 'Complete Order'}
          </Button>
        </Box>
      </DialogActions>
    </Dialog>
  );
};

export default PaymentModal;
