/**
 * CompanyManagementPage.tsx — Platform Admin Company Management
 */
import React, { useState, useEffect, useCallback } from 'react';
import {
  Box, Typography, Table, TableBody, TableCell, TableContainer,
  TableHead, TableRow, Paper, Chip, CircularProgress, Button,
  Snackbar, Alert, Dialog, DialogTitle, DialogContent, DialogActions,
  List, ListItem, ListItemText, TextField, Grid, IconButton,
} from '@mui/material';
import { Edit as EditIcon, Add as AddIcon, ContentCopy as CopyIcon, Key as KeyIcon } from '@mui/icons-material';
import { useNavigate } from 'react-router-dom';
import api from '../../api/axios';

interface CompanyRow {
  id: string;
  name: string;
  region: string;
  isActive: boolean;
  email?: string;
  phone?: string;
  address?: string;
  shortDescription?: string;
  timeZone?: string;
  currencyCode?: string;
  taxIdentifier?: string;
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

interface CompanyForm {
  name: string;
  region: string;
  email: string;
  phone: string;
  address: string;
  shortDescription: string;
  timeZone: string;
  currencyCode: string;
  taxIdentifier: string;
}

const EMPTY_FORM: CompanyForm = {
  name: '', region: 'IN', email: '', phone: '', address: '',
  shortDescription: '', timeZone: 'Asia/Kolkata', currencyCode: 'INR', taxIdentifier: '',
};

const CompanyManagementPage: React.FC = () => {
  const navigate = useNavigate();
  const [companies, setCompanies] = useState<CompanyRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [seeding, setSeeding] = useState<string | null>(null);
  const [seedResult, setSeedResult] = useState<SeedResult | null>(null);
  const [purging, setPurging] = useState<string | null>(null);
  const [purgeResult, setPurgeResult] = useState<Record<string, number> | null>(null);
  const [credentials, setCredentials] = useState<{ companyName: string; adminEmail: string; tempPassword: string } | null>(null);
  const [credLoading, setCredLoading] = useState<string | null>(null);
  const [copied, setCopied] = useState('');
  const [snack, setSnack] = useState<{ open: boolean; message: string; severity: 'success' | 'error' }>({
    open: false, message: '', severity: 'success',
  });

  // Create / Edit dialog
  const [formOpen, setFormOpen] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [form, setForm] = useState<CompanyForm>(EMPTY_FORM);
  const [formSaving, setFormSaving] = useState(false);

  const loadCompanies = useCallback(async () => {
    setLoading(true);
    try {
      const res = await api.get('/platform/companies');
      setCompanies(res.data ?? []);
    } catch (err) {
      console.error('Failed to load companies:', err);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { loadCompanies(); }, [loadCompanies]);

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

  const openCreate = () => {
    setEditingId(null);
    setForm(EMPTY_FORM);
    setFormOpen(true);
  };

  const openEdit = (c: CompanyRow) => {
    setEditingId(c.id);
    setForm({
      name: c.name || '',
      region: c.region || 'IN',
      email: c.email || '',
      phone: c.phone || '',
      address: c.address || '',
      shortDescription: c.shortDescription || '',
      timeZone: c.timeZone || 'Asia/Kolkata',
      currencyCode: c.currencyCode || 'INR',
      taxIdentifier: c.taxIdentifier || '',
    });
    setFormOpen(true);
  };

  const handleFormSave = async () => {
    if (!form.name.trim()) {
      setSnack({ open: true, message: 'Company name is required', severity: 'error' });
      return;
    }
    setFormSaving(true);
    try {
      if (editingId) {
        await api.put(`/platform/companies/${editingId}`, form);
        setSnack({ open: true, message: 'Company updated', severity: 'success' });
      } else {
        await api.post('/platform/companies', form);
        setSnack({ open: true, message: 'Company created', severity: 'success' });
      }
      setFormOpen(false);
      loadCompanies();
    } catch (err: any) {
      setSnack({ open: true, message: err?.response?.data?.message || 'Failed to save', severity: 'error' });
    } finally {
      setFormSaving(false);
    }
  };

  const handleSeedDemoData = async (company: CompanyRow) => {
    if (!confirm(`Populate demo data for "${company.name}"?\n\nTables that already have data will be skipped.`)) return;
    setSeeding(company.id);
    try {
      const res = await api.post(`/platform/companies/${company.id}/seed-demo-data`);
      const result: SeedResult = res.data;
      if (result.totalSeeded === 0) {
        setSnack({ open: true, message: `"${company.name}" already has data in all tables.`, severity: 'success' });
      } else {
        setSeedResult(result);
      }
    } catch (err: any) {
      setSnack({ open: true, message: err?.response?.data?.message || 'Failed to seed', severity: 'error' });
    } finally {
      setSeeding(null);
    }
  };

  const handlePurgeDemoData = async (company: CompanyRow) => {
    if (!confirm(`⚠️ REMOVE ALL DATA for "${company.name}"?\n\nThis action CANNOT be undone.`)) return;
    setPurging(company.id);
    try {
      const res = await api.post(`/platform/companies/${company.id}/purge-demo-data`);
      const result = res.data;
      if (result.totalPurged === 0) {
        setSnack({ open: true, message: `"${company.name}" has no data to remove.`, severity: 'success' });
      } else {
        setPurgeResult(result);
      }
    } catch (err: any) {
      setSnack({ open: true, message: err?.response?.data?.message || 'Failed to purge', severity: 'error' });
    } finally {
      setPurging(null);
    }
  };

  const handleGetCredentials = async (company: CompanyRow) => {
    setCredLoading(company.id);
    try {
      const res = await api.post(`/platform/companies/${company.id}/admin-credentials`);
      setCredentials(res.data);
    } catch (err: any) {
      const msg = err?.response?.data?.message || 'Failed to get credentials';
      setSnack({ open: true, message: msg, severity: 'error' });
    } finally {
      setCredLoading(null);
    }
  };

  const copyToClipboard = async (text: string, label: string) => {
    await navigator.clipboard.writeText(text);
    setCopied(label);
    setTimeout(() => setCopied(''), 2000);
  };

  const copyAllCredentials = async () => {
    if (!credentials) return;
    const text = `Login Credentials for ${credentials.companyName}\n\nURL: ${window.location.origin}\nEmail: ${credentials.adminEmail}\nPassword: ${credentials.tempPassword}\n\nPlease change your password after first login.`;
    await navigator.clipboard.writeText(text);
    setCopied('all');
    setTimeout(() => setCopied(''), 2000);
  };

  const updateField = (field: keyof CompanyForm, value: string) =>
    setForm(prev => ({ ...prev, [field]: value }));

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
        <Box sx={{ display: 'flex', gap: 1 }}>
          <Button variant="contained" startIcon={<AddIcon />} onClick={openCreate}>
            Add Company
          </Button>
          <Button variant="outlined" onClick={() => navigate('/admin/dashboard')}>Back</Button>
        </Box>
      </Box>

      <TableContainer component={Paper}>
        <Table>
          <TableHead>
            <TableRow>
              <TableCell><strong>Name</strong></TableCell>
              <TableCell><strong>Email</strong></TableCell>
              <TableCell><strong>Region</strong></TableCell>
              <TableCell><strong>Currency</strong></TableCell>
              <TableCell><strong>Status</strong></TableCell>
              <TableCell><strong>Actions</strong></TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {companies.map(c => (
              <TableRow key={c.id}>
                <TableCell>
                  <Typography fontWeight={600}>{c.name}</Typography>
                  {c.shortDescription && (
                    <Typography variant="caption" color="text.secondary">{c.shortDescription}</Typography>
                  )}
                </TableCell>
                <TableCell>{c.email || '—'}</TableCell>
                <TableCell>{c.region}</TableCell>
                <TableCell>{c.currencyCode || '—'}</TableCell>
                <TableCell>
                  <Chip
                    label={c.isActive ? 'Active' : 'Inactive'}
                    color={c.isActive ? 'success' : 'default'}
                    size="small"
                  />
                </TableCell>
                <TableCell>
                  <Box sx={{ display: 'flex', gap: 0.5, flexWrap: 'wrap' }}>
                    <IconButton size="small" title="Edit" onClick={() => openEdit(c)}>
                      <EditIcon fontSize="small" />
                    </IconButton>
                    <Button size="small" onClick={() => handleToggleActive(c)}>
                      {c.isActive ? 'Deactivate' : 'Activate'}
                    </Button>
                    <Button size="small" variant="outlined" color="secondary"
                      disabled={seeding === c.id} onClick={() => handleSeedDemoData(c)}>
                      {seeding === c.id ? 'Seeding…' : '🌱 Demo Data'}
                    </Button>
                    <Button size="small" variant="outlined" color="error"
                      disabled={purging === c.id} onClick={() => handlePurgeDemoData(c)}>
                      {purging === c.id ? 'Removing…' : '🗑️ Purge'}
                    </Button>
                    <Button size="small" variant="outlined" color="info"
                      disabled={credLoading === c.id} onClick={() => handleGetCredentials(c)}
                      startIcon={<KeyIcon fontSize="small" />}>
                      {credLoading === c.id ? 'Loading…' : 'Login Info'}
                    </Button>
                  </Box>
                </TableCell>
              </TableRow>
            ))}
            {companies.length === 0 && (
              <TableRow>
                <TableCell colSpan={6} align="center">No companies found</TableCell>
              </TableRow>
            )}
          </TableBody>
        </Table>
      </TableContainer>

      {/* ─── Create / Edit Company Dialog ─── */}
      <Dialog open={formOpen} onClose={() => setFormOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>{editingId ? 'Edit Company' : 'Add New Company'}</DialogTitle>
        <DialogContent>
          <Grid container spacing={2} sx={{ mt: 0.5 }}>
            <Grid size={{ xs: 12 }}>
              <TextField label="Company Name" value={form.name} onChange={e => updateField('name', e.target.value)} fullWidth required />
            </Grid>
            <Grid size={{ xs: 12, sm: 6 }}>
              <TextField label="Email" value={form.email} onChange={e => updateField('email', e.target.value)} fullWidth />
            </Grid>
            <Grid size={{ xs: 12, sm: 6 }}>
              <TextField label="Phone" value={form.phone} onChange={e => updateField('phone', e.target.value)} fullWidth />
            </Grid>
            <Grid size={{ xs: 12 }}>
              <TextField label="Address" value={form.address} onChange={e => updateField('address', e.target.value)} fullWidth />
            </Grid>
            <Grid size={{ xs: 12 }}>
              <TextField label="Short Description" value={form.shortDescription} onChange={e => updateField('shortDescription', e.target.value)} fullWidth />
            </Grid>
            <Grid size={{ xs: 12, sm: 4 }}>
              <TextField label="Region" value={form.region} onChange={e => updateField('region', e.target.value)} fullWidth />
            </Grid>
            <Grid size={{ xs: 12, sm: 4 }}>
              <TextField label="Time Zone" value={form.timeZone} onChange={e => updateField('timeZone', e.target.value)} fullWidth />
            </Grid>
            <Grid size={{ xs: 12, sm: 4 }}>
              <TextField label="Currency" value={form.currencyCode} onChange={e => updateField('currencyCode', e.target.value)} fullWidth />
            </Grid>
            <Grid size={{ xs: 12 }}>
              <TextField label="Tax Identifier (GST/VAT)" value={form.taxIdentifier} onChange={e => updateField('taxIdentifier', e.target.value)} fullWidth />
            </Grid>
          </Grid>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setFormOpen(false)}>Cancel</Button>
          <Button variant="contained" onClick={handleFormSave} disabled={formSaving}>
            {formSaving ? 'Saving…' : editingId ? 'Update' : 'Create'}
          </Button>
        </DialogActions>
      </Dialog>

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
                      secondary={count > 0 ? `${count} records added` : 'Skipped'}
                    />
                    <Chip label={count > 0 ? `+${count}` : 'Skipped'} color={count > 0 ? 'success' : 'default'} size="small" />
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

      {/* Purge Result Dialog */}
      <Dialog open={!!purgeResult} onClose={() => setPurgeResult(null)} maxWidth="xs" fullWidth>
        <DialogTitle>🗑️ Demo Data Removed</DialogTitle>
        <DialogContent>
          {purgeResult && (
            <List dense>
              {Object.entries(purgeResult)
                .filter(([key]) => key !== 'totalPurged')
                .filter(([, count]) => (count as number) > 0)
                .map(([key, count]) => (
                  <ListItem key={key}>
                    <ListItemText primary={key.replace(/([A-Z])/g, ' $1').replace(/^./, s => s.toUpperCase())} />
                    <Chip label={`−${count}`} color="error" size="small" variant="outlined" />
                  </ListItem>
                ))}
              <ListItem>
                <ListItemText primary="Total Removed" primaryTypographyProps={{ fontWeight: 700 }} />
                <Chip label={`${purgeResult.totalPurged} records`} color="error" size="small" />
              </ListItem>
            </List>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setPurgeResult(null)}>Close</Button>
        </DialogActions>
      </Dialog>

      {/* Login Credentials Dialog */}
      <Dialog open={!!credentials} onClose={() => setCredentials(null)} maxWidth="sm" fullWidth>
        <DialogTitle>🔑 Company Login Credentials</DialogTitle>
        <DialogContent>
          {credentials && (
            <Box>
              <Alert severity="info" sx={{ mb: 2 }}>
                Share these login credentials with the company admin. They should change their password after first login.
              </Alert>

              <Typography variant="subtitle2" color="text.secondary" sx={{ mb: 1 }}>Company</Typography>
              <Typography variant="body1" fontWeight={600} sx={{ mb: 2 }}>{credentials.companyName}</Typography>

              <Typography variant="subtitle2" color="text.secondary" sx={{ mb: 0.5 }}>Login URL</Typography>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 2, p: 1.5, bgcolor: 'grey.100', borderRadius: 1 }}>
                <Typography variant="body2" sx={{ fontFamily: 'monospace', flexGrow: 1 }}>{window.location.origin}</Typography>
                <IconButton size="small" onClick={() => copyToClipboard(window.location.origin, 'url')} color={copied === 'url' ? 'success' : 'default'}>
                  <CopyIcon fontSize="small" />
                </IconButton>
              </Box>

              <Typography variant="subtitle2" color="text.secondary" sx={{ mb: 0.5 }}>Email</Typography>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 2, p: 1.5, bgcolor: 'grey.100', borderRadius: 1 }}>
                <Typography variant="body2" sx={{ fontFamily: 'monospace', flexGrow: 1 }}>{credentials.adminEmail}</Typography>
                <IconButton size="small" onClick={() => copyToClipboard(credentials.adminEmail, 'email')} color={copied === 'email' ? 'success' : 'default'}>
                  <CopyIcon fontSize="small" />
                </IconButton>
              </Box>

              <Typography variant="subtitle2" color="text.secondary" sx={{ mb: 0.5 }}>Temporary Password</Typography>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 2, p: 1.5, bgcolor: 'grey.100', borderRadius: 1 }}>
                <Typography variant="body2" sx={{ fontFamily: 'monospace', flexGrow: 1, fontWeight: 700 }}>{credentials.tempPassword}</Typography>
                <IconButton size="small" onClick={() => copyToClipboard(credentials.tempPassword, 'password')} color={copied === 'password' ? 'success' : 'default'}>
                  <CopyIcon fontSize="small" />
                </IconButton>
              </Box>
            </Box>
          )}
        </DialogContent>
        <DialogActions>
          <Button
            variant="outlined"
            startIcon={<CopyIcon />}
            onClick={copyAllCredentials}
            color={copied === 'all' ? 'success' : 'primary'}
          >
            {copied === 'all' ? 'Copied!' : 'Copy All'}
          </Button>
          <Button variant="contained" onClick={() => setCredentials(null)}>Done</Button>
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
