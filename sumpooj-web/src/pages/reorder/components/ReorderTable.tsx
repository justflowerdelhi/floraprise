/**
 * ReorderTable — sortable table with checkbox selection & smart risk badges
 */
import React from 'react';
import {
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  TableSortLabel,
  Checkbox,
  Chip,
  Tooltip,
  Typography,
  Paper,
  useTheme,
  alpha,
  Box,
} from '@mui/material';
import {
  LocalShipping as LeadTimeIcon,
  CalendarToday as DateIcon,
} from '@mui/icons-material';
import type { ReorderProduct, ReorderFilterState } from '../data/reorder.data';
import { RISK_CONFIG, fmtCurrency, fmtDays, fmtDate } from '../utils/reorder.utils';

type SortField = ReorderFilterState['sortField'];

interface Props {
  products: ReorderProduct[];
  selected: Set<string>;
  onToggle: (id: string) => void;
  onToggleAll: () => void;
  sortField: SortField;
  sortDir: 'asc' | 'desc';
  onSort: (field: SortField) => void;
}

interface ColDef {
  id: SortField | '';
  label: string;
  align?: 'left' | 'right' | 'center';
  minWidth?: number;
  sortable?: boolean;
}

const COLUMNS: ColDef[] = [
  { id: 'productName',        label: 'Product',           sortable: true,  minWidth: 180 },
  { id: '',                   label: 'Category',          minWidth: 130 },
  { id: '',                   label: 'Risk',              minWidth: 120 },
  { id: '',                   label: 'Current Stock',     align: 'right', minWidth: 100 },
  { id: '',                   label: 'Avg Daily Usage',   align: 'right', minWidth: 110 },
  { id: 'daysOfStockLeft',    label: 'Days Left',         align: 'right', sortable: true, minWidth: 90 },
  { id: '',                   label: 'Reorder Level',     align: 'right', minWidth: 100 },
  { id: 'suggestedOrderQty',  label: 'Suggested Qty',     align: 'right', sortable: true, minWidth: 110 },
  { id: 'estimatedOrderCost', label: 'Est. Cost',         align: 'right', sortable: true, minWidth: 100 },
  { id: '',                   label: 'Supplier',          minWidth: 150 },
  { id: '',                   label: 'Lead Time',         align: 'center', minWidth: 90 },
  { id: '',                   label: 'Last Ordered',      align: 'right', minWidth: 100 },
];

