/**
 * Stock Movement Ledger — Main Page
 * Florist POS + ERP SaaS Platform
 *
 * Complete transaction history of every inventory movement:
 * purchases, sales, adjustments, transfers.
 *
 * Orchestrates: LedgerSummaryPanel, LedgerFilterBar, LedgerTable
 */

import { useState, useEffect, useMemo, useCallback } from 'react';
import {
  Box,
  Container,
  Typography,
  IconButton,
  Tooltip,
  Chip,
  alpha,
} from '@mui/material';
import DarkModeIcon from '@mui/icons-material/DarkMode';
import LightModeIcon from '@mui/icons-material/LightMode';
import MenuBookIcon from '@mui/icons-material/MenuBook';

import type { StockMovement, LedgerFilterState } from './data/ledger.data';
import { fetchMovements, DEFAULT_LEDGER_FILTERS } from './data/ledger.data';
import { computeLedgerSummary, filterAndSort } from './utils/ledger.utils';

import LedgerSummaryPanel from './components/LedgerSummaryPanel';
import LedgerFilterBar from './components/LedgerFilterBar';
import LedgerTable from './components/LedgerTable';

const StockMovementLedger = () => {
  // ── State ──────────────────────────────────────────────────
  const [darkMode, setDarkMode] = useState(false);
  const [loading, setLoading] = useState(true);
  const [allMovements, setAllMovements] = useState<StockMovement[]>([]);
  const [filters, setFilters] = useState<LedgerFilterState>(DEFAULT_LEDGER_FILTERS);
  const [page, setPage] = useState(0);
  const [rowsPerPage, setRowsPerPage] = useState(10);

  // ── Load data ──────────────────────────────────────────────
  useEffect(() => {
    let cancelled = false;
    setLoading(true);
    fetchMovements().then((data) => {
      if (!cancelled) {
        setAllMovements(data);
        setLoading(false);
      }
    });
    return () => {
      cancelled = true;
    };
  }, []);

  // ── Derived data ───────────────────────────────────────────
  const filtered = useMemo(
    () => filterAndSort(allMovements, filters),
    [allMovements, filters],
  );

  const summary = useMemo(
    () => (filtered.length > 0 ? computeLedgerSummary(filtered) : null),
    [filtered],
  );

  // Reset page on filter change
  const handleFilterChange = useCallback((f: LedgerFilterState) => {
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

  // Movement type breakdown for header chip
  const typeBreakdown = useMemo(() => {
    const counts: Record<string, number> = {};
    for (const mv of filtered) {
      counts[mv.referenceType] = (counts[mv.referenceType] ?? 0) + 1;
    }
    return counts;
  }, [filtered]);

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
            <MenuBookIcon
              sx={{ fontSize: 28, color: darkMode ? '#90caf9' : '#1565c0' }}
            />
            <Box>
              <Typography
                variant="h5"
                sx={{ fontWeight: 800, color: textPrimary, lineHeight: 1.2 }}
              >
                Stock Movement Ledger
              </Typography>
              <Typography
                variant="body2"
                sx={{ color: textSecondary, fontSize: '0.8rem' }}
              >
                Complete transaction history — purchases, sales, adjustments &amp; transfers
              </Typography>
            </Box>
          </Box>

          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, flexWrap: 'wrap' }}>
            {/* Type breakdown chips */}
            {Object.entries(typeBreakdown).map(([type, count]) => (
              <Chip
                key={type}
                label={`${count} ${type}${count > 1 ? 's' : ''}`}
                size="small"
                variant="outlined"
                sx={{
                  fontWeight: 600,
                  fontSize: '0.68rem',
                  height: 24,
                  borderColor: darkMode ? 'rgba(255,255,255,0.12)' : alpha('#1565c0', 0.2),
                  color: darkMode ? 'grey.400' : 'grey.600',
                }}
              />
            ))}

            <Chip
              label={`${filtered.length} of ${allMovements.length} entries`}
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

        {/* ── Summary Panel ───────────────────────────────── */}
        <Box sx={{ mb: 3 }}>
          <LedgerSummaryPanel
            summary={summary}
            loading={loading}
            darkMode={darkMode}
          />
        </Box>

        {/* ── Filter Bar ──────────────────────────────────── */}
        <Box sx={{ mb: 3 }}>
          <LedgerFilterBar
            filters={filters}
            onChange={handleFilterChange}
            movements={filtered}
            darkMode={darkMode}
          />
        </Box>

        {/* ── Ledger Table ────────────────────────────────── */}
        <LedgerTable
          movements={filtered}
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

export default StockMovementLedger;
