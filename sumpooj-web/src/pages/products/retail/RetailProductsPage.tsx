/**
 * RetailProductsPage.tsx — Floraprise ERP Retail View Product Management Page
 *
 * Dedicated Retail Product experience:
 * - Simple, responsive, florist-centric design
 * - Fast search by Name, SKU, and Barcode
 * - Category filter chips matching Android app workflows
 * - Stock status filtering (All, In Stock, Low Stock, Out of Stock)
 * - Visual Product Cards Grid & Compact Table views
 * - Quick Add & Edit product modals (non-destructive)
 * - Integrated barcode label printing
 */

import React, { useState, useEffect, useMemo, useCallback } from 'react';
import {
  Box,
  Typography,
  Button,
  TextField,
  InputAdornment,
  Chip,
  IconButton,
  Tooltip,
  CircularProgress,
  Alert,
  Snackbar,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  ToggleButtonGroup,
  ToggleButton,
  useTheme,
  alpha,
  useMediaQuery,
} from '@mui/material';
import {
  Add as AddIcon,
  Search as SearchIcon,
  Clear as ClearIcon,
  Refresh as RefreshIcon,
  GridView as GridViewIcon,
  TableRows as TableViewIcon,
  Print as PrintIcon,
  Edit as EditIcon,
  LocalFlorist as FlowerIcon,
} from '@mui/icons-material';
import {
  searchProducts,
  activateProduct,
  deactivateProduct,
} from '../../../api/product.api';
import { getCategories, type ProductCategoryDto } from '../../../api/category.api';
import { getBatchSummary, type BatchSummaryItem } from '../../../api/inventory.api';
import { useTenant } from '../../../core/tenant';
import { CURRENCY_SYMBOL_MAP } from '../../../core/tenant/TenantTypes';
import LabelPrintModal from '../../../components/barcode/LabelPrintModal';
import type { LabelData } from '../../../components/barcode/BarcodeTypes';

import { RetailProductCard, type RetailProductItem } from './RetailProductCard';
import { RetailProductModal } from './RetailProductModal';

