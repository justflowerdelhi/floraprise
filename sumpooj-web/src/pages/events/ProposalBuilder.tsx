/**
 * ProposalBuilder.tsx — Main Proposal Builder UI
 * 
 * Features:
 * - Add/remove line items (Product, Service, Package)
 * - Product picker with auto-fill cost
 * - Live margin calculations per item
 * - Integrated Profit Summary Panel
 * - Versioning support
 */
import React, { useState, useMemo, useCallback, useEffect } from 'react';
import {
  Box,
  Paper,
  Typography,
  Button,
  IconButton,
  TextField,
  MenuItem,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Chip,
  Autocomplete,
  Stack,
  Tooltip,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Alert,
  Breadcrumbs,
  Link,
  CircularProgress,
  useTheme,
  alpha,
} from '@mui/material';
import {
  Add as AddIcon,
  Delete as DeleteIcon,
  Save as SaveIcon,
  Send as SendIcon,
  History as HistoryIcon,
  ContentCopy as DuplicateIcon,
  ArrowBack as BackIcon,
  Inventory as ProductIcon,
  Build as ServiceIcon,
  CardGiftcard as PackageIcon,
  Warning as WarningIcon,
} from '@mui/icons-material';
import { useNavigate, useParams } from 'react-router-dom';
import Grid from '@mui/material/Grid';
import type {
  ProposalItem,
  ProposalItemType,
  ProposalVersion,
} from './ProposalTypes';
import {
  createNewItem,
  calculateItemTotals,
  calculateProposalTotals,
  getMarginColor,
  SERVICE_PRESETS,
  PACKAGE_PRESETS,
  PROPOSAL_STATUS_CONFIG,
} from './ProposalTypes';
import { PRODUCT_OPTIONS, MOCK_PROPOSALS, MOCK_VERSION_HISTORY } from './ProposalMockData';
import { MOCK_EVENTS } from './EventMockData';
import ProfitSummaryPanel from './ProfitSummaryPanel';
import { formatCurrency } from '../../core/i18n';
import {
  createProposal,
  updateProposal,
  sendProposal as sendProposalApi,
  getProposalById,
} from '../../api/proposal.api';
import { useToast } from '../../hooks/useToast';
import { getEventById, searchEvents } from '../../api/event.api';

type ProposalColors = {
  cardBg: string;
  borderColor: string;
  accent: string;
  pageBg: string;
  inputBg: string;
  textPrimary: string;
  textSecondary: string;
  tableHeadBg: string;
};

type EnquiryEventOption = {
  id: string;
  eventName: string;
  clientName: string;
  eventType?: string;
  eventDate?: string;
};

const isGuid = (value?: string | null) =>
  !!value &&
  /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(value);

// ─── Format Currency ────────────────────────────────────────

// ─── Version History Dialog ─────────────────────────────────

interface VersionHistoryDialogProps {
  open: boolean;
  onClose: () => void;
  versions: ProposalVersion[];
  onRestore: (versionId: string) => void;
  colors: ProposalColors;
}

const VersionHistoryDialog: React.FC<VersionHistoryDialogProps> = ({
  open,
  onClose,
  versions,
  onRestore,
  colors,
}) => (
  <Dialog open={open} onClose={onClose} maxWidth="sm" fullWidth>
    <DialogTitle sx={{ backgroundColor: colors.cardBg, color: colors.textPrimary, borderBottom: `1px solid ${colors.borderColor}` }}>
      <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
        <HistoryIcon />
        Version History
      </Box>
    </DialogTitle>
    <DialogContent sx={{ backgroundColor: colors.cardBg, p: 0 }}>
      <Table size="small">
        <TableHead>
          <TableRow sx={{ '& th': { color: colors.textSecondary, borderColor: colors.borderColor } }}>
            <TableCell>Version</TableCell>
            <TableCell>Status</TableCell>
            <TableCell align="right">Total</TableCell>
            <TableCell align="right">Margin</TableCell>
            <TableCell align="right">Actions</TableCell>
          </TableRow>
        </TableHead>
        <TableBody>
          {versions.map((version) => (
            <TableRow key={version.id} sx={{ '& td': { color: colors.textPrimary, borderColor: colors.borderColor } }}>
              <TableCell>
                <Typography variant="body2" sx={{ fontWeight: 600 }}>
                  {version.versionName}
                </Typography>
                <Typography variant="caption" sx={{ color: colors.textSecondary }}>
                  {new Date(version.createdAt).toLocaleDateString()} by {version.changedBy}
                </Typography>
              </TableCell>
              <TableCell>
                <Chip
                  label={version.status}
                  size="small"
                  sx={{
                    backgroundColor: `${PROPOSAL_STATUS_CONFIG[version.status].color}20`,
                    color: PROPOSAL_STATUS_CONFIG[version.status].color,
                    fontSize: '0.7rem',
                  }}
                />
              </TableCell>
              <TableCell align="right" sx={{ fontFamily: 'monospace' }}>
                {formatCurrency(version.grandTotal)}
              </TableCell>
              <TableCell align="right">
                <Typography sx={{ color: getMarginColor(version.marginPercentage) }}>
                  {version.marginPercentage.toFixed(1)}%
                </Typography>
              </TableCell>
              <TableCell align="right">
                <Tooltip title="Restore this version">
                  <IconButton size="small" onClick={() => onRestore(version.id)} sx={{ color: colors.accent }}>
                    <HistoryIcon fontSize="small" />
                  </IconButton>
                </Tooltip>
              </TableCell>
            </TableRow>
          ))}
        </TableBody>
      </Table>
    </DialogContent>
    <DialogActions sx={{ backgroundColor: colors.cardBg, borderTop: `1px solid ${colors.borderColor}`, p: 2 }}>
      <Button onClick={onClose} sx={{ color: colors.textSecondary }}>
        Close
      </Button>
    </DialogActions>
  </Dialog>
);

