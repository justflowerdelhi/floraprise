/**
 * Ledger Table — Main data table with collapsible detail rows & pagination
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
  useTheme,
  alpha,
} from '@mui/material';
import KeyboardArrowDownIcon from '@mui/icons-material/KeyboardArrowDown';
import KeyboardArrowUpIcon from '@mui/icons-material/KeyboardArrowUp';

import type { StockMovement } from '../data/ledger.data';
import { fmtDateTime, fmt, fmtSigned, refTypeConfig } from '../utils/ledger.utils';

interface Props {
  movements: StockMovement[];
  loading: boolean;
  darkMode: boolean;
  page: number;
  rowsPerPage: number;
  onPageChange: (p: number) => void;
  onRowsPerPageChange: (r: number) => void;
}

const COLUMNS = [
  '',             // expand
  'Date',
  'Reference Type',
  'Reference #',
  'Batch #',
  'Qty In',
  'Qty Out',
  'Balance',
  'Cost Impact',
  'Performed By',
];

const LedgerTable = ({
  movements,
  loading,
  darkMode,
  page,
  rowsPerPage,
  onPageChange,
  onRowsPerPageChange,
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
    () => movements.slice(page * rowsPerPage, page * rowsPerPage + rowsPerPage),
    [movements, page, rowsPerPage],
  );

  const borderColor = darkMode ? theme.palette.grey[800] : theme.palette.grey[200];
  const headerBg = darkMode ? alpha(theme.palette.grey[900], 0.95) : '#fafafa';
  const rowHoverBg = darkMode
    ? alpha(theme.palette.grey[800], 0.4)
    : alpha(theme.palette.primary.main, 0.03);

  // Empty state
  if (!loading && movements.length === 0) {
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
          No movements found
        </Typography>
        <Typography variant="body2" sx={{ color: darkMode ? 'grey.600' : 'grey.400' }}>
          Try adjusting your filters or date range.
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
              {COLUMNS.map((col, i) => (
                <TableCell
                  key={i}
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
                    ...(i === 0 && { width: 40, px: 0.5 }),
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
                    {COLUMNS.map((_, j) => (
                      <TableCell key={j}>
                        <Skeleton variant="text" width={j === 0 ? 24 : j === 1 ? 120 : 70} />
                      </TableCell>
                    ))}
                  </TableRow>
                ))
              : paginated.map((mv) => {
                  const cfg = refTypeConfig[mv.referenceType];
                  const expanded = expandedIds.has(mv.id);

                  return (
                    <Fragment key={mv.id}>
                      {/* Main row */}
                      <TableRow
                        sx={{
                          '&:hover': { backgroundColor: rowHoverBg },
                          transition: 'background-color 0.15s',
                          cursor: 'pointer',
                          '& td': {
                            borderBottom: expanded
                              ? 'none'
                              : `1px solid ${borderColor}`,
                            color: darkMode ? 'grey.300' : 'grey.800',
                            fontSize: '0.8rem',
                            py: 1,
                          },
                        }}
                        onClick={() => toggle(mv.id)}
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

                        {/* Date */}
                        <TableCell sx={{ whiteSpace: 'nowrap' }}>
                          <Typography
                            variant="body2"
                            sx={{
                              fontSize: '0.78rem',
                              color: darkMode ? 'grey.300' : 'grey.700',
                            }}
                          >
                            {fmtDateTime(mv.date)}
                          </Typography>
                        </TableCell>

                        {/* Reference Type */}
                        <TableCell>
                          <Chip
                            label={mv.referenceType}
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

                        {/* Reference # */}
                        <TableCell>
                          <Typography
                            variant="caption"
                            sx={{
                              fontFamily: 'monospace',
                              fontSize: '0.72rem',
                              color: darkMode ? 'grey.400' : 'grey.600',
                            }}
                          >
                            {mv.referenceNumber}
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
                            {mv.batchNumber}
                          </Typography>
                        </TableCell>

                        {/* Qty In */}
                        <TableCell align="right">
                          {mv.quantityIn > 0 ? (
                            <Typography
                              variant="body2"
                              sx={{ fontWeight: 700, color: '#2e7d32', fontSize: '0.8rem' }}
                            >
                              +{mv.quantityIn}
                            </Typography>
                          ) : (
                            <Typography
                              variant="body2"
                              sx={{ color: darkMode ? 'grey.700' : 'grey.300', fontSize: '0.8rem' }}
                            >
                              —
                            </Typography>
                          )}
                        </TableCell>

                        {/* Qty Out */}
                        <TableCell align="right">
                          {mv.quantityOut > 0 ? (
                            <Typography
                              variant="body2"
                              sx={{ fontWeight: 700, color: '#c62828', fontSize: '0.8rem' }}
                            >
                              −{mv.quantityOut}
                            </Typography>
                          ) : (
                            <Typography
                              variant="body2"
                              sx={{ color: darkMode ? 'grey.700' : 'grey.300', fontSize: '0.8rem' }}
                            >
                              —
                            </Typography>
                          )}
                        </TableCell>

                        {/* Balance After */}
                        <TableCell align="right">
                          <Typography
                            variant="body2"
                            sx={{
                              fontWeight: 700,
                              fontSize: '0.8rem',
                              color: darkMode ? '#f5f5f5' : '#1a1a1a',
                            }}
                          >
                            {mv.balanceAfter}
                          </Typography>
                        </TableCell>

                        {/* Cost Impact */}
                        <TableCell align="right">
                          {mv.costImpact !== 0 ? (
                            <Typography
                              variant="body2"
                              sx={{
                                fontWeight: 600,
                                fontSize: '0.78rem',
                                color: mv.costImpact > 0 ? '#2e7d32' : '#c62828',
                              }}
                            >
                              {fmtSigned(mv.costImpact)}
                            </Typography>
                          ) : (
                            <Typography
                              variant="body2"
                              sx={{ color: darkMode ? 'grey.700' : 'grey.400', fontSize: '0.78rem' }}
                            >
                              —
                            </Typography>
                          )}
                        </TableCell>

                        {/* Performed By */}
                        <TableCell sx={{ whiteSpace: 'nowrap' }}>
                          {mv.performedBy}
                        </TableCell>
                      </TableRow>

                      {/* Collapsible Detail Row */}
                      <TableRow>
                        <TableCell
                          colSpan={COLUMNS.length}
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
                              <Box
                                sx={{
                                  display: 'grid',
                                  gridTemplateColumns: {
                                    xs: '1fr',
                                    sm: '1fr 1fr',
                                    md: '1fr 1fr 1fr 1fr',
                                  },
                                  gap: 2,
                                }}
                              >
                                <DetailField
                                  label="Product"
                                  value={mv.productName}
                                  darkMode={darkMode}
                                />
                                <DetailField
                                  label="Location"
                                  value={mv.location}
                                  darkMode={darkMode}
                                />
                                <DetailField
                                  label="Cost / Unit"
                                  value={fmt(mv.costPerUnit)}
                                  darkMode={darkMode}
                                />
                                <DetailField
                                  label="Total Cost Impact"
                                  value={
                                    mv.costImpact !== 0
                                      ? fmtSigned(mv.costImpact)
                                      : 'No cost change (transfer)'
                                  }
                                  darkMode={darkMode}
                                />
                              </Box>
                              {mv.notes && (
                                <Box sx={{ mt: 1.5 }}>
                                  <Typography
                                    variant="caption"
                                    sx={{
                                      color: darkMode ? 'grey.500' : 'grey.500',
                                      fontWeight: 600,
                                      textTransform: 'uppercase',
                                      fontSize: '0.65rem',
                                      letterSpacing: 0.5,
                                    }}
                                  >
                                    Notes
                                  </Typography>
                                  <Typography
                                    variant="body2"
                                    sx={{
                                      color: darkMode ? 'grey.300' : 'grey.700',
                                      fontSize: '0.8rem',
                                      mt: 0.3,
                                    }}
                                  >
                                    {mv.notes}
                                  </Typography>
                                </Box>
                              )}
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
        count={movements.length}
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

// ─── Small helper component ─────────────────────────────────

const DetailField = ({
  label,
  value,
  darkMode,
}: {
  label: string;
  value: string;
  darkMode: boolean;
}) => (
  <Box>
    <Typography
      variant="caption"
      sx={{
        color: darkMode ? 'grey.500' : 'grey.500',
        fontWeight: 600,
        textTransform: 'uppercase',
        fontSize: '0.65rem',
        letterSpacing: 0.5,
      }}
    >
      {label}
    </Typography>
    <Typography
      variant="body2"
      sx={{
        color: darkMode ? 'grey.200' : 'grey.800',
        fontWeight: 600,
        fontSize: '0.8rem',
      }}
    >
      {value}
    </Typography>
  </Box>
);

export default LedgerTable;
