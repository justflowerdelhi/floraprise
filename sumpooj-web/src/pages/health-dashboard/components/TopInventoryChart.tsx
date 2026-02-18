/**
 * TopInventoryChart — Horizontal bar chart showing top 10 items by value
 */
import React from 'react';
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  Cell,
} from 'recharts';
import { Card, CardContent, Typography, useTheme } from '@mui/material';
import type { TopInventoryItem } from '../data/health.data';
import { CHART_COLORS } from '../data/health.data';
import { fmtCurrency, fmtPercent } from '../utils/health.utils';

interface Props {
  data: TopInventoryItem[];
}

const BAR_COLORS = [
  CHART_COLORS.blue,
  CHART_COLORS.indigo,
  CHART_COLORS.teal,
  CHART_COLORS.green,
  CHART_COLORS.cyan,
  CHART_COLORS.purple,
  CHART_COLORS.amber,
  CHART_COLORS.orange,
  CHART_COLORS.pink,
  CHART_COLORS.red,
];

interface TooltipPayloadItem {
  payload: TopInventoryItem;
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
      <strong>{d.productName}</strong>
      <div>{d.category}</div>
      <div>Stock: {d.currentStock} × {fmtCurrency(d.unitCost)} = <strong>{fmtCurrency(d.totalValue)}</strong></div>
      <div>{fmtPercent(d.percentOfTotal)} of total</div>
    </div>
  );
};

const TopInventoryChart: React.FC<Props> = ({ data }) => {
  const theme = useTheme();
  const darkMode = theme.palette.mode === 'dark';

  // Truncate long names for Y-axis
  const chartData = data.map((d) => ({
    ...d,
    shortName: d.productName.length > 18 ? d.productName.slice(0, 16) + '…' : d.productName,
  }));

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
          Top 10 Inventory by Value
        </Typography>
        <ResponsiveContainer width="100%" height={360}>
          <BarChart
            data={chartData}
            layout="vertical"
            margin={{ top: 5, right: 30, bottom: 5, left: 100 }}
          >
            <CartesianGrid
              strokeDasharray="3 3"
              stroke={darkMode ? 'rgba(255,255,255,0.06)' : '#eee'}
              horizontal={false}
            />
            <XAxis
              type="number"
              tick={{ fontSize: 11, fill: darkMode ? '#888' : '#666' }}
              tickLine={false}
              axisLine={false}
              tickFormatter={(v: number) => `₹${(v / 1000).toFixed(0)}K`}
            />
            <YAxis
              type="category"
              dataKey="shortName"
              tick={{ fontSize: 11, fill: darkMode ? '#aaa' : '#555' }}
              tickLine={false}
              axisLine={false}
              width={95}
            />
            <Tooltip content={<CustomTooltip />} />
            <Bar dataKey="totalValue" radius={[0, 4, 4, 0]} barSize={22}>
              {chartData.map((_, idx) => (
                <Cell key={idx} fill={BAR_COLORS[idx % BAR_COLORS.length]} />
              ))}
            </Bar>
          </BarChart>
        </ResponsiveContainer>
      </CardContent>
    </Card>
  );
};

export default TopInventoryChart;
