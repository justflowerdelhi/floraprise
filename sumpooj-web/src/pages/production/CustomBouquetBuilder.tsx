import { usePOS } from '../pos/POSContext';
import { generateBouquetName } from '../../utils/bouquetNameGenerator';
/**
 * CustomBouquetBuilder.tsx — Custom Bouquet Builder Screen
 *
 * Features:
 * - Select components manually from inventory
 * - Enter quantities and selling price
 * - Optional labor cost and image
 * - "Create & Sell Now" (on-demand mode)
 * - "Save as Recipe"
 * - Live cost preview
 */

import { useState, useEffect, useMemo } from 'react';
import {
  Box, Container, Typography, TextField, Button, Card, CardContent,
  Table, TableHead, TableBody, TableRow, TableCell, IconButton, Tooltip,
  FormControl, InputLabel, Select, MenuItem, Paper, useTheme, alpha,
  Grid, Divider, Alert, Chip, Dialog, DialogTitle, DialogContent,
  DialogActions, CircularProgress,
} from '@mui/material';
import {
  Add as AddIcon,
  Delete as DeleteIcon,
  ShoppingCart as SellIcon,
  Save as SaveIcon,
  Palette as BuilderIcon,
  LocalFlorist as FloristIcon,
  ArrowBack as BackIcon,
} from '@mui/icons-material';
import ImageUploader from '../../components/ImageUploader';
import { useNavigate } from 'react-router-dom';
import type { InventoryProduct, CustomBouquetComponent } from './types/ProductionTypes';
import { RECIPE_CATEGORIES } from './types/ProductionTypes';
import { getInventoryProducts, createCustomBouquetAndSell, saveCustomBouquetAsRecipe } from './api/production.api';
import { formatCurrency } from './utils/production.utils';
import { getCurrencySymbol } from '../../core/i18n';
import { useLocation } from '../../core/location/LocationContext';

interface ComponentRow extends CustomBouquetComponent {
  _key: string;
}

