/**
 * CartTable.tsx — Reusable cart line items table
 *
 * Shows: product, qty (+/-), unit price, discount, tax, line total, margin, warnings
 * Supports read-only mode for FTD orders (isPriceEditable = false)
 * Enhanced with line-item discount popover for quick discount application.
 */
import React, { useState } from 'react';
import {
  Table, TableBody, TableCell, TableContainer, TableHead, TableRow,
  IconButton, Typography, Box, Chip, Tooltip, Paper,
  useTheme, alpha, Button,
} from '@mui/material';
import {
  Add as AddIcon,
  Remove as RemoveIcon,
  Delete as DeleteIcon,
  WarningAmber as WarnIcon,
  AccessTime as ExpiryIcon,
  LocalOffer as DiscountIcon,
} from '@mui/icons-material';
import type { CartItem, Product, LineItemDiscount } from '../orders/OrderTypes';
import { fmtCurrency, fmtPercent } from './CartUtils';
import LineItemDiscountPopover from './LineItemDiscountPopover';

interface Props {
  items: CartItem[];
  products: Product[];
  isPriceEditable: boolean;
  onUpdateQty: (lineId: string, qty: number, product: Product) => void;
  onRemove: (lineId: string) => void;
  onSetDiscount: (lineId: string, pct: number, product: Product) => void;
  onSetLineDiscount?: (lineId: string, discount: LineItemDiscount | null, product: Product) => void;
  deliveryFee?: number;
}

