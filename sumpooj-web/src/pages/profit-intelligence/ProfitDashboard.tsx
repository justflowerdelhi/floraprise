/**
 * ProfitDashboard.tsx — Enterprise Profit Intelligence Dashboard
 *
 * Executive-level view with:
 * - Summary cards (revenue, profit, COGS, wastage, etc.)
 * - Date range filtering
 * - Tabbed sections for detailed reports
 */
import React, { useState, useEffect, useMemo } from 'react';
import {
  Box, Typography, Card, CardContent, Grid, Button, Chip,
  ToggleButton, ToggleButtonGroup, Skeleton, Tabs, Tab, Divider,
  useTheme, alpha,
} from '@mui/material';
import {
  TrendingUp as RevenueIcon,
  TrendingDown as ExpenseIcon,
  AccountBalance as ProfitIcon,
  LocalShipping as ChannelIcon,
  Inventory as InventoryIcon,
  Payment as PaymentIcon,
  Assessment as ReportIcon,
  CalendarToday as CalendarIcon,
  CompareArrows as CompareIcon,
  Warning as WastageIcon,
} from '@mui/icons-material';
import {
  LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip,
  ResponsiveContainer, Legend, Area, AreaChart,
} from 'recharts';
import type {
  DateRangePreset, ProfitDashboardData, ExecutiveSummary,
} from './ProfitTypes';
import { DATE_RANGE_CONFIG } from './ProfitTypes';
import { fetchProfitDashboardData } from './ProfitMockData';
import ChannelProfitChart from './ChannelProfitChart';
import ProductProfitTable from './ProductProfitTable';
import CommissionReport from './CommissionReport';
import InventoryImpactReport from './InventoryImpactReport';
import PaymentAnalysis from './PaymentAnalysis';

// ─── Formatters (tenant-aware) ───────────────────────────────

import { formatCurrency, formatCurrencyCompact, formatPercent } from '../../core/i18n';

const fmtCurrency = (v: number) => formatCurrency(v);
const fmtPercent = (v: number) => formatPercent(v);
const fmtCompact = (v: number) => formatCurrencyCompact(v);

// ─── Summary Card Component ─────────────────────────────────

interface SummaryCardProps {
  title: string;
  value: string;
  subtitle?: string;
  icon: React.ReactNode;
  color: string;
  trend?: { value: number; isPositive: boolean };
  loading?: boolean;
}

const SummaryCard: React.FC<SummaryCardProps> = ({
  title, value, subtitle, icon, color, trend, loading,
}) => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';

  if (loading) {
    return (
      <Card
        elevation={dk ? 0 : 1}
        sx={{
          bgcolor: dk ? '#1a1a2e' : '#fff',
          border: dk ? '1px solid rgba(255,255,255,0.06)' : 'none',
          borderRadius: 2,
        }}
      >
        <CardContent>
          <Skeleton variant="text" width={100} />
          <Skeleton variant="text" width={120} height={40} />
          <Skeleton variant="text" width={80} />
        </CardContent>
      </Card>
    );
  }

  return (
    <Card
      elevation={dk ? 0 : 1}
      sx={{
        bgcolor: dk ? '#1a1a2e' : '#fff',
        border: dk ? '1px solid rgba(255,255,255,0.06)' : 'none',
        borderRadius: 2,
        transition: 'all 0.2s',
        '&:hover': {
          transform: 'translateY(-2px)',
          boxShadow: dk ? '0 8px 24px rgba(0,0,0,0.3)' : '0 4px 16px rgba(0,0,0,0.1)',
        },
      }}
    >
      <CardContent sx={{ p: 2, '&:last-child': { pb: 2 } }}>
        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', mb: 1 }}>
          <Typography
            variant="caption"
            sx={{
              fontWeight: 600,
              textTransform: 'uppercase',
              letterSpacing: 0.5,
              color: dk ? 'rgba(255,255,255,0.5)' : 'text.secondary',
            }}
          >
            {title}
          </Typography>
          <Box
            sx={{
              p: 0.75,
              borderRadius: 1.5,
              bgcolor: alpha(color, dk ? 0.15 : 0.1),
              color,
              display: 'flex',
            }}
          >
            {icon}
          </Box>
        </Box>

        <Typography variant="h5" sx={{ fontWeight: 800, mb: 0.5/*, color: dk ? '#fff' : 'inherit'*/ }}>
          {value}
        </Typography>

        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
          {trend && (
            <Chip
              size="small"
              label={`${trend.isPositive ? '+' : ''}${trend.value.toFixed(1)}%`}
              sx={{
                fontWeight: 700,
                fontSize: '0.7rem',
                height: 20,
                bgcolor: alpha(trend.isPositive ? '#4caf50' : '#f44336', dk ? 0.2 : 0.12),
                color: trend.isPositive ? '#4caf50' : '#f44336',
              }}
            />
          )}
          {subtitle && (
            <Typography variant="caption" sx={{ color: dk ? 'rgba(255,255,255,0.4)' : 'text.disabled' }}>
              {subtitle}
            </Typography>
          )}
        </Box>
      </CardContent>
    </Card>
  );
};

