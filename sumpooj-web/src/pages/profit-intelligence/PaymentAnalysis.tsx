/**
 * PaymentAnalysis.tsx — Payment Method Analysis
 *
 * Includes:
 * - Payment method breakdown (pie chart)
 * - Daily payment trends (stacked area)
 * - Processing cost breakdown
 */
import React from 'react';
import {
  Box, Typography, Grid, Card, CardContent, Chip, Table, TableHead,
  TableRow, TableCell, TableBody, useTheme, alpha,
} from '@mui/material';
import {
  Payment as PaymentIcon,
  CreditCard as CardIcon,
  LocalAtm as CashIcon,
  CardGiftcard as GiftIcon,
  PointOfSale as TerminalIcon,
  QrCode as UPIIcon,
  AccountBalance as BankIcon,
} from '@mui/icons-material';
import {
  PieChart, Pie, Cell, AreaChart, Area, XAxis, YAxis,
  CartesianGrid, Tooltip, ResponsiveContainer, Legend,
} from 'recharts';
import type { PaymentAnalysisSummary, PaymentMethodAnalysis } from './ProfitTypes';
import type { PaymentMethod } from '../payments/PaymentTypes';

interface Props {
  data: PaymentAnalysisSummary;
}

// ─── Formatters (tenant-aware) ───────────────────────────────

import { formatCurrency, formatCurrencyCompact, formatPercent } from '../../core/i18n';

const fmtCurrency = (v: number) => formatCurrency(v);
const fmtPercent = (v: number) => formatPercent(v);

// ─── Payment Method Config ──────────────────────────────────

const PAYMENT_CONFIG: Record<PaymentMethod, { label: string; color: string; icon: React.ReactNode }> = {
  CASH: { label: 'Cash', color: '#4caf50', icon: <CashIcon fontSize="small" /> },
  CARD: { label: 'Card', color: '#2196f3', icon: <CardIcon fontSize="small" /> },
  GIFT_CARD: { label: 'Gift Card', color: '#9c27b0', icon: <GiftIcon fontSize="small" /> },
  EXTERNAL_TERMINAL: { label: 'External Terminal', color: '#ff9800', icon: <TerminalIcon fontSize="small" /> },
  UPI: { label: 'UPI', color: '#00897b', icon: <UPIIcon fontSize="small" /> },
  BANK_TRANSFER: { label: 'Bank Transfer', color: '#546e7a', icon: <BankIcon fontSize="small" /> },
};

// ─── Method Card Component ──────────────────────────────────

interface MethodCardProps {
  method: PaymentMethodAnalysis;
  totalVolume: number;
  dk: boolean;
}

const MethodCard: React.FC<MethodCardProps> = ({ method, totalVolume, dk }) => {
  const config = PAYMENT_CONFIG[method.method];
  const sharePercent = (method.totalAmount / totalVolume) * 100;

  return (
    <Card
      elevation={0}
      sx={{
        bgcolor: dk ? 'rgba(255,255,255,0.03)' : '#fafafa',
        borderRadius: 2,
        p: 2,
        borderLeft: `4px solid ${config.color}`,
      }}
    >
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', mb: 1.5 }}>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
          <Box sx={{ color: config.color }}>{config.icon}</Box>
          <Typography variant="subtitle2" sx={{ fontWeight: 700 }}>{config.label}</Typography>
        </Box>
        <Chip
          size="small"
          label={`${method.transactionCount} txns`}
          sx={{
            fontSize: '0.65rem',
            height: 20,
            bgcolor: dk ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.06)',
          }}
        />
      </Box>

      <Typography variant="h5" sx={{ fontWeight: 800, mb: 0.5 }}>
        {fmtCurrency(method.totalAmount)}
      </Typography>

      <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 1.5 }}>
        <Chip
          size="small"
          label={`${sharePercent.toFixed(1)}% of total`}
          sx={{
            fontSize: '0.65rem',
            height: 20,
            bgcolor: alpha(config.color, dk ? 0.15 : 0.1),
            color: config.color,
            fontWeight: 600,
          }}
        />
      </Box>

      <Box sx={{ display: 'flex', justifyContent: 'space-between', pt: 1, borderTop: `1px solid ${dk ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.08)'}` }}>
        <Box>
          <Typography variant="caption" sx={{ color: dk ? 'rgba(255,255,255,0.5)' : 'text.secondary' }}>
            Processing Rate
          </Typography>
          <Typography variant="body2" sx={{ fontWeight: 600 }}>
            {fmtPercent(method.estimatedProcessingRate * 100)}
          </Typography>
        </Box>
        <Box sx={{ textAlign: 'right' }}>
          <Typography variant="caption" sx={{ color: dk ? 'rgba(255,255,255,0.5)' : 'text.secondary' }}>
            Processing Cost
          </Typography>
          <Typography variant="body2" sx={{ fontWeight: 600, color: method.estimatedProcessingCost > 0 ? '#f44336' : '#4caf50' }}>
            {method.estimatedProcessingCost > 0 ? `-${fmtCurrency(method.estimatedProcessingCost)}` : fmtCurrency(0)}
          </Typography>
        </Box>
      </Box>
    </Card>
  );
};

