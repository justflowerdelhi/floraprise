/**
 * ChannelProfitChart.tsx — Channel-wise Profit Analysis
 *
 * Includes:
 * - Bar chart: Revenue by channel
 * - Pie chart: Revenue distribution
 * - Table: Detailed channel metrics
 */
import React, { useState } from 'react';
import {
  Box, Typography, Grid, Card, CardContent, Table, TableHead, TableRow,
  TableCell, TableBody, ToggleButton, ToggleButtonGroup, Chip, useTheme, alpha,
} from '@mui/material';
import {
  BarChart, Bar, PieChart, Pie, Cell, XAxis, YAxis, CartesianGrid,
  Tooltip, ResponsiveContainer, Legend,
} from 'recharts';
import type { ChannelProfit, ChannelTrendPoint } from './ProfitTypes';
import { CHANNEL_CONFIG } from './ProfitTypes';

interface Props {
  data: ChannelProfit[];
  trend: ChannelTrendPoint[];
}

// ─── Formatters (tenant-aware) ───────────────────────────────

import { formatCurrency, formatPercent } from '../../core/i18n';

const fmtCurrency = (v: number) => formatCurrency(v);
const fmtPercent = (v: number) => formatPercent(v);

// ─── Custom Tooltip ─────────────────────────────────────────

const CustomTooltip: React.FC<{ active?: boolean; payload?: any[] }> = ({ active, payload }) => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';

  if (!active || !payload?.length) return null;

  const data = payload[0].payload as ChannelProfit;
  const config = CHANNEL_CONFIG[data.channel];

  return (
    <Card
      elevation={4}
      sx={{
        bgcolor: dk ? '#1a1a2e' : '#fff',
        border: dk ? '1px solid rgba(255,255,255,0.15)' : 'none',
        p: 1.5,
        maxWidth: 220,
      }}
    >
      <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 1 }}>
        <Box sx={{ width: 12, height: 12, borderRadius: 1, bgcolor: config.color }} />
        <Typography variant="subtitle2" sx={{ fontWeight: 700 }}>{config.label}</Typography>
      </Box>
      <Box sx={{ display: 'flex', flexDirection: 'column', gap: 0.5 }}>
        <Typography variant="caption">Gross: {fmtCurrency(data.grossRevenue)}</Typography>
        <Typography variant="caption">Commission: {fmtCurrency(data.commission)}</Typography>
        <Typography variant="caption">Net: {fmtCurrency(data.netRevenue)}</Typography>
        <Typography variant="caption">COGS: {fmtCurrency(data.cogs)}</Typography>
        <Typography variant="caption" sx={{ fontWeight: 600, color: config.color }}>
          Profit: {fmtCurrency(data.estimatedProfit)} ({fmtPercent(data.profitPercent)})
        </Typography>
        <Typography variant="caption">{data.orderCount} orders</Typography>
      </Box>
    </Card>
  );
};

// ─── Component ──────────────────────────────────────────────

