/**
 * CompanyManagementPage.tsx — Platform Admin Company Management
 */
import React, { useState, useEffect } from 'react';
import {
  Box, Typography, Table, TableBody, TableCell, TableContainer,
  TableHead, TableRow, Paper, Chip, CircularProgress, Button,
  Snackbar, Alert, Dialog, DialogTitle, DialogContent, DialogActions,
  List, ListItem, ListItemText,
} from '@mui/material';
import { useNavigate } from 'react-router-dom';
import api from '../../api/axios';

interface CompanyRow {
  id: string;
  name: string;
  region: string;
  isActive: boolean;
}

interface SeedResult {
  locations: number;
  taxRules: number;
  categories: number;
  suppliers: number;
  products: number;
  customers: number;
  staff: number;
  accounts: number;
  expenses: number;
  orders: number;
  events: number;
  recipes: number;
  deliveryZones: number;
  totalSeeded: number;
}

const CompanyManagementPage: React.FC = () => {
  const navigate = useNavigate();
  const [companies, setCompanies] = useState<CompanyRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [seeding, setSeeding] = useState<string | null>(null);
  const [seedResult, setSeedResult] = useState<SeedResult | null>(null);
  const [snack, setSnack] = useState<{ open: boolean; message: string; severity: 'success' | 'error' }>({
    open: false, message: '', severity: 'success',
  });

  useEffect(() => {
    const load = async () => {
      try {
        const res = await api.get('/platform/companies');
        setCompanies(res.data ?? []);
      } catch (err) {
        console.error('Failed to load companies:', err);
      } finally {
        setLoading(false);
      }
    };
    load();
  }, []);

  const handleToggleActive = async (company: CompanyRow) => {
    try {
      const endpoint = company.isActive ? 'deactivate' : 'activate';
      await api.patch(`/platform/companies/${company.id}/${endpoint}`);
      setCompanies(prev =>
        prev.map(c => c.id === company.id ? { ...c, isActive: !c.isActive } : c)
      );
    } catch (err) {
      console.error('Failed to toggle company status:', err);
    }
  };

  const handleSeedDemoData = async (company: CompanyRow) => {
    if (!confirm(`Populate demo data for "${company.name}"?\n\nThis will add ~5 sample records to each major table (customers, products, orders, etc.). Tables that already have data will be skipped.`)) return;

    setSeeding(company.id);
    try {
      const res = await api.post(`/platform/companies/${company.id}/seed-demo-data`);
      const result: SeedResult = res.data;
      if (result.totalSeeded === 0) {
        setSnack({ open: true, message: `"${company.name}" already has data in all tables. Nothing seeded.`, severity: 'success' });
      } else {
        setSeedResult(result);
      }
    } catch (err: any) {
      console.error('Failed to seed demo data:', err);
      setSnack({ open: true, message: err?.response?.data?.message || 'Failed to seed demo data', severity: 'error' });
    } finally {
      setSeeding(null);
    }
  };

  if (loading) {
    return (
      <Box sx={{ p: 4, display: 'flex', justifyContent: 'center' }}>
        <CircularProgress />
      </Box>
    );
  }

  return (
    <Box sx={{ p: 3 }}>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 3 }}>
        <Typography variant="h5" fontWeight={700}>Company Management</Typography>
        <Button variant="outlined" onClick={() => navigate('/admin/dashboard')}>Back</Button>
      </Box>

      <TableContainer component={Paper}>
        <Table>
          <TableHead>
            <TableRow>
              <TableCell><strong>Name</strong></TableCell>
              <TableCell><strong>Region</strong></TableCell>
              <TableCell><strong>Status</strong></TableCell>
              <TableCell><strong>Actions</strong></TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {companies.map(c => (
              <TableRow key={c.id}>
                <TableCell>{c.name}</TableCell>
                <TableCell>{c.region}</TableCell>
                <TableCell>
                  <Chip
                    label={c.isActive ? 'Active' : 'Inactive'}
                    color={c.isActive ? 'success' : 'default'}
                    size="small"
                  />
                </TableCell>
                <TableCell sx={{ display: 'flex', gap: 1 }}>
                  <Button size="small" onClick={() => handleToggleActive(c)}>
                    {c.isActive ? 'Deactivate' : 'Activate'}
                  </Button>
                  <Button
                    size="small"
                    variant="outlined"
                    color="secondary"
                    disabled={seeding === c.id}
                    onClick={() => handleSeedDemoData(c)}
                  >
                    {seeding === c.id ? 'Seeding…' : '🌱 Populate Demo Data'}
                  </Button>
                </TableCell>
              </TableRow>
            ))}
            {companies.length === 0 && (
              <TableRow>
                <TableCell colSpan={4} align="center">No companies found</TableCell>
              </TableRow>
            )}
          </TableBody>
        </Table>
      </TableContainer>

      {/* Seed Result Dialog */}
      <Dialog open={!!seedResult} onClose={() => setSeedResult(null)} maxWidth="xs" fullWidth>
        <DialogTitle>✅ Demo Data Populated</DialogTitle>
        <DialogContent>
          {seedResult && (
            <List dense>
              {Object.entries(seedResult)
                .filter(([key]) => key !== 'totalSeeded')
                .map(([key, count]) => (
                  <ListItem key={key}>
                    <ListItemText
                      primary={key.replace(/([A-Z])/g, ' $1').replace(/^./, s => s.toUpperCase())}
                      secondary={count > 0 ? `${count} records added` : 'Already had data — skipped'}
                    />
                    <Chip
                      label={count > 0 ? `+${count}` : 'Skipped'}
                      color={count > 0 ? 'success' : 'default'}
                      size="small"
                    />
                  </ListItem>
                ))}
              <ListItem>
                <ListItemText primary="Total" primaryTypographyProps={{ fontWeight: 700 }} />
                <Chip label={`${seedResult.totalSeeded} records`} color="primary" size="small" />
              </ListItem>
            </List>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setSeedResult(null)}>Close</Button>
        </DialogActions>
      </Dialog>

      {/* Snackbar */}
      <Snackbar
        open={snack.open}
        autoHideDuration={4000}
        onClose={() => setSnack(s => ({ ...s, open: false }))}
        anchorOrigin={{ vertical: 'bottom', horizontal: 'center' }}
      >
        <Alert severity={snack.severity} onClose={() => setSnack(s => ({ ...s, open: false }))}>
          {snack.message}
        </Alert>
      </Snackbar>
    </Box>
  );
};

export default CompanyManagementPage;
