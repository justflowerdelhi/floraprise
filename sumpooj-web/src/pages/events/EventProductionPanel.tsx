/**
 * EventProductionPanel.tsx — Production Planning Panel
 *
 * Phase 4: Production Planning & Inventory Reservation
 *
 * Features:
 * - Event summary header
 * - Designer assignment
 * - Production items table with status
 * - Inventory reservation UI
 * - Production checklist integration
 * - Role-based access
 */
import React, { useState, useMemo, useCallback } from 'react';
import {
  Box,
  Paper,
  Typography,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  TextField,
  MenuItem,
  Select,
  FormControl,
  InputLabel,
  Button,
  Chip,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Alert,
  useTheme,
  alpha,
  Tooltip,
  LinearProgress,
  Divider,
  Stack,
} from '@mui/material';
import {
  Person as PersonIcon,
  CalendarToday as DateIcon,
  LocalShipping as DeliveryIcon,
  Inventory as InventoryIcon,
  Warning as WarningIcon,
  Engineering as ProductionIcon,
  Edit as EditIcon,
} from '@mui/icons-material';
import type {
  EventProductionData,
  EventProductionItem,
  ProductionStatus,
  InventoryAvailability,
} from './ProductionTypes';
import {
  PRODUCTION_STATUS_CONFIG,
  PRODUCTION_STATUSES,
  calculateProductionProgress,
  checkReservationWarnings,
  getOverallProductionStatus,
  generateDefaultChecklist,
  proposalItemsToProductionItems,
} from './ProductionTypes';
import { getInventoryAvailabilityMap } from './ProductionMockData';
import { DESIGNERS } from './EventTypes';
import ProductionChecklist from './ProductionChecklist';

// ─── Formatting Utilities ───────────────────────────────────

const formatDate = (date: string): string =>
  new Date(date).toLocaleDateString('en-IN', { day: 'numeric', month: 'short', year: 'numeric' });

// ─── Event Summary Header ───────────────────────────────────

interface EventSummaryHeaderProps {
  eventName: string;
  eventDate: string;
  venueName?: string;
  assignedDesigner?: string;
  productionStartDate?: string;
  deliveryDate?: string;
  onAssignDesigner?: () => void;
  onEditDates?: () => void;
  readonly?: boolean;
}

