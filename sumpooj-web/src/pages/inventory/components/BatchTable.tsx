/**
 * Batch Table — Main inventory table with all columns,
 * expiry progress bars, status badges, pagination, tooltips
 */

import { useMemo } from 'react';
import {
  Box,
  Table,
  TableHead,
  TableBody,
  TableCell,
  TableContainer,
  TableRow,
  Paper,
  Typography,
  Chip,
  LinearProgress,
  Tooltip,
  Skeleton,
  TablePagination,
  IconButton,
  useTheme,
  alpha,
} from '@mui/material';
import InfoOutlinedIcon from '@mui/icons-material/InfoOutlined';
import PrintIcon from '@mui/icons-material/Print';
import type { InventoryBatch } from '../data/inventory.data';
import {
  getDaysLeft,
  getBatchStatus,
  statusConfig,
  getRemainingValue,
  getExpiryProgress,
  fmt,
  fmtDate,
  printBatchLabel,
} from '../utils/inventory.utils';

interface BatchTableProps {
  batches: InventoryBatch[];
  loading: boolean;
  darkMode: boolean;
  page: number;
  rowsPerPage: number;
  onPageChange: (p: number) => void;
  onRowsPerPageChange: (r: number) => void;
}

// Identify the oldest non-expired perishable batch → tooltip "Use this batch first"
const getOldestBatchId = (batches: InventoryBatch[]): string | null => {
  let oldest: InventoryBatch | null = null;
  let oldestDays = Infinity;
  for (const b of batches) {
    if (!b.isPerishable || !b.expiryDate) continue;
    const days = getDaysLeft(b.expiryDate);
    if (days === null || days < 0) continue;
    if (days < oldestDays) {
      oldestDays = days;
      oldest = b;
    }
  }
  return oldest?.id ?? null;
};

const progressColor = (pct: number): string => {
  if (pct <= 0) return '#9e9e9e';
  if (pct <= 25) return '#c62828';
  if (pct <= 50) return '#e65100';
  return '#2e7d32';
};

