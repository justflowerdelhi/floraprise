/**
 * ProductsListPage.tsx — Products List Page
 *
 * Features:
 * - MUI Table with Product Name, Category, Unit of Measure, Flower Type, Available Units, Actions
 * - Flower Type column shows chip based on isMultiUnit
 * - Available Units column shows aggregated inventory with low stock warning
 * - Edit action navigates to /products/{id}
 * - Add Product button navigates to /products/new
 */
import React, { useState, useEffect, useCallback } from 'react';
import {
  Box, Typography, Button, Chip, Card,
  Table, TableBody, TableCell, TableContainer, TableHead, TableRow,
  IconButton, useTheme, alpha, Tooltip, TablePagination, CircularProgress,
} from '@mui/material';
import {
  Add as AddIcon,
  Edit as EditIcon,
  Warning as WarningIcon,
} from '@mui/icons-material';
import { useNavigate } from 'react-router-dom';
import { searchProducts } from '../../api/product.api';
import { getBatchSummary, type BatchSummaryItem } from '../../api/inventory.api';
import { useApiCall } from '../../hooks/useApiCall';

// ─── Product List Item Type ─────────────────────────────────

interface ProductListItem {
  id: string;
  name: string;
  productName?: string;
  category: string;
  unitOfMeasure: string;
  isMultiUnit: boolean;
  avgUnitsPerStem: number;
  reorderLevel: number;
}

// ─── Aggregated Inventory Data ──────────────────────────────

interface ProductInventory {
  availableUnits: number;
  remainingStems: number;
}

// ─── Main Component ─────────────────────────────────────────

