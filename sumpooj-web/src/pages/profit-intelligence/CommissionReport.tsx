/**
 * CommissionReport.tsx — Platform Commission Analysis
 *
 * Analysis of external platform fees:
 * - BloomNation (10% commission)
 * - FTD (27% commission)
 * - Summary cards & comparison
 */
import React from 'react';
import {
  Box, Typography, Grid, Card, CardContent, Chip, Divider,
  LinearProgress, useTheme, alpha,
} from '@mui/material';
import {
  PieChart, Pie, Cell, BarChart, Bar, XAxis, YAxis,
  CartesianGrid, Tooltip, ResponsiveContainer, Legend,
} from 'recharts';
import type { PlatformCommission } from './ProfitTypes';

interface Props {
  data: PlatformCommission[];
}

// ─── Formatters ─────────────────────────────────────────────

const fmtCurrency = (v: number) =>
  new Intl.NumberFormat('en-IN', { style: 'currency', currency: 'INR', maximumFractionDigits: 0 }).format(v);

const fmtPercent = (v: number) => `${v.toFixed(1)}%`;

// ─── Platform Card Component ────────────────────────────────

interface PlatformCardProps {
  platform: PlatformCommission;
  dk: boolean;
}

const PlatformCard: React.FC<PlatformCardProps> = ({ platform, dk }) => {
  const platformColors: Record<string, string> = {
    BLOOMNATION: '#4caf50',
    FTD: '#2196f3',
  };

  const color = platformColors[platform.platform] ?? '#ff9800';

  return (
    <Card
      elevation={dk ? 0 : 1}
      sx={{
        bgcolor: dk ? 'rgba(255,255,255,0.03)' : '#fff',
        border: dk ? '1px solid rgba(255,255,255,0.08)' : 'none',
        borderRadius: 2,
        overflow: 'hidden',
      }}
    >
      {/* Header stripe */}
      <Box sx={{ height: 4, bgcolor: color }} />

      <CardContent sx={{ p: 2.5 }}>
        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', mb: 2 }}>
          <Box>
            <Typography variant="h6" sx={{ fontWeight: 800, mb: 0.5 }}>
              {platform.platform === 'BLOOMNATION' ? 'BloomNation' : platform.platform}
            </Typography>
            <Chip
              size="small"
              label={`${platform.commissionRate * 100}% Commission`}
              sx={{
                fontWeight: 700,
                fontSize: '0.7rem',
                height: 22,
                bgcolor: alpha(color, dk ? 0.2 : 0.1),
                color,
              }}
            />
          </Box>
          <Typography
            variant="caption"
            sx={{
              fontWeight: 600,
              px: 1,
              py: 0.5,
              borderRadius: 1,
              bgcolor: dk ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.05)',
            }}
          >
            {platform.orderCount} orders
          </Typography>
        </Box>

        <Grid container spacing={2}>
          {/* Gross Revenue */}
          <Grid size={{ xs: 6 }}>
            <Typography variant="caption" sx={{ color: dk ? 'rgba(255,255,255,0.5)' : 'text.secondary', fontWeight: 500 }}>
              Gross Revenue
            </Typography>
            <Typography variant="h6" sx={{ fontWeight: 700 }}>
              {fmtCurrency(platform.grossRevenue)}
            </Typography>
          </Grid>

          {/* Commission Amount */}
          <Grid size={{ xs: 6 }}>
            <Typography variant="caption" sx={{ color: dk ? 'rgba(255,255,255,0.5)' : 'text.secondary', fontWeight: 500 }}>
              Commission Paid
            </Typography>
            <Typography variant="h6" sx={{ fontWeight: 700, color: '#f44336' }}>
              -{fmtCurrency(platform.commissionAmount)}
            </Typography>
          </Grid>

          {/* Platform Fees */}
          <Grid size={{ xs: 6 }}>
            <Typography variant="caption" sx={{ color: dk ? 'rgba(255,255,255,0.5)' : 'text.secondary', fontWeight: 500 }}>
              Platform Fees
            </Typography>
            <Typography variant="h6" sx={{ fontWeight: 700, color: '#ff9800' }}>
              -{fmtCurrency(platform.platformFees)}
            </Typography>
          </Grid>

          {/* Net Payout */}
          <Grid size={{ xs: 6 }}>
            <Typography variant="caption" sx={{ color: dk ? 'rgba(255,255,255,0.5)' : 'text.secondary', fontWeight: 500 }}>
              Net Payout
            </Typography>
            <Typography variant="h6" sx={{ fontWeight: 700, color: '#2196f3' }}>
              {fmtCurrency(platform.netPayout)}
            </Typography>
          </Grid>
        </Grid>

        <Divider sx={{ my: 2, borderColor: dk ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.08)' }} />

        {/* COGS & Profit */}
        <Grid container spacing={2}>
          <Grid size={{ xs: 6 }}>
            <Typography variant="caption" sx={{ color: dk ? 'rgba(255,255,255,0.5)' : 'text.secondary', fontWeight: 500 }}>
              COGS
            </Typography>
            <Typography variant="subtitle1" sx={{ fontWeight: 700 }}>
              {fmtCurrency(platform.cogs)}
            </Typography>
          </Grid>

          <Grid size={{ xs: 6 }}>
            <Typography variant="caption" sx={{ color: dk ? 'rgba(255,255,255,0.5)' : 'text.secondary', fontWeight: 500 }}>
              Net Profit
            </Typography>
            <Typography variant="subtitle1" sx={{ fontWeight: 700, color: '#4caf50' }}>
              {fmtCurrency(platform.profit)}
            </Typography>
          </Grid>
        </Grid>

        {/* Profit Margin Bar */}
        <Box sx={{ mt: 2 }}>
          <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 0.5 }}>
            <Typography variant="caption" sx={{ fontWeight: 600 }}>
              Profit Margin
            </Typography>
            <Typography variant="caption" sx={{ fontWeight: 700, color }}>
              {fmtPercent(platform.profitPercent)}
            </Typography>
          </Box>
          <LinearProgress
            variant="determinate"
            value={Math.min(platform.profitPercent, 100)}
            sx={{
              height: 8,
              borderRadius: 4,
              bgcolor: dk ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.08)',
              '& .MuiLinearProgress-bar': {
                bgcolor: color,
                borderRadius: 4,
              },
            }}
          />
        </Box>
      </CardContent>
    </Card>
  );
};

