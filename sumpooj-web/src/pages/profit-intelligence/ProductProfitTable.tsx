/**
 * ProductProfitTable.tsx — Product-level Profit Analysis
 *
 * Sortable table with:
 * - Product name, SKU, category
 * - Qty sold, revenue, COGS, wastage
 * - Channel breakdown (expandable)
 * - Net profit & margin
 */
import React, { useState, useMemo } from 'react';
import {
  Box, Typography, Table, TableHead, TableRow, TableCell, TableBody,
  TableSortLabel, Collapse, IconButton, TextField, InputAdornment,
  Chip, useTheme, alpha
} from '@mui/material';
import {
  KeyboardArrowDown, KeyboardArrowUp, Search as SearchIcon,
} from '@mui/icons-material';
import type { ProductProfit } from './ProfitTypes';
import { CHANNEL_CONFIG } from './ProfitTypes';
import type { OrderSource } from '../orders/OrderTypes';

interface Props {
  data: ProductProfit[];
}

type SortField = 'productName' | 'quantitySold' | 'grossRevenue' | 'netProfit' | 'effectiveMarginPercent';
type SortDirection = 'asc' | 'desc';

// ─── Formatters (tenant-aware) ───────────────────────────────

import { formatCurrency, formatPercent } from '../../core/i18n';

const fmtCurrency = (v: number) => formatCurrency(v);
const fmtPercent = (v: number) => formatPercent(v);

// ─── Row Component ──────────────────────────────────────────

interface RowProps {
  product: ProductProfit;
  dk: boolean;
}

const ProductRow: React.FC<RowProps> = ({ product, dk }) => {
  const [open, setOpen] = useState(false);

  const channelBreakdown = Object.entries(product.channelBreakdown).filter(([_, v]) => v > 0);
  const hasChannelBreakdown = channelBreakdown.length > 0;

  return (
    <>
      <TableRow hover sx={{ '& > *': { borderBottom: open ? 'none' : undefined } }}>
        <TableCell padding="checkbox">
          {hasChannelBreakdown && (
            <IconButton size="small" onClick={() => setOpen(!open)}>
              {open ? <KeyboardArrowUp fontSize="small" /> : <KeyboardArrowDown fontSize="small" />}
            </IconButton>
          )}
        </TableCell>
        <TableCell>
          <Box>
            <Typography variant="body2" sx={{ fontWeight: 600 }}>{product.productName}</Typography>
            <Typography variant="caption" sx={{ color: dk ? 'rgba(255,255,255,0.4)' : 'text.disabled' }}>
              {product.sku}
            </Typography>
          </Box>
        </TableCell>
        <TableCell>
          <Chip
            size="small"
            label={product.category}
            sx={{
              fontSize: '0.7rem',
              height: 22,
              bgcolor: dk ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.06)',
            }}
          />
        </TableCell>
        <TableCell align="right">
          <Typography variant="body2" sx={{ fontWeight: 600 }}>{product.quantitySold}</Typography>
        </TableCell>
        <TableCell align="right">{fmtCurrency(product.grossRevenue)}</TableCell>
        <TableCell align="right" sx={{ color: dk ? 'rgba(255,255,255,0.6)' : 'text.secondary' }}>
          {fmtCurrency(product.cogs)}
        </TableCell>
        <TableCell align="right" sx={{ color: '#f44336' }}>
          {product.wastageImpact > 0 ? `-${fmtCurrency(product.wastageImpact)}` : '—'}
        </TableCell>
        <TableCell align="right" sx={{ fontWeight: 600, color: '#4caf50' }}>
          {fmtCurrency(product.netProfit)}
        </TableCell>
        <TableCell align="center">
          <Chip
            size="small"
            label={fmtPercent(product.netProfitPercent)}
            sx={{
              fontWeight: 700,
              fontSize: '0.7rem',
              height: 22,
              bgcolor: alpha(
                product.netProfitPercent >= 50 ? '#4caf50' : product.netProfitPercent >= 30 ? '#ff9800' : '#f44336',
                dk ? 0.2 : 0.12
              ),
              color: product.netProfitPercent >= 50 ? '#4caf50' : product.netProfitPercent >= 30 ? '#ff9800' : '#f44336',
            }}
          />
        </TableCell>
        <TableCell align="center">
          <Chip
            size="small"
            label={fmtPercent(product.effectiveMarginPercent)}
            sx={{
              fontWeight: 700,
              fontSize: '0.7rem',
              height: 22,
              bgcolor: alpha('#fdd835', dk ? 0.15 : 0.12),
              color: '#fdd835',
            }}
          />
        </TableCell>
      </TableRow>

      {/* Expanded Channel Breakdown */}
      {hasChannelBreakdown && (
        <TableRow>
          <TableCell colSpan={10} sx={{ py: 0 }}>
            <Collapse in={open} timeout="auto" unmountOnExit>
              <Box sx={{ py: 2, pl: 6 }}>
                <Typography variant="caption" sx={{ fontWeight: 600, textTransform: 'uppercase', mb: 1, display: 'block' }}>
                  Revenue by Channel
                </Typography>
                <Box sx={{ display: 'flex', gap: 1.5, flexWrap: 'wrap' }}>
                  {channelBreakdown.map(([channel, revenue]) => {
                    const config = CHANNEL_CONFIG[channel as OrderSource];
                    return (
                      <Box
                        key={channel}
                        sx={{
                          display: 'flex',
                          alignItems: 'center',
                          gap: 1,
                          px: 1.5,
                          py: 0.75,
                          borderRadius: 1,
                          bgcolor: dk ? 'rgba(255,255,255,0.05)' : 'rgba(0,0,0,0.04)',
                        }}
                      >
                        <Box sx={{ width: 8, height: 8, borderRadius: '50%', bgcolor: config?.color ?? '#666' }} />
                        <Typography variant="caption" sx={{ fontWeight: 500 }}>
                          {config?.label ?? channel}:
                        </Typography>
                        <Typography variant="caption" sx={{ fontWeight: 700 }}>
                          {fmtCurrency(revenue)}
                        </Typography>
                      </Box>
                    );
                  })}
                </Box>
              </Box>
            </Collapse>
          </TableCell>
        </TableRow>
      )}
    </>
  );
};

