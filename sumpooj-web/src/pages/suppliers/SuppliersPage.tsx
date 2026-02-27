/**
 * SuppliersPage.tsx — Suppliers Management UI
 *
 * Features:
 * - List all suppliers with search/filter
 * - Add/Edit/Deactivate suppliers
 * - View supplier details and stats
 * - Rating system
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
  TablePagination,
  Rating,
  Avatar,
} from '@mui/material';
import {
  Add,
  Edit,
  Delete,
  Search,
  LocalShipping,
  Phone,
  Email,
  LocationOn,
  Star,
  Refresh,
  Business,
  Receipt,
  AttachMoney,
} from '@mui/icons-material';
import {
  type CreateSupplierRequest,
  type UpdateSupplierRequest,
  searchSuppliers,
  getAllSuppliers,
  createSupplier,
  updateSupplier,
  deactivateSupplier,
  getSupplierById,
} from '../../api/supplier.api';
import { useToast } from '../../hooks/useToast';

// ─── Supplier DTO ───────────────────────────────────────────

interface SupplierDto {
  id: string;
  name: string;
  contactPerson: string | null;
  email: string | null;
  phone: string | null;
  address: string | null;
  paymentTermsDays: number;
  taxIdentifier: string | null;
  rating: number;
  isActive: boolean;
  totalOrdersCount: number;
  totalSpentAmount: number;
  lastOrderDate: string | null;
}

// ─── Supplier Card Component ────────────────────────────────

interface SupplierCardProps {
  supplier: SupplierDto;
  onEdit: () => void;
  onDeactivate: () => void;
}

const SupplierCard: React.FC<SupplierCardProps> = ({
  supplier,
  onEdit,
  onDeactivate,
}) => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';

  return (
    <Card
      sx={{
        height: '100%',
        opacity: supplier.isActive ? 1 : 0.6,
        transition: 'all 0.2s',
        '&:hover': {
          boxShadow: 4,
        },
      }}
    >
      <CardContent>
        {/* Header */}
        <Stack direction="row" spacing={2} alignItems="flex-start" mb={2}>
          <Avatar
            sx={{
              width: 48,
              height: 48,
              bgcolor: dk ? alpha('#4caf50', 0.2) : alpha('#4caf50', 0.1),
              color: '#4caf50',
            }}
          >
            <Business />
          </Avatar>
          <Box flex={1}>
            <Typography variant="h6" fontWeight={700} noWrap>
              {supplier.name}
            </Typography>
            {supplier.contactPerson && (
              <Typography variant="body2" color="text.secondary">
                {supplier.contactPerson}
              </Typography>
            )}
          </Box>
          <Chip
            label={supplier.isActive ? 'Active' : 'Inactive'}
            size="small"
            color={supplier.isActive ? 'success' : 'default'}
          />
        </Stack>

        {/* Contact Info */}
        <Stack spacing={0.5} mb={2}>
          {supplier.phone && (
            <Stack direction="row" spacing={1} alignItems="center">
              <Phone sx={{ fontSize: 16, color: 'text.secondary' }} />
              <Typography variant="body2">{supplier.phone}</Typography>
            </Stack>
          )}
          {supplier.email && (
            <Stack direction="row" spacing={1} alignItems="center">
              <Email sx={{ fontSize: 16, color: 'text.secondary' }} />
              <Typography variant="body2" noWrap>{supplier.email}</Typography>
            </Stack>
          )}
          {supplier.address && (
            <Stack direction="row" spacing={1} alignItems="flex-start">
              <LocationOn sx={{ fontSize: 16, color: 'text.secondary', mt: 0.2 }} />
              <Typography variant="body2" color="text.secondary" sx={{ 
                display: '-webkit-box',
                WebkitLineClamp: 2,
                WebkitBoxOrient: 'vertical',
                overflow: 'hidden',
              }}>
                {supplier.address}
              </Typography>
            </Stack>
          )}
        </Stack>

        {/* Stats */}
        <Stack direction="row" spacing={2} mb={2}>
          <Box>
            <Typography variant="caption" color="text.secondary">Orders</Typography>
            <Typography variant="h6" fontWeight={600}>{supplier.totalOrdersCount ?? 0}</Typography>
          </Box>
          <Box>
            <Typography variant="caption" color="text.secondary">Total Spent</Typography>
            <Typography variant="h6" fontWeight={600}>
              ${(supplier.totalSpentAmount ?? 0).toLocaleString()}
            </Typography>
          </Box>
          <Box>
            <Typography variant="caption" color="text.secondary">Terms</Typography>
            <Typography variant="h6" fontWeight={600}>{supplier.paymentTermsDays ?? 0}d</Typography>
          </Box>
        </Stack>

        {/* Rating */}
        <Stack direction="row" alignItems="center" spacing={1} mb={2}>
          <Rating value={Number(supplier.rating) || 0} readOnly size="small" />
          <Typography variant="body2" color="text.secondary">
            ({Number(supplier.rating) || 0}/5)
          </Typography>
        </Stack>

        <Divider sx={{ my: 1.5 }} />

        {/* Actions */}
        <Stack direction="row" justifyContent="flex-end" spacing={0.5}>
          <Tooltip title="Edit">
            <IconButton size="small" onClick={onEdit}>
              <Edit />
            </IconButton>
          </Tooltip>
          {supplier.isActive && (
            <Tooltip title="Deactivate">
              <IconButton size="small" color="error" onClick={onDeactivate}>
                <Delete />
              </IconButton>
            </Tooltip>
          )}
        </Stack>
      </CardContent>
    </Card>
  );
};