// ─── Main Component ─────────────────────────────────────────

const CommissionReport: React.FC<Props> = ({ data }) => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';

  // Calculate totals
  const totals = {
    grossRevenue: data.reduce((s, p) => s + p.grossRevenue, 0),
    commission: data.reduce((s, p) => s + p.commissionAmount, 0),
    platformFees: data.reduce((s, p) => s + p.platformFees, 0),
    netPayout: data.reduce((s, p) => s + p.netPayout, 0),
    cogs: data.reduce((s, p) => s + p.cogs, 0),
    profit: data.reduce((s, p) => s + p.profit, 0),
    orders: data.reduce((s, p) => s + p.orderCount, 0),
  };

  const effectiveCommissionRate = (totals.commission / totals.grossRevenue) * 100;

  // Chart data
  const breakdownData = [
    { name: 'Commission', value: totals.commission, color: '#f44336' },
    { name: 'Platform Fees', value: totals.platformFees, color: '#ff9800' },
    { name: 'COGS', value: totals.cogs, color: '#2196f3' },
    { name: 'Net Profit', value: totals.profit, color: '#4caf50' },
  ];

  const comparisonData = data.map((p) => ({
    platform: p.platform === 'BLOOMNATION' ? 'BloomNation' : p.platform,
    grossRevenue: p.grossRevenue,
    commission: p.commissionAmount,
    profit: p.profit,
    color: p.platform === 'BLOOMNATION' ? '#4caf50' : '#2196f3',
  }));

  return (
    <Box>
      {/* Header */}
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3, flexWrap: 'wrap', gap: 2 }}>
        <Box>
          <Typography variant="subtitle1" sx={{ fontWeight: 700 }}>
            Platform Commission Analysis
          </Typography>
          <Typography variant="caption" sx={{ color: dk ? 'rgba(255,255,255,0.5)' : 'text.secondary' }}>
            External marketplace fees and profitability
          </Typography>
        </Box>

        <Box sx={{ display: 'flex', gap: 2 }}>
          <Box sx={{ textAlign: 'right' }}>
            <Typography variant="caption" sx={{ color: dk ? 'rgba(255,255,255,0.5)' : 'text.secondary' }}>
              Total Commission Paid
            </Typography>
            <Typography variant="h6" sx={{ fontWeight: 700, color: '#f44336' }}>
              {fmtCurrency(totals.commission)}
            </Typography>
          </Box>
          <Box sx={{ textAlign: 'right' }}>
            <Typography variant="caption" sx={{ color: dk ? 'rgba(255,255,255,0.5)' : 'text.secondary' }}>
              Effective Rate
            </Typography>
            <Typography variant="h6" sx={{ fontWeight: 700, color: '#ff9800' }}>
              {fmtPercent(effectiveCommissionRate)}
            </Typography>
          </Box>
        </Box>
      </Box>

      {/* Platform Cards */}
      <Grid container spacing={2} sx={{ mb: 3 }}>
        {data.map((platform) => (
          <Grid key={platform.platform} size={{ xs: 12, md: 6 }}>
            <PlatformCard platform={platform} dk={dk} />
          </Grid>
        ))}
      </Grid>

      {/* Charts */}
      <Grid container spacing={2}>
        {/* Revenue Breakdown Pie */}
        <Grid size={{ xs: 12, md: 6 }}>
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
              Revenue Allocation
            </Typography>
            <ResponsiveContainer width="100%" height={280}>
              <PieChart>
                <Pie
                  data={breakdownData}
                  dataKey="value"
                  nameKey="name"
                  cx="50%"
                  cy="50%"
                  innerRadius={60}
                  outerRadius={100}
                  paddingAngle={3}
                  label={({ name, value }) => `${name}: ${fmtPercent((value / totals.grossRevenue) * 100)}`}
                  labelLine={{ stroke: dk ? 'rgba(255,255,255,0.3)' : '#999', strokeWidth: 1 }}
                >
                  {breakdownData.map((entry, i) => (
                    <Cell key={i} fill={entry.color} />
                  ))}
                </Pie>
                <Tooltip formatter={(v: number) => fmtCurrency(v)} />
              </PieChart>
            </ResponsiveContainer>
          </Card>
        </Grid>

        {/* Platform Comparison Bar */}
        <Grid size={{ xs: 12, md: 6 }}>
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
              Platform Comparison
            </Typography>
            <ResponsiveContainer width="100%" height={280}>
              <BarChart data={comparisonData}>
                <CartesianGrid strokeDasharray="3 3" stroke={dk ? 'rgba(255,255,255,0.08)' : '#eee'} />
                <XAxis
                  dataKey="platform"
                  tick={{ fontSize: 12, fill: dk ? 'rgba(255,255,255,0.7)' : '#333', fontWeight: 500 }}
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
                <Legend />
                <Bar dataKey="grossRevenue" name="Gross Revenue" fill="#2196f3" radius={[4, 4, 0, 0]} />
                <Bar dataKey="commission" name="Commission" fill="#f44336" radius={[4, 4, 0, 0]} />
                <Bar dataKey="profit" name="Profit" fill="#4caf50" radius={[4, 4, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </Card>
        </Grid>
      </Grid>

      {/* Summary Box */}
      <Card
        elevation={0}
        sx={{
          mt: 2,
          bgcolor: dk ? 'rgba(253,216,53,0.08)' : 'rgba(253,216,53,0.1)',
          borderRadius: 2,
          p: 2,
        }}
      >
        <Grid container spacing={2} alignItems="center">
          <Grid size={{ xs: 12, sm: 3 }}>
            <Typography variant="caption" sx={{ fontWeight: 600, textTransform: 'uppercase' }}>
              Total Ext. Revenue
            </Typography>
            <Typography variant="h6" sx={{ fontWeight: 700 }}>
              {fmtCurrency(totals.grossRevenue)}
            </Typography>
          </Grid>
          <Grid size={{ xs: 12, sm: 3 }}>
            <Typography variant="caption" sx={{ fontWeight: 600, textTransform: 'uppercase' }}>
              Total Deductions
            </Typography>
            <Typography variant="h6" sx={{ fontWeight: 700, color: '#f44336' }}>
              -{fmtCurrency(totals.commission + totals.platformFees)}
            </Typography>
          </Grid>
          <Grid size={{ xs: 12, sm: 3 }}>
            <Typography variant="caption" sx={{ fontWeight: 600, textTransform: 'uppercase' }}>
              Net Payout
            </Typography>
            <Typography variant="h6" sx={{ fontWeight: 700, color: '#2196f3' }}>
              {fmtCurrency(totals.netPayout)}
            </Typography>
          </Grid>
          <Grid size={{ xs: 12, sm: 3 }}>
            <Typography variant="caption" sx={{ fontWeight: 600, textTransform: 'uppercase' }}>
              External Profit
            </Typography>
            <Typography variant="h6" sx={{ fontWeight: 700, color: '#4caf50' }}>
              {fmtCurrency(totals.profit)} ({fmtPercent((totals.profit / totals.grossRevenue) * 100)})
            </Typography>
          </Grid>
        </Grid>
      </Card>
    </Box>
  );
};

export default CommissionReport;
