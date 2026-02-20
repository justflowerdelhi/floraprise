/**
 * PaymentSchedulePanel.tsx — Payment Schedule Management
 *
 * Phase 3: Payment Schedule & Deposit Tracking
 * Features:
 * - Manual entry of payment milestones
 * - Auto-generate from templates (30/40/30, 50/50, Full)
 * - Record payment modal integration
 * - Status tracking with color indicators
 * - Role-based actions (Designer: view only; Manager/Admin: full control)
 */
import React, { useState, useCallback } from 'react';
import {
  Box,
  Paper,
  Typography,
  Button,
  IconButton,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Chip,
  TextField,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Menu,
  MenuItem,
  ListItemIcon,
  ListItemText,
  Tooltip,
  LinearProgress,
  Stack,
  Alert,
  Divider,
} from '@mui/material';
import {
  Add as AddIcon,
  Delete as DeleteIcon,
  Payment as PaymentIcon,
  Schedule as ScheduleIcon,
  CheckCircle as PaidIcon,
  Warning as OverdueIcon,
  PieChart as PartialIcon,
  MoreVert as MoreIcon,
  AutoAwesome as AutoIcon,
  History as HistoryIcon,
  Receipt as ReceiptIcon,
} from '@mui/icons-material';
import type {
  EventPaymentSchedule,
  PaymentPlanTemplate,
} from './PaymentScheduleTypes';
import {
  PAYMENT_SCHEDULE_STATUS_CONFIG,
  PAYMENT_PLAN_TEMPLATES,
  createCustomScheduleItem,
  generatePaymentSchedule,
  calculateScheduleStatus,
} from './PaymentScheduleTypes';
import { getPaymentsForSchedule, type MockPaymentRecord } from './PaymentScheduleMockData';
import { formatCurrency, getCurrencySymbol } from '../../core/i18n';

// ─── Styling Constants ──────────────────────────────────────

const cardBg = '#1a1a2e';
const borderColor = '#2d2d44';
const yellowAccent = '#fdd835';

// ─── Format Functions ───────────────────────────────────────

const formatDate = (dateString: string): string => {
  if (!dateString) return '-';
  return new Date(dateString).toLocaleDateString('en-IN', {
    day: 'numeric',
    month: 'short',
    year: 'numeric',
  });
};

// ─── Status Icon Component ──────────────────────────────────

const StatusIcon: React.FC<{ status: EventPaymentSchedule['status'] }> = ({ status }) => {
  const icons: Record<string, React.ReactNode> = {
    PENDING: <ScheduleIcon fontSize="small" />,
    PAID: <PaidIcon fontSize="small" />,
    OVERDUE: <OverdueIcon fontSize="small" />,
    PARTIAL: <PartialIcon fontSize="small" />,
  };
  return <>{icons[status]}</>;
};

// ─── Add Milestone Dialog ───────────────────────────────────

interface AddMilestoneDialogProps {
  open: boolean;
  onClose: () => void;
  onAdd: (label: string, dueDate: string, amount: number) => void;
}