// ─── Supplier Form Dialog ───────────────────────────────────

interface SupplierFormProps {
  open: boolean;
  onClose: () => void;
  onSave: (data: CreateSupplierRequest | UpdateSupplierRequest, id?: string) => void;
  editSupplier?: SupplierDto | null;
  loading?: boolean;
}

const SupplierFormDialog: React.FC<SupplierFormProps> = ({
  open,
  onClose,
  onSave,
  editSupplier,
  loading,
}) => {
  const [name, setName] = useState('');
  const [contactPerson, setContactPerson] = useState('');
  const [email, setEmail] = useState('');
  const [phone, setPhone] = useState('');
  const [address, setAddress] = useState('');
  const [paymentTermsDays, setPaymentTermsDays] = useState(30);
  const [taxIdentifier, setTaxIdentifier] = useState('');
  const [rating, setRating] = useState<number | null>(3);

  useEffect(() => {
    if (open) {
      if (editSupplier) {
        setName(editSupplier.name);
        setContactPerson(editSupplier.contactPerson || '');
        setEmail(editSupplier.email || '');
        setPhone(editSupplier.phone || '');
        setAddress(editSupplier.address || '');
        setPaymentTermsDays(editSupplier.paymentTermsDays);
        setTaxIdentifier(editSupplier.taxIdentifier || '');
        setRating(editSupplier.rating);
      } else {
        setName('');
        setContactPerson('');
        setEmail('');
        setPhone('');
        setAddress('');
        setPaymentTermsDays(30);
        setTaxIdentifier('');
        setRating(3);
      }
    }
  }, [open, editSupplier]);

  const handleSubmit = () => {
    if (editSupplier) {
      const update: UpdateSupplierRequest = {
        name,
        contactPerson: contactPerson || null,
        email: email || null,
        phone: phone || null,
        address: address || null,
        paymentTermsDays,
        taxIdentifier: taxIdentifier || null,
        rating: rating?.toString() || null,
      };
      onSave(update, editSupplier.id);
    } else {
      const create: CreateSupplierRequest = {
        name,
        contactPerson: contactPerson || null,
        email: email || null,
        phone: phone || null,
        address: address || null,
        paymentTermsDays,
        taxIdentifier: taxIdentifier || null,
      };
      onSave(create);
    }
  };

  const canSubmit = name.trim();

  return (
    <Dialog open={open} onClose={onClose} maxWidth="md" fullWidth>
      <DialogTitle>
        <Stack direction="row" spacing={1} alignItems="center">
          <LocalShipping />
          <Typography variant="h6">
            {editSupplier ? 'Edit Supplier' : 'Add Supplier'}
          </Typography>
        </Stack>
      </DialogTitle>

      <DialogContent dividers>
        <Grid container spacing={3}>
          <Grid size={{ xs: 12, md: 6 }}>
            <TextField
              fullWidth
              label="Company Name"
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="e.g., ABC Flowers Ltd"
              required
            />
          </Grid>

          <Grid size={{ xs: 12, md: 6 }}>
            <TextField
              fullWidth
              label="Contact Person"
              value={contactPerson}
              onChange={(e) => setContactPerson(e.target.value)}
              placeholder="Primary contact name"
            />
          </Grid>

          <Grid size={{ xs: 12, md: 6 }}>
            <TextField
              fullWidth
              label="Email"
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="supplier@example.com"
              InputProps={{
                startAdornment: (
                  <InputAdornment position="start">
                    <Email sx={{ color: 'text.secondary' }} />
                  </InputAdornment>
                ),
              }}
            />
          </Grid>

          <Grid size={{ xs: 12, md: 6 }}>
            <TextField
              fullWidth
              label="Phone"
              value={phone}
              onChange={(e) => setPhone(e.target.value)}
              placeholder="+1 (555) 123-4567"
              InputProps={{
                startAdornment: (
                  <InputAdornment position="start">
                    <Phone sx={{ color: 'text.secondary' }} />
                  </InputAdornment>
                ),
              }}
            />
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

          <Grid size={{ xs: 12, md: 6 }}>
            <TextField
              fullWidth
              label="Payment Terms (Days)"
              type="number"
              value={paymentTermsDays}
              onChange={(e) => setPaymentTermsDays(parseInt(e.target.value) || 0)}
              InputProps={{
                endAdornment: <InputAdornment position="end">days</InputAdornment>,
                inputProps: { min: 0, max: 365 },
              }}
            />
          </Grid>

          <Grid size={{ xs: 12, md: 6 }}>
            <TextField
              fullWidth
              label="Tax ID / GST / VAT Number"
              value={taxIdentifier}
              onChange={(e) => setTaxIdentifier(e.target.value)}
              placeholder="Tax identification number"
            />
          </Grid>

          {editSupplier && (
            <Grid size={12}>
              <Box>
                <Typography variant="subtitle2" gutterBottom>
                  Supplier Rating
                </Typography>
                <Rating
                  value={rating}
                  onChange={(_, newValue) => setRating(newValue)}
                  size="large"
                />
              </Box>
            </Grid>
          )}
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
          {editSupplier ? 'Update' : 'Add Supplier'}
        </Button>
      </DialogActions>
    </Dialog>
  );
};

