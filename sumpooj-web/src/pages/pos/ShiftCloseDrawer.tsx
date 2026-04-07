/**
 * ShiftCloseDrawer.tsx — Shift Close Summary & Confirmation
 *
 * Slides in from the right showing:
 * - Opening cash
 * - Sales breakdown by payment method
 * - Expected cash in drawer
 * - Actual cash count input
 * - Cash difference (over / short)
 * - Optional notes
 * - Confirm close button
 */
import React, { useState, useCallback, useMemo } from 'react';
import {
  Drawer,
  Box,
  Typography,
  TextField,
  Button,
  Divider,
  CircularProgress,
  Alert,
  InputAdornment,
  IconButton,
  Chip,
} from '@mui/material';
import {
  Close as CloseIcon,
  AttachMoney,
  CreditCard,
  PhoneAndroid,
  CardGiftcard,
  MoreHoriz,
  TrendingUp,
  TrendingDown,
  Remove as DashIcon,
} from '@mui/icons-material';
import { useShift } from './ShiftContext';
import { formatCurrency, useCurrency } from '../../core/i18n';

// ─── Summary Row ────────────────────────────────────────────

interface SummaryRowProps {
  icon: React.ReactNode;
  label: string;
  value: number;
  color?: string;
  bold?: boolean;
}

const SummaryRow: React.FC<SummaryRowProps> = ({ icon, label, value, color, bold }) => (
  <Box
    sx={{
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'space-between',
      py: 0.75,
    }}
  >
    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
      {icon}
      <Typography
        variant="body2"
        sx={{ fontWeight: bold ? 600 : 400, color: color || 'text.primary' }}
      >
        {label}
      </Typography>
    </Box>
    <Typography
      variant="body2"
      sx={{ fontWeight: bold ? 700 : 500, fontFamily: 'monospace', color: color || 'text.primary' }}
    >
      {formatCurrency(value)}
    </Typography>
  </Box>
);

// ─── Component ──────────────────────────────────────────────

