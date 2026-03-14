/**
 * AdminDemoRequestsPage.tsx — Platform Super Admin: Demo Requests Management
 *
 * Features:
 * - List all demo requests from DB
 * - Show status badge (NewLead / Contacted / Qualified / Converted)
 * - Update status with optional comments
 */
import React, { useState, useEffect, useCallback } from 'react';
import {
  Box, Typography, Card, Table, TableHead, TableRow, TableCell, TableBody,
  Chip, IconButton, CircularProgress, Select, MenuItem, TextField, Button,
  Dialog, DialogTitle, DialogContent, DialogActions, Alert,
} from '@mui/material';
import { Edit as EditIcon, Refresh as RefreshIcon, ContentCopy as CopyIcon } from '@mui/icons-material';
import api from '../../api/axios';

interface DemoRequest {
  id: string;
  fullName: string;
  businessEmail: string;
  businessType?: string;
  currentSoftware?: string;
  notes?: string;
  status: string;
  comments?: string;
  createdAt: string;
  updatedAt?: string;
}

const STATUS_COLORS: Record<string, 'default' | 'info' | 'warning' | 'success'> = {
  NewLead: 'default',
  Contacted: 'info',
  Qualified: 'warning',
  Converted: 'success',
};

const STATUSES = ['NewLead', 'Contacted', 'Qualified', 'Converted'];