const AddMilestoneDialog: React.FC<AddMilestoneDialogProps> = ({ open, onClose, onAdd }) => {
  const [label, setLabel] = useState('');
  const [dueDate, setDueDate] = useState('');
  const [amount, setAmount] = useState('');

  const handleSubmit = () => {
    if (label && dueDate && amount) {
      onAdd(label, dueDate, Number(amount));
      setLabel('');
      setDueDate('');
      setAmount('');
      onClose();
    }
  };

  return (
    <Dialog open={open} onClose={onClose} maxWidth="xs" fullWidth>
      <DialogTitle sx={{ backgroundColor: cardBg, color: '#fff', borderBottom: `1px solid ${borderColor}` }}>
        Add Payment Milestone
      </DialogTitle>
      <DialogContent sx={{ backgroundColor: cardBg, pt: 3 }}>
        <Stack spacing={2.5} sx={{ mt: 1 }}>
          <TextField
            label="Label"
            placeholder="e.g., Booking Deposit"
            fullWidth
            value={label}
            onChange={(e) => setLabel(e.target.value)}
            sx={{
              '& .MuiOutlinedInput-root': {
                backgroundColor: '#0f0f0f',
                '& fieldset': { borderColor },
              },
              '& .MuiInputBase-input': { color: '#fff' },
              '& .MuiInputLabel-root': { color: '#888' },
            }}
          />
          <TextField
            label="Due Date"
            type="date"
            fullWidth
            value={dueDate}
            onChange={(e) => setDueDate(e.target.value)}
            InputLabelProps={{ shrink: true }}
            sx={{
              '& .MuiOutlinedInput-root': {
                backgroundColor: '#0f0f0f',
                '& fieldset': { borderColor },
              },
              '& .MuiInputBase-input': { color: '#fff' },
              '& .MuiInputLabel-root': { color: '#888' },
            }}
          />
          <TextField
            label="Amount"
            type="number"
            fullWidth
            value={amount}
            onChange={(e) => setAmount(e.target.value)}
            InputProps={{
              startAdornment: <Typography sx={{ color: '#888', mr: 0.5 }}>{getCurrencySymbol()}</Typography>,
            }}
            sx={{
              '& .MuiOutlinedInput-root': {
                backgroundColor: '#0f0f0f',
                '& fieldset': { borderColor },
              },
              '& .MuiInputBase-input': { color: '#fff' },
              '& .MuiInputLabel-root': { color: '#888' },
            }}
          />
        </Stack>
      </DialogContent>
      <DialogActions sx={{ backgroundColor: cardBg, borderTop: `1px solid ${borderColor}`, p: 2 }}>
        <Button onClick={onClose} sx={{ color: '#888' }}>
          Cancel
        </Button>
        <Button
          variant="contained"
          onClick={handleSubmit}
          disabled={!label || !dueDate || !amount}
          sx={{
            backgroundColor: yellowAccent,
            color: '#000',
            '&:hover': { backgroundColor: '#fbc02d' },
          }}
        >
          Add Milestone
        </Button>
      </DialogActions>
    </Dialog>
  );
};

// ─── Record Payment Dialog ──────────────────────────────────

interface RecordPaymentDialogProps {
  open: boolean;
  onClose: () => void;
  schedule: EventPaymentSchedule | null;
  onRecord: (scheduleId: string, amount: number, method: string, reference?: string) => void;
}

