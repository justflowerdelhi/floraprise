/**
 * PaymentModal.tsx — Multi-method payment dialog with terminal simulation
 *
 * Features:
 * - Payment method selector (Cash, Card, Gift Card, External Terminal)
 * - Amount input (prefilled with remaining balance)
 * - Split payment support (can add multiple payments)
 * - Terminal simulation with approval/decline feedback
 * - Payment history table showing all order payments
 * - Void and refund actions on existing payments
 */
import React, { useState, useMemo } from 'react';
import {
  Dialog, DialogTitle, DialogContent, DialogActions,
  Box, Typography, Button, TextField, ToggleButton, ToggleButtonGroup,
  Table, TableBody, TableCell, TableContainer, TableHead, TableRow,
  Chip, Paper, Divider, CircularProgress, Alert,
  useTheme, alpha, IconButton, Tooltip,
} from '@mui/material';
import {
  AttachMoney as CashIcon,
  CreditCard as CardIcon,
  CardGiftcard as GiftCardIcon,
  PointOfSale as TerminalIcon,
  Block as VoidIcon,
  // Undo as RefundIcon,
  CheckCircle as ApprovedIcon,
  ErrorOutline as DeclinedIcon,
  QrCode as UpiIcon,
  AccountBalance as BankIcon,
} from '@mui/icons-material';
import type { PaymentMethod } from './PaymentTypes';
import { PAYMENT_METHOD_CONFIG, PAYMENT_STATUS_CONFIG } from './PaymentTypes';
import { usePayments, type ProcessPaymentResult } from './PaymentContext';
import { fmtPaymentAmount } from './PaymentUtils';

interface PaymentModalProps {
  open: boolean;
  onClose: () => void;
  orderId: string;
  grandTotal: number;
  orderSource?: string;
  /** Called when order becomes fully paid */
  onFullyPaid?: () => void;
}

const METHOD_ICONS: Record<PaymentMethod, React.ReactElement> = {
  CASH: <CashIcon />,
  CARD: <CardIcon />,
  GIFT_CARD: <GiftCardIcon />,
  EXTERNAL_TERMINAL: <TerminalIcon />,
  UPI: <UpiIcon />,
  BANK_TRANSFER: <BankIcon />,
};