export default function AdminDemoRequestsPage() {
  const [requests, setRequests] = useState<DemoRequest[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  // Edit dialog
  const [editItem, setEditItem] = useState<DemoRequest | null>(null);
  const [editStatus, setEditStatus] = useState('');
  const [editComments, setEditComments] = useState('');
  const [saving, setSaving] = useState(false);
  const [onboarding, setOnboarding] = useState<string | null>(null);
  const [credentials, setCredentials] = useState<{ companyName: string; adminEmail: string; tempPassword: string } | null>(null);
  const [copied, setCopied] = useState('');

  const loadData = useCallback(async () => {
    setLoading(true);
    setError('');
    try {
      const res = await api.get('/admin/demo-requests');
      setRequests(res.data);
    } catch (err: any) {
      setError('Failed to load demo requests');
      console.error(err);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { loadData(); }, [loadData]);

  const openEdit = (item: DemoRequest) => {
    setEditItem(item);
    setEditStatus(item.status);
    setEditComments(item.comments ?? '');
  };

  const handleSave = async () => {
    if (!editItem) return;
    setSaving(true);
    try {
      await api.patch(`/admin/demo-requests/${editItem.id}/status`, {
        status: editStatus,
        comments: editComments || null,
      });
      setEditItem(null);
      loadData();
    } catch (err: any) {
      console.error('Failed to update status:', err);
    } finally {
      setSaving(false);
    }
  };

  const fmtDate = (iso: string) =>
    new Date(iso).toLocaleString('en-IN', {
      day: '2-digit', month: 'short', year: 'numeric',
      hour: '2-digit', minute: '2-digit',
    });

  const handleOnboard = async (r: DemoRequest) => {
    if (!confirm(`Onboard "${r.fullName}" as a new company?\n\nThis will:\n• Create a new company with their info\n• Create a CompanyAdmin login\n• Mark this demo request as "Converted"`)) return;

    setOnboarding(r.id);
    try {
      const res = await api.post(`/admin/demo-requests/${r.id}/onboard`);
      setCredentials({
        companyName: res.data.companyName,
        adminEmail: res.data.adminEmail,
        tempPassword: res.data.tempPassword,
      });
      loadData();
    } catch (err: any) {
      const msg = err?.response?.data?.message || 'Failed to onboard';
      alert(msg);
    } finally {
      setOnboarding(null);
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

  if (loading) {
    return (
      <Box p={4} display="flex" justifyContent="center">
        <CircularProgress />
      </Box>
    );
  }

  return (
    <Box p={3}>
      <Box display="flex" justifyContent="space-between" alignItems="center" mb={3}>
        <Typography variant="h5" fontWeight={700}>
          Demo Requests
        </Typography>
        <IconButton onClick={loadData}><RefreshIcon /></IconButton>
      </Box>

      {error && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}

      <Card sx={{ p: 2, overflowX: 'auto' }}>
        <Table>
          <TableHead>
            <TableRow>
              <TableCell>Name</TableCell>
              <TableCell>Email</TableCell>
              <TableCell>Business Type</TableCell>
              <TableCell>Current Software</TableCell>
              <TableCell>Notes</TableCell>
              <TableCell>Status</TableCell>
              <TableCell>Comments</TableCell>
              <TableCell>Submitted</TableCell>
              <TableCell>Actions</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {requests.length === 0 && (
              <TableRow>
                <TableCell colSpan={9} align="center">No demo requests yet</TableCell>
              </TableRow>
            )}
            {requests.map((r) => (
              <TableRow key={r.id}>
                <TableCell>{r.fullName}</TableCell>
                <TableCell>{r.businessEmail}</TableCell>
                <TableCell>{r.businessType || '—'}</TableCell>
                <TableCell>{r.currentSoftware || '—'}</TableCell>
                <TableCell sx={{ maxWidth: 200, overflow: 'hidden', textOverflow: 'ellipsis' }}>
                  {r.notes || '—'}
                </TableCell>
                <TableCell>
                  <Chip
                    label={r.status}
                    color={STATUS_COLORS[r.status] ?? 'default'}
                    size="small"
                  />
                </TableCell>
                <TableCell sx={{ maxWidth: 150, overflow: 'hidden', textOverflow: 'ellipsis' }}>
                  {r.comments || '—'}
                </TableCell>
                <TableCell>{fmtDate(r.createdAt)}</TableCell>
                <TableCell>
                  <Box sx={{ display: 'flex', gap: 0.5 }}>
                    <IconButton size="small" onClick={() => openEdit(r)} title="Edit Status">
                      <EditIcon fontSize="small" />
                    </IconButton>
                    {r.status !== 'Converted' && (
                      <Button
                        size="small"
                        variant="contained"
                        color="success"
                        disabled={onboarding === r.id}
                        onClick={() => handleOnboard(r)}
                      >
                        {onboarding === r.id ? 'Creating…' : '🚀 Onboard'}
                      </Button>
                    )}
                    {r.status === 'Converted' && (
                      <Chip label="Onboarded" color="success" size="small" variant="outlined" />
                    )}
                  </Box>
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </Card>

      {/* Edit Status Dialog */}
      <Dialog open={!!editItem} onClose={() => setEditItem(null)} maxWidth="sm" fullWidth>
        <DialogTitle>Update Demo Request Status</DialogTitle>
        <DialogContent>
          <Typography variant="body2" color="text.secondary" mb={2}>
            {editItem?.fullName} — {editItem?.businessEmail}
          </Typography>
          <Select
            value={editStatus}
            onChange={(e) => setEditStatus(e.target.value)}
            fullWidth
            sx={{ mb: 2 }}
          >
            {STATUSES.map((s) => (
              <MenuItem key={s} value={s}>{s}</MenuItem>
            ))}
          </Select>
          <TextField
            label="Comments"
            value={editComments}
            onChange={(e) => setEditComments(e.target.value)}
            multiline
            rows={3}
            fullWidth
          />
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setEditItem(null)}>Cancel</Button>
          <Button variant="contained" onClick={handleSave} disabled={saving}>
            {saving ? 'Saving...' : 'Save'}
          </Button>
        </DialogActions>
      </Dialog>

      {/* Onboard Credentials Dialog */}
      <Dialog open={!!credentials} onClose={() => setCredentials(null)} maxWidth="sm" fullWidth>
        <DialogTitle>✅ Company Onboarded Successfully</DialogTitle>
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
    </Box>
  );
}
