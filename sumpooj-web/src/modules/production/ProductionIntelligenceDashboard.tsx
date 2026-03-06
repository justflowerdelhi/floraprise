// Kanban board mock data
const productionKanban = {
  Waiting: [
    { order: "#1021", product: "Red Rose Bouquet", delivery: "11:30" },
    { order: "#1022", product: "Sympathy Arrangement", delivery: "12:00" },
  ],
  Assigned: [
    { order: "#1023", product: "Birthday Basket", delivery: "1:00" },
  ],
  "In Design": [
    { order: "#1024", product: "Anniversary Centerpiece", delivery: "2:00" },
  ],
  Ready: [
    { order: "#1025", product: "Get Well Flowers", delivery: "3:00" },
  ],
  Delivered: [
    { order: "#1026", product: "Congratulations Bouquet", delivery: "4:00" },
  ],
};
// Workload chart data
const hourlyProduction = [
  { hour: "9 AM", orders: 3 },
  { hour: "10 AM", orders: 5 },
  { hour: "11 AM", orders: 7 },
  { hour: "12 PM", orders: 6 },
  { hour: "1 PM", orders: 4 },
];

// Production queue table data
const productionQueue = [
  { order: "#1021", product: "Red Rose Bouquet", delivery: "11:30 AM", priority: "High" },
  { order: "#1023", product: "Sympathy Arrangement", delivery: "12:15 PM", priority: "Medium" },
  { order: "#1027", product: "Birthday Basket", delivery: "1:00 PM", priority: "Normal" },
];

// Florist efficiency table data
const floristEfficiency = [
  { name: "Priya", orders: 32, avgTime: "12 min" },
  { name: "Neha", orders: 27, avgTime: "15 min" },
  { name: "Vikram", orders: 21, avgTime: "18 min" },
];

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
  { title: "Avg Design Time", value: "14 min", color: "#E1BEE7" },
  { title: "Delayed Orders", value: 3, color: "#FFCDD2" }
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
    // Kanban board columns
    const kanbanStages = ["Waiting", "Assigned", "In Design", "Ready", "Delivered"];
    {/* Production Queue Board (Kanban) */}
    <Box sx={{ mt: 4 }}>
      <Typography variant="subtitle1" fontWeight={600} sx={{ mb: 2 }}>
        Production Queue Board
      </Typography>
      <Grid container spacing={2}>
        {kanbanStages.map((stage) => (
          <Grid item xs={12} sm={6} md={2.4} key={stage}>
            <Paper sx={{ p: 2, borderRadius: 2, minHeight: 180, bgcolor: '#f5f5f5' }}>
              <Typography variant="caption" fontWeight={700} sx={{ mb: 1, textTransform: 'uppercase', letterSpacing: 1 }}>
                {stage}
              </Typography>
              <Divider sx={{ mb: 1 }} />
              {productionKanban[stage].length === 0 ? (
                <Typography variant="body2" color="text.secondary">No orders</Typography>
              ) : (
                productionKanban[stage].map((order) => (
                  <Box key={order.order} sx={{ mb: 2, p: 1, bgcolor: '#fff', borderRadius: 1, boxShadow: 1 }}>
                    <Typography variant="subtitle2" fontWeight={600}>{order.order}</Typography>
                    <Typography variant="body2">{order.product}</Typography>
                    <Typography variant="caption" color="text.secondary">Delivery {order.delivery}</Typography>
                  </Box>
                ))
              )}
            </Paper>
          </Grid>
        ))}
      </Grid>
    </Box>
  return (
    <Box sx={{ p: 3, width: "100%" }}>
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

      {/* Workload Chart */}
      <Box sx={{ mt: 4 }}>
        <Typography variant="subtitle1" fontWeight={600} sx={{ mb: 1 }}>
          Workload by Hour
        </Typography>
        <ResponsiveContainer width="100%" height={220}>
          <BarChart data={hourlyProduction}>
            <XAxis dataKey="hour" />
            <YAxis />
            <Tooltip />
            <Bar dataKey="orders" fill="#FFA726" />
          </BarChart>
        </ResponsiveContainer>
      </Box>

      {/* Orders Waiting Production Table */}
      <Box sx={{ mt: 4 }}>
        <Typography variant="subtitle1" fontWeight={600} sx={{ mb: 1 }}>
          Orders Waiting Production
        </Typography>
        <Grid container>
          <Grid item xs={12}>
            <Paper sx={{ p: 2, borderRadius: 2 }}>
              <table style={{ width: '100%', borderCollapse: 'collapse' }}>
                <thead>
                  <tr>
                    <th style={{ textAlign: 'left', padding: '8px' }}>Order</th>
                    <th style={{ textAlign: 'left', padding: '8px' }}>Product</th>
                    <th style={{ textAlign: 'left', padding: '8px' }}>Delivery Time</th>
                    <th style={{ textAlign: 'left', padding: '8px' }}>Priority</th>
                  </tr>
                </thead>
                <tbody>
                  {productionQueue.map((row) => (
                    <tr key={row.order}>
                      <td style={{ padding: '8px' }}>{row.order}</td>
                      <td style={{ padding: '8px' }}>{row.product}</td>
                      <td style={{ padding: '8px' }}>{row.delivery}</td>
                      <td style={{ padding: '8px' }}>{row.priority}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </Paper>
          </Grid>
        </Grid>
      </Box>

      {/* Florist Efficiency Table */}
      <Box sx={{ mt: 4 }}>
        <Typography variant="subtitle1" fontWeight={600} sx={{ mb: 1 }}>
          Florist Efficiency
        </Typography>
        <Grid container>
          <Grid item xs={12}>
            <Paper sx={{ p: 2, borderRadius: 2 }}>
              <table style={{ width: '100%', borderCollapse: 'collapse' }}>
                <thead>
                  <tr>
                    <th style={{ textAlign: 'left', padding: '8px' }}>Florist</th>
                    <th style={{ textAlign: 'left', padding: '8px' }}>Orders</th>
                    <th style={{ textAlign: 'left', padding: '8px' }}>Avg Time</th>
                  </tr>
                </thead>
                <tbody>
                  {floristEfficiency.map((row) => (
                    <tr key={row.name}>
                      <td style={{ padding: '8px' }}>{row.name}</td>
                      <td style={{ padding: '8px' }}>{row.orders}</td>
                      <td style={{ padding: '8px' }}>{row.avgTime}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </Paper>
          </Grid>
        </Grid>
      </Box>
    </Box>
  );
};

export default ProductionIntelligenceDashboard;
