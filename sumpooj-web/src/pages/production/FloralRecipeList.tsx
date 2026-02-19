/**
 * FloralRecipeList.tsx — Recipe (BOM) Management Page
 *
 * Features:
 * - List all floral recipes with search/filter
 * - Cost preview per recipe
 * - Active/inactive toggle
 * - Navigate to add/edit
 */

import { useState, useEffect, useMemo, useCallback } from 'react';
import {
  Box, Container, Typography, TextField, Button, Card,
  Table, TableHead, TableBody, TableRow, TableCell, TableContainer,
  Chip, IconButton, Tooltip, InputAdornment, Select, MenuItem,
  FormControl, InputLabel, Switch, FormControlLabel, Paper,
  useTheme, alpha, Skeleton, Dialog, DialogTitle, DialogContent,
  DialogActions,
} from '@mui/material';
import {
  Add as AddIcon,
  Search as SearchIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
  LocalFlorist as FloristIcon,
  Visibility as ViewIcon,
} from '@mui/icons-material';
import { useNavigate } from 'react-router-dom';
import type { FloralRecipe, RecipeFilterState } from './types/ProductionTypes';
import { RECIPE_CATEGORIES } from './types/ProductionTypes';
import { getRecipes, deleteRecipe } from './api/production.api';
import { calculateComponentCost, calculateTotalCost, calculateMargin, formatCurrency } from './utils/production.utils';