// ─── Main Component ─────────────────────────────────────────

const PaymentAnalysis: React.FC<Props> = ({ data }) => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';

  // Calculate totals
  const totalVolume = data.methodBreakdown.reduce((s, m) => s + m.totalAmount, 0);
  const totalProcessingCost = data.methodBreakdown.reduce((s, m) => s + m.estimatedProcessingCost, 0);
  const totalTransactions = data.methodBreakdown.reduce((s, m) => s + m.transactionCount, 0);
  const effectiveProcessingRate = (totalProcessingCost / totalVolume) * 100;

  // Pie chart data
  const pieData = data.methodBreakdown.map((m) => ({
    name: PAYMENT_CONFIG[m.method].label,
    value: m.totalAmount,
    color: PAYMENT_CONFIG[m.method].color,
  }));

  // Area chart data (stacked)
  const trendData = data.dailyTrend.map((day) => ({
    date: new Date(day.date).toLocaleDateString('en-IN', { day: '2-digit', month: 'short' }),
    CASH: day.cash ?? 0,
    CARD: day.card ?? 0,
    GIFT_CARD: day.giftCard ?? 0,
    EXTERNAL_TERMINAL: day.externalTerminal ?? 0,
  }));

  return (
    <Box>
      {/* Header */}
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3, flexWrap: 'wrap', gap: 2 }}>
        <Box>
          <Typography variant="subtitle1" sx={{ fontWeight: 700 }}>
            Payment Method Analysis
          </Typography>
          <Typography variant="caption" sx={{ color: dk ? 'rgba(255,255,255,0.5)' : 'text.secondary' }}>
            Transaction breakdown and processing cost impact
          </Typography>
        </Box>

        <Box sx={{ display: 'flex', gap: 3 }}>
          <Box sx={{ textAlign: 'right' }}>
            <Typography variant="caption" sx={{ color: dk ? 'rgba(255,255,255,0.5)' : 'text.secondary' }}>
              Total Processing Cost
            </Typography>
            <Typography variant="h6" sx={{ fontWeight: 700, color: '#f44336' }}>
              -{fmtCurrency(totalProcessingCost)}
            </Typography>
          </Box>
          <Box sx={{ textAlign: 'right' }}>
            <Typography variant="caption" sx={{ color: dk ? 'rgba(255,255,255,0.5)' : 'text.secondary' }}>
              Effective Rate
            </Typography>
            <Typography variant="h6" sx={{ fontWeight: 700, color: '#ff9800' }}>
              {fmtPercent(effectiveProcessingRate)}
            </Typography>
          </Box>
        </Box>
      </Box>

      {/* Method Cards */}
      <Grid container spacing={2} sx={{ mb: 3 }}>
        {data.methodBreakdown.map((method: PaymentMethodAnalysis) => (
          <Grid key={method.method} size={{ xs: 12, sm: 6, lg: 3 }}>
            <MethodCard method={method} totalVolume={totalVolume} dk={dk} />
          </Grid>
        ))}
      </Grid>

      {/* Charts */}
      <Grid container spacing={2} sx={{ mb: 3 }}>
        {/* Distribution Pie */}
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
              Payment Volume Distribution
            </Typography>
            <ResponsiveContainer width="100%" height={280}>
              <PieChart>
                <Pie
                  data={pieData}
                  dataKey="value"
                  nameKey="name"
                  cx="50%"
                  cy="50%"
                  innerRadius={60}
                  outerRadius={100}
                  paddingAngle={2}
                  label={({ name, percent }) => `${name}: ${((percent ?? 0) * 100).toFixed(0)}%`}
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

        {/* Daily Trend Area */}
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
              Daily Payment Trends
            </Typography>
            <ResponsiveContainer width="100%" height={280}>
              <AreaChart data={trendData}>
                <CartesianGrid strokeDasharray="3 3" stroke={dk ? 'rgba(255,255,255,0.08)' : '#eee'} />
                <XAxis
                  dataKey="date"
                  tick={{ fontSize: 10, fill: dk ? 'rgba(255,255,255,0.5)' : '#666' }}
                />
                <YAxis
                  tick={{ fontSize: 10, fill: dk ? 'rgba(255,255,255,0.5)' : '#666' }}
                  tickFormatter={(v) => formatCurrencyCompact(v)}
                />
                <Tooltip
                  contentStyle={{
                    backgroundColor: dk ? '#1a1a2e' : '#fff',
                    border: dk ? '1px solid rgba(255,255,255,0.1)' : '1px solid #ddd',
                    borderRadius: 8,
                  }}
                  formatter={(v: number | undefined) => fmtCurrency(v ?? 0)}
                />
                <Legend />
                <Area type="monotone" dataKey="CASH" name="Cash" stackId="1" stroke="#4caf50" fill="#4caf50" fillOpacity={0.7} />
                <Area type="monotone" dataKey="CARD" name="Card" stackId="1" stroke="#2196f3" fill="#2196f3" fillOpacity={0.7} />
                <Area type="monotone" dataKey="GIFT_CARD" name="Gift Card" stackId="1" stroke="#9c27b0" fill="#9c27b0" fillOpacity={0.7} />
                <Area type="monotone" dataKey="EXTERNAL_TERMINAL" name="Ext. Terminal" stackId="1" stroke="#ff9800" fill="#ff9800" fillOpacity={0.7} />
              </AreaChart>
            </ResponsiveContainer>
          </Card>
        </Grid>
      </Grid>

      {/* Detailed Table */}
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
              <TableCell sx={{ fontWeight: 700, bgcolor: dk ? 'rgba(255,255,255,0.05)' : '#f5f5f5' }}>Method</TableCell>
              <TableCell align="right" sx={{ fontWeight: 700, bgcolor: dk ? 'rgba(255,255,255,0.05)' : '#f5f5f5' }}>Volume</TableCell>
              <TableCell align="center" sx={{ fontWeight: 700, bgcolor: dk ? 'rgba(255,255,255,0.05)' : '#f5f5f5' }}>Share</TableCell>
              <TableCell align="right" sx={{ fontWeight: 700, bgcolor: dk ? 'rgba(255,255,255,0.05)' : '#f5f5f5' }}>Transactions</TableCell>
              <TableCell align="right" sx={{ fontWeight: 700, bgcolor: dk ? 'rgba(255,255,255,0.05)' : '#f5f5f5' }}>Avg Txn</TableCell>
              <TableCell align="center" sx={{ fontWeight: 700, bgcolor: dk ? 'rgba(255,255,255,0.05)' : '#f5f5f5' }}>Rate</TableCell>
              <TableCell align="right" sx={{ fontWeight: 700, bgcolor: dk ? 'rgba(255,255,255,0.05)' : '#f5f5f5' }}>Cost</TableCell>
              <TableCell align="right" sx={{ fontWeight: 700, bgcolor: dk ? 'rgba(255,255,255,0.05)' : '#f5f5f5' }}>Net Volume</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {data.methodBreakdown.map((method: PaymentMethodAnalysis) => {
              const config = PAYMENT_CONFIG[method.method];
              const share = (method.totalAmount / totalVolume) * 100;
              const avgTxn = method.totalAmount / method.transactionCount;
              const netVolume = method.netRevenue;

              return (
                <TableRow key={method.method} hover>
                  <TableCell>
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                      <Box sx={{ color: config.color }}>{config.icon}</Box>
                      <Typography variant="body2" sx={{ fontWeight: 600 }}>{config.label}</Typography>
                    </Box>
                  </TableCell>
                  <TableCell align="right">{fmtCurrency(method.totalAmount)}</TableCell>
                  <TableCell align="center">
                    <Chip
                      size="small"
                      label={`${share.toFixed(1)}%`}
                      sx={{
                        fontSize: '0.65rem',
                        height: 20,
                        bgcolor: alpha(config.color, dk ? 0.15 : 0.1),
                        color: config.color,
                        fontWeight: 600,
                      }}
                    />
                  </TableCell>
                  <TableCell align="right">{method.transactionCount}</TableCell>
                  <TableCell align="right">{fmtCurrency(avgTxn)}</TableCell>
                  <TableCell align="center">
                    <Typography variant="body2" sx={{ color: method.estimatedProcessingRate > 0 ? '#ff9800' : '#4caf50' }}>
                      {fmtPercent(method.estimatedProcessingRate * 100)}
                    </Typography>
                  </TableCell>
                  <TableCell align="right" sx={{ color: method.estimatedProcessingCost > 0 ? '#f44336' : 'inherit' }}>
                    {method.estimatedProcessingCost > 0 ? `-${fmtCurrency(method.estimatedProcessingCost)}` : '—'}
                  </TableCell>
                  <TableCell align="right" sx={{ fontWeight: 600 }}>{fmtCurrency(netVolume)}</TableCell>
                </TableRow>
              );
            })}

            {/* Totals */}
            <TableRow sx={{ bgcolor: dk ? 'rgba(253,216,53,0.08)' : 'rgba(0,0,0,0.03)' }}>
              <TableCell sx={{ fontWeight: 700 }}>TOTAL</TableCell>
              <TableCell align="right" sx={{ fontWeight: 700 }}>{fmtCurrency(totalVolume)}</TableCell>
              <TableCell align="center">
                <Chip
                  size="small"
                  label="100%"
                  sx={{
                    fontSize: '0.65rem',
                    height: 20,
                    bgcolor: alpha('#fdd835', dk ? 0.2 : 0.15),
                    color: '#fdd835',
                    fontWeight: 600,
                  }}
                />
              </TableCell>
              <TableCell align="right" sx={{ fontWeight: 700 }}>{totalTransactions}</TableCell>
              <TableCell align="right" sx={{ fontWeight: 700 }}>{fmtCurrency(totalVolume / totalTransactions)}</TableCell>
              <TableCell align="center" sx={{ fontWeight: 700, color: '#ff9800' }}>
                {fmtPercent(effectiveProcessingRate)}
              </TableCell>
              <TableCell align="right" sx={{ fontWeight: 700, color: '#f44336' }}>
                -{fmtCurrency(totalProcessingCost)}
              </TableCell>
              <TableCell align="right" sx={{ fontWeight: 700, color: '#4caf50' }}>
                {fmtCurrency(totalVolume - totalProcessingCost)}
              </TableCell>
            </TableRow>
          </TableBody>
        </Table>
      </Card>
    </Box>
  );
};

export default PaymentAnalysis;