// ─── Line Item Row ──────────────────────────────────────────

interface LineItemRowProps {
  item: ProposalItem;
  index: number;
  onUpdate: (index: number, updates: Partial<ProposalItem>) => void;
  onDelete: (index: number) => void;
  colors: ProposalColors;
}

const LineItemRow: React.FC<LineItemRowProps> = ({ item, index, onUpdate, onDelete, colors }) => {
  const marginColor = getMarginColor(item.marginPercentage);
  const isLowMargin = item.marginPercentage < 20;

  const handleProductSelect = (product: (typeof PRODUCT_OPTIONS)[0] | null) => {
    if (product) {
      onUpdate(index, {
        linkedProductId: product.id,
        linkedProductSku: product.sku,
        name: product.name,
        unitPrice: product.sellingPrice,
        unitCost: product.costPrice,
      });
    }
  };

  const handleServiceSelect = (service: (typeof SERVICE_PRESETS)[0] | string | null) => {
    if (service && typeof service !== 'string') {
      onUpdate(index, {
        name: service.name,
        unitPrice: service.defaultPrice,
        unitCost: service.defaultCost,
      });
    }
  };

  const handlePackageSelect = (pkg: (typeof PACKAGE_PRESETS)[0] | string | null) => {
    if (pkg && typeof pkg !== 'string') {
      onUpdate(index, {
        name: pkg.name,
        description: pkg.description,
        unitPrice: pkg.defaultPrice,
        unitCost: pkg.defaultCost,
      });
    }
  };

  return (
    <TableRow
      sx={{
        '& td': { borderColor: colors.borderColor, py: 1.5 },
        backgroundColor: isLowMargin ? 'rgba(239, 83, 80, 0.05)' : 'transparent',
      }}
    >
      {/* Type */}
      <TableCell sx={{ width: 120 }}>
        <TextField
          select
          size="small"
          value={item.type}
          onChange={(e) => {
            onUpdate(index, {
              type: e.target.value as ProposalItemType,
              linkedProductId: undefined,
              linkedProductSku: undefined,
              name: '',
              description: undefined,
              unitPrice: 0,
              unitCost: 0,
            });
          }}
          sx={{
            '& .MuiOutlinedInput-root': {
              backgroundColor: colors.inputBg,
              '& fieldset': { borderColor: colors.borderColor },
            },
            '& .MuiSelect-select': { color: colors.textPrimary, display: 'flex', alignItems: 'center', gap: 1 },
          }}
          fullWidth
        >
          <MenuItem value="PRODUCT">
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
              <ProductIcon fontSize="small" /> Product
            </Box>
          </MenuItem>
          <MenuItem value="SERVICE">
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
              <ServiceIcon fontSize="small" /> Service
            </Box>
          </MenuItem>
          <MenuItem value="PACKAGE">
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
              <PackageIcon fontSize="small" /> Package
            </Box>
          </MenuItem>
        </TextField>
      </TableCell>

      {/* Item Selection */}
      <TableCell sx={{ minWidth: 250 }}>
        {item.type === 'PRODUCT' && (
          <Autocomplete
            size="small"
            options={PRODUCT_OPTIONS}
            getOptionLabel={(option) => `${option.name} (${option.sku})`}
            groupBy={(option) => option.category}
            value={PRODUCT_OPTIONS.find((p) => p.id === item.linkedProductId) || null}
            onChange={(_, value) => handleProductSelect(value)}
            renderInput={(params) => (
              <TextField
                {...params}
                placeholder="Select product..."
                sx={{
                  '& .MuiOutlinedInput-root': {
                    backgroundColor: colors.inputBg,
                    '& fieldset': { borderColor: colors.borderColor },
                  },
                  '& .MuiInputBase-input': { color: colors.textPrimary },
                }}
              />
            )}
            renderOption={(props, option) => {
              const { key, ...rest } = props as { key: string } & React.HTMLAttributes<HTMLLIElement>;
              return (
                <Box component="li" {...rest} key={key} sx={{ display: 'flex', justifyContent: 'space-between', gap: 2 }}>
                  <Typography variant="body2">{option.name}</Typography>
                  <Typography variant="caption" sx={{ color: colors.textSecondary }}>
                    {formatCurrency(option.sellingPrice)}
                  </Typography>
                </Box>
              );
            }}
          />
        )}
        {item.type === 'SERVICE' && (
          <Autocomplete
            size="small"
            options={SERVICE_PRESETS}
            getOptionLabel={(option) => typeof option === 'string' ? option : option.name}
            value={SERVICE_PRESETS.find((s) => s.name === item.name) || null}
            onChange={(_, value) => handleServiceSelect(value)}
            freeSolo
            renderInput={(params) => (
              <TextField
                {...params}
                placeholder="Select or type service..."
                onChange={(e) => onUpdate(index, { name: e.target.value })}
                sx={{
                  '& .MuiOutlinedInput-root': {
                    backgroundColor: colors.inputBg,
                    '& fieldset': { borderColor: colors.borderColor },
                  },
                  '& .MuiInputBase-input': { color: colors.textPrimary },
                }}
              />
            )}
          />
        )}
        {item.type === 'PACKAGE' && (
          <Autocomplete
            size="small"
            options={PACKAGE_PRESETS}
            getOptionLabel={(option) => typeof option === 'string' ? option : option.name}
            value={PACKAGE_PRESETS.find((p) => p.name === item.name) || null}
            onChange={(_, value) => handlePackageSelect(value)}
            freeSolo
            renderInput={(params) => (
              <TextField
                {...params}
                placeholder="Select or type package..."
                onChange={(e) => onUpdate(index, { name: e.target.value })}
                sx={{
                  '& .MuiOutlinedInput-root': {
                    backgroundColor: colors.inputBg,
                    '& fieldset': { borderColor: colors.borderColor },
                  },
                  '& .MuiInputBase-input': { color: colors.textPrimary },
                }}
              />
            )}
          />
        )}
        {item.linkedProductSku && (
          <Typography variant="caption" sx={{ color: colors.textSecondary, mt: 0.5, display: 'block' }}>
            SKU: {item.linkedProductSku}
          </Typography>
        )}
      </TableCell>

      {/* Quantity */}
      <TableCell sx={{ width: 80 }}>
        <TextField
          type="number"
          size="small"
          value={item.quantity}
          onChange={(e) => onUpdate(index, { quantity: Math.max(1, Number(e.target.value)) })}
          inputProps={{ min: 1, step: 1 }}
          sx={{
            '& .MuiOutlinedInput-root': {
              backgroundColor: colors.inputBg,
              '& fieldset': { borderColor: colors.borderColor },
            },
            '& .MuiInputBase-input': { color: colors.textPrimary, textAlign: 'center' },
          }}
          fullWidth
        />
      </TableCell>

      {/* Unit Price */}
      <TableCell sx={{ width: 120 }}>
        <TextField
          type="number"
          size="small"
          value={item.unitPrice}
          onChange={(e) => onUpdate(index, { unitPrice: Math.max(0, Number(e.target.value)) })}
          inputProps={{ min: 0, step: 10 }}
          sx={{
            '& .MuiOutlinedInput-root': {
              backgroundColor: colors.inputBg,
              '& fieldset': { borderColor: colors.borderColor },
            },
            '& .MuiInputBase-input': { color: colors.textPrimary, textAlign: 'right' },
          }}
          fullWidth
        />
      </TableCell>

      {/* Unit Cost */}
      <TableCell sx={{ width: 120 }}>
        <TextField
          type="number"
          size="small"
          value={item.unitCost}
          onChange={(e) => onUpdate(index, { unitCost: Math.max(0, Number(e.target.value)) })}
          inputProps={{ min: 0, step: 10 }}
          sx={{
            '& .MuiOutlinedInput-root': {
              backgroundColor: colors.inputBg,
              '& fieldset': { borderColor: colors.borderColor },
            },
            '& .MuiInputBase-input': { color: colors.textSecondary, textAlign: 'right' },
          }}
          fullWidth
        />
      </TableCell>

      {/* Total */}
      <TableCell align="right" sx={{ width: 100 }}>
        <Typography sx={{ color: colors.textPrimary, fontFamily: 'monospace', fontWeight: 600 }}>
          {formatCurrency(item.totalPrice)}
        </Typography>
      </TableCell>

      {/* Margin */}
      <TableCell align="right" sx={{ width: 80 }}>
        <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'flex-end', gap: 0.5 }}>
          {isLowMargin && <WarningIcon fontSize="small" sx={{ color: '#ef5350' }} />}
          <Typography
            sx={{
              color: marginColor,
              fontFamily: 'monospace',
              fontWeight: 600,
            }}
          >
            {item.marginPercentage.toFixed(1)}%
          </Typography>
        </Box>
      </TableCell>

      {/* Actions */}
      <TableCell align="center" sx={{ width: 60 }}>
        <Tooltip title="Remove item">
          <IconButton size="small" onClick={() => onDelete(index)} sx={{ color: '#ef5350' }}>
            <DeleteIcon fontSize="small" />
          </IconButton>
        </Tooltip>
      </TableCell>
    </TableRow>
  );
};

