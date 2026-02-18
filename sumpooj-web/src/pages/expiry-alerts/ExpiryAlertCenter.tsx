/**
 * Expiry Alert Center — Main Page
 * Florist POS + ERP SaaS Platform
 *
 * Centralized dashboard for monitoring product expiry across the supply chain.
 * Orchestrates: ExpirySummaryCards, ExpiryFilterBar, ExpiryAlertTable
 */

import { useState, useEffect, useMemo, useCallback } from 'react';
import {
  Box,
  Container,
  Typography,
  IconButton,
  Tooltip,
  Alert,
  Chip,
  alpha,
} from '@mui/material';
import DarkModeIcon from '@mui/icons-material/DarkMode';
import LightModeIcon from '@mui/icons-material/LightMode';
import NotificationsActiveIcon from '@mui/icons-material/NotificationsActive';
import WarningIcon from '@mui/icons-material/Warning';

import type { ExpiryAlertBatch, ExpiryFilterState } from './data/expiry.data';
import { fetchExpiryBatches, DEFAULT_EXPIRY_FILTERS } from './data/expiry.data';
import {
  enrichBatch,
  computeExpirySummary,
  filterAndSort,
  fmt,
} from './utils/expiry.utils';

import ExpirySummaryCards from './components/ExpirySummaryCards';
import ExpiryFilterBar from './components/ExpiryFilterBar';
import ExpiryAlertTable from './components/ExpiryAlertTable';

const ExpiryAlertCenter = () => {
  // ── State ──────────────────────────────────────────────────
  const [darkMode, setDarkMode] = useState(false);
  const [loading, setLoading] = useState(true);
  const [allBatches, setAllBatches] = useState<ExpiryAlertBatch[]>([]);
  const [filters, setFilters] = useState<ExpiryFilterState>(DEFAULT_EXPIRY_FILTERS);
  const [page, setPage] = useState(0);
  const [rowsPerPage, setRowsPerPage] = useState(10);

  // ── Load & enrich data ─────────────────────────────────────
  useEffect(() => {
    let cancelled = false;
    setLoading(true);
    fetchExpiryBatches().then((raw) => {
      if (!cancelled) {
        setAllBatches(raw.map(enrichBatch));
        setLoading(false);
      }
    });
    return () => {
      cancelled = true;
    };
  }, []);

  // ── Derived data ───────────────────────────────────────────
  const summary = useMemo(
    () => (allBatches.length > 0 ? computeExpirySummary(allBatches) : null),
    [allBatches],
  );

  const filtered = useMemo(
    () => filterAndSort(allBatches, filters),
    [allBatches, filters],
  );

  // Reset page on filter change
  const handleFilterChange = useCallback((f: ExpiryFilterState) => {
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
            <NotificationsActiveIcon
              sx={{ fontSize: 28, color: '#c62828' }}
            />
            <Box>
              <Typography
                variant="h5"
                sx={{ fontWeight: 800, color: textPrimary, lineHeight: 1.2 }}
              >
                Expiry Alert Center
              </Typography>
              <Typography
                variant="body2"
                sx={{ color: textSecondary, fontSize: '0.8rem' }}
              >
                Monitor perishable stock, take action before value is lost
              </Typography>
            </Box>
          </Box>

          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
            <Chip
              label={`${filtered.length} of ${allBatches.length} alerts`}
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

        {/* ── Smart Alert: Expired Stock ──────────────────── */}
        {summary && summary.expiredCount > 0 && (
          <Alert
            severity="error"
            icon={<WarningIcon />}
            sx={{
              mb: 3,
              borderRadius: 2,
              fontWeight: 600,
              backgroundColor: darkMode
                ? alpha('#c62828', 0.15)
                : '#ffebee',
              color: darkMode ? '#ef9a9a' : '#c62828',
              border: `1px solid ${
                darkMode ? alpha('#c62828', 0.3) : alpha('#c62828', 0.2)
              }`,
              '& .MuiAlert-icon': {
                color: darkMode ? '#ef9a9a' : '#c62828',
              },
            }}
          >
            ⚠️ {summary.expiredCount} batch{summary.expiredCount > 1 ? 'es' : ''}{' '}
            have already expired — <strong>{fmt(summary.expiredValue)}</strong>{' '}
            total expired value. Adjust as wastage or mark disposed immediately.
          </Alert>
        )}

        {/* ── Expiring Today Banner ───────────────────────── */}
        {summary && summary.expiringToday > 0 && summary.expiredCount === 0 && (
          <Alert
            severity="warning"
            sx={{
              mb: 3,
              borderRadius: 2,
              fontWeight: 600,
              backgroundColor: darkMode
                ? alpha('#e65100', 0.12)
                : '#fff3e0',
              color: darkMode ? '#ffb74d' : '#e65100',
              border: `1px solid ${
                darkMode ? alpha('#e65100', 0.25) : alpha('#e65100', 0.2)
              }`,
              '& .MuiAlert-icon': {
                color: darkMode ? '#ffb74d' : '#e65100',
              },
            }}
          >
            🕐 {summary.expiringToday} batch{summary.expiringToday > 1 ? 'es' : ''}{' '}
            expire <strong>today</strong> — worth{' '}
            <strong>{fmt(summary.expiringTodayValue)}</strong>. Consider discounting
            or prioritizing in POS.
          </Alert>
        )}

        {/* ── Summary Cards ───────────────────────────────── */}
        <Box sx={{ mb: 3 }}>
          <ExpirySummaryCards
            summary={summary}
            loading={loading}
            darkMode={darkMode}
          />
        </Box>

        {/* ── Filter Bar ──────────────────────────────────── */}
        <Box sx={{ mb: 3 }}>
          <ExpiryFilterBar
            filters={filters}
            onChange={handleFilterChange}
            batches={filtered}
            darkMode={darkMode}
          />
        </Box>

        {/* ── Expiry Alert Table ──────────────────────────── */}
        <ExpiryAlertTable
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

export default ExpiryAlertCenter;
