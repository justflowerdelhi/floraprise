/**
 * FinishedGoodsInventory.tsx — Finished Goods Batch View
 *
 * Features:
 * - List all finished goods batches
 * - Expiry tracking with color-coded status
 * - Filter by status/location
 * - Barcode display
 * - Maintenance action
 * - Sorted by expiry (soonest first)
 */

import { useState, useEffect, useMemo, useCallback } from 'react';
import {
  Box, Container, Typography, TextField, Card, CardContent,
  Table, TableHead, TableBody, TableRow, TableCell, TableContainer,
  Chip, IconButton, Tooltip, InputAdornment, Select, MenuItem,
  FormControl, InputLabel, Paper, useTheme, alpha, Skeleton, Grid,
} from '@mui/material';
import {
  Search as SearchIcon,
  QrCode as BarcodeIcon,
  Build as MaintainIcon,
  Inventory2 as InventoryIcon,
  Warning as WarningIcon,
  CheckCircle as ActiveIcon,
  Cancel as ExpiredIcon,
  Refresh as RefreshIcon,
} from '@mui/icons-material';
import type { FinishedGoodsBatch, FinishedGoodsFilterState, FinishedBatchStatus } from './types/ProductionTypes';
import { getFinishedBatches } from './api/production.api';
import {
  getBatchDisplayStatus, isBatchMaintainable,
  formatDateTime, expiryLabel,
} from './utils/production.utils';
import MaintenanceModal from './MaintenanceModal';

