/**
 * RetailPOSProductGrid.tsx — Fast visual product catalog for Retail POS
 *
 * Florist-optimized product catalog:
 * - Search bar with Barcode / SKU / Name matching
 * - Dynamic category chips
 * - Stock status filtering (All, In Stock, Low Stock)
 * - Responsive touch-friendly product tiles with stock indicators
 */

import React, { useState, useMemo, useRef, useEffect } from 'react';
import {
  Box,
  Typography,
  TextField,
  InputAdornment,
  Chip,
  IconButton,
  Card,
  CardActionArea,
  CardContent,
  CircularProgress,
  alpha,
  useTheme,
} from '@mui/material';
import {
  Search as SearchIcon,
  Clear as ClearIcon,
  CheckCircle as InStockIcon,
  WarningAmber as LowStockIcon,
  ErrorOutline as OutOfStockIcon,
  LocalOffer as TagIcon,
  QrCodeScanner as BarcodeIcon,
} from '@mui/icons-material';
import type { RetailPOSProduct } from './retailPos.api';
import { formatCurrency } from '../../../core/i18n';

interface RetailPOSProductGridProps {
  products: RetailPOSProduct[];
  loading: boolean;
  onAddToCart: (product: RetailPOSProduct) => void;
  searchQuery: string;
  onSearchChange: (query: string) => void;
  selectedCategory: string;
  onCategoryChange: (category: string) => void;
}

