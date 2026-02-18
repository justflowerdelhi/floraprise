/**
 * Expiry Alert Table — Main table with suggested actions column
 */

import { useMemo } from 'react';
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
  Tooltip,
  useTheme,
  alpha,
} from '@mui/material';
import LocalOfferIcon from '@mui/icons-material/LocalOffer';
import CampaignIcon from '@mui/icons-material/Campaign';
import StarIcon from '@mui/icons-material/Star';
import DeleteSweepIcon from '@mui/icons-material/DeleteSweep';
import RemoveCircleOutlineIcon from '@mui/icons-material/RemoveCircleOutline';
import type { ExpiryAlertBatch, SuggestedAction } from '../data/expiry.data';
import { urgencyConfig, fmt, fmtDate } from '../utils/expiry.utils';

interface Props {
  batches: ExpiryAlertBatch[];
  loading: boolean;
  darkMode: boolean;
  page: number;
  rowsPerPage: number;
  onPageChange: (p: number) => void;
  onRowsPerPageChange: (r: number) => void;
}

const actionIcons: Record<SuggestedAction['icon'], React.ReactNode> = {
  discount: <LocalOfferIcon sx={{ fontSize: 14 }} />,
  promo: <CampaignIcon sx={{ fontSize: 14 }} />,
  prioritize: <StarIcon sx={{ fontSize: 14 }} />,
  wastage: <DeleteSweepIcon sx={{ fontSize: 14 }} />,
  dispose: <RemoveCircleOutlineIcon sx={{ fontSize: 14 }} />,
};