const EventSummaryHeader: React.FC<EventSummaryHeaderProps> = ({
  eventName,
  eventDate,
  venueName,
  assignedDesigner,
  productionStartDate,
  deliveryDate,
  onAssignDesigner,
  onEditDates,
  readonly = false,
}) => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';

  const designer = DESIGNERS.find((d) => d.id === assignedDesigner || d.name === assignedDesigner);

  return (
    <Paper
      sx={{
        p: 3,
        bgcolor: dk ? '#1a1a2e' : '#fff',
        borderRadius: 3,
        mb: 3,
      }}
    >
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', mb: 2 }}>
        <Box>
          <Typography variant="h5" sx={{ fontWeight: 800, mb: 0.5 }}>
            {eventName}
          </Typography>
          <Typography variant="body2" sx={{ color: dk ? 'rgba(255,255,255,0.5)' : 'text.secondary' }}>
            {venueName} • {formatDate(eventDate)}
          </Typography>
        </Box>
        {!readonly && (
          <Button
            size="small"
            startIcon={<EditIcon />}
            onClick={onEditDates}
            sx={{ textTransform: 'none' }}
          >
            Edit Dates
          </Button>
        )}
      </Box>

      <Divider sx={{ mb: 2, borderColor: dk ? 'rgba(255,255,255,0.08)' : 'divider' }} />

      <Stack direction={{ xs: 'column', sm: 'row' }} spacing={3}>
        {/* Assigned Designer */}
        <Box sx={{ flex: 1 }}>
          <Typography
            variant="caption"
            sx={{
              color: dk ? 'rgba(255,255,255,0.5)' : 'text.secondary',
              fontWeight: 600,
              textTransform: 'uppercase',
              letterSpacing: 0.5,
            }}
          >
            Assigned Designer
          </Typography>
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mt: 0.5 }}>
            <PersonIcon sx={{ color: '#2196f3', fontSize: 20 }} />
            {designer ? (
              <Typography variant="body1" sx={{ fontWeight: 600 }}>
                {designer.name}
              </Typography>
            ) : (
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                <Typography variant="body2" sx={{ color: '#ff9800' }}>
                  Not Assigned
                </Typography>
                {!readonly && onAssignDesigner && (
                  <Button size="small" onClick={onAssignDesigner} sx={{ textTransform: 'none' }}>
                    Assign
                  </Button>
                )}
              </Box>
            )}
          </Box>
        </Box>

        {/* Production Start */}
        <Box sx={{ flex: 1 }}>
          <Typography
            variant="caption"
            sx={{
              color: dk ? 'rgba(255,255,255,0.5)' : 'text.secondary',
              fontWeight: 600,
              textTransform: 'uppercase',
              letterSpacing: 0.5,
            }}
          >
            Production Start
          </Typography>
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mt: 0.5 }}>
            <DateIcon sx={{ color: '#4caf50', fontSize: 20 }} />
            <Typography variant="body1" sx={{ fontWeight: 600 }}>
              {productionStartDate ? formatDate(productionStartDate) : 'Not Set'}
            </Typography>
          </Box>
        </Box>

        {/* Delivery Date */}
        <Box sx={{ flex: 1 }}>
          <Typography
            variant="caption"
            sx={{
              color: dk ? 'rgba(255,255,255,0.5)' : 'text.secondary',
              fontWeight: 600,
              textTransform: 'uppercase',
              letterSpacing: 0.5,
            }}
          >
            Delivery Date
          </Typography>
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mt: 0.5 }}>
            <DeliveryIcon sx={{ color: '#ff9800', fontSize: 20 }} />
            <Typography variant="body1" sx={{ fontWeight: 600 }}>
              {deliveryDate ? formatDate(deliveryDate) : 'Not Set'}
            </Typography>
          </Box>
        </Box>
      </Stack>
    </Paper>
  );
};

// ─── Production Progress Bar ────────────────────────────────

interface ProductionProgressBarProps {
  items: EventProductionItem[];
}

const ProductionProgressBar: React.FC<ProductionProgressBarProps> = ({ items }) => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';
  const progress = calculateProductionProgress(items);
  const overallStatus = getOverallProductionStatus(items);
  const statusConfig = PRODUCTION_STATUS_CONFIG[overallStatus];

  return (
    <Paper
      sx={{
        p: 2.5,
        bgcolor: dk ? '#1a1a2e' : '#fff',
        borderRadius: 3,
        mb: 3,
      }}
    >
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 1.5 }}>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
          <ProductionIcon sx={{ color: statusConfig.color }} />
          <Typography variant="subtitle1" sx={{ fontWeight: 700 }}>
            Production Progress
          </Typography>
        </Box>
        <Chip
          label={statusConfig.label}
          size="small"
          sx={{
            bgcolor: statusConfig.bgColor,
            color: statusConfig.color,
            fontWeight: 600,
          }}
        />
      </Box>
      <LinearProgress
        variant="determinate"
        value={progress}
        sx={{
          height: 10,
          borderRadius: 5,
          backgroundColor: dk ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.08)',
          '& .MuiLinearProgress-bar': {
            borderRadius: 5,
            backgroundColor: progress === 100 ? '#4caf50' : '#fdd835',
          },
        }}
      />
      <Typography
        variant="caption"
        sx={{ mt: 1, display: 'block', color: dk ? 'rgba(255,255,255,0.5)' : 'text.secondary' }}
      >
        {progress}% complete • {items.filter((i) => i.productionStatus === 'READY' || i.productionStatus === 'INSTALLED').length} of {items.length} items ready
      </Typography>
    </Paper>
  );
};

// ─── Production Status Dropdown ─────────────────────────────

interface StatusDropdownProps {
  value: ProductionStatus;
  onChange: (status: ProductionStatus) => void;
  disabled?: boolean;
}

