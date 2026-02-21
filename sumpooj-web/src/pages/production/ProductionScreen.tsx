/**
 * ProductionScreen.tsx — Pre-Produce Mode
 *
 * Features:
 * - Select recipe to produce
 * - Enter quantity and expected expiry
 * - Select production location
 * - Stock sufficiency check
 * - Cost preview
 * - Generate finished goods batch with barcode
 */

import { useState, useEffect, useMemo } from 'react';
import {
  Box, Container, Typography, TextField, Button, Card, CardContent,
  Select, MenuItem, FormControl, InputLabel, useTheme, alpha,
  Grid, Divider, Alert, Chip, Table, TableHead, TableBody, TableRow,
  TableCell, CircularProgress, Dialog, DialogTitle, DialogContent,
  DialogActions, IconButton, Tooltip,
} from '@mui/material';
import {
  PlayArrow as ProduceIcon,
  LocalFlorist as FloristIcon,
  CheckCircle as CheckIcon,
  Cancel as FailIcon,
  QrCode as BarcodeIcon,
  Inventory2 as InventoryIcon,
  ArrowBack as BackIcon,
} from '@mui/icons-material';
import { useNavigate } from 'react-router-dom';
import type { FloralRecipe, ProductionRunResult } from './types/ProductionTypes';
import type { StockCheck } from './utils/production.utils';
import { getRecipes, getInventoryProducts, createProductionRun } from './api/production.api';
import {
  calculateTotalCost, calculateBatchTotalCost, formatCurrency,
  checkStockSufficiency,
} from './utils/production.utils';
import { getLocations } from '../../api/location.api';

