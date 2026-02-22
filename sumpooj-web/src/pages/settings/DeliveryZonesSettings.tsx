/**
 * DeliveryZonesSettings.tsx — Delivery Zones Management UI
 *
 * Features:
 * - List all delivery zones
 * - Add/Edit/Delete zones
 * - Configure fees (standard, same-day, express)
 * - ZIP code / City based matching
 * - Free delivery thresholds
 */
import React, { useState, useEffect, useCallback } from 'react';
import {
  Box,
  Typography,
  Card,
  CardContent,
  Grid,
  Button,
  IconButton,
  Chip,
  Stack,
  Alert,
  CircularProgress,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  FormControlLabel,
  Switch,
  Tooltip,
  Divider,
  Paper,
  useTheme,
  alpha,
  InputAdornment,
  Table,
  TableHead,
  TableBody,
  TableRow,
  TableCell,
  TableContainer,
} from '@mui/material';
import {
  Add,
  Edit,
  Delete,
  LocalShipping,
  AttachMoney,
  Schedule,
  CheckCircle,
  Cancel,
  Refresh,
  LocationOn,
  Speed,
  DirectionsCar,
} from '@mui/icons-material';
import {
  type DeliveryZone,
  type CreateDeliveryZoneRequest,
  getDeliveryZones,
  createDeliveryZone,
  updateDeliveryZone,
  deleteDeliveryZone,
  activateDeliveryZone,
  deactivateDeliveryZone,
} from '../../api/delivery-zone.api';
import { useToast } from '../../hooks/useToast';
import { useCurrency } from '../../core/i18n/CurrencyContext';

// ─── Match Type Config ──────────────────────────────────────

const MATCH_TYPES = [
  { value: 'ZIP', label: 'ZIP/Postal Code', description: 'Match by postal codes' },
  { value: 'CITY', label: 'City', description: 'Match by city names' },
  { value: 'AREA', label: 'Area/Neighborhood', description: 'Match by area names' },
];

// ─── Zone Card Component ────────────────────────────────────

interface ZoneCardProps {
  zone: DeliveryZone;
  currencySymbol: string;
  onEdit: () => void;
  onDelete: () => void;
  onToggleActive: () => void;
}

