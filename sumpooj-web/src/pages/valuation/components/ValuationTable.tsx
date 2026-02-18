/**
 * Valuation Table — Product rows with FIFO layer expansion,
 * % of total bar, sortable columns, pagination
 */

import { useState, useMemo, Fragment } from 'react';
import {
  Box,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  Typography,
  Chip,
  Skeleton,
  TablePagination,
  IconButton,
  Collapse,
  LinearProgress,
  Tooltip,
  useTheme,
  alpha,
} from '@mui/material';
import KeyboardArrowDownIcon from '@mui/icons-material/KeyboardArrowDown';
import KeyboardArrowUpIcon from '@mui/icons-material/KeyboardArrowUp';
import TableSortLabelIcon from '@mui/icons-material/UnfoldMore';

import type { ValuationProduct, ValuationFilterState } from '../data/valuation.data';
import { fmt, fmtPct, fmtDate, categoryConfig } from '../utils/valuation.utils';

interface Props {
  products: ValuationProduct[];
  loading: boolean;
  darkMode: boolean;
  page: number;
  rowsPerPage: number;
  onPageChange: (p: number) => void;
  onRowsPerPageChange: (r: number) => void;
  sortField: ValuationFilterState['sortField'];
  sortDir: ValuationFilterState['sortDir'];
  onSortChange: (field: ValuationFilterState['sortField']) => void;
}