const FinishedGoodsInventory = () => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';

  // ── State ──────────────────────────────────────────────────
  const [batches, setBatches] = useState<FinishedGoodsBatch[]>([]);
  const [loading, setLoading] = useState(true);
  const [filters, setFilters] = useState<FinishedGoodsFilterState>({
    search: '',
    status: 'ALL',
    locationId: '',
  });
  const [maintenanceBatch, setMaintenanceBatch] = useState<FinishedGoodsBatch | null>(null);

  // ── Load ───────────────────────────────────────────────────
  const loadBatches = useCallback(async () => {
    setLoading(true);
    try {
      const data = await getFinishedBatches();
      setBatches(data);
    } catch {
      // handle error
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { loadBatches(); }, [loadBatches]);

  // ── Filter & sort ──────────────────────────────────────────
  const filtered = useMemo(() => {
    let list = [...batches];
    if (filters.search) {
      const q = filters.search.toLowerCase();
      list = list.filter((b) =>
        b.recipeName.toLowerCase().includes(q) ||
        b.batchCode.toLowerCase().includes(q) ||
        b.barcode.includes(q),
      );
    }
    if (filters.status !== 'ALL') {
      list = list.filter((b) => b.status === filters.status);
    }
    if (filters.locationId) {
      list = list.filter((b) => b.locationId === filters.locationId);
    }
    // Sort by expiry (soonest first)
    list.sort((a, b) => new Date(a.expectedExpiry).getTime() - new Date(b.expectedExpiry).getTime());
    return list;
  }, [batches, filters]);

  // ── Summary cards ──────────────────────────────────────────
  const summary = useMemo(() => {
    const active = batches.filter((b) => b.status === 'ACTIVE' && b.quantityAvailable > 0);
    const totalQty = active.reduce((s, b) => s + b.quantityAvailable, 0);
    const expiringSoon = active.filter((b) => {
      const hours = (new Date(b.expectedExpiry).getTime() - Date.now()) / (1000 * 60 * 60);
      return hours > 0 && hours <= 24;
    }).length;
    const expired = batches.filter((b) => b.status === 'EXPIRED').length;
    return { activeCount: active.length, totalQty, expiringSoon, expired };
  }, [batches]);

  // ── Unique locations ───────────────────────────────────────
  const locations = useMemo(() => {
    const map = new Map<string, string>();
    batches.forEach((b) => map.set(b.locationId, b.locationName));
    return Array.from(map.entries());
  }, [batches]);

  return (
    <Box sx={{ minHeight: '100vh', pb: 6 }}>
      <Container maxWidth="xl" sx={{ pt: 3 }}>
        {/* ── Header ────────────────────────────────────── */}
        <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', mb: 3 }}>
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
            <InventoryIcon sx={{ fontSize: 32, color: '#ff9800' }} />
            <Box>
              <Typography variant="h5" fontWeight={700}>Finished Goods</Typography>
              <Typography variant="body2" color="text.secondary">
                Track pre-produced bouquets and arrangements
              </Typography>
            </Box>
          </Box>
          <Tooltip title="Refresh">
            <IconButton onClick={loadBatches}>
              <RefreshIcon />
            </IconButton>
          </Tooltip>
        </Box>

        {/* ── Summary Cards ─────────────────────────────── */}
        <Grid container spacing={2} sx={{ mb: 3 }}>
          {[
            { label: 'Active Batches', value: summary.activeCount, color: '#4caf50', icon: <ActiveIcon /> },
            { label: 'Total Available', value: summary.totalQty, color: '#2196f3', icon: <InventoryIcon /> },
            { label: 'Expiring <24h', value: summary.expiringSoon, color: '#ff9800', icon: <WarningIcon /> },
            { label: 'Expired', value: summary.expired, color: '#f44336', icon: <ExpiredIcon /> },
          ].map((card) => (
            <Grid size={{ xs: 6, sm: 3 }} key={card.label}>
              <Card
                elevation={0}
                sx={{
                  borderRadius: 2,
                  border: `1px solid ${dk ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.08)'}`,
                  bgcolor: alpha(card.color, dk ? 0.08 : 0.04),
                }}
              >
                <CardContent sx={{ p: 2, '&:last-child': { pb: 2 } }}>
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 0.5 }}>
                    <Box sx={{ color: card.color, display: 'flex' }}>{card.icon}</Box>
                    <Typography variant="caption" color="text.secondary">{card.label}</Typography>
                  </Box>
                  <Typography variant="h4" fontWeight={700} sx={{ color: card.color }}>
                    {card.value}
                  </Typography>
                </CardContent>
              </Card>
            </Grid>
          ))}
        </Grid>

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
            placeholder="Search by name, batch code, barcode..."
            value={filters.search}
            onChange={(e) => setFilters((f) => ({ ...f, search: e.target.value }))}
            sx={{ minWidth: 280 }}
            InputProps={{
              startAdornment: <InputAdornment position="start"><SearchIcon sx={{ fontSize: 20 }} /></InputAdornment>,
            }}
          />
          <FormControl size="small" sx={{ minWidth: 140 }}>
            <InputLabel>Status</InputLabel>
            <Select
              value={filters.status}
              label="Status"
              onChange={(e) => setFilters((f) => ({ ...f, status: e.target.value as FinishedBatchStatus | 'ALL' }))}
            >
              <MenuItem value="ALL">All</MenuItem>
              <MenuItem value="ACTIVE">Active</MenuItem>
              <MenuItem value="EXPIRED">Expired</MenuItem>
              <MenuItem value="DISCARDED">Discarded</MenuItem>
            </Select>
          </FormControl>
          <FormControl size="small" sx={{ minWidth: 180 }}>
            <InputLabel>Location</InputLabel>
            <Select
              value={filters.locationId}
              label="Location"
              onChange={(e) => setFilters((f) => ({ ...f, locationId: e.target.value }))}
            >
              <MenuItem value="">All Locations</MenuItem>
              {locations.map(([id, name]) => (
                <MenuItem key={id} value={id}>{name}</MenuItem>
              ))}
            </Select>
          </FormControl>
          <Typography variant="body2" color="text.secondary" sx={{ ml: 'auto' }}>
            {filtered.length} batch{filtered.length !== 1 ? 'es' : ''}
          </Typography>
        </Paper>

        {/* ── Table ─────────────────────────────────────── */}
        <Card elevation={0} sx={{ borderRadius: 2, border: `1px solid ${dk ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.08)'}` }}>
          <TableContainer>
            <Table>
              <TableHead>
                <TableRow sx={{ '& th': { fontWeight: 700, fontSize: '0.8125rem', color: 'text.secondary' } }}>
                  <TableCell>Batch Code</TableCell>
                  <TableCell>Recipe</TableCell>
                  <TableCell>Barcode</TableCell>
                  <TableCell align="center">Produced</TableCell>
                  <TableCell align="center">Available</TableCell>
                  <TableCell>Expiry</TableCell>
                  <TableCell>Location</TableCell>
                  <TableCell align="center">Status</TableCell>
                  <TableCell align="center">Actions</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {loading ? (
                  Array.from({ length: 4 }).map((_, i) => (
                    <TableRow key={i}>
                      {Array.from({ length: 9 }).map((_, j) => (
                        <TableCell key={j}><Skeleton variant="text" /></TableCell>
                      ))}
                    </TableRow>
                  ))
                ) : filtered.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={9} align="center" sx={{ py: 6 }}>
                      <InventoryIcon sx={{ fontSize: 48, color: 'text.disabled', mb: 1 }} />
                      <Typography color="text.secondary">No finished goods found</Typography>
                    </TableCell>
                  </TableRow>
                ) : (
                  filtered.map((batch) => {
                    const status = getBatchDisplayStatus(batch);
                    return (
                      <TableRow key={batch.id} hover>
                        <TableCell>
                          <Typography fontWeight={600} fontSize="0.875rem" sx={{ fontFamily: 'monospace' }}>
                            {batch.batchCode}
                          </Typography>
                        </TableCell>
                        <TableCell>
                          <Typography fontWeight={500}>{batch.recipeName}</Typography>
                        </TableCell>
                        <TableCell>
                          <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
                            <BarcodeIcon sx={{ fontSize: 16, color: 'text.secondary' }} />
                            <Typography variant="body2" sx={{ fontFamily: 'monospace' }}>{batch.barcode}</Typography>
                          </Box>
                        </TableCell>
                        <TableCell align="center">{batch.quantityProduced}</TableCell>
                        <TableCell align="center">
                          <Typography
                            fontWeight={700}
                            sx={{ color: batch.quantityAvailable > 0 ? '#4caf50' : 'text.disabled' }}
                          >
                            {batch.quantityAvailable}
                          </Typography>
                        </TableCell>
                        <TableCell>
                          <Typography variant="body2">{formatDateTime(batch.expectedExpiry)}</Typography>
                          <Chip
                            label={expiryLabel(batch.expectedExpiry)}
                            size="small"
                            color={status.color}
                            variant="outlined"
                            sx={{ mt: 0.5, fontSize: '0.7rem' }}
                          />
                        </TableCell>
                        <TableCell>
                          <Typography variant="body2">{batch.locationName}</Typography>
                        </TableCell>
                        <TableCell align="center">
                          <Chip label={status.label} size="small" color={status.color} variant="filled" />
                        </TableCell>
                        <TableCell align="center">
                          {isBatchMaintainable(batch) && (
                            <Tooltip title="Maintain / Repair">
                              <IconButton
                                size="small"
                                onClick={() => setMaintenanceBatch(batch)}
                                sx={{ color: '#ff9800' }}
                              >
                                <MaintainIcon fontSize="small" />
                              </IconButton>
                            </Tooltip>
                          )}
                        </TableCell>
                      </TableRow>
                    );
                  })
                )}
              </TableBody>
            </Table>
          </TableContainer>
        </Card>

        {/* ── Maintenance Modal ─────────────────────────── */}
        {maintenanceBatch && (
          <MaintenanceModal
            open={Boolean(maintenanceBatch)}
            batch={maintenanceBatch}
            onClose={() => setMaintenanceBatch(null)}
            onComplete={() => {
              setMaintenanceBatch(null);
              loadBatches();
            }}
          />
        )}
      </Container>
    </Box>
  );
};

export default FinishedGoodsInventory;