const ExpiryAlertTable = ({
  batches,
  loading,
  darkMode,
  page,
  rowsPerPage,
  onPageChange,
  onRowsPerPageChange,
}: Props) => {
  const theme = useTheme();

  const paginated = useMemo(
    () => batches.slice(page * rowsPerPage, page * rowsPerPage + rowsPerPage),
    [batches, page, rowsPerPage],
  );

  const borderColor = darkMode ? theme.palette.grey[800] : theme.palette.grey[200];
  const headerBg = darkMode ? alpha(theme.palette.grey[900], 0.95) : '#fafafa';
  const rowHoverBg = darkMode
    ? alpha(theme.palette.grey[800], 0.4)
    : alpha(theme.palette.primary.main, 0.03);

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
          No expiry alerts
        </Typography>
        <Typography variant="body2" sx={{ color: darkMode ? 'grey.600' : 'grey.400' }}>
          All perishable batches are well within shelf life, or adjust your filters.
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
      <TableContainer sx={{ maxHeight: 560 }}>
        <Table stickyHeader size="small">
          <TableHead>
            <TableRow>
              {[
                'Product',
                'Batch #',
                'Supplier',
                'Qty Remaining',
                'Expiry Date',
                'Days Left',
                'Inventory Value',
                'Status',
                'Suggested Action',
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
              ? Array.from({ length: 5 }).map((_, i) => (
                  <TableRow key={`skel-${i}`}>
                    {Array.from({ length: 9 }).map((_, j) => (
                      <TableCell key={j}>
                        <Skeleton variant="text" width={j === 0 ? 130 : j === 8 ? 150 : 70} />
                      </TableCell>
                    ))}
                  </TableRow>
                ))
              : paginated.map((batch) => {
                  const cfg = urgencyConfig[batch.urgency];

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
                          {batch.productName}
                        </Typography>
                        <Typography
                          variant="caption"
                          sx={{ color: darkMode ? 'grey.600' : 'grey.400', fontSize: '0.68rem' }}
                        >
                          {batch.productType} · {batch.storageLocation}
                        </Typography>
                      </TableCell>

                      {/* Batch # */}
                      <TableCell>
                        <Typography
                          variant="caption"
                          sx={{
                            fontFamily: 'monospace',
                            fontSize: '0.72rem',
                            color: darkMode ? 'grey.400' : 'grey.600',
                          }}
                        >
                          {batch.batchNumber}
                        </Typography>
                      </TableCell>

                      {/* Supplier */}
                      <TableCell sx={{ whiteSpace: 'nowrap' }}>{batch.supplier}</TableCell>

                      {/* Qty Remaining */}
                      <TableCell align="right">
                        <Typography variant="body2" sx={{ fontWeight: 600 }}>
                          {batch.quantityRemaining}
                        </Typography>
                      </TableCell>

                      {/* Expiry Date */}
                      <TableCell sx={{ whiteSpace: 'nowrap' }}>
                        {fmtDate(batch.expiryDate)}
                      </TableCell>

                      {/* Days Left */}
                      <TableCell>
                        {batch.daysLeft !== null ? (
                          <Typography
                            variant="body2"
                            sx={{
                              fontWeight: 700,
                              fontSize: '0.8rem',
                              color:
                                batch.daysLeft < 0
                                  ? '#9e9e9e'
                                  : batch.daysLeft <= 3
                                    ? '#c62828'
                                    : batch.daysLeft <= 7
                                      ? '#e65100'
                                      : '#2e7d32',
                            }}
                          >
                            {batch.daysLeft < 0
                              ? `${Math.abs(batch.daysLeft)}d ago`
                              : batch.daysLeft === 0
                                ? 'Today'
                                : `${batch.daysLeft}d`}
                          </Typography>
                        ) : (
                          '—'
                        )}
                      </TableCell>

                      {/* Inventory Value */}
                      <TableCell align="right">
                        <Typography variant="body2" sx={{ fontWeight: 600 }}>
                          {fmt(batch.inventoryValue)}
                        </Typography>
                      </TableCell>

                      {/* Status */}
                      <TableCell>
                        <Chip
                          label={cfg.label}
                          size="small"
                          sx={{
                            fontWeight: 700,
                            fontSize: '0.65rem',
                            height: 22,
                            backgroundColor: darkMode
                              ? alpha(cfg.color, 0.15)
                              : cfg.bg,
                            color: darkMode ? cfg.color : cfg.textColor,
                            border: `1px solid ${
                              darkMode
                                ? alpha(cfg.color, 0.3)
                                : alpha(cfg.color, 0.2)
                            }`,
                          }}
                        />
                      </TableCell>

                      {/* Suggested Actions */}
                      <TableCell>
                        {batch.suggestedActions.length > 0 ? (
                          <Box sx={{ display: 'flex', gap: 0.5, flexWrap: 'wrap' }}>
                            {batch.suggestedActions.map((action, i) => (
                              <Tooltip key={i} title={action.label} arrow>
                                <Chip
                                  label={action.label}
                                  size="small"
                                  icon={
                                    <Box
                                      component="span"
                                      sx={{
                                        display: 'flex',
                                        alignItems: 'center',
                                        color: 'inherit',
                                      }}
                                    >
                                      {actionIcons[action.icon]}
                                    </Box>
                                  }
                                  sx={{
                                    fontWeight: 600,
                                    fontSize: '0.62rem',
                                    height: 24,
                                    cursor: 'pointer',
                                    backgroundColor: darkMode
                                      ? alpha(action.color, 0.12)
                                      : alpha(action.color, 0.08),
                                    color: action.color,
                                    border: `1px solid ${alpha(action.color, darkMode ? 0.25 : 0.18)}`,
                                    '&:hover': {
                                      backgroundColor: alpha(action.color, darkMode ? 0.2 : 0.15),
                                    },
                                    '& .MuiChip-icon': {
                                      color: action.color,
                                      ml: '4px',
                                    },
                                  }}
                                />
                              </Tooltip>
                            ))}
                          </Box>
                        ) : (
                          <Typography
                            variant="caption"
                            sx={{ color: darkMode ? 'grey.600' : 'grey.400' }}
                          >
                            No action needed
                          </Typography>
                        )}
                      </TableCell>
                    </TableRow>
                  );
                })}
          </TableBody>
        </Table>
      </TableContainer>

      <TablePagination
        component="div"
        count={batches.length}
        page={page}
        onPageChange={(_, p) => onPageChange(p)}
        rowsPerPage={rowsPerPage}
        onRowsPerPageChange={(e) => onRowsPerPageChange(Number(e.target.value))}
        rowsPerPageOptions={[5, 10, 25]}
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

export default ExpiryAlertTable;
