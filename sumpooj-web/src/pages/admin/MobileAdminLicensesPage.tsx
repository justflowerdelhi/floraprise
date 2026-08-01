import React, { useCallback, useEffect, useMemo, useState } from 'react';
import {
  Alert,
  Box,
  Button,
  Card,
  CardContent,
  Chip,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  Grid,
  MenuItem,
  Skeleton,
  Stack,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TablePagination,
  TableRow,
  TextField,
  Typography,
} from '@mui/material';
import { useNavigate } from 'react-router-dom';
import {
  activateMobileAdminLicense,
  convertTrialMobileAdminLicense,
  extendMobileAdminLicense,
  getMobileAdminLicenses,
  getMobileAdminPlans,
  resumeMobileAdminLicense,
  suspendMobileAdminLicense,
  type MobileAdminLicenseListItem,
  type MobileSubscriptionPlanDto,
} from '../../api/mobile-admin.api';
import { getCompanies } from '../../api/company.api';
import MobileAdminGlobalSearchBar from './components/MobileAdminGlobalSearchBar';

interface CompanyOption {
  id: string;
  name: string;
}

type LicenseAction = 'ACTIVATE' | 'SUSPEND' | 'RESUME' | 'EXTEND' | 'CONVERT_TRIAL';

const formatDate = (value?: string | null) => {
  if (!value) return '—';
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return '—';
  return date.toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' });
};