const StatusDropdown: React.FC<StatusDropdownProps> = ({ value, onChange, disabled }) => {
  return (
    <FormControl size="small" sx={{ minWidth: 140 }}>
      <Select
        value={value}
        onChange={(e) => onChange(e.target.value as ProductionStatus)}
        disabled={disabled}
        sx={{
          '& .MuiSelect-select': {
            display: 'flex',
            alignItems: 'center',
            gap: 1,
            py: 0.75,
          },
        }}
      >
        {PRODUCTION_STATUSES.map((status) => {
          const sc = PRODUCTION_STATUS_CONFIG[status];
          return (
            <MenuItem key={status} value={status}>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                <Box
                  sx={{
                    width: 8,
                    height: 8,
                    borderRadius: '50%',
                    backgroundColor: sc.color,
                  }}
                />
                {sc.label}
              </Box>
            </MenuItem>
          );
        })}
      </Select>
    </FormControl>
  );
};

// ─── Inventory Cell ─────────────────────────────────────────

interface InventoryCellProps {
  item: EventProductionItem;
  availability: InventoryAvailability | null;
  onReserveChange: (quantity: number) => void;
  readonly?: boolean;
}

const InventoryCell: React.FC<InventoryCellProps> = ({
  item,
  availability,
  onReserveChange,
  readonly = false,
}) => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';

  if (!item.linkedProductId || !availability) {
    return (
      <Typography variant="body2" sx={{ color: dk ? 'rgba(255,255,255,0.3)' : 'text.disabled' }}>
        No inventory link
      </Typography>
    );
  }

  const isOverReserved = item.reservedQuantity > availability.availableQuantity;
  const remaining = availability.availableQuantity - item.reservedQuantity;

  return (
    <Box>
      <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 0.5 }}>
        <InventoryIcon sx={{ fontSize: 16, color: dk ? 'rgba(255,255,255,0.5)' : 'text.secondary' }} />
        <Typography variant="caption" sx={{ color: dk ? 'rgba(255,255,255,0.5)' : 'text.secondary' }}>
          {availability.availableQuantity} available
        </Typography>
      </Box>
      <TextField
        type="number"
        value={item.reservedQuantity}
        onChange={(e) => onReserveChange(Math.max(0, parseInt(e.target.value) || 0))}
        disabled={readonly}
        size="small"
        inputProps={{ min: 0, max: item.quantity * 2 }}
        sx={{
          width: 80,
          '& .MuiOutlinedInput-root': {
            backgroundColor: isOverReserved ? alpha('#f44336', 0.1) : 'transparent',
          },
        }}
      />
      {isOverReserved && (
        <Typography variant="caption" sx={{ color: '#f44336', display: 'block', mt: 0.5 }}>
          ⚠️ Exceeds available!
        </Typography>
      )}
      {!isOverReserved && remaining >= 0 && (
        <Typography variant="caption" sx={{ color: '#4caf50', display: 'block', mt: 0.5 }}>
          {remaining} remaining
        </Typography>
      )}
    </Box>
  );
};

// ─── Designer Assignment Dialog ─────────────────────────────

interface AssignDesignerDialogProps {
  open: boolean;
  onClose: () => void;
  currentDesignerId?: string;
  onAssign: (designerId: string) => void;
}

const AssignDesignerDialog: React.FC<AssignDesignerDialogProps> = ({
  open,
  onClose,
  currentDesignerId,
  onAssign,
}) => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';
  const [selectedDesigner, setSelectedDesigner] = useState(currentDesignerId || '');

  const handleAssign = () => {
    if (selectedDesigner) {
      onAssign(selectedDesigner);
      onClose();
    }
  };

  return (
    <Dialog open={open} onClose={onClose} maxWidth="xs" fullWidth>
      <DialogTitle sx={{ bgcolor: dk ? '#1a1a2e' : '#fff' }}>Assign Designer</DialogTitle>
      <DialogContent sx={{ bgcolor: dk ? '#1a1a2e' : '#fff', pt: 2 }}>
        <FormControl fullWidth>
          <InputLabel>Designer</InputLabel>
          <Select
            value={selectedDesigner}
            onChange={(e) => setSelectedDesigner(e.target.value)}
            label="Designer"
          >
            {DESIGNERS.map((d) => (
              <MenuItem key={d.id} value={d.id}>
                {d.name}
              </MenuItem>
            ))}
          </Select>
        </FormControl>
      </DialogContent>
      <DialogActions sx={{ bgcolor: dk ? '#1a1a2e' : '#fff', px: 3, pb: 2 }}>
        <Button onClick={onClose}>Cancel</Button>
        <Button
          variant="contained"
          onClick={handleAssign}
          disabled={!selectedDesigner}
          sx={{
            bgcolor: '#fdd835',
            color: '#000',
            '&:hover': { bgcolor: '#ffeb3b' },
          }}
        >
          Assign
        </Button>
      </DialogActions>
    </Dialog>
  );
};

