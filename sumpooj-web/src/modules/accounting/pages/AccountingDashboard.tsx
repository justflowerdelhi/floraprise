import React, { useState, useEffect } from "react";
import { Box, Grid, Paper, Typography } from "@mui/material";
import { BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer, PieChart, Pie, Cell, Legend } from "recharts";
import ProfitSummaryCards from "./ProfitSummaryCards";
import { getAccountingDashboardData } from "../accounting.service";

const defaultDashboardData = {
  revenue: 0,
  expenses: 0,
  grossProfit: 0,
  netProfit: 0,
  taxPayable: 0,
  monthlyRevenueExpense: [],
  topExpenseCategories: []
};

const pieColors = ["#FF7043", "#42A5F5", "#66BB6A", "#FFD600", "#AB47BC"];

const AccountingDashboard: React.FC = () => {

  const [dashboardData, setDashboardData] = useState<any>(defaultDashboardData);

  useEffect(() => {
    loadDashboard();
  }, []);

  const loadDashboard = async () => {
    const data = await getAccountingDashboardData();
    setDashboardData(data || defaultDashboardData);
  };

  const summaryCards = [
    { title: "Revenue (This Month)", value: dashboardData.revenue, color: "#E3F2FD" },
    { title: "Expenses (This Month)", value: dashboardData.expenses, color: "#FFEBEE" },
    { title: "Gross Profit", value: dashboardData.grossProfit, color: "#E8F5E9" },
    { title: "Net Profit", value: dashboardData.netProfit, color: "#FFFDE7" },
    { title: "Tax Payable", value: dashboardData.taxPayable, color: "#F3E5F5" }
  ];

  const revenueExpenseChartData = dashboardData.monthlyRevenueExpense || [];

  return (
    <Box sx={{ p: { xs: 1, sm: 2, md: 3 }, maxWidth: 1200, mx: "auto" }}>
      <Typography variant="h5" fontWeight={700} sx={{ mb: 2 }}>
        Accounting Dashboard
      </Typography>

      <ProfitSummaryCards cards={summaryCards} />

      <Grid container spacing={3} sx={{ mt: 2 }}>

        <Grid size={{ xs: 12, md: 7 }}>
          <Paper sx={{ p: 2, borderRadius: 2 }}>
            <Typography variant="subtitle1" fontWeight={600} sx={{ mb: 1 }}>
              Revenue vs Expense
            </Typography>

            <ResponsiveContainer width="100%" height={300}>
              <BarChart data={revenueExpenseChartData}>
                <XAxis dataKey="month" />
                <YAxis />
                <Tooltip />
                <Legend />
                <Bar dataKey="revenue" fill="#42A5F5" name="Revenue" />
                <Bar dataKey="expense" fill="#FF7043" name="Expense" />
              </BarChart>
            </ResponsiveContainer>

          </Paper>
        </Grid>

        <Grid size={{ xs: 12, md: 5 }}>
          <Paper sx={{ p: 2, borderRadius: 2 }}>
            <Typography variant="subtitle1" fontWeight={600} sx={{ mb: 1 }}>
              Top Expense Categories
            </Typography>

            <ResponsiveContainer width="100%" height={300}>
              <PieChart>

                <Pie
                  data={dashboardData.topExpenseCategories || []}
                  dataKey="amount"
                  nameKey="category"
                  cx="50%"
                  cy="50%"
                  outerRadius={100}
                  label
                >
                  {(dashboardData.topExpenseCategories || []).map((entry: any, idx: number) => (
                    <Cell key={entry.category} fill={pieColors[idx % pieColors.length]} />
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

export default AccountingDashboard;