const ValuationTable = ({
  products,
  loading,
  darkMode,
  page,
  rowsPerPage,
  onPageChange,
  onRowsPerPageChange,
  sortField,
  sortDir,
  onSortChange,
}: Props) => {
  const theme = useTheme();
  const [expandedIds, setExpandedIds] = useState<Set<string>>(new Set());

  const toggle = (id: string) => {
    setExpandedIds((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
  };

  const paginated = useMemo(
    () => products.slice(page * rowsPerPage, page * rowsPerPage + rowsPerPage),
    [products, page, rowsPerPage],
  );

  const borderColor = darkMode ? theme.palette.grey[800] : theme.palette.grey[200];
  const headerBg = darkMode ? alpha(theme.palette.grey[900], 0.95) : '#fafafa';
  const rowHoverBg = darkMode
    ? alpha(theme.palette.grey[800], 0.4)
    : alpha(theme.palette.primary.main, 0.03);

  // Sortable header helper
  const SortableHeader = ({
    label,
    field,
    align,
  }: {
    label: string;
    field: ValuationFilterState['sortField'];
    align?: 'left' | 'right';
  }) => (
    <TableCell
      align={align}
      sx={{
        fontWeight: 700,
        fontSize: '0.7rem',
        textTransform: 'uppercase',
        letterSpacing: 0.5,
        color: darkMode ? 'grey.400' : 'grey.600',
        backgroundColor: headerBg,
        borderBottom: `1px solid ${borderColor}`,
        whiteSpace: 'nowrap',
        py: 1.5,
        cursor: 'pointer',
        userSelect: 'none',
        ...(darkMode && { borderBottomColor: theme.palette.grey[800] }),
      }}
      onClick={() => onSortChange(field)}
    >
      <Box
        sx={{
          display: 'inline-flex',
          alignItems: 'center',
          gap: 0.3,
        }}
      >
        {label}
        <TableSortLabelIcon
          sx={{
            fontSize: 14,
            opacity: sortField === field ? 1 : 0.3,
            transform:
              sortField === field && sortDir === 'asc'
                ? 'scaleY(-1)'
                : 'none',
            transition: 'opacity 0.15s, transform 0.15s',
          }}
        />
      </Box>
    </TableCell>
  );

  // Empty state
  if (!loading && products.length === 0) {
    return (
      <Paper
        elevation={0}
        sx={{
          p: 6,
          borderRadius: 2,
          border: `1px solid ${borderColor}`,
          backgroundColor: darkMode ? alpha(theme.palette.grey[900], 0.85) : '#fff',
          textAlign: 'center',
        }}
      >
        <Typography variant="h6" sx={{ color: darkMode ? 'grey.400' : 'grey.500', mb: 1 }}>
          No products found
        </Typography>
        <Typography variant="body2" sx={{ color: darkMode ? 'grey.600' : 'grey.400' }}>
          Adjust your filters to see valuation data.
        </Typography>
      </Paper>
    );
  }

  return (
    <Paper
      elevation={0}
      sx={{
        borderRadius: 2,
        border: `1px solid ${borderColor}`,
        backgroundColor: darkMode ? alpha(theme.palette.grey[900], 0.85) : '#fff',
        overflow: 'hidden',
      }}
    >
      <TableContainer sx={{ maxHeight: 580 }}>
        <Table stickyHeader size="small">
          <TableHead>
            <TableRow>
              {/* Expand */}
              <TableCell
                sx={{
                  width: 40,
                  px: 0.5,
                  backgroundColor: headerBg,
                  borderBottom: `1px solid ${borderColor}`,
                  ...(darkMode && { borderBottomColor: theme.palette.grey[800] }),
                }}
              />
              <SortableHeader label="Product" field="productName" />
              {/* Category — not sortable */}
              <TableCell
                sx={{
                  fontWeight: 700,
                  fontSize: '0.7rem',
                  textTransform: 'uppercase',
                  letterSpacing: 0.5,
                  color: darkMode ? 'grey.400' : 'grey.600',
                  backgroundColor: headerBg,
                  borderBottom: `1px solid ${borderColor}`,
                  whiteSpace: 'nowrap',
                  py: 1.5,
                  ...(darkMode && { borderBottomColor: theme.palette.grey[800] }),
                }}
              >
                Category
              </TableCell>
              <SortableHeader label="Quantity" field="totalQuantity" align="right" />
              {/* Avg Cost — not a sort field, display only */}
              <TableCell
                align="right"
                sx={{
                  fontWeight: 700,
                  fontSize: '0.7rem',
                  textTransform: 'uppercase',
                  letterSpacing: 0.5,
                  color: darkMode ? 'grey.400' : 'grey.600',
                  backgroundColor: headerBg,
                  borderBottom: `1px solid ${borderColor}`,
                  whiteSpace: 'nowrap',
                  py: 1.5,
                  ...(darkMode && { borderBottomColor: theme.palette.grey[800] }),
                }}
              >
                Avg Cost
              </TableCell>
              <SortableHeader label="Total Value" field="totalValue" align="right" />
              {/* % of Total — not sortable, visual bar */}
              <TableCell
                sx={{
                  fontWeight: 700,
                  fontSize: '0.7rem',
                  textTransform: 'uppercase',
                  letterSpacing: 0.5,
                  color: darkMode ? 'grey.400' : 'grey.600',
                  backgroundColor: headerBg,
                  borderBottom: `1px solid ${borderColor}`,
                  whiteSpace: 'nowrap',
                  py: 1.5,
                  minWidth: 130,
                  ...(darkMode && { borderBottomColor: theme.palette.grey[800] }),
                }}
              >
                % of Total
              </TableCell>
              <SortableHeader label="Margin" field="marginPercent" align="right" />
            </TableRow>
          </TableHead>

          <TableBody>
            {loading
              ? Array.from({ length: 6 }).map((_, i) => (
                  <TableRow key={`skel-${i}`}>
                    {Array.from({ length: 9 }).map((_, j) => (
                      <TableCell key={j}>
                        <Skeleton variant="text" width={j === 1 ? 130 : 70} />
                      </TableCell>
                    ))}
                  </TableRow>
                ))
              : paginated.map((p) => {
                  const expanded = expandedIds.has(p.id);
                  const catCfg = categoryConfig[p.category] ?? categoryConfig['Supplies'];
                  const marginColor =
                    p.marginPercent >= 50
                      ? '#2e7d32'
                      : p.marginPercent >= 30
                        ? '#e65100'
                        : '#c62828';

                  return (
                    <Fragment key={p.id}>
                      {/* Main row */}
                      <TableRow
                        sx={{
                          '&:hover': { backgroundColor: rowHoverBg },
                          transition: 'background-color 0.15s',
                          cursor: 'pointer',
                          '& td': {
                            borderBottom: expanded ? 'none' : `1px solid ${borderColor}`,
                            color: darkMode ? 'grey.300' : 'grey.800',
                            fontSize: '0.8rem',
                            py: 1.2,
                          },
                        }}
                        onClick={() => toggle(p.id)}
                      >
                        {/* Expand */}
                        <TableCell sx={{ px: 0.5 }}>
                          <IconButton size="small" sx={{ color: darkMode ? 'grey.500' : 'grey.400' }}>
                            {expanded ? (
                              <KeyboardArrowUpIcon sx={{ fontSize: 18 }} />
                            ) : (
                              <KeyboardArrowDownIcon sx={{ fontSize: 18 }} />
                            )}
                          </IconButton>
                        </TableCell>

                        {/* Product */}
                        <TableCell>
                          <Typography
                            variant="body2"
                            sx={{
                              fontWeight: 600,
                              color: darkMode ? 'grey.100' : 'grey.900',
                              whiteSpace: 'nowrap',
                            }}
                          >
                            {p.productName}
                          </Typography>
                          <Typography
                            variant="caption"
                            sx={{
                              color: darkMode ? 'grey.600' : 'grey.400',
                              fontSize: '0.68rem',
                            }}
                          >
                            {p.location}
                            {p.isPerishable ? ' · Perishable' : ''}
                          </Typography>
                        </TableCell>

                        {/* Category */}
                        <TableCell>
                          <Chip
                            label={p.category}
                            size="small"
                            sx={{
                              fontWeight: 700,
                              fontSize: '0.62rem',
                              height: 22,
                              backgroundColor: darkMode
                                ? alpha(catCfg.color, 0.15)
                                : catCfg.bg,
                              color: darkMode ? catCfg.color : catCfg.textColor,
                              border: `1px solid ${
                                darkMode
                                  ? alpha(catCfg.color, 0.3)
                                  : alpha(catCfg.color, 0.2)
                              }`,
                            }}
                          />
                        </TableCell>

                        {/* Quantity */}
                        <TableCell align="right">
                          <Typography variant="body2" sx={{ fontWeight: 700 }}>
                            {p.totalQuantity.toLocaleString()}
                          </Typography>
                        </TableCell>

                        {/* Avg Cost */}
                        <TableCell align="right">
                          <Typography variant="body2" sx={{ fontWeight: 600 }}>
                            {fmt(p.averageCost)}
                          </Typography>
                        </TableCell>

                        {/* Total Value */}
                        <TableCell align="right">
                          <Typography
                            variant="body2"
                            sx={{
                              fontWeight: 800,
                              color: darkMode ? '#f5f5f5' : '#1a1a1a',
                            }}
                          >
                            {fmt(p.totalValue)}
                          </Typography>
                        </TableCell>

                        {/* % of Total — visual bar */}
                        <TableCell>
                          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                            <Box sx={{ flex: 1, minWidth: 60 }}>
                              <LinearProgress
                                variant="determinate"
                                value={Math.min(p.pctOfTotalInventory, 100)}
                                sx={{
                                  height: 6,
                                  borderRadius: 3,
                                  backgroundColor: darkMode
                                    ? alpha('#fff', 0.06)
                                    : alpha('#000', 0.06),
                                  '& .MuiLinearProgress-bar': {
                                    borderRadius: 3,
                                    backgroundColor: darkMode
                                      ? alpha('#1565c0', 0.7)
                                      : '#1565c0',
                                  },
                                }}
                              />
                            </Box>
                            <Typography
                              variant="caption"
                              sx={{
                                fontWeight: 700,
                                fontSize: '0.72rem',
                                color: darkMode ? 'grey.400' : 'grey.600',
                                minWidth: 38,
                                textAlign: 'right',
                              }}
                            >
                              {fmtPct(p.pctOfTotalInventory)}
                            </Typography>
                          </Box>
                        </TableCell>

                        {/* Margin */}
                        <TableCell align="right">
                          <Tooltip
                            title={`Sell ${fmt(p.sellingPricePerUnit)} — Cost ${fmt(p.averageCost)}`}
                            arrow
                          >
                            <Typography
                              variant="body2"
                              sx={{
                                fontWeight: 700,
                                fontSize: '0.8rem',
                                color: marginColor,
                              }}
                            >
                              {fmtPct(p.marginPercent)}
                            </Typography>
                          </Tooltip>
                        </TableCell>
                      </TableRow>

                      {/* Collapsible FIFO layers */}
                      <TableRow>
                        <TableCell
                          colSpan={9}
                          sx={{
                            py: 0,
                            borderBottom: `1px solid ${borderColor}`,
                          }}
                        >
                          <Collapse in={expanded} timeout="auto" unmountOnExit>
                            <Box
                              sx={{
                                py: 2,
                                px: 3,
                                backgroundColor: darkMode
                                  ? alpha(theme.palette.grey[900], 0.5)
                                  : alpha(theme.palette.grey[50], 0.8),
                                borderRadius: 1,
                                my: 0.5,
                              }}
                            >
                              <Typography
                                variant="caption"
                                sx={{
                                  fontWeight: 700,
                                  fontSize: '0.7rem',
                                  textTransform: 'uppercase',
                                  letterSpacing: 0.5,
                                  color: darkMode ? 'grey.400' : 'grey.500',
                                  mb: 1.5,
                                  display: 'block',
                                }}
                              >
                                FIFO Cost Layers ({p.fifoLayers.length} batch{p.fifoLayers.length > 1 ? 'es' : ''})
                              </Typography>

                              <Table size="small">
                                <TableHead>
                                  <TableRow>
                                    {['Batch #', 'Purchase Date', 'Quantity', 'Cost / Unit', 'Layer Value'].map(
                                      (h) => (
                                        <TableCell
                                          key={h}
                                          sx={{
                                            fontWeight: 700,
                                            fontSize: '0.65rem',
                                            textTransform: 'uppercase',
                                            letterSpacing: 0.4,
                                            color: darkMode ? 'grey.500' : 'grey.500',
                                            borderBottom: `1px solid ${
                                              darkMode
                                                ? alpha('#fff', 0.06)
                                                : alpha('#000', 0.08)
                                            }`,
                                            py: 1,
                                          }}
                                        >
                                          {h}
                                        </TableCell>
                                      ),
                                    )}
                                  </TableRow>
                                </TableHead>
                                <TableBody>
                                  {p.fifoLayers.map((layer, idx) => (
                                    <TableRow key={idx}>
                                      <TableCell
                                        sx={{
                                          fontFamily: 'monospace',
                                          fontSize: '0.72rem',
                                          color: darkMode ? 'grey.400' : 'grey.600',
                                          borderBottom: `1px solid ${
                                            darkMode
                                              ? alpha('#fff', 0.04)
                                              : alpha('#000', 0.05)
                                          }`,
                                        }}
                                      >
                                        {layer.batchNumber}
                                      </TableCell>
                                      <TableCell
                                        sx={{
                                          fontSize: '0.78rem',
                                          color: darkMode ? 'grey.300' : 'grey.700',
                                          borderBottom: `1px solid ${
                                            darkMode
                                              ? alpha('#fff', 0.04)
                                              : alpha('#000', 0.05)
                                          }`,
                                        }}
                                      >
                                        {fmtDate(layer.purchaseDate)}
                                      </TableCell>
                                      <TableCell
                                        sx={{
                                          fontWeight: 600,
                                          fontSize: '0.78rem',
                                          color: darkMode ? 'grey.200' : 'grey.800',
                                          borderBottom: `1px solid ${
                                            darkMode
                                              ? alpha('#fff', 0.04)
                                              : alpha('#000', 0.05)
                                          }`,
                                        }}
                                      >
                                        {layer.quantity}
                                      </TableCell>
                                      <TableCell
                                        sx={{
                                          fontSize: '0.78rem',
                                          color: darkMode ? 'grey.300' : 'grey.700',
                                          borderBottom: `1px solid ${
                                            darkMode
                                              ? alpha('#fff', 0.04)
                                              : alpha('#000', 0.05)
                                          }`,
                                        }}
                                      >
                                        {fmt(layer.costPerUnit)}
                                      </TableCell>
                                      <TableCell
                                        sx={{
                                          fontWeight: 700,
                                          fontSize: '0.78rem',
                                          color: darkMode ? '#f5f5f5' : '#1a1a1a',
                                          borderBottom: `1px solid ${
                                            darkMode
                                              ? alpha('#fff', 0.04)
                                              : alpha('#000', 0.05)
                                          }`,
                                        }}
                                      >
                                        {fmt(layer.totalCost)}
                                      </TableCell>
                                    </TableRow>
                                  ))}
                                </TableBody>
                              </Table>

                              {/* Layer summary line */}
                              <Box
                                sx={{
                                  display: 'flex',
                                  justifyContent: 'flex-end',
                                  mt: 1,
                                  pt: 1,
                                  borderTop: `1px dashed ${
                                    darkMode
                                      ? alpha('#fff', 0.08)
                                      : alpha('#000', 0.1)
                                  }`,
                                }}
                              >
                                <Typography
                                  variant="body2"
                                  sx={{
                                    fontWeight: 700,
                                    fontSize: '0.8rem',
                                    color: darkMode ? 'grey.200' : 'grey.800',
                                  }}
                                >
                                  Total: {fmt(p.totalValue)} ({p.totalQuantity} units @ avg {fmt(p.averageCost)})
                                </Typography>
                              </Box>
                            </Box>
                          </Collapse>
                        </TableCell>
                      </TableRow>
                    </Fragment>
                  );
                })}
          </TableBody>
        </Table>
      </TableContainer>

      <TablePagination
        component="div"
        count={products.length}
        page={page}
        onPageChange={(_, p) => onPageChange(p)}
        rowsPerPage={rowsPerPage}
        onRowsPerPageChange={(e) => onRowsPerPageChange(Number(e.target.value))}
        rowsPerPageOptions={[10, 25, 50]}
        sx={{
          borderTop: `1px solid ${borderColor}`,
          color: darkMode ? 'grey.400' : undefined,
          '& .MuiTablePagination-selectIcon': {
            color: darkMode ? 'grey.500' : undefined,
          },
        }}
      />
    </Paper>
  );
};

export default ValuationTable;