const RecordPaymentDialog: React.FC<RecordPaymentDialogProps> = ({
  open,
  onClose,
  schedule,
  onRecord,
}) => {
  const [amount, setAmount] = useState('');
  const [method, setMethod] = useState<string>('CASH');
  const [reference, setReference] = useState('');

  // Reset form when schedule changes
  React.useEffect(() => {
    if (schedule) {
      setAmount(String(schedule.amount - schedule.amountPaid));
      setMethod('CASH');
      setReference('');
    }
  }, [schedule]);

  const handleSubmit = () => {
    if (schedule && amount) {
      onRecord(schedule.id, Number(amount), method, reference || undefined);
      onClose();
    }
  };

  if (!schedule) return null;

  const balanceDue = schedule.amount - schedule.amountPaid;

  return (
    <Dialog open={open} onClose={onClose} maxWidth="sm" fullWidth>
      <DialogTitle sx={{ backgroundColor: cardBg, color: '#fff', borderBottom: `1px solid ${borderColor}` }}>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
          <PaymentIcon />
          Record Payment
        </Box>
      </DialogTitle>
      <DialogContent sx={{ backgroundColor: cardBg, pt: 3 }}>
        {/* Schedule Info */}
        <Paper sx={{ backgroundColor: '#0f0f0f', p: 2, mb: 3, borderRadius: 2 }}>
          <Typography variant="subtitle2" sx={{ color: '#888', mb: 1 }}>
            Payment For
          </Typography>
          <Typography variant="h6" sx={{ color: '#fff', fontWeight: 600 }}>
            {schedule.label}
          </Typography>
          <Box sx={{ display: 'flex', gap: 3, mt: 1 }}>
            <Box>
              <Typography variant="caption" sx={{ color: '#666' }}>
                Total Due
              </Typography>
              <Typography sx={{ color: '#fff', fontFamily: 'monospace' }}>
                {formatCurrency(schedule.amount)}
              </Typography>
            </Box>
            <Box>
              <Typography variant="caption" sx={{ color: '#666' }}>
                Already Paid
              </Typography>
              <Typography sx={{ color: '#4caf50', fontFamily: 'monospace' }}>
                {formatCurrency(schedule.amountPaid)}
              </Typography>
            </Box>
            <Box>
              <Typography variant="caption" sx={{ color: '#666' }}>
                Balance
              </Typography>
              <Typography sx={{ color: yellowAccent, fontFamily: 'monospace', fontWeight: 600 }}>
                {formatCurrency(balanceDue)}
              </Typography>
            </Box>
          </Box>
        </Paper>

        <Stack spacing={2.5}>
          <TextField
            label="Amount"
            type="number"
            fullWidth
            value={amount}
            onChange={(e) => setAmount(e.target.value)}
            InputProps={{
              startAdornment: <Typography sx={{ color: '#888', mr: 0.5 }}>{getCurrencySymbol()}</Typography>,
            }}
            helperText={Number(amount) > balanceDue ? 'Amount exceeds balance due' : ''}
            error={Number(amount) > balanceDue}
            sx={{
              '& .MuiOutlinedInput-root': {
                backgroundColor: '#0f0f0f',
                '& fieldset': { borderColor },
              },
              '& .MuiInputBase-input': { color: '#fff' },
              '& .MuiInputLabel-root': { color: '#888' },
            }}
          />

          <TextField
            select
            label="Payment Method"
            fullWidth
            value={method}
            onChange={(e) => setMethod(e.target.value)}
            sx={{
              '& .MuiOutlinedInput-root': {
                backgroundColor: '#0f0f0f',
                '& fieldset': { borderColor },
              },
              '& .MuiSelect-select': { color: '#fff' },
              '& .MuiInputLabel-root': { color: '#888' },
            }}
          >
            <MenuItem value="CASH">Cash</MenuItem>
            <MenuItem value="CARD">Credit/Debit Card</MenuItem>
            <MenuItem value="BANK_TRANSFER">Bank Transfer</MenuItem>
            <MenuItem value="UPI">UPI</MenuItem>
            <MenuItem value="CHEQUE">Cheque</MenuItem>
          </TextField>

          <TextField
            label="Reference (optional)"
            placeholder="Transaction ID, Cheque No., etc."
            fullWidth
            value={reference}
            onChange={(e) => setReference(e.target.value)}
            sx={{
              '& .MuiOutlinedInput-root': {
                backgroundColor: '#0f0f0f',
                '& fieldset': { borderColor },
              },
              '& .MuiInputBase-input': { color: '#fff' },
              '& .MuiInputLabel-root': { color: '#888' },
            }}
          />
        </Stack>
      </DialogContent>
      <DialogActions sx={{ backgroundColor: cardBg, borderTop: `1px solid ${borderColor}`, p: 2 }}>
        <Button onClick={onClose} sx={{ color: '#888' }}>
          Cancel
        </Button>
        <Button
          variant="contained"
          onClick={handleSubmit}
          disabled={!amount || Number(amount) <= 0 || Number(amount) > balanceDue}
          startIcon={<PaymentIcon />}
          sx={{
            backgroundColor: '#4caf50',
            color: '#fff',
            '&:hover': { backgroundColor: '#43a047' },
          }}
        >
          Record Payment
        </Button>
      </DialogActions>
    </Dialog>
  );
};

// ─── Payment History Dialog ─────────────────────────────────

interface PaymentHistoryDialogProps {
  open: boolean;
  onClose: () => void;
  schedule: EventPaymentSchedule | null;
  payments: MockPaymentRecord[];
}