const ZoneCard: React.FC<ZoneCardProps> = ({
  zone,
  currencySymbol,
  onEdit,
  onDelete,
  onToggleActive,
}) => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';
  const zoneColor = zone.color || '#4caf50';

  return (
    <Card
      sx={{
        height: '100%',
        opacity: zone.isActive ? 1 : 0.6,
        borderLeft: `4px solid ${zoneColor}`,
        transition: 'all 0.2s',
        '&:hover': {
          boxShadow: 4,
        },
      }}
    >
      <CardContent>
        {/* Header */}
        <Stack direction="row" justifyContent="space-between" alignItems="flex-start" mb={2}>
          <Box>
            <Typography variant="h6" fontWeight={700}>
              {zone.name}
            </Typography>
            <Typography variant="body2" color="text.secondary">
              Code: {zone.code}
            </Typography>
          </Box>
          <Stack direction="row" spacing={0.5}>
            {zone.isServiceable ? (
              <Chip
                icon={<CheckCircle sx={{ fontSize: 16 }} />}
                label="Serviceable"
                size="small"
                color="success"
              />
            ) : (
              <Chip
                icon={<Cancel sx={{ fontSize: 16 }} />}
                label="Not Serviceable"
                size="small"
                color="error"
              />
            )}
          </Stack>
        </Stack>

        {/* Match Info */}
        <Box mb={2}>
          <Chip
            label={zone.matchType}
            size="small"
            variant="outlined"
            sx={{ mr: 1, mb: 1 }}
          />
          <Typography variant="body2" color="text.secondary" sx={{
            display: '-webkit-box',
            WebkitLineClamp: 2,
            WebkitBoxOrient: 'vertical',
            overflow: 'hidden',
          }}>
            {zone.matchValues?.join(', ') || zone.zipCodes?.join(', ') || zone.cities?.join(', ')}
          </Typography>
        </Box>

        {/* Fees */}
        <Grid container spacing={1} mb={2}>
          <Grid size={4}>
            <Paper variant="outlined" sx={{ p: 1, textAlign: 'center' }}>
              <Typography variant="caption" color="text.secondary">Standard</Typography>
              <Typography variant="body1" fontWeight={600}>
                {currencySymbol}{zone.deliveryFee}
              </Typography>
            </Paper>
          </Grid>
          <Grid size={4}>
            <Paper variant="outlined" sx={{ p: 1, textAlign: 'center' }}>
              <Typography variant="caption" color="text.secondary">Same Day</Typography>
              <Typography variant="body1" fontWeight={600}>
                {currencySymbol}{zone.sameDayFee}
              </Typography>
            </Paper>
          </Grid>
          <Grid size={4}>
            <Paper variant="outlined" sx={{ p: 1, textAlign: 'center' }}>
              <Typography variant="caption" color="text.secondary">Express</Typography>
              <Typography variant="body1" fontWeight={600}>
                {currencySymbol}{zone.expressFee}
              </Typography>
            </Paper>
          </Grid>
        </Grid>

        {/* Estimated Time */}
        <Stack direction="row" spacing={2} mb={2}>
          <Stack direction="row" spacing={0.5} alignItems="center">
            <Schedule sx={{ fontSize: 18, color: 'text.secondary' }} />
            <Typography variant="body2">
              {zone.estimatedMinutes} min
            </Typography>
          </Stack>
          {zone.distanceKm && (
            <Stack direction="row" spacing={0.5} alignItems="center">
              <DirectionsCar sx={{ fontSize: 18, color: 'text.secondary' }} />
              <Typography variant="body2">
                {zone.distanceKm} km
              </Typography>
            </Stack>
          )}
          {zone.freeDeliveryThreshold && (
            <Stack direction="row" spacing={0.5} alignItems="center">
              <AttachMoney sx={{ fontSize: 18, color: 'success.main' }} />
              <Typography variant="body2" color="success.main">
                Free over {currencySymbol}{zone.freeDeliveryThreshold}
              </Typography>
            </Stack>
          )}
        </Stack>

        <Divider sx={{ my: 1.5 }} />

        {/* Actions */}
        <Stack direction="row" justifyContent="space-between" alignItems="center">
          <FormControlLabel
            control={
              <Switch
                checked={zone.isActive}
                onChange={onToggleActive}
                size="small"
                color="success"
              />
            }
            label={zone.isActive ? 'Active' : 'Inactive'}
          />
          <Stack direction="row" spacing={0.5}>
            <Tooltip title="Edit">
              <IconButton size="small" onClick={onEdit}>
                <Edit />
              </IconButton>
            </Tooltip>
            <Tooltip title="Delete">
              <IconButton size="small" color="error" onClick={onDelete}>
                <Delete />
              </IconButton>
            </Tooltip>
          </Stack>
        </Stack>
      </CardContent>
    </Card>
  );
};

// ─── Zone Form Dialog ───────────────────────────────────────

interface ZoneFormProps {
  open: boolean;
  onClose: () => void;
  onSave: (data: CreateDeliveryZoneRequest, id?: string) => void;
  editZone?: DeliveryZone | null;
  loading?: boolean;
  currencySymbol: string;
}