const PaymentModal: React.FC<PaymentModalProps> = ({
  open, onClose, orderId, grandTotal, onFullyPaid,
}) => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';

  const {
    processNewPayment,
    voidPayment,
    getOrderPayments,
    getOrderPaymentStatus,
    getOrderApprovedTotal,
    getOrderRemainingBalance,
  } = usePayments();

  const [method, setMethod] = useState<PaymentMethod>('CASH');
  const [amount, setAmount] = useState('');
  const [processing, setProcessing] = useState(false);
  const [lastResult, setLastResult] = useState<ProcessPaymentResult | null>(null);

  const payments = useMemo(() => getOrderPayments(orderId), [getOrderPayments, orderId]);
  const paymentStatus = useMemo(() => getOrderPaymentStatus(orderId, grandTotal), [getOrderPaymentStatus, orderId, grandTotal]);
  const approvedTotal = useMemo(() => getOrderApprovedTotal(orderId), [getOrderApprovedTotal, orderId]);
  const remaining = useMemo(() => getOrderRemainingBalance(orderId, grandTotal), [getOrderRemainingBalance, orderId, grandTotal]);

  const effectiveAmount = amount === '' ? remaining : Number(amount);

  const handleProcess = () => {
    if (effectiveAmount <= 0) return;
    setProcessing(true);
    setLastResult(null);

    // Simulate async terminal delay for cards
    const delay = method === 'CARD' || method === 'EXTERNAL_TERMINAL' ? 1200 : 300;

    setTimeout(() => {
      const result = processNewPayment(orderId, method, effectiveAmount);
      setLastResult(result);
      setProcessing(false);
      setAmount('');

      // Check if fully paid after this payment
      if (result.success) {
        const newStatus = getOrderPaymentStatus(orderId, grandTotal);
        if (newStatus === 'PAID' && onFullyPaid) {
          onFullyPaid();
        }
      }
    }, delay);
  };

  const handleVoid = (paymentId: string) => {
    voidPayment(paymentId);
    setLastResult(null);
  };

  const headerSx = {
    fontWeight: 700, fontSize: '0.68rem', textTransform: 'uppercase' as const,
    letterSpacing: 0.5, py: 0.8,
    color: dk ? 'rgba(255,255,255,0.5)' : 'text.secondary',
    bgcolor: dk ? '#1a1a2e' : '#f8f8f8',
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
        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <Typography variant="h6" sx={{ fontWeight: 800 }}>Process Payment</Typography>
          <Chip
            label={paymentStatus}
            color={paymentStatus === 'PAID' ? 'success' : paymentStatus === 'PARTIAL' ? 'info' : 'warning'}
            size="small"
            sx={{ fontWeight: 700 }}
          />
        </Box>
      </DialogTitle>

      <DialogContent dividers>
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
        <Box
          sx={{
            display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 2, mb: 3,
            p: 2, borderRadius: 2,
            bgcolor: dk ? alpha('#fff', 0.03) : alpha('#000', 0.02),
          }}
        >
          <Box sx={{ textAlign: 'center' }}>
            <Typography variant="caption" color="text.secondary">Paid</Typography>
            <Typography variant="h6" sx={{ fontWeight: 800, color: theme.palette.success.main }}>
              {fmtPaymentAmount(approvedTotal)}
            </Typography>
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
              sx={{
                bgcolor: dk ? '#0f0f0f' : '#fff',
                border: dk ? '1px solid rgba(255,255,255,0.08)' : 'none',
                borderRadius: 1,
              }}
            >
              <Table size="small">
                <TableHead>
                  <TableRow>
                    <TableCell sx={headerSx}>Method</TableCell>
                    <TableCell sx={headerSx} align="right">Amount</TableCell>
                    <TableCell sx={headerSx}>Status</TableCell>
                    <TableCell sx={headerSx}>Details</TableCell>
                    <TableCell sx={headerSx} align="center" width={60}>Actions</TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {payments.map((p) => {
                    const mCfg = PAYMENT_METHOD_CONFIG[p.method];
                    const sCfg = PAYMENT_STATUS_CONFIG[p.status];
                    return (
                      <TableRow key={p.id} sx={{ '&:hover': { bgcolor: dk ? alpha('#fff', 0.02) : alpha('#000', 0.01) } }}>
                        <TableCell>
                          <Chip
                            label={mCfg.label}
                            size="small"
                            sx={{
                              bgcolor: alpha(mCfg.color, dk ? 0.2 : 0.1),
                              color: mCfg.color,
                              fontWeight: 700,
                              fontSize: '0.68rem',
                            }}
                          />
                        </TableCell>
                        <TableCell align="right">
                          <Typography variant="body2" sx={{ fontWeight: 700, color: p.amount < 0 ? theme.palette.error.main : undefined }}>
                            {fmtPaymentAmount(p.amount)}
                          </Typography>
                        </TableCell>
                        <TableCell>
                          <Chip label={sCfg.label} size="small" variant={dk ? 'outlined' : 'filled'} sx={{ bgcolor: alpha(sCfg.color, dk ? 0.25 : 0.12), color: sCfg.color, fontWeight: 700, fontSize: '0.68rem' }} />
                        </TableCell>
                        <TableCell>
                          {p.cardBrand && (
                            <Typography variant="caption" sx={{ color: dk ? 'rgba(255,255,255,0.5)' : 'text.secondary' }}>
                              {p.cardBrand} ••{p.last4}
                            </Typography>
                          )}
                          {p.transactionId && !p.cardBrand && (
                            <Typography variant="caption" sx={{ fontFamily: 'monospace', fontSize: '0.7rem', color: dk ? 'rgba(255,255,255,0.4)' : 'text.disabled' }}>
                              {p.transactionId}
                            </Typography>
                          )}
                        </TableCell>
                        <TableCell align="center">
                          {p.status === 'APPROVED' && (
                            <Tooltip title="Void Payment" arrow>
                              <IconButton size="small" color="error" onClick={() => handleVoid(p.id)}>
                                <VoidIcon sx={{ fontSize: 16 }} />
                              </IconButton>
                            </Tooltip>
                          )}
                        </TableCell>
                      </TableRow>
                    );
                  })}
                </TableBody>
              </Table>
            </TableContainer>
          </>
        )}
      </DialogContent>

      <DialogActions sx={{ px: 3, py: 2 }}>
        <Button onClick={onClose} sx={{ fontWeight: 600 }}>Close</Button>
      </DialogActions>
    </Dialog>
  );
};

export default PaymentModal;
