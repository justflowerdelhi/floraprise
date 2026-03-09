import React from 'react';
import { Box, Grid, Paper, Typography } from '@mui/material';
import { TrendingUp, MoneyOff, Paid, AccountBalanceWallet } from '@mui/icons-material';
import { formatCurrency } from '../../core/i18n';

const snapshotData = [
  {
    title: 'Revenue Today',
    amount: 1250,
    icon: <TrendingUp fontSize="large" color="primary" />,
    color: 'primary.main',
  },
  {
    title: 'Expenses Today',
    amount: 180,
    icon: <MoneyOff fontSize="large" sx={{ color: 'error.main' }} />,
    color: 'error.main',
  },
  {
    title: 'Profit Today',
    amount: 1070,
    icon: <Paid fontSize="large" sx={{ color: 'success.main' }} />,
    color: 'success.main',
  },
  {
    title: 'Cash Balance',
    amount: 3400,
    icon: <AccountBalanceWallet fontSize="large" color="action" />,
    color: 'grey.700',
  },
];

const FinancialSnapshotWidget: React.FC = () => (
  <Grid container spacing={2}>
    {snapshotData.map((card, idx) => (
      <Grid size={{ xs: 12, sm: 6, md: 3 }} key={idx}>
        <Paper sx={{ p: 2, display: 'flex', flexDirection: 'column', alignItems: 'center', borderRadius: 2, minHeight: 120, bgcolor: 'background.paper', boxShadow: 1 }}>
          <Box sx={{ mb: 1 }}>{card.icon}</Box>
          <Typography variant="subtitle2" color="text.secondary" sx={{ mb: 0.5 }}>{card.title}</Typography>
          <Typography variant="h4" fontWeight={700} sx={{ color: card.color }}>{formatCurrency(card.amount)}</Typography>
        </Paper>
      </Grid>
    ))}
  </Grid>
);

export default FinancialSnapshotWidget;
