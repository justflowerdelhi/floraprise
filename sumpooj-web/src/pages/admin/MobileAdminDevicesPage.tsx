import React, { useCallback, useEffect, useState } from 'react';
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
import { useNavigate, useSearchParams } from 'react-router-dom';
import {
  disableMobileAdminDevice,
  forceLogoutMobileAdminDevice,
  getMobileAdminDevices,
  resetMobileAdminDevice,
  type MobileAdminDeviceListItem,
} from '../../api/mobile-admin.api';
import { getCompanies } from '../../api/company.api';
import MobileAdminGlobalSearchBar from './components/MobileAdminGlobalSearchBar';

interface CompanyOption {
  id: string;
  name: string;
}

type DeviceAction = 'FORCE_LOGOUT' | 'RESET' | 'DISABLE';

const formatDateTime = (value?: string | null) => {
  if (!value) return '—';
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return '—';
  return date.toLocaleString('en-IN');
};

const MobileAdminDevicesPage: React.FC = () => {
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const [companies, setCompanies] = useState<CompanyOption[]>([]);
  const [companyId, setCompanyId] = useState('');
  const [search, setSearch] = useState('');
  const [connectionStatus, setConnectionStatus] = useState('');
  const [subscriptionType, setSubscriptionType] = useState('');
  const [appVersion, setAppVersion] = useState('');
  const [platform, setPlatform] = useState('');
  const [rows, setRows] = useState<MobileAdminDeviceListItem[]>([]);
  const [totalCount, setTotalCount] = useState(0);
  const [page, setPage] = useState(0);
  const [pageSize, setPageSize] = useState(20);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  const [actionOpen, setActionOpen] = useState(false);
  const [actionType, setActionType] = useState<DeviceAction>('FORCE_LOGOUT');
  const [actionDevice, setActionDevice] = useState<MobileAdminDeviceListItem | null>(null);
  const [actionNotes, setActionNotes] = useState('');
  const [actionLoading, setActionLoading] = useState(false);

  useEffect(() => {
    const q = searchParams.get('search') ?? '';
    const qsConnectionStatus = searchParams.get('connectionStatus') ?? '';
    const qsSubscriptionType = searchParams.get('subscriptionType') ?? '';
    const qsAppVersion = searchParams.get('appVersion') ?? '';
    const qsPlatform = searchParams.get('platform') ?? '';
    if (q) setSearch(q);
    if (qsConnectionStatus) setConnectionStatus(qsConnectionStatus);
    if (qsSubscriptionType) setSubscriptionType(qsSubscriptionType);
    if (qsAppVersion) setAppVersion(qsAppVersion);
    if (qsPlatform) setPlatform(qsPlatform);
  }, [searchParams]);

  const fetchCompanies = useCallback(async () => {
    const rowsData = await getCompanies();
    setCompanies((rowsData ?? []).map((x: any) => ({ id: String(x.id), name: String(x.name ?? x.id) })));
  }, []);

  const fetchDevices = useCallback(async () => {
    setLoading(true);
    setError('');
    try {
      const result = await getMobileAdminDevices({
        companyId: companyId || undefined,
        search: search || undefined,
        connectionStatus: (connectionStatus as any) || undefined,
        subscriptionType: (subscriptionType as any) || undefined,
        appVersion: appVersion || undefined,
        platform: platform || undefined,
        page: page + 1,
        pageSize,
      });
      setRows(result.items ?? []);
      setTotalCount(result.totalCount ?? 0);
    } catch (err: any) {
      setError(err?.response?.data?.message || 'Unable to load devices.');
    } finally {
      setLoading(false);
    }
  }, [companyId, search, connectionStatus, subscriptionType, appVersion, platform, page, pageSize]);

  useEffect(() => {
    fetchCompanies().catch(() => setError('Unable to load companies.'));
  }, [fetchCompanies]);

  useEffect(() => {
    fetchDevices().catch(() => setError('Unable to load devices.'));
  }, [fetchDevices]);

  const openActionDialog = (type: DeviceAction, row: MobileAdminDeviceListItem) => {
    setActionType(type);
    setActionDevice(row);
    setActionNotes('');
    setActionOpen(true);
  };

  const submitAction = async () => {
    if (!actionDevice) return;
    setActionLoading(true);
    setError('');
    setSuccess('');
    try {
      const payload = { companyId: actionDevice.companyId, notes: actionNotes || undefined };
      if (actionType === 'FORCE_LOGOUT') {
        await forceLogoutMobileAdminDevice(actionDevice.mobileDeviceId, payload);
        setSuccess('Device force logout completed.');
      }
      if (actionType === 'RESET') {
        await resetMobileAdminDevice(actionDevice.mobileDeviceId, payload);
        setSuccess('Device reset completed.');
      }
      if (actionType === 'DISABLE') {
        await disableMobileAdminDevice(actionDevice.mobileDeviceId, payload);
        setSuccess('Device disabled successfully.');
      }
      setActionOpen(false);
      await fetchDevices();
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
          <Typography variant="h5" fontWeight={700}>Devices Console</Typography>
          <Typography variant="body2" color="text.secondary">Diagnose and manage registered devices quickly.</Typography>
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
              <TextField
                fullWidth
                size="small"
                label="Search"
                placeholder="device id, business"
                value={search}
                onChange={(e) => { setSearch(e.target.value); setPage(0); }}
              />
            </Grid>
            <Grid size={{ xs: 12, sm: 6, md: 2 }}>
              <TextField select fullWidth size="small" label="Company" value={companyId} onChange={(e) => { setCompanyId(e.target.value); setPage(0); }}>
                <MenuItem value="">All</MenuItem>
                {companies.map((company) => <MenuItem key={company.id} value={company.id}>{company.name}</MenuItem>)}
              </TextField>
            </Grid>
            <Grid size={{ xs: 12, sm: 6, md: 2 }}>
              <TextField select fullWidth size="small" label="Online/Offline" value={connectionStatus} onChange={(e) => { setConnectionStatus(e.target.value); setPage(0); }}>
                <MenuItem value="">All</MenuItem>
                <MenuItem value="online">Online</MenuItem>
                <MenuItem value="offline">Offline</MenuItem>
              </TextField>
            </Grid>
            <Grid size={{ xs: 12, sm: 6, md: 2 }}>
              <TextField select fullWidth size="small" label="Trial/Paid" value={subscriptionType} onChange={(e) => { setSubscriptionType(e.target.value); setPage(0); }}>
                <MenuItem value="">All</MenuItem>
                <MenuItem value="trial">Trial</MenuItem>
                <MenuItem value="paid">Paid</MenuItem>
              </TextField>
            </Grid>
            <Grid size={{ xs: 12, sm: 6, md: 2 }}>
              <TextField fullWidth size="small" label="App Version" value={appVersion} onChange={(e) => { setAppVersion(e.target.value); setPage(0); }} />
            </Grid>
            <Grid size={{ xs: 12, sm: 6, md: 1 }}>
              <TextField fullWidth size="small" label="Platform" value={platform} onChange={(e) => { setPlatform(e.target.value); setPage(0); }} />
            </Grid>
          </Grid>
          <Stack direction="row" spacing={1} sx={{ mt: 2 }}>
            <Button variant="contained" onClick={() => fetchDevices()}>Apply</Button>
            <Button variant="outlined" onClick={() => {
              setSearch(''); setCompanyId(''); setConnectionStatus(''); setSubscriptionType(''); setAppVersion(''); setPlatform(''); setPage(0);
            }}>Reset</Button>
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
            <Box sx={{ p: 3 }}>
              <Alert severity="info">No devices found for current filters.</Alert>
            </Box>
          ) : (
            <>
              <TableContainer>
                <Table size="small">
                  <TableHead>
                    <TableRow>
                      <TableCell><strong>Device Name</strong></TableCell>
                      <TableCell><strong>Business</strong></TableCell>
                      <TableCell><strong>Platform</strong></TableCell>
                      <TableCell><strong>OS Version</strong></TableCell>
                      <TableCell><strong>App Version</strong></TableCell>
                      <TableCell><strong>Online/Offline</strong></TableCell>
                      <TableCell><strong>Last Seen</strong></TableCell>
                      <TableCell><strong>Registered</strong></TableCell>
                      <TableCell align="right"><strong>Actions</strong></TableCell>
                    </TableRow>
                  </TableHead>
                  <TableBody>
                    {rows.map((row) => (
                      <TableRow key={row.mobileDeviceId} hover>
                        <TableCell>
                          <Typography fontWeight={600}>{row.deviceName}</Typography>
                          <Typography variant="caption" color="text.secondary">{row.deviceId}</Typography>
                        </TableCell>
                        <TableCell>{row.businessName || '—'}</TableCell>
                        <TableCell>{row.platform}</TableCell>
                        <TableCell>{row.osVersion || '—'}</TableCell>
                        <TableCell>{row.appVersion}</TableCell>
                        <TableCell>
                          <Chip size="small" label={row.online ? 'Online' : 'Offline'} color={row.online ? 'success' : 'default'} />
                        </TableCell>
                        <TableCell>{formatDateTime(row.lastSeenAtUtc)}</TableCell>
                        <TableCell>{formatDateTime(row.registeredAtUtc)}</TableCell>
                        <TableCell align="right">
                          <Stack direction="row" spacing={1} justifyContent="flex-end" useFlexGap flexWrap="wrap">
                            <Button size="small" onClick={() => navigate(`/admin/mobile/customers/${row.companyId}/${row.mobileUserId}`)}>View Customer</Button>
                            <Button size="small" onClick={() => openActionDialog('FORCE_LOGOUT', row)}>Force Logout</Button>
                            <Button size="small" color="error" onClick={() => openActionDialog('RESET', row)}>Reset Device</Button>
                            <Button size="small" color="warning" onClick={() => openActionDialog('DISABLE', row)}>Disable</Button>
                            <Button size="small" disabled>Transfer License</Button>
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
          {actionType === 'FORCE_LOGOUT' && 'Confirm Force Logout'}
          {actionType === 'RESET' && 'Confirm Device Reset'}
          {actionType === 'DISABLE' && 'Confirm Disable Device'}
        </DialogTitle>
        <DialogContent dividers>
          <Stack spacing={2}>
            <Typography variant="body2" color="text.secondary">
              {actionDevice?.deviceName} ({actionDevice?.deviceId})
            </Typography>
            <TextField
              fullWidth
              label="Notes"
              value={actionNotes}
              onChange={(e) => setActionNotes(e.target.value)}
              multiline
              minRows={2}
            />
            <Alert severity="warning">This is a support action and will be logged in support activity.</Alert>
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setActionOpen(false)}>Cancel</Button>
          <Button variant="contained" color="warning" onClick={() => submitAction()} disabled={actionLoading || !actionDevice}>
            {actionLoading ? 'Processing...' : 'Confirm'}
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default MobileAdminDevicesPage;
