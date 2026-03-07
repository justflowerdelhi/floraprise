import React, { useState } from 'react';
import { Box, Button, Grid, Paper, Typography, TextField, MenuItem } from '@mui/material';
import { BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer, Legend } from 'recharts';
import ProfitSummaryCards from './ProfitSummaryCards';
import { getProfitLossReportData } from '../accounting.service';
import { locations } from '../accounting.constants.tsx';

const ProfitLossReport: React.FC = () => {
  const [dateFrom, setDateFrom] = useState('');
  const [dateTo, setDateTo] = useState('');
  const [location, setLocation] = useState('Main');
  const data = getProfitLossReportData({ dateFrom, dateTo, location });

  // Fix profit margin calculation
  const totalRevenue = data.totalRevenue || 0;
  const netProfit = data.netProfit || 0;
  const profitMargin =
    totalRevenue > 0
      ? ((netProfit / totalRevenue) * 100).toFixed(2)
      : 0;

  const summaryCards = [
    { title: 'Total Revenue', value: data.totalRevenue, color: '#E3F2FD' },
    { title: 'COGS', value: data.cogs, color: '#FFEBEE' },
    { title: 'Gross Profit', value: data.grossProfit, color: '#E8F5E9' },
    { title: 'Total Expenses', value: data.totalExpenses, color: '#FFFDE7' },
    { title: 'Net Profit', value: data.netProfit, color: '#F3E5F5' },
    { title: 'Profit Margin %', value: `${profitMargin}%`, color: '#E1F5FE' },
  ];

  return (
    <Box sx={{ p: { xs: 1, sm: 2, md: 3 }, maxWidth: 1200, mx: 'auto' }}>
      <Typography variant="h5" fontWeight={700} sx={{ mb: 2 }}>Profit & Loss Report</Typography>
      <Grid container spacing={2} sx={{ mb: 2 }}>
        <Grid item xs={12} sm={4}>
          <TextField label="From" type="date" value={dateFrom} onChange={e => setDateFrom(e.target.value)} fullWidth InputLabelProps={{ shrink: true }} />
        </Grid>
        <Grid item xs={12} sm={4}>
          <TextField label="To" type="date" value={dateTo} onChange={e => setDateTo(e.target.value)} fullWidth InputLabelProps={{ shrink: true }} />
        </Grid>
        <Grid item xs={12} sm={4}>
          <TextField label="Location" select value={location} onChange={e => setLocation(e.target.value)} fullWidth>
            {locations.map(l => (
              <MenuItem key={l} value={l}>{l}</MenuItem>
            ))}
          </TextField>
        </Grid>
      </Grid>
      <ProfitSummaryCards cards={summaryCards} />
      <Box sx={{ mt: 3 }}>
        <Paper sx={{ p: 2, borderRadius: 2, mb: 3 }}>
          <Typography variant="subtitle1" fontWeight={600} sx={{ mb: 1 }}>Revenue vs Expense</Typography>
          <ResponsiveContainer width="100%" height={300}>
            <BarChart data={data.monthlyRevenueExpense}>
              <XAxis dataKey="month" />
              <YAxis />
              <Tooltip />
              <Legend />
              <Bar dataKey="revenue" fill="#42A5F5" name="Revenue" />
              <Bar dataKey="expense" fill="#FF7043" name="Expense" />
            </BarChart>
          </ResponsiveContainer>
        </Paper>
        <Paper sx={{ p: 2, borderRadius: 2 }}>
          <Typography variant="subtitle1" fontWeight={600} sx={{ mb: 2 }}>Profit & Loss</Typography>
          <Box sx={{ overflowX: 'auto' }}>
            <table style={{ width: '100%', borderCollapse: 'collapse' }}>
              <tbody>
                <tr><td><strong>Revenue</strong></td><td>{data.totalRevenue}</td></tr>
                <tr><td><strong>Cost of Goods Sold</strong></td><td>{data.cogs}</td></tr>
                <tr><td><strong>Gross Profit</strong></td><td>{data.grossProfit}</td></tr>
                <tr><td><strong>Expenses</strong></td><td>{data.totalExpenses}</td></tr>
                <tr><td><strong>Net Profit</strong></td><td>{data.netProfit}</td></tr>
              </tbody>
            </table>
          </Box>
        </Paper>
        <Box sx={{ display: 'flex', gap: 2, mt: 3, flexWrap: 'wrap' }}>
          <Button variant="outlined">Export CSV</Button>
          <Button variant="outlined">Export PDF</Button>
        </Box>
      </Box>
    </Box>
  );
};

export default ProfitLossReport;