const FloralRecipeList = () => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';
  const navigate = useNavigate();

  // ── State ──────────────────────────────────────────────────
  const [recipes, setRecipes] = useState<FloralRecipe[]>([]);
  const [loading, setLoading] = useState(true);
  const [filters, setFilters] = useState<RecipeFilterState>({
    search: '',
    category: '',
    activeOnly: false,
  });
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [selectedRecipe, setSelectedRecipe] = useState<FloralRecipe | null>(null);
  const [detailDialogOpen, setDetailDialogOpen] = useState(false);

  // ── Load ───────────────────────────────────────────────────
  const loadRecipes = useCallback(async () => {
    setLoading(true);
    try {
      const data = await getRecipes();
      setRecipes(data);
    } catch {
      // handle error
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { loadRecipes(); }, [loadRecipes]);

  // ── Filter ─────────────────────────────────────────────────
  const filtered = useMemo(() => {
    let list = [...recipes];
    if (filters.search) {
      const q = filters.search.toLowerCase();
      list = list.filter((r) => r.name.toLowerCase().includes(q) || r.category?.toLowerCase().includes(q));
    }
    if (filters.category) {
      list = list.filter((r) => r.category === filters.category);
    }
    if (filters.activeOnly) {
      list = list.filter((r) => r.isActive);
    }
    return list;
  }, [recipes, filters]);

  // ── Handlers ───────────────────────────────────────────────
  const handleDelete = async () => {
    if (!selectedRecipe) return;
    try {
      await deleteRecipe(selectedRecipe.id);
      setRecipes((prev) => prev.filter((r) => r.id !== selectedRecipe.id));
    } catch {
      // handle error
    }
    setDeleteDialogOpen(false);
    setSelectedRecipe(null);
  };

  const openDeleteDialog = (recipe: FloralRecipe) => {
    setSelectedRecipe(recipe);
    setDeleteDialogOpen(true);
  };

  const openDetailDialog = (recipe: FloralRecipe) => {
    setSelectedRecipe(recipe);
    setDetailDialogOpen(true);
  };

  return (
    <Box sx={{ minHeight: '100vh', pb: 6 }}>
      <Container maxWidth="xl" sx={{ pt: 3 }}>
        {/* ── Header ────────────────────────────────────── */}
        <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', mb: 3 }}>
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
            <FloristIcon sx={{ fontSize: 32, color: '#e91e63' }} />
            <Box>
              <Typography variant="h5" fontWeight={700}>Floral Recipes</Typography>
              <Typography variant="body2" color="text.secondary">
                Manage bouquet & arrangement recipes (Bill of Materials)
              </Typography>
            </Box>
          </Box>
          <Button
            variant="contained"
            startIcon={<AddIcon />}
            onClick={() => navigate('/production/recipes/new')}
            sx={{
              bgcolor: '#e91e63',
              '&:hover': { bgcolor: '#c2185b' },
              borderRadius: 2,
              textTransform: 'none',
              fontWeight: 600,
              px: 3,
            }}
          >
            New Recipe
          </Button>
        </Box>

        {/* ── Filters ───────────────────────────────────── */}
        <Paper
          elevation={0}
          sx={{
            p: 2,
            mb: 3,
            borderRadius: 2,
            border: `1px solid ${dk ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.08)'}`,
            display: 'flex',
            gap: 2,
            flexWrap: 'wrap',
            alignItems: 'center',
          }}
        >
          <TextField
            size="small"
            placeholder="Search recipes..."
            value={filters.search}
            onChange={(e) => setFilters((f) => ({ ...f, search: e.target.value }))}
            sx={{ minWidth: 260 }}
            InputProps={{
              startAdornment: (
                <InputAdornment position="start">
                  <SearchIcon sx={{ fontSize: 20, color: 'text.secondary' }} />
                </InputAdornment>
              ),
            }}
          />
          <FormControl size="small" sx={{ minWidth: 160 }}>
            <InputLabel>Category</InputLabel>
            <Select
              value={filters.category}
              label="Category"
              onChange={(e) => setFilters((f) => ({ ...f, category: e.target.value }))}
            >
              <MenuItem value="">All Categories</MenuItem>
              {RECIPE_CATEGORIES.map((c) => (
                <MenuItem key={c} value={c}>{c}</MenuItem>
              ))}
            </Select>
          </FormControl>
          <FormControlLabel
            control={
              <Switch
                checked={filters.activeOnly}
                onChange={(e) => setFilters((f) => ({ ...f, activeOnly: e.target.checked }))}
                size="small"
              />
            }
            label="Active only"
            sx={{ ml: 1 }}
          />
          <Typography variant="body2" color="text.secondary" sx={{ ml: 'auto' }}>
            {filtered.length} recipe{filtered.length !== 1 ? 's' : ''}
          </Typography>
        </Paper>

        {/* ── Table ─────────────────────────────────────── */}
        <Card
          elevation={0}
          sx={{
            borderRadius: 2,
            border: `1px solid ${dk ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.08)'}`,
          }}
        >
          <TableContainer>
            <Table>
              <TableHead>
                <TableRow sx={{ '& th': { fontWeight: 700, fontSize: '0.8125rem', color: 'text.secondary' } }}>
                  <TableCell>Recipe Name</TableCell>
                  <TableCell>Category</TableCell>
                  <TableCell align="center">Components</TableCell>
                  <TableCell align="right">Material Cost</TableCell>
                  <TableCell align="right">Labor</TableCell>
                  <TableCell align="right">Total Cost</TableCell>
                  <TableCell align="right">Selling Price</TableCell>
                  <TableCell align="right">Margin</TableCell>
                  <TableCell align="center">Status</TableCell>
                  <TableCell align="center">Actions</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {loading ? (
                  Array.from({ length: 5 }).map((_, i) => (
                    <TableRow key={i}>
                      {Array.from({ length: 10 }).map((_, j) => (
                        <TableCell key={j}><Skeleton variant="text" /></TableCell>
                      ))}
                    </TableRow>
                  ))
                ) : filtered.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={10} align="center" sx={{ py: 6 }}>
                      <FloristIcon sx={{ fontSize: 48, color: 'text.disabled', mb: 1 }} />
                      <Typography color="text.secondary">No recipes found</Typography>
                    </TableCell>
                  </TableRow>
                ) : (
                  filtered.map((recipe) => {
                    const matCost = calculateComponentCost(recipe.components);
                    const totalCost = calculateTotalCost(recipe);
                    const margin = calculateMargin(recipe);
                    return (
                      <TableRow
                        key={recipe.id}
                        hover
                        sx={{ cursor: 'pointer', '&:last-child td': { borderBottom: 0 } }}
                        onClick={() => openDetailDialog(recipe)}
                      >
                        <TableCell>
                          <Typography fontWeight={600} fontSize="0.9rem">{recipe.name}</Typography>
                        </TableCell>
                        <TableCell>
                          <Chip label={recipe.category ?? '—'} size="small" variant="outlined" />
                        </TableCell>
                        <TableCell align="center">{recipe.components.length}</TableCell>
                        <TableCell align="right">{formatCurrency(matCost)}</TableCell>
                        <TableCell align="right">{formatCurrency(recipe.laborCost ?? 0)}</TableCell>
                        <TableCell align="right">
                          <Typography fontWeight={600}>{formatCurrency(totalCost)}</Typography>
                        </TableCell>
                        <TableCell align="right">
                          <Typography fontWeight={700} color="primary">{formatCurrency(recipe.sellingPrice)}</Typography>
                        </TableCell>
                        <TableCell align="right">
                          <Chip
                            label={`${margin.toFixed(1)}%`}
                            size="small"
                            sx={{
                              fontWeight: 600,
                              bgcolor: alpha(margin > 30 ? '#4caf50' : margin > 15 ? '#ff9800' : '#f44336', 0.12),
                              color: margin > 30 ? '#4caf50' : margin > 15 ? '#ff9800' : '#f44336',
                            }}
                          />
                        </TableCell>
                        <TableCell align="center">
                          <Chip
                            label={recipe.isActive ? 'Active' : 'Inactive'}
                            size="small"
                            color={recipe.isActive ? 'success' : 'default'}
                            variant={recipe.isActive ? 'filled' : 'outlined'}
                          />
                        </TableCell>
                        <TableCell align="center" onClick={(e) => e.stopPropagation()}>
                          <Tooltip title="View details">
                            <IconButton size="small" onClick={() => openDetailDialog(recipe)}>
                              <ViewIcon fontSize="small" />
                            </IconButton>
                          </Tooltip>
                          <Tooltip title="Edit">
                            <IconButton size="small" onClick={() => navigate(`/production/recipes/${recipe.id}/edit`)}>
                              <EditIcon fontSize="small" />
                            </IconButton>
                          </Tooltip>
                          <Tooltip title="Delete">
                            <IconButton size="small" color="error" onClick={() => openDeleteDialog(recipe)}>
                              <DeleteIcon fontSize="small" />
                            </IconButton>
                          </Tooltip>
                        </TableCell>
                      </TableRow>
                    );
                  })
                )}
              </TableBody>
            </Table>
          </TableContainer>
        </Card>

        {/* ── Detail Dialog ─────────────────────────────── */}
        <Dialog
          open={detailDialogOpen}
          onClose={() => setDetailDialogOpen(false)}
          maxWidth="sm"
          fullWidth
        >
          {selectedRecipe && (
            <>
              <DialogTitle sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                <FloristIcon sx={{ color: '#e91e63' }} />
                {selectedRecipe.name}
                <Chip
                  label={selectedRecipe.isActive ? 'Active' : 'Inactive'}
                  size="small"
                  color={selectedRecipe.isActive ? 'success' : 'default'}
                  sx={{ ml: 'auto' }}
                />
              </DialogTitle>
              <DialogContent dividers>
                <Box sx={{ mb: 2 }}>
                  <Typography variant="subtitle2" color="text.secondary" gutterBottom>Category</Typography>
                  <Typography>{selectedRecipe.category ?? '—'}</Typography>
                </Box>
                <Typography variant="subtitle2" color="text.secondary" gutterBottom>Components</Typography>
                <Table size="small" sx={{ mb: 2 }}>
                  <TableHead>
                    <TableRow>
                      <TableCell sx={{ fontWeight: 700 }}>Material</TableCell>
                      <TableCell align="right" sx={{ fontWeight: 700 }}>Qty</TableCell>
                      <TableCell align="right" sx={{ fontWeight: 700 }}>Unit Cost</TableCell>
                      <TableCell align="right" sx={{ fontWeight: 700 }}>Subtotal</TableCell>
                    </TableRow>
                  </TableHead>
                  <TableBody>
                    {selectedRecipe.components.map((c) => (
                      <TableRow key={c.productId}>
                        <TableCell>{c.productName}</TableCell>
                        <TableCell align="right">{c.quantityRequired}</TableCell>
                        <TableCell align="right">{formatCurrency(c.unitCost)}</TableCell>
                        <TableCell align="right">{formatCurrency(c.unitCost * c.quantityRequired)}</TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
                <Box sx={{ display: 'flex', gap: 3, flexWrap: 'wrap' }}>
                  <Box>
                    <Typography variant="caption" color="text.secondary">Material Cost</Typography>
                    <Typography fontWeight={600}>{formatCurrency(calculateComponentCost(selectedRecipe.components))}</Typography>
                  </Box>
                  <Box>
                    <Typography variant="caption" color="text.secondary">Labor Cost</Typography>
                    <Typography fontWeight={600}>{formatCurrency(selectedRecipe.laborCost ?? 0)}</Typography>
                  </Box>
                  <Box>
                    <Typography variant="caption" color="text.secondary">Total Cost</Typography>
                    <Typography fontWeight={700} color="error">{formatCurrency(calculateTotalCost(selectedRecipe))}</Typography>
                  </Box>
                  <Box>
                    <Typography variant="caption" color="text.secondary">Selling Price</Typography>
                    <Typography fontWeight={700} color="primary">{formatCurrency(selectedRecipe.sellingPrice)}</Typography>
                  </Box>
                  <Box>
                    <Typography variant="caption" color="text.secondary">Margin</Typography>
                    <Typography fontWeight={700} sx={{ color: '#4caf50' }}>{calculateMargin(selectedRecipe).toFixed(1)}%</Typography>
                  </Box>
                </Box>
              </DialogContent>
              <DialogActions>
                <Button onClick={() => setDetailDialogOpen(false)}>Close</Button>
                <Button
                  variant="contained"
                  onClick={() => {
                    setDetailDialogOpen(false);
                    navigate(`/production/recipes/${selectedRecipe.id}/edit`);
                  }}
                  sx={{ bgcolor: '#e91e63', '&:hover': { bgcolor: '#c2185b' } }}
                >
                  Edit Recipe
                </Button>
              </DialogActions>
            </>
          )}
        </Dialog>

        {/* ── Delete Confirmation ───────────────────────── */}
        <Dialog open={deleteDialogOpen} onClose={() => setDeleteDialogOpen(false)}>
          <DialogTitle>Delete Recipe</DialogTitle>
          <DialogContent>
            <Typography>
              Are you sure you want to delete <strong>{selectedRecipe?.name}</strong>? This action cannot be undone.
            </Typography>
          </DialogContent>
          <DialogActions>
            <Button onClick={() => setDeleteDialogOpen(false)}>Cancel</Button>
            <Button color="error" variant="contained" onClick={handleDelete}>Delete</Button>
          </DialogActions>
        </Dialog>
      </Container>
    </Box>
  );
};

export default FloralRecipeList;
