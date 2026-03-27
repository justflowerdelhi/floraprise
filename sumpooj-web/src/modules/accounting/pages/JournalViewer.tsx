import React, { useState, useEffect } from 'react';
import { Alert, Box, Button, Paper, Table, TableBody, TableCell, TableContainer, TableHead, TableRow, Typography, TextField, MenuItem, Grid } from '@mui/material';
import JournalEntryModal from './JournalEntryModal';
import { getJournalEntries } from '../accounting.service';

const JournalViewer: React.FC = () => {
  const [entries, setEntries] = useState<any[]>([]);
  const [modalOpen, setModalOpen] = useState(false);
  const [selectedEntry, setSelectedEntry] = useState<any>(null);
  const [dateFrom, setDateFrom] = useState('');
  const [dateTo, setDateTo] = useState('');
  const [refType, setRefType] = useState('');
  const [error, setError] = useState<string | null>(null);

  const loadEntries = () => {
    setError(null);
    getJournalEntries()
      .then(data => setEntries(Array.isArray(data) ? data : []))
      .catch(err => setError(err?.response?.data?.message || err?.message || 'Failed to load journal entries'));
  };

  useEffect(() => {
    loadEntries();
  }, []);

  const handleRowClick = (entry: any) => {
    setSelectedEntry(entry);
    setModalOpen(true);
  };

  const handleFilter = () => {
    setError(null);
    getJournalEntries()
      .then(data => {
        let filtered = Array.isArray(data) ? data : [];
        if (dateFrom) filtered = filtered.filter((e: any) => e.date >= dateFrom);
        if (dateTo) filtered = filtered.filter((e: any) => e.date <= dateTo);
        if (refType) filtered = filtered.filter((e: any) => e.referenceType === refType);
        setEntries(filtered);
      })
      .catch(err => setError(err?.response?.data?.message || err?.message || 'Failed to load journal entries'));
  };

  return (
    <Box sx={{ p: { xs: 1, sm: 2, md: 3 }, maxWidth: 1200, mx: 'auto' }}>
      <Typography variant="h5" fontWeight={700} sx={{ mb: 2 }}>Journal Viewer</Typography>
      {error && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}
      <Grid container spacing={2} sx={{ mb: 2 }}>
        <Grid size={{ xs: 12, sm: 4 }}>
          <TextField label="From" type="date" value={dateFrom} onChange={e => setDateFrom(e.target.value)} fullWidth InputLabelProps={{ shrink: true }} />
        </Grid>
        <Grid size={{ xs: 12, sm: 4 }}>
          <TextField label="To" type="date" value={dateTo} onChange={e => setDateTo(e.target.value)} fullWidth InputLabelProps={{ shrink: true }} />
        </Grid>
        <Grid size={{ xs: 12, sm: 4 }}>
          <TextField label="Reference Type" select value={refType} onChange={e => setRefType(e.target.value)} fullWidth>
            <MenuItem value="">All</MenuItem>
            {['SALE', 'CASH', 'ACCOUNT', 'RECEIVABLE', 'PAYABLE', 'INCOME', 'EXPENSE'].map(rt => (
              <MenuItem key={rt} value={rt}>{rt}</MenuItem>
            ))}
          </TextField>
        </Grid>
        <Grid size={12}>
          <Button variant="contained" onClick={handleFilter} sx={{ mr: 1 }}>Filter</Button>
          <Button variant="outlined" onClick={loadEntries}>Refresh</Button>
        </Grid>
      </Grid>
      <TableContainer component={Paper} sx={{ borderRadius: 2 }}>
        <Table>
          <TableHead>
            <TableRow>
              <TableCell>Date</TableCell>
              <TableCell>Reference</TableCell>
              <TableCell>Description</TableCell>
              <TableCell>Debit</TableCell>
              <TableCell>Credit</TableCell>
              <TableCell>Actions</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {entries.map((entry: any) => (
              <TableRow key={entry.id} hover sx={{ cursor: 'pointer' }} onClick={() => handleRowClick(entry)}>
                <TableCell>{entry.date}</TableCell>
                <TableCell>{entry.reference}</TableCell>
                <TableCell>{entry.description}</TableCell>
                <TableCell>{entry.debit}</TableCell>
                <TableCell>{entry.credit}</TableCell>
                <TableCell>
                  <Button size="small" variant="outlined" onClick={e => { e.stopPropagation(); handleRowClick(entry); }}>View</Button>
                </TableCell>
              </TableRow>
            ))}
            {entries.length === 0 && (
              <TableRow>
                <TableCell colSpan={6} align="center">No journal entries found</TableCell>
              </TableRow>
            )}
          </TableBody>
        </Table>
      </TableContainer>
      <JournalEntryModal open={modalOpen} onClose={() => setModalOpen(false)} entry={selectedEntry} />
    </Box>
  );
};

export default JournalViewer;