const ZoneFormDialog: React.FC<ZoneFormProps> = ({
  open,
  onClose,
  onSave,
  editZone,
  loading,
  currencySymbol,
}) => {
  const [name, setName] = useState('');
  const [code, setCode] = useState('');
  const [matchType, setMatchType] = useState<'ZIP' | 'AREA' | 'CITY'>('ZIP');
  const [matchValuesText, setMatchValuesText] = useState('');
  const [deliveryFee, setDeliveryFee] = useState(0);
  const [sameDayFee, setSameDayFee] = useState(0);
  const [expressFee, setExpressFee] = useState(0);
  const [estimatedMinutes, setEstimatedMinutes] = useState(60);
  const [distanceKm, setDistanceKm] = useState<number | undefined>(undefined);
  const [freeDeliveryThreshold, setFreeDeliveryThreshold] = useState<number | undefined>(undefined);
  const [priority, setPriority] = useState(1);
  const [isServiceable, setIsServiceable] = useState(true);
  const [notes, setNotes] = useState('');
  const [color, setColor] = useState('#4caf50');

  useEffect(() => {
    if (open) {
      if (editZone) {
        setName(editZone.name);
        setCode(editZone.code);
        setMatchType(editZone.matchType || 'ZIP');
        setMatchValuesText((editZone.matchValues || editZone.zipCodes || editZone.cities || []).join(', '));
        setDeliveryFee(editZone.deliveryFee);
        setSameDayFee(editZone.sameDayFee);
        setExpressFee(editZone.expressFee);
        setEstimatedMinutes(editZone.estimatedMinutes);
        setDistanceKm(editZone.distanceKm);
        setFreeDeliveryThreshold(editZone.freeDeliveryThreshold);
        setPriority(editZone.priority);
        setIsServiceable(editZone.isServiceable);
        setNotes(editZone.notes || '');
        setColor(editZone.color || '#4caf50');
      } else {
        setName('');
        setCode('');
        setMatchType('ZIP');
        setMatchValuesText('');
        setDeliveryFee(0);
        setSameDayFee(0);
        setExpressFee(0);
        setEstimatedMinutes(60);
        setDistanceKm(undefined);
        setFreeDeliveryThreshold(undefined);
        setPriority(1);
        setIsServiceable(true);
        setNotes('');
        setColor('#4caf50');
      }
    }
  }, [open, editZone]);

  const handleSubmit = () => {
    const matchValues = matchValuesText
      .split(',')
      .map((v) => v.trim())
      .filter((v) => v);

    const data: CreateDeliveryZoneRequest = {
      name,
      code,
      matchType,
      matchValues,
      deliveryFee,
      sameDayFee,
      expressFee,
      estimatedMinutes,
      distanceKm,
      freeDeliveryThreshold,
      priority,
      isServiceable,
      notes: notes || undefined,
      color,
    };
    onSave(data, editZone?.id);
  };

  const canSubmit = name.trim() && code.trim() && matchValuesText.trim();

  return (
    <Dialog open={open} onClose={onClose} maxWidth="md" fullWidth>
      <DialogTitle>
        <Stack direction="row" spacing={1} alignItems="center">
          <LocalShipping />
          <Typography variant="h6">
            {editZone ? 'Edit Delivery Zone' : 'Add Delivery Zone'}
          </Typography>
        </Stack>
      </DialogTitle>

      <DialogContent dividers>
        <Grid container spacing={3}>
          {/* Basic Info */}
          <Grid size={{ xs: 12, md: 6 }}>
            <TextField
              fullWidth
              label="Zone Name"
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="e.g., Downtown, North Area"
              required
            />
          </Grid>

          <Grid size={{ xs: 12, md: 3 }}>
            <TextField
              fullWidth
              label="Zone Code"
              value={code}
              onChange={(e) => setCode(e.target.value.toUpperCase())}
              placeholder="e.g., DT, NA"
              required
            />
          </Grid>

          <Grid size={{ xs: 12, md: 3 }}>
            <TextField
              fullWidth
              label="Priority"
              type="number"
              value={priority}
              onChange={(e) => setPriority(parseInt(e.target.value) || 1)}
              InputProps={{
                inputProps: { min: 1 },
              }}
              helperText="Lower = higher priority"
            />
          </Grid>

          {/* Match Type */}
          <Grid size={{ xs: 12, md: 4 }}>
            <FormControl fullWidth>
              <InputLabel>Match Type</InputLabel>
              <Select
                value={matchType}
                onChange={(e) => setMatchType(e.target.value as 'ZIP' | 'AREA' | 'CITY')}
                label="Match Type"
              >
                {MATCH_TYPES.map((type) => (
                  <MenuItem key={type.value} value={type.value}>
                    {type.label}
                  </MenuItem>
                ))}
              </Select>
            </FormControl>
          </Grid>

          <Grid size={{ xs: 12, md: 8 }}>
            <TextField
              fullWidth
              label={`${matchType === 'ZIP' ? 'ZIP Codes' : matchType === 'CITY' ? 'Cities' : 'Areas'} (comma separated)`}
              value={matchValuesText}
              onChange={(e) => setMatchValuesText(e.target.value)}
              placeholder={matchType === 'ZIP' ? '10001, 10002, 10003' : 'Manhattan, Brooklyn'}
              required
              helperText="Enter values separated by commas"
            />
          </Grid>

          <Grid size={12}>
            <Divider>
              <Chip label="Delivery Fees" size="small" />
            </Divider>
          </Grid>

          {/* Fees */}
          <Grid size={{ xs: 12, md: 4 }}>
            <TextField
              fullWidth
              label="Standard Delivery Fee"
              type="number"
              value={deliveryFee}
              onChange={(e) => setDeliveryFee(parseFloat(e.target.value) || 0)}
              InputProps={{
                startAdornment: <InputAdornment position="start">{currencySymbol}</InputAdornment>,
                inputProps: { min: 0, step: 0.01 },
              }}
            />
          </Grid>

          <Grid size={{ xs: 12, md: 4 }}>
            <TextField
              fullWidth
              label="Same Day Fee"
              type="number"
              value={sameDayFee}
              onChange={(e) => setSameDayFee(parseFloat(e.target.value) || 0)}
              InputProps={{
                startAdornment: <InputAdornment position="start">{currencySymbol}</InputAdornment>,
                inputProps: { min: 0, step: 0.01 },
              }}
            />
          </Grid>

          <Grid size={{ xs: 12, md: 4 }}>
            <TextField
              fullWidth
              label="Express Fee"
              type="number"
              value={expressFee}
              onChange={(e) => setExpressFee(parseFloat(e.target.value) || 0)}
              InputProps={{
                startAdornment: <InputAdornment position="start">{currencySymbol}</InputAdornment>,
                inputProps: { min: 0, step: 0.01 },
              }}
            />
          </Grid>

          <Grid size={{ xs: 12, md: 4 }}>
            <TextField
              fullWidth
              label="Free Delivery Threshold"
              type="number"
              value={freeDeliveryThreshold || ''}
              onChange={(e) => setFreeDeliveryThreshold(parseFloat(e.target.value) || undefined)}
              InputProps={{
                startAdornment: <InputAdornment position="start">{currencySymbol}</InputAdornment>,
                inputProps: { min: 0, step: 0.01 },
              }}
              helperText="Leave empty for no free delivery"
            />
          </Grid>

          <Grid size={{ xs: 12, md: 4 }}>
            <TextField
              fullWidth
              label="Estimated Delivery Time"
              type="number"
              value={estimatedMinutes}
              onChange={(e) => setEstimatedMinutes(parseInt(e.target.value) || 0)}
              InputProps={{
                endAdornment: <InputAdornment position="end">minutes</InputAdornment>,
                inputProps: { min: 0 },
              }}
            />
          </Grid>

          <Grid size={{ xs: 12, md: 4 }}>
            <TextField
              fullWidth
              label="Distance"
              type="number"
              value={distanceKm || ''}
              onChange={(e) => setDistanceKm(parseFloat(e.target.value) || undefined)}
              InputProps={{
                endAdornment: <InputAdornment position="end">km</InputAdornment>,
                inputProps: { min: 0, step: 0.1 },
              }}
            />
          </Grid>

          {/* Options */}
          <Grid size={{ xs: 12, md: 6 }}>
            <FormControlLabel
              control={
                <Switch
                  checked={isServiceable}
                  onChange={(e) => setIsServiceable(e.target.checked)}
                  color="success"
                />
              }
              label="Zone is serviceable (deliveries can be made)"
            />
          </Grid>

          <Grid size={{ xs: 12, md: 6 }}>
            <TextField
              fullWidth
              label="Zone Color"
              type="color"
              value={color}
              onChange={(e) => setColor(e.target.value)}
              sx={{ '& input': { height: 40, cursor: 'pointer' } }}
            />
          </Grid>

          <Grid size={12}>
            <TextField
              fullWidth
              label="Notes"
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              multiline
              rows={2}
              placeholder="Internal notes about this zone"
            />
          </Grid>
        </Grid>
      </DialogContent>

      <DialogActions sx={{ p: 2 }}>
        <Button onClick={onClose} disabled={loading}>
          Cancel
        </Button>
        <Button
          variant="contained"
          onClick={handleSubmit}
          disabled={!canSubmit || loading}
          startIcon={loading ? <CircularProgress size={20} /> : undefined}
        >
          {editZone ? 'Update' : 'Add Zone'}
        </Button>
      </DialogActions>
    </Dialog>
  );
};