const BatchTable = ({
  batches,
  loading,
  darkMode,
  page,
  rowsPerPage,
  onPageChange,
  onRowsPerPageChange,
}: BatchTableProps) => {
  const theme = useTheme();
  const oldestId = useMemo(() => getOldestBatchId(batches), [batches]);

  const paginated = useMemo(
    () => batches.slice(page * rowsPerPage, page * rowsPerPage + rowsPerPage),
    [batches, page, rowsPerPage],
  );

  const borderColor = darkMode ? theme.palette.grey[800] : theme.palette.grey[200];
  const headerBg = darkMode ? alpha(theme.palette.grey[900], 0.95) : '#fafafa';
  const rowHoverBg = darkMode ? alpha(theme.palette.grey[800], 0.4) : alpha(theme.palette.primary.main, 0.03);

  // Empty state
  if (!loading && batches.length === 0) {
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
          No batches found
        </Typography>
        <Typography variant="body2" sx={{ color: darkMode ? 'grey.600' : 'grey.400' }}>
          Try adjusting your filters or add new inventory batches.
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
      <TableContainer sx={{ maxHeight: 600 }}>
        <Table stickyHeader size="small">
          <TableHead>
            <TableRow>
              {[
                'Product Name',
                'Batch Code',
                'Supplier',
                'Location',
                'Received Date',
                'Expiry Date',
                'Days Left',
                'Qty Remaining',
                'Received Qty',
                'Remaining Value',
                'Expiry Life',
                'Status',
                'Label',
              ].map((col) => (
                <TableCell
                  key={col}
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
                  {col}
                </TableCell>
              ))}
            </TableRow>
          </TableHead>
          <TableBody>
            {loading
              ? Array.from({ length: 6 }).map((_, i) => (
                  <TableRow key={`skel-${i}`}>
                    {Array.from({ length: 13 }).map((_, j) => (
                      <TableCell key={j}>
                        <Skeleton variant="text" width={j === 0 ? 140 : 70} />
                      </TableCell>
                    ))}
                  </TableRow>
                ))
              : paginated.map((batch) => {
                  const status = getBatchStatus(batch);
                  const cfg = statusConfig[status];
                  const days = getDaysLeft(batch.expiryDate);
                  const expiryPct = getExpiryProgress(batch);
                  const value = getRemainingValue(batch);
                  const isOldest = batch.id === oldestId;

                  return (
                    <TableRow
                      key={batch.id}
                      sx={{
                        '&:hover': { backgroundColor: rowHoverBg },
                        transition: 'background-color 0.15s',
                        '& td': {
                          borderBottom: `1px solid ${borderColor}`,
                          color: darkMode ? 'grey.300' : 'grey.800',
                          fontSize: '0.8rem',
                          py: 1.2,
                        },
                      }}
                    >
                      {/* Product Name */}
                      <TableCell>
                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
                          <Typography
                            variant="body2"
                            sx={{
                              fontWeight: 600,
                              color: darkMode ? 'grey.100' : 'grey.900',
                              whiteSpace: 'nowrap',
                            }}
                          >
                            {batch.productName}
                          </Typography>
                          {isOldest && (
                            <Tooltip title="Use this batch first — oldest perishable" arrow>
                              <InfoOutlinedIcon
                                sx={{ fontSize: 15, color: '#e65100', cursor: 'help' }}
                              />
                            </Tooltip>
                          )}
                        </Box>
                        <Typography
                          variant="caption"
                          sx={{ color: darkMode ? 'grey.600' : 'grey.400', fontSize: '0.68rem' }}
                        >
                          {batch.productType}
                        </Typography>
                      </TableCell>

                      {/* Batch Code */}
                      <TableCell>
                        <Typography
                          variant="caption"
                          sx={{
                            fontFamily: 'monospace',
                            fontSize: '0.72rem',
                            color: darkMode ? 'grey.400' : 'grey.600',
                          }}
                        >
                          {batch.batchCode}
                        </Typography>
                      </TableCell>

                      {/* Supplier */}
                      <TableCell sx={{ whiteSpace: 'nowrap' }}>{batch.supplier ?? '—'}</TableCell>

                      {/* Storage Location */}
                      <TableCell sx={{ whiteSpace: 'nowrap' }}>{batch.storageLocation}</TableCell>

                      {/* Received Date */}
                      <TableCell sx={{ whiteSpace: 'nowrap' }}>{fmtDate(batch.receivedDate)}</TableCell>

                      {/* Expiry Date */}
                      <TableCell sx={{ whiteSpace: 'nowrap' }}>
                        {batch.expiryDate ? fmtDate(batch.expiryDate) : '—'}
                      </TableCell>

                      {/* Days Left */}
                      <TableCell>
                        {days !== null ? (
                          <Typography
                            variant="body2"
                            sx={{
                              fontWeight: 700,
                              color: days < 0 ? '#9e9e9e' : days <= 2 ? '#c62828' : days <= 6 ? '#e65100' : '#2e7d32',
                              fontSize: '0.8rem',
                            }}
                          >
                            {days < 0 ? `${Math.abs(days)}d ago` : `${days}d`}
                          </Typography>
                        ) : (
                          <Typography variant="body2" sx={{ color: darkMode ? 'grey.600' : 'grey.400' }}>
                            N/A
                          </Typography>
                        )}
                      </TableCell>

                      {/* Qty Remaining */}
                      <TableCell align="right">
                        <Typography variant="body2" sx={{ fontWeight: 600 }}>
                          {batch.quantityRemaining}
                        </Typography>
                      </TableCell>

                      {/* Received Qty */}
                      <TableCell align="right">
                        <Typography variant="body2" sx={{ color: darkMode ? 'grey.500' : 'grey.500' }}>
                          {batch.quantityReceived}
                        </Typography>
                      </TableCell>

                      {/* Remaining Value */}
                      <TableCell align="right">
                        <Typography variant="body2" sx={{ fontWeight: 600 }}>
                          {fmt(value)}
                        </Typography>
                      </TableCell>

                      {/* Expiry Progress */}
                      <TableCell>
                        {batch.isPerishable ? (
                          <Tooltip title={`${expiryPct.toFixed(0)}% shelf life remaining`} arrow>
                            <Box sx={{ width: 70 }}>
                              <LinearProgress
                                variant="determinate"
                                value={expiryPct}
                                sx={{
                                  height: 6,
                                  borderRadius: 3,
                                  backgroundColor: darkMode
                                    ? 'rgba(255,255,255,0.08)'
                                    : 'rgba(0,0,0,0.06)',
                                  '& .MuiLinearProgress-bar': {
                                    borderRadius: 3,
                                    backgroundColor: progressColor(expiryPct),
                                  },
                                }}
                              />
                            </Box>
                          </Tooltip>
                        ) : (
                          <Typography variant="caption" sx={{ color: darkMode ? 'grey.600' : 'grey.400' }}>
                            —
                          </Typography>
                        )}
                      </TableCell>

                      {/* Status Badge */}
                      <TableCell>
                        <Chip
                          label={cfg.label}
                          size="small"
                          sx={{
                            fontWeight: 700,
                            fontSize: '0.65rem',
                            height: 22,
                            backgroundColor: darkMode ? alpha(cfg.color, 0.15) : cfg.bg,
                            color: darkMode ? cfg.color : cfg.textColor,
                            border: `1px solid ${darkMode ? alpha(cfg.color, 0.3) : alpha(cfg.color, 0.2)}`,
                          }}
                        />
                      </TableCell>
                      <TableCell>
                        <Tooltip title="Print Batch Label" arrow>
                          <IconButton
                            size="small"
                            onClick={() => printBatchLabel(batch)}
                            sx={{ color: darkMode ? 'grey.300' : 'text.secondary' }}
                          >
                            <PrintIcon sx={{ fontSize: 18 }} />
                          </IconButton>
                        </Tooltip>
                      </TableCell>
                    </TableRow>
                  );
                })}
          </TableBody>
        </Table>
      </TableContainer>

      {/* Pagination */}
      <TablePagination
        component="div"
        count={batches.length}
        page={page}
        onPageChange={(_, p) => onPageChange(p)}
        rowsPerPage={rowsPerPage}
        onRowsPerPageChange={(e) => onRowsPerPageChange(Number(e.target.value))}
        rowsPerPageOptions={[5, 10, 25, 50]}
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

export default BatchTable;