const ChannelProfitChart: React.FC<Props> = ({ data, trend }) => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';

  const [viewMode, setViewMode] = useState<'revenue' | 'profit'>('revenue');

  // Calculate totals for pie chart percentages
  const totalRevenue = data.reduce((s, c) => s + c.grossRevenue, 0);
  const totalProfit = data.reduce((s, c) => s + c.estimatedProfit, 0);

  // Pie data
  const pieData = data.map((c) => ({
    ...c,
    name: CHANNEL_CONFIG[c.channel].label,
    value: viewMode === 'revenue' ? c.grossRevenue : c.estimatedProfit,
    color: CHANNEL_CONFIG[c.channel].color,
  }));

  // Bar data
  const barData = data.map((c) => ({
    ...c,
    name: CHANNEL_CONFIG[c.channel].label,
    color: CHANNEL_CONFIG[c.channel].color,
    value: viewMode === 'revenue' ? c.grossRevenue : c.estimatedProfit,
  }));

  return (
    <Box>
      {/* ─── Controls ────────────────────────────────────── */}
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
        <Typography variant="subtitle1" sx={{ fontWeight: 700 }}>
          Channel Performance Breakdown
        </Typography>
        <ToggleButtonGroup
          size="small"
          exclusive
          value={viewMode}
          onChange={(_, v) => { if (v) setViewMode(v); }}
          sx={{
            '& .MuiToggleButton-root': {
              textTransform: 'none',
              fontWeight: 600,
              px: 2,
            },
            '& .Mui-selected': {
              bgcolor: dk ? 'rgba(253,216,53,0.15)' : undefined,
              color: dk ? '#fdd835' : undefined,
            },
          }}
        >
          <ToggleButton value="revenue">Revenue</ToggleButton>
          <ToggleButton value="profit">Profit</ToggleButton>
        </ToggleButtonGroup>
      </Box>

      {/* ─── Charts Grid ────────────────────────────────── */}
      <Grid container spacing={2} sx={{ mb: 3 }}>
        {/* Bar Chart */}
        <Grid size={{ xs: 12, lg: 7 }}>
          <Card
            elevation={0}
            sx={{
              bgcolor: dk ? 'rgba(255,255,255,0.03)' : '#fafafa',
              borderRadius: 2,
              p: 2,
            }}
          >
            <Typography variant="caption" sx={{ fontWeight: 600, textTransform: 'uppercase', mb: 2, display: 'block' }}>
              {viewMode === 'revenue' ? 'Revenue by Channel' : 'Profit by Channel'}
            </Typography>
            <ResponsiveContainer width="100%" height={260}>
              <BarChart data={barData} layout="vertical" margin={{ left: 100 }}>
                <CartesianGrid horizontal strokeDasharray="3 3" stroke={dk ? 'rgba(255,255,255,0.08)' : '#eee'} />
                <XAxis
                  type="number"
                  tick={{ fontSize: 11, fill: dk ? 'rgba(255,255,255,0.5)' : '#666' }}
                  tickFormatter={(v) => `₹${(v / 1000).toFixed(0)}K`}
                />
                <YAxis
                  type="category"
                  dataKey="name"
                  tick={{ fontSize: 12, fill: dk ? 'rgba(255,255,255,0.8)' : '#333', fontWeight: 500 }}
                  width={95}
                />
                <Tooltip content={<CustomTooltip />} />
                <Bar dataKey="value" radius={[0, 4, 4, 0]}>
                  {barData.map((entry, i) => (
                    <Cell key={i} fill={entry.color} />
                  ))}
                </Bar>
              </BarChart>
            </ResponsiveContainer>
          </Card>
        </Grid>

        {/* Pie Chart */}
        <Grid size={{ xs: 12, lg: 5 }}>
          <Card
            elevation={0}
            sx={{
              bgcolor: dk ? 'rgba(255,255,255,0.03)' : '#fafafa',
              borderRadius: 2,
              p: 2,
            }}
          >
            <Typography variant="caption" sx={{ fontWeight: 600, textTransform: 'uppercase', mb: 2, display: 'block' }}>
              {viewMode === 'revenue' ? 'Revenue Distribution' : 'Profit Distribution'}
            </Typography>
            <ResponsiveContainer width="100%" height={260}>
              <PieChart>
                <Pie
                  data={pieData}
                  dataKey="value"
                  nameKey="name"
                  cx="50%"
                  cy="50%"
                  innerRadius={50}
                  outerRadius={90}
                  paddingAngle={2}
                  label={({ name, value }) =>
                    `${(name ?? 'N/A').split(' ')[0]}: ${((value / (viewMode === 'revenue' ? totalRevenue : totalProfit)) * 100).toFixed(0)}%`
                  }
                  labelLine={{ stroke: dk ? 'rgba(255,255,255,0.3)' : '#999', strokeWidth: 1 }}
                >
                  {pieData.map((entry, i) => (
                    <Cell key={i} fill={entry.color} />
                  ))}
                </Pie>
                <Tooltip formatter={(v: number | undefined) => fmtCurrency(v ?? 0)} />
              </PieChart>
            </ResponsiveContainer>
          </Card>
        </Grid>
      </Grid>

      {/* ─── Detailed Table ─────────────────────────────── */}
      <Card
        elevation={0}
        sx={{
          bgcolor: dk ? 'rgba(255,255,255,0.03)' : '#fafafa',
          borderRadius: 2,
          overflow: 'hidden',
        }}
      >
        <Table size="small">
          <TableHead>
            <TableRow>
              <TableCell sx={{ fontWeight: 700, bgcolor: dk ? 'rgba(255,255,255,0.05)' : '#f5f5f5' }}>Channel</TableCell>
              <TableCell align="right" sx={{ fontWeight: 700, bgcolor: dk ? 'rgba(255,255,255,0.05)' : '#f5f5f5' }}>Gross Revenue</TableCell>
              <TableCell align="right" sx={{ fontWeight: 700, bgcolor: dk ? 'rgba(255,255,255,0.05)' : '#f5f5f5' }}>Commission</TableCell>
              <TableCell align="right" sx={{ fontWeight: 700, bgcolor: dk ? 'rgba(255,255,255,0.05)' : '#f5f5f5' }}>Net Revenue</TableCell>
              <TableCell align="right" sx={{ fontWeight: 700, bgcolor: dk ? 'rgba(255,255,255,0.05)' : '#f5f5f5' }}>COGS</TableCell>
              <TableCell align="right" sx={{ fontWeight: 700, bgcolor: dk ? 'rgba(255,255,255,0.05)' : '#f5f5f5' }}>Profit</TableCell>
              <TableCell align="center" sx={{ fontWeight: 700, bgcolor: dk ? 'rgba(255,255,255,0.05)' : '#f5f5f5' }}>Margin</TableCell>
              <TableCell align="center" sx={{ fontWeight: 700, bgcolor: dk ? 'rgba(255,255,255,0.05)' : '#f5f5f5' }}>Orders</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {data.map((channel) => {
              const config = CHANNEL_CONFIG[channel.channel];
              return (
                <TableRow key={channel.channel} hover>
                  <TableCell>
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                      <Box sx={{ width: 10, height: 10, borderRadius: 1, bgcolor: config.color }} />
                      <Typography variant="body2" sx={{ fontWeight: 600 }}>{config.label}</Typography>
                    </Box>
                  </TableCell>
                  <TableCell align="right">{fmtCurrency(channel.grossRevenue)}</TableCell>
                  <TableCell align="right" sx={{ color: channel.commission > 0 ? '#f44336' : 'inherit' }}>
                    {channel.commission > 0 ? `-${fmtCurrency(channel.commission)}` : '—'}
                  </TableCell>
                  <TableCell align="right">{fmtCurrency(channel.netRevenue)}</TableCell>
                  <TableCell align="right" sx={{ color: dk ? 'rgba(255,255,255,0.6)' : 'text.secondary' }}>
                    {fmtCurrency(channel.cogs)}
                  </TableCell>
                  <TableCell align="right" sx={{ fontWeight: 600, color: '#4caf50' }}>
                    {fmtCurrency(channel.estimatedProfit)}
                  </TableCell>
                  <TableCell align="center">
                    <Chip
                      size="small"
                      label={fmtPercent(channel.profitPercent)}
                      sx={{
                        fontWeight: 700,
                        fontSize: '0.7rem',
                        height: 22,
                        bgcolor: alpha(
                          channel.profitPercent >= 50 ? '#4caf50' : channel.profitPercent >= 30 ? '#ff9800' : '#f44336',
                          dk ? 0.2 : 0.12
                        ),
                        color: channel.profitPercent >= 50 ? '#4caf50' : channel.profitPercent >= 30 ? '#ff9800' : '#f44336',
                      }}
                    />
                  </TableCell>
                  <TableCell align="center">
                    <Typography variant="body2" sx={{ fontWeight: 600 }}>{channel.orderCount}</Typography>
                  </TableCell>
                </TableRow>
              );
            })}
            {/* Totals row */}
            <TableRow sx={{ bgcolor: dk ? 'rgba(253,216,53,0.08)' : 'rgba(0,0,0,0.03)' }}>
              <TableCell sx={{ fontWeight: 700 }}>TOTAL</TableCell>
              <TableCell align="right" sx={{ fontWeight: 700 }}>{fmtCurrency(totalRevenue)}</TableCell>
              <TableCell align="right" sx={{ fontWeight: 700, color: '#f44336' }}>
                -{fmtCurrency(data.reduce((s, c) => s + c.commission, 0))}
              </TableCell>
              <TableCell align="right" sx={{ fontWeight: 700 }}>
                {fmtCurrency(data.reduce((s, c) => s + c.netRevenue, 0))}
              </TableCell>
              <TableCell align="right" sx={{ fontWeight: 700 }}>
                {fmtCurrency(data.reduce((s, c) => s + c.cogs, 0))}
              </TableCell>
              <TableCell align="right" sx={{ fontWeight: 700, color: '#4caf50' }}>
                {fmtCurrency(totalProfit)}
              </TableCell>
              <TableCell align="center">
                <Chip
                  size="small"
                  label={fmtPercent((totalProfit / totalRevenue) * 100)}
                  sx={{
                    fontWeight: 700,
                    fontSize: '0.7rem',
                    height: 22,
                    bgcolor: alpha('#fdd835', dk ? 0.2 : 0.15),
                    color: '#fdd835',
                  }}
                />
              </TableCell>
              <TableCell align="center" sx={{ fontWeight: 700 }}>
                {data.reduce((s, c) => s + c.orderCount, 0)}
              </TableCell>
            </TableRow>
          </TableBody>
        </Table>
      </Card>
    </Box>
  );
};

export default ChannelProfitChart;