const PaymentHistoryDialog: React.FC<PaymentHistoryDialogProps> = ({
  open,
  onClose,
  schedule,
  payments,
}) => {
  if (!schedule) return null;

  return (
    <Dialog open={open} onClose={onClose} maxWidth="sm" fullWidth>
      <DialogTitle sx={{ backgroundColor: cardBg, color: '#fff', borderBottom: `1px solid ${borderColor}` }}>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
          <HistoryIcon />
          Payment History - {schedule.label}
        </Box>
      </DialogTitle>
      <DialogContent sx={{ backgroundColor: cardBg, p: 0 }}>
        {payments.length === 0 ? (
          <Box sx={{ p: 4, textAlign: 'center' }}>
            <Typography sx={{ color: '#888' }}>No payments recorded yet</Typography>
          </Box>
        ) : (
          <Table size="small">
            <TableHead>
              <TableRow sx={{ '& th': { color: '#888', borderColor } }}>
                <TableCell>Date</TableCell>
                <TableCell>Method</TableCell>
                <TableCell align="right">Amount</TableCell>
                <TableCell>Reference</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {payments.map((payment) => (
                <TableRow key={payment.id} sx={{ '& td': { color: '#fff', borderColor } }}>
                  <TableCell>{formatDate(payment.recordedAt)}</TableCell>
                  <TableCell>
                    <Chip
                      label={payment.method}
                      size="small"
                      sx={{ backgroundColor: '#333', color: '#fff', fontSize: '0.7rem' }}
                    />
                  </TableCell>
                  <TableCell align="right" sx={{ fontFamily: 'monospace', color: '#4caf50' }}>
                    {formatCurrency(payment.amount)}
                  </TableCell>
                  <TableCell>
                    <Typography variant="caption" sx={{ color: '#888' }}>
                      {payment.reference || '-'}
                    </Typography>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        )}
      </DialogContent>
      <DialogActions sx={{ backgroundColor: cardBg, borderTop: `1px solid ${borderColor}`, p: 2 }}>
        <Button onClick={onClose} sx={{ color: '#888' }}>
          Close
        </Button>
      </DialogActions>
    </Dialog>
  );
};

// ─── Schedule Row Component ─────────────────────────────────

interface ScheduleRowProps {
  schedule: EventPaymentSchedule;
  onRecordPayment: () => void;
  onViewHistory: () => void;
  onDelete: () => void;
  readonly?: boolean;
}

const ScheduleRow: React.FC<ScheduleRowProps> = ({
  schedule,
  onRecordPayment,
  onViewHistory,
  onDelete,
  readonly = false,
}) => {
  const [anchorEl, setAnchorEl] = useState<null | HTMLElement>(null);
  const statusConfig = PAYMENT_SCHEDULE_STATUS_CONFIG[schedule.status];
  const progress = schedule.amount > 0 ? (schedule.amountPaid / schedule.amount) * 100 : 0;
  const balanceDue = schedule.amount - schedule.amountPaid;

  return (
    <TableRow
      sx={{
        '& td': { borderColor, py: 1.5 },
        backgroundColor:
          schedule.status === 'OVERDUE'
            ? 'rgba(244, 67, 54, 0.05)'
            : schedule.status === 'PAID'
              ? 'rgba(76, 175, 80, 0.05)'
              : 'transparent',
      }}
    >
      {/* Label */}
      <TableCell>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
          <Chip
            icon={<StatusIcon status={schedule.status} />}
            label={statusConfig.label}
            size="small"
            sx={{
              backgroundColor: statusConfig.bgColor,
              color: statusConfig.color,
              '& .MuiChip-icon': { color: statusConfig.color },
              fontSize: '0.7rem',
            }}
          />
          <Typography variant="body2" sx={{ color: '#fff', fontWeight: 600 }}>
            {schedule.label}
          </Typography>
        </Box>
      </TableCell>

      {/* Due Date */}
      <TableCell>
        <Typography variant="body2" sx={{ color: schedule.status === 'OVERDUE' ? '#f44336' : '#888' }}>
          {formatDate(schedule.dueDate)}
        </Typography>
      </TableCell>

      {/* Amount */}
      <TableCell align="right">
        <Typography sx={{ color: '#fff', fontFamily: 'monospace', fontWeight: 600 }}>
          {formatCurrency(schedule.amount)}
        </Typography>
      </TableCell>

      {/* Paid */}
      <TableCell align="right">
        <Typography sx={{ color: '#4caf50', fontFamily: 'monospace' }}>
          {formatCurrency(schedule.amountPaid)}
        </Typography>
        {schedule.amountPaid > 0 && schedule.status !== 'PAID' && (
          <LinearProgress
            variant="determinate"
            value={progress}
            sx={{
              height: 4,
              borderRadius: 2,
              mt: 0.5,
              backgroundColor: '#333',
              '& .MuiLinearProgress-bar': { backgroundColor: '#4caf50' },
            }}
          />
        )}
      </TableCell>

      {/* Balance */}
      <TableCell align="right">
        <Typography
          sx={{
            color: balanceDue > 0 ? '#ff9800' : '#4caf50',
            fontFamily: 'monospace',
            fontWeight: balanceDue > 0 ? 600 : 400,
          }}
        >
          {formatCurrency(balanceDue)}
        </Typography>
      </TableCell>

      {/* Actions */}
      <TableCell align="right">
        {!readonly && (
          <>
            {schedule.status !== 'PAID' && (
              <Tooltip title="Record Payment">
                <IconButton
                  size="small"
                  onClick={onRecordPayment}
                  sx={{ color: '#4caf50', '&:hover': { backgroundColor: 'rgba(76, 175, 80, 0.1)' } }}
                >
                  <PaymentIcon fontSize="small" />
                </IconButton>
              </Tooltip>
            )}
            <IconButton
              size="small"
              onClick={(e) => setAnchorEl(e.currentTarget)}
              sx={{ color: '#888' }}
            >
              <MoreIcon fontSize="small" />
            </IconButton>
            <Menu
              anchorEl={anchorEl}
              open={Boolean(anchorEl)}
              onClose={() => setAnchorEl(null)}
              PaperProps={{
                sx: { backgroundColor: cardBg, border: `1px solid ${borderColor}` },
              }}
            >
              <MenuItem
                onClick={() => {
                  onViewHistory();
                  setAnchorEl(null);
                }}
              >
                <ListItemIcon>
                  <HistoryIcon fontSize="small" sx={{ color: '#888' }} />
                </ListItemIcon>
                <ListItemText sx={{ '& .MuiTypography-root': { color: '#fff' } }}>
                  Payment History
                </ListItemText>
              </MenuItem>
              <MenuItem
                onClick={() => {
                  onDelete();
                  setAnchorEl(null);
                }}
              >
                <ListItemIcon>
                  <DeleteIcon fontSize="small" sx={{ color: '#ef5350' }} />
                </ListItemIcon>
                <ListItemText sx={{ '& .MuiTypography-root': { color: '#ef5350' } }}>
                  Delete
                </ListItemText>
              </MenuItem>
            </Menu>
          </>
        )}
        {readonly && schedule.linkedPaymentIds.length > 0 && (
          <Tooltip title="View History">
            <IconButton size="small" onClick={onViewHistory} sx={{ color: '#888' }}>
              <HistoryIcon fontSize="small" />
            </IconButton>
          </Tooltip>
        )}
      </TableCell>
    </TableRow>
  );
};

// ─── Main Component ─────────────────────────────────────────

interface PaymentSchedulePanelProps {
  eventId: string;
  proposalId: string;
  proposalGrandTotal: number;
  eventDate: string;
  schedules: EventPaymentSchedule[];
  onSchedulesChange?: (schedules: EventPaymentSchedule[]) => void;
  readonly?: boolean;
}

const PaymentSchedulePanel: React.FC<PaymentSchedulePanelProps> = ({
  eventId,
  proposalId,
  proposalGrandTotal,
  eventDate,
  schedules,
  onSchedulesChange,
  readonly = false,
}) => {
  // State
  const [localSchedules, setLocalSchedules] = useState<EventPaymentSchedule[]>(schedules);
  const [showAddDialog, setShowAddDialog] = useState(false);
  const [showRecordDialog, setShowRecordDialog] = useState(false);
  const [showHistoryDialog, setShowHistoryDialog] = useState(false);
  const [selectedSchedule, setSelectedSchedule] = useState<EventPaymentSchedule | null>(null);
  const [templateMenuAnchor, setTemplateMenuAnchor] = useState<null | HTMLElement>(null);

  // Calculate totals
  const totalScheduled = localSchedules.reduce((sum, s) => sum + s.amount, 0);
  const totalPaid = localSchedules.reduce((sum, s) => sum + s.amountPaid, 0);
  const unscheduledAmount = proposalGrandTotal - totalScheduled;

  // Handlers
  const handleAddMilestone = useCallback(
    (label: string, dueDate: string, amount: number) => {
      const newItem = createCustomScheduleItem(eventId, proposalId, label, dueDate, amount);
      const updated = [...localSchedules, newItem];
      setLocalSchedules(updated);
      onSchedulesChange?.(updated);
    },
    [eventId, proposalId, localSchedules, onSchedulesChange]
  );

  const handleGenerateFromTemplate = useCallback(
    (template: PaymentPlanTemplate) => {
      const newSchedules = generatePaymentSchedule(
        eventId,
        proposalId,
        proposalGrandTotal,
        eventDate,
        template
      );
      setLocalSchedules(newSchedules);
      onSchedulesChange?.(newSchedules);
      setTemplateMenuAnchor(null);
    },
    [eventId, proposalId, proposalGrandTotal, eventDate, onSchedulesChange]
  );

  const handleRecordPayment = useCallback(
    (scheduleId: string, amount: number, method: string, reference?: string) => {
      const updated = localSchedules.map((s) => {
        if (s.id === scheduleId) {
          const newPaid = s.amountPaid + amount;
          return {
            ...s,
            amountPaid: newPaid,
            status: calculateScheduleStatus(s.dueDate, s.amount, newPaid),
            linkedPaymentIds: [...s.linkedPaymentIds, `pay-${Date.now()}`],
            updatedAt: new Date().toISOString(),
            paidAt: newPaid >= s.amount ? new Date().toISOString() : undefined,
          };
        }
        return s;
      });
      setLocalSchedules(updated);
      onSchedulesChange?.(updated);
      console.log('Payment recorded:', { scheduleId, amount, method, reference });
    },
    [localSchedules, onSchedulesChange]
  );

  const handleDeleteSchedule = useCallback(
    (scheduleId: string) => {
      const updated = localSchedules.filter((s) => s.id !== scheduleId);
      setLocalSchedules(updated);
      onSchedulesChange?.(updated);
    },
    [localSchedules, onSchedulesChange]
  );

  const handleViewHistory = useCallback((schedule: EventPaymentSchedule) => {
    setSelectedSchedule(schedule);
    setShowHistoryDialog(true);
  }, []);

  const handleOpenRecordPayment = useCallback((schedule: EventPaymentSchedule) => {
    setSelectedSchedule(schedule);
    setShowRecordDialog(true);
  }, []);

  // Get payments for selected schedule
  const selectedPayments = selectedSchedule ? getPaymentsForSchedule(selectedSchedule.id) : [];

  return (
    <Paper
      sx={{
        backgroundColor: cardBg,
        border: `1px solid ${borderColor}`,
        borderRadius: 2,
        overflow: 'hidden',
      }}
    >
      {/* Header */}
      <Box
        sx={{
          p: 2,
          borderBottom: `1px solid ${borderColor}`,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
        }}
      >
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
          <ReceiptIcon sx={{ color: yellowAccent }} />
          <Typography variant="h6" sx={{ color: '#fff', fontWeight: 600 }}>
            Payment Schedule
          </Typography>
          <Chip
            label={`${localSchedules.length} milestones`}
            size="small"
            sx={{ backgroundColor: '#333', color: '#fff' }}
          />
        </Box>

        {!readonly && (
          <Stack direction="row" spacing={1}>
            <Button
              size="small"
              startIcon={<AutoIcon />}
              onClick={(e) => setTemplateMenuAnchor(e.currentTarget)}
              sx={{ color: '#888', '&:hover': { color: yellowAccent } }}
            >
              Templates
            </Button>
            <Button
              size="small"
              variant="outlined"
              startIcon={<AddIcon />}
              onClick={() => setShowAddDialog(true)}
              sx={{
                borderColor,
                color: '#888',
                '&:hover': { borderColor: yellowAccent, color: yellowAccent },
              }}
            >
              Add Milestone
            </Button>
          </Stack>
        )}

        {/* Template Menu */}
        <Menu
          anchorEl={templateMenuAnchor}
          open={Boolean(templateMenuAnchor)}
          onClose={() => setTemplateMenuAnchor(null)}
          PaperProps={{
            sx: { backgroundColor: cardBg, border: `1px solid ${borderColor}`, minWidth: 280 },
          }}
        >
          <Box sx={{ px: 2, py: 1 }}>
            <Typography variant="caption" sx={{ color: '#888' }}>
              Generate from Template
            </Typography>
          </Box>
          <Divider sx={{ borderColor }} />
          {PAYMENT_PLAN_TEMPLATES.map((template) => (
            <MenuItem
              key={template.type}
              onClick={() => handleGenerateFromTemplate(template)}
            >
              <ListItemText
                primary={
                  <Typography sx={{ color: '#fff' }}>{template.label}</Typography>
                }
                secondary={
                  <Typography variant="caption" sx={{ color: '#888' }}>
                    {template.description}
                  </Typography>
                }
              />
            </MenuItem>
          ))}
          <Divider sx={{ borderColor }} />
          <Box sx={{ px: 2, py: 1 }}>
            <Typography variant="caption" sx={{ color: '#666' }}>
              Based on: {formatCurrency(proposalGrandTotal)}
            </Typography>
          </Box>
        </Menu>
      </Box>

      {/* Unscheduled Warning */}
      {unscheduledAmount > 0 && localSchedules.length > 0 && (
        <Alert
          severity="warning"
          sx={{
            borderRadius: 0,
            backgroundColor: 'rgba(255, 152, 0, 0.1)',
            border: 'none',
            borderBottom: `1px solid ${borderColor}`,
            '& .MuiAlert-message': { color: '#fff' },
          }}
        >
          {formatCurrency(unscheduledAmount)} not yet scheduled ({((unscheduledAmount / proposalGrandTotal) * 100).toFixed(0)}% of total)
        </Alert>
      )}

      {/* Table */}
      <TableContainer>
        <Table>
          <TableHead>
            <TableRow sx={{ '& th': { backgroundColor: '#252540', color: '#888', borderColor } }}>
              <TableCell>Milestone</TableCell>
              <TableCell>Due Date</TableCell>
              <TableCell align="right">Amount</TableCell>
              <TableCell align="right">Paid</TableCell>
              <TableCell align="right">Balance</TableCell>
              <TableCell align="right">Actions</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {localSchedules.length === 0 ? (
              <TableRow>
                <TableCell colSpan={6} sx={{ textAlign: 'center', py: 6, color: '#666' }}>
                  <Box>
                    <ScheduleIcon sx={{ fontSize: 48, mb: 1, opacity: 0.3 }} />
                    <Typography>No payment schedule yet.</Typography>
                    {!readonly && (
                      <Typography variant="caption">
                        Add milestones manually or generate from a template.
                      </Typography>
                    )}
                  </Box>
                </TableCell>
              </TableRow>
            ) : (
              localSchedules.map((schedule) => (
                <ScheduleRow
                  key={schedule.id}
                  schedule={schedule}
                  onRecordPayment={() => handleOpenRecordPayment(schedule)}
                  onViewHistory={() => handleViewHistory(schedule)}
                  onDelete={() => handleDeleteSchedule(schedule.id)}
                  readonly={readonly}
                />
              ))
            )}
          </TableBody>
        </Table>
      </TableContainer>

      {/* Summary Footer */}
      {localSchedules.length > 0 && (
        <Box
          sx={{
            p: 2,
            borderTop: `1px solid ${borderColor}`,
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center',
            backgroundColor: '#252540',
          }}
        >
          <Box sx={{ display: 'flex', gap: 4 }}>
            <Box>
              <Typography variant="caption" sx={{ color: '#888' }}>
                Total Scheduled
              </Typography>
              <Typography sx={{ color: '#fff', fontFamily: 'monospace', fontWeight: 600 }}>
                {formatCurrency(totalScheduled)}
              </Typography>
            </Box>
            <Box>
              <Typography variant="caption" sx={{ color: '#888' }}>
                Total Paid
              </Typography>
              <Typography sx={{ color: '#4caf50', fontFamily: 'monospace', fontWeight: 600 }}>
                {formatCurrency(totalPaid)}
              </Typography>
            </Box>
            <Box>
              <Typography variant="caption" sx={{ color: '#888' }}>
                Outstanding
              </Typography>
              <Typography
                sx={{
                  color: totalScheduled - totalPaid > 0 ? '#ff9800' : '#4caf50',
                  fontFamily: 'monospace',
                  fontWeight: 600,
                }}
              >
                {formatCurrency(totalScheduled - totalPaid)}
              </Typography>
            </Box>
          </Box>
          <Box>
            <Typography variant="caption" sx={{ color: '#888' }}>
              Proposal Total
            </Typography>
            <Typography sx={{ color: yellowAccent, fontFamily: 'monospace', fontWeight: 600 }}>
              {formatCurrency(proposalGrandTotal)}
            </Typography>
          </Box>
        </Box>
      )}

      {/* Dialogs */}
      <AddMilestoneDialog
        open={showAddDialog}
        onClose={() => setShowAddDialog(false)}
        onAdd={handleAddMilestone}
      />

      <RecordPaymentDialog
        open={showRecordDialog}
        onClose={() => setShowRecordDialog(false)}
        schedule={selectedSchedule}
        onRecord={handleRecordPayment}
      />

      <PaymentHistoryDialog
        open={showHistoryDialog}
        onClose={() => setShowHistoryDialog(false)}
        schedule={selectedSchedule}
        payments={selectedPayments}
      />
    </Paper>
  );
};

export default PaymentSchedulePanel;
