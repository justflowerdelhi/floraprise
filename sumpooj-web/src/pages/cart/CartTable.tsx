/**
 * CartTable.tsx — Reusable cart line items table
 *
 * Shows: product, qty (+/-), unit price, discount, tax, line total, margin, warnings
 * Supports read-only mode for FTD orders (isPriceEditable = false)
 */
import React from 'react';
import {
  Table, TableBody, TableCell, TableContainer, TableHead, TableRow,
  IconButton, Typography, Box, Chip, Tooltip, TextField, Paper,
  useTheme, alpha,
} from '@mui/material';
import {
  Add as AddIcon,
  Remove as RemoveIcon,
  Delete as DeleteIcon,
  WarningAmber as WarnIcon,
  AccessTime as ExpiryIcon,
} from '@mui/icons-material';
import type { CartItem, Product } from '../orders/OrderTypes';
import { fmtCurrency, fmtPercent } from './CartUtils';

interface Props {
  items: CartItem[];
  products: Product[];
  isPriceEditable: boolean;
  onUpdateQty: (lineId: string, qty: number, product: Product) => void;
  onRemove: (lineId: string) => void;
  onSetDiscount: (lineId: string, pct: number, product: Product) => void;
}

const CartTable: React.FC<Props> = ({
  items, products, isPriceEditable, onUpdateQty, onRemove, onSetDiscount,
}) => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';

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
      <Box sx={{ py: 6, textAlign: 'center' }}>
        <Typography variant="body1" color="text.secondary">
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
                  '&:hover': { bgcolor: dk ? alpha('#fff', 0.03) : alpha('#000', 0.02) },
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
                  <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 0.5 }}>
                    <IconButton
                      size="small"
                      onClick={() => prod && onUpdateQty(item.id, item.quantity - 1, prod)}
                      sx={{ p: 0.3 }}
                    >
                      <RemoveIcon sx={{ fontSize: 16 }} />
                    </IconButton>
                    <Typography variant="body2" sx={{ fontWeight: 700, minWidth: 24, textAlign: 'center' }}>
                      {item.quantity}
                    </Typography>
                    <IconButton
                      size="small"
                      onClick={() => prod && onUpdateQty(item.id, item.quantity + 1, prod)}
                      sx={{ p: 0.3 }}
                    >
                      <AddIcon sx={{ fontSize: 16 }} />
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
                    <TextField
                      size="small"
                      type="number"
                      value={item.discountPercent}
                      onChange={(e) => {
                        const val = Math.max(0, Math.min(100, Number(e.target.value)));
                        if (prod) onSetDiscount(item.id, val, prod);
                      }}
                      slotProps={{ input: { sx: { fontSize: '0.8rem', py: 0.5, px: 1, width: 52, textAlign: 'right' } } }}
                      sx={{
                        '& .MuiOutlinedInput-root': {
                          ...(dk ? { color: '#e0e0e0', '& fieldset': { borderColor: 'rgba(255,255,255,0.15)' } } : {}),
                        },
                      }}
                    />
                  ) : (
                    <Typography variant="body2">{item.discountPercent}%</Typography>
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
                  <Typography variant="body2" sx={{ fontWeight: 700 }}>
                    {fmtCurrency(item.lineTotal)}
                  </Typography>
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
                  <IconButton size="small" color="error" onClick={() => onRemove(item.id)}>
                    <DeleteIcon sx={{ fontSize: 18 }} />
                  </IconButton>
                </TableCell>
              </TableRow>
            );
          })}
        </TableBody>
      </Table>
    </TableContainer>
  );
};

export default CartTable;
