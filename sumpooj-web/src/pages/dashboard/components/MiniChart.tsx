/**
 * MiniChart.tsx — Tiny sales trend bar chart using Recharts.
 */
import {
  ResponsiveContainer,
  BarChart,
  Bar,
  XAxis,
  YAxis,
  Tooltip,
} from 'recharts';
import type { SalesTrendPoint } from '../api/dashboardApi';

interface MiniChartProps {
  data: SalesTrendPoint[];
}

export default function MiniChart({ data }: MiniChartProps) {
  return (
    <div className="bg-white rounded-xl shadow-sm border border-slate-100 p-5">
      <p className="text-xs font-medium text-slate-500 uppercase tracking-wide mb-4">
        This Week's Sales
      </p>
      <div className="h-44">
        <ResponsiveContainer width="100%" height="100%">
          <BarChart data={data} barCategoryGap="30%">
            <XAxis
              dataKey="day"
              axisLine={false}
              tickLine={false}
              tick={{ fontSize: 11, fill: '#94a3b8' }}
            />
            <YAxis hide />
            <Tooltip
              contentStyle={{
                background: '#fff',
                border: '1px solid #e2e8f0',
                borderRadius: 10,
                fontSize: 12,
                boxShadow: '0 2px 8px rgba(0,0,0,0.06)',
              }}
              formatter={(v: number | undefined) => [`₹${(v ?? 0).toLocaleString('en-IN')}`, 'Sales']}
              cursor={{ fill: 'rgba(0,0,0,0.03)' }}
            />
            <Bar dataKey="sales" fill="#10b981" radius={[6, 6, 0, 0]} />
          </BarChart>
        </ResponsiveContainer>
      </div>
    </div>
  );
}