const MobileAdminLicensesPage: React.FC = () => {
  const navigate = useNavigate();
  const [companies, setCompanies] = useState<CompanyOption[]>([]);
  const [plans, setPlans] = useState<MobileSubscriptionPlanDto[]>([]);
  const [companyId, setCompanyId] = useState('');
  const [search, setSearch] = useState('');
  const [status, setStatus] = useState('');
  const [planCode, setPlanCode] = useState('');
  const [rows, setRows] = useState<MobileAdminLicenseListItem[]>([]);
  const [totalCount, setTotalCount] = useState(0);
  const [page, setPage] = useState(0);
  const [pageSize, setPageSize] = useState(20);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  const [actionOpen, setActionOpen] = useState(false);
  const [actionType, setActionType] = useState<LicenseAction>('ACTIVATE');
  const [actionRow, setActionRow] = useState<MobileAdminLicenseListItem | null>(null);
  const [actionNotes, setActionNotes] = useState('');
  const [extendByDays, setExtendByDays] = useState<number>(30);
  const [convertPlanId, setConvertPlanId] = useState('');
  const [convertBillingCycle, setConvertBillingCycle] = useState('monthly');
  const [actionLoading, setActionLoading] = useState(false);

  const planCodeOptions = useMemo(() => {
    return Array.from(new Set(plans.map((x) => x.code))).filter(Boolean);
  }, [plans]);

  const fetchReference = useCallback(async () => {
    const [companyRows, planRows] = await Promise.all([getCompanies(), getMobileAdminPlans()]);
    setCompanies((companyRows ?? []).map((x: any) => ({ id: String(x.id), name: String(x.name ?? x.id) })));
    setPlans(planRows ?? []);
  }, []);

  const fetchLicenses = useCallback(async () => {
    setLoading(true);
    setError('');
    try {
      const result = await getMobileAdminLicenses({
        companyId: companyId || undefined,
        search: search || undefined,
        status: status || undefined,
        planCode: planCode || undefined,
        page: page + 1,
        pageSize,
      });
      setRows(result.items ?? []);
      setTotalCount(result.totalCount ?? 0);
    } catch (err: any) {
      setError(err?.response?.data?.message || 'Unable to load licenses.');
    } finally {
      setLoading(false);
    }
  }, [companyId, search, status, planCode, page, pageSize]);

  useEffect(() => {
    fetchReference().catch(() => setError('Unable to load reference data.'));
  }, [fetchReference]);

  useEffect(() => {
    fetchLicenses().catch(() => setError('Unable to load licenses.'));
  }, [fetchLicenses]);

  const openActionDialog = (type: LicenseAction, row: MobileAdminLicenseListItem) => {
    setActionType(type);
    setActionRow(row);
    setActionNotes('');
    setExtendByDays(30);
    setConvertPlanId('');
    setConvertBillingCycle('monthly');
    setActionOpen(true);
  };

  const submitAction = async () => {
    if (!actionRow) return;
    setActionLoading(true);
    setError('');
    setSuccess('');
    try {
      const payload = { companyId: actionRow.companyId, notes: actionNotes || undefined };
      if (actionType === 'ACTIVATE') {
        await activateMobileAdminLicense(actionRow.mobileLicenseId, payload);
        setSuccess('License activated.');
      }
      if (actionType === 'SUSPEND') {
        await suspendMobileAdminLicense(actionRow.mobileLicenseId, payload);
        setSuccess('License suspended.');
      }
      if (actionType === 'RESUME') {
        await resumeMobileAdminLicense(actionRow.mobileLicenseId, payload);
        setSuccess('License resumed.');
      }
      if (actionType === 'EXTEND') {
        await extendMobileAdminLicense(actionRow.mobileLicenseId, {
          companyId: actionRow.companyId,
          extendByDays,
          notes: actionNotes || undefined,
        });
        setSuccess('License extended.');
      }
      if (actionType === 'CONVERT_TRIAL') {
        if (!convertPlanId) {
          setError('Please select target plan for trial conversion.');
          setActionLoading(false);
          return;
        }
        await convertTrialMobileAdminLicense(actionRow.mobileLicenseId, {
          companyId: actionRow.companyId,
          planId: convertPlanId,
          billingCycle: convertBillingCycle,
          notes: actionNotes || undefined,
        });
        setSuccess('Trial converted to paid successfully.');
      }
      setActionOpen(false);
      await fetchLicenses();
    } catch (err: any) {
      setError(err?.response?.data?.message || 'Action failed.');
    } finally {
      setActionLoading(false);
    }
  };

  return (
    <Box sx={{ p: 3 }}>
      <Stack direction={{ xs: 'column', md: 'row' }} justifyContent="space-between" alignItems={{ xs: 'stretch', md: 'center' }} spacing={2} sx={{ mb: 2 }}>
        <Box>
          <Typography variant="h5" fontWeight={700}>Licenses Console</Typography>
          <Typography variant="body2" color="text.secondary">Manage lifecycle of mobile licenses.</Typography>
        </Box>
        <Stack direction="row" spacing={1}>
          <Button variant="outlined" onClick={() => navigate('/admin/mobile/dashboard')}>Dashboard</Button>
          <Button variant="outlined" onClick={() => navigate('/admin/mobile/customers')}>Customers</Button>
        </Stack>
      </Stack>

      <Card sx={{ mb: 2 }}>
        <CardContent>
          <MobileAdminGlobalSearchBar companyId={companyId || undefined} />
        </CardContent>
      </Card>

      {error && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}
      {success && <Alert severity="success" sx={{ mb: 2 }}>{success}</Alert>}

      <Card sx={{ mb: 2 }}>
        <CardContent>
          <Grid container spacing={2}>
            <Grid size={{ xs: 12, md: 3 }}>
              <TextField fullWidth size="small" label="Search" placeholder="license no, business" value={search} onChange={(e) => { setSearch(e.target.value); setPage(0); }} />
            </Grid>
            <Grid size={{ xs: 12, sm: 6, md: 2 }}>
              <TextField select fullWidth size="small" label="Company" value={companyId} onChange={(e) => { setCompanyId(e.target.value); setPage(0); }}>
                <MenuItem value="">All</MenuItem>
                {companies.map((company) => <MenuItem key={company.id} value={company.id}>{company.name}</MenuItem>)}
              </TextField>
            </Grid>
            <Grid size={{ xs: 12, sm: 6, md: 2 }}>
              <TextField select fullWidth size="small" label="Status" value={status} onChange={(e) => { setStatus(e.target.value); setPage(0); }}>
                <MenuItem value="">All</MenuItem>
                <MenuItem value="Active">Active</MenuItem>
                <MenuItem value="Suspended">Suspended</MenuItem>
                <MenuItem value="Revoked">Revoked</MenuItem>
                <MenuItem value="Expired">Expired</MenuItem>
              </TextField>
            </Grid>
            <Grid size={{ xs: 12, sm: 6, md: 2 }}>
              <TextField select fullWidth size="small" label="Plan" value={planCode} onChange={(e) => { setPlanCode(e.target.value); setPage(0); }}>
                <MenuItem value="">All</MenuItem>
                {planCodeOptions.map((code) => <MenuItem key={code} value={code}>{code}</MenuItem>)}
              </TextField>
            </Grid>
          </Grid>
          <Stack direction="row" spacing={1} sx={{ mt: 2 }}>
            <Button variant="contained" onClick={() => fetchLicenses()}>Apply</Button>
            <Button variant="outlined" onClick={() => { setSearch(''); setCompanyId(''); setStatus(''); setPlanCode(''); setPage(0); }}>Reset</Button>
          </Stack>
        </CardContent>
      </Card>

      <Card>
        <CardContent sx={{ p: 0 }}>
          {loading ? (
            <Box sx={{ p: 2 }}>
              <Skeleton height={42} />
              <Skeleton height={42} />
              <Skeleton height={42} />
              <Skeleton height={42} />
            </Box>
          ) : rows.length === 0 ? (
            <Box sx={{ p: 3 }}><Alert severity="info">No licenses found.</Alert></Box>
          ) : (
            <>
              <TableContainer>
                <Table size="small">
                  <TableHead>
                    <TableRow>
                      <TableCell><strong>License Number</strong></TableCell>
                      <TableCell><strong>Business</strong></TableCell>
                      <TableCell><strong>Plan</strong></TableCell>
                      <TableCell><strong>Status</strong></TableCell>
                      <TableCell><strong>Issue Date</strong></TableCell>
                      <TableCell><strong>Expiry Date</strong></TableCell>
                      <TableCell><strong>Remaining Days</strong></TableCell>
                      <TableCell align="right"><strong>Actions</strong></TableCell>
                    </TableRow>
                  </TableHead>
                  <TableBody>
                    {rows.map((row) => (
                      <TableRow key={row.mobileLicenseId} hover>
                        <TableCell>
                          <Typography fontWeight={600}>{row.licenseNumber.slice(0, 8)}...</Typography>
                          <Typography variant="caption" color="text.secondary">{row.licenseNumber}</Typography>
                        </TableCell>
                        <TableCell>{row.businessName || '—'}</TableCell>
                        <TableCell>{row.plan || '—'}</TableCell>
                        <TableCell><Chip size="small" label={row.status} color={row.status === 'Active' ? 'success' : 'default'} /></TableCell>
                        <TableCell>{formatDate(row.issueDateUtc)}</TableCell>
                        <TableCell>{formatDate(row.expiryDateUtc)}</TableCell>
                        <TableCell>{row.remainingDays}</TableCell>
                        <TableCell align="right">
                          <Stack direction="row" spacing={1} justifyContent="flex-end" useFlexGap flexWrap="wrap">
                            <Button size="small" onClick={() => openActionDialog('ACTIVATE', row)}>Activate</Button>
                            <Button size="small" color="warning" onClick={() => openActionDialog('SUSPEND', row)}>Suspend</Button>
                            <Button size="small" color="success" onClick={() => openActionDialog('RESUME', row)}>Resume</Button>
                            <Button size="small" onClick={() => openActionDialog('EXTEND', row)}>Extend</Button>
                            <Button size="small" onClick={() => openActionDialog('CONVERT_TRIAL', row)}>Convert Trial</Button>
                            <Button size="small" onClick={() => navigate(`/admin/mobile/customers/${row.companyId}/${row.mobileUserId}`)}>View Customer</Button>
                          </Stack>
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </TableContainer>
              <TablePagination
                component="div"
                count={totalCount}
                page={page}
                onPageChange={(_, nextPage) => setPage(nextPage)}
                rowsPerPage={pageSize}
                onRowsPerPageChange={(e) => { setPageSize(Number(e.target.value)); setPage(0); }}
                rowsPerPageOptions={[10, 20, 50]}
              />
            </>
          )}
        </CardContent>
      </Card>

      <Dialog open={actionOpen} onClose={() => setActionOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>
          {actionType === 'ACTIVATE' && 'Activate License'}
          {actionType === 'SUSPEND' && 'Suspend License'}
          {actionType === 'RESUME' && 'Resume License'}
          {actionType === 'EXTEND' && 'Extend License'}
          {actionType === 'CONVERT_TRIAL' && 'Convert Trial to Paid'}
        </DialogTitle>
        <DialogContent dividers>
          <Stack spacing={2}>
            <Typography variant="body2" color="text.secondary">
              License: {actionRow?.licenseNumber}
            </Typography>
            {actionType === 'EXTEND' && (
              <TextField type="number" fullWidth label="Extend By Days" value={extendByDays} onChange={(e) => setExtendByDays(Number(e.target.value || 0))} />
            )}
            {actionType === 'CONVERT_TRIAL' && (
              <>
                <TextField select fullWidth label="Target Plan" value={convertPlanId} onChange={(e) => setConvertPlanId(e.target.value)}>
                  <MenuItem value="">Select Plan</MenuItem>
                  {plans.map((plan) => <MenuItem key={plan.id} value={plan.id}>{plan.name} ({plan.code})</MenuItem>)}
                </TextField>
                <TextField select fullWidth label="Billing Cycle" value={convertBillingCycle} onChange={(e) => setConvertBillingCycle(e.target.value)}>
                  <MenuItem value="monthly">Monthly</MenuItem>
                  <MenuItem value="quarterly">Quarterly</MenuItem>
                  <MenuItem value="half-yearly">Half-Yearly</MenuItem>
                  <MenuItem value="yearly">Yearly</MenuItem>
                </TextField>
              </>
            )}
            <TextField
              fullWidth
              label="Notes"
              value={actionNotes}
              onChange={(e) => setActionNotes(e.target.value)}
              multiline
              minRows={2}
            />
            <Alert severity="warning">This operation will be audited in support activity logs.</Alert>
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setActionOpen(false)}>Cancel</Button>
          <Button variant="contained" onClick={() => submitAction()} disabled={actionLoading || !actionRow}>
            {actionLoading ? 'Processing...' : 'Confirm'}
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default MobileAdminLicensesPage;
