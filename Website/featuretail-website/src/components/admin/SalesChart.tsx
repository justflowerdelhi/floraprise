"use client";

import { useEffect, useState } from "react";
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  Tooltip,
  ResponsiveContainer,
  CartesianGrid,
} from "recharts";

type SalesPoint = {
  date: string;
  total: number;
};

export default function SalesChart() {
  const [data, setData] = useState<SalesPoint[]>([]);

  useEffect(() => {
    fetch("/api/admin/dashboard-sales")
      .then((res) => res.json())
      .then((payload) => setData(payload ?? []))
      .catch(() => setData([]));
  }, []);

  return (
    <div className="bg-white p-6 rounded-xl shadow border">
      <h2 className="text-xl font-semibold mb-4">Sales - Last 7 Days</h2>

      <ResponsiveContainer width="100%" height={300}>
        <LineChart data={data}>
          <CartesianGrid strokeDasharray="3 3" />
          <XAxis dataKey="date" />
          <YAxis />
          <Tooltip />
          <Line
            type="monotone"
            dataKey="total"
            stroke="#e11d48"
            strokeWidth={3}
            dot={false}
          />
        </LineChart>
      </ResponsiveContainer>
    </div>
  );
}
