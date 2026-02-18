/**
 * AgingDistributionChart — Donut/Pie chart showing inventory aging buckets
 */
import React from 'react';
import {
  PieChart,
  Pie,
  Cell,
  Tooltip,
  Legend,
  ResponsiveContainer,
} from 'recharts';
import type { PieLabelRenderProps } from 'recharts';
import { Card, CardContent, Typography, useTheme } from '@mui/material';
import type { AgingDataPoint } from '../data/health.data';
import { AGING_COLORS } from '../data/health.data';
import { fmtCurrency } from '../utils/health.utils';

interface Props {
  data: AgingDataPoint[];
}

const RADIAN = Math.PI / 180;

const renderCustomLabel = (props: PieLabelRenderProps) => {
  const cx = Number(props.cx ?? 0);
  const cy = Number(props.cy ?? 0);
  const midAngle = Number(props.midAngle ?? 0);
  const innerRadius = Number(props.innerRadius ?? 0);
  const outerRadius = Number(props.outerRadius ?? 0);
  const percent = Number(props.percent ?? 0);
  const radius = innerRadius + (outerRadius - innerRadius) * 0.5;
  const x = cx + radius * Math.cos(-midAngle * RADIAN);
  const y = cy + radius * Math.sin(-midAngle * RADIAN);

  if (percent < 0.05) return null;

  return (
    <text x={x} y={y} fill="#fff" textAnchor="middle" dominantBaseline="central" fontSize={12} fontWeight={700}>
      {`${(percent * 100).toFixed(0)}%`}
    </text>
  );
};

interface TooltipPayloadItem {
  payload: AgingDataPoint;
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
      <strong>{d.bucket}</strong>
      <div>{d.itemCount} items · {d.percentage}%</div>
      <div>Value: {fmtCurrency(d.value)}</div>
    </div>
  );
};

const AgingDistributionChart: React.FC<Props> = ({ data }) => {
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
          Inventory Aging Distribution
        </Typography>
        <ResponsiveContainer width="100%" height={300}>
          <PieChart>
            <Pie
              data={data}
              dataKey="itemCount"
              nameKey="bucket"
              cx="50%"
              cy="50%"
              innerRadius={60}
              outerRadius={110}
              paddingAngle={2}
              labelLine={false}
              label={renderCustomLabel}
            >
              {data.map((entry) => (
                <Cell
                  key={entry.bucket}
                  fill={AGING_COLORS[entry.bucket]}
                  stroke={darkMode ? '#1a1a2e' : '#fff'}
                  strokeWidth={2}
                />
              ))}
            </Pie>
            <Tooltip content={<CustomTooltip />} />
            <Legend
              verticalAlign="bottom"
              iconType="circle"
              wrapperStyle={{ fontSize: 12, color: darkMode ? '#aaa' : '#666' }}
            />
          </PieChart>
        </ResponsiveContainer>
      </CardContent>
    </Card>
  );
};

export default AgingDistributionChart;