const CustomBouquetBuilder = () => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';
  const navigate = useNavigate();
  const { addProduct } = usePOS();
  const { currentLocationId } = useLocation();

  // ── State ──────────────────────────────────────────────────
  const [inventoryProducts, setInventoryProducts] = useState<InventoryProduct[]>([]);
  const [components, setComponents] = useState<ComponentRow[]>([]);
  const [sellingPrice, setSellingPrice] = useState<number>(0);
  const [laborCost, setLaborCost] = useState<number>(0);
  const [imageUrls, setImageUrls] = useState<string[]>([]);
  const [_loading, setLoading] = useState(true);
  const [processing, setProcessing] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  // Save as recipe dialog
  const [saveDialogOpen, setSaveDialogOpen] = useState(false);
  const [recipeName, setRecipeName] = useState('');
  const [recipeCategory, setRecipeCategory] = useState<string>('');

  // ── Load inventory ─────────────────────────────────────────
  useEffect(() => {
    const load = async () => {
      setLoading(true);
      try {
        const data = await getInventoryProducts();
        setInventoryProducts(data);
      } catch {
        setError('Failed to load inventory');
      } finally {
        setLoading(false);
      }
    };
    load();
  }, []);

  // ── Component management ───────────────────────────────────
  const addComponent = () => {
    setComponents((prev) => [
      ...prev,
      { _key: `comp-${Date.now()}`, productId: '', productName: '', quantity: 1, unitCost: 0 },
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

  // ── Calculations ───────────────────────────────────────────
  const materialCost = useMemo(
    () => components.reduce((sum, c) => sum + c.unitCost * c.quantity, 0),
    [components],
  );
  const totalCost = materialCost + laborCost;
  const margin = sellingPrice > 0 ? ((sellingPrice - totalCost) / sellingPrice) * 100 : 0;

  const availableProducts = useMemo(() => {
    const selectedIds = new Set(components.map((c) => c.productId));
    return inventoryProducts.filter((p) => !selectedIds.has(p.id));
  }, [inventoryProducts, components]);

  // ── Validation ─────────────────────────────────────────────
  const isValid = useMemo(() => {
    if (components.length === 0) return false;
    if (components.some((c) => !c.productId || c.quantity <= 0)) return false;
    if (sellingPrice <= 0) return false;
    return true;
  }, [components, sellingPrice]);

  // ── Create & Sell Now ──────────────────────────────────────
  const handleSellNow = async () => {
    if (!isValid) return;

    if (!currentLocationId || currentLocationId === 'ALL') {
      setError('Select a specific location before creating and selling a custom bouquet.');
      return;
    }

    setProcessing(true);
    setError('');

    try {
      const bouquetName = generateBouquetName(
        components.map(c => ({ productName: c.productName, quantity: c.quantity })),
      );

      const created = await createCustomBouquetAndSell({
        name: bouquetName,
        category: 'Custom',
        components: components.map(({ _key, ...rest }) => rest),
        sellingPrice,
        laborCost: laborCost || undefined,
        image: imageUrls[0] || undefined,
        locationId: currentLocationId,
      });

      addProduct({
        id: created.id,
        name: created.name,
        sku: created.batchCode,
        barcode: created.barcode,
        finishedBarcode: created.barcode,
        category: 'Bouquets',
        sellingPrice: Number(created.retailPrice),
        costPrice: Number(created.costPrice),
        taxRate: 0,
        availableStock: Number(created.stockQuantity ?? 1),
        isPerishable: true,
        trackBatch: false,
        imageUrl: imageUrls?.[0] ?? undefined,
        batches: [],
      } as any, 1);

      navigate("/pos");

    } catch (err) {
      console.error(err);
      setError("Failed to create bouquet.");
    } finally {
      setProcessing(false);
    }
  };

  // ── Save as Recipe ─────────────────────────────────────────
  const handleSaveAsRecipe = async () => {
    if (!recipeName.trim()) return;
    setProcessing(true);
    setError('');
    try {
      await saveCustomBouquetAsRecipe({
        name: recipeName.trim(),
        category: recipeCategory || undefined,
        components: components.map(({ _key, ...rest }) => rest),
        sellingPrice,
        laborCost: laborCost || undefined,
        image: imageUrls[0] || undefined,
      });
      setSuccess(`Recipe "${recipeName}" saved successfully!`);
      setSaveDialogOpen(false);
      setRecipeName('');
      setRecipeCategory('');
    } catch {
      setError('Failed to save recipe.');
    } finally {
      setProcessing(false);
    }
  };

  return (
    <Box sx={{ minHeight: '100vh', pb: 6 }}>
      <Container maxWidth="lg" sx={{ pt: 3 }}>
        {/* ── Header ────────────────────────────────────── */}
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 3 }}>
          <Tooltip title="Back">
            <IconButton onClick={() => navigate('/production/recipes')}>
              <BackIcon />
            </IconButton>
          </Tooltip>
          <BuilderIcon sx={{ fontSize: 32, color: '#9c27b0' }} />
          <Box>
            <Typography variant="h5" fontWeight={700}>Custom Bouquet Builder</Typography>
            <Typography variant="body2" color="text.secondary">
              Build a custom arrangement from available inventory
            </Typography>
          </Box>
        </Box>

        {error && <Alert severity="error" sx={{ mb: 2, borderRadius: 2 }} onClose={() => setError('')}>{error}</Alert>}
        {error && inventoryProducts.length === 0 && (
          <Alert severity="warning" sx={{ mb: 2 }}>
            Using temporary mock inventory.
          </Alert>
        )}
        {success && <Alert severity="success" sx={{ mb: 2, borderRadius: 2 }} onClose={() => setSuccess('')}>{success}</Alert>}

        <Grid container spacing={3}>
          {/* ── Left: Builder Form ──────────────────────── */}
          <Grid size={{ xs: 12, md: 8 }}>
            {/* Components */}
            <Card elevation={0} sx={{ mb: 3, borderRadius: 2, border: `1px solid ${dk ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.08)'}` }}>
              <CardContent sx={{ p: 3 }}>
                <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', mb: 2 }}>
                  <Typography variant="subtitle1" fontWeight={700}>
                    Select Components ({components.length})
                  </Typography>
                  <Button
                    size="small"
                    startIcon={<AddIcon />}
                    onClick={addComponent}
                    disabled={!!error && inventoryProducts.length === 0}
                    sx={{ textTransform: 'none' }}
                  >
                    Add Item
                  </Button>
                </Box>

                {components.length === 0 ? (
                  <Paper
                    sx={{
                      p: 4, textAlign: 'center', borderRadius: 2,
                      bgcolor: dk ? 'rgba(255,255,255,0.03)' : 'rgba(0,0,0,0.02)',
                      border: `2px dashed ${dk ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.1)'}`,
                    }}
                  >
                    <FloristIcon sx={{ fontSize: 40, color: 'text.disabled', mb: 1 }} />
                    <Typography color="text.secondary">Start by adding flowers and materials from inventory</Typography>
                  </Paper>
                ) : (
                  <Table size="small">
                    <TableHead>
                      <TableRow sx={{ '& th': { fontWeight: 700, fontSize: '0.8rem' } }}>
                        <TableCell>Item</TableCell>
                        <TableCell sx={{ width: 100 }}>Qty</TableCell>
                        <TableCell align="right">Available</TableCell>
                        <TableCell align="right">Unit Cost</TableCell>
                        <TableCell align="right">Subtotal</TableCell>
                        <TableCell sx={{ width: 50 }} />
                      </TableRow>
                    </TableHead>
                    <TableBody>
                      {components.map((comp) => {
                        const inv = inventoryProducts.find((p) => p.id === comp.productId);
                        return (
                          <TableRow key={comp._key}>
                            <TableCell>
                              <FormControl fullWidth size="small">
                                <Select
                                  value={comp.productId}
                                  onChange={(e) => updateComponent(comp._key, 'productId', e.target.value)}
                                  displayEmpty
                                >
                                  <MenuItem value="" disabled>Select item...</MenuItem>
                                  {comp.productId && (
                                    <MenuItem value={comp.productId}>{comp.productName}</MenuItem>
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
                                value={comp.quantity}
                                onChange={(e) => updateComponent(comp._key, 'quantity', Number(e.target.value))}
                                inputProps={{ min: 1, step: 1 }}
                                sx={{ width: 80 }}
                              />
                            </TableCell>
                            <TableCell align="right">
                              <Typography
                                variant="body2"
                                sx={{
                                  color: inv && comp.quantity > inv.quantityAvailable ? '#f44336' : 'text.secondary',
                                  fontWeight: inv && comp.quantity > inv.quantityAvailable ? 700 : 400,
                                }}
                              >
                                {inv?.quantityAvailable ?? '—'}
                              </Typography>
                            </TableCell>
                            <TableCell align="right">
                              <Typography variant="body2">{formatCurrency(comp.unitCost)}</Typography>
                            </TableCell>
                            <TableCell align="right">
                              <Typography variant="body2" fontWeight={600}>
                                {formatCurrency(comp.unitCost * comp.quantity)}
                              </Typography>
                            </TableCell>
                            <TableCell>
                              <IconButton size="small" color="error" onClick={() => removeComponent(comp._key)}>
                                <DeleteIcon fontSize="small" />
                              </IconButton>
                            </TableCell>
                          </TableRow>
                        );
                      })}
                    </TableBody>
                  </Table>
                )}
              </CardContent>
            </Card>

            {/* Pricing & Image */}
            <Card elevation={0} sx={{ mb: 3, borderRadius: 2, border: `1px solid ${dk ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.08)'}` }}>
              <CardContent sx={{ p: 3 }}>
                <Typography variant="subtitle1" fontWeight={700} gutterBottom>Pricing & Details</Typography>
                <Grid container spacing={2}>
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
                      helperText="Optional"
                      inputProps={{ min: 0 }}
                    />
                  </Grid>
                  <Grid size={{ xs: 12 }}>
                    <Typography variant="subtitle2" fontWeight={600} sx={{ mb: 1 }}>Photo (optional)</Typography>
                    <ImageUploader
                      images={imageUrls}
                      onChange={setImageUrls}
                      maxImages={4}
                      disabled={processing}
                    />
                  </Grid>
                </Grid>
              </CardContent>
            </Card>
          </Grid>

          {/* ── Right: Cost Preview & Actions ───────────── */}
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
                <Typography variant="subtitle1" fontWeight={700} gutterBottom>Cost Summary</Typography>
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
                <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 3 }}>
                  <Typography fontWeight={700}>Margin</Typography>
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

                {/* Action Buttons */}
                <Button
                  variant="contained"
                  fullWidth
                  size="large"
                  startIcon={processing ? <CircularProgress size={20} color="inherit" /> : <SellIcon />}
                  onClick={handleSellNow}
                  disabled={!isValid || processing}
                  sx={{
                    bgcolor: '#4caf50',
                    '&:hover': { bgcolor: '#388e3c' },
                    borderRadius: 2,
                    textTransform: 'none',
                    fontWeight: 600,
                    py: 1.5,
                    mb: 1.5,
                  }}
                >
                  Create & Sell Now
                </Button>
                <Button
                  variant="outlined"
                  fullWidth
                  size="large"
                  startIcon={<SaveIcon />}
                  onClick={() => setSaveDialogOpen(true)}
                  disabled={!isValid || processing}
                  sx={{
                    borderColor: '#9c27b0',
                    color: '#9c27b0',
                    '&:hover': { borderColor: '#7b1fa2', bgcolor: alpha('#9c27b0', 0.04) },
                    borderRadius: 2,
                    textTransform: 'none',
                    fontWeight: 600,
                    py: 1.5,
                  }}
                >
                  Save as Recipe
                </Button>

                <Typography variant="caption" color="text.secondary" sx={{ display: 'block', mt: 2, textAlign: 'center' }}>
                  "Create & Sell" deducts raw materials immediately (on-demand mode).
                  No finished goods batch is created.
                </Typography>
              </CardContent>
            </Card>
          </Grid>
        </Grid>

        {/* ── Save as Recipe Dialog ─────────────────────── */}
        <Dialog open={saveDialogOpen} onClose={() => setSaveDialogOpen(false)} maxWidth="sm" fullWidth>
          <DialogTitle>Save as Recipe</DialogTitle>
          <DialogContent>
            <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
              This will create a reusable floral recipe from your custom selection.
            </Typography>
            <TextField
              label="Recipe Name *"
              value={recipeName}
              onChange={(e) => setRecipeName(e.target.value)}
              fullWidth
              sx={{ mb: 2 }}
              placeholder="e.g. Summer Garden Mix"
            />
            <FormControl fullWidth>
              <InputLabel>Category</InputLabel>
              <Select value={recipeCategory} label="Category" onChange={(e) => setRecipeCategory(e.target.value)}>
                <MenuItem value="">None</MenuItem>
                {RECIPE_CATEGORIES.map((c) => (
                  <MenuItem key={c} value={c}>{c}</MenuItem>
                ))}
              </Select>
            </FormControl>
          </DialogContent>
          <DialogActions>
            <Button onClick={() => setSaveDialogOpen(false)}>Cancel</Button>
            <Button
              variant="contained"
              onClick={handleSaveAsRecipe}
              disabled={!recipeName.trim() || processing}
              sx={{ bgcolor: '#9c27b0', '&:hover': { bgcolor: '#7b1fa2' } }}
            >
              {processing ? 'Saving...' : 'Save Recipe'}
            </Button>
          </DialogActions>
        </Dialog>
      </Container>
    </Box>
  );
};

export default CustomBouquetBuilder;
