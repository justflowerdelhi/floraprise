/**
 * WastageTrendChart — Area chart showing daily wastage over 30 days
 */
import React from 'react';
import {
  AreaChart,
  Area,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
} from 'recharts';
import { Card, CardContent, Typography, useTheme } from '@mui/material';
import type { WastageTrendPoint } from '../data/health.data';
import { CHART_COLORS } from '../data/health.data';
import { fmtCurrency } from '../utils/health.utils';
import { formatCurrencyCompact } from '../../../core/i18n';

interface Props {
  data: WastageTrendPoint[];
}

interface TooltipPayloadItem {
  payload: WastageTrendPoint;
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
      <strong>{d.date}</strong>
      <div>Wastage: {fmtCurrency(d.wastageValue)}</div>
      <div>{d.wastageUnits} units · {d.category}</div>
    </div>
  );
};

const WastageTrendChart: React.FC<Props> = ({ data }) => {
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
          Wastage Trend (Last 30 Days)
        </Typography>
        <ResponsiveContainer width="100%" height={300}>
          <AreaChart data={data} margin={{ top: 5, right: 20, bottom: 5, left: 10 }}>
            <defs>
              <linearGradient id="wastageGrad" x1="0" y1="0" x2="0" y2="1">
                <stop offset="5%" stopColor={CHART_COLORS.red} stopOpacity={0.3} />
                <stop offset="95%" stopColor={CHART_COLORS.red} stopOpacity={0.02} />
              </linearGradient>
            </defs>
            <CartesianGrid
              strokeDasharray="3 3"
              stroke={darkMode ? 'rgba(255,255,255,0.06)' : '#eee'}
            />
            <XAxis
              dataKey="date"
              tick={{ fontSize: 11, fill: darkMode ? '#888' : '#666' }}
              tickLine={false}
              axisLine={{ stroke: darkMode ? 'rgba(255,255,255,0.1)' : '#ddd' }}
              interval="preserveStartEnd"
            />
            <YAxis
              tick={{ fontSize: 11, fill: darkMode ? '#888' : '#666' }}
              tickLine={false}
              axisLine={false}
              tickFormatter={(v: number) => formatCurrencyCompact(v)}
            />
            <Tooltip content={<CustomTooltip />} />
            <Area
              type="monotone"
              dataKey="wastageValue"
              stroke={CHART_COLORS.red}
              strokeWidth={2}
              fill="url(#wastageGrad)"
              dot={false}
              activeDot={{ r: 4, fill: CHART_COLORS.red, stroke: '#fff', strokeWidth: 2 }}
            />
          </AreaChart>
        </ResponsiveContainer>
      </CardContent>
    </Card>
  );
};

export default WastageTrendChart;