const ReorderTable: React.FC<Props> = ({
  products,
  selected,
  onToggle,
  onToggleAll,
  sortField,
  sortDir,
  onSort,
}) => {
  const theme = useTheme();
  const darkMode = theme.palette.mode === 'dark';
  const allSelected = products.length > 0 && selected.size === products.length;
  const someSelected = selected.size > 0 && selected.size < products.length;

  const headerBg = darkMode ? '#1a1a2e' : '#f5f5f5';
  const rowHover = darkMode ? alpha('#fff', 0.04) : alpha('#000', 0.02);
  const selectedRowBg = darkMode ? alpha(theme.palette.primary.dark, 0.15) : alpha(theme.palette.primary.light, 0.12);

  const daysLeftColor = (d: number, leadTime: number): string => {
    if (d === 0) return theme.palette.error.main;
    if (d <= leadTime) return theme.palette.error.main;
    if (d <= leadTime + 3) return theme.palette.warning.main;
    return darkMode ? '#e0e0e0' : 'inherit';
  };

  return (
    <TableContainer
      component={Paper}
      elevation={darkMode ? 0 : 1}
      sx={{
        bgcolor: darkMode ? '#0f0f0f' : '#fff',
        border: darkMode ? '1px solid rgba(255,255,255,0.08)' : 'none',
        borderRadius: 2,
        overflow: 'auto',
      }}
    >
      <Table size="small" stickyHeader>
        <TableHead>
          <TableRow>
            {/* Checkbox column */}
            <TableCell
              padding="checkbox"
              sx={{ bgcolor: headerBg, borderBottom: `2px solid ${darkMode ? 'rgba(255,255,255,0.12)' : '#ddd'}` }}
            >
              <Checkbox
                indeterminate={someSelected}
                checked={allSelected}
                onChange={onToggleAll}
                sx={darkMode ? { color: 'rgba(255,255,255,0.5)' } : {}}
              />
            </TableCell>

            {COLUMNS.map((col) => (
              <TableCell
                key={col.label}
                align={col.align ?? 'left'}
                sx={{
                  bgcolor: headerBg,
                  fontWeight: 700,
                  fontSize: '0.75rem',
                  textTransform: 'uppercase',
                  letterSpacing: 0.5,
                  color: darkMode ? 'rgba(255,255,255,0.7)' : 'text.secondary',
                  minWidth: col.minWidth,
                  borderBottom: `2px solid ${darkMode ? 'rgba(255,255,255,0.12)' : '#ddd'}`,
                  whiteSpace: 'nowrap',
                }}
              >
                {col.sortable && col.id ? (
                  <TableSortLabel
                    active={sortField === col.id}
                    direction={sortField === col.id ? sortDir : 'asc'}
                    onClick={() => onSort(col.id as SortField)}
                    sx={{
                      '& .MuiTableSortLabel-icon': {
                        color: darkMode ? 'rgba(255,255,255,0.5) !important' : undefined,
                      },
                    }}
                  >
                    {col.label}
                  </TableSortLabel>
                ) : (
                  col.label
                )}
              </TableCell>
            ))}
          </TableRow>
        </TableHead>

        <TableBody>
          {products.length === 0 ? (
            <TableRow>
              <TableCell colSpan={COLUMNS.length + 1} align="center" sx={{ py: 6 }}>
                <Typography variant="body1" color="text.secondary">
                  No products match the current filters
                </Typography>
              </TableCell>
            </TableRow>
          ) : (
            products.map((p) => {
              const isSelected = selected.has(p.id);
              const riskCfg = RISK_CONFIG[p.risk];

              return (
                <TableRow
                  key={p.id}
                  hover
                  selected={isSelected}
                  onClick={() => onToggle(p.id)}
                  sx={{
                    cursor: 'pointer',
                    bgcolor: isSelected ? selectedRowBg : 'transparent',
                    '&:hover': { bgcolor: isSelected ? selectedRowBg : rowHover },
                  }}
                >
                  {/* Checkbox */}
                  <TableCell padding="checkbox">
                    <Checkbox
                      checked={isSelected}
                      sx={darkMode ? { color: 'rgba(255,255,255,0.5)' } : {}}
                    />
                  </TableCell>

                  {/* Product */}
                  <TableCell>
                    <Box>
                      <Typography variant="body2" sx={{ fontWeight: 600 }}>
                        {p.productName}
                      </Typography>
                      <Typography
                        variant="caption"
                        sx={{ color: darkMode ? 'rgba(255,255,255,0.4)' : 'text.disabled' }}
                      >
                        {p.location}
                      </Typography>
                    </Box>
                  </TableCell>

                  {/* Category */}
                  <TableCell>
                    <Typography variant="body2">{p.category}</Typography>
                  </TableCell>

                  {/* Risk chip */}
                  <TableCell>
                    <Chip
                      label={riskCfg.label}
                      color={riskCfg.color}
                      size="small"
                      variant={darkMode ? 'outlined' : 'filled'}
                      sx={{ fontWeight: 600, fontSize: '0.72rem' }}
                    />
                  </TableCell>

                  {/* Current stock */}
                  <TableCell align="right">
                    <Typography
                      variant="body2"
                      sx={{
                        fontWeight: p.currentStock === 0 ? 700 : 400,
                        color: p.currentStock === 0 ? theme.palette.error.main : 'inherit',
                      }}
                    >
                      {p.currentStock}
                    </Typography>
                  </TableCell>

                  {/* Avg daily usage */}
                  <TableCell align="right">
                    <Typography variant="body2">{p.avgDailyUsage}/day</Typography>
                  </TableCell>

                  {/* Days left */}
                  <TableCell align="right">
                    <Typography
                      variant="body2"
                      sx={{
                        fontWeight: 600,
                        color: daysLeftColor(p.daysOfStockLeft, p.leadTimeDays),
                      }}
                    >
                      {fmtDays(p.daysOfStockLeft)}
                    </Typography>
                  </TableCell>

                  {/* Reorder level */}
                  <TableCell align="right">
                    <Typography variant="body2">{p.reorderLevel}</Typography>
                  </TableCell>

                  {/* Suggested qty */}
                  <TableCell align="right">
                    <Typography
                      variant="body2"
                      sx={{
                        fontWeight: 700,
                        color:
                          p.suggestedOrderQty > 0
                            ? darkMode
                              ? '#fdd835'
                              : theme.palette.primary.main
                            : 'text.disabled',
                      }}
                    >
                      {p.suggestedOrderQty > 0 ? p.suggestedOrderQty : '—'}
                    </Typography>
                  </TableCell>

                  {/* Est cost */}
                  <TableCell align="right">
                    <Typography variant="body2">
                      {p.estimatedOrderCost > 0 ? fmtCurrency(p.estimatedOrderCost) : '—'}
                    </Typography>
                  </TableCell>

                  {/* Supplier */}
                  <TableCell>
                    <Typography variant="body2">{p.supplier}</Typography>
                  </TableCell>

                  {/* Lead time */}
                  <TableCell align="center">
                    <Tooltip title={`Supplier lead time: ${p.leadTimeDays} day(s)`} arrow>
                      <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 0.5 }}>
                        <LeadTimeIcon sx={{ fontSize: 14, color: 'text.secondary' }} />
                        <Typography variant="body2">{p.leadTimeDays}d</Typography>
                      </Box>
                    </Tooltip>
                  </TableCell>

                  {/* Last ordered */}
                  <TableCell align="right">
                    <Tooltip title="Last purchase order date" arrow>
                      <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'flex-end', gap: 0.5 }}>
                        <DateIcon sx={{ fontSize: 14, color: 'text.secondary' }} />
                        <Typography variant="body2">{fmtDate(p.lastOrderDate)}</Typography>
                      </Box>
                    </Tooltip>
                  </TableCell>
                </TableRow>
              );
            })
          )}
        </TableBody>
      </Table>
    </TableContainer>
  );
};

export default ReorderTable;