const ProductsListPage: React.FC = () => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';
  const navigate = useNavigate();

  const { loading, execute } = useApiCall();

  // State
  const [products, setProducts] = useState<ProductListItem[]>([]);
  const [inventoryMap, setInventoryMap] = useState<Map<string, ProductInventory>>(new Map());
  const [page, setPage] = useState(0);
  const [rowsPerPage, setRowsPerPage] = useState(10);

  // Load products and batch summary from API
  const loadData = useCallback(async () => {
    const [productResult, batchResult] = await Promise.all([
      execute(() => searchProducts({ PageSize: 500 })),
      execute(() => getBatchSummary()),
    ]);

    // Process products
    if (productResult?.items || Array.isArray(productResult)) {
      const items = productResult.items ?? productResult;
      setProducts(
        items.map((p: any) => ({
          id: p.id,
          name: p.name || p.productName || '',
          category: p.category || '-',
          unitOfMeasure: p.unitOfMeasure || '-',
          isMultiUnit: p.isMultiUnit ?? false,
          avgUnitsPerStem: p.avgUnitsPerStem ?? 1,
          reorderLevel: p.reorderLevel ?? 0,
        }))
      );
    }

    // Process batch summary - aggregate by productId
    if (Array.isArray(batchResult)) {
      const invMap = new Map<string, ProductInventory>();
      batchResult.forEach((batch: BatchSummaryItem) => {
        const existing = invMap.get(batch.productId) ?? { availableUnits: 0, remainingStems: 0 };
        invMap.set(batch.productId, {
          availableUnits: existing.availableUnits + batch.availableUnits,
          remainingStems: existing.remainingStems + batch.remainingStems,
        });
      });
      setInventoryMap(invMap);
    }
  }, [execute]);

  useEffect(() => {
    loadData();
  }, [loadData]);

  // Paginated products
  const paginatedProducts = products.slice(
    page * rowsPerPage,
    page * rowsPerPage + rowsPerPage
  );

  return (
    <Box sx={{ p: 3 }}>
      {/* Header */}
      <Box
        sx={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          mb: 3,
        }}
      >
        <Typography variant="h5" sx={{ fontWeight: 700 }}>
          Products
        </Typography>
        <Button
          variant="contained"
          startIcon={<AddIcon />}
          onClick={() => navigate('/products/new')}
          sx={{
            bgcolor: '#7c4dff',
            '&:hover': { bgcolor: '#651fff' },
            fontWeight: 700,
            px: 3,
          }}
        >
          Add Product
        </Button>
      </Box>

      {/* Loading State */}
      {loading && (
        <Box sx={{ display: 'flex', justifyContent: 'center', py: 6 }}>
          <CircularProgress />
        </Box>
      )}

      {/* Products Table */}
      {!loading && (
        <Card
          sx={{
            bgcolor: dk ? '#1a1a2e' : '#fff',
            border: `1px solid ${dk ? 'rgba(255,255,255,0.06)' : '#e0e0e0'}`,
            borderRadius: 2,
            overflow: 'hidden',
          }}
        >
          <TableContainer>
            <Table>
              <TableHead>
                <TableRow sx={{ bgcolor: dk ? 'rgba(255,255,255,0.03)' : '#f5f5f5' }}>
                  <TableCell sx={{ fontWeight: 700 }}>Product Name</TableCell>
                  <TableCell sx={{ fontWeight: 700 }}>Category</TableCell>
                  <TableCell sx={{ fontWeight: 700 }}>Unit of Measure</TableCell>
                  <TableCell sx={{ fontWeight: 700 }}>Flower Type</TableCell>
                  <TableCell sx={{ fontWeight: 700 }}>Available Units</TableCell>
                  <TableCell sx={{ fontWeight: 700 }} align="center">Actions</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {paginatedProducts.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={6} align="center" sx={{ py: 6 }}>
                      <Typography variant="body1" sx={{ color: 'text.secondary' }}>
                        No products found
                      </Typography>
                    </TableCell>
                  </TableRow>
                ) : (
                  paginatedProducts.map((product) => (
                    <TableRow
                      key={product.id}
                      hover
                      sx={{
                        '&:hover': { bgcolor: dk ? 'rgba(255,255,255,0.03)' : 'rgba(0,0,0,0.02)' },
                      }}
                    >
                      <TableCell>
                        <Typography variant="body2" sx={{ fontWeight: 600 }}>
                          {product.name}
                        </Typography>
                      </TableCell>
                      <TableCell>
                        <Typography variant="body2">{product.category}</Typography>
                      </TableCell>
                      <TableCell>
                        <Typography variant="body2">{product.unitOfMeasure}</Typography>
                      </TableCell>
                      <TableCell>
                        {product.isMultiUnit ? (
                          <Chip
                            label={`${product.avgUnitsPerStem} units/stem`}
                            size="small"
                            color="secondary"
                            sx={{
                              fontWeight: 600,
                              fontSize: '0.75rem',
                            }}
                          />
                        ) : (
                          <Chip
                            label="Single Stem"
                            size="small"
                            color="default"
                            sx={{
                              fontWeight: 600,
                              fontSize: '0.75rem',
                            }}
                          />
                        )}
                      </TableCell>
                      <TableCell>
                        {(() => {
                          const inv = inventoryMap.get(product.id);
                          const value = product.isMultiUnit
                            ? (inv?.availableUnits ?? 0)
                            : (inv?.remainingStems ?? 0);
                          const unit = product.isMultiUnit ? 'units' : 'stems';
                          const isLowStock = value <= product.reorderLevel && product.reorderLevel > 0;

                          return (
                            <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
                              <Typography
                                variant="body2"
                                sx={{
                                  fontWeight: 600,
                                  color: isLowStock ? '#f44336' : 'inherit',
                                }}
                              >
                                {value} {unit}
                              </Typography>
                              {isLowStock && (
                                <Tooltip title="Low Stock">
                                  <WarningIcon sx={{ fontSize: 16, color: '#f44336' }} />
                                </Tooltip>
                              )}
                            </Box>
                          );
                        })()}
                      </TableCell>
                      <TableCell align="center">
                        <Tooltip title="Edit Product">
                          <IconButton
                            size="small"
                            onClick={() => navigate(`/products/${product.id}`)}
                            sx={{
                              color: '#ff9800',
                              '&:hover': { bgcolor: alpha('#ff9800', 0.1) },
                            }}
                          >
                            <EditIcon fontSize="small" />
                          </IconButton>
                        </Tooltip>
                      </TableCell>
                    </TableRow>
                  ))
                )}
              </TableBody>
            </Table>
          </TableContainer>

          {/* Pagination */}
          <TablePagination
            component="div"
            count={products.length}
            page={page}
            onPageChange={(_, newPage) => setPage(newPage)}
            rowsPerPage={rowsPerPage}
            onRowsPerPageChange={(e) => {
              setRowsPerPage(parseInt(e.target.value, 10));
              setPage(0);
            }}
            rowsPerPageOptions={[5, 10, 25, 50]}
            sx={{
              borderTop: `1px solid ${dk ? 'rgba(255,255,255,0.06)' : '#e0e0e0'}`,
              '.MuiTablePagination-selectLabel, .MuiTablePagination-displayedRows': {
                color: dk ? 'rgba(255,255,255,0.6)' : 'text.secondary',
              },
            }}
          />
        </Card>
      )}
    </Box>
  );
};

export default ProductsListPage;
