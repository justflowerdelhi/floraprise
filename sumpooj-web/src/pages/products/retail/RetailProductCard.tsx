/**
 * RetailProductCard.tsx — Floraprise ERP Retail View Product Card
 *
 * Florist-friendly product card for fast operational retail usage:
 * - Clear pricing and stock visibility
 * - Category and Unit of Measure badges
 * - Visual stock status (In Stock, Low Stock, Out of Stock, Untracked)
 * - Quick actions: Edit, Print Barcode, Activate/Deactivate
 */

import React, { useState } from 'react';
import {
  Card,
  CardContent,
  Box,
  Typography,
  Chip,
  IconButton,
  Tooltip,
  Menu,
  MenuItem,
  ListItemIcon,
  ListItemText,
  useTheme,
  alpha,
  Divider,
} from '@mui/material';
import {
  Edit as EditIcon,
  Print as PrintIcon,
  MoreVert as MoreVertIcon,
  CheckCircle as ActiveIcon,
  Block as DeactivateIcon,
  QrCode as BarcodeIcon,
  Inventory2 as BatchIcon,
} from '@mui/icons-material';

export interface RetailProductItem {
  id: string;
  name: string;
  sku: string;
  barcode?: string | null;
  manufacturerBarcode?: string | null;
  internalBarcode?: string | null;
  category: string;
  categoryId?: string | null;
  unitOfMeasure: string;
  retailPrice: number;
  costPrice: number;
  stockQuantity: number;
  reorderLevel: number;
  trackInventory: boolean;
  trackBatch: boolean;
  isActive: boolean;
  description?: string | null;
}

interface RetailProductCardProps {
  product: RetailProductItem;
  currencySymbol?: string;
  onEdit: (product: RetailProductItem) => void;
  onPrintBarcode: (product: RetailProductItem) => void;
  onToggleStatus: (product: RetailProductItem) => void;
}

