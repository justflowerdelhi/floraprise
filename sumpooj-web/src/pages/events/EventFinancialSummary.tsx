/**
 * EventFinancialSummary.tsx — Financial Summary Panel
 *
 * Phase 3: Payment Schedule & Deposit Tracking
 * Displays large, readable financial overview with:
 * - Proposal Grand Total
 * - Total Paid
 * - Balance Remaining
 * - Next Due Payment
 * - Overdue Indicator
 */
import React from 'react';
import {
  Box,
  Paper,
  Typography,
  Chip,
  LinearProgress,
  Tooltip,
  IconButton,
  Stack,
  Alert,
  Divider,
  Button,
} from '@mui/material';
import {
  AccountBalance as TotalIcon,
  CheckCircle as PaidIcon,
  Schedule as PendingIcon,
  Warning as WarningIcon,
  Info as InfoIcon,
  CalendarMonth as DueDateIcon,
  Error as OverdueIcon,
} from '@mui/icons-material';
import type {
  EventFinancialSummaryData,
  EventPaymentSchedule,
  PaymentWarning,
} from './PaymentScheduleTypes';
import { PAYMENT_SCHEDULE_STATUS_CONFIG } from './PaymentScheduleTypes';

// ─── Styling Constants ──────────────────────────────────────

const cardBg = '#1a1a2e';
const borderColor = '#2d2d44';
const yellowAccent = '#fdd835';

// ─── Format Functions ───────────────────────────────────────

const formatCurrency = (amount: number): string => {
  return new Intl.NumberFormat('en-IN', {
    style: 'currency',
    currency: 'INR',
    maximumFractionDigits: 0,
  }).format(amount);
};

const formatDate = (dateString: string): string => {
  if (!dateString) return '-';
  return new Date(dateString).toLocaleDateString('en-IN', {
    day: 'numeric',
    month: 'short',
    year: 'numeric',
  });
};

const getDaysUntilDue = (dueDate: string): number => {
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const due = new Date(dueDate);
  due.setHours(0, 0, 0, 0);
  return Math.ceil((due.getTime() - today.getTime()) / (1000 * 60 * 60 * 24));
};

// ─── Metric Card Component ──────────────────────────────────

interface MetricCardProps {
  label: string;
  value: string;
  subValue?: string;
  icon: React.ReactNode;
  color?: string;
  large?: boolean;
}

const MetricCard: React.FC<MetricCardProps> = ({
  label,
  value,
  subValue,
  icon,
  color = '#fff',
  large = false,
}) => (
  <Box
    sx={{
      p: 2.5,
      borderRadius: 2,
      backgroundColor: 'rgba(0,0,0,0.2)',
      border: `1px solid ${borderColor}`,
      display: 'flex',
      alignItems: 'center',
      gap: 2,
    }}
  >
    <Box
      sx={{
        width: large ? 56 : 48,
        height: large ? 56 : 48,
        borderRadius: 2,
        backgroundColor: `${color}15`,
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        color: color,
      }}
    >
      {icon}
    </Box>
    <Box sx={{ flex: 1 }}>
      <Typography
        variant="caption"
        sx={{ color: '#888', textTransform: 'uppercase', fontSize: '0.65rem' }}
      >
        {label}
      </Typography>
      <Typography
        variant={large ? 'h4' : 'h5'}
        sx={{ color, fontWeight: 700, fontFamily: 'monospace', lineHeight: 1.2 }}
      >
        {value}
      </Typography>
      {subValue && (
        <Typography variant="caption" sx={{ color: '#666' }}>
          {subValue}
        </Typography>
      )}
    </Box>
  </Box>
);

// ─── Next Due Card Component ────────────────────────────────

interface NextDueCardProps {
  payment: EventPaymentSchedule | null;
  onRecordPayment?: () => void;
}

