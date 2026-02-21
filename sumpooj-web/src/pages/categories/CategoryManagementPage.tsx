/**
 * CategoryManagementPage — CRUD for Product Categories
 *
 * Features:
 *   - Table with name, perishable badge, batch-tracking badge, product count
 *   - Inline Add / Edit dialog
 *   - Soft-delete (deactivate) with guard when products are assigned
 *   - Re-activate toggle
 */

import React, { useState, useEffect, useCallback } from 'react';
import {
  Box,
  Typography,
  Card,
  CardContent,
  Button,
  IconButton,
  Tooltip,
  Chip,
  Stack,
  Table,
  TableHead,
  TableBody,
  TableRow,
  TableCell,
  TableContainer,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  FormControlLabel,
  Switch,
  Alert,
  Snackbar,
  CircularProgress,
  Paper,
  useTheme,
} from '@mui/material';
import AddIcon from '@mui/icons-material/Add';
import EditIcon from '@mui/icons-material/Edit';
import DeleteIcon from '@mui/icons-material/Delete';
import RestoreIcon from '@mui/icons-material/Restore';
import AcUnitIcon from '@mui/icons-material/AcUnit';
import CategoryIcon from '@mui/icons-material/Category';

import type { ProductCategoryDto, CreateProductCategoryRequest, UpdateProductCategoryRequest } from '../../api/category.api';
import {
  getCategories,
  createCategory,
  updateCategory,
  deactivateCategory,
  activateCategory,
} from '../../api/category.api';

// ─── Types ──────────────────────────────────────────────────

interface FormState {
  name: string;
  isPerishable: boolean;
  trackBatchByDefault: boolean;
}

const emptyForm: FormState = {
  name: '',
  isPerishable: false,
  trackBatchByDefault: false,
};

// ─── Component ──────────────────────────────────────────────