// ─── Edit Dates Dialog ──────────────────────────────────────

interface EditDatesDialogProps {
  open: boolean;
  onClose: () => void;
  productionStartDate?: string;
  deliveryDate?: string;
  onSave: (startDate: string, deliveryDate: string) => void;
}

const EditDatesDialog: React.FC<EditDatesDialogProps> = ({
  open,
  onClose,
  productionStartDate,
  deliveryDate,
  onSave,
}) => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';
  const [startDate, setStartDate] = useState(productionStartDate || '');
  const [delivery, setDelivery] = useState(deliveryDate || '');

  const handleSave = () => {
    onSave(startDate, delivery);
    onClose();
  };

  return (
    <Dialog open={open} onClose={onClose} maxWidth="xs" fullWidth>
      <DialogTitle sx={{ bgcolor: dk ? '#1a1a2e' : '#fff' }}>Edit Production Dates</DialogTitle>
      <DialogContent sx={{ bgcolor: dk ? '#1a1a2e' : '#fff', pt: 2 }}>
        <Stack spacing={2.5}>
          <TextField
            label="Production Start Date"
            type="date"
            value={startDate}
            onChange={(e) => setStartDate(e.target.value)}
            InputLabelProps={{ shrink: true }}
            fullWidth
          />
          <TextField
            label="Delivery Date"
            type="date"
            value={delivery}
            onChange={(e) => setDelivery(e.target.value)}
            InputLabelProps={{ shrink: true }}
            fullWidth
          />
        </Stack>
      </DialogContent>
      <DialogActions sx={{ bgcolor: dk ? '#1a1a2e' : '#fff', px: 3, pb: 2 }}>
        <Button onClick={onClose}>Cancel</Button>
        <Button
          variant="contained"
          onClick={handleSave}
          sx={{
            bgcolor: '#fdd835',
            color: '#000',
            '&:hover': { bgcolor: '#ffeb3b' },
          }}
        >
          Save
        </Button>
      </DialogActions>
    </Dialog>
  );
};

// ─── Props ──────────────────────────────────────────────────

interface EventProductionPanelProps {
  eventId: string;
  eventName: string;
  eventDate: string;
  venueName?: string;
  productionData: EventProductionData | null;
  proposalItems?: Array<{
    id: string;
    name: string;
    quantity: number;
    linkedProductId?: string;
    linkedProductSku?: string;
  }>;
  onProductionChange: (data: EventProductionData) => void;
  readonly?: boolean;
  canModifyReservation?: boolean;
  canAssignDesigner?: boolean;
  currentUser?: string;
}

// ─── Main Component ─────────────────────────────────────────