const NextDueCard: React.FC<NextDueCardProps> = ({ payment, onRecordPayment }) => {
  if (!payment) {
    return (
      <Box
        sx={{
          p: 2.5,
          borderRadius: 2,
          backgroundColor: 'rgba(76, 175, 80, 0.08)',
          border: '1px solid rgba(76, 175, 80, 0.3)',
        }}
      >
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 1 }}>
          <PaidIcon sx={{ color: '#4caf50' }} />
          <Typography variant="subtitle2" sx={{ color: '#4caf50', fontWeight: 600 }}>
            All Payments Complete
          </Typography>
        </Box>
        <Typography variant="body2" sx={{ color: '#888' }}>
          No outstanding payments
        </Typography>
      </Box>
    );
  }

  const daysUntil = getDaysUntilDue(payment.dueDate);
  const isOverdue = daysUntil < 0;
  const isUrgent = daysUntil >= 0 && daysUntil <= 7;
  const statusConfig = PAYMENT_SCHEDULE_STATUS_CONFIG[payment.status];

  return (
    <Box
      sx={{
        p: 2.5,
        borderRadius: 2,
        backgroundColor: isOverdue
          ? 'rgba(244, 67, 54, 0.08)'
          : isUrgent
            ? 'rgba(255, 152, 0, 0.08)'
            : 'rgba(33, 150, 243, 0.08)',
        border: `1px solid ${isOverdue ? 'rgba(244, 67, 54, 0.3)' : isUrgent ? 'rgba(255, 152, 0, 0.3)' : 'rgba(33, 150, 243, 0.3)'}`,
      }}
    >
      <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', mb: 1 }}>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
          {isOverdue ? (
            <OverdueIcon sx={{ color: '#f44336' }} />
          ) : (
            <DueDateIcon sx={{ color: isUrgent ? '#ff9800' : '#2196f3' }} />
          )}
          <Typography
            variant="subtitle2"
            sx={{ color: isOverdue ? '#f44336' : isUrgent ? '#ff9800' : '#2196f3', fontWeight: 600 }}
          >
            {isOverdue ? 'Overdue' : 'Next Payment Due'}
          </Typography>
        </Box>
        <Chip
          label={payment.label}
          size="small"
          sx={{
            backgroundColor: statusConfig.bgColor,
            color: statusConfig.color,
            fontSize: '0.7rem',
          }}
        />
      </Box>

      <Typography variant="h5" sx={{ color: '#fff', fontWeight: 700, fontFamily: 'monospace', mb: 0.5 }}>
        {formatCurrency(payment.amount - payment.amountPaid)}
      </Typography>

      <Typography variant="body2" sx={{ color: '#888', mb: 1 }}>
        Due: {formatDate(payment.dueDate)}
        {isOverdue ? (
          <Typography component="span" sx={{ color: '#f44336', ml: 1 }}>
            ({Math.abs(daysUntil)} days overdue)
          </Typography>
        ) : (
          <Typography component="span" sx={{ color: isUrgent ? '#ff9800' : '#888', ml: 1 }}>
            ({daysUntil === 0 ? 'Today' : `${daysUntil} days`})
          </Typography>
        )}
      </Typography>

      {payment.amountPaid > 0 && (
        <Typography variant="caption" sx={{ color: '#4caf50' }}>
          Partial: {formatCurrency(payment.amountPaid)} paid
        </Typography>
      )}

      {onRecordPayment && (
        <Button
          size="small"
          onClick={onRecordPayment}
          sx={{
            mt: 1.5,
            color: isOverdue ? '#f44336' : isUrgent ? '#ff9800' : '#2196f3',
            textTransform: 'none',
            fontWeight: 600,
            '&:hover': {
              backgroundColor: isOverdue
                ? 'rgba(244, 67, 54, 0.1)'
                : isUrgent
                  ? 'rgba(255, 152, 0, 0.1)'
                  : 'rgba(33, 150, 243, 0.1)',
            },
          }}
        >
          Record Payment →
        </Button>
      )}
    </Box>
  );
};

// ─── Warning Alert Component ────────────────────────────────

interface WarningAlertProps {
  warnings: PaymentWarning[];
  onAction?: (warning: PaymentWarning) => void;
}

const WarningAlert: React.FC<WarningAlertProps> = ({ warnings, onAction }) => {
  if (warnings.length === 0) return null;

  return (
    <Stack spacing={1} sx={{ mb: 2 }}>
      {warnings.map((warning, index) => (
        <Alert
          key={index}
          severity={warning.severity}
          sx={{
            backgroundColor:
              warning.severity === 'error' ? 'rgba(244, 67, 54, 0.1)' : 'rgba(255, 152, 0, 0.1)',
            border: `1px solid ${warning.severity === 'error' ? '#f44336' : '#ff9800'}`,
            '& .MuiAlert-message': { color: '#fff' },
            '& .MuiAlert-icon': {
              color: warning.severity === 'error' ? '#f44336' : '#ff9800',
            },
          }}
          action={
            warning.actionLabel && onAction ? (
              <Chip
                label={warning.actionLabel}
                size="small"
                onClick={() => onAction(warning)}
                sx={{
                  backgroundColor: `${warning.severity === 'error' ? '#f44336' : '#ff9800'}20`,
                  color: warning.severity === 'error' ? '#f44336' : '#ff9800',
                  cursor: 'pointer',
                  '&:hover': {
                    backgroundColor: `${warning.severity === 'error' ? '#f44336' : '#ff9800'}30`,
                  },
                }}
              />
            ) : undefined
          }
        >
          {warning.message}
        </Alert>
      ))}
    </Stack>
  );
};

// ─── Main Component ─────────────────────────────────────────

interface EventFinancialSummaryProps {
  summary: EventFinancialSummaryData;
  warnings?: PaymentWarning[];
  onRecordPayment?: () => void;
  onWarningAction?: (warning: PaymentWarning) => void;
  readonly?: boolean;
}

