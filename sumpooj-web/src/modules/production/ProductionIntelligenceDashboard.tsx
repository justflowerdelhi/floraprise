
import React from "react";
import { Box, Grid, Paper, Typography } from "@mui/material";
import {
  ResponsiveContainer,
  BarChart,
  Bar,
  XAxis,
  YAxis,
  Tooltip,
  PieChart,
  Pie,
  Cell,
  Legend
} from "recharts";

const summaryCards = [
  { title: "Orders Waiting Production", value: 12, color: "#FFE0B2" },
  { title: "Orders In Production", value: 6, color: "#BBDEFB" },
  { title: "Completed Today", value: 18, color: "#C8E6C9" },
  { title: "Avg Design Time", value: "14 min", color: "#E1BEE7" }
];

const productionTrend = [
  { day: "Mon", orders: 22 },
  { day: "Tue", orders: 28 },
  { day: "Wed", orders: 34 },
  { day: "Thu", orders: 31 },
  { day: "Fri", orders: 45 },
  { day: "Sat", orders: 52 }
];

const floristPerformance = [
  { name: "Priya", value: 32 },
  { name: "Neha", value: 27 },
  { name: "Vikram", value: 21 },
  { name: "Sameer", value: 15 }
];

const COLORS = ["#42A5F5", "#66BB6A", "#FFA726", "#AB47BC"];

const ProductionIntelligenceDashboard: React.FC = () => {
  return (
    <Box sx={{ p: 3, maxWidth: 1200, mx: "auto" }}>
      <Typography variant="h5" fontWeight={700} sx={{ mb: 2 }}>
        Production Intelligence
      </Typography>

      {/* Summary Cards */}

      <Grid container spacing={2}>
        {summaryCards.map((card) => (
          <Grid item xs={12} sm={6} md={3} key={card.title}>
            <Paper sx={{ p: 2, borderRadius: 2, background: card.color }}>
              <Typography variant="subtitle2">{card.title}</Typography>
              <Typography variant="h6" fontWeight={700}>
                {card.value}
              </Typography>
            </Paper>
          </Grid>
        ))}
      </Grid>

      {/* Charts */}

      <Grid container spacing={3} sx={{ mt: 2 }}>
        <Grid item xs={12} md={7}>
          <Paper sx={{ p: 2, borderRadius: 2 }}>
            <Typography variant="subtitle1" fontWeight={600}>
              Production Trend
            </Typography>

            <ResponsiveContainer width="100%" height={300}>
              <BarChart data={productionTrend}>
                <XAxis dataKey="day" />
                <YAxis />
                <Tooltip />
                <Bar dataKey="orders" fill="#42A5F5" />
              </BarChart>
            </ResponsiveContainer>
          </Paper>
        </Grid>

        <Grid item xs={12} md={5}>
          <Paper sx={{ p: 2, borderRadius: 2 }}>
            <Typography variant="subtitle1" fontWeight={600}>
              Florist Performance
            </Typography>

            <ResponsiveContainer width="100%" height={300}>
              <PieChart>
                <Pie
                  data={floristPerformance}
                  dataKey="value"
                  nameKey="name"
                  outerRadius={100}
                  label
                >
                  {floristPerformance.map((entry, index) => (
                    <Cell key={entry.name} fill={COLORS[index % COLORS.length]} />
                  ))}
                </Pie>

                <Legend />
              </PieChart>
            </ResponsiveContainer>
          </Paper>
        </Grid>
      </Grid>
    </Box>
  );
};

export default ProductionIntelligenceDashboard;
