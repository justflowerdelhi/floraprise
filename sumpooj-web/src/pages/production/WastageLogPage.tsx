/**
 * WastageLogPage.tsx — Wastage Log & Report
 *
 * Features:
 * - View all wastage entries
 * - Filter by reason, date range, product
 * - Summary cards (total wastage, by reason)
 * - Link to related finished batch
 */

import { useState, useEffect, useMemo, useCallback } from 'react';
import {
  Box, Container, Typography, TextField, Card, CardContent,
  Table, TableHead, TableBody, TableRow, TableCell, TableContainer,
  Chip, InputAdornment, Select, MenuItem, FormControl, InputLabel,
  Paper, useTheme, alpha, Skeleton, Grid,
} from '@mui/material';
import {
  Search as SearchIcon,
  DeleteSweep as WastageIcon,
  TrendingDown as TrendIcon,
} from '@mui/icons-material';
import type { WastageLog, WastageFilterState, WastageReason } from './types/ProductionTypes';
import { WASTAGE_REASONS } from './types/ProductionTypes';
import { getWastageLogs } from './api/production.api';
import { formatDateTime, aggregateWastage } from './utils/production.utils';

const WastageLogPage = () => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';

  // ── State ──────────────────────────────────────────────────
  const [logs, setLogs] = useState<WastageLog[]>([]);
  const [loading, setLoading] = useState(true);
  const [filters, setFilters] = useState<WastageFilterState>({
    search: '',
    reason: 'ALL',
    dateFrom: '',
    dateTo: '',
  });

  // ── Load ───────────────────────────────────────────────────
  const loadLogs = useCallback(async () => {
    setLoading(true);
    try {
      const data = await getWastageLogs();
      setLogs(data);
    } catch {
      // handle error
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { loadLogs(); }, [loadLogs]);

  // ── Filter ─────────────────────────────────────────────────
  const filtered = useMemo(() => {
    let list = [...logs];
    if (filters.search) {
      const q = filters.search.toLowerCase();
      list = list.filter((l) =>
        l.productName.toLowerCase().includes(q) ||
        l.relatedBatchCode?.toLowerCase().includes(q),
      );
    }
    if (filters.reason !== 'ALL') {
      list = list.filter((l) => l.reason === filters.reason);
    }
    if (filters.dateFrom) {
      const from = new Date(filters.dateFrom).getTime();
      list = list.filter((l) => new Date(l.createdAt).getTime() >= from);
    }
    if (filters.dateTo) {
      const to = new Date(filters.dateTo).getTime() + 86400000; // end of day
      list = list.filter((l) => new Date(l.createdAt).getTime() <= to);
    }
    // Sort by date descending
    list.sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime());
    return list;
  }, [logs, filters]);

  // ── Summary ────────────────────────────────────────────────
  const summary = useMemo(() => aggregateWastage(filtered), [filtered]);

  // ── Reason styling ─────────────────────────────────────────
  const reasonColor = (reason: WastageReason): string => {
    switch (reason) {
      case 'SPOILED': return '#f44336';
      case 'WILTED': return '#ff9800';
      case 'DAMAGED': return '#9c27b0';
      default: return '#757575';
    }
  };

  const reasonIcon = (reason: WastageReason): string => {
    switch (reason) {
      case 'SPOILED': return '🦠';
      case 'WILTED': return '🥀';
      case 'DAMAGED': return '💔';
      default: return '❓';
    }
  };

  return (
    <Box sx={{ minHeight: '100vh', pb: 6 }}>
      <Container maxWidth="xl" sx={{ pt: 3 }}>
        {/* ── Header ────────────────────────────────────── */}
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5, mb: 3 }}>
          <WastageIcon sx={{ fontSize: 32, color: '#f44336' }} />
          <Box>
            <Typography variant="h5" fontWeight={700}>Wastage Log</Typography>
            <Typography variant="body2" color="text.secondary">
              Track spoiled, wilted, and damaged materials
            </Typography>
          </Box>
        </Box>

        {/* ── Summary Cards ─────────────────────────────── */}
        <Grid container spacing={2} sx={{ mb: 3 }}>
          <Grid size={{ xs: 6, sm: 3 }}>
            <Card
              elevation={0}
              sx={{
                borderRadius: 2,
                border: `1px solid ${dk ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.08)'}`,
                bgcolor: alpha('#f44336', dk ? 0.08 : 0.04),
              }}
            >
              <CardContent sx={{ p: 2, '&:last-child': { pb: 2 } }}>
                <Typography variant="caption" color="text.secondary">Total Wastage</Typography>
                <Typography variant="h4" fontWeight={700} sx={{ color: '#f44336' }}>
                  {summary.totalQuantity}
                </Typography>
                <Typography variant="caption" color="text.secondary">items</Typography>
              </CardContent>
            </Card>
          </Grid>
          {WASTAGE_REASONS.map((reason) => (
            <Grid size={{ xs: 6, sm: 3 }} key={reason}>
              <Card
                elevation={0}
                sx={{
                  borderRadius: 2,
                  border: `1px solid ${dk ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.08)'}`,
                  bgcolor: alpha(reasonColor(reason), dk ? 0.08 : 0.04),
                }}
              >
                <CardContent sx={{ p: 2, '&:last-child': { pb: 2 } }}>
                  <Typography variant="caption" color="text.secondary">
                    {reasonIcon(reason)} {reason}
                  </Typography>
                  <Typography variant="h4" fontWeight={700} sx={{ color: reasonColor(reason) }}>
                    {summary.byReason[reason] ?? 0}
                  </Typography>
                  <Typography variant="caption" color="text.secondary">items</Typography>
                </CardContent>
              </Card>
            </Grid>
          ))}
        </Grid>

        {/* ── Top Wasted Products ────────────────────────── */}
        {Object.keys(summary.byProduct).length > 0 && (
          <Card
            elevation={0}
            sx={{ mb: 3, borderRadius: 2, border: `1px solid ${dk ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.08)'}` }}
          >
            <CardContent sx={{ p: 2 }}>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 1.5 }}>
                <TrendIcon sx={{ color: '#f44336', fontSize: 20 }} />
                <Typography variant="subtitle2" fontWeight={700}>Most Wasted Products</Typography>
              </Box>
              <Box sx={{ display: 'flex', gap: 1, flexWrap: 'wrap' }}>
                {Object.entries(summary.byProduct)
                  .sort(([, a], [, b]) => b - a)
                  .slice(0, 8)
                  .map(([name, qty]) => (
                    <Chip
                      key={name}
                      label={`${name}: ${qty}`}
                      size="small"
                      variant="outlined"
                      sx={{ fontWeight: 600 }}
                    />
                  ))}
              </Box>
            </CardContent>
          </Card>
        )}

        {/* ── Filters ───────────────────────────────────── */}
        <Paper
          elevation={0}
          sx={{
            p: 2, mb: 3, borderRadius: 2,
            border: `1px solid ${dk ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.08)'}`,
            display: 'flex', gap: 2, flexWrap: 'wrap', alignItems: 'center',
          }}
        >
          <TextField
            size="small"
            placeholder="Search by product or batch..."
            value={filters.search}
            onChange={(e) => setFilters((f) => ({ ...f, search: e.target.value }))}
            sx={{ minWidth: 240 }}
            InputProps={{
              startAdornment: <InputAdornment position="start"><SearchIcon sx={{ fontSize: 20 }} /></InputAdornment>,
            }}
          />
          <FormControl size="small" sx={{ minWidth: 140 }}>
            <InputLabel>Reason</InputLabel>
            <Select
              value={filters.reason}
              label="Reason"
              onChange={(e) => setFilters((f) => ({ ...f, reason: e.target.value as WastageReason | 'ALL' }))}
            >
              <MenuItem value="ALL">All Reasons</MenuItem>
              {WASTAGE_REASONS.map((r) => (
                <MenuItem key={r} value={r}>{r}</MenuItem>
              ))}
            </Select>
          </FormControl>
          <TextField
            size="small"
            label="From"
            type="date"
            value={filters.dateFrom}
            onChange={(e) => setFilters((f) => ({ ...f, dateFrom: e.target.value }))}
            InputLabelProps={{ shrink: true }}
            sx={{ minWidth: 150 }}
          />
          <TextField
            size="small"
            label="To"
            type="date"
            value={filters.dateTo}
            onChange={(e) => setFilters((f) => ({ ...f, dateTo: e.target.value }))}
            InputLabelProps={{ shrink: true }}
            sx={{ minWidth: 150 }}
          />
          <Typography variant="body2" color="text.secondary" sx={{ ml: 'auto' }}>
            {filtered.length} entr{filtered.length !== 1 ? 'ies' : 'y'}
          </Typography>
        </Paper>

        {/* ── Table ─────────────────────────────────────── */}
        <Card elevation={0} sx={{ borderRadius: 2, border: `1px solid ${dk ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.08)'}` }}>
          <TableContainer>
            <Table>
              <TableHead>
                <TableRow sx={{ '& th': { fontWeight: 700, fontSize: '0.8125rem', color: 'text.secondary' } }}>
                  <TableCell>Date</TableCell>
                  <TableCell>Product</TableCell>
                  <TableCell align="center">Quantity</TableCell>
                  <TableCell>Reason</TableCell>
                  <TableCell>Related Batch</TableCell>
                  <TableCell>Logged By</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {loading ? (
                  Array.from({ length: 4 }).map((_, i) => (
                    <TableRow key={i}>
                      {Array.from({ length: 6 }).map((_, j) => (
                        <TableCell key={j}><Skeleton variant="text" /></TableCell>
                      ))}
                    </TableRow>
                  ))
                ) : filtered.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={6} align="center" sx={{ py: 6 }}>
                      <WastageIcon sx={{ fontSize: 48, color: 'text.disabled', mb: 1 }} />
                      <Typography color="text.secondary">No wastage entries found</Typography>
                    </TableCell>
                  </TableRow>
                ) : (
                  filtered.map((log) => (
                    <TableRow key={log.id} hover>
                      <TableCell>
                        <Typography variant="body2">{formatDateTime(log.createdAt)}</Typography>
                      </TableCell>
                      <TableCell>
                        <Typography fontWeight={600}>{log.productName}</Typography>
                      </TableCell>
                      <TableCell align="center">
                        <Typography fontWeight={700} color="error">{log.quantity}</Typography>
                      </TableCell>
                      <TableCell>
                        <Chip
                          label={`${reasonIcon(log.reason)} ${log.reason}`}
                          size="small"
                          sx={{
                            fontWeight: 600,
                            bgcolor: alpha(reasonColor(log.reason), 0.12),
                            color: reasonColor(log.reason),
                          }}
                        />
                      </TableCell>
                      <TableCell>
                        {log.relatedBatchCode ? (
                          <Chip
                            label={log.relatedBatchCode}
                            size="small"
                            variant="outlined"
                            sx={{ fontFamily: 'monospace', fontSize: '0.75rem' }}
                          />
                        ) : (
                          <Typography variant="body2" color="text.disabled">—</Typography>
                        )}
                      </TableCell>
                      <TableCell>
                        <Typography variant="body2" color="text.secondary">
                          {log.createdBy ?? '—'}
                        </Typography>
                      </TableCell>
                    </TableRow>
                  ))
                )}
              </TableBody>
            </Table>
          </TableContainer>
        </Card>
      </Container>
    </Box>
  );
};

export default WastageLogPage;