const ShiftCloseDrawer: React.FC = () => {
  const { activeShift, isCloseDrawerOpen, setCloseDrawerOpen, closeShift, error } = useShift();
  const { currencySymbol } = useCurrency();
  const [closingCash, setClosingCash] = useState('');
  const [notes, setNotes] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [localError, setLocalError] = useState<string | null>(null);

  const cashAmount = parseFloat(closingCash) || 0;
  const expectedCash = activeShift?.expectedCash ?? 0;
  const difference = useMemo(() => cashAmount - expectedCash, [cashAmount, expectedCash]);

  const handleClose = useCallback(async () => {
    const amount = parseFloat(closingCash);
    if (isNaN(amount) || amount < 0) {
      setLocalError('Enter a valid cash count');
      return;
    }
    try {
      setLocalError(null);
      setSubmitting(true);
      await closeShift(amount, notes || undefined);
    } catch {
      setLocalError('Failed to close shift. Please try again.');
    } finally {
      setSubmitting(false);
    }
  }, [closingCash, notes, closeShift]);

  const handleDrawerClose = useCallback(() => {
    if (!submitting) {
      setCloseDrawerOpen(false);
      setClosingCash('');
      setNotes('');
      setLocalError(null);
    }
  }, [submitting, setCloseDrawerOpen]);

  if (!activeShift) return null;

  const totalSales =
    activeShift.cashSales +
    activeShift.cardSales +
    activeShift.upiSales +
    activeShift.giftCardSales +
    activeShift.otherSales;

  return (
    <Drawer
      anchor="right"
      open={isCloseDrawerOpen}
      onClose={handleDrawerClose}
      PaperProps={{
        sx: { width: 400, maxWidth: '100vw' },
      }}
    >
      {/* Header */}
      <Box
        sx={{
          background: 'linear-gradient(135deg, #1e293b 0%, #334155 100%)',
          px: 3,
          py: 2,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
        }}
      >
        <Typography variant="h6" sx={{ color: 'white', fontWeight: 700 }}>
          Close Shift
        </Typography>
        <IconButton onClick={handleDrawerClose} sx={{ color: 'white' }} size="small">
          <CloseIcon />
        </IconButton>
      </Box>

      {/* Shift info */}
      <Box sx={{ px: 3, pt: 2, pb: 1 }}>
        <Typography variant="caption" color="text.secondary">
          Opened by {activeShift.openedByName} at{' '}
          {new Date(activeShift.openedAt).toLocaleTimeString()} &middot;{' '}
          {activeShift.transactionCount} transaction{activeShift.transactionCount !== 1 ? 's' : ''}
        </Typography>
      </Box>

      <Divider />

      {/* Sales Breakdown */}
      <Box sx={{ px: 3, py: 2 }}>
        <Typography variant="subtitle2" sx={{ mb: 1, fontWeight: 600, textTransform: 'uppercase', letterSpacing: 0.5, fontSize: '0.7rem', color: 'text.secondary' }}>
          Sales Breakdown
        </Typography>

        <SummaryRow icon={<AttachMoney fontSize="small" color="success" />} label="Cash Sales" value={activeShift.cashSales} />
        <SummaryRow icon={<CreditCard fontSize="small" color="primary" />} label="Card Sales" value={activeShift.cardSales} />
        <SummaryRow icon={<PhoneAndroid fontSize="small" color="secondary" />} label="UPI Sales" value={activeShift.upiSales} />
        <SummaryRow icon={<CardGiftcard fontSize="small" color="warning" />} label="Gift Card" value={activeShift.giftCardSales} />
        <SummaryRow icon={<MoreHoriz fontSize="small" color="action" />} label="Other" value={activeShift.otherSales} />

        <Divider sx={{ my: 1 }} />

        <SummaryRow icon={<TrendingUp fontSize="small" />} label="Total Sales" value={totalSales} bold />
        <SummaryRow icon={<DashIcon fontSize="small" color="error" />} label="Refunds" value={activeShift.totalRefunds} color="#ef4444" />
        <SummaryRow icon={<DashIcon fontSize="small" color="error" />} label="Paid Outs" value={activeShift.paidOuts} color="#ef4444" />
      </Box>

      <Divider />

      {/* Cash Drawer */}
      <Box sx={{ px: 3, py: 2 }}>
        <Typography variant="subtitle2" sx={{ mb: 1.5, fontWeight: 600, textTransform: 'uppercase', letterSpacing: 0.5, fontSize: '0.7rem', color: 'text.secondary' }}>
          Cash Drawer
        </Typography>

        <SummaryRow icon={<AttachMoney fontSize="small" />} label="Opening Cash" value={activeShift.openingCash} />
        <SummaryRow icon={<AttachMoney fontSize="small" color="success" />} label="Expected Cash" value={expectedCash} bold />

        <TextField
          fullWidth
          label="Actual Cash Count"
          type="number"
          value={closingCash}
          onChange={(e) => {
            setClosingCash(e.target.value);
            setLocalError(null);
          }}
          slotProps={{
            input: {
              startAdornment: <InputAdornment position="start">{currencySymbol}</InputAdornment>,
            },
          }}
          placeholder="0.00"
          disabled={submitting}
          sx={{ mt: 1.5, mb: 1 }}
        />

        {closingCash && (
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mt: 0.5 }}>
            <Typography variant="body2" color="text.secondary">
              Difference:
            </Typography>
            <Chip
              size="small"
              icon={difference > 0 ? <TrendingUp fontSize="small" /> : difference < 0 ? <TrendingDown fontSize="small" /> : undefined}
              label={`${difference >= 0 ? '+' : ''}${formatCurrency(Math.abs(difference))}`}
              color={difference === 0 ? 'success' : Math.abs(difference) <= 5 ? 'warning' : 'error'}
              variant="outlined"
            />
          </Box>
        )}
      </Box>

      <Divider />

      {/* Notes */}
      <Box sx={{ px: 3, py: 2 }}>
        <TextField
          fullWidth
          label="Notes (optional)"
          multiline
          rows={2}
          value={notes}
          onChange={(e) => setNotes(e.target.value)}
          disabled={submitting}
          placeholder="Any notes about this shift..."
        />
      </Box>

      {/* Errors */}
      {(error || localError) && (
        <Box sx={{ px: 3, pb: 1 }}>
          <Alert severity="error">{localError || error}</Alert>
        </Box>
      )}

      {/* Actions */}
      <Box sx={{ px: 3, pb: 3, mt: 'auto' }}>
        <Button
          onClick={handleClose}
          variant="contained"
          color="error"
          fullWidth
          size="large"
          disabled={submitting || !closingCash}
          sx={{ py: 1.2, fontWeight: 600, borderRadius: 2 }}
        >
          {submitting ? (
            <CircularProgress size={22} color="inherit" />
          ) : (
            'Confirm & Close Shift'
          )}
        </Button>
      </Box>
    </Drawer>
  );
};

export default ShiftCloseDrawer;