// ─── Main Dashboard Component ───────────────────────────────

const ProfitDashboard: React.FC = () => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';
  const bgColor = dk ? '#0f0f0f' : '#f8f9fa';

  // State
  const [dateRange, setDateRange] = useState<DateRangePreset>('LAST_30_DAYS');
  const [data, setData] = useState<ProfitDashboardData | null>(null);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState(0);

  // Fetch data on mount & date change
  useEffect(() => {
    const loadData = async () => {
      setLoading(true);
      const today = new Date().toISOString().slice(0, 10);
      const startDate = getStartDate(dateRange);
      const result = await fetchProfitDashboardData(startDate, today);
      setData(result);
      setLoading(false);
    };
    loadData();
  }, [dateRange]);

  const getStartDate = (preset: DateRangePreset): string => {
    const d = new Date();
    switch (preset) {
      case 'TODAY':
        return d.toISOString().slice(0, 10);
      case 'YESTERDAY':
        d.setDate(d.getDate() - 1);
        return d.toISOString().slice(0, 10);
      case 'LAST_7_DAYS':
        d.setDate(d.getDate() - 7);
        return d.toISOString().slice(0, 10);
      case 'LAST_30_DAYS':
        d.setDate(d.getDate() - 30);
        return d.toISOString().slice(0, 10);
      default:
        d.setDate(d.getDate() - 30);
        return d.toISOString().slice(0, 10);
    }
  };

  // Summary calculations
  const summary = data?.summary;
  const revenueTrend = useMemo(() => {
    if (!summary?.comparisonPeriod) return null;
    const change = ((summary.grossRevenue - summary.comparisonPeriod.grossRevenue) /
      summary.comparisonPeriod.grossRevenue) * 100;
    return { value: change, isPositive: change >= 0 };
  }, [summary]);

  const profitTrend = useMemo(() => {
    if (!summary?.comparisonPeriod) return null;
    const change = ((summary.netProfit - summary.comparisonPeriod.netProfit) /
      summary.comparisonPeriod.netProfit) * 100;
    return { value: change, isPositive: change >= 0 };
  }, [summary]);

  return (
    <Box sx={{ p: { xs: 2, md: 3 }, bgcolor: bgColor, minHeight: '100vh' }}>
      {/* ─── Header ─────────────────────────────────────── */}
      <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', mb: 3, flexWrap: 'wrap', gap: 2 }}>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
          <ReportIcon sx={{ fontSize: 36, color: '#fdd835' }} />
          <Box>
            <Typography variant="h4" sx={{ fontWeight: 800 }}>
              Profit Intelligence
            </Typography>
            <Typography variant="body2" sx={{ color: dk ? 'rgba(255,255,255,0.5)' : 'text.secondary' }}>
              Enterprise-level financial analytics & insights
            </Typography>
          </Box>
        </Box>

        {/* Date Range Selector */}
        <ToggleButtonGroup
          size="small"
          exclusive
          value={dateRange}
          onChange={(_, v) => { if (v) setDateRange(v as DateRangePreset); }}
          sx={{
            '& .MuiToggleButton-root': {
              textTransform: 'none',
              fontWeight: 600,
              px: 2,
              ...(dk ? { color: '#e0e0e0', borderColor: 'rgba(255,255,255,0.15)' } : {}),
            },
            '& .Mui-selected': {
              bgcolor: dk ? 'rgba(253,216,53,0.15)' : undefined,
              color: dk ? '#fdd835' : undefined,
            },
          }}
        >
          {(['TODAY', 'LAST_7_DAYS', 'LAST_30_DAYS', 'THIS_MONTH'] as DateRangePreset[]).map((p) => (
            <ToggleButton key={p} value={p}>
              {DATE_RANGE_CONFIG[p].label}
            </ToggleButton>
          ))}
        </ToggleButtonGroup>
      </Box>

      {/* ─── Executive Summary Cards ────────────────────── */}
      <Grid container spacing={2} sx={{ mb: 4 }}>
        <Grid size={{ xs: 12, sm: 6, md: 3 }}>
          <SummaryCard
            title="Gross Revenue"
            value={summary ? fmtCurrency(summary.grossRevenue) : '—'}
            subtitle={`${summary?.orderCount ?? 0} orders`}
            icon={<RevenueIcon sx={{ fontSize: 20 }} />}
            color="#4caf50"
            trend={revenueTrend ?? undefined}
            loading={loading}
          />
        </Grid>
        <Grid size={{ xs: 12, sm: 6, md: 3 }}>
          <SummaryCard
            title="Commission Paid"
            value={summary ? fmtCurrency(summary.externalCommissionPaid) : '—'}
            subtitle="External platforms"
            icon={<ChannelIcon sx={{ fontSize: 20 }} />}
            color="#ff9800"
            loading={loading}
          />
        </Grid>
        <Grid size={{ xs: 12, sm: 6, md: 3 }}>
          <SummaryCard
            title="Total COGS"
            value={summary ? fmtCurrency(summary.totalCOGS) : '—'}
            subtitle="FIFO costing"
            icon={<InventoryIcon sx={{ fontSize: 20 }} />}
            color="#2196f3"
            loading={loading}
          />
        </Grid>
        <Grid size={{ xs: 12, sm: 6, md: 3 }}>
          <SummaryCard
            title="Net Profit"
            value={summary ? fmtCurrency(summary.netProfit) : '—'}
            subtitle={summary ? fmtPercent(summary.profitMarginPercent) + ' margin' : ''}
            icon={<ProfitIcon sx={{ fontSize: 20 }} />}
            color="#fdd835"
            trend={profitTrend ?? undefined}
            loading={loading}
          />
        </Grid>
        <Grid size={{ xs: 12, sm: 6, md: 3 }}>
          <SummaryCard
            title="Wastage Value"
            value={summary ? fmtCurrency(summary.wastageValue) : '—'}
            subtitle="Inventory loss"
            icon={<WastageIcon sx={{ fontSize: 20 }} />}
            color="#f44336"
            loading={loading}
          />
        </Grid>
        <Grid size={{ xs: 12, sm: 6, md: 3 }}>
          <SummaryCard
            title="Refunds"
            value={summary ? fmtCurrency(summary.refundsIssued) : '—'}
            subtitle="Returns issued"
            icon={<ExpenseIcon sx={{ fontSize: 20 }} />}
            color="#e91e63"
            loading={loading}
          />
        </Grid>
        <Grid size={{ xs: 12, sm: 6, md: 3 }}>
          <SummaryCard
            title="Processing Cost"
            value={summary ? fmtCurrency(summary.paymentProcessingCost) : '—'}
            subtitle="Card fees"
            icon={<PaymentIcon sx={{ fontSize: 20 }} />}
            color="#9c27b0"
            loading={loading}
          />
        </Grid>
        <Grid size={{ xs: 12, sm: 6, md: 3 }}>
          <SummaryCard
            title="Avg Order Value"
            value={summary ? fmtCurrency(summary.avgOrderValue) : '—'}
            subtitle="Per transaction"
            icon={<CompareIcon sx={{ fontSize: 20 }} />}
            color="#00bcd4"
            loading={loading}
          />
        </Grid>
      </Grid>

      {/* ─── Revenue Trend Chart ────────────────────────── */}
      <Card
        elevation={dk ? 0 : 1}
        sx={{
          bgcolor: dk ? '#1a1a2e' : '#fff',
          border: dk ? '1px solid rgba(255,255,255,0.06)' : 'none',
          borderRadius: 2,
          mb: 3,
          p: 2,
        }}
      >
        <Typography variant="subtitle1" sx={{ fontWeight: 700, mb: 2 }}>
          Revenue & Profit Trend
        </Typography>
        {loading ? (
          <Skeleton variant="rectangular" height={280} sx={{ borderRadius: 1 }} />
        ) : (
          <ResponsiveContainer width="100%" height={280}>
            <AreaChart data={data?.revenueTrend ?? []}>
              <defs>
                <linearGradient id="colorRevenue" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="#4caf50" stopOpacity={0.3} />
                  <stop offset="95%" stopColor="#4caf50" stopOpacity={0} />
                </linearGradient>
                <linearGradient id="colorProfit" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="#fdd835" stopOpacity={0.3} />
                  <stop offset="95%" stopColor="#fdd835" stopOpacity={0} />
                </linearGradient>
              </defs>
              <CartesianGrid strokeDasharray="3 3" stroke={dk ? 'rgba(255,255,255,0.08)' : '#eee'} />
              <XAxis
                dataKey="date"
                tick={{ fontSize: 11, fill: dk ? 'rgba(255,255,255,0.5)' : '#666' }}
                tickFormatter={(v) => new Date(v).toLocaleDateString('en-IN', { day: '2-digit', month: 'short' })}
              />
              <YAxis
                tick={{ fontSize: 11, fill: dk ? 'rgba(255,255,255,0.5)' : '#666' }}
                tickFormatter={fmtCompact}
              />
              <Tooltip
                contentStyle={{
                  backgroundColor: dk ? '#1a1a2e' : '#fff',
                  border: dk ? '1px solid rgba(255,255,255,0.1)' : '1px solid #ddd',
                  borderRadius: 8,
                }}
                formatter={(v: number, name: string) => [fmtCurrency(v), name === 'grossRevenue' ? 'Gross Revenue' : 'Net Profit']}
                labelFormatter={(v) => new Date(v).toLocaleDateString('en-IN', { weekday: 'short', day: '2-digit', month: 'short' })}
              />
              <Legend />
              <Area
                type="monotone"
                dataKey="grossRevenue"
                name="Gross Revenue"
                stroke="#4caf50"
                fill="url(#colorRevenue)"
                strokeWidth={2}
              />
              <Area
                type="monotone"
                dataKey="profit"
                name="Net Profit"
                stroke="#fdd835"
                fill="url(#colorProfit)"
                strokeWidth={2}
              />
            </AreaChart>
          </ResponsiveContainer>
        )}
      </Card>

      {/* ─── Report Tabs ────────────────────────────────── */}
      <Card
        elevation={dk ? 0 : 1}
        sx={{
          bgcolor: dk ? '#1a1a2e' : '#fff',
          border: dk ? '1px solid rgba(255,255,255,0.06)' : 'none',
          borderRadius: 2,
        }}
      >
        <Tabs
          value={activeTab}
          onChange={(_, v) => setActiveTab(v)}
          variant="scrollable"
          scrollButtons="auto"
          sx={{
            borderBottom: `1px solid ${dk ? 'rgba(255,255,255,0.08)' : '#e0e0e0'}`,
            '& .MuiTab-root': {
              textTransform: 'none',
              fontWeight: 600,
              minHeight: 56,
            },
            '& .Mui-selected': {
              color: dk ? '#fdd835' : undefined,
            },
            '& .MuiTabs-indicator': {
              bgcolor: '#fdd835',
            },
          }}
        >
          <Tab icon={<ChannelIcon sx={{ fontSize: 18 }} />} iconPosition="start" label="Channel Profit" />
          <Tab icon={<ReportIcon sx={{ fontSize: 18 }} />} iconPosition="start" label="Product Profit" />
          <Tab icon={<ChannelIcon sx={{ fontSize: 18 }} />} iconPosition="start" label="Commission Report" />
          <Tab icon={<InventoryIcon sx={{ fontSize: 18 }} />} iconPosition="start" label="Inventory Impact" />
          <Tab icon={<PaymentIcon sx={{ fontSize: 18 }} />} iconPosition="start" label="Payment Analysis" />
        </Tabs>

        <Box sx={{ p: 2 }}>
          {loading ? (
            <Box sx={{ p: 4 }}>
              <Skeleton variant="rectangular" height={300} sx={{ borderRadius: 1 }} />
            </Box>
          ) : (
            <>
              {activeTab === 0 && data && (
                <ChannelProfitChart data={data.channelProfit} trend={data.channelTrend} />
              )}
              {activeTab === 1 && data && (
                <ProductProfitTable data={data.productProfit} />
              )}
              {activeTab === 2 && data && (
                <CommissionReport data={data.platformCommission} />
              )}
              {activeTab === 3 && data && (
                <InventoryImpactReport data={data.inventoryImpact} />
              )}
              {activeTab === 4 && data && (
                <PaymentAnalysis data={data.paymentAnalysis} />
              )}
            </>
          )}
        </Box>
      </Card>
    </Box>
  );
};

export default ProfitDashboard;
