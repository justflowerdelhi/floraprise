/**
 * Inventory Batch Dashboard — Main page
 * Florist POS + ERP SaaS Platform
 *
 * Orchestrates: SummaryCards, FilterBar, BatchTable
 * + Smart alerts, dark mode toggle, loading states
 */

import { useState, useEffect, useMemo, useCallback } from 'react';
import {
  Box,
  Container,
  Typography,
  IconButton,
  Tooltip,
  Alert,
  useTheme,
  alpha,
  Chip,
} from '@mui/material';
import DarkModeIcon from '@mui/icons-material/DarkMode';
import LightModeIcon from '@mui/icons-material/LightMode';
import Inventory2Icon from '@mui/icons-material/Inventory2';
import WarningIcon from '@mui/icons-material/Warning';

import type { InventoryBatch, FilterState } from './data/inventory.data';
import { DEFAULT_FILTERS } from './data/inventory.data';
import { searchBatches } from '../../api/inventory.api';
import { useApiCall } from '../../hooks/useApiCall';
import { useToast } from '../../hooks/useToast';
import { computeSummary, filterAndSort, fmt } from './utils/inventory.utils';

import SummaryCards from './components/SummaryCards';
import FilterBar from './components/FilterBar';
import BatchTable from './components/BatchTable';

const InventoryBatchDashboard = () => {
  const theme = useTheme();
  const { execute, loading: apiLoading } = useApiCall();
  const toast = useToast();

  // ── State ──────────────────────────────────────────────────
  const [darkMode, setDarkMode] = useState(false);
  const [batches, setBatches] = useState<InventoryBatch[]>([]);
  const [filters, setFilters] = useState<FilterState>(DEFAULT_FILTERS);
  const [page, setPage] = useState(0);
  const [rowsPerPage, setRowsPerPage] = useState(10);
  const [initialLoad, setInitialLoad] = useState(true);

  const loading = apiLoading || initialLoad;

  // ── Load data ──────────────────────────────────────────────
  useEffect(() => {
    let cancelled = false;
    const loadBatches = async () => {
      const data = await execute(() => searchBatches(), {
        errorMessage: 'Failed to load inventory batches',
      });
      if (!cancelled && data) {
        setBatches(data.items ?? data);
        toast.info(`Loaded ${(data.items ?? data).length} batches`);
      }
      if (!cancelled) setInitialLoad(false);
    };
    loadBatches();
    return () => {
      cancelled = true;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  // ── Derived data ───────────────────────────────────────────
  const summary = useMemo(
    () => (batches.length > 0 ? computeSummary(batches) : null),
    [batches],
  );

  const filtered = useMemo(
    () => filterAndSort(batches, filters),
    [batches, filters],
  );

  // Reset page on filter change
  const handleFilterChange = useCallback((f: FilterState) => {
    setFilters(f);
    setPage(0);
  }, []);

  const handleRowsPerPageChange = useCallback((r: number) => {
    setRowsPerPage(r);
    setPage(0);
  }, []);

  // ── Styling ────────────────────────────────────────────────
  const bgColor = darkMode ? '#0f0f0f' : '#f8f9fa';
  const textPrimary = darkMode ? '#f5f5f5' : '#1a1a1a';
  const textSecondary = darkMode ? '#9e9e9e' : '#666';

  return (
    <Box
      sx={{
        minHeight: '100vh',
        backgroundColor: bgColor,
        transition: 'background-color 0.3s ease',
        pb: 6,
      }}
    >
      <Container maxWidth="xl" sx={{ pt: 3 }}>
        {/* ── Header ──────────────────────────────────────── */}
        <Box
          sx={{
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
            mb: 3,
            flexWrap: 'wrap',
            gap: 1,
          }}
        >
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
            <Inventory2Icon sx={{ fontSize: 28, color: theme.palette.primary.main }} />
            <Box>
              <Typography
                variant="h5"
                sx={{ fontWeight: 800, color: textPrimary, lineHeight: 1.2 }}
              >
                Inventory Batch Dashboard
              </Typography>
              <Typography variant="body2" sx={{ color: textSecondary, fontSize: '0.8rem' }}>
                Track batches, monitor expiry risk & manage stock levels
              </Typography>
            </Box>
          </Box>

          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
            <Chip
              label={`${filtered.length} of ${batches.length} batches`}
              size="small"
              variant="outlined"
              sx={{
                fontWeight: 600,
                fontSize: '0.72rem',
                borderColor: darkMode ? 'rgba(255,255,255,0.15)' : undefined,
                color: darkMode ? 'grey.400' : undefined,
              }}
            />
            <Tooltip title={darkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode'}>
              <IconButton
                onClick={() => setDarkMode((v) => !v)}
                sx={{
                  color: darkMode ? '#fdd835' : '#616161',
                  backgroundColor: darkMode
                    ? 'rgba(255,255,255,0.05)'
                    : 'rgba(0,0,0,0.04)',
                  '&:hover': {
                    backgroundColor: darkMode
                      ? 'rgba(255,255,255,0.1)'
                      : 'rgba(0,0,0,0.08)',
                  },
                }}
              >
                {darkMode ? <LightModeIcon /> : <DarkModeIcon />}
              </IconButton>
            </Tooltip>
          </Box>
        </Box>

        {/* ── Smart Alert: Expired Inventory ──────────────── */}
        {summary && summary.expiredCount > 0 && (
          <Alert
            severity="error"
            icon={<WarningIcon />}
            sx={{
              mb: 3,
              borderRadius: 2,
              fontWeight: 600,
              backgroundColor: darkMode ? alpha('#c62828', 0.15) : '#ffebee',
              color: darkMode ? '#ef9a9a' : '#c62828',
              border: `1px solid ${darkMode ? alpha('#c62828', 0.3) : alpha('#c62828', 0.2)}`,
              '& .MuiAlert-icon': {
                color: darkMode ? '#ef9a9a' : '#c62828',
              },
            }}
          >
            ⚠️ {summary.expiredCount} batch{summary.expiredCount > 1 ? 'es' : ''} have expired —{' '}
            <strong>{fmt(summary.expiredValue)}</strong> total expired value. Review and dispose
            immediately.
          </Alert>
        )}

        {/* ── Summary Cards ───────────────────────────────── */}
        <Box sx={{ mb: 3 }}>
          <SummaryCards summary={summary} loading={loading} darkMode={darkMode} />
        </Box>

        {/* ── Filter Bar ──────────────────────────────────── */}
        <Box sx={{ mb: 3 }}>
          <FilterBar
            filters={filters}
            onChange={handleFilterChange}
            batches={filtered}
            darkMode={darkMode}
          />
        </Box>

        {/* ── Batch Table ─────────────────────────────────── */}
        <BatchTable
          batches={filtered}
          loading={loading}
          darkMode={darkMode}
          page={page}
          rowsPerPage={rowsPerPage}
          onPageChange={setPage}
          onRowsPerPageChange={handleRowsPerPageChange}
        />
      </Container>
    </Box>
  );
};

export default InventoryBatchDashboard;
