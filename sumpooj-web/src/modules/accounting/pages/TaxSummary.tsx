import React, { useState } from 'react';
import { Box, Button, Grid, Paper, Typography, TextField, MenuItem } from '@mui/material';
import { BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer, Legend } from 'recharts';
import ProfitSummaryCards from './ProfitSummaryCards';
import { getTaxSummaryData, taxTypes } from '../accounting.service';
import { locations } from '../accounting.constants.tsx';

const TaxSummary: React.FC = () => {
  const [dateFrom, setDateFrom] = useState('');
  const [dateTo, setDateTo] = useState('');
  const [location, setLocation] = useState('Main');
  const [taxType, setTaxType] = useState('');
  const data = getTaxSummaryData();

  const summaryCards = [
    { title: 'Tax Collected', value: 0, color: '#E3F2FD' },
    { title: 'Tax Paid', value: 0, color: '#FFEBEE' },
    { title: 'Net Tax Payable', value: 0, color: '#E8F5E9' },
  ];

  return (
    <Box sx={{ p: { xs: 1, sm: 2, md: 3 }, maxWidth: 1200, mx: 'auto' }}>
      <Typography variant="h5" fontWeight={700} sx={{ mb: 2 }}>Tax Summary</Typography>
      <Grid container spacing={2} sx={{ mb: 2 }}>
        <Grid item xs={12} sm={3}>
          <TextField label="From" type="date" value={dateFrom} onChange={e => setDateFrom(e.target.value)} fullWidth InputLabelProps={{ shrink: true }} />
        </Grid>
        <Grid item xs={12} sm={3}>
          <TextField label="To" type="date" value={dateTo} onChange={e => setDateTo(e.target.value)} fullWidth InputLabelProps={{ shrink: true }} />
        </Grid>
        <Grid item xs={12} sm={3}>
          <TextField label="Location" select value={location} onChange={e => setLocation(e.target.value)} fullWidth>
            {locations.map(l => (
              <MenuItem key={l} value={l}>{l}</MenuItem>
            ))}
          </TextField>
        </Grid>
        <Grid item xs={12} sm={3}>
          <TextField label="Tax Type" select value={taxType} onChange={e => setTaxType(e.target.value)} fullWidth>
            <MenuItem value="">All</MenuItem>
            {taxTypes.map(tt => (
              <MenuItem key={tt} value={tt}>{tt}</MenuItem>
            ))}
          </TextField>
        </Grid>
      </Grid>
      <ProfitSummaryCards cards={summaryCards} />
      <Box sx={{ mt: 3 }}>
        <Paper sx={{ p: 2, borderRadius: 2, mb: 3 }}>
          <Typography variant="subtitle1" fontWeight={600} sx={{ mb: 1 }}>Tax Collected vs Tax Paid</Typography>
          <ResponsiveContainer width="100%" height={250}>
            <BarChart data={data.taxChartData}>
              <XAxis dataKey="month" />
              <YAxis />
              <Tooltip />
              <Legend />
              <Bar dataKey="collected" fill="#42A5F5" name="Tax Collected" />
              <Bar dataKey="paid" fill="#FF7043" name="Tax Paid" />
            </BarChart>
          </ResponsiveContainer>
        </Paper>
        <Paper sx={{ p: 2, borderRadius: 2 }}>
          <Typography variant="subtitle1" fontWeight={600} sx={{ mb: 2 }}>Tax Breakdown</Typography>
          <Box sx={{ overflowX: 'auto' }}>
            <table style={{ width: '100%', borderCollapse: 'collapse' }}>
              <thead>
                <tr>
                  <th>Tax Type</th>
                  <th>Tax Rate</th>
                  <th>Taxable Amount</th>
                  <th>Tax Amount</th>
                </tr>
              </thead>
              <tbody>
                {(data.taxBreakdown || []).map((row: any, idx: number) => (
                  <tr key={idx}>
                    <td>{row.taxType}</td>
                    <td>{row.taxRate}%</td>
                    <td>{row.taxableAmount}</td>
                    <td>{row.taxAmount}</td>
                  </tr>
                ))}
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

export default TaxSummary;
