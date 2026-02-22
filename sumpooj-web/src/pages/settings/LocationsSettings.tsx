/**
 * LocationsSettings.tsx — Locations Management UI
 *
 * Features:
 * - List all store locations
 * - Add/Edit/Deactivate locations
 * - Set default location
 * - Support for different location types (Store, Warehouse, Office)
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
} from '@mui/material';
import {
  Add,
  Edit,
  Delete,
  CheckCircle,
  Store,
  Warehouse,
  Business,
  LocationOn,
  Star,
  StarBorder,
  Refresh,
} from '@mui/icons-material';
import {
  type CreateLocationRequest,
  type UpdateLocationRequest,
  getLocations,
  getLocationById,
  createLocation,
  updateLocation,
  deactivateLocation,
} from '../../api/location.api';
import { useToast } from '../../hooks/useToast';

// ─── Location Types ─────────────────────────────────────────

const LOCATION_TYPES = [
  { value: 'Store', label: 'Retail Store', icon: <Store />, color: '#4caf50' },
  { value: 'Warehouse', label: 'Warehouse', icon: <Warehouse />, color: '#ff9800' },
  { value: 'Office', label: 'Office', icon: <Business />, color: '#2196f3' },
];

const getLocationTypeConfig = (type: string) => {
  return LOCATION_TYPES.find((t) => t.value === type) || LOCATION_TYPES[0];
};

// ─── Location DTO ───────────────────────────────────────────

interface LocationDto {
  id: string;
  name: string;
  code: string;
  locationType: string;
  address: string | null;
  isDefault: boolean;
  isActive: boolean;
}

// ─── Location Card Component ────────────────────────────────

interface LocationCardProps {
  location: LocationDto;
  onEdit: () => void;
  onDeactivate: () => void;
  onSetDefault: () => void;
}

const LocationCard: React.FC<LocationCardProps> = ({
  location,
  onEdit,
  onDeactivate,
  onSetDefault,
}) => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';
  const typeConfig = getLocationTypeConfig(location.locationType);

  return (
    <Card
      sx={{
        position: 'relative',
        border: `2px solid ${location.isDefault ? typeConfig.color : 'transparent'}`,
        opacity: location.isActive ? 1 : 0.6,
        transition: 'all 0.2s',
        '&:hover': {
          boxShadow: 4,
        },
      }}
    >
      {/* Default Badge */}
      {location.isDefault && (
        <Chip
          icon={<Star sx={{ fontSize: 16 }} />}
          label="DEFAULT"
          size="small"
          sx={{
            position: 'absolute',
            top: 8,
            right: 8,
            bgcolor: typeConfig.color,
            color: 'white',
            fontWeight: 600,
            fontSize: '0.7rem',
          }}
        />
      )}

      <CardContent>
        {/* Header */}
        <Stack direction="row" spacing={2} alignItems="center" mb={2}>
          <Box
            sx={{
              width: 48,
              height: 48,
              borderRadius: 2,
              bgcolor: dk ? alpha(typeConfig.color, 0.2) : alpha(typeConfig.color, 0.1),
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              color: typeConfig.color,
            }}
          >
            {typeConfig.icon}
          </Box>
          <Box flex={1}>
            <Typography variant="h6" fontWeight={700}>
              {location.name}
            </Typography>
            <Typography variant="body2" color="text.secondary">
              Code: {location.code}
            </Typography>
          </Box>
        </Stack>

        {/* Details */}
        <Stack spacing={1} mb={2}>
          <Chip
            label={typeConfig.label}
            size="small"
            sx={{
              bgcolor: dk ? alpha(typeConfig.color, 0.2) : alpha(typeConfig.color, 0.1),
              color: typeConfig.color,
              fontWeight: 500,
            }}
          />

          {location.address && (
            <Stack direction="row" spacing={0.5} alignItems="flex-start">
              <LocationOn sx={{ fontSize: 18, color: 'text.secondary', mt: 0.2 }} />
              <Typography variant="body2" color="text.secondary">
                {location.address}
              </Typography>
            </Stack>
          )}
        </Stack>

        <Divider sx={{ my: 1.5 }} />

        {/* Actions */}
        <Stack direction="row" justifyContent="space-between" alignItems="center">
          <Chip
            label={location.isActive ? 'Active' : 'Inactive'}
            size="small"
            color={location.isActive ? 'success' : 'default'}
          />

          <Stack direction="row" spacing={0.5}>
            {!location.isDefault && location.isActive && (
              <Tooltip title="Set as Default">
                <IconButton size="small" onClick={onSetDefault}>
                  <StarBorder />
                </IconButton>
              </Tooltip>
            )}
            <Tooltip title="Edit">
              <IconButton size="small" onClick={onEdit}>
                <Edit />
              </IconButton>
            </Tooltip>
            {location.isActive && !location.isDefault && (
              <Tooltip title="Deactivate">
                <IconButton size="small" color="error" onClick={onDeactivate}>
                  <Delete />
                </IconButton>
              </Tooltip>
            )}
          </Stack>
        </Stack>
      </CardContent>
    </Card>
  );
};