const EventFinancialSummary: React.FC<EventFinancialSummaryProps> = ({
  summary,
  warnings = [],
  onRecordPayment,
  onWarningAction,
  readonly = false,
}) => {
  const {
    proposalGrandTotal,
    totalPaid,
    balanceRemaining,
    paymentProgress,
    nextDuePayment,
    overduePayments,
    depositPaid,
  } = summary;

  // Determine overall status color
  const statusColor =
    balanceRemaining <= 0
      ? '#4caf50'
      : overduePayments.length > 0
        ? '#f44336'
        : '#ff9800';

  return (
    <Paper
      sx={{
        backgroundColor: cardBg,
        border: `1px solid ${borderColor}`,
        borderRadius: 2,
        p: 3,
      }}
    >
      {/* Header */}
      <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', mb: 2 }}>
        <Typography variant="h6" sx={{ color: '#fff', fontWeight: 600 }}>
          Financial Summary
        </Typography>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
          {depositPaid ? (
            <Chip
              icon={<PaidIcon />}
              label="Deposit Secured"
              size="small"
              sx={{
                backgroundColor: 'rgba(76, 175, 80, 0.15)',
                color: '#4caf50',
                '& .MuiChip-icon': { color: '#4caf50' },
              }}
            />
          ) : (
            <Chip
              icon={<WarningIcon />}
              label="Awaiting Deposit"
              size="small"
              sx={{
                backgroundColor: 'rgba(255, 152, 0, 0.15)',
                color: '#ff9800',
                '& .MuiChip-icon': { color: '#ff9800' },
              }}
            />
          )}
          <Tooltip title="Payment summary for this event">
            <IconButton size="small" sx={{ color: '#666' }}>
              <InfoIcon fontSize="small" />
            </IconButton>
          </Tooltip>
        </Box>
      </Box>

      {/* Warnings */}
      <WarningAlert warnings={warnings} onAction={onWarningAction} />

      {/* Progress Bar */}
      <Box sx={{ mb: 3 }}>
        <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', mb: 1 }}>
          <Typography variant="body2" sx={{ color: '#888' }}>
            Payment Progress
          </Typography>
          <Typography
            variant="body2"
            sx={{ color: statusColor, fontWeight: 600, fontFamily: 'monospace' }}
          >
            {paymentProgress.toFixed(0)}%
          </Typography>
        </Box>
        <LinearProgress
          variant="determinate"
          value={Math.min(paymentProgress, 100)}
          sx={{
            height: 10,
            borderRadius: 5,
            backgroundColor: '#2d2d44',
            '& .MuiLinearProgress-bar': {
              backgroundColor: statusColor,
              borderRadius: 5,
            },
          }}
        />
        <Box sx={{ display: 'flex', justifyContent: 'space-between', mt: 0.5 }}>
          <Typography variant="caption" sx={{ color: '#666' }}>
            {formatCurrency(totalPaid)} paid
          </Typography>
          <Typography variant="caption" sx={{ color: '#666' }}>
            {formatCurrency(proposalGrandTotal)} total
          </Typography>
        </Box>
      </Box>

      {/* Metrics Grid */}
      <Box
        sx={{
          display: 'grid',
          gridTemplateColumns: { xs: '1fr', sm: '1fr 1fr' },
          gap: 2,
          mb: 3,
        }}
      >
        <MetricCard
          label="Proposal Total"
          value={formatCurrency(proposalGrandTotal)}
          icon={<TotalIcon sx={{ fontSize: 28 }} />}
          color={yellowAccent}
          large
        />
        <MetricCard
          label="Total Paid"
          value={formatCurrency(totalPaid)}
          icon={<PaidIcon sx={{ fontSize: 28 }} />}
          color="#4caf50"
          large
        />
        <MetricCard
          label="Balance Remaining"
          value={formatCurrency(balanceRemaining)}
          subValue={balanceRemaining > 0 ? `${summary.scheduleItems.filter(s => s.status !== 'PAID').length} payments pending` : 'Fully paid'}
          icon={<PendingIcon sx={{ fontSize: 24 }} />}
          color={balanceRemaining > 0 ? '#ff9800' : '#4caf50'}
        />
        <MetricCard
          label="Overdue"
          value={overduePayments.length > 0 ? formatCurrency(overduePayments.reduce((sum, p) => sum + (p.amount - p.amountPaid), 0)) : '₹0'}
          subValue={overduePayments.length > 0 ? `${overduePayments.length} overdue payment(s)` : 'No overdue'}
          icon={<OverdueIcon sx={{ fontSize: 24 }} />}
          color={overduePayments.length > 0 ? '#f44336' : '#4caf50'}
        />
      </Box>

      <Divider sx={{ borderColor, my: 2 }} />

      {/* Next Due Payment */}
      <NextDueCard payment={nextDuePayment} onRecordPayment={readonly ? undefined : onRecordPayment} />
    </Paper>
  );
};

export default EventFinancialSummary;