// ─── Main ProposalBuilder Component ─────────────────────────

const ProposalBuilder: React.FC = () => {
  const theme = useTheme();
  const toast = useToast();
  const dk = theme.palette.mode === 'dark';
  const colors: ProposalColors = {
    cardBg: theme.palette.background.paper,
    borderColor: theme.palette.divider,
    accent: '#fdd835',
    pageBg: theme.palette.background.default,
    inputBg: dk ? alpha(theme.palette.common.white, 0.04) : alpha(theme.palette.common.black, 0.02),
    textPrimary: theme.palette.text.primary,
    textSecondary: theme.palette.text.secondary,
    tableHeadBg: dk ? alpha(theme.palette.primary.main, 0.14) : alpha(theme.palette.primary.main, 0.06),
  };
  const navigate = useNavigate();
  const { eventId, proposalId } = useParams<{ eventId?: string; proposalId?: string }>();

  // Load existing proposal or create new
  const existingProposal = proposalId ? MOCK_PROPOSALS.find((p) => p.id === proposalId) : null;
  const linkedEvent = eventId
    ? MOCK_EVENTS.find((e) => e.id === eventId)
    : existingProposal
      ? MOCK_EVENTS.find((e) => e.id === existingProposal.eventId)
      : null;

  // State
  const [items, setItems] = useState<ProposalItem[]>(existingProposal?.items || []);
  const [discountType, setDiscountType] = useState<'FIXED' | 'PERCENTAGE'>(
    existingProposal?.discountType || 'PERCENTAGE'
  );
  const [discountValue, setDiscountValue] = useState(existingProposal?.discountValue || 0);
  const [taxRate, setTaxRate] = useState(existingProposal?.taxRate || 18);
  const [notes, setNotes] = useState(existingProposal?.notes || '');
  const [versionName, setVersionName] = useState(existingProposal?.versionName || 'Draft v1');
  const [showVersionHistory, setShowVersionHistory] = useState(false);
  const [hasChanges, setHasChanges] = useState(false);
  const [eventMeta, setEventMeta] = useState<{ id: string; clientName: string; eventType?: string } | null>(null);
  const [enquiryEvents, setEnquiryEvents] = useState<EnquiryEventOption[]>([]);
  const [selectedEnquiryEvent, setSelectedEnquiryEvent] = useState<EnquiryEventOption | null>(null);
  const [loadingEnquiryEvents, setLoadingEnquiryEvents] = useState(false);

  useEffect(() => {
    let cancelled = false;

    const loadEventMeta = async () => {
      if (!eventId || linkedEvent) {
        setEventMeta(null);
        return;
      }

      try {
        const event = await getEventById(eventId);
        if (cancelled) return;
        setEventMeta({
          id: String(event?.id ?? eventId),
          clientName: String(event?.clientName ?? ''),
          eventType: typeof event?.eventTypeName === 'string' ? event.eventTypeName : undefined,
        });
      } catch {
        if (!cancelled) setEventMeta(null);
      }
    };

    loadEventMeta();
    return () => {
      cancelled = true;
    };
  }, [eventId, linkedEvent]);

  useEffect(() => {
    let cancelled = false;

    const loadEnquiryEvents = async () => {
      if (eventId || proposalId) {
        setEnquiryEvents([]);
        return;
      }

      setLoadingEnquiryEvents(true);
      try {
        const response = await searchEvents({
          Status: 'Inquiry',
          Page: 1,
          PageSize: 200,
        });

        if (cancelled) return;
        const rawItems = (response?.items ?? response ?? []) as any[];
        const mapped: EnquiryEventOption[] = rawItems
          .map((event: any) => ({
            id: String(event?.id ?? ''),
            eventName: String(event?.eventName ?? 'Untitled Event'),
            clientName: String(event?.clientName ?? 'Unknown Client'),
            eventType: typeof event?.eventType === 'string' ? event.eventType : undefined,
            eventDate: typeof event?.eventDate === 'string' ? event.eventDate : undefined,
          }))
          .filter((event) => isGuid(event.id));

        setEnquiryEvents(mapped);
      } catch {
        if (!cancelled) setEnquiryEvents([]);
      } finally {
        if (!cancelled) setLoadingEnquiryEvents(false);
      }
    };

    loadEnquiryEvents();
    return () => {
      cancelled = true;
    };
  }, [eventId, proposalId]);

  // Version history
  const versionHistory = proposalId ? MOCK_VERSION_HISTORY[proposalId] || [] : [];

  // Calculate totals
  const totals = useMemo(() => {
    return calculateProposalTotals(items, discountType, discountValue, taxRate);
  }, [items, discountType, discountValue, taxRate]);

  // Update item with recalculated margins
  const updateItem = useCallback((index: number, updates: Partial<ProposalItem>) => {
    setItems((prev) => {
      const newItems = [...prev];
      const item = { ...newItems[index], ...updates };
      const calculated = calculateItemTotals(item.quantity, item.unitPrice, item.unitCost);
      newItems[index] = { ...item, ...calculated };
      return newItems;
    });
    setHasChanges(true);
  }, []);

  // Add new item
  const addItem = useCallback((type: ProposalItemType = 'PRODUCT') => {
    setItems((prev) => [...prev, createNewItem(type)]);
    setHasChanges(true);
  }, []);

  // Delete item
  const deleteItem = useCallback((index: number) => {
    setItems((prev) => prev.filter((_, i) => i !== index));
    setHasChanges(true);
  }, []);

  // Handle discount change
  const handleDiscountTypeChange = (type: 'FIXED' | 'PERCENTAGE') => {
    setDiscountType(type);
    setHasChanges(true);
  };

  const handleDiscountValueChange = (value: number) => {
    setDiscountValue(value);
    setHasChanges(true);
  };

  const handleTaxRateChange = (rate: number) => {
    setTaxRate(rate);
    setHasChanges(true);
  };

  // Save
  const handleSave = async () => {
    const resolvedEventId = selectedEnquiryEvent?.id ?? linkedEvent?.id ?? eventMeta?.id ?? eventId ?? '';
    if (!isGuid(resolvedEventId)) {
      toast.error('Please select an Enquiry event before saving.');
      return;
    }
    if (items.length === 0) {
      toast.error('Add at least one line item before saving.');
      return;
    }
    if (items.some((item) => !item.name.trim())) {
      toast.error('Each line item must have a name.');
      return;
    }

    const payload = {
      eventId: resolvedEventId,
      title: versionName,
      clientName: selectedEnquiryEvent?.clientName ?? linkedEvent?.clientName ?? eventMeta?.clientName ?? 'Event Client',
      clientEmail: '',
      items: items.map((item, idx) => ({
        type: item.type,
        name: item.name,
        category: '',
        description: item.description,
        linkedProductId: isGuid(item.linkedProductId) ? item.linkedProductId : undefined,
        quantity: item.quantity,
        unitPrice: item.unitPrice,
        unitCost: item.unitCost,
        sortOrder: idx,
      })),
      discountType,
      discountValue,
      taxRate,
      notes,
      versionName,
    };
    try {
      if (proposalId) {
        await updateProposal(proposalId, payload);
        toast.success('Proposal updated.');
      } else {
        const created = await createProposal(payload);
        toast.success('Proposal created.');
        navigate(`/proposals/${created.id}/edit`, { replace: true });
      }
      setHasChanges(false);
    } catch (err) {
      console.error('Failed to save proposal:', err);
      toast.error('Failed to save proposal. Please check event and item data.');
    }
  };

  // Send to client
  const handleSend = async () => {
    if (!proposalId) {
      await handleSave();
      return;
    }
    try {
      if (proposalId) {
        await sendProposalApi(proposalId);
        toast.success('Proposal sent to client.');
      }
    } catch (err) {
      console.error('Failed to send proposal:', err);
      toast.error('Failed to send proposal.');
    }
  };

  // Restore version
  const handleRestoreVersion = async (versionId: string) => {
    setShowVersionHistory(false);
    if (!proposalId) return;
    try {
      const restored = await getProposalById(proposalId);
      if (restored?.items) {
        setItems(restored.items);
        setDiscountType(restored.discountType ?? 'PERCENTAGE');
        setDiscountValue(restored.discountValue ?? 0);
        setTaxRate(restored.taxRate ?? 18);
        setNotes(restored.notes ?? '');
        setVersionName(restored.versionName ?? `Restored from ${versionId}`);
        setHasChanges(true);
      }
    } catch (err) {
      console.error('Failed to restore version:', err);
    }
  };

  // Low margin warning check
  const hasLowMarginItems = items.some((item) => item.marginPercentage < 20);
  const hasEventContext = isGuid(selectedEnquiryEvent?.id ?? linkedEvent?.id ?? eventMeta?.id ?? eventId ?? '');

  return (
    <Box sx={{ p: 3, backgroundColor: colors.pageBg, minHeight: '100vh' }}>
      {/* Header */}
      <Box sx={{ mb: 3 }}>
        <Breadcrumbs sx={{ mb: 1, '& .MuiBreadcrumbs-separator': { color: colors.textSecondary } }}>
          <Link
            component="button"
            onClick={() => navigate('/events')}
            sx={{ color: colors.textSecondary, textDecoration: 'none', '&:hover': { color: colors.accent } }}
          >
            Events
          </Link>
          {linkedEvent && (
            <Link
              component="button"
              onClick={() => navigate(`/events/${linkedEvent.id}`)}
              sx={{ color: colors.textSecondary, textDecoration: 'none', '&:hover': { color: colors.accent } }}
            >
              {linkedEvent.clientName}
            </Link>
          )}
          <Typography sx={{ color: colors.textPrimary }}>
            {proposalId ? 'Edit Proposal' : 'New Proposal'}
          </Typography>
        </Breadcrumbs>

        <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
            <IconButton onClick={() => navigate(-1)} sx={{ color: colors.textSecondary }}>
              <BackIcon />
            </IconButton>
            <Box>
              <Typography variant="h5" sx={{ color: colors.textPrimary, fontWeight: 600 }}>
                {proposalId ? 'Edit Proposal' : 'Create Proposal'}
              </Typography>
              {linkedEvent && (
                <Typography variant="body2" sx={{ color: colors.textSecondary }}>
                  {linkedEvent.clientName} • {linkedEvent.eventType}
                </Typography>
              )}
              {!linkedEvent && eventMeta && (
                <Typography variant="body2" sx={{ color: colors.textSecondary }}>
                  {eventMeta.clientName}{eventMeta.eventType ? ` • ${eventMeta.eventType}` : ''}
                </Typography>
              )}
              {!linkedEvent && !eventMeta && selectedEnquiryEvent && (
                <Typography variant="body2" sx={{ color: colors.textSecondary }}>
                  {selectedEnquiryEvent.clientName}
                  {selectedEnquiryEvent.eventType ? ` • ${selectedEnquiryEvent.eventType}` : ''}
                </Typography>
              )}
            </Box>
            {existingProposal && (
              <Chip
                label={existingProposal.status}
                sx={{
                  backgroundColor: `${PROPOSAL_STATUS_CONFIG[existingProposal.status].color}20`,
                  color: PROPOSAL_STATUS_CONFIG[existingProposal.status].color,
                }}
              />
            )}
          </Box>

          <Stack direction="row" spacing={1}>
            {versionHistory.length > 0 && (
              <Button
                variant="outlined"
                startIcon={<HistoryIcon />}
                onClick={() => setShowVersionHistory(true)}
                sx={{ borderColor: colors.borderColor, color: colors.textSecondary, '&:hover': { borderColor: colors.accent, color: colors.accent } }}
              >
                History ({versionHistory.length})
              </Button>
            )}
            <Button
              variant="outlined"
              startIcon={<DuplicateIcon />}
              sx={{ borderColor: colors.borderColor, color: colors.textSecondary, '&:hover': { borderColor: colors.accent, color: colors.accent } }}
            >
              Duplicate
            </Button>
            <Button
              variant="outlined"
              startIcon={<SaveIcon />}
              onClick={handleSave}
              disabled={!hasChanges}
              sx={{
                borderColor: hasChanges ? colors.accent : colors.borderColor,
                color: hasChanges ? colors.accent : colors.textSecondary,
              }}
            >
              Save Draft
            </Button>
            <Button
              variant="contained"
              startIcon={<SendIcon />}
              onClick={handleSend}
              disabled={items.length === 0 || !hasEventContext}
              sx={{
                backgroundColor: colors.accent,
                color: '#000',
                '&:hover': { backgroundColor: '#fbc02d' },
                '&:disabled': { backgroundColor: '#333', color: '#666' },
              }}
            >
              Send to Client
            </Button>
          </Stack>
        </Box>
      </Box>

      {/* Context Warning */}
      {!proposalId && !eventId && !linkedEvent && !eventMeta && (
        <Paper sx={{ backgroundColor: colors.cardBg, border: `1px solid ${colors.borderColor}`, borderRadius: 2, p: 2, mb: 2 }}>
          <Typography variant="subtitle2" sx={{ color: colors.textSecondary, mb: 1 }}>
            Select Enquiry Event
          </Typography>
          <Autocomplete
            size="small"
            options={enquiryEvents}
            loading={loadingEnquiryEvents}
            value={selectedEnquiryEvent}
            onChange={(_, value) => setSelectedEnquiryEvent(value)}
            isOptionEqualToValue={(option, value) => option.id === value.id}
            getOptionLabel={(option) => `${option.eventName} - ${option.clientName}`}
            renderInput={(params) => (
              <TextField
                {...params}
                placeholder="Search enquiry events..."
                helperText="Only events in Enquiry status are shown."
                sx={{
                  '& .MuiOutlinedInput-root': {
                    backgroundColor: colors.inputBg,
                    '& fieldset': { borderColor: colors.borderColor },
                  },
                  '& .MuiInputBase-input': { color: colors.textPrimary },
                }}
                slotProps={{
                  input: {
                    ...params.InputProps,
                    endAdornment: (
                      <>
                        {loadingEnquiryEvents ? <CircularProgress color="inherit" size={16} /> : null}
                        {params.InputProps.endAdornment}
                      </>
                    ),
                  },
                }}
              />
            )}
            renderOption={(props, option) => {
              const { key, ...rest } = props as { key: string } & React.HTMLAttributes<HTMLLIElement>;
              return (
                <Box component="li" {...rest} key={key} sx={{ display: 'flex', flexDirection: 'column', alignItems: 'flex-start', py: 1 }}>
                  <Typography variant="body2" sx={{ fontWeight: 600 }}>
                    {option.eventName}
                  </Typography>
                  <Typography variant="caption" sx={{ color: colors.textSecondary }}>
                    {option.clientName}
                    {option.eventDate ? ` • ${new Date(option.eventDate).toLocaleDateString('en-IN')}` : ''}
                  </Typography>
                </Box>
              );
            }}
            noOptionsText={loadingEnquiryEvents ? 'Loading enquiry events...' : 'No enquiry events found'}
          />
        </Paper>
      )}

      {!hasEventContext && !proposalId && (
        <Alert severity="info" sx={{ mb: 2 }}>
          Select an Enquiry event above, or open any event and click New Proposal.
        </Alert>
      )}

      {/* Low Margin Warning */}
      {hasLowMarginItems && (
        <Alert
          severity="warning"
          icon={<WarningIcon />}
          sx={{
            mb: 2,
            backgroundColor: 'rgba(255, 152, 0, 0.1)',
            border: '1px solid #ff9800',
            '& .MuiAlert-message': { color: colors.textPrimary },
          }}
        >
          Some items have margins below 20%. Review pricing before sending.
        </Alert>
      )}

      <Grid container spacing={3}>
        {/* Left: Line Items */}
        <Grid size={{ xs: 12, lg: 8 }}>
          <Paper sx={{ backgroundColor: colors.cardBg, border: `1px solid ${colors.borderColor}`, borderRadius: 2, overflow: 'hidden' }}>
            {/* Toolbar */}
            <Box
              sx={{
                p: 2,
                borderBottom: `1px solid ${colors.borderColor}`,
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'space-between',
              }}
            >
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                <Typography variant="subtitle1" sx={{ color: colors.textPrimary, fontWeight: 600 }}>
                  Line Items
                </Typography>
                <Chip label={`${items.length} items`} size="small" sx={{ backgroundColor: alpha(theme.palette.text.primary, 0.12), color: colors.textPrimary }} />
              </Box>
              <Stack direction="row" spacing={1}>
                <Button
                  size="small"
                  startIcon={<ProductIcon />}
                  onClick={() => addItem('PRODUCT')}
                  sx={{ color: '#4caf50' }}
                >
                  Product
                </Button>
                <Button
                  size="small"
                  startIcon={<ServiceIcon />}
                  onClick={() => addItem('SERVICE')}
                  sx={{ color: '#2196f3' }}
                >
                  Service
                </Button>
                <Button
                  size="small"
                  startIcon={<PackageIcon />}
                  onClick={() => addItem('PACKAGE')}
                  sx={{ color: '#9c27b0' }}
                >
                  Package
                </Button>
              </Stack>
            </Box>

            {/* Items Table */}
            <TableContainer sx={{ maxHeight: 500 }}>
              <Table stickyHeader size="small">
                <TableHead>
                  <TableRow sx={{ '& th': { backgroundColor: colors.tableHeadBg, color: colors.textSecondary, borderColor: colors.borderColor } }}>
                    <TableCell>Type</TableCell>
                    <TableCell>Item</TableCell>
                    <TableCell align="center">Qty</TableCell>
                    <TableCell align="right">Unit Price</TableCell>
                    <TableCell align="right">Unit Cost</TableCell>
                    <TableCell align="right">Total</TableCell>
                    <TableCell align="right">Margin</TableCell>
                    <TableCell align="center"></TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {items.length === 0 ? (
                    <TableRow>
                      <TableCell colSpan={8} sx={{ textAlign: 'center', py: 6, color: colors.textSecondary }}>
                        <Box>
                          <AddIcon sx={{ fontSize: 48, mb: 1, opacity: 0.3 }} />
                          <Typography>No items yet. Add products, services, or packages.</Typography>
                        </Box>
                      </TableCell>
                    </TableRow>
                  ) : (
                    items.map((item, index) => (
                      <LineItemRow
                        key={item.id}
                        item={item}
                        index={index}
                        onUpdate={updateItem}
                        onDelete={deleteItem}
                        colors={colors}
                      />
                    ))
                  )}
                </TableBody>
              </Table>
            </TableContainer>
          </Paper>

          {/* Notes */}
          <Paper sx={{ backgroundColor: colors.cardBg, border: `1px solid ${colors.borderColor}`, borderRadius: 2, p: 2, mt: 3 }}>
            <Typography variant="subtitle2" sx={{ color: colors.textSecondary, mb: 1 }}>
              Internal Notes
            </Typography>
            <TextField
              multiline
              rows={3}
              fullWidth
              value={notes}
              onChange={(e) => {
                setNotes(e.target.value);
                setHasChanges(true);
              }}
              placeholder="Add notes for your team..."
              sx={{
                '& .MuiOutlinedInput-root': {
                  backgroundColor: colors.inputBg,
                  '& fieldset': { borderColor: colors.borderColor },
                },
                '& .MuiInputBase-input': { color: colors.textPrimary },
              }}
            />
          </Paper>
        </Grid>

        {/* Right: Profit Summary */}
        <Grid size={{ xs: 12, lg: 4 }}>
          <ProfitSummaryPanel
            subtotal={totals.subtotal}
            discountType={discountType}
            discountValue={discountValue}
            discount={totals.discount}
            taxRate={taxRate}
            tax={totals.tax}
            grandTotal={totals.grandTotal}
            totalCost={totals.totalCost}
            grossProfit={totals.grossProfit}
            marginPercentage={totals.marginPercentage}
            onDiscountTypeChange={handleDiscountTypeChange}
            onDiscountValueChange={handleDiscountValueChange}
            onTaxRateChange={handleTaxRateChange}
          />

          {/* Version Info */}
          <Paper sx={{ backgroundColor: colors.cardBg, border: `1px solid ${colors.borderColor}`, borderRadius: 2, p: 2, mt: 2 }}>
            <Typography variant="subtitle2" sx={{ color: colors.textSecondary, mb: 1 }}>
              Version Name
            </Typography>
            <TextField
              size="small"
              fullWidth
              value={versionName}
              onChange={(e) => {
                setVersionName(e.target.value);
                setHasChanges(true);
              }}
              sx={{
                '& .MuiOutlinedInput-root': {
                  backgroundColor: colors.inputBg,
                  '& fieldset': { borderColor: colors.borderColor },
                },
                '& .MuiInputBase-input': { color: colors.textPrimary },
              }}
            />
          </Paper>
        </Grid>
      </Grid>

      {/* Version History Dialog */}
      <VersionHistoryDialog
        open={showVersionHistory}
        onClose={() => setShowVersionHistory(false)}
        versions={versionHistory}
        onRestore={handleRestoreVersion}
        colors={colors}
      />
    </Box>
  );
};

export default ProposalBuilder;