// ─── Main Component ─────────────────────────────────────────

const SuppliersPage: React.FC = () => {
  const theme = useTheme();
  const toast = useToast();

  const [suppliers, setSuppliers] = useState<SupplierDto[]>([]);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const [showInactive, setShowInactive] = useState(false);
  const [viewMode, setViewMode] = useState<'cards' | 'table'>('cards');

  // Dialogs
  const [formOpen, setFormOpen] = useState(false);
  const [editSupplier, setEditSupplier] = useState<SupplierDto | null>(null);
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [supplierToDelete, setSupplierToDelete] = useState<SupplierDto | null>(null);

  // ─── Data Loading ───────────────────────────────────────

  const loadData = useCallback(async () => {
    try {
      setLoading(true);
      const data = await searchSuppliers({
        Query: searchQuery || undefined,
        IsActive: showInactive ? undefined : true,
      });
      setSuppliers(data.items || data);
    } catch (err) {
      toast.error('Failed to load suppliers');
      console.error(err);
    } finally {
      setLoading(false);
    }
  }, [toast, searchQuery, showInactive]);

  useEffect(() => {
    loadData();
  }, [loadData]);

  // ─── Handlers ───────────────────────────────────────────

  const handleAdd = () => {
    setEditSupplier(null);
    setFormOpen(true);
  };

  const handleEdit = (supplier: SupplierDto) => {
    setEditSupplier(supplier);
    setFormOpen(true);
  };

  const handleSave = async (data: CreateSupplierRequest | UpdateSupplierRequest, id?: string) => {
    try {
      setSaving(true);
      if (id) {
        await updateSupplier(id, data as UpdateSupplierRequest);
        toast.success('Supplier updated successfully');
      } else {
        await createSupplier(data as CreateSupplierRequest);
        toast.success('Supplier added successfully');
      }
      setFormOpen(false);
      loadData();
    } catch (err: any) {
      toast.error(err?.response?.data?.message || 'Failed to save supplier');
    } finally {
      setSaving(false);
    }
  };

  const handleDeactivate = async () => {
    if (!supplierToDelete) return;
    try {
      setSaving(true);
      await deactivateSupplier(supplierToDelete.id);
      toast.success('Supplier deactivated');
      setDeleteDialogOpen(false);
      setSupplierToDelete(null);
      loadData();
    } catch (err) {
      toast.error('Failed to deactivate supplier');
    } finally {
      setSaving(false);
    }
  };

  // ─── Render ─────────────────────────────────────────────

  return (
    <Box p={3}>
      {/* Header */}
      <Stack direction="row" justifyContent="space-between" alignItems="center" mb={3}>
        <Box>
          <Typography variant="h4" fontWeight={700}>
            Suppliers
          </Typography>
          <Typography variant="body2" color="text.secondary">
            Manage your vendors and suppliers
          </Typography>
        </Box>
        <Stack direction="row" spacing={1}>
          <Button startIcon={<Refresh />} onClick={loadData} variant="outlined">
            Refresh
          </Button>
          <Button startIcon={<Add />} variant="contained" onClick={handleAdd}>
            Add Supplier
          </Button>
        </Stack>
      </Stack>

      {/* Filters */}
      <Paper sx={{ p: 2, mb: 3 }}>
        <Stack direction={{ xs: 'column', md: 'row' }} spacing={2} alignItems="center">
          <TextField
            size="small"
            placeholder="Search suppliers..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            InputProps={{
              startAdornment: (
                <InputAdornment position="start">
                  <Search />
                </InputAdornment>
              ),
            }}
            sx={{ minWidth: 300 }}
          />
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
        </Stack>
      </Paper>

      {/* Loading */}
      {loading ? (
        <Box display="flex" justifyContent="center" alignItems="center" minHeight={300}>
          <CircularProgress />
        </Box>
      ) : suppliers.length === 0 ? (
        <Alert severity="info">
          <Typography fontWeight={600}>No suppliers found</Typography>
          <Typography variant="body2">
            {searchQuery ? 'Try adjusting your search criteria.' : 'Add your first supplier to get started.'}
          </Typography>
        </Alert>
      ) : (
        <Grid container spacing={3}>
          {suppliers.map((supplier) => (
            <Grid key={supplier.id} size={{ xs: 12, md: 6, lg: 4 }}>
              <SupplierCard
                supplier={supplier}
                onEdit={() => handleEdit(supplier)}
                onDeactivate={() => {
                  setSupplierToDelete(supplier);
                  setDeleteDialogOpen(true);
                }}
              />
            </Grid>
          ))}
        </Grid>
      )}

      {/* Form Dialog */}
      <SupplierFormDialog
        open={formOpen}
        onClose={() => setFormOpen(false)}
        onSave={handleSave}
        editSupplier={editSupplier}
        loading={saving}
      />

      {/* Deactivate Confirmation */}
      <Dialog open={deleteDialogOpen} onClose={() => setDeleteDialogOpen(false)} maxWidth="xs" fullWidth>
        <DialogTitle>Deactivate Supplier</DialogTitle>
        <DialogContent>
          <Alert severity="warning" sx={{ mb: 2 }}>
            This supplier will be deactivated. Existing purchase history will be preserved.
          </Alert>
          <Typography>
            Are you sure you want to deactivate <strong>{supplierToDelete?.name}</strong>?
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

export default SuppliersPage;