export const RetailProductsPage: React.FC = () => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';
  const isMobile = useMediaQuery(theme.breakpoints.down('sm'));
  const { tenant } = useTenant();

  const currencySymbol = tenant?.currency ? (CURRENCY_SYMBOL_MAP[tenant.currency] ?? '$') : '$';

  // Data State
  const [products, setProducts] = useState<RetailProductItem[]>([]);
  const [categories, setCategories] = useState<ProductCategoryDto[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Filter & Search State
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCategory, setSelectedCategory] = useState<string>('all');
  const [stockFilter, setStockFilter] = useState<'all' | 'in_stock' | 'low_stock' | 'out_of_stock'>('all');
  const [viewLayout, setViewLayout] = useState<'cards' | 'table'>('cards');

  // Modal State
  const [modalOpen, setModalOpen] = useState(false);
  const [editingProduct, setEditingProduct] = useState<RetailProductItem | null>(null);

  // Barcode Print Modal State
  const [printModalOpen, setPrintModalOpen] = useState(false);
  const [labelData, setLabelData] = useState<LabelData | null>(null);

  // Snackbar Notification
  const [toast, setToast] = useState<{ open: boolean; message: string; severity: 'success' | 'info' | 'error' }>({
    open: false,
    message: '',
    severity: 'info',
  });

  // Load products and categories from backend
  const loadData = useCallback(async () => {
    setLoading(true);
    setError(null);

    try {
      const [productRes, categoryRes, batchRes] = await Promise.all([
        searchProducts({ PageSize: 500 }),
        getCategories(),
        getBatchSummary().catch(() => [] as BatchSummaryItem[]),
      ]);

      // Category map
      const activeCats = Array.isArray(categoryRes) ? categoryRes.filter((c) => c.isActive) : [];
      setCategories(activeCats);

      // Batch inventory map
      const invMap = new Map<string, number>();
      if (Array.isArray(batchRes)) {
        batchRes.forEach((b: BatchSummaryItem) => {
          invMap.set(b.productId, (invMap.get(b.productId) ?? 0) + (b.availableUnits ?? 0));
        });
      }

      // Products map
      const rawItems = productRes?.items ?? (Array.isArray(productRes) ? productRes : []);
      const mapped: RetailProductItem[] = rawItems.map((p: any) => {
        const batchStock = invMap.get(p.id);
        const effectiveStock = batchStock !== undefined ? batchStock : (p.stockQuantity ?? 0);

        return {
          id: p.id,
          name: p.name || p.productName || 'Unnamed Product',
          sku: p.sku || '',
          barcode: p.barcode || null,
          manufacturerBarcode: p.manufacturerBarcode || null,
          internalBarcode: p.internalBarcode || null,
          category: p.categoryName || p.category || 'Other',
          categoryId: p.categoryId || null,
          unitOfMeasure: p.unitOfMeasure || 'Stem',
          retailPrice: Number(p.retailPrice ?? 0),
          costPrice: Number(p.costPrice ?? 0),
          stockQuantity: effectiveStock,
          reorderLevel: Number(p.reorderLevel ?? 0),
          trackInventory: Boolean(p.trackInventory),
          trackBatch: Boolean(p.trackBatch),
          isActive: p.isActive !== false,
          description: p.description || null,
        };
      });

      setProducts(mapped);
    } catch (err: any) {
      console.error('Failed to load retail products:', err);
      setError(err?.message || 'Failed to load products. Please check your connection.');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    loadData();
  }, [loadData]);

  // Handle Edit Action
  const handleOpenEdit = (prod: RetailProductItem) => {
    setEditingProduct(prod);
    setModalOpen(true);
  };

  // Handle Add Product Action
  const handleOpenAdd = () => {
    setEditingProduct(null);
    setModalOpen(true);
  };

  // Handle Toggle Active/Inactive Status
  const handleToggleStatus = async (prod: RetailProductItem) => {
    try {
      if (prod.isActive) {
        await deactivateProduct(prod.id);
        setToast({ open: true, message: `Product "${prod.name}" deactivated.`, severity: 'info' });
      } else {
        await activateProduct(prod.id);
        setToast({ open: true, message: `Product "${prod.name}" activated.`, severity: 'success' });
      }
      loadData();
    } catch (err: any) {
      setToast({
        open: true,
        message: `Failed to update status: ${err?.message || 'Error'}`,
        severity: 'error',
      });
    }
  };

  // Handle Barcode Label Print
  const handlePrintBarcode = (prod: RetailProductItem) => {
    const code =
      prod.manufacturerBarcode?.trim() ||
      prod.barcode?.trim() ||
      prod.internalBarcode?.trim() ||
      prod.sku.trim();

    if (!code) {
      setToast({ open: true, message: 'No barcode or SKU available for printing.', severity: 'error' });
      return;
    }

    setLabelData({
      productName: prod.name,
      sku: prod.sku,
      barcode: code,
      retailPrice: prod.retailPrice,
      currency: currencySymbol,
    });
    setPrintModalOpen(true);
  };

  // Filtered Products
  const filteredProducts = useMemo(() => {
    const q = searchQuery.trim().toLowerCase();

    return products.filter((item) => {
      // Search filter (Name, SKU, Barcode)
      if (q) {
        const matchesName = item.name.toLowerCase().includes(q);
        const matchesSku = item.sku.toLowerCase().includes(q);
        const matchesBarcode =
          (item.barcode && item.barcode.toLowerCase().includes(q)) ||
          (item.manufacturerBarcode && item.manufacturerBarcode.toLowerCase().includes(q)) ||
          (item.internalBarcode && item.internalBarcode.toLowerCase().includes(q));

        if (!matchesName && !matchesSku && !matchesBarcode) {
          return false;
        }
      }

      // Category filter
      if (selectedCategory !== 'all') {
        const matchesId = item.categoryId === selectedCategory;
        const matchesName = item.category?.toLowerCase() === selectedCategory.toLowerCase();
        if (!matchesId && !matchesName) return false;
      }

      // Stock filter
      if (stockFilter === 'in_stock') {
        if (item.trackInventory && item.stockQuantity <= 0) return false;
      } else if (stockFilter === 'low_stock') {
        const threshold = item.reorderLevel > 0 ? item.reorderLevel : 5;
        if (!item.trackInventory || item.stockQuantity <= 0 || item.stockQuantity > threshold) return false;
      } else if (stockFilter === 'out_of_stock') {
        if (!item.trackInventory || item.stockQuantity > 0) return false;
      }

      return true;
    });
  }, [products, searchQuery, selectedCategory, stockFilter]);

  return (
    <Box sx={{ p: { xs: 2, md: 3 }, maxWidth: 1440, mx: 'auto' }}>
      {/* Top Header Bar */}
      <Box
        sx={{
          display: 'flex',
          flexDirection: { xs: 'column', sm: 'row' },
          justifyContent: 'space-between',
          alignItems: { xs: 'flex-start', sm: 'center' },
          gap: 2,
          mb: 3,
        }}
      >
        <Box>
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
            <Typography variant="h5" sx={{ fontWeight: 800, color: dk ? '#fff' : '#1a1a2e' }}>
              Products
            </Typography>
            <Chip
              label={`${filteredProducts.length}${filteredProducts.length !== products.length ? ` / ${products.length}` : ''}`}
              size="small"
              sx={{ fontWeight: 700, bgcolor: dk ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.06)' }}
            />
          </Box>
          <Typography variant="body2" sx={{ color: 'text.secondary', mt: 0.25 }}>
            Retail Florist Catalog & Stock Management
          </Typography>
        </Box>

        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5, width: { xs: '100%', sm: 'auto' } }}>
          <Button
            variant="contained"
            color="primary"
            startIcon={<AddIcon />}
            onClick={handleOpenAdd}
            sx={{
              borderRadius: 2,
              px: 2.5,
              py: 1,
              fontWeight: 700,
              flexGrow: { xs: 1, sm: 0 },
              boxShadow: '0 4px 12px rgba(46,125,50,0.25)',
            }}
          >
            Add Product
          </Button>

          <Tooltip title="Refresh Catalog" arrow>
            <IconButton
              onClick={loadData}
              disabled={loading}
              sx={{
                bgcolor: dk ? 'rgba(255,255,255,0.05)' : 'rgba(0,0,0,0.04)',
                border: `1px solid ${dk ? 'rgba(255,255,255,0.08)' : '#e0e0e0'}`,
              }}
            >
              <RefreshIcon fontSize="small" />
            </IconButton>
          </Tooltip>

          {/* View layout toggle (desktop/tablet only) */}
          {!isMobile && (
            <ToggleButtonGroup
              size="small"
              value={viewLayout}
              exclusive
              onChange={(_, next) => next && setViewLayout(next)}
              sx={{
                bgcolor: dk ? 'rgba(255,255,255,0.05)' : 'rgba(0,0,0,0.04)',
              }}
            >
              <ToggleButton value="cards" aria-label="Card Grid">
                <GridViewIcon fontSize="small" />
              </ToggleButton>
              <ToggleButton value="table" aria-label="Table View">
                <TableViewIcon fontSize="small" />
              </ToggleButton>
            </ToggleButtonGroup>
          )}
        </Box>
      </Box>

      {/* Search & Stock Filter Bar */}
      <Box
        sx={{
          p: 2,
          mb: 2.5,
          borderRadius: 2.5,
          bgcolor: dk ? '#1e1e2d' : '#ffffff',
          border: `1px solid ${dk ? 'rgba(255,255,255,0.08)' : '#e8eaed'}`,
          display: 'flex',
          flexDirection: { xs: 'column', md: 'row' },
          gap: 2,
          alignItems: { xs: 'stretch', md: 'center' },
          justifyContent: 'space-between',
        }}
      >
        {/* Search Field */}
        <TextField
          size="small"
          placeholder="Search by Product Name, SKU, or Barcode..."
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          sx={{ minWidth: { xs: '100%', md: 380 } }}
          slotProps={{
            input: {
              startAdornment: (
                <InputAdornment position="start">
                  <SearchIcon fontSize="small" sx={{ color: 'text.secondary' }} />
                </InputAdornment>
              ),
              endAdornment: searchQuery ? (
                <InputAdornment position="end">
                  <IconButton size="small" onClick={() => setSearchQuery('')}>
                    <ClearIcon fontSize="small" />
                  </IconButton>
                </InputAdornment>
              ) : undefined,
            },
          }}
        />

        {/* Stock Filter Chips */}
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, flexWrap: 'wrap' }}>
          <Typography variant="caption" sx={{ color: 'text.secondary', fontWeight: 600, mr: 0.5 }}>
            Stock:
          </Typography>
          <Chip
            size="small"
            label="All"
            clickable
            color={stockFilter === 'all' ? 'primary' : 'default'}
            variant={stockFilter === 'all' ? 'filled' : 'outlined'}
            onClick={() => setStockFilter('all')}
          />
          <Chip
            size="small"
            label="In Stock"
            clickable
            color={stockFilter === 'in_stock' ? 'success' : 'default'}
            variant={stockFilter === 'in_stock' ? 'filled' : 'outlined'}
            onClick={() => setStockFilter('in_stock')}
          />
          <Chip
            size="small"
            label="Low Stock"
            clickable
            color={stockFilter === 'low_stock' ? 'warning' : 'default'}
            variant={stockFilter === 'low_stock' ? 'filled' : 'outlined'}
            onClick={() => setStockFilter('low_stock')}
          />
          <Chip
            size="small"
            label="Out of Stock"
            clickable
            color={stockFilter === 'out_of_stock' ? 'error' : 'default'}
            variant={stockFilter === 'out_of_stock' ? 'filled' : 'outlined'}
            onClick={() => setStockFilter('out_of_stock')}
          />
        </Box>
      </Box>

      {/* Category Filter Chips Bar */}
      <Box
        sx={{
          mb: 3,
          display: 'flex',
          alignItems: 'center',
          gap: 1,
          overflowX: 'auto',
          pb: 1,
          '&::-webkit-scrollbar': { height: 4 },
          '&::-webkit-scrollbar-thumb': { bgcolor: dk ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.15)', borderRadius: 2 },
        }}
      >
        <Chip
          label="All Categories"
          clickable
          color={selectedCategory === 'all' ? 'primary' : 'default'}
          variant={selectedCategory === 'all' ? 'filled' : 'outlined'}
          onClick={() => setSelectedCategory('all')}
          sx={{ fontWeight: 600, borderRadius: 2, px: 0.5 }}
        />

        {categories.map((c) => {
          const isSelected = selectedCategory === c.id || selectedCategory.toLowerCase() === c.name.toLowerCase();
          return (
            <Chip
              key={c.id}
              label={c.name}
              clickable
              color={isSelected ? 'primary' : 'default'}
              variant={isSelected ? 'filled' : 'outlined'}
              onClick={() => setSelectedCategory(isSelected ? 'all' : c.id)}
              sx={{ fontWeight: 600, borderRadius: 2, px: 0.5 }}
            />
          );
        })}
      </Box>

      {/* Error Display */}
      {error && (
        <Alert severity="error" sx={{ mb: 3, borderRadius: 2 }}>
          {error}
        </Alert>
      )}

      {/* Content Area: Loading / Empty / Cards Grid / Table */}
      {loading ? (
        <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', minHeight: 280, gap: 2 }}>
          <CircularProgress size={32} />
          <Typography variant="body2" sx={{ color: 'text.secondary' }}>
            Loading products...
          </Typography>
        </Box>
      ) : filteredProducts.length === 0 ? (
        <Paper
          elevation={0}
          sx={{
            p: 6,
            textAlign: 'center',
            borderRadius: 3,
            bgcolor: dk ? '#1e1e2d' : '#ffffff',
            border: `1px solid ${dk ? 'rgba(255,255,255,0.08)' : '#e8eaed'}`,
          }}
        >
          <FlowerIcon sx={{ fontSize: 48, color: 'text.secondary', opacity: 0.4, mb: 1.5 }} />
          <Typography variant="h6" sx={{ fontWeight: 700, mb: 0.5 }}>
            No products found
          </Typography>
          <Typography variant="body2" sx={{ color: 'text.secondary', mb: 2.5, maxWidth: 420, mx: 'auto' }}>
            {searchQuery || selectedCategory !== 'all' || stockFilter !== 'all'
              ? 'No products matched your active search or filters. Try clearing some filters.'
              : 'Your florist catalog is currently empty. Add your first flower or product to start selling.'}
          </Typography>
          {searchQuery || selectedCategory !== 'all' || stockFilter !== 'all' ? (
            <Button
              variant="outlined"
              onClick={() => {
                setSearchQuery('');
                setSelectedCategory('all');
                setStockFilter('all');
              }}
            >
              Reset Filters
            </Button>
          ) : (
            <Button variant="contained" color="primary" startIcon={<AddIcon />} onClick={handleOpenAdd}>
              Add Product
            </Button>
          )}
        </Paper>
      ) : viewLayout === 'cards' || isMobile ? (
        /* Cards Grid View */
        <Box
          sx={{
            display: 'grid',
            gridTemplateColumns: {
              xs: '1fr',
              sm: 'repeat(auto-fill, minmax(280px, 1fr))',
              md: 'repeat(auto-fill, minmax(310px, 1fr))',
            },
            gap: 2.5,
          }}
        >
          {filteredProducts.map((prod) => (
            <RetailProductCard
              key={prod.id}
              product={prod}
              currencySymbol={currencySymbol}
              onEdit={handleOpenEdit}
              onPrintBarcode={handlePrintBarcode}
              onToggleStatus={handleToggleStatus}
            />
          ))}
        </Box>
      ) : (
        /* Compact Table View */
        <TableContainer
          component={Paper}
          elevation={0}
          sx={{
            borderRadius: 3,
            border: `1px solid ${dk ? 'rgba(255,255,255,0.08)' : '#e8eaed'}`,
            bgcolor: dk ? '#1e1e2d' : '#ffffff',
          }}
        >
          <Table size="small">
            <TableHead>
              <TableRow sx={{ bgcolor: dk ? 'rgba(255,255,255,0.03)' : 'rgba(0,0,0,0.02)' }}>
                <TableCell sx={{ fontWeight: 700 }}>Product Name</TableCell>
                <TableCell sx={{ fontWeight: 700 }}>SKU</TableCell>
                <TableCell sx={{ fontWeight: 700 }}>Category</TableCell>
                <TableCell sx={{ fontWeight: 700 }}>UOM</TableCell>
                <TableCell align="right" sx={{ fontWeight: 700 }}>Selling Price</TableCell>
                <TableCell align="right" sx={{ fontWeight: 700 }}>Cost Price</TableCell>
                <TableCell align="center" sx={{ fontWeight: 700 }}>Stock Level</TableCell>
                <TableCell align="center" sx={{ fontWeight: 700 }}>Status</TableCell>
                <TableCell align="center" sx={{ fontWeight: 700 }}>Actions</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {filteredProducts.map((prod) => {
                const isOutOfStock = prod.trackInventory && prod.stockQuantity <= 0;
                const isLowStock =
                  prod.trackInventory &&
                  prod.stockQuantity > 0 &&
                  prod.stockQuantity <= (prod.reorderLevel > 0 ? prod.reorderLevel : 5);

                return (
                  <TableRow
                    key={prod.id}
                    hover
                    sx={{
                      opacity: prod.isActive ? 1 : 0.6,
                      '&:last-child td, &:last-child th': { border: 0 },
                    }}
                  >
                    <TableCell sx={{ fontWeight: 600 }}>{prod.name}</TableCell>
                    <TableCell sx={{ fontFamily: 'monospace', color: 'text.secondary' }}>{prod.sku}</TableCell>
                    <TableCell>
                      <Chip size="small" label={prod.category} sx={{ fontSize: '0.72rem', height: 20 }} />
                    </TableCell>
                    <TableCell>{prod.unitOfMeasure}</TableCell>
                    <TableCell align="right" sx={{ fontWeight: 700, color: '#2e7d32' }}>
                      {currencySymbol}{prod.retailPrice.toFixed(2)}
                    </TableCell>
                    <TableCell align="right" sx={{ color: 'text.secondary' }}>
                      {currencySymbol}{prod.costPrice.toFixed(2)}
                    </TableCell>
                    <TableCell align="center">
                      <Chip
                        size="small"
                        color={!prod.trackInventory ? 'default' : isOutOfStock ? 'error' : isLowStock ? 'warning' : 'success'}
                        label={
                          !prod.trackInventory
                            ? 'Untracked'
                            : isOutOfStock
                            ? 'Out of Stock'
                            : `${prod.stockQuantity}`
                        }
                        sx={{ fontSize: '0.72rem', height: 20 }}
                      />
                    </TableCell>
                    <TableCell align="center">
                      <Typography
                        variant="caption"
                        sx={{
                          fontWeight: 600,
                          color: prod.isActive ? '#2e7d32' : 'text.disabled',
                        }}
                      >
                        {prod.isActive ? 'Active' : 'Inactive'}
                      </Typography>
                    </TableCell>
                    <TableCell align="center">
                      <Box sx={{ display: 'inline-flex', gap: 0.5 }}>
                        <Tooltip title="Print Barcode" arrow>
                          <IconButton size="small" onClick={() => handlePrintBarcode(prod)}>
                            <PrintIcon fontSize="small" />
                          </IconButton>
                        </Tooltip>
                        <Tooltip title="Edit" arrow>
                          <IconButton size="small" color="primary" onClick={() => handleOpenEdit(prod)}>
                            <EditIcon fontSize="small" />
                          </IconButton>
                        </Tooltip>
                      </Box>
                    </TableCell>
                  </TableRow>
                );
              })}
            </TableBody>
          </Table>
        </TableContainer>
      )}

      {/* Add / Edit Product Modal */}
      <RetailProductModal
        open={modalOpen}
        onClose={() => setModalOpen(false)}
        product={editingProduct}
        categories={categories}
        currencySymbol={currencySymbol}
        onSuccess={() => {
          setToast({
            open: true,
            message: editingProduct ? 'Product updated successfully!' : 'Product created successfully!',
            severity: 'success',
          });
          loadData();
        }}
      />

      {/* Barcode Label Print Modal */}
      {labelData && (
        <LabelPrintModal
          open={printModalOpen}
          onClose={() => {
            setPrintModalOpen(false);
            setLabelData(null);
          }}
          labelData={labelData}
        />
      )}

      {/* Toast Feedback */}
      <Snackbar
        open={toast.open}
        autoHideDuration={4000}
        onClose={() => setToast((prev) => ({ ...prev, open: false }))}
        anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }}
      >
        <Alert
          severity={toast.severity}
          variant="filled"
          onClose={() => setToast((prev) => ({ ...prev, open: false }))}
          sx={{ borderRadius: 2 }}
        >
          {toast.message}
        </Alert>
      </Snackbar>
    </Box>
  );
};

export default RetailProductsPage;
