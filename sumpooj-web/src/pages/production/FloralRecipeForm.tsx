/**
 * FloralRecipeForm.tsx — Add/Edit Floral Recipe (BOM)
 *
 * Features:
 * - Component selector from available inventory
 * - Image URL uploader
 * - Live cost preview
 * - Validation
 */

import { useState, useEffect, useMemo } from 'react';
import {
  Box, Container, Typography, TextField, Button, Card, CardContent,
  Table, TableHead, TableBody, TableRow, TableCell, IconButton, Tooltip,
  Select, MenuItem, FormControl, InputLabel, Switch, FormControlLabel,
  Paper, useTheme, alpha, Alert, Grid, Divider, Chip,
} from '@mui/material';
import {
  Add as AddIcon,
  Delete as DeleteIcon,
  ArrowBack as BackIcon,
  Save as SaveIcon,
  LocalFlorist as FloristIcon,
} from '@mui/icons-material';
import ImageUploader from '../../components/ImageUploader';
import { useNavigate, useParams } from 'react-router-dom';
import type { RecipeComponent, InventoryProduct } from './types/ProductionTypes';
import { RECIPE_CATEGORIES } from './types/ProductionTypes';
import { getRecipeById, createRecipe, updateRecipe, getInventoryProducts } from './api/production.api';
import { calculateComponentCost, formatCurrency } from './utils/production.utils';
import { getCurrencySymbol } from '../../core/i18n';

interface ComponentRow extends RecipeComponent {
  _key: string; // for React key
}