// ─── Main Component ─────────────────────────────────────────

const ProductProfitTable: React.FC<Props> = ({ data }) => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';

  const [sortField, setSortField] = useState<SortField>('grossRevenue');
  const [sortDir, setSortDir] = useState<SortDirection>('desc');
  const [search, setSearch] = useState('');

  // Sort & filter data
  const sortedData = useMemo(() => {
    let filtered = data;

    if (search.trim()) {
      const q = search.toLowerCase();
      filtered = data.filter(
        (p) =>
          p.productName.toLowerCase().includes(q) ||
          p.sku.toLowerCase().includes(q) ||
          p.category.toLowerCase().includes(q)
      );
    }

    return [...filtered].sort((a, b) => {
      const aVal = a[sortField];
      const bVal = b[sortField];
      const cmp = typeof aVal === 'string' ? aVal.localeCompare(bVal as string) : (aVal as number) - (bVal as number);
      return sortDir === 'asc' ? cmp : -cmp;
    });
  }, [data, sortField, sortDir, search]);

  const handleSort = (field: SortField) => {
    if (sortField === field) {
      setSortDir((d) => (d === 'asc' ? 'desc' : 'asc'));
    } else {
      setSortField(field);
      setSortDir('desc');
    }
  };

  // Totals
  const totals = useMemo(
    () => ({
      qty: sortedData.reduce((s, p) => s + p.quantitySold, 0),
      grossRevenue: sortedData.reduce((s, p) => s + p.grossRevenue, 0),
      cogs: sortedData.reduce((s, p) => s + p.cogs, 0),
      wastage: sortedData.reduce((s, p) => s + p.wastageImpact, 0),
      netProfit: sortedData.reduce((s, p) => s + p.netProfit, 0),
    }),
    [sortedData]
  );

  return (
    <Box>
      {/* Header & Search */}
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2, flexWrap: 'wrap', gap: 2 }}>
        <Typography variant="subtitle1" sx={{ fontWeight: 700 }}>
          Product Profit Analysis
          <Typography component="span" variant="caption" sx={{ ml: 1, color: dk ? 'rgba(255,255,255,0.5)' : 'text.secondary' }}>
            ({sortedData.length} products)
          </Typography>
        </Typography>

        <TextField
          size="small"
          placeholder="Search products..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          sx={{
            width: 220,
            '& .MuiOutlinedInput-root': {
              bgcolor: dk ? 'rgba(255,255,255,0.05)' : '#fff',
            },
          }}
          slotProps={{
            input: {
              startAdornment: (
                <InputAdornment position="start">
                  <SearchIcon fontSize="small" sx={{ color: dk ? 'rgba(255,255,255,0.4)' : 'text.disabled' }} />
                </InputAdornment>
              ),
            },
          }}
        />
      </Box>

      {/* Table */}
      <Box sx={{ borderRadius: 2, overflow: 'hidden', bgcolor: dk ? 'rgba(255,255,255,0.03)' : '#fafafa' }}>
        <Table size="small">
          <TableHead>
            <TableRow>
              <TableCell padding="checkbox" sx={{ bgcolor: dk ? 'rgba(255,255,255,0.05)' : '#f5f5f5' }} />
              <TableCell
                sx={{ fontWeight: 700, bgcolor: dk ? 'rgba(255,255,255,0.05)' : '#f5f5f5', minWidth: 180 }}
              >
                <TableSortLabel
                  active={sortField === 'productName'}
                  direction={sortField === 'productName' ? sortDir : 'asc'}
                  onClick={() => handleSort('productName')}
                >
                  Product
                </TableSortLabel>
              </TableCell>
              <TableCell sx={{ fontWeight: 700, bgcolor: dk ? 'rgba(255,255,255,0.05)' : '#f5f5f5' }}>Category</TableCell>
              <TableCell
                align="right"
                sx={{ fontWeight: 700, bgcolor: dk ? 'rgba(255,255,255,0.05)' : '#f5f5f5' }}
              >
                <TableSortLabel
                  active={sortField === 'quantitySold'}
                  direction={sortField === 'quantitySold' ? sortDir : 'asc'}
                  onClick={() => handleSort('quantitySold')}
                >
                  Qty Sold
                </TableSortLabel>
              </TableCell>
              <TableCell
                align="right"
                sx={{ fontWeight: 700, bgcolor: dk ? 'rgba(255,255,255,0.05)' : '#f5f5f5' }}
              >
                <TableSortLabel
                  active={sortField === 'grossRevenue'}
                  direction={sortField === 'grossRevenue' ? sortDir : 'asc'}
                  onClick={() => handleSort('grossRevenue')}
                >
                  Gross Revenue
                </TableSortLabel>
              </TableCell>
              <TableCell align="right" sx={{ fontWeight: 700, bgcolor: dk ? 'rgba(255,255,255,0.05)' : '#f5f5f5' }}>COGS</TableCell>
              <TableCell align="right" sx={{ fontWeight: 700, bgcolor: dk ? 'rgba(255,255,255,0.05)' : '#f5f5f5' }}>Wastage</TableCell>
              <TableCell
                align="right"
                sx={{ fontWeight: 700, bgcolor: dk ? 'rgba(255,255,255,0.05)' : '#f5f5f5' }}
              >
                <TableSortLabel
                  active={sortField === 'netProfit'}
                  direction={sortField === 'netProfit' ? sortDir : 'asc'}
                  onClick={() => handleSort('netProfit')}
                >
                  Net Profit
                </TableSortLabel>
              </TableCell>
              <TableCell align="center" sx={{ fontWeight: 700, bgcolor: dk ? 'rgba(255,255,255,0.05)' : '#f5f5f5' }}>Profit %</TableCell>
              <TableCell
                align="center"
                sx={{ fontWeight: 700, bgcolor: dk ? 'rgba(255,255,255,0.05)' : '#f5f5f5' }}
              >
                <TableSortLabel
                  active={sortField === 'effectiveMarginPercent'}
                  direction={sortField === 'effectiveMarginPercent' ? sortDir : 'asc'}
                  onClick={() => handleSort('effectiveMarginPercent')}
                >
                  Eff. Margin
                </TableSortLabel>
              </TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {sortedData.map((product) => (
              <ProductRow key={product.productId} product={product} dk={dk} />
            ))}

            {/* Totals Row */}
            <TableRow sx={{ bgcolor: dk ? 'rgba(253,216,53,0.08)' : 'rgba(0,0,0,0.03)' }}>
              <TableCell colSpan={3} sx={{ fontWeight: 700 }}>TOTAL</TableCell>
              <TableCell align="right" sx={{ fontWeight: 700 }}>{totals.qty}</TableCell>
              <TableCell align="right" sx={{ fontWeight: 700 }}>{fmtCurrency(totals.grossRevenue)}</TableCell>
              <TableCell align="right" sx={{ fontWeight: 700 }}>{fmtCurrency(totals.cogs)}</TableCell>
              <TableCell align="right" sx={{ fontWeight: 700, color: '#f44336' }}>
                -{fmtCurrency(totals.wastage)}
              </TableCell>
              <TableCell align="right" sx={{ fontWeight: 700, color: '#4caf50' }}>{fmtCurrency(totals.netProfit)}</TableCell>
              <TableCell align="center">
                <Chip
                  size="small"
                  label={fmtPercent((totals.netProfit / totals.grossRevenue) * 100)}
                  sx={{
                    fontWeight: 700,
                    fontSize: '0.7rem',
                    height: 22,
                    bgcolor: alpha('#4caf50', dk ? 0.2 : 0.12),
                    color: '#4caf50',
                  }}
                />
              </TableCell>
              <TableCell />
            </TableRow>
          </TableBody>
        </Table>
      </Box>
    </Box>
  );
};

export default ProductProfitTable;
