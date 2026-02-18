/**
 * InventoryHealthDashboard — Main executive dashboard page
 *
 * Layout:
 *  - Header with title + date range selector
 *  - 6 KPI summary cards (responsive grid)
 *  - Row 1: Aging Distribution (donut) + Wastage Trend (area)
 *  - Row 2: Expiry Trend (stacked bar) + Top 10 Inventory (horizontal bar)
 *  - Row 3: Slow Moving Items (table with progress bars)
 */
import React, { useCallback, useEffect, useState } from 'react';
import {
  Box,
  Typography,
  CircularProgress,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  useTheme,
  Divider,
} from '@mui/material';
import type { SxProps, Theme } from '@mui/material/styles';
import type { SelectChangeEvent } from '@mui/material/Select';

import type { DashboardData, DateRange } from './data/health.data';
import { DATE_RANGE_OPTIONS, DEFAULT_DATE_RANGE, fetchDashboardData } from './data/health.data';

import HealthSummaryCards    from './components/HealthSummaryCards';
import AgingDistributionChart from './components/AgingDistributionChart';
import WastageTrendChart     from './components/WastageTrendChart';
import ExpiryTrendChart      from './components/ExpiryTrendChart';
import TopInventoryChart     from './components/TopInventoryChart';
import SlowMovingItemsChart  from './components/SlowMovingItemsChart';

const InventoryHealthDashboard: React.FC = () => {
  const theme = useTheme();
  const darkMode = theme.palette.mode === 'dark';

  const [dateRange, setDateRange] = useState<DateRange>(DEFAULT_DATE_RANGE);
  const [data, setData]           = useState<DashboardData | null>(null);
  const [loading, setLoading]     = useState(true);

  const loadData = useCallback(async (range: DateRange) => {
    setLoading(true);
    const result = await fetchDashboardData(range);
    setData(result);
    setLoading(false);
  }, []);

  useEffect(() => {
    loadData(dateRange);
  }, [dateRange, loadData]);

  const handleDateRangeChange = (e: SelectChangeEvent) => {
    const selected = DATE_RANGE_OPTIONS.find((r) => r.label === e.target.value);
    if (selected) setDateRange(selected);
  };

  const bgColor = darkMode ? '#0f0f0f' : '#f8f9fa';

  const fieldSx: SxProps<Theme> = darkMode
    ? {
        '& .MuiOutlinedInput-root': {
          color: '#e0e0e0',
          '& fieldset': { borderColor: 'rgba(255,255,255,0.2)' },
          '&:hover fieldset': { borderColor: 'rgba(255,255,255,0.4)' },
          '&.Mui-focused fieldset': { borderColor: theme.palette.primary.main },
        },
        '& .MuiInputLabel-root': { color: 'rgba(255,255,255,0.6)' },
        '& .MuiSelect-icon': { color: 'rgba(255,255,255,0.5)' },
      }
    : {};

  if (loading || !data) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', minHeight: 400, bgcolor: bgColor }}>
        <CircularProgress />
      </Box>
    );
  }

  return (
    <Box sx={{ p: { xs: 2, md: 3 }, bgcolor: bgColor, minHeight: '100vh' }}>
      {/* ─── Header ────────────────────────────────────────── */}
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
            Inventory Health Dashboard
          </Typography>
          <Typography
            variant="body2"
            sx={{ color: darkMode ? 'rgba(255,255,255,0.5)' : 'text.secondary' }}
          >
            Executive overview of inventory performance, wastage, aging & valuation
          </Typography>
        </Box>

        {/* Date Range Selector */}
        <FormControl size="small" sx={{ minWidth: 180, ...fieldSx }}>
          <InputLabel>Date Range</InputLabel>
          <Select
            value={dateRange.label}
            label="Date Range"
            onChange={handleDateRangeChange}
          >
            {DATE_RANGE_OPTIONS.map((r) => (
              <MenuItem key={r.label} value={r.label}>
                {r.label}
              </MenuItem>
            ))}
          </Select>
        </FormControl>
      </Box>

      {/* ─── Summary KPIs ──────────────────────────────────── */}
      <HealthSummaryCards metrics={data.summary} />

      <Divider sx={{ mb: 3, borderColor: darkMode ? 'rgba(255,255,255,0.08)' : undefined }} />

      {/* ─── Row 1: Aging + Wastage ────────────────────────── */}
      <Box
        sx={{
          display: 'grid',
          gridTemplateColumns: { xs: '1fr', lg: '1fr 1.5fr' },
          gap: 2.5,
          mb: 2.5,
        }}
      >
        <AgingDistributionChart data={data.aging} />
        <WastageTrendChart data={data.wastageTrend} />
      </Box>

      {/* ─── Row 2: Expiry + Top 10 ────────────────────────── */}
      <Box
        sx={{
          display: 'grid',
          gridTemplateColumns: { xs: '1fr', lg: '1fr 1fr' },
          gap: 2.5,
          mb: 2.5,
        }}
      >
        <ExpiryTrendChart data={data.expiryTrend} />
        <TopInventoryChart data={data.topInventory} />
      </Box>

      {/* ─── Row 3: Slow Moving ────────────────────────────── */}
      <Box sx={{ mb: 3 }}>
        <SlowMovingItemsChart data={data.slowMoving} />
      </Box>

      {/* ─── Footer ────────────────────────────────────────── */}
      <Box sx={{ textAlign: 'center', py: 2 }}>
        <Typography variant="caption" sx={{ color: darkMode ? 'rgba(255,255,255,0.3)' : 'text.disabled' }}>
          Data refreshed from {dateRange.label.toLowerCase()} · Last updated: {new Date().toLocaleString('en-IN')}
        </Typography>
      </Box>
    </Box>
  );
};

export default InventoryHealthDashboard;
