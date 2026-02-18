/**
 * InventoryImpactReport.tsx — Inventory Impact on Profitability
 *
 * Includes:
 * - Wastage by category (pie chart)
 * - Monthly wastage trend (line chart)
 * - Shrinkage metrics & adjusted profit
 */
import React from 'react';
import {
  Box, Typography, Grid, Card, CardContent, Chip, Divider,
  LinearProgress, useTheme, alpha,
} from '@mui/material';
import {
  Warning as WastageIcon,
  TrendingDown as ShrinkIcon,
  Inventory as InventoryIcon,
  ShowChart as TrendIcon,
} from '@mui/icons-material';
import {
  PieChart, Pie, Cell, LineChart, Line, XAxis, YAxis,
  CartesianGrid, Tooltip, ResponsiveContainer, Legend, Area, AreaChart,
} from 'recharts';
import type { InventoryImpact } from './ProfitTypes';

interface Props {
  data: InventoryImpact;
}

// ─── Formatters (tenant-aware) ───────────────────────────────

import { formatCurrency, formatPercent } from '../../core/i18n';

const fmtCurrency = (v: number) => formatCurrency(v);
const fmtPercent = (v: number) => formatPercent(v);

// ─── Category Colors ────────────────────────────────────────

const CATEGORY_COLORS: Record<string, string> = {
  Flowers: '#e91e63',
  Greenery: '#4caf50',
  Arrangements: '#ff9800',
  Supplies: '#2196f3',
  Plants: '#9c27b0',
};

// ─── Metric Card Component ──────────────────────────────────

interface MetricCardProps {
  title: string;
  value: string;
  subtitle?: string;
  icon: React.ReactNode;
  color: string;
  dk: boolean;
}

const MetricCard: React.FC<MetricCardProps> = ({ title, value, subtitle, icon, color, dk }) => (
  <Card
    elevation={0}
    sx={{
      bgcolor: dk ? 'rgba(255,255,255,0.03)' : '#fafafa',
      borderRadius: 2,
      p: 2,
    }}
  >
    <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
      <Box>
        <Typography variant="caption" sx={{ fontWeight: 600, textTransform: 'uppercase', color: dk ? 'rgba(255,255,255,0.5)' : 'text.secondary' }}>
          {title}
        </Typography>
        <Typography variant="h5" sx={{ fontWeight: 800, mt: 0.5, color }}>
          {value}
        </Typography>
        {subtitle && (
          <Typography variant="caption" sx={{ color: dk ? 'rgba(255,255,255,0.4)' : 'text.disabled' }}>
            {subtitle}
          </Typography>
        )}
      </Box>
      <Box
        sx={{
          p: 1,
          borderRadius: 1.5,
          bgcolor: alpha(color, dk ? 0.15 : 0.1),
          color,
        }}
      >
        {icon}
      </Box>
    </Box>
  </Card>
);

// ─── Main Component ─────────────────────────────────────────

