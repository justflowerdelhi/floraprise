/**
 * Inventory Valuation Report — Main Page
 * Florist POS + ERP SaaS Platform
 *
 * FIFO-based inventory valuation with drill-down into cost layers.
 * Orchestrates: ValuationSummaryCards, ValuationFilterBar, ValuationTable
 */

import { useState, useEffect, useMemo, useCallback } from 'react';
import {
  Box,
  Container,
  Typography,
  IconButton,
  Tooltip,
  Chip,
} from '@mui/material';
import DarkModeIcon from '@mui/icons-material/DarkMode';
import LightModeIcon from '@mui/icons-material/LightMode';
import AssessmentIcon from '@mui/icons-material/Assessment';

import type { ValuationProduct, ValuationFilterState } from './data/valuation.data';
import { fetchValuationData, DEFAULT_VALUATION_FILTERS } from './data/valuation.data';
import {
  computeValuationSummary,
  filterAndSort,
  fmt,
  fmtDate,
} from './utils/valuation.utils';

import ValuationSummaryCards from './components/ValuationSummaryCards';
import ValuationFilterBar from './components/ValuationFilterBar';
import ValuationTable from './components/ValuationTable';

const InventoryValuationReport = () => {
  // ── State ──────────────────────────────────────────────────
  const [darkMode, setDarkMode] = useState(false);
  const [loading, setLoading] = useState(true);
  const [allProducts, setAllProducts] = useState<ValuationProduct[]>([]);
  const [filters, setFilters] = useState<ValuationFilterState>(DEFAULT_VALUATION_FILTERS);
  const [page, setPage] = useState(0);
  const [rowsPerPage, setRowsPerPage] = useState(10);

  // ── Load data ──────────────────────────────────────────────
  useEffect(() => {
    let cancelled = false;
    setLoading(true);
    fetchValuationData().then((data) => {
      if (!cancelled) {
        setAllProducts(data);
        setLoading(false);
      }
    });
    return () => {
      cancelled = true;
    };
  }, []);

  // ── Derived data ───────────────────────────────────────────
  const filtered = useMemo(
    () => filterAndSort(allProducts, filters),
    [allProducts, filters],
  );

  const summary = useMemo(
    () => (filtered.length > 0 ? computeValuationSummary(filtered) : null),
    [filtered],
  );

  // Reset page on filter change
  const handleFilterChange = useCallback((f: ValuationFilterState) => {
    setFilters(f);
    setPage(0);
  }, []);

  const handleRowsPerPageChange = useCallback((r: number) => {
    setRowsPerPage(r);
    setPage(0);
  }, []);

  const handleSortChange = useCallback(
    (field: ValuationFilterState['sortField']) => {
      setFilters((prev) => ({
        ...prev,
        sortField: field,
        sortDir:
          prev.sortField === field
            ? prev.sortDir === 'desc'
              ? 'asc'
              : 'desc'
            : 'desc',
      }));
      setPage(0);
    },
    [],
  );

  // ── Styling ────────────────────────────────────────────────
  const bgColor = darkMode ? '#0f0f0f' : '#f8f9fa';
  const textPrimary = darkMode ? '#f5f5f5' : '#1a1a1a';
  const textSecondary = darkMode ? '#9e9e9e' : '#666';

  const valuationDate = fmtDate(new Date().toISOString());

  return (
    <Box
      sx={{
        minHeight: '100vh',
        backgroundColor: bgColor,
        transition: 'background-color 0.3s ease',
        pb: 6,
        '@media print': {
          backgroundColor: '#fff',
          '& .no-print': { display: 'none !important' },
        },
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
            <AssessmentIcon
              sx={{ fontSize: 28, color: darkMode ? '#90caf9' : '#1565c0' }}
            />
            <Box>
              <Typography
                variant="h5"
                sx={{ fontWeight: 800, color: textPrimary, lineHeight: 1.2 }}
              >
                Inventory Valuation Report
              </Typography>
              <Typography
                variant="body2"
                sx={{ color: textSecondary, fontSize: '0.8rem' }}
              >
                FIFO method · As of {valuationDate} · {fmt(summary?.totalInventoryValue ?? 0)} total value
              </Typography>
            </Box>
          </Box>

          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, flexWrap: 'wrap' }}>
            <Chip
              label={`${filtered.length} of ${allProducts.length} products`}
              size="small"
              variant="outlined"
              sx={{
                fontWeight: 600,
                fontSize: '0.72rem',
                borderColor: darkMode ? 'rgba(255,255,255,0.15)' : undefined,
                color: darkMode ? 'grey.400' : undefined,
              }}
            />

            <Tooltip
              title={darkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode'}
            >
              <IconButton
                className="no-print"
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

        {/* ── Summary Cards ───────────────────────────────── */}
        <Box sx={{ mb: 3 }}>
          <ValuationSummaryCards
            summary={summary}
            loading={loading}
            darkMode={darkMode}
          />
        </Box>

        {/* ── Filter Bar ──────────────────────────────────── */}
        <Box sx={{ mb: 3 }} className="no-print">
          <ValuationFilterBar
            filters={filters}
            onChange={handleFilterChange}
            products={filtered}
            darkMode={darkMode}
          />
        </Box>

        {/* ── Valuation Table ─────────────────────────────── */}
        <ValuationTable
          products={filtered}
          loading={loading}
          darkMode={darkMode}
          page={page}
          rowsPerPage={rowsPerPage}
          onPageChange={setPage}
          onRowsPerPageChange={handleRowsPerPageChange}
          sortField={filters.sortField}
          sortDir={filters.sortDir}
          onSortChange={handleSortChange}
        />
      </Container>
    </Box>
  );
};

export default InventoryValuationReport;
