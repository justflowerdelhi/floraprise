// ...existing code...
import React, { useState } from 'react';
import { Box, Button, Grid, Paper, Typography, TextField, MenuItem } from '@mui/material';
import { getAccounts, getAccountLedgerData } from '../accounting.service';
import { locations } from '../accounting.constants.tsx';

const AccountLedger: React.FC = () => {

  const accountsData = getAccounts();
  const accounts = Array.isArray(accountsData) ? accountsData : [];

  const [accountId, setAccountId] = useState(accounts[0]?.id || '');
  const [dateFrom, setDateFrom] = useState('');
  const [dateTo, setDateTo] = useState('');
  const [location, setLocation] = useState('Main');

  const ledgerData = getAccountLedgerData({ accountId, dateFrom, dateTo, location });
  const data = Array.isArray(ledgerData) ? ledgerData : [];
  return (
    <Box sx={{ p: { xs: 1, sm: 2, md: 3 }, maxWidth: 1200, mx: 'auto' }}>
      <Typography variant="h5" fontWeight={700} sx={{ mb: 2 }}>Account Ledger</Typography>
      <Grid container spacing={2} sx={{ mb: 2 }}>
        <Grid item xs={12} sm={3}>
          <TextField label="Account" select value={accountId} onChange={e => setAccountId(e.target.value)} fullWidth>
            {accounts.map(acc => (
              <MenuItem key={acc.id} value={acc.id}>{acc.code} - {acc.name}</MenuItem>
            ))}
          </TextField>
        </Grid>
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
      </Grid>
      <Paper sx={{ p: 2, borderRadius: 2 }}>
        <Typography variant="subtitle1" fontWeight={600} sx={{ mb: 2 }}>Ledger</Typography>
        <Box sx={{ overflowX: 'auto' }}>
          <table style={{ width: '100%', borderCollapse: 'collapse' }}>
            <thead>
              <tr>
                <th>Date</th>
                <th>Reference</th>
                <th>Description</th>
                <th>Debit</th>
                <th>Credit</th>
                <th>Balance</th>
              </tr>
            </thead>
            <tbody>
              {data.map((row: any, idx: number) => (
                <tr key={idx}>
                  <td>{row.date}</td>
                  <td>{row.reference}</td>
                  <td>{row.description}</td>
                  <td>{row.debit}</td>
                  <td>{row.credit}</td>
                  <td>{row.balance}</td>
                </tr>
              ))}
              {data.length === 0 && (
                <tr>
                  <td colSpan={6} align="center">No ledger entries found</td>
                </tr>
              )}
            </tbody>
          </table>
        </Box>
        <Box sx={{ display: 'flex', gap: 2, mt: 3, flexWrap: 'wrap' }}>
          <Button variant="outlined">Export CSV</Button>
          <Button variant="outlined">Export PDF</Button>
        </Box>
      </Paper>
    </Box>
  );
};

export default AccountLedger;