const CategoryManagementPage: React.FC = () => {
  const theme = useTheme();

  // Data
  const [categories, setCategories] = useState<ProductCategoryDto[]>([]);
  const [loading, setLoading] = useState(true);
  const [showInactive, setShowInactive] = useState(false);

  // Dialog
  const [dialogOpen, setDialogOpen] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [form, setForm] = useState<FormState>(emptyForm);
  const [saving, setSaving] = useState(false);
  const [formError, setFormError] = useState<string | null>(null);

  // Notification
  const [notification, setNotification] = useState<{
    open: boolean;
    message: string;
    severity: 'success' | 'error';
  }>({ open: false, message: '', severity: 'success' });

  // ─── Data Loading ───────────────────────────────────────

  const loadCategories = useCallback(async () => {
    setLoading(true);
    try {
      const data = await getCategories(showInactive);
      setCategories(data);
    } catch (err) {
      console.error('Failed to load categories', err);
      setNotification({ open: true, message: 'Failed to load categories', severity: 'error' });
    } finally {
      setLoading(false);
    }
  }, [showInactive]);

  useEffect(() => {
    loadCategories();
  }, [loadCategories]);

  // ─── Dialog Handlers ───────────────────────────────────

  const openAddDialog = () => {
    setEditingId(null);
    setForm(emptyForm);
    setFormError(null);
    setDialogOpen(true);
  };

  const openEditDialog = (cat: ProductCategoryDto) => {
    setEditingId(cat.id);
    setForm({
      name: cat.name,
      isPerishable: cat.isPerishable,
      trackBatchByDefault: cat.trackBatchByDefault,
    });
    setFormError(null);
    setDialogOpen(true);
  };

  const handleDialogClose = () => {
    setDialogOpen(false);
    setEditingId(null);
    setForm(emptyForm);
    setFormError(null);
  };

  const handleSave = async () => {
    if (!form.name.trim()) {
      setFormError('Category name is required');
      return;
    }
    setSaving(true);
    setFormError(null);
    try {
      if (editingId) {
        const payload: UpdateProductCategoryRequest = {
          name: form.name.trim(),
          isPerishable: form.isPerishable,
          trackBatchByDefault: form.trackBatchByDefault,
        };
        await updateCategory(editingId, payload);
        setNotification({ open: true, message: 'Category updated', severity: 'success' });
      } else {
        const payload: CreateProductCategoryRequest = {
          name: form.name.trim(),
          isPerishable: form.isPerishable,
          trackBatchByDefault: form.trackBatchByDefault,
        };
        await createCategory(payload);
        setNotification({ open: true, message: 'Category created', severity: 'success' });
      }
      handleDialogClose();
      loadCategories();
    } catch (err: any) {
      const msg = err?.response?.data?.error || 'Failed to save category';
      setFormError(msg);
    } finally {
      setSaving(false);
    }
  };

  const handleDeactivate = async (cat: ProductCategoryDto) => {
    if (cat.productCount > 0) {
      setNotification({
        open: true,
        message: `Cannot deactivate "${cat.name}" — ${cat.productCount} product(s) assigned. Reassign them first.`,
        severity: 'error',
      });
      return;
    }
    try {
      await deactivateCategory(cat.id);
      setNotification({ open: true, message: `"${cat.name}" deactivated`, severity: 'success' });
      loadCategories();
    } catch (err: any) {
      const msg = err?.response?.data?.error || 'Failed to deactivate category';
      setNotification({ open: true, message: msg, severity: 'error' });
    }
  };

  const handleActivate = async (cat: ProductCategoryDto) => {
    try {
      await activateCategory(cat.id);
      setNotification({ open: true, message: `"${cat.name}" re-activated`, severity: 'success' });
      loadCategories();
    } catch {
      setNotification({ open: true, message: 'Failed to activate category', severity: 'error' });
    }
  };

  // ─── Render ─────────────────────────────────────────────

  return (
    <Box sx={{ p: { xs: 2, md: 4 }, maxWidth: 960, mx: 'auto' }}>
      {/* Header */}
      <Stack direction="row" justifyContent="space-between" alignItems="center" mb={3}>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
          <Box
            sx={{
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              width: 44,
              height: 44,
              borderRadius: 2,
              background: 'linear-gradient(135deg, #00bcd4 0%, #0097a7 100%)',
            }}
          >
            <CategoryIcon sx={{ color: 'white', fontSize: 24 }} />
          </Box>
          <Box>
            <Typography variant="h5" fontWeight={700}>
              Product Categories
            </Typography>
            <Typography variant="body2" color="text.secondary">
              Manage dynamic categories for your products
            </Typography>
          </Box>
        </Box>

        <Button variant="contained" startIcon={<AddIcon />} onClick={openAddDialog}>
          Add Category
        </Button>
      </Stack>

      {/* Show Inactive Toggle */}
      <Stack direction="row" alignItems="center" mb={2}>
        <FormControlLabel
          control={
            <Switch
              checked={showInactive}
              onChange={(e) => setShowInactive(e.target.checked)}
              size="small"
            />
          }
          label={<Typography variant="body2">Show Inactive</Typography>}
        />
      </Stack>

      {/* Table */}
      <Card variant="outlined">
        <CardContent sx={{ p: 0 }}>
          {loading ? (
            <Box sx={{ display: 'flex', justifyContent: 'center', py: 6 }}>
              <CircularProgress />
            </Box>
          ) : categories.length === 0 ? (
            <Box sx={{ textAlign: 'center', py: 6 }}>
              <Typography color="text.secondary">
                No categories found. Create your first category to get started.
              </Typography>
            </Box>
          ) : (
            <TableContainer component={Paper} elevation={0}>
              <Table size="medium">
                <TableHead>
                  <TableRow>
                    <TableCell sx={{ fontWeight: 700 }}>Name</TableCell>
                    <TableCell sx={{ fontWeight: 700 }} align="center">Perishable</TableCell>
                    <TableCell sx={{ fontWeight: 700 }} align="center">Batch Tracking</TableCell>
                    <TableCell sx={{ fontWeight: 700 }} align="center">Products</TableCell>
                    <TableCell sx={{ fontWeight: 700 }} align="center">Status</TableCell>
                    <TableCell sx={{ fontWeight: 700 }} align="right">Actions</TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {categories.map((cat) => (
                    <TableRow
                      key={cat.id}
                      sx={{
                        opacity: cat.isActive ? 1 : 0.5,
                        '&:hover': { bgcolor: theme.palette.action.hover },
                      }}
                    >
                      <TableCell>
                        <Typography variant="body2" fontWeight={600}>
                          {cat.name}
                        </Typography>
                      </TableCell>
                      <TableCell align="center">
                        {cat.isPerishable ? (
                          <Chip
                            icon={<AcUnitIcon sx={{ fontSize: 14 }} />}
                            label="Yes"
                            size="small"
                            color="warning"
                            variant="outlined"
                            sx={{ height: 24 }}
                          />
                        ) : (
                          <Typography variant="body2" color="text.secondary">No</Typography>
                        )}
                      </TableCell>
                      <TableCell align="center">
                        {cat.trackBatchByDefault ? (
                          <Chip label="Yes" size="small" color="info" variant="outlined" sx={{ height: 24 }} />
                        ) : (
                          <Typography variant="body2" color="text.secondary">No</Typography>
                        )}
                      </TableCell>
                      <TableCell align="center">
                        <Chip label={cat.productCount} size="small" variant="filled" sx={{ height: 24 }} />
                      </TableCell>
                      <TableCell align="center">
                        <Chip
                          label={cat.isActive ? 'Active' : 'Inactive'}
                          size="small"
                          color={cat.isActive ? 'success' : 'default'}
                          sx={{ height: 24 }}
                        />
                      </TableCell>
                      <TableCell align="right">
                        <Tooltip title="Edit">
                          <IconButton size="small" onClick={() => openEditDialog(cat)}>
                            <EditIcon fontSize="small" />
                          </IconButton>
                        </Tooltip>
                        {cat.isActive ? (
                          <Tooltip title="Deactivate">
                            <IconButton
                              size="small"
                              color="error"
                              onClick={() => handleDeactivate(cat)}
                            >
                              <DeleteIcon fontSize="small" />
                            </IconButton>
                          </Tooltip>
                        ) : (
                          <Tooltip title="Re-activate">
                            <IconButton
                              size="small"
                              color="success"
                              onClick={() => handleActivate(cat)}
                            >
                              <RestoreIcon fontSize="small" />
                            </IconButton>
                          </Tooltip>
                        )}
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </TableContainer>
          )}
        </CardContent>
      </Card>

      {/* ─── Add / Edit Dialog ──────────────────────────── */}
      <Dialog open={dialogOpen} onClose={handleDialogClose} maxWidth="xs" fullWidth>
        <DialogTitle>{editingId ? 'Edit Category' : 'Add Category'}</DialogTitle>
        <DialogContent>
          <Stack spacing={2.5} sx={{ mt: 1 }}>
            <TextField
              label="Category Name"
              value={form.name}
              onChange={(e) => setForm((f) => ({ ...f, name: e.target.value }))}
              required
              fullWidth
              autoFocus
              placeholder="e.g., Fresh Flower"
            />
            <FormControlLabel
              control={
                <Switch
                  checked={form.isPerishable}
                  onChange={(e) => setForm((f) => ({ ...f, isPerishable: e.target.checked }))}
                />
              }
              label="Perishable"
            />
            <FormControlLabel
              control={
                <Switch
                  checked={form.trackBatchByDefault}
                  onChange={(e) => setForm((f) => ({ ...f, trackBatchByDefault: e.target.checked }))}
                />
              }
              label="Track Batch by Default"
            />
            {formError && <Alert severity="error">{formError}</Alert>}
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={handleDialogClose} disabled={saving}>
            Cancel
          </Button>
          <Button
            variant="contained"
            onClick={handleSave}
            disabled={saving || !form.name.trim()}
            startIcon={saving ? <CircularProgress size={16} /> : undefined}
          >
            {editingId ? 'Update' : 'Create'}
          </Button>
        </DialogActions>
      </Dialog>

      {/* Notification */}
      <Snackbar
        open={notification.open}
        autoHideDuration={4000}
        onClose={() => setNotification((n) => ({ ...n, open: false }))}
        anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }}
      >
        <Alert
          severity={notification.severity}
          variant="filled"
          onClose={() => setNotification((n) => ({ ...n, open: false }))}
        >
          {notification.message}
        </Alert>
      </Snackbar>
    </Box>
  );
};

export default CategoryManagementPage;