// ─── Location Form Dialog ───────────────────────────────────

interface LocationFormProps {
  open: boolean;
  onClose: () => void;
  onSave: (data: CreateLocationRequest | UpdateLocationRequest, id?: string) => void;
  editLocation?: LocationDto | null;
  loading?: boolean;
}

const LocationFormDialog: React.FC<LocationFormProps> = ({
  open,
  onClose,
  onSave,
  editLocation,
  loading,
}) => {
  const [name, setName] = useState('');
  const [code, setCode] = useState('');
  const [locationType, setLocationType] = useState('Store');
  const [address, setAddress] = useState('');
  const [isDefault, setIsDefault] = useState(false);

  useEffect(() => {
    if (open) {
      if (editLocation) {
        setName(editLocation.name);
        setCode(editLocation.code);
        setLocationType(editLocation.locationType);
        setAddress(editLocation.address || '');
        setIsDefault(editLocation.isDefault);
      } else {
        setName('');
        setCode('');
        setLocationType('Store');
        setAddress('');
        setIsDefault(false);
      }
    }
  }, [open, editLocation]);

  const handleSubmit = () => {
    if (editLocation) {
      const update: UpdateLocationRequest = {
        name,
        address: address || null,
        isDefault,
      };
      onSave(update, editLocation.id);
    } else {
      const create: CreateLocationRequest = {
        name,
        code,
        locationType,
        address: address || null,
        isDefault,
      };
      onSave(create);
    }
  };

  const canSubmit = name.trim() && (editLocation || code.trim());

  return (
    <Dialog open={open} onClose={onClose} maxWidth="sm" fullWidth>
      <DialogTitle>
        <Stack direction="row" spacing={1} alignItems="center">
          <Store />
          <Typography variant="h6">
            {editLocation ? 'Edit Location' : 'Add Location'}
          </Typography>
        </Stack>
      </DialogTitle>

      <DialogContent dividers>
        <Grid container spacing={3}>
          <Grid size={12}>
            <TextField
              fullWidth
              label="Location Name"
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="e.g., Main Store, Downtown Branch"
              required
            />
          </Grid>

          <Grid size={{ xs: 12, md: 6 }}>
            <TextField
              fullWidth
              label="Location Code"
              value={code}
              onChange={(e) => setCode(e.target.value.toUpperCase())}
              placeholder="e.g., MAIN, DT01"
              required
              disabled={!!editLocation}
              helperText="Unique identifier for the location"
            />
          </Grid>

          <Grid size={{ xs: 12, md: 6 }}>
            <FormControl fullWidth>
              <InputLabel>Location Type</InputLabel>
              <Select
                value={locationType}
                onChange={(e) => setLocationType(e.target.value)}
                label="Location Type"
                disabled={!!editLocation}
              >
                {LOCATION_TYPES.map((type) => (
                  <MenuItem key={type.value} value={type.value}>
                    <Stack direction="row" spacing={1} alignItems="center">
                      {React.cloneElement(type.icon, { sx: { color: type.color } })}
                      <Typography>{type.label}</Typography>
                    </Stack>
                  </MenuItem>
                ))}
              </Select>
            </FormControl>
          </Grid>

          <Grid size={12}>
            <TextField
              fullWidth
              label="Address"
              value={address}
              onChange={(e) => setAddress(e.target.value)}
              placeholder="Full address"
              multiline
              rows={2}
            />
          </Grid>

          <Grid size={12}>
            <FormControlLabel
              control={
                <Switch
                  checked={isDefault}
                  onChange={(e) => setIsDefault(e.target.checked)}
                  color="primary"
                />
              }
              label="Set as default location"
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
          {editLocation ? 'Update' : 'Add Location'}
        </Button>
      </DialogActions>
    </Dialog>
  );
};

// ─── Main Component ─────────────────────────────────────────