// ─── Main Component ─────────────────────────────────────────

const DeliveryZonesSettings: React.FC = () => {
  const theme = useTheme();
  const toast = useToast();
  const { currencySymbol } = useCurrency();

  const [zones, setZones] = useState<DeliveryZone[]>([]);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [showInactive, setShowInactive] = useState(false);

  // Dialogs
  const [formOpen, setFormOpen] = useState(false);
  const [editZone, setEditZone] = useState<DeliveryZone | null>(null);
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [zoneToDelete, setZoneToDelete] = useState<DeliveryZone | null>(null);

  // ─── Data Loading ───────────────────────────────────────

  const loadData = useCallback(async () => {
    try {
      setLoading(true);
      const data = await getDeliveryZones(!showInactive);
      setZones(data);
    } catch (err) {
      toast.error('Failed to load delivery zones');
      console.error(err);
    } finally {
      setLoading(false);
    }
  }, [toast, showInactive]);

  useEffect(() => {
    loadData();
  }, [loadData]);

  // ─── Handlers ───────────────────────────────────────────

  const handleAdd = () => {
    setEditZone(null);
    setFormOpen(true);
  };

  const handleEdit = (zone: DeliveryZone) => {
    setEditZone(zone);
    setFormOpen(true);
  };

  const handleSave = async (data: CreateDeliveryZoneRequest, id?: string) => {
    try {
      setSaving(true);
      if (id) {
        await updateDeliveryZone(id, data);
        toast.success('Delivery zone updated successfully');
      } else {
        await createDeliveryZone(data);
        toast.success('Delivery zone added successfully');
      }
      setFormOpen(false);
      loadData();
    } catch (err: any) {
      toast.error(err?.response?.data?.message || 'Failed to save delivery zone');
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async () => {
    if (!zoneToDelete) return;
    try {
      setSaving(true);
      await deleteDeliveryZone(zoneToDelete.id);
      toast.success('Delivery zone deleted');
      setDeleteDialogOpen(false);
      setZoneToDelete(null);
      loadData();
    } catch (err) {
      toast.error('Failed to delete delivery zone');
    } finally {
      setSaving(false);
    }
  };

  const handleToggleActive = async (zone: DeliveryZone) => {
    try {
      if (zone.isActive) {
        await deactivateDeliveryZone(zone.id);
        toast.success('Delivery zone deactivated');
      } else {
        await activateDeliveryZone(zone.id);
        toast.success('Delivery zone activated');
      }
      loadData();
    } catch (err) {
      toast.error('Failed to update zone status');
    }
  };

  // ─── Render ─────────────────────────────────────────────

  if (loading) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" minHeight={400}>
        <CircularProgress />
      </Box>
    );
  }

  return (
    <Box p={3}>
      {/* Header */}
      <Stack direction="row" justifyContent="space-between" alignItems="center" mb={3}>
        <Box>
          <Typography variant="h4" fontWeight={700}>
            Delivery Zones
          </Typography>
          <Typography variant="body2" color="text.secondary">
            Configure delivery areas and fees
          </Typography>
        </Box>
        <Stack direction="row" spacing={1}>
          <FormControlLabel
            control={
              <Switch
                checked={showInactive}
                onChange={(e) => setShowInactive(e.target.checked)}
                size="small"
              />
            }
            label="Show Inactive"
          />
          <Button startIcon={<Refresh />} onClick={loadData} variant="outlined">
            Refresh
          </Button>
          <Button startIcon={<Add />} variant="contained" onClick={handleAdd}>
            Add Zone
          </Button>
        </Stack>
      </Stack>

      {/* No Zones Alert */}
      {zones.length === 0 && (
        <Alert severity="info" sx={{ mb: 3 }}>
          <Typography fontWeight={600}>No delivery zones configured</Typography>
          <Typography variant="body2">
            Add delivery zones to enable automatic fee calculation based on customer location.
          </Typography>
        </Alert>
      )}

      {/* Zones Grid */}
      <Grid container spacing={3}>
        {zones.map((zone) => (
          <Grid key={zone.id} size={{ xs: 12, md: 6, lg: 4 }}>
            <ZoneCard
              zone={zone}
              currencySymbol={currencySymbol}
              onEdit={() => handleEdit(zone)}
              onDelete={() => {
                setZoneToDelete(zone);
                setDeleteDialogOpen(true);
              }}
              onToggleActive={() => handleToggleActive(zone)}
            />
          </Grid>
        ))}
      </Grid>

      {/* Form Dialog */}
      <ZoneFormDialog
        open={formOpen}
        onClose={() => setFormOpen(false)}
        onSave={handleSave}
        editZone={editZone}
        loading={saving}
        currencySymbol={currencySymbol}
      />

      {/* Delete Confirmation */}
      <Dialog open={deleteDialogOpen} onClose={() => setDeleteDialogOpen(false)} maxWidth="xs" fullWidth>
        <DialogTitle>Delete Delivery Zone</DialogTitle>
        <DialogContent>
          <Alert severity="warning" sx={{ mb: 2 }}>
            This action cannot be undone.
          </Alert>
          <Typography>
            Are you sure you want to delete <strong>{zoneToDelete?.name}</strong>?
          </Typography>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDeleteDialogOpen(false)} disabled={saving}>
            Cancel
          </Button>
          <Button
            variant="contained"
            color="error"
            onClick={handleDelete}
            disabled={saving}
            startIcon={saving ? <CircularProgress size={20} /> : <Delete />}
          >
            Delete
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default DeliveryZonesSettings;