export const RetailProductCard: React.FC<RetailProductCardProps> = ({
  product,
  currencySymbol = '$',
  onEdit,
  onPrintBarcode,
  onToggleStatus,
}) => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';

  const [menuAnchor, setMenuAnchor] = useState<null | HTMLElement>(null);
  const menuOpen = Boolean(menuAnchor);

  const handleMenuOpen = (e: React.MouseEvent<HTMLElement>) => {
    e.stopPropagation();
    setMenuAnchor(e.currentTarget);
  };

  const handleMenuClose = () => {
    setMenuAnchor(null);
  };

  // Stock status determination
  const isOutOfStock = product.trackInventory && product.stockQuantity <= 0;
  const isLowStock =
    product.trackInventory &&
    product.stockQuantity > 0 &&
    product.stockQuantity <= (product.reorderLevel > 0 ? product.reorderLevel : 5);

  const stockColor = !product.trackInventory
    ? 'default'
    : isOutOfStock
    ? 'error'
    : isLowStock
    ? 'warning'
    : 'success';

  const stockLabel = !product.trackInventory
    ? 'Untracked'
    : isOutOfStock
    ? 'Out of Stock'
    : isLowStock
    ? `Low: ${product.stockQuantity} ${product.unitOfMeasure}`
    : `${product.stockQuantity} ${product.unitOfMeasure}`;

  const effectiveBarcode =
    product.manufacturerBarcode?.trim() ||
    product.barcode?.trim() ||
    product.internalBarcode?.trim() ||
    null;

  return (
    <Card
      elevation={0}
      sx={{
        borderRadius: 3,
        border: `1px solid ${
          !product.isActive
            ? dk
              ? 'rgba(255,255,255,0.08)'
              : '#e0e0e0'
            : dk
            ? 'rgba(255,255,255,0.12)'
            : '#e8eaed'
        }`,
        bgcolor: !product.isActive
          ? dk
            ? 'rgba(255,255,255,0.02)'
            : 'rgba(0,0,0,0.02)'
          : dk
          ? '#1e1e2d'
          : '#ffffff',
        opacity: product.isActive ? 1 : 0.75,
        display: 'flex',
        flexDirection: 'column',
        justifyContent: 'space-between',
        transition: 'transform 0.15s ease, box-shadow 0.15s ease, border-color 0.15s ease',
        '&:hover': {
          transform: product.isActive ? 'translateY(-2px)' : 'none',
          boxShadow: product.isActive
            ? dk
              ? '0 6px 20px rgba(0,0,0,0.4)'
              : '0 6px 20px rgba(0,0,0,0.08)'
            : 'none',
          borderColor: product.isActive ? theme.palette.primary.main : undefined,
        },
      }}
    >
      <CardContent sx={{ p: 2.5, pb: 1.5 }}>
        {/* Top Badges: Category & Stock status */}
        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 1.5, gap: 1 }}>
          <Chip
            size="small"
            label={product.category || 'Other'}
            sx={{
              fontWeight: 600,
              fontSize: '0.72rem',
              bgcolor: dk ? alpha(theme.palette.primary.main, 0.15) : alpha(theme.palette.primary.main, 0.08),
              color: theme.palette.primary.main,
              borderRadius: 1.5,
              maxWidth: 130,
            }}
          />

          <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.75 }}>
            {product.trackBatch && (
              <Tooltip title="Batch & Freshness Tracked" arrow>
                <Chip
                  size="small"
                  icon={<BatchIcon sx={{ fontSize: '13px !important' }} />}
                  label="Batch"
                  sx={{
                    fontWeight: 600,
                    fontSize: '0.68rem',
                    height: 22,
                    bgcolor: dk ? 'rgba(156,39,176,0.18)' : 'rgba(156,39,176,0.1)',
                    color: '#ab47bc',
                    borderRadius: 1,
                  }}
                />
              </Tooltip>
            )}

            <Chip
              size="small"
              color={stockColor}
              variant={product.trackInventory ? 'filled' : 'outlined'}
              label={stockLabel}
              sx={{
                fontWeight: 600,
                fontSize: '0.72rem',
                height: 22,
                borderRadius: 1.5,
              }}
            />
          </Box>
        </Box>

        {/* Product Name */}
        <Typography
          variant="subtitle1"
          sx={{
            fontWeight: 700,
            fontSize: '1rem',
            lineHeight: 1.3,
            color: dk ? '#ffffff' : '#1a1a2e',
            mb: 0.5,
            overflow: 'hidden',
            textOverflow: 'ellipsis',
            display: '-webkit-box',
            WebkitLineClamp: 2,
            WebkitBoxOrient: 'vertical',
            minHeight: '2.6em',
          }}
          title={product.name}
        >
          {product.name}
        </Typography>

        {/* SKU & Barcode snippet */}
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 2, flexWrap: 'wrap' }}>
          <Typography
            variant="caption"
            sx={{
              color: 'text.secondary',
              fontFamily: 'monospace',
              fontSize: '0.78rem',
              bgcolor: dk ? 'rgba(255,255,255,0.06)' : 'rgba(0,0,0,0.04)',
              px: 0.75,
              py: 0.25,
              borderRadius: 1,
            }}
          >
            SKU: {product.sku}
          </Typography>

          {effectiveBarcode && (
            <Tooltip title={`Barcode: ${effectiveBarcode}`} arrow>
              <Box sx={{ display: 'inline-flex', alignItems: 'center', gap: 0.35, color: 'text.secondary' }}>
                <BarcodeIcon sx={{ fontSize: 14 }} />
                <Typography variant="caption" sx={{ fontFamily: 'monospace', fontSize: '0.75rem' }}>
                  {effectiveBarcode.length > 10 ? `${effectiveBarcode.substring(0, 8)}...` : effectiveBarcode}
                </Typography>
              </Box>
            </Tooltip>
          )}
        </Box>

        <Divider sx={{ my: 1.5, borderColor: dk ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.06)' }} />

        {/* Pricing Info */}
        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-end' }}>
          <Box>
            <Typography variant="caption" sx={{ color: 'text.secondary', display: 'block', fontSize: '0.72rem' }}>
              Selling Price / {product.unitOfMeasure}
            </Typography>
            <Typography
              variant="h6"
              sx={{
                fontWeight: 800,
                color: '#2e7d32',
                lineHeight: 1.2,
                fontSize: '1.25rem',
              }}
            >
              {currencySymbol}
              {product.retailPrice.toFixed(2)}
            </Typography>
          </Box>

          <Box sx={{ textAlign: 'right' }}>
            <Typography variant="caption" sx={{ color: 'text.secondary', display: 'block', fontSize: '0.72rem' }}>
              Cost Price
            </Typography>
            <Typography
              variant="body2"
              sx={{
                fontWeight: 600,
                color: 'text.secondary',
                fontSize: '0.85rem',
              }}
            >
              {currencySymbol}
              {product.costPrice.toFixed(2)}
            </Typography>
          </Box>
        </Box>
      </CardContent>

      {/* Action Footer */}
      <Box
        sx={{
          px: 2,
          py: 1,
          bgcolor: dk ? 'rgba(0,0,0,0.2)' : 'rgba(0,0,0,0.02)',
          borderTop: `1px solid ${dk ? 'rgba(255,255,255,0.06)' : 'rgba(0,0,0,0.05)'}`,
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
        }}
      >
        <Typography
          variant="caption"
          sx={{
            fontWeight: 600,
            fontSize: '0.72rem',
            color: product.isActive ? '#2e7d32' : 'text.disabled',
          }}
        >
          {product.isActive ? 'Active' : 'Inactive'}
        </Typography>

        <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
          {effectiveBarcode && (
            <Tooltip title="Print Barcode Label" arrow>
              <IconButton size="small" onClick={() => onPrintBarcode(product)} sx={{ color: 'text.secondary' }}>
                <PrintIcon fontSize="small" />
              </IconButton>
            </Tooltip>
          )}

          <Tooltip title="Edit Product" arrow>
            <IconButton
              size="small"
              onClick={() => onEdit(product)}
              sx={{ color: theme.palette.primary.main }}
            >
              <EditIcon fontSize="small" />
            </IconButton>
          </Tooltip>

          <IconButton size="small" onClick={handleMenuOpen} sx={{ color: 'text.secondary' }}>
            <MoreVertIcon fontSize="small" />
          </IconButton>

          <Menu
            anchorEl={menuAnchor}
            open={menuOpen}
            onClose={handleMenuClose}
            transformOrigin={{ horizontal: 'right', vertical: 'top' }}
            anchorOrigin={{ horizontal: 'right', vertical: 'bottom' }}
          >
            <MenuItem
              onClick={() => {
                handleMenuClose();
                onToggleStatus(product);
              }}
            >
              <ListItemIcon>
                {product.isActive ? (
                  <DeactivateIcon fontSize="small" color="error" />
                ) : (
                  <ActiveIcon fontSize="small" color="success" />
                )}
              </ListItemIcon>
              <ListItemText primary={product.isActive ? 'Deactivate Product' : 'Activate Product'} />
            </MenuItem>
          </Menu>
        </Box>
      </Box>
    </Card>
  );
};