const InventoryImpactReport: React.FC<Props> = ({ data }) => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';

  // Calculate derived metrics
  const adjustedProfit = data.totalSalesValue - data.totalCOGS - data.totalWastageValue;
  const wastagePercent = (data.totalWastageValue / data.totalSalesValue) * 100;
  const cogsPercent = (data.totalCOGS / data.totalSalesValue) * 100;

  // Pie chart data
  const pieData = data.wastageByCategory.map((cat) => ({
    ...cat,
    color: CATEGORY_COLORS[cat.category] ?? '#666',
  }));

  // Trend chart data with gradient
  const trendData = data.monthlyWastageTrend.map((t) => ({
    ...t,
    month: new Date(t.month + '-01').toLocaleDateString('en-IN', { month: 'short', year: '2-digit' }),
  }));

  return (
    <Box>
      {/* Header */}
      <Box sx={{ mb: 3 }}>
        <Typography variant="subtitle1" sx={{ fontWeight: 700 }}>
          Inventory Impact on Profitability
        </Typography>
        <Typography variant="caption" sx={{ color: dk ? 'rgba(255,255,255,0.5)' : 'text.secondary' }}>
          Wastage, shrinkage, and inventory-adjusted profit analysis
        </Typography>
      </Box>

      {/* Summary Metrics */}
      <Grid container spacing={2} sx={{ mb: 3 }}>
        <Grid size={{ xs: 12, sm: 6, md: 3 }}>
          <MetricCard
            title="Total Sales Value"
            value={fmtCurrency(data.totalSalesValue)}
            icon={<InventoryIcon />}
            color="#4caf50"
            dk={dk}
          />
        </Grid>
        <Grid size={{ xs: 12, sm: 6, md: 3 }}>
          <MetricCard
            title="Total COGS"
            value={fmtCurrency(data.totalCOGS)}
            subtitle={fmtPercent(cogsPercent) + ' of sales'}
            icon={<TrendIcon />}
            color="#2196f3"
            dk={dk}
          />
        </Grid>
        <Grid size={{ xs: 12, sm: 6, md: 3 }}>
          <MetricCard
            title="Wastage Value"
            value={fmtCurrency(data.totalWastageValue)}
            subtitle={fmtPercent(wastagePercent) + ' of sales'}
            icon={<WastageIcon />}
            color="#f44336"
            dk={dk}
          />
        </Grid>
        <Grid size={{ xs: 12, sm: 6, md: 3 }}>
          <MetricCard
            title="Shrinkage Rate"
            value={fmtPercent(data.shrinkagePercent)}
            subtitle="Inventory loss rate"
            icon={<ShrinkIcon />}
            color="#ff9800"
            dk={dk}
          />
        </Grid>
      </Grid>

      {/* Charts */}
      <Grid container spacing={2} sx={{ mb: 3 }}>
        {/* Wastage by Category Pie */}
        <Grid size={{ xs: 12, md: 5 }}>
          <Card
            elevation={0}
            sx={{
              bgcolor: dk ? 'rgba(255,255,255,0.03)' : '#fafafa',
              borderRadius: 2,
              p: 2,
              height: '100%',
            }}
          >
            <Typography variant="caption" sx={{ fontWeight: 600, textTransform: 'uppercase', mb: 2, display: 'block' }}>
              Wastage by Category
            </Typography>
            <ResponsiveContainer width="100%" height={280}>
              <PieChart>
                <Pie
                  data={pieData}
                  dataKey="value"
                  nameKey="category"
                  cx="50%"
                  cy="50%"
                  innerRadius={50}
                  outerRadius={90}
                  paddingAngle={2}
                  label={({ category, percent }) => `${category}: ${(percent * 100).toFixed(0)}%`}
                  labelLine={{ stroke: dk ? 'rgba(255,255,255,0.3)' : '#999', strokeWidth: 1 }}
                >
                  {pieData.map((entry, i) => (
                    <Cell key={i} fill={entry.color} />
                  ))}
                </Pie>
                <Tooltip formatter={(v: number) => fmtCurrency(v)} />
              </PieChart>
            </ResponsiveContainer>

            {/* Category Legend */}
            <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 1, mt: 2, justifyContent: 'center' }}>
              {pieData.map((cat) => (
                <Chip
                  key={cat.category}
                  size="small"
                  label={`${cat.category}: ${fmtCurrency(cat.value)}`}
                  sx={{
                    fontSize: '0.7rem',
                    height: 24,
                    bgcolor: alpha(cat.color, dk ? 0.2 : 0.12),
                    color: cat.color,
                    fontWeight: 600,
                  }}
                />
              ))}
            </Box>
          </Card>
        </Grid>

        {/* Monthly Trend */}
        <Grid size={{ xs: 12, md: 7 }}>
          <Card
            elevation={0}
            sx={{
              bgcolor: dk ? 'rgba(255,255,255,0.03)' : '#fafafa',
              borderRadius: 2,
              p: 2,
              height: '100%',
            }}
          >
            <Typography variant="caption" sx={{ fontWeight: 600, textTransform: 'uppercase', mb: 2, display: 'block' }}>
              Monthly Wastage Trend
            </Typography>
            <ResponsiveContainer width="100%" height={310}>
              <AreaChart data={trendData}>
                <defs>
                  <linearGradient id="wastageGradient" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#f44336" stopOpacity={0.3} />
                    <stop offset="95%" stopColor="#f44336" stopOpacity={0} />
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" stroke={dk ? 'rgba(255,255,255,0.08)' : '#eee'} />
                <XAxis
                  dataKey="month"
                  tick={{ fontSize: 11, fill: dk ? 'rgba(255,255,255,0.6)' : '#666' }}
                />
                <YAxis
                  tick={{ fontSize: 11, fill: dk ? 'rgba(255,255,255,0.5)' : '#666' }}
                  tickFormatter={(v) => `₹${(v / 1000).toFixed(0)}K`}
                />
                <Tooltip
                  contentStyle={{
                    backgroundColor: dk ? '#1a1a2e' : '#fff',
                    border: dk ? '1px solid rgba(255,255,255,0.1)' : '1px solid #ddd',
                    borderRadius: 8,
                  }}
                  formatter={(v: number) => fmtCurrency(v)}
                />
                <Area
                  type="monotone"
                  dataKey="value"
                  name="Wastage"
                  stroke="#f44336"
                  fill="url(#wastageGradient)"
                  strokeWidth={2}
                />
              </AreaChart>
            </ResponsiveContainer>
          </Card>
        </Grid>
      </Grid>

      {/* Adjusted Profit Summary */}
      <Card
        elevation={0}
        sx={{
          bgcolor: dk ? 'rgba(253,216,53,0.08)' : 'rgba(253,216,53,0.1)',
          borderRadius: 2,
          p: 2.5,
        }}
      >
        <Typography variant="subtitle2" sx={{ fontWeight: 700, mb: 2 }}>
          Inventory-Adjusted Profit Calculation
        </Typography>

        <Grid container spacing={2} alignItems="center">
          <Grid size={{ xs: 12, sm: 2.4 }}>
            <Typography variant="caption" sx={{ fontWeight: 600 }}>Sales Value</Typography>
            <Typography variant="h6" sx={{ fontWeight: 700, color: '#4caf50' }}>
              {fmtCurrency(data.totalSalesValue)}
            </Typography>
          </Grid>
          <Grid size={{ xs: 12, sm: 0.3 }} sx={{ textAlign: 'center', display: { xs: 'none', sm: 'block' } }}>
            <Typography variant="h6">−</Typography>
          </Grid>
          <Grid size={{ xs: 12, sm: 2.4 }}>
            <Typography variant="caption" sx={{ fontWeight: 600 }}>COGS</Typography>
            <Typography variant="h6" sx={{ fontWeight: 700, color: '#2196f3' }}>
              {fmtCurrency(data.totalCOGS)}
            </Typography>
          </Grid>
          <Grid size={{ xs: 12, sm: 0.3 }} sx={{ textAlign: 'center', display: { xs: 'none', sm: 'block' } }}>
            <Typography variant="h6">−</Typography>
          </Grid>
          <Grid size={{ xs: 12, sm: 2.4 }}>
            <Typography variant="caption" sx={{ fontWeight: 600 }}>Wastage</Typography>
            <Typography variant="h6" sx={{ fontWeight: 700, color: '#f44336' }}>
              {fmtCurrency(data.totalWastageValue)}
            </Typography>
          </Grid>
          <Grid size={{ xs: 12, sm: 0.4 }} sx={{ textAlign: 'center', display: { xs: 'none', sm: 'block' } }}>
            <Typography variant="h6">=</Typography>
          </Grid>
          <Grid size={{ xs: 12, sm: 3 }}>
            <Typography variant="caption" sx={{ fontWeight: 700 }}>Adjusted Profit</Typography>
            <Typography variant="h5" sx={{ fontWeight: 800, color: '#fdd835' }}>
              {fmtCurrency(adjustedProfit)}
            </Typography>
            <Typography variant="caption" sx={{ color: dk ? 'rgba(255,255,255,0.5)' : 'text.secondary' }}>
              {fmtPercent((adjustedProfit / data.totalSalesValue) * 100)} margin
            </Typography>
          </Grid>
        </Grid>

        {/* Visual Breakdown Bar */}
        <Box sx={{ mt: 3 }}>
          <Box sx={{ display: 'flex', height: 24, borderRadius: 2, overflow: 'hidden' }}>
            <Box
              sx={{
                width: `${cogsPercent}%`,
                bgcolor: '#2196f3',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
              }}
            >
              <Typography variant="caption" sx={{ color: '#fff', fontWeight: 600, fontSize: '0.65rem' }}>
                COGS {cogsPercent.toFixed(0)}%
              </Typography>
            </Box>
            <Box
              sx={{
                width: `${wastagePercent}%`,
                bgcolor: '#f44336',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
              }}
            >
              <Typography variant="caption" sx={{ color: '#fff', fontWeight: 600, fontSize: '0.65rem' }}>
                {wastagePercent > 5 ? `Waste ${wastagePercent.toFixed(0)}%` : ''}
              </Typography>
            </Box>
            <Box
              sx={{
                flexGrow: 1,
                bgcolor: '#4caf50',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
              }}
            >
              <Typography variant="caption" sx={{ color: '#fff', fontWeight: 600, fontSize: '0.65rem' }}>
                Profit {((adjustedProfit / data.totalSalesValue) * 100).toFixed(0)}%
              </Typography>
            </Box>
          </Box>
        </Box>
      </Card>
    </Box>
  );
};

export default InventoryImpactReport;