const EventProductionPanel: React.FC<EventProductionPanelProps> = ({
  eventId,
  eventName,
  eventDate,
  venueName,
  productionData,
  proposalItems = [],
  onProductionChange,
  readonly = false,
  canModifyReservation = true,
  canAssignDesigner = true,
  currentUser = 'Current User',
}) => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';

  // State
  const [assignDialogOpen, setAssignDialogOpen] = useState(false);
  const [datesDialogOpen, setDatesDialogOpen] = useState(false);

  // Initialize production data if needed
  const data: EventProductionData = useMemo(() => {
    if (productionData) return productionData;

    // Create new production data from proposal items
    const now = new Date().toISOString();
    return {
      eventId,
      proposalId: '',
      items: proposalItemsToProductionItems(eventId, '', proposalItems),
      checklist: generateDefaultChecklist(),
      createdAt: now,
      updatedAt: now,
    };
  }, [productionData, eventId, proposalItems]);

  // Inventory availability
  const inventoryMap = useMemo(() => getInventoryAvailabilityMap(), []);

  // Reservation warnings
  const warnings = useMemo(
    () => checkReservationWarnings(data.items, inventoryMap),
    [data.items, inventoryMap]
  );

  // Handlers
  const handleStatusChange = useCallback(
    (itemId: string, status: ProductionStatus) => {
      const updatedItems = data.items.map((item) =>
        item.id === itemId ? { ...item, productionStatus: status } : item
      );
      onProductionChange({
        ...data,
        items: updatedItems,
        updatedAt: new Date().toISOString(),
      });
    },
    [data, onProductionChange]
  );

  const handleReserveChange = useCallback(
    (itemId: string, quantity: number) => {
      const updatedItems = data.items.map((item) =>
        item.id === itemId ? { ...item, reservedQuantity: quantity } : item
      );
      onProductionChange({
        ...data,
        items: updatedItems,
        updatedAt: new Date().toISOString(),
      });
    },
    [data, onProductionChange]
  );

  const handleChecklistToggle = useCallback(
    (itemId: string) => {
      const updatedChecklist = data.checklist.map((item) =>
        item.id === itemId
          ? {
              ...item,
              completed: !item.completed,
              completedAt: !item.completed ? new Date().toISOString() : undefined,
              completedBy: !item.completed ? currentUser : undefined,
            }
          : item
      );
      onProductionChange({
        ...data,
        checklist: updatedChecklist,
        updatedAt: new Date().toISOString(),
      });
    },
    [data, onProductionChange, currentUser]
  );

  const handleAssignDesigner = useCallback(
    (designerId: string) => {
      onProductionChange({
        ...data,
        assignedDesignerId: designerId,
        updatedAt: new Date().toISOString(),
      });
    },
    [data, onProductionChange]
  );

  const handleSaveDates = useCallback(
    (startDate: string, deliveryDate: string) => {
      onProductionChange({
        ...data,
        productionStartDate: startDate,
        deliveryDate: deliveryDate,
        updatedAt: new Date().toISOString(),
      });
    },
    [data, onProductionChange]
  );

  return (
    <Box>
      {/* Event Summary Header */}
      <EventSummaryHeader
        eventName={eventName}
        eventDate={eventDate}
        venueName={venueName}
        assignedDesigner={data.assignedDesignerId}
        productionStartDate={data.productionStartDate}
        deliveryDate={data.deliveryDate}
        onAssignDesigner={canAssignDesigner ? () => setAssignDialogOpen(true) : undefined}
        onEditDates={canAssignDesigner ? () => setDatesDialogOpen(true) : undefined}
        readonly={readonly || !canAssignDesigner}
      />

      {/* Progress Bar */}
      <ProductionProgressBar items={data.items} />

      {/* Reservation Warnings */}
      {warnings.length > 0 && (
        <Alert
          severity="warning"
          icon={<WarningIcon />}
          sx={{ mb: 3, bgcolor: alpha('#ff9800', 0.1), borderRadius: 2 }}
        >
          <Typography variant="subtitle2" sx={{ fontWeight: 600, mb: 0.5 }}>
            Inventory Warnings
          </Typography>
          {warnings.map((w) => (
            <Typography key={w.itemId} variant="body2">
              • {w.itemName}: Reserved {w.requested}, only {w.available} available (shortfall: {w.shortfall})
            </Typography>
          ))}
        </Alert>
      )}

      {/* Production Items Table */}
      <Paper
        sx={{
          bgcolor: dk ? '#1a1a2e' : '#fff',
          borderRadius: 3,
          mb: 3,
          overflow: 'hidden',
        }}
      >
        <Box sx={{ p: 2.5, borderBottom: 1, borderColor: dk ? 'rgba(255,255,255,0.08)' : 'divider' }}>
          <Typography variant="h6" sx={{ fontWeight: 700 }}>
            Production Items
          </Typography>
          <Typography variant="body2" sx={{ color: dk ? 'rgba(255,255,255,0.5)' : 'text.secondary' }}>
            {data.items.length} items from proposal
          </Typography>
        </Box>

        <TableContainer>
          <Table size="small">
            <TableHead>
              <TableRow
                sx={{
                  '& th': {
                    bgcolor: dk ? 'rgba(255,255,255,0.03)' : 'rgba(0,0,0,0.02)',
                    fontWeight: 700,
                    borderColor: dk ? 'rgba(255,255,255,0.08)' : 'divider',
                  },
                }}
              >
                <TableCell>Item Name</TableCell>
                <TableCell align="center">Qty</TableCell>
                <TableCell>Linked Product</TableCell>
                <TableCell>Inventory / Reserve</TableCell>
                <TableCell>Status</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {data.items.map((item) => {
                const availability = item.linkedProductId
                  ? inventoryMap.get(item.linkedProductId) || null
                  : null;

                return (
                  <TableRow
                    key={item.id}
                    sx={{
                      '&:hover': {
                        bgcolor: dk ? 'rgba(255,255,255,0.02)' : 'rgba(0,0,0,0.02)',
                      },
                      '& td': {
                        borderColor: dk ? 'rgba(255,255,255,0.08)' : 'divider',
                      },
                    }}
                  >
                    <TableCell>
                      <Box>
                        <Typography variant="body2" sx={{ fontWeight: 600 }}>
                          {item.name}
                        </Typography>
                        {item.notes && (
                          <Typography
                            variant="caption"
                            sx={{ color: dk ? 'rgba(255,255,255,0.5)' : 'text.secondary' }}
                          >
                            {item.notes}
                          </Typography>
                        )}
                      </Box>
                    </TableCell>
                    <TableCell align="center">
                      <Chip
                        label={item.quantity}
                        size="small"
                        sx={{
                          fontWeight: 600,
                          bgcolor: dk ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.08)',
                        }}
                      />
                    </TableCell>
                    <TableCell>
                      {item.linkedProductSku ? (
                        <Tooltip title={availability?.productName || 'Unknown product'}>
                          <Chip
                            label={item.linkedProductSku}
                            size="small"
                            variant="outlined"
                            sx={{ fontFamily: 'monospace' }}
                          />
                        </Tooltip>
                      ) : (
                        <Typography variant="caption" sx={{ color: dk ? 'rgba(255,255,255,0.3)' : 'text.disabled' }}>
                          Service item
                        </Typography>
                      )}
                    </TableCell>
                    <TableCell>
                      <InventoryCell
                        item={item}
                        availability={availability}
                        onReserveChange={(qty) => handleReserveChange(item.id, qty)}
                        readonly={readonly || !canModifyReservation}
                      />
                    </TableCell>
                    <TableCell>
                      <StatusDropdown
                        value={item.productionStatus}
                        onChange={(status) => handleStatusChange(item.id, status)}
                        disabled={readonly}
                      />
                    </TableCell>
                  </TableRow>
                );
              })}
            </TableBody>
          </Table>
        </TableContainer>
      </Paper>

      {/* Production Checklist */}
      <ProductionChecklist
        checklist={data.checklist}
        onToggle={handleChecklistToggle}
        readonly={readonly}
        currentUser={currentUser}
      />

      {/* Dialogs */}
      <AssignDesignerDialog
        open={assignDialogOpen}
        onClose={() => setAssignDialogOpen(false)}
        currentDesignerId={data.assignedDesignerId}
        onAssign={handleAssignDesigner}
      />
      <EditDatesDialog
        open={datesDialogOpen}
        onClose={() => setDatesDialogOpen(false)}
        productionStartDate={data.productionStartDate}
        deliveryDate={data.deliveryDate}
        onSave={handleSaveDates}
      />
    </Box>
  );
};

export default EventProductionPanel;
