/**
 * ReorderIntelligence — Main orchestrator page
 *
 * Features:
 *  - 5 KPI summary cards (stockout, low, optimal, overstock, total cost)
 *  - Filter bar (search, risk, supplier, category)
 *  - Sortable table with bulk-select checkboxes & smart risk badges
 *  - "Generate Purchase Order" action button
 *  - Dark mode support
 */
import React, { useCallback, useEffect, useMemo, useState } from 'react';
import {
  Box,
  Button,
  CircularProgress,
  Snackbar,
  Alert,
  Typography,
  useTheme,
  Divider,
  Chip,
} from '@mui/material';
import {
  ShoppingCartCheckout as POIcon,
  Refresh as RefreshIcon,
} from '@mui/icons-material';

import type { ReorderProduct, ReorderFilterState } from './data/reorder.data';
import { DEFAULT_REORDER_FILTERS, fetchReorderData } from './data/reorder.data';
import { filterAndSort, computeSummary, generatePO, fmtCurrency } from './utils/reorder.utils';
import type { GeneratedPO } from './utils/reorder.utils';

import ReorderSummaryCards from './components/ReorderSummaryCards';
import ReorderFilterBar   from './components/ReorderFilterBar';
import ReorderTable        from './components/ReorderTable';

const ReorderIntelligence: React.FC = () => {
  const theme = useTheme();
  const darkMode = theme.palette.mode === 'dark';

  // ─── State ──────────────────────────────────────────────
  const [allProducts, setAllProducts]   = useState<ReorderProduct[]>([]);
  const [loading, setLoading]           = useState(true);
  const [filters, setFilters]           = useState<ReorderFilterState>(DEFAULT_REORDER_FILTERS);
  const [selected, setSelected]         = useState<Set<string>>(new Set());
  const [generatingPO, setGeneratingPO] = useState(false);
  const [lastPO, setLastPO]             = useState<GeneratedPO | null>(null);
  const [snackOpen, setSnackOpen]       = useState(false);

  // ─── Fetch data ─────────────────────────────────────────
  const loadData = useCallback(async () => {
    setLoading(true);
    const data = await fetchReorderData();
    setAllProducts(data);
    setSelected(new Set());
    setLoading(false);
  }, []);

  useEffect(() => {
    loadData();
  }, [loadData]);

  // ─── Derived ────────────────────────────────────────────
  const filteredProducts = useMemo(
    () => filterAndSort(allProducts, filters),
    [allProducts, filters],
  );

  const summary = useMemo(() => computeSummary(allProducts), [allProducts]);

  const selectedCost = useMemo(() => {
    return allProducts
      .filter((p) => selected.has(p.id))
      .reduce((s, p) => s + p.estimatedOrderCost, 0);
  }, [allProducts, selected]);

  // ─── Handlers ───────────────────────────────────────────
  const handleToggle = (id: string) => {
    setSelected((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
  };

  const handleToggleAll = () => {
    if (selected.size === filteredProducts.length) {
      setSelected(new Set());
    } else {
      setSelected(new Set(filteredProducts.map((p) => p.id)));
    }
  };

  const handleSort = (field: ReorderFilterState['sortField']) => {
    setFilters((prev) => ({
      ...prev,
      sortField: field,
      sortDir: prev.sortField === field && prev.sortDir === 'asc' ? 'desc' : 'asc',
    }));
  };

  const handleGeneratePO = async () => {
    const items = allProducts.filter((p) => selected.has(p.id));
    if (items.length === 0) return;
    setGeneratingPO(true);
    const po = await generatePO(items);
    setLastPO(po);
    setGeneratingPO(false);
    setSnackOpen(true);
  };

  const handleAutoSelect = () => {
    // Select all stockout + low-stock items automatically
    const urgent = allProducts
      .filter((p) => p.risk === 'stockout' || p.risk === 'low')
      .map((p) => p.id);
    setSelected(new Set(urgent));
  };

  // ─── Render ─────────────────────────────────────────────
  const bgColor = darkMode ? '#0f0f0f' : '#f8f9fa';

  if (loading) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', minHeight: 400 }}>
        <CircularProgress />
      </Box>
    );
  }

  return (
    <Box sx={{ p: { xs: 2, md: 3 }, bgcolor: bgColor, minHeight: '100vh' }}>
      {/* Header */}
      <Box
        sx={{
          display: 'flex',
          flexWrap: 'wrap',
          justifyContent: 'space-between',
          alignItems: 'center',
          mb: 3,
          gap: 2,
        }}
      >
        <Box>
          <Typography variant="h4" sx={{ fontWeight: 800, mb: 0.5 }}>
            Reorder Intelligence
          </Typography>
          <Typography
            variant="body2"
            sx={{ color: darkMode ? 'rgba(255,255,255,0.5)' : 'text.secondary' }}
          >
            AI-predicted reorder suggestions based on usage trends, lead times & safety stock
          </Typography>
        </Box>

        <Box sx={{ display: 'flex', gap: 1, flexWrap: 'wrap' }}>
          <Button
            variant="outlined"
            startIcon={<RefreshIcon />}
            onClick={loadData}
            size="small"
            sx={darkMode ? { borderColor: 'rgba(255,255,255,0.2)', color: '#e0e0e0' } : {}}
          >
            Refresh
          </Button>
          <Button
            variant="outlined"
            size="small"
            onClick={handleAutoSelect}
            sx={darkMode ? { borderColor: 'rgba(255,255,255,0.2)', color: '#e0e0e0' } : {}}
          >
            Auto-Select Urgent
          </Button>
          <Button
            variant="contained"
            startIcon={generatingPO ? <CircularProgress size={18} color="inherit" /> : <POIcon />}
            onClick={handleGeneratePO}
            disabled={selected.size === 0 || generatingPO}
            sx={{
              fontWeight: 700,
              bgcolor: darkMode ? '#fdd835' : undefined,
              color: darkMode ? '#000' : undefined,
              '&:hover': { bgcolor: darkMode ? '#fbc02d' : undefined },
              '&.Mui-disabled': {
                bgcolor: darkMode ? 'rgba(255,255,255,0.08)' : undefined,
                color: darkMode ? 'rgba(255,255,255,0.3)' : undefined,
              },
            }}
          >
            Generate Purchase Order
          </Button>
        </Box>
      </Box>

      {/* Selection info bar */}
      {selected.size > 0 && (
        <Box
          sx={{
            display: 'flex',
            alignItems: 'center',
            gap: 2,
            mb: 2,
            px: 2,
            py: 1,
            borderRadius: 1,
            bgcolor: darkMode ? 'rgba(253,216,53,0.08)' : 'rgba(25,118,210,0.06)',
            border: `1px solid ${darkMode ? 'rgba(253,216,53,0.2)' : 'rgba(25,118,210,0.15)'}`,
          }}
        >
          <Chip
            label={`${selected.size} item${selected.size > 1 ? 's' : ''} selected`}
            size="small"
            color="primary"
            variant="outlined"
          />
          <Typography variant="body2" sx={{ fontWeight: 600 }}>
            Estimated PO total: {fmtCurrency(selectedCost)}
          </Typography>
          <Button
            size="small"
            onClick={() => setSelected(new Set())}
            sx={{ ml: 'auto', textTransform: 'none' }}
          >
            Clear selection
          </Button>
        </Box>
      )}

      {/* Summary KPIs */}
      <ReorderSummaryCards summary={summary} />

      <Divider sx={{ mb: 3, borderColor: darkMode ? 'rgba(255,255,255,0.08)' : undefined }} />

      {/* Filters */}
      <ReorderFilterBar filters={filters} onChange={setFilters} />

      {/* Table */}
      <ReorderTable
        products={filteredProducts}
        selected={selected}
        onToggle={handleToggle}
        onToggleAll={handleToggleAll}
        sortField={filters.sortField}
        sortDir={filters.sortDir}
        onSort={handleSort}
      />

      {/* Results count */}
      <Box sx={{ mt: 1.5, display: 'flex', justifyContent: 'space-between', px: 1 }}>
        <Typography variant="caption" color="text.secondary">
          Showing {filteredProducts.length} of {allProducts.length} products
        </Typography>
        {lastPO && (
          <Typography variant="caption" color="text.secondary">
            Last PO: {lastPO.poNumber} · {lastPO.lines.length} lines · {fmtCurrency(lastPO.totalCost)}
          </Typography>
        )}
      </Box>

      {/* Snackbar */}
      <Snackbar
        open={snackOpen}
        autoHideDuration={5000}
        onClose={() => setSnackOpen(false)}
        anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }}
      >
        <Alert
          severity="success"
          variant="filled"
          onClose={() => setSnackOpen(false)}
          sx={{ width: '100%' }}
        >
          {lastPO
            ? `Purchase Order ${lastPO.poNumber} generated — ${lastPO.lines.length} lines across ${lastPO.supplierCount} supplier(s), total ${fmtCurrency(lastPO.totalCost)}`
            : 'Purchase Order generated'}
        </Alert>
      </Snackbar>
    </Box>
  );
};

export default ReorderIntelligence;