export const RetailPOSProductGrid: React.FC<RetailPOSProductGridProps> = ({
  products,
  loading,
  onAddToCart,
  searchQuery,
  onSearchChange,
  selectedCategory,
  onCategoryChange,
}) => {
  const theme = useTheme();
  const searchInputRef = useRef<HTMLInputElement>(null);
  const [stockFilter, setStockFilter] = useState<'all' | 'in_stock' | 'low_stock'>('all');

  // Extract unique categories
  const categories = useMemo(() => {
    const set = new Set<string>();
    for (const p of products) {
      if (p.categoryName && p.categoryName.trim()) {
        set.add(p.categoryName.trim());
      }
    }
    return ['All', ...Array.from(set).sort()];
  }, [products]);

  // Filter products by category, search text, and stock status
  const filteredProducts = useMemo(() => {
    const q = searchQuery.trim().toLowerCase();

    return products.filter((p) => {
      // Category match
      if (selectedCategory !== 'All' && (p.categoryName || 'General') !== selectedCategory) {
        return false;
      }

      // Stock status filter
      if (stockFilter === 'in_stock') {
        if (p.trackInventory && p.stockQuantity <= 0) return false;
      } else if (stockFilter === 'low_stock') {
        if (!p.trackInventory) return false;
        const minStock = p.minimumStockLevel ?? 5;
        if (p.stockQuantity <= 0 || p.stockQuantity > minStock) return false;
      }

      // Text / barcode / SKU match
      if (!q) return true;
      const nameMatch = p.name.toLowerCase().includes(q);
      const skuMatch = p.sku.toLowerCase().includes(q);
      const barcodeMatch = p.barcode ? p.barcode.toLowerCase().includes(q) : false;

      return nameMatch || skuMatch || barcodeMatch;
    });
  }, [products, searchQuery, selectedCategory, stockFilter]);

  // Auto-focus search input on keyboard shortcut (F2)
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'F2') {
        e.preventDefault();
        searchInputRef.current?.focus();
        searchInputRef.current?.select();
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, []);

  return (
    <Box sx={{ display: 'flex', flexDirection: 'column', height: '100%', gap: 1.5 }}>
      {/* Search & Stock Filter Row */}
      <Box sx={{ display: 'flex', gap: 1, flexWrap: 'wrap', alignItems: 'center' }}>
        <TextField
          inputRef={searchInputRef}
          placeholder="Search products or scan barcode (F2)..."
          size="small"
          value={searchQuery}
          onChange={(e) => onSearchChange(e.target.value)}
          sx={{
            flex: 1,
            minWidth: 220,
            bgcolor: 'background.paper',
            '& .MuiOutlinedInput-root': {
              borderRadius: 2,
            },
          }}
          InputProps={{
            startAdornment: (
              <InputAdornment position="start">
                <SearchIcon color="action" fontSize="small" />
              </InputAdornment>
            ),
            endAdornment: searchQuery ? (
              <InputAdornment position="end">
                <IconButton size="small" onClick={() => onSearchChange('')}>
                  <ClearIcon fontSize="small" />
                </IconButton>
              </InputAdornment>
            ) : (
              <InputAdornment position="end">
                <BarcodeIcon fontSize="small" sx={{ color: 'text.disabled' }} />
              </InputAdornment>
            ),
          }}
        />

        <Box sx={{ display: 'flex', gap: 0.5 }}>
          <Chip
            label="All Stock"
            size="small"
            clickable
            color={stockFilter === 'all' ? 'primary' : 'default'}
            variant={stockFilter === 'all' ? 'filled' : 'outlined'}
            onClick={() => setStockFilter('all')}
            sx={{ fontWeight: 600 }}
          />
          <Chip
            label="In Stock"
            size="small"
            clickable
            color={stockFilter === 'in_stock' ? 'success' : 'default'}
            variant={stockFilter === 'in_stock' ? 'filled' : 'outlined'}
            onClick={() => setStockFilter('in_stock')}
            sx={{ fontWeight: 600 }}
          />
          <Chip
            label="Low Stock"
            size="small"
            clickable
            color={stockFilter === 'low_stock' ? 'warning' : 'default'}
            variant={stockFilter === 'low_stock' ? 'filled' : 'outlined'}
            onClick={() => setStockFilter('low_stock')}
            sx={{ fontWeight: 600 }}
          />
        </Box>
      </Box>

      {/* Category Pills */}
      <Box
        sx={{
          display: 'flex',
          gap: 0.75,
          overflowX: 'auto',
          pb: 0.5,
          '&::-webkit-scrollbar': { height: 4 },
          '&::-webkit-scrollbar-thumb': { bgcolor: 'divider', borderRadius: 2 },
        }}
      >
        {categories.map((cat) => {
          const isSelected = selectedCategory === cat;
          return (
            <Chip
              key={cat}
              label={cat}
              clickable
              color={isSelected ? 'primary' : 'default'}
              variant={isSelected ? 'filled' : 'outlined'}
              onClick={() => onCategoryChange(cat)}
              sx={{
                fontWeight: isSelected ? 700 : 500,
                borderRadius: 2,
                px: 0.5,
                bgcolor: isSelected ? undefined : 'background.paper',
              }}
            />
          );
        })}
      </Box>

      {/* Product Grid */}
      <Box
        sx={{
          flex: 1,
          overflowY: 'auto',
          pr: 0.5,
          minHeight: 380,
          '&::-webkit-scrollbar': { width: 6 },
          '&::-webkit-scrollbar-thumb': { bgcolor: 'divider', borderRadius: 3 },
        }}
      >
        {loading ? (
          <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', py: 8 }}>
            <CircularProgress size={36} />
            <Typography variant="body2" color="text.secondary" sx={{ mt: 2 }}>
              Loading products...
            </Typography>
          </Box>
        ) : filteredProducts.length === 0 ? (
          <Box
            sx={{
              display: 'flex',
              flexDirection: 'column',
              alignItems: 'center',
              justifyContent: 'center',
              py: 8,
              bgcolor: 'background.paper',
              borderRadius: 2,
              border: '1px dashed',
              borderColor: 'divider',
            }}
          >
            <TagIcon sx={{ fontSize: 48, color: 'text.disabled', mb: 1 }} />
            <Typography variant="subtitle1" fontWeight={600} color="text.secondary">
              No products found
            </Typography>
            <Typography variant="caption" color="text.secondary">
              Try adjusting your search query or category filter
            </Typography>
          </Box>
        ) : (
          <Box
            sx={{
              display: 'grid',
              gridTemplateColumns: {
                xs: 'repeat(2, 1fr)',
                sm: 'repeat(3, 1fr)',
                md: 'repeat(3, 1fr)',
                lg: 'repeat(4, 1fr)',
              },
              gap: 1.5,
            }}
          >
            {filteredProducts.map((product) => {
              const isOutOfStock = product.trackInventory && product.stockQuantity <= 0;
              const isLowStock =
                product.trackInventory &&
                product.stockQuantity > 0 &&
                product.stockQuantity <= (product.minimumStockLevel ?? 5);

              return (
                <Card
                  key={product.id}
                  variant="outlined"
                  sx={{
                    borderRadius: 2,
                    transition: 'transform 0.15s ease, box-shadow 0.15s ease',
                    bgcolor: 'background.paper',
                    opacity: isOutOfStock ? 0.75 : 1,
                    '&:hover': {
                      transform: 'translateY(-2px)',
                      boxShadow: '0 4px 12px rgba(0,0,0,0.08)',
                      borderColor: 'primary.main',
                    },
                  }}
                >
                  <CardActionArea
                    onClick={() => onAddToCart(product)}
                    sx={{ height: '100%', p: 0.5, display: 'flex', flexDirection: 'column', alignItems: 'stretch' }}
                  >
                    <CardContent sx={{ p: 1.5, flex: 1, display: 'flex', flexDirection: 'column' }}>
                      {/* Category & Stock Tag */}
                      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', mb: 1 }}>
                        <Typography
                          variant="caption"
                          color="text.secondary"
                          fontWeight={600}
                          sx={{
                            textTransform: 'uppercase',
                            fontSize: '0.65rem',
                            letterSpacing: 0.5,
                            maxWidth: '55%',
                            whiteSpace: 'nowrap',
                            overflow: 'hidden',
                            textOverflow: 'ellipsis',
                          }}
                        >
                          {product.categoryName || 'General'}
                        </Typography>

                        {/* Stock status indicator */}
                        {!product.trackInventory ? (
                          <Chip
                            label="Service"
                            size="small"
                            sx={{ height: 18, fontSize: '0.625rem', bgcolor: 'action.selected' }}
                          />
                        ) : isOutOfStock ? (
                          <Chip
                            icon={<OutOfStockIcon sx={{ fontSize: '11px !important' }} />}
                            label="0 Left"
                            size="small"
                            color="error"
                            variant="filled"
                            sx={{ height: 18, fontSize: '0.625rem', fontWeight: 700 }}
                          />
                        ) : isLowStock ? (
                          <Chip
                            icon={<LowStockIcon sx={{ fontSize: '11px !important' }} />}
                            label={`${product.stockQuantity} Left`}
                            size="small"
                            color="warning"
                            variant="filled"
                            sx={{ height: 18, fontSize: '0.625rem', fontWeight: 700 }}
                          />
                        ) : (
                          <Chip
                            icon={<InStockIcon sx={{ fontSize: '11px !important' }} />}
                            label={`${product.stockQuantity}`}
                            size="small"
                            color="success"
                            variant="outlined"
                            sx={{ height: 18, fontSize: '0.625rem', fontWeight: 600 }}
                          />
                        )}
                      </Box>

                      {/* Product Name */}
                      <Typography
                        variant="subtitle2"
                        fontWeight={700}
                        sx={{
                          lineHeight: 1.3,
                          mb: 0.5,
                          display: '-webkit-box',
                          WebkitLineClamp: 2,
                          WebkitBoxOrient: 'vertical',
                          overflow: 'hidden',
                          minHeight: '2.6em',
                        }}
                      >
                        {product.name}
                      </Typography>

                      {/* SKU / Barcode */}
                      <Typography variant="caption" color="text.secondary" sx={{ mb: 1, fontSize: '0.7rem' }}>
                        {product.sku || (product.barcode ? `BC: ${product.barcode}` : '')}
                      </Typography>

                      {/* Price Bottom */}
                      <Box sx={{ mt: 'auto', pt: 0.5, display: 'flex', alignItems: 'baseline', justifyContent: 'space-between' }}>
                        <Typography variant="h6" fontWeight={800} color="primary.main" sx={{ fontSize: '1.05rem' }}>
                          {formatCurrency(product.price)}
                        </Typography>
                        {product.trackBatch && (
                          <Typography variant="caption" color="info.main" fontWeight={600} sx={{ fontSize: '0.65rem' }}>
                            Batch
                          </Typography>
                        )}
                      </Box>
                    </CardContent>
                  </CardActionArea>
                </Card>
              );
            })}
          </Box>
        )}
      </Box>
    </Box>
  );
};

export default RetailPOSProductGrid;
