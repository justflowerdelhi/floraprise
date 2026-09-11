/**
 * RetailStockCard.tsx — Floraprise ERP Retail View Inventory Stock Card
 *
 * Designed specifically for retail florists:
 * - Prominent display of current stock level and unit of measure
 * - Authoritative color-coded stock status chips (In Stock, Low Stock, Out of Stock, Untracked)
 * - Uses authoritative domain low-stock rule: StockQuantity <= MinimumStockLevel
 * - Quick action buttons: + Stock In, - Stock Out, Wastage, Adjust, History
 * - Clear badges for TrackBatch and TrackInventory
 * - Gracefully disables stock operations if product is untracked
 */

import React from 'react';
import {
  Card,
  CardContent,
  Box,
  Typography,
  Chip,
  IconButton,
  Tooltip,
  Button,
  useTheme,
  alpha,
  Divider,
} from '@mui/material';
import {
  Add as AddIcon,
  Remove as RemoveIcon,
  DeleteOutline as WastageIcon,
  Tune as AdjustIcon,
  History as HistoryIcon,
  WarningAmber as WarningIcon,
  ErrorOutline as OutOfStockIcon,
  CheckCircleOutline as InStockIcon,
  Layers as BatchIcon,
  RemoveShoppingCart as UntrackedIcon,
} from '@mui/icons-material';

export interface RetailStockItem {
  id: string;
  name: string;
  sku: string;
  barcode: string | null;
  manufacturerBarcode: string | null;
  internalBarcode: string | null;
  category: string;
  categoryId: string | null;
  unitOfMeasure: string;
  retailPrice: number;
  costPrice: number;
  stockQuantity: number;
  minimumStockLevel: number;
  reorderLevel: number;
  isLowStock: boolean;
  needsReorder: boolean;
  trackInventory: boolean;
  trackBatch: boolean;
  isActive: boolean;
  description: string | null;
}

export type StockStatus = 'in_stock' | 'low_stock' | 'out_of_stock' | 'untracked';

/**
 * Authoritative Floraprise Low-Stock Rule:
 * 1. Untracked: !trackInventory
 * 2. Out of Stock: stockQuantity <= 0
 * 3. Low Stock: isLowStock flag from domain OR (minimumStockLevel > 0 && stockQuantity <= minimumStockLevel)
 * 4. In Stock: stockQuantity > minimumStockLevel
 * Note: reorderLevel is a separate replenishment trigger, NOT the low-stock safety threshold.
 */
export function getStockStatus(item: RetailStockItem): StockStatus {
  if (!item.trackInventory) return 'untracked';
  if (item.stockQuantity <= 0) return 'out_of_stock';
  if (item.isLowStock) return 'low_stock';
  if (item.minimumStockLevel > 0 && item.stockQuantity <= item.minimumStockLevel) return 'low_stock';
  return 'in_stock';
}

interface RetailStockCardProps {
  item: RetailStockItem;
  currencySymbol: string;
  onStockAction: (
    item: RetailStockItem,
    action: 'purchase' | 'sale' | 'wastage' | 'adjustment',
  ) => void;
  onViewHistory: (item: RetailStockItem) => void;
}