const FloralRecipeForm = () => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';
  const navigate = useNavigate();
  const { id } = useParams<{ id: string }>();
  const isEdit = Boolean(id);

  // ── State ──────────────────────────────────────────────────
  const [name, setName] = useState('');
  const [category, setCategory] = useState<string>('');
  const [sellingPrice, setSellingPrice] = useState<number>(0);
  const [laborCost, setLaborCost] = useState<number>(0);
  const [isActive, setIsActive] = useState(true);
  const [components, setComponents] = useState<ComponentRow[]>([]);
  const [imageUrls, setImageUrls] = useState<string[]>([]);
  const [inventoryProducts, setInventoryProducts] = useState<InventoryProduct[]>([]);
  const [_loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  // ── Load data ──────────────────────────────────────────────
  useEffect(() => {
    const load = async () => {
      setLoading(true);
      try {
        const products = await getInventoryProducts();
        setInventoryProducts(products);

        if (isEdit && id) {
          const recipe = await getRecipeById(id);
          if (recipe) {
            setName(recipe.name);
            setCategory(recipe.category ?? '');
            setSellingPrice(recipe.sellingPrice);
            setLaborCost(recipe.laborCost ?? 0);
            setIsActive(recipe.isActive);
            setComponents(recipe.components.map((c, i) => ({ ...c, _key: `comp-${i}` })));
            setImageUrls(recipe.sampleImages ?? []);
          }
        }
      } catch {
        setError('Failed to load data');
      } finally {
        setLoading(false);
      }
    };
    load();
  }, [id, isEdit]);

  // ── Component management ───────────────────────────────────
  const addComponent = () => {
    setComponents((prev) => [
      ...prev,
      { _key: `comp-${Date.now()}`, productId: '', productName: '', quantityRequired: 1, unitCost: 0 },
    ]);
  };

  const updateComponent = (key: string, field: keyof ComponentRow, value: string | number) => {
    setComponents((prev) =>
      prev.map((c) => {
        if (c._key !== key) return c;
        if (field === 'productId') {
          const product = inventoryProducts.find((p) => p.id === value);
          return {
            ...c,
            productId: value as string,
            productName: product?.name ?? '',
            unitCost: product?.unitCost ?? 0,
          };
        }
        return { ...c, [field]: value };
      }),
    );
  };

  const removeComponent = (key: string) => {
    setComponents((prev) => prev.filter((c) => c._key !== key));
  };

  // ── Cost calculations ──────────────────────────────────────
  const materialCost = useMemo(() => calculateComponentCost(components), [components]);
  const totalCost = materialCost + laborCost;
  const margin = sellingPrice > 0 ? ((sellingPrice - totalCost) / sellingPrice) * 100 : 0;

  // ── Validation ─────────────────────────────────────────────
  const isValid = useMemo(() => {
    if (!name.trim()) return false;
    if (sellingPrice <= 0) return false;
    if (components.length === 0) return false;
    if (components.some((c) => !c.productId || c.quantityRequired <= 0)) return false;
    return true;
  }, [name, sellingPrice, components]);

  // ── Submit ─────────────────────────────────────────────────
  const handleSubmit = async () => {
    if (!isValid) return;
    setSaving(true);
    setError('');
    setSuccess('');

    try {
      const recipeData = {
        tenantId: '', // resolved by backend
        name: name.trim(),
        category: category || undefined,
        sellingPrice,
        laborCost: laborCost || undefined,
        components: components.map(({ _key, ...rest }) => rest),
        sampleImages: imageUrls.length > 0 ? imageUrls : undefined,
        isActive,
      };

      if (isEdit && id) {
        await updateRecipe(id, recipeData);
        setSuccess('Recipe updated successfully!');
      } else {
        await createRecipe(recipeData);
        setSuccess('Recipe created successfully!');
        setTimeout(() => navigate('/production/recipes'), 1200);
      }
    } catch {
      setError('Failed to save recipe. Please try again.');
    } finally {
      setSaving(false);
    }
  };

  // ── Available products (exclude already selected) ──────────
  const availableProducts = useMemo(() => {
    const selectedIds = new Set(components.map((c) => c.productId));
    return inventoryProducts.filter((p) => !selectedIds.has(p.id));
  }, [inventoryProducts, components]);

  return (
    <Box sx={{ minHeight: '100vh', pb: 6 }}>
      <Container maxWidth="lg" sx={{ pt: 3 }}>
        {/* ── Header ────────────────────────────────────── */}
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 3 }}>
          <Tooltip title="Back to recipes">
            <IconButton onClick={() => navigate('/production/recipes')}>
              <BackIcon />
            </IconButton>
          </Tooltip>
          <FloristIcon sx={{ fontSize: 28, color: '#e91e63' }} />
          <Box>
            <Typography variant="h5" fontWeight={700}>
              {isEdit ? 'Edit Recipe' : 'New Floral Recipe'}
            </Typography>
            <Typography variant="body2" color="text.secondary">
              Define the Bill of Materials for your flower arrangement
            </Typography>
          </Box>
        </Box>

        {error && <Alert severity="error" sx={{ mb: 2, borderRadius: 2 }}>{error}</Alert>}
        {success && <Alert severity="success" sx={{ mb: 2, borderRadius: 2 }}>{success}</Alert>}

        <Grid container spacing={3}>
          {/* ── Left: Form ──────────────────────────────── */}
          <Grid size={{ xs: 12, md: 8 }}>
            {/* Basic Info */}
            <Card elevation={0} sx={{ mb: 3, borderRadius: 2, border: `1px solid ${dk ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.08)'}` }}>
              <CardContent sx={{ p: 3 }}>
                <Typography variant="subtitle1" fontWeight={700} gutterBottom>Basic Information</Typography>
                <Grid container spacing={2}>
                  <Grid size={{ xs: 12, sm: 8 }}>
                    <TextField
                      label="Recipe Name"
                      value={name}
                      onChange={(e) => setName(e.target.value)}
                      fullWidth
                      required
                      placeholder="e.g. Classic Red Rose Bouquet"
                    />
                  </Grid>
                  <Grid size={{ xs: 12, sm: 4 }}>
                    <FormControl fullWidth>
                      <InputLabel>Category</InputLabel>
                      <Select value={category} label="Category" onChange={(e) => setCategory(e.target.value)}>
                        <MenuItem value="">None</MenuItem>
                        {RECIPE_CATEGORIES.map((c) => (
                          <MenuItem key={c} value={c}>{c}</MenuItem>
                        ))}
                      </Select>
                    </FormControl>
                  </Grid>
                  <Grid size={{ xs: 12, sm: 4 }}>
                    <TextField
                      label={`Selling Price (${getCurrencySymbol()})`}
                      type="number"
                      value={sellingPrice || ''}
                      onChange={(e) => setSellingPrice(Number(e.target.value))}
                      fullWidth
                      required
                      inputProps={{ min: 0 }}
                    />
                  </Grid>
                  <Grid size={{ xs: 12, sm: 4 }}>
                    <TextField
                      label={`Labor Cost (${getCurrencySymbol()})`}
                      type="number"
                      value={laborCost || ''}
                      onChange={(e) => setLaborCost(Number(e.target.value))}
                      fullWidth
                      inputProps={{ min: 0 }}
                      helperText="Optional"
                    />
                  </Grid>
                  <Grid size={{ xs: 12, sm: 4 }}>
                    <FormControlLabel
                      control={<Switch checked={isActive} onChange={(e) => setIsActive(e.target.checked)} />}
                      label="Active"
                      sx={{ mt: 1 }}
                    />
                  </Grid>
                </Grid>
              </CardContent>
            </Card>

            {/* Components */}
            <Card elevation={0} sx={{ mb: 3, borderRadius: 2, border: `1px solid ${dk ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.08)'}` }}>
              <CardContent sx={{ p: 3 }}>
                <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', mb: 2 }}>
                  <Typography variant="subtitle1" fontWeight={700}>
                    Components ({components.length})
                  </Typography>
                  <Button size="small" startIcon={<AddIcon />} onClick={addComponent} sx={{ textTransform: 'none' }}>
                    Add Component
                  </Button>
                </Box>

                {components.length === 0 ? (
                  <Paper
                    sx={{
                      p: 4,
                      textAlign: 'center',
                      borderRadius: 2,
                      bgcolor: dk ? 'rgba(255,255,255,0.03)' : 'rgba(0,0,0,0.02)',
                      border: `2px dashed ${dk ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.1)'}`,
                    }}
                  >
                    <FloristIcon sx={{ fontSize: 40, color: 'text.disabled', mb: 1 }} />
                    <Typography color="text.secondary">No components added yet. Click "Add Component" to start building.</Typography>
                  </Paper>
                ) : (
                  <Table size="small">
                    <TableHead>
                      <TableRow sx={{ '& th': { fontWeight: 700, fontSize: '0.8rem' } }}>
                        <TableCell>Material</TableCell>
                        <TableCell sx={{ width: 100 }}>Qty</TableCell>
                        <TableCell align="right">Unit Cost</TableCell>
                        <TableCell align="right">Subtotal</TableCell>
                        <TableCell sx={{ width: 50 }} />
                      </TableRow>
                    </TableHead>
                    <TableBody>
                      {components.map((comp) => (
                        <TableRow key={comp._key}>
                          <TableCell>
                            <FormControl fullWidth size="small">
                              <Select
                                value={comp.productId}
                                onChange={(e) => updateComponent(comp._key, 'productId', e.target.value)}
                                displayEmpty
                              >
                                <MenuItem value="" disabled>Select material...</MenuItem>
                                {/* Show selected product + available */}
                                {comp.productId && (
                                  <MenuItem value={comp.productId}>
                                    {comp.productName} ({inventoryProducts.find((p) => p.id === comp.productId)?.quantityAvailable ?? 0} avail.)
                                  </MenuItem>
                                )}
                                {availableProducts.map((p) => (
                                  <MenuItem key={p.id} value={p.id}>
                                    {p.name} ({p.quantityAvailable} avail.)
                                  </MenuItem>
                                ))}
                              </Select>
                            </FormControl>
                          </TableCell>
                          <TableCell>
                            <TextField
                              type="number"
                              size="small"
                              value={comp.quantityRequired}
                              onChange={(e) => updateComponent(comp._key, 'quantityRequired', Number(e.target.value))}
                              inputProps={{ min: 0.1, step: 0.5 }}
                              sx={{ width: 80 }}
                            />
                          </TableCell>
                          <TableCell align="right">
                            <Typography variant="body2">{formatCurrency(comp.unitCost)}</Typography>
                          </TableCell>
                          <TableCell align="right">
                            <Typography variant="body2" fontWeight={600}>
                              {formatCurrency(comp.unitCost * comp.quantityRequired)}
                            </Typography>
                          </TableCell>
                          <TableCell>
                            <IconButton size="small" color="error" onClick={() => removeComponent(comp._key)}>
                              <DeleteIcon fontSize="small" />
                            </IconButton>
                          </TableCell>
                        </TableRow>
                      ))}
                    </TableBody>
                  </Table>
                )}
              </CardContent>
            </Card>

            {/* Images */}
            <Card elevation={0} sx={{ mb: 3, borderRadius: 2, border: `1px solid ${dk ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.08)'}` }}>
              <CardContent sx={{ p: 3 }}>
                <Typography variant="subtitle1" fontWeight={700} gutterBottom>Sample Images</Typography>
                <ImageUploader
                  images={imageUrls}
                  onChange={setImageUrls}
                  maxImages={8}
                  disabled={saving}
                />
              </CardContent>
            </Card>
          </Grid>

          {/* ── Right: Cost Preview ─────────────────────── */}
          <Grid size={{ xs: 12, md: 4 }}>
            <Card
              elevation={0}
              sx={{
                borderRadius: 2,
                border: `1px solid ${dk ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.08)'}`,
                position: 'sticky',
                top: 80,
              }}
            >
              <CardContent sx={{ p: 3 }}>
                <Typography variant="subtitle1" fontWeight={700} gutterBottom>Cost Preview</Typography>
                <Divider sx={{ mb: 2 }} />

                <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
                  <Typography variant="body2" color="text.secondary">Material Cost</Typography>
                  <Typography fontWeight={600}>{formatCurrency(materialCost)}</Typography>
                </Box>
                <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
                  <Typography variant="body2" color="text.secondary">Labor Cost</Typography>
                  <Typography fontWeight={600}>{formatCurrency(laborCost)}</Typography>
                </Box>
                <Divider sx={{ my: 1.5 }} />
                <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
                  <Typography fontWeight={700}>Total Cost</Typography>
                  <Typography fontWeight={700} color="error">{formatCurrency(totalCost)}</Typography>
                </Box>
                <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
                  <Typography fontWeight={700}>Selling Price</Typography>
                  <Typography fontWeight={700} color="primary">{formatCurrency(sellingPrice)}</Typography>
                </Box>
                <Divider sx={{ my: 1.5 }} />
                <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 2 }}>
                  <Typography fontWeight={700}>Profit Margin</Typography>
                  <Chip
                    label={`${margin.toFixed(1)}%`}
                    size="small"
                    sx={{
                      fontWeight: 700,
                      bgcolor: alpha(margin > 30 ? '#4caf50' : margin > 15 ? '#ff9800' : '#f44336', 0.12),
                      color: margin > 30 ? '#4caf50' : margin > 15 ? '#ff9800' : '#f44336',
                    }}
                  />
                </Box>

                {margin < 0 && (
                  <Alert severity="warning" sx={{ mb: 2, borderRadius: 1.5 }}>
                    Selling price is below cost. You'll lose money on each sale.
                  </Alert>
                )}

                <Button
                  variant="contained"
                  fullWidth
                  size="large"
                  startIcon={<SaveIcon />}
                  onClick={handleSubmit}
                  disabled={!isValid || saving}
                  sx={{
                    bgcolor: '#e91e63',
                    '&:hover': { bgcolor: '#c2185b' },
                    borderRadius: 2,
                    textTransform: 'none',
                    fontWeight: 600,
                    py: 1.5,
                  }}
                >
                  {saving ? 'Saving...' : isEdit ? 'Update Recipe' : 'Create Recipe'}
                </Button>
              </CardContent>
            </Card>
          </Grid>
        </Grid>
      </Container>
    </Box>
  );
};

export default FloralRecipeForm;