const CartTable: React.FC<Props> = ({
  items, products, isPriceEditable, onUpdateQty, onRemove, onSetDiscount, onSetLineDiscount, deliveryFee,
}) => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';
  const deliveryFeeAmount = deliveryFee ?? 0;
  const showDeliveryFee = deliveryFeeAmount > 0;

  // Popover state for line-item discount
  const [discountAnchor, setDiscountAnchor] = useState<HTMLElement | null>(null);
  const [selectedItem, setSelectedItem] = useState<CartItem | null>(null);

  const handleOpenDiscount = (e: React.MouseEvent<HTMLElement>, item: CartItem) => {
    setDiscountAnchor(e.currentTarget);
    setSelectedItem(item);
  };

  const handleCloseDiscount = () => {
    setDiscountAnchor(null);
    setSelectedItem(null);
  };

  const handleApplyDiscount = (discount: LineItemDiscount | null) => {
    if (!selectedItem) return;
    const prod = findProduct(selectedItem.productId);
    if (!prod) return;

    if (onSetLineDiscount) {
      onSetLineDiscount(selectedItem.id, discount, prod);
    } else {
      // Fallback to legacy percentage-based discount
      onSetDiscount(selectedItem.id, discount?.type === 'PERCENT' ? discount.value : 0, prod);
    }
  };

  const findProduct = (pid: string) => products.find((p) => p.id === pid);

  const headerSx = {
    fontWeight: 700, fontSize: '0.7rem', textTransform: 'uppercase' as const,
    letterSpacing: 0.5, py: 1,
    color: dk ? 'rgba(255,255,255,0.6)' : 'text.secondary',
    bgcolor: dk ? '#111122' : '#fafafa',
    borderBottom: `2px solid ${dk ? 'rgba(255,255,255,0.08)' : '#eee'}`,
  };

  if (items.length === 0) {
    return (
      <Box sx={{ py: 8, textAlign: 'center' }}>
        <Typography variant="body1" color="text.secondary" sx={{ fontSize: '1rem' }}>
          Cart is empty — add products to begin
        </Typography>
      </Box>
    );
  }

  return (
    <TableContainer
      component={Paper}
      elevation={dk ? 0 : 1}
      sx={{
        bgcolor: dk ? '#0f0f0f' : '#fff',
        border: dk ? '1px solid rgba(255,255,255,0.08)' : 'none',
        borderRadius: 2,
      }}
    >
      <Table size="small">
        <TableHead>
          <TableRow>
            <TableCell sx={headerSx}>Product</TableCell>
            <TableCell sx={headerSx} align="center">Qty</TableCell>
            <TableCell sx={headerSx} align="right">Price</TableCell>
            <TableCell sx={headerSx} align="right">Disc%</TableCell>
            <TableCell sx={headerSx} align="right">Tax</TableCell>
            <TableCell sx={headerSx} align="right">Total</TableCell>
            <TableCell sx={headerSx} align="right">Margin</TableCell>
            <TableCell sx={headerSx} align="center" width={50}></TableCell>
          </TableRow>
        </TableHead>
        <TableBody>
          {items.map((item) => {
            const prod = findProduct(item.productId);
            return (
              <TableRow
                key={item.id}
                sx={{
                  transition: 'all 0.15s ease-out',
                  '&:hover': {
                    bgcolor: dk ? alpha('#fff', 0.05) : alpha('#000', 0.03),
                    transform: 'scale(1.005)',
                  },
                }}
              >
                {/* Product */}
                <TableCell>
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                    <Box>
                      <Typography variant="body2" sx={{ fontWeight: 600, fontSize: '0.85rem' }}>
                        {item.productName}
                      </Typography>
                      <Typography variant="caption" sx={{ color: dk ? 'rgba(255,255,255,0.4)' : 'text.disabled' }}>
                        {item.sku}
                      </Typography>
                    </Box>
                    {item.expiryWarning && (
                      <Tooltip title="Batch expiring within 3 days!" arrow>
                        <ExpiryIcon sx={{ fontSize: 16, color: theme.palette.warning.main }} />
                      </Tooltip>
                    )}
                    {item.stockWarning && (
                      <Tooltip title="Quantity exceeds available stock" arrow>
                        <WarnIcon sx={{ fontSize: 16, color: theme.palette.error.main }} />
                      </Tooltip>
                    )}
                  </Box>
                </TableCell>

                {/* Qty */}
                <TableCell align="center">
                  <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 0.75 }}>
                    <IconButton
                      size="medium"
                      onClick={() => prod && onUpdateQty(item.id, item.quantity - 1, prod)}
                      sx={{
                        width: 40,
                        height: 40,
                        bgcolor: dk ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.04)',
                        transition: 'all 0.15s',
                        '&:hover': {
                          bgcolor: dk ? 'rgba(255,255,255,0.15)' : 'rgba(0,0,0,0.08)',
                          transform: 'scale(1.1)',
                        },
                      }}
                    >
                      <RemoveIcon sx={{ fontSize: 20 }} />
                    </IconButton>
                    <Typography
                      variant="body2"
                      sx={{
                        fontWeight: 700,
                        minWidth: 32,
                        textAlign: 'center',
                        fontSize: '1rem',
                        cursor: 'pointer',
                        px: 1,
                        py: 0.5,
                        borderRadius: 1,
                        '&:hover': {
                          bgcolor: dk ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.04)',
                        },
                      }}
                    >
                      {item.quantity}
                    </Typography>
                    <IconButton
                      size="medium"
                      onClick={() => prod && onUpdateQty(item.id, item.quantity + 1, prod)}
                      sx={{
                        width: 40,
                        height: 40,
                        bgcolor: dk ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.04)',
                        transition: 'all 0.15s',
                        '&:hover': {
                          bgcolor: dk ? 'rgba(255,255,255,0.15)' : 'rgba(0,0,0,0.08)',
                          transform: 'scale(1.1)',
                        },
                      }}
                    >
                      <AddIcon sx={{ fontSize: 20 }} />
                    </IconButton>
                  </Box>
                </TableCell>

                {/* Price */}
                <TableCell align="right">
                  <Typography variant="body2">{fmtCurrency(item.unitPrice)}</Typography>
                </TableCell>

                {/* Discount */}
                <TableCell align="right">
                  {isPriceEditable ? (
                    (() => {
                      const hasDiscount = item.discountAmount > 0;
                      const discountLabel = item.lineDiscount
                        ? item.lineDiscount.type === 'PERCENT'
                          ? `${item.lineDiscount.value}%`
                          : fmtCurrency(item.lineDiscount.value)
                        : item.discountPercent > 0
                          ? `${item.discountPercent}%`
                          : '';
                      return (
                        <Button
                          size="small"
                          variant={hasDiscount ? 'contained' : 'outlined'}
                          color={hasDiscount ? 'success' : 'inherit'}
                          onClick={(e) => handleOpenDiscount(e, item)}
                          startIcon={<DiscountIcon sx={{ fontSize: 14 }} />}
                          sx={{
                            minWidth: 50,
                            minHeight: 32,
                            fontWeight: 700,
                            fontSize: '0.75rem',
                            textTransform: 'none',
                            px: 1,
                            py: 0.25,
                            borderRadius: 1.5,
                            transition: 'all 0.12s ease-out',
                            ...(hasDiscount
                              ? {
                                  bgcolor: dk ? 'rgba(76,175,80,0.25)' : undefined,
                                  color: dk ? '#81c784' : undefined,
                                  '&:hover': {
                                    bgcolor: dk ? 'rgba(76,175,80,0.35)' : undefined,
                                  },
                                }
                              : {
                                  borderColor: dk ? 'rgba(255,255,255,0.2)' : undefined,
                                  color: dk ? 'rgba(255,255,255,0.6)' : 'text.secondary',
                                  '&:hover': {
                                    borderColor: dk ? 'rgba(255,255,255,0.4)' : undefined,
                                    bgcolor: dk ? 'rgba(255,255,255,0.05)' : 'rgba(0,0,0,0.04)',
                                  },
                                }),
                          }}
                        >
                          {hasDiscount ? discountLabel : '%'}
                        </Button>
                      );
                    })()
                  ) : (
                    <Typography variant="body2" sx={{ fontSize: '0.82rem' }}>
                      {item.discountPercent > 0 ? `${item.discountPercent}%` : '-'}
                    </Typography>
                  )}
                </TableCell>

                {/* Tax */}
                <TableCell align="right">
                  <Typography variant="body2" sx={{ fontSize: '0.82rem' }}>
                    {fmtCurrency(item.taxAmount)}
                  </Typography>
                </TableCell>

                {/* Line total */}
                <TableCell align="right">
                  {item.discountAmount > 0 ? (
                    <Box>
                      <Typography
                        variant="caption"
                        sx={{
                          textDecoration: 'line-through',
                          color: dk ? 'rgba(255,255,255,0.4)' : 'text.disabled',
                          display: 'block',
                          fontSize: '0.7rem',
                        }}
                      >
                        {fmtCurrency(item.unitPrice * item.quantity)}
                      </Typography>
                      <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5, justifyContent: 'flex-end' }}>
                        <Typography variant="body2" sx={{ fontWeight: 700, color: theme.palette.success.main }}>
                          {fmtCurrency(item.lineTotal)}
                        </Typography>
                      </Box>
                    </Box>
                  ) : (
                    <Typography variant="body2" sx={{ fontWeight: 700 }}>
                      {fmtCurrency(item.lineTotal)}
                    </Typography>
                  )}
                </TableCell>

                {/* Margin */}
                <TableCell align="right">
                  <Chip
                    label={fmtPercent(item.marginPercent)}
                    size="small"
                    color={item.marginPercent < 20 ? 'error' : item.marginPercent < 35 ? 'warning' : 'success'}
                    variant={dk ? 'outlined' : 'filled'}
                    sx={{ fontWeight: 700, fontSize: '0.7rem' }}
                  />
                </TableCell>

                {/* Delete */}
                <TableCell align="center">
                  <IconButton
                    size="medium"
                    color="error"
                    onClick={() => onRemove(item.id)}
                    sx={{
                      width: 40,
                      height: 40,
                      transition: 'all 0.15s',
                      '&:hover': {
                        bgcolor: 'rgba(239,68,68,0.1)',
                        transform: 'scale(1.1)',
                      },
                    }}
                  >
                    <DeleteIcon sx={{ fontSize: 20 }} />
                  </IconButton>
                </TableCell>
              </TableRow>
            );
          })}
          {showDeliveryFee && (
            <TableRow
              sx={{
                bgcolor: dk ? alpha(theme.palette.primary.main, 0.08) : alpha(theme.palette.primary.main, 0.04),
              }}
            >
              <TableCell>
                <Typography variant="body2" sx={{ fontWeight: 700, fontSize: '0.85rem' }}>
                  Delivery Fee
                </Typography>
              </TableCell>
              <TableCell align="center">
                <Typography variant="body2" color="text.secondary">-</Typography>
              </TableCell>
              <TableCell align="right">
                <Typography variant="body2" color="text.secondary">-</Typography>
              </TableCell>
              <TableCell align="right">
                <Typography variant="body2" color="text.secondary">-</Typography>
              </TableCell>
              <TableCell align="right">
                <Typography variant="body2" color="text.secondary">-</Typography>
              </TableCell>
              <TableCell align="right">
                <Typography variant="body2" sx={{ fontWeight: 700 }}>
                  {fmtCurrency(deliveryFeeAmount)}
                </Typography>
              </TableCell>
              <TableCell align="right">
                <Typography variant="body2" color="text.secondary">-</Typography>
              </TableCell>
              <TableCell align="center"></TableCell>
            </TableRow>
          )}
        </TableBody>
      </Table>

      {/* Line Item Discount Popover */}
      {selectedItem && (
        <LineItemDiscountPopover
          anchorEl={discountAnchor}
          open={Boolean(discountAnchor)}
          onClose={handleCloseDiscount}
          onApply={handleApplyDiscount}
          currentDiscount={selectedItem.lineDiscount}
          lineGross={selectedItem.unitPrice * selectedItem.quantity}
          productName={selectedItem.productName}
          lineItemId={selectedItem.id}
        />
      )}
    </TableContainer>
  );
};

export default CartTable;