export const RetailStockCard: React.FC<RetailStockCardProps> = ({
  item,
  currencySymbol,
  onStockAction,
  onViewHistory,
}) => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';
  const status = getStockStatus(item);

  const statusConfig = {
    in_stock: {
      label: 'In Stock',
      color: theme.palette.success.main,
      bg: dk ? alpha(theme.palette.success.main, 0.18) : '#E8F5E9',
      border: dk ? alpha(theme.palette.success.main, 0.35) : '#C8E6C9',
      icon: <InStockIcon sx={{ fontSize: 16 }} />,
    },
    low_stock: {
      label: 'Low Stock',
      color: theme.palette.warning.main,
      bg: dk ? alpha(theme.palette.warning.main, 0.18) : '#FFF3E0',
      border: dk ? alpha(theme.palette.warning.main, 0.35) : '#FFE0B2',
      icon: <WarningIcon sx={{ fontSize: 16 }} />,
    },
    out_of_stock: {
      label: 'Out of Stock',
      color: theme.palette.error.main,
      bg: dk ? alpha(theme.palette.error.main, 0.18) : '#FFEBEE',
      border: dk ? alpha(theme.palette.error.main, 0.35) : '#FFCDD2',
      icon: <OutOfStockIcon sx={{ fontSize: 16 }} />,
    },
    untracked: {
      label: 'Untracked',
      color: theme.palette.text.secondary,
      bg: dk ? alpha(theme.palette.action.disabledBackground, 0.2) : '#F5F5F5',
      border: dk ? alpha(theme.palette.divider, 0.4) : '#E0E0E0',
      icon: <UntrackedIcon sx={{ fontSize: 16 }} />,
    },
  }[status];

  return (
    <Card
      elevation={0}
      sx={{
        borderRadius: 3,
        border: '1px solid',
        borderColor: dk ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.08)',
        backgroundColor: dk ? 'background.paper' : '#FFFFFF',
        transition: 'all 0.2s cubic-bezier(0.4, 0, 0.2, 1)',
        display: 'flex',
        flexDirection: 'column',
        height: '100%',
        '&:hover': {
          borderColor: theme.palette.primary.main,
          boxShadow: dk
            ? '0 6px 20px rgba(0,0,0,0.4)'
            : '0 6px 20px rgba(46,125,50,0.12)',
          transform: 'translateY(-2px)',
        },
      }}
    >
      <CardContent sx={{ p: 2.5, flexGrow: 1, display: 'flex', flexDirection: 'column' }}>
        {/* Top Header: Category & History Button */}
        <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', mb: 1 }}>
          <Box sx={{ display: 'flex', gap: 0.8, alignItems: 'center', flexWrap: 'wrap' }}>
            <Chip
              label={item.category || 'Other'}
              size="small"
              sx={{
                fontSize: '0.72rem',
                fontWeight: 600,
                height: 22,
                borderRadius: 1.5,
                bgcolor: dk ? 'rgba(255,255,255,0.06)' : '#F0F4F8',
                color: theme.palette.text.secondary,
              }}
            />
            {item.trackBatch && (
              <Tooltip title="Batch Tracked Product (FIFO / Expiry monitored)">
                <Chip
                  icon={<BatchIcon sx={{ fontSize: '13px !important' }} />}
                  label="Batches"
                  size="small"
                  color="primary"
                  variant="outlined"
                  sx={{
                    fontSize: '0.7rem',
                    fontWeight: 600,
                    height: 22,
                    borderRadius: 1.5,
                  }}
                />
              </Tooltip>
            )}
          </Box>

          <Tooltip title="View Stock Movement History">
            <IconButton
              size="small"
              onClick={() => onViewHistory(item)}
              sx={{
                color: theme.palette.text.secondary,
                '&:hover': {
                  color: theme.palette.primary.main,
                  bgcolor: alpha(theme.palette.primary.main, 0.08),
                },
              }}
            >
              <HistoryIcon fontSize="small" />
            </IconButton>
          </Tooltip>
        </Box>

        {/* Product Name */}
        <Typography
          variant="subtitle1"
          fontWeight={700}
          sx={{
            lineHeight: 1.3,
            mb: 0.5,
            color: item.isActive ? 'text.primary' : 'text.disabled',
            display: '-webkit-box',
            WebkitLineClamp: 2,
            WebkitBoxOrient: 'vertical',
            overflow: 'hidden',
          }}
        >
          {item.name}
        </Typography>

        {/* SKU & Barcode */}
        <Box sx={{ display: 'flex', gap: 1.5, alignItems: 'center', mb: 2 }}>
          <Typography variant="caption" color="text.secondary" sx={{ fontFamily: 'monospace' }}>
            SKU: {item.sku}
          </Typography>
          {(item.barcode || item.manufacturerBarcode || item.internalBarcode) && (
            <Typography variant="caption" color="text.secondary" sx={{ fontFamily: 'monospace' }}>
              Barcode: {item.barcode || item.manufacturerBarcode || item.internalBarcode}
            </Typography>
          )}
        </Box>

        {/* Stock Level Display Area */}
        <Box
          sx={{
            p: 1.8,
            borderRadius: 2.5,
            bgcolor: statusConfig.bg,
            border: `1px solid ${statusConfig.border}`,
            mb: 2,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
          }}
        >
          <Box>
            <Typography
              variant="caption"
              fontWeight={600}
              sx={{ color: statusConfig.color, textTransform: 'uppercase', letterSpacing: 0.5 }}
            >
              Current Stock
            </Typography>
            <Box sx={{ display: 'flex', alignItems: 'baseline', gap: 0.8, mt: 0.2 }}>
              <Typography
                variant="h4"
                fontWeight={800}
                sx={{
                  color: statusConfig.color,
                  lineHeight: 1,
                }}
              >
                {item.trackInventory ? item.stockQuantity : '—'}
              </Typography>
              <Typography variant="body2" fontWeight={600} color="text.secondary">
                {item.trackInventory ? item.unitOfMeasure : 'Untracked'}
              </Typography>
            </Box>
          </Box>

          <Chip
            icon={statusConfig.icon}
            label={statusConfig.label}
            size="small"
            sx={{
              fontWeight: 700,
              fontSize: '0.75rem',
              color: statusConfig.color,
              bgcolor: dk ? alpha(statusConfig.color, 0.2) : '#FFFFFF',
              borderColor: statusConfig.border,
              border: '1px solid',
            }}
          />
        </Box>

        {/* Reorder Threshold & Unit Cost Details */}
        <Box
          sx={{
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center',
            mt: 'auto',
            pt: 0.5,
            pb: 1.5,
          }}
        >
          <Typography variant="caption" color="text.secondary">
            {item.trackInventory ? (
              <>
                Min Level:{' '}
                <strong>
                  {item.minimumStockLevel > 0
                    ? `${item.minimumStockLevel} ${item.unitOfMeasure}`
                    : 'Not set'}
                </strong>
                {item.reorderLevel > 0 && (
                  <span style={{ marginLeft: 8, opacity: 0.8 }}>
                    (Reorder: {item.reorderLevel})
                  </span>
                )}
              </>
            ) : (
              'Inventory tracking disabled'
            )}
          </Typography>
          <Typography variant="caption" color="text.secondary">
            Cost:{' '}
            <strong>
              {currencySymbol}
              {item.costPrice.toFixed(2)}
            </strong>
          </Typography>
        </Box>

        <Divider sx={{ my: 1, borderColor: dk ? 'rgba(255,255,255,0.06)' : 'rgba(0,0,0,0.06)' }} />

        {/* Quick Action Buttons */}
        <Box sx={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 0.8, pt: 0.5 }}>
          <Tooltip
            title={
              !item.trackInventory
                ? 'Inventory tracking is disabled for this product'
                : 'Stock In (Purchase / Inbound receipt)'
            }
          >
            <span>
              <Button
                size="small"
                variant="outlined"
                color="success"
                disabled={!item.trackInventory}
                onClick={() => onStockAction(item, 'purchase')}
                sx={{
                  minWidth: 0,
                  width: '100%',
                  px: 0.5,
                  py: 0.6,
                  fontSize: '0.75rem',
                  fontWeight: 700,
                  borderRadius: 2,
                  display: 'flex',
                  flexDirection: 'column',
                  gap: 0.2,
                }}
              >
                <AddIcon sx={{ fontSize: 16 }} />
                + In
              </Button>
            </span>
          </Tooltip>

          <Tooltip
            title={
              !item.trackInventory
                ? 'Inventory tracking is disabled for this product'
                : 'Stock Out (Manual Sale / Reduction)'
            }
          >
            <span>
              <Button
                size="small"
                variant="outlined"
                color="info"
                disabled={!item.trackInventory || item.stockQuantity <= 0}
                onClick={() => onStockAction(item, 'sale')}
                sx={{
                  minWidth: 0,
                  width: '100%',
                  px: 0.5,
                  py: 0.6,
                  fontSize: '0.75rem',
                  fontWeight: 700,
                  borderRadius: 2,
                  display: 'flex',
                  flexDirection: 'column',
                  gap: 0.2,
                }}
              >
                <RemoveIcon sx={{ fontSize: 16 }} />
                - Out
              </Button>
            </span>
          </Tooltip>

          <Tooltip
            title={
              !item.trackInventory
                ? 'Inventory tracking is disabled for this product'
                : 'Record Wastage (Damaged, wilted, or expired flowers)'
            }
          >
            <span>
              <Button
                size="small"
                variant="outlined"
                color="error"
                disabled={!item.trackInventory || item.stockQuantity <= 0}
                onClick={() => onStockAction(item, 'wastage')}
                sx={{
                  minWidth: 0,
                  width: '100%',
                  px: 0.5,
                  py: 0.6,
                  fontSize: '0.72rem',
                  fontWeight: 700,
                  borderRadius: 2,
                  display: 'flex',
                  flexDirection: 'column',
                  gap: 0.2,
                }}
              >
                <WastageIcon sx={{ fontSize: 16 }} />
                Waste
              </Button>
            </span>
          </Tooltip>

          <Tooltip
            title={
              !item.trackInventory
                ? 'Inventory tracking is disabled for this product'
                : 'Stock Adjustment (Physical count correction)'
            }
          >
            <span>
              <Button
                size="small"
                variant="outlined"
                color="secondary"
                disabled={!item.trackInventory}
                onClick={() => onStockAction(item, 'adjustment')}
                sx={{
                  minWidth: 0,
                  width: '100%',
                  px: 0.5,
                  py: 0.6,
                  fontSize: '0.72rem',
                  fontWeight: 700,
                  borderRadius: 2,
                  display: 'flex',
                  flexDirection: 'column',
                  gap: 0.2,
                }}
              >
                <AdjustIcon sx={{ fontSize: 16 }} />
                Adjust
              </Button>
            </span>
          </Tooltip>
        </Box>
      </CardContent>
    </Card>
  );
};