const ProductionScreen = () => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';
  const navigate = useNavigate();

  // ── State ──────────────────────────────────────────────────
  const [recipes, setRecipes] = useState<FloralRecipe[]>([]);
  const [selectedRecipeId, setSelectedRecipeId] = useState('');
  const [quantity, setQuantity] = useState<number>(1);
  const [expectedExpiry, setExpectedExpiry] = useState('');
  const [locationId, setLocationId] = useState('');
  const [_loading, setLoading] = useState(true);
  const [producing, setProducing] = useState(false);
  const [stockChecks, setStockChecks] = useState<StockCheck[]>([]);
  const [result, setResult] = useState<ProductionRunResult | null>(null);
  const [resultDialogOpen, setResultDialogOpen] = useState(false);
  const [error, setError] = useState('');
  const [locations, setLocations] = useState<Array<{ id: string; name: string; isActive?: boolean }>>([]);

  const activeLocations = useMemo(() => locations.filter((l) => l.isActive !== false), [locations]);

  // ── Load recipes & locations ───────────────────────────────────
  useEffect(() => {
    const load = async () => {
      setLoading(true);
      try {
        const [recipeData, locationData] = await Promise.all([
          getRecipes(),
          getLocations(),
        ]);
        setRecipes(recipeData.filter((r: FloralRecipe) => r.isActive));
        const locs = Array.isArray(locationData) ? locationData : locationData.items ?? locationData ?? [];
        setLocations(locs);
      } catch {
        setError('Failed to load recipes or locations');
      } finally {
        setLoading(false);
      }
    };
    load();
  }, []);

  // ── Selected recipe ────────────────────────────────────────
  const selectedRecipe = useMemo(
    () => recipes.find((r) => r.id === selectedRecipeId),
    [recipes, selectedRecipeId],
  );

  // ── Stock check on recipe/quantity/location change ─────────
  useEffect(() => {
    if (!selectedRecipe || !locationId) {
      setStockChecks([]);
      return;
    }
    const check = async () => {
      try {
        const products = await getInventoryProducts(locationId);
        const checks = checkStockSufficiency(selectedRecipe.components, quantity, products);
        setStockChecks(checks);
      } catch {
        setStockChecks([]);
      }
    };
    check();
  }, [selectedRecipe, quantity, locationId]);

  const allSufficient = useMemo(() => stockChecks.length > 0 && stockChecks.every((s) => s.sufficient), [stockChecks]);
  const unitCost = selectedRecipe ? calculateTotalCost(selectedRecipe) : 0;
  const totalCost = selectedRecipe ? calculateBatchTotalCost(selectedRecipe, quantity) : 0;

  // ── Validation ─────────────────────────────────────────────
  const isValid = useMemo(() => {
    if (!selectedRecipeId) return false;
    if (quantity <= 0) return false;
    if (!expectedExpiry) return false;
    if (!locationId) return false;
    if (!allSufficient) return false;
    return true;
  }, [selectedRecipeId, quantity, expectedExpiry, locationId, allSufficient]);

  // ── Submit ─────────────────────────────────────────────────
  const handleProduce = async () => {
    if (!isValid) return;
    setProducing(true);
    setError('');

    try {
      const res = await createProductionRun({
        recipeId: selectedRecipeId,
        quantity,
        expectedExpiry: new Date(expectedExpiry).toISOString(),
        locationId,
      });
      setResult(res);
      setResultDialogOpen(true);
    } catch {
      setError('Production failed. Please check stock levels and try again.');
    } finally {
      setProducing(false);
    }
  };

  // ── Default expiry (3 days from now) ───────────────────────
  useEffect(() => {
    if (!expectedExpiry) {
      const d = new Date();
      d.setDate(d.getDate() + 3);
      const local = new Date(d.getTime() - d.getTimezoneOffset() * 60000).toISOString().slice(0, 16);
      setExpectedExpiry(local);
    }
  }, []);

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
          <ProduceIcon sx={{ fontSize: 32, color: '#4caf50' }} />
          <Box>
            <Typography variant="h5" fontWeight={700}>Production</Typography>
            <Typography variant="body2" color="text.secondary">
              Pre-produce finished bouquets from recipes
            </Typography>
          </Box>
        </Box>

        {error && <Alert severity="error" sx={{ mb: 2, borderRadius: 2 }}>{error}</Alert>}

        <Grid container spacing={3}>
          {/* ── Left: Production Form ───────────────────── */}
          <Grid size={{ xs: 12, md: 7 }}>
            <Card elevation={0} sx={{ mb: 3, borderRadius: 2, border: `1px solid ${dk ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.08)'}` }}>
              <CardContent sx={{ p: 3 }}>
                <Typography variant="subtitle1" fontWeight={700} gutterBottom>Production Details</Typography>

                <Grid container spacing={2}>
                  <Grid size={{ xs: 12 }}>
                    <FormControl fullWidth>
                      <InputLabel>Select Recipe *</InputLabel>
                      <Select
                        value={selectedRecipeId}
                        label="Select Recipe *"
                        onChange={(e) => setSelectedRecipeId(e.target.value)}
                      >
                        {recipes.map((r) => (
                          <MenuItem key={r.id} value={r.id}>
                            <Box sx={{ display: 'flex', justifyContent: 'space-between', width: '100%', alignItems: 'center' }}>
                              <span>{r.name}</span>
                              <Chip label={r.category ?? 'Other'} size="small" variant="outlined" sx={{ ml: 2 }} />
                            </Box>
                          </MenuItem>
                        ))}
                      </Select>
                    </FormControl>
                  </Grid>
                  <Grid size={{ xs: 12, sm: 4 }}>
                    <TextField
                      label="Quantity to Produce *"
                      type="number"
                      value={quantity}
                      onChange={(e) => setQuantity(Math.max(1, Number(e.target.value)))}
                      fullWidth
                      inputProps={{ min: 1 }}
                    />
                  </Grid>
                  <Grid size={{ xs: 12, sm: 4 }}>
                    <TextField
                      label="Expected Expiry *"
                      type="datetime-local"
                      value={expectedExpiry}
                      onChange={(e) => setExpectedExpiry(e.target.value)}
                      fullWidth
                      InputLabelProps={{ shrink: true }}
                    />
                  </Grid>
                  <Grid size={{ xs: 12, sm: 4 }}>
                    <FormControl fullWidth>
                      <InputLabel>Location *</InputLabel>
                      <Select
                        value={locationId}
                        label="Location *"
                        onChange={(e) => setLocationId(e.target.value)}
                      >
                        {activeLocations.map((l) => (
                          <MenuItem key={l.id} value={l.id}>{l.name}</MenuItem>
                        ))}
                      </Select>
                    </FormControl>
                  </Grid>
                </Grid>
              </CardContent>
            </Card>

            {/* ── Stock Check ───────────────────────────── */}
            {selectedRecipe && stockChecks.length > 0 && (
              <Card elevation={0} sx={{ mb: 3, borderRadius: 2, border: `1px solid ${dk ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.08)'}` }}>
                <CardContent sx={{ p: 3 }}>
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 2 }}>
                    <InventoryIcon sx={{ color: allSufficient ? '#4caf50' : '#f44336' }} />
                    <Typography variant="subtitle1" fontWeight={700}>
                      Stock Check
                    </Typography>
                    <Chip
                      label={allSufficient ? 'All Sufficient' : 'Insufficient Stock'}
                      size="small"
                      color={allSufficient ? 'success' : 'error'}
                      sx={{ ml: 'auto' }}
                    />
                  </Box>
                  <Table size="small">
                    <TableHead>
                      <TableRow sx={{ '& th': { fontWeight: 700, fontSize: '0.8rem' } }}>
                        <TableCell>Material</TableCell>
                        <TableCell align="right">Required</TableCell>
                        <TableCell align="right">Available</TableCell>
                        <TableCell align="center">Status</TableCell>
                      </TableRow>
                    </TableHead>
                    <TableBody>
                      {stockChecks.map((s) => (
                        <TableRow key={s.productId}>
                          <TableCell>{s.productName}</TableCell>
                          <TableCell align="right">{s.required}</TableCell>
                          <TableCell align="right">{s.available}</TableCell>
                          <TableCell align="center">
                            {s.sufficient ? (
                              <CheckIcon sx={{ color: '#4caf50', fontSize: 20 }} />
                            ) : (
                              <FailIcon sx={{ color: '#f44336', fontSize: 20 }} />
                            )}
                          </TableCell>
                        </TableRow>
                      ))}
                    </TableBody>
                  </Table>

                  {!allSufficient && (
                    <Alert severity="error" sx={{ mt: 2, borderRadius: 1.5 }}>
                      Insufficient stock for one or more components. Reduce quantity or restock first.
                    </Alert>
                  )}
                </CardContent>
              </Card>
            )}
          </Grid>

          {/* ── Right: Cost Preview & Submit ─────────────── */}
          <Grid size={{ xs: 12, md: 5 }}>
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
                <Typography variant="subtitle1" fontWeight={700} gutterBottom>Production Summary</Typography>
                <Divider sx={{ mb: 2 }} />

                {selectedRecipe ? (
                  <>
                    <Box sx={{ mb: 2 }}>
                      <Typography variant="body2" color="text.secondary">Recipe</Typography>
                      <Typography fontWeight={600}>{selectedRecipe.name}</Typography>
                    </Box>
                    <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
                      <Typography variant="body2" color="text.secondary">Unit Cost</Typography>
                      <Typography>{formatCurrency(unitCost)}</Typography>
                    </Box>
                    <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
                      <Typography variant="body2" color="text.secondary">Quantity</Typography>
                      <Typography fontWeight={600}>× {quantity}</Typography>
                    </Box>
                    <Divider sx={{ my: 1.5 }} />
                    <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
                      <Typography fontWeight={700}>Total Production Cost</Typography>
                      <Typography fontWeight={700} color="error">{formatCurrency(totalCost)}</Typography>
                    </Box>
                    <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 2 }}>
                      <Typography variant="body2" color="text.secondary">Revenue (if all sold)</Typography>
                      <Typography fontWeight={600} color="primary">
                        {formatCurrency(selectedRecipe.sellingPrice * quantity)}
                      </Typography>
                    </Box>

                    <Typography variant="subtitle2" color="text.secondary" sx={{ mb: 1 }}>Components to Deduct</Typography>
                    {selectedRecipe.components.map((c) => (
                      <Box key={c.productId} sx={{ display: 'flex', justifyContent: 'space-between', mb: 0.5 }}>
                        <Typography variant="body2">{c.productName}</Typography>
                        <Typography variant="body2" fontWeight={600}>{c.quantityRequired * quantity}</Typography>
                      </Box>
                    ))}
                    <Divider sx={{ my: 2 }} />
                  </>
                ) : (
                  <Box sx={{ py: 4, textAlign: 'center' }}>
                    <FloristIcon sx={{ fontSize: 48, color: 'text.disabled', mb: 1 }} />
                    <Typography color="text.secondary">Select a recipe to begin</Typography>
                  </Box>
                )}

                <Button
                  variant="contained"
                  fullWidth
                  size="large"
                  startIcon={producing ? <CircularProgress size={20} color="inherit" /> : <ProduceIcon />}
                  onClick={handleProduce}
                  disabled={!isValid || producing}
                  sx={{
                    bgcolor: '#4caf50',
                    '&:hover': { bgcolor: '#388e3c' },
                    borderRadius: 2,
                    textTransform: 'none',
                    fontWeight: 600,
                    py: 1.5,
                  }}
                >
                  {producing ? 'Producing...' : 'Start Production'}
                </Button>
              </CardContent>
            </Card>
          </Grid>
        </Grid>

        {/* ── Result Dialog ─────────────────────────────── */}
        <Dialog open={resultDialogOpen} onClose={() => setResultDialogOpen(false)} maxWidth="sm" fullWidth>
          {result && (
            <>
              <DialogTitle sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                <CheckIcon sx={{ color: '#4caf50' }} />
                Production Complete!
              </DialogTitle>
              <DialogContent dividers>
                <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
                  <Box sx={{ p: 2, borderRadius: 2, bgcolor: alpha('#4caf50', 0.08), textAlign: 'center' }}>
                    <BarcodeIcon sx={{ fontSize: 48, color: '#4caf50', mb: 1 }} />
                    <Typography variant="h6" fontWeight={700}>{result.batchCode}</Typography>
                    <Typography variant="body2" color="text.secondary">Batch Code</Typography>
                    <Divider sx={{ my: 1.5 }} />
                    <Typography variant="h6" fontWeight={600} sx={{ fontFamily: 'monospace' }}>
                      {result.barcode}
                    </Typography>
                    <Typography variant="body2" color="text.secondary">Barcode</Typography>
                  </Box>

                  <Box sx={{ display: 'flex', gap: 3, justifyContent: 'center' }}>
                    <Box sx={{ textAlign: 'center' }}>
                      <Typography variant="h5" fontWeight={700} color="primary">{result.quantityProduced}</Typography>
                      <Typography variant="caption" color="text.secondary">Units Produced</Typography>
                    </Box>
                    <Box sx={{ textAlign: 'center' }}>
                      <Typography variant="h5" fontWeight={700} color="error">{formatCurrency(result.totalCost)}</Typography>
                      <Typography variant="caption" color="text.secondary">Total Cost</Typography>
                    </Box>
                  </Box>

                  <Typography variant="subtitle2" color="text.secondary">Raw Materials Deducted:</Typography>
                  {result.componentsDeducted.map((c) => {
                    const name = selectedRecipe?.components.find((rc) => rc.productId === c.productId)?.productName ?? c.productId;
                    return (
                      <Box key={c.productId} sx={{ display: 'flex', justifyContent: 'space-between' }}>
                        <Typography variant="body2">{name}</Typography>
                        <Typography variant="body2" fontWeight={600}>-{c.quantityDeducted}</Typography>
                      </Box>
                    );
                  })}
                </Box>
              </DialogContent>
              <DialogActions>
                <Button onClick={() => navigate('/production/finished-goods')}>View Finished Goods</Button>
                <Button
                  variant="contained"
                  onClick={() => {
                    setResultDialogOpen(false);
                    setResult(null);
                    setSelectedRecipeId('');
                    setQuantity(1);
                  }}
                  sx={{ bgcolor: '#4caf50', '&:hover': { bgcolor: '#388e3c' } }}
                >
                  Produce More
                </Button>
              </DialogActions>
            </>
          )}
        </Dialog>
      </Container>
    </Box>
  );
};

export default ProductionScreen;
