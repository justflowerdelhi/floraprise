/**
 * ExpiryTrendChart — Stacked bar chart showing expiring & expired items per week
 */
import React from 'react';
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
} from 'recharts';
import { Card, CardContent, Typography, useTheme } from '@mui/material';
import type { ExpiryTrendPoint } from '../data/health.data';
import { CHART_COLORS } from '../data/health.data';
import { fmtCurrency } from '../utils/health.utils';

interface Props {
  data: ExpiryTrendPoint[];
}

interface TooltipPayloadItem {
  payload: ExpiryTrendPoint;
}

const CustomTooltip = ({ active, payload }: { active?: boolean; payload?: TooltipPayloadItem[] }) => {
  if (!active || !payload?.length) return null;
  const d = payload[0].payload;
  return (
    <div style={{
      background: 'rgba(30,30,30,0.95)',
      border: '1px solid rgba(255,255,255,0.1)',
      borderRadius: 8,
      padding: '8px 12px',
      color: '#fff',
      fontSize: 13,
    }}>
      <strong>{d.week}</strong>
      <div style={{ color: CHART_COLORS.orange }}>Expiring: {d.expiringItems} items</div>
      <div style={{ color: CHART_COLORS.red }}>Expired: {d.expiredItems} items</div>
      <div>Value at risk: {fmtCurrency(d.valueAtRisk)}</div>
    </div>
  );
};

const ExpiryTrendChart: React.FC<Props> = ({ data }) => {
  const theme = useTheme();
  const darkMode = theme.palette.mode === 'dark';

  return (
    <Card
      elevation={darkMode ? 0 : 1}
      sx={{
        bgcolor: darkMode ? '#1a1a2e' : '#fff',
        border: darkMode ? '1px solid rgba(255,255,255,0.08)' : 'none',
        height: '100%',
      }}
    >
      <CardContent>
        <Typography variant="subtitle1" sx={{ fontWeight: 700, mb: 2 }}>
          Expiry Trend (8-Week Outlook)
        </Typography>
        <ResponsiveContainer width="100%" height={300}>
          <BarChart data={data} margin={{ top: 5, right: 20, bottom: 5, left: 10 }}>
            <CartesianGrid
              strokeDasharray="3 3"
              stroke={darkMode ? 'rgba(255,255,255,0.06)' : '#eee'}
            />
            <XAxis
              dataKey="week"
              tick={{ fontSize: 11, fill: darkMode ? '#888' : '#666' }}
              tickLine={false}
              axisLine={{ stroke: darkMode ? 'rgba(255,255,255,0.1)' : '#ddd' }}
            />
            <YAxis
              tick={{ fontSize: 11, fill: darkMode ? '#888' : '#666' }}
              tickLine={false}
              axisLine={false}
            />
            <Tooltip content={<CustomTooltip />} />
            <Legend
              verticalAlign="bottom"
              iconType="square"
              wrapperStyle={{ fontSize: 12, color: darkMode ? '#aaa' : '#666' }}
            />
            <Bar
              dataKey="expiringItems"
              name="Expiring Soon"
              stackId="expiry"
              fill={CHART_COLORS.orange}
              radius={[0, 0, 0, 0]}
            />
            <Bar
              dataKey="expiredItems"
              name="Already Expired"
              stackId="expiry"
              fill={CHART_COLORS.red}
              radius={[4, 4, 0, 0]}
            />
          </BarChart>
        </ResponsiveContainer>
      </CardContent>
    </Card>
  );
};

export default ExpiryTrendChart;