const LocationsSettings: React.FC = () => {
  const theme = useTheme();
  const toast = useToast();

  const [locations, setLocations] = useState<LocationDto[]>([]);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);

  // Dialogs
  const [formOpen, setFormOpen] = useState(false);
  const [editLocation, setEditLocation] = useState<LocationDto | null>(null);
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [locationToDelete, setLocationToDelete] = useState<LocationDto | null>(null);

  // ─── Data Loading ───────────────────────────────────────

  const loadData = useCallback(async () => {
    try {
      setLoading(true);
      const data = await getLocations();
      setLocations(data);
    } catch (err) {
      toast.error('Failed to load locations');
      console.error(err);
    } finally {
      setLoading(false);
    }
  }, [toast]);

  useEffect(() => {
    loadData();
  }, [loadData]);

  // ─── Handlers ───────────────────────────────────────────

  const handleAdd = () => {
    setEditLocation(null);
    setFormOpen(true);
  };

  const handleEdit = (location: LocationDto) => {
    setEditLocation(location);
    setFormOpen(true);
  };

  const handleSave = async (data: CreateLocationRequest | UpdateLocationRequest, id?: string) => {
    try {
      setSaving(true);
      if (id) {
        await updateLocation(id, data as UpdateLocationRequest);
        toast.success('Location updated successfully');
      } else {
        await createLocation(data as CreateLocationRequest);
        toast.success('Location added successfully');
      }
      setFormOpen(false);
      loadData();
    } catch (err: any) {
      toast.error(err?.response?.data?.message || 'Failed to save location');
    } finally {
      setSaving(false);
    }
  };

  const handleDeactivate = async () => {
    if (!locationToDelete) return;
    try {
      setSaving(true);
      await deactivateLocation(locationToDelete.id);
      toast.success('Location deactivated');
      setDeleteDialogOpen(false);
      setLocationToDelete(null);
      loadData();
    } catch (err) {
      toast.error('Failed to deactivate location');
    } finally {
      setSaving(false);
    }
  };

  const handleSetDefault = async (location: LocationDto) => {
    try {
      await updateLocation(location.id, { isDefault: true });
      toast.success(`${location.name} is now the default location`);
      loadData();
    } catch (err) {
      toast.error('Failed to set default location');
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

  const activeLocations = locations.filter((l) => l.isActive);
  const inactiveLocations = locations.filter((l) => !l.isActive);

  return (
    <Box p={3}>
      {/* Header */}
      <Stack direction="row" justifyContent="space-between" alignItems="center" mb={3}>
        <Box>
          <Typography variant="h4" fontWeight={700}>
            Locations
          </Typography>
          <Typography variant="body2" color="text.secondary">
            Manage your store locations and warehouses
          </Typography>
        </Box>
        <Stack direction="row" spacing={1}>
          <Button startIcon={<Refresh />} onClick={loadData} variant="outlined">
            Refresh
          </Button>
          <Button startIcon={<Add />} variant="contained" onClick={handleAdd}>
            Add Location
          </Button>
        </Stack>
      </Stack>

      {/* No Locations Alert */}
      {locations.length === 0 && (
        <Alert severity="info" sx={{ mb: 3 }}>
          <Typography fontWeight={600}>No locations configured</Typography>
          <Typography variant="body2">
            Add your first location to enable multi-location inventory and POS operations.
          </Typography>
        </Alert>
      )}

      {/* Active Locations */}
      {activeLocations.length > 0 && (
        <Box mb={4}>
          <Typography variant="h6" fontWeight={600} mb={2}>
            Active Locations ({activeLocations.length})
          </Typography>
          <Grid container spacing={3}>
            {activeLocations.map((location) => (
              <Grid key={location.id} size={{ xs: 12, md: 6, lg: 4 }}>
                <LocationCard
                  location={location}
                  onEdit={() => handleEdit(location)}
                  onDeactivate={() => {
                    setLocationToDelete(location);
                    setDeleteDialogOpen(true);
                  }}
                  onSetDefault={() => handleSetDefault(location)}
                />
              </Grid>
            ))}
          </Grid>
        </Box>
      )}

      {/* Inactive Locations */}
      {inactiveLocations.length > 0 && (
        <Box>
          <Typography variant="h6" fontWeight={600} mb={2} color="text.secondary">
            Inactive Locations ({inactiveLocations.length})
          </Typography>
          <Grid container spacing={3}>
            {inactiveLocations.map((location) => (
              <Grid key={location.id} size={{ xs: 12, md: 6, lg: 4 }}>
                <LocationCard
                  location={location}
                  onEdit={() => handleEdit(location)}
                  onDeactivate={() => {}}
                  onSetDefault={() => {}}
                />
              </Grid>
            ))}
          </Grid>
        </Box>
      )}

      {/* Form Dialog */}
      <LocationFormDialog
        open={formOpen}
        onClose={() => setFormOpen(false)}
        onSave={handleSave}
        editLocation={editLocation}
        loading={saving}
      />

      {/* Deactivate Confirmation */}
      <Dialog open={deleteDialogOpen} onClose={() => setDeleteDialogOpen(false)} maxWidth="xs" fullWidth>
        <DialogTitle>Deactivate Location</DialogTitle>
        <DialogContent>
          <Alert severity="warning" sx={{ mb: 2 }}>
            This location will be deactivated. Existing data will be preserved.
          </Alert>
          <Typography>
            Are you sure you want to deactivate <strong>{locationToDelete?.name}</strong>?
          </Typography>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDeleteDialogOpen(false)} disabled={saving}>
            Cancel
          </Button>
          <Button
            variant="contained"
            color="error"
            onClick={handleDeactivate}
            disabled={saving}
            startIcon={saving ? <CircularProgress size={20} /> : <Delete />}
          >
            Deactivate
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default LocationsSettings;
