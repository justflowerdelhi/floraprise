import React, { useCallback, useEffect, useMemo, useState } from 'react';
import {
  Alert,
  Box,
  Button,
  Card,
  CardContent,
  CircularProgress,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  Grid,
  MenuItem,
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
  Chip,
  Divider,
} from '@mui/material';
import { useNavigate, useSearchParams } from 'react-router-dom';
import { getCompanies } from '../../api/company.api';
import {
  getMobileAdminCustomers,
  getMobileAdminPlans,
  renewMobileAdminCustomer,
  resetMobileAdminCustomerDevice,
  suspendMobileAdminCustomer,
  type MobileAdminCustomerListItem,
  type MobileSubscriptionPlanDto,
  upgradeMobileAdminCustomerPlan,
} from '../../api/mobile-admin.api';
import MobileAdminGlobalSearchBar from './components/MobileAdminGlobalSearchBar';

type ActionKind = 'UPGRADE' | 'SUSPEND' | 'RENEW' | 'RESET_DEVICE';

interface CompanyOption {
  id: string;
  name: string;
}

const MobileAdminCustomersPage: React.FC = () => {
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const [companies, setCompanies] = useState<CompanyOption[]>([]);
  const [plans, setPlans] = useState<MobileSubscriptionPlanDto[]>([]);
  const [rows, setRows] = useState<MobileAdminCustomerListItem[]>([]);
  const [totalCount, setTotalCount] = useState<number>(0);

  const [search, setSearch] = useState<string>('');
  const [companyId, setCompanyId] = useState<string>('');
  const [userStatus, setUserStatus] = useState<string>('');
  const [subscriptionStatus, setSubscriptionStatus] = useState<string>('');
  const [page, setPage] = useState<number>(0);
  const [pageSize, setPageSize] = useState<number>(20);

  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string>('');
  const [success, setSuccess] = useState<string>('');

  const [selected, setSelected] = useState<MobileAdminCustomerListItem | null>(null);

  const [actionOpen, setActionOpen] = useState<boolean>(false);
  const [actionKind, setActionKind] = useState<ActionKind>('SUSPEND');
  const [actionLoading, setActionLoading] = useState<boolean>(false);
  const [selectedPlanId, setSelectedPlanId] = useState<string>('');
  const [billingCycle, setBillingCycle] = useState<string>('monthly');
  const [targetDeviceId, setTargetDeviceId] = useState<string>('');

  useEffect(() => {
    const q = searchParams.get('search') ?? '';
    const qsUserStatus = searchParams.get('userStatus') ?? '';
    const qsSubscriptionStatus = searchParams.get('subscriptionStatus') ?? '';
    if (q) setSearch(q);
    if (qsUserStatus) setUserStatus(qsUserStatus);
    if (qsSubscriptionStatus) setSubscriptionStatus(qsSubscriptionStatus);
  }, [searchParams]);

  const fetchBootData = useCallback(async () => {
    const [companyRows, planRows] = await Promise.all([getCompanies(), getMobileAdminPlans()]);
    const mappedCompanies = (companyRows ?? []).map((row: any) => ({
      id: String(row.id),
      name: String(row.name ?? row.id),
    }));
    setCompanies(mappedCompanies);
    setPlans(planRows ?? []);
  }, []);

  const fetchCustomers = useCallback(async () => {
    setLoading(true);
    setError('');
    try {
      const result = await getMobileAdminCustomers({
        search: search || undefined,
        companyId: companyId || undefined,
        userStatus: userStatus || undefined,
        subscriptionStatus: subscriptionStatus || undefined,
        page: page + 1,
        pageSize,
      });
      setRows(result.items ?? []);
      setTotalCount(result.totalCount ?? 0);
    } catch (err: any) {
      setError(err?.response?.data?.message || 'Unable to load mobile customers.');
    } finally {
      setLoading(false);
    }
  }, [search, companyId, userStatus, subscriptionStatus, page, pageSize]);

  useEffect(() => {
    fetchBootData().catch(() => {
      setError('Unable to load reference data.');
    });
  }, [fetchBootData]);

  useEffect(() => {
    fetchCustomers().catch(() => {
      setError('Unable to load mobile customers.');
    });
  }, [fetchCustomers]);

  const selectedPlan = useMemo(
    () => plans.find((plan) => plan.id === selectedPlanId),
    [plans, selectedPlanId],
  );

  const openAction = (kind: ActionKind, row: MobileAdminCustomerListItem) => {
    setSelected(row);
    setActionKind(kind);
    setSelectedPlanId('');
    setBillingCycle('monthly');
    setTargetDeviceId('');
    setActionOpen(true);
  };

  const submitAction = async () => {
    if (!selected) return;
    setActionLoading(true);
    setError('');
    setSuccess('');
    try {
      if (actionKind === 'UPGRADE') {
        if (!selectedPlanId) {
          setError('Please select a target plan.');
          setActionLoading(false);
          return;
        }
        await upgradeMobileAdminCustomerPlan(selected.mobileUserId, {
          companyId: selected.companyId,
          planId: selectedPlanId,
          billingCycle,
        });
        setSuccess('Plan upgraded successfully.');
      }

      if (actionKind === 'SUSPEND') {
        await suspendMobileAdminCustomer(selected.mobileUserId, {
          companyId: selected.companyId,
        });
        setSuccess('Mobile customer suspended successfully.');
      }

      if (actionKind === 'RENEW') {
        await renewMobileAdminCustomer(selected.mobileUserId, {
          companyId: selected.companyId,
          billingCycle,
          autoRenew: true,
        });
        setSuccess('Subscription renewed successfully.');
      }

      if (actionKind === 'RESET_DEVICE') {
        await resetMobileAdminCustomerDevice(selected.mobileUserId, {
          companyId: selected.companyId,
          deviceId: targetDeviceId || undefined,
        });
        setSuccess('Device reset successfully.');
      }

      setActionOpen(false);
      await fetchCustomers();
    } catch (err: any) {
      setError(err?.response?.data?.message || 'Action failed.');
    } finally {
      setActionLoading(false);
    }
  };

  return (
    <Box sx={{ p: 3 }}>
      <Stack direction={{ xs: 'column', md: 'row' }} spacing={2} justifyContent="space-between" alignItems={{ xs: 'stretch', md: 'center' }} sx={{ mb: 3 }}>
        <Box>
          <Typography variant="h5" fontWeight={700}>
            Mobile Customers
          </Typography>
          <Typography variant="body2" color="text.secondary">
            Search, monitor, and administer mobile subscriptions.
          </Typography>
        </Box>
        <Stack direction="row" spacing={1}>
          <Button variant="outlined" onClick={() => navigate('/admin/mobile/dashboard')}>
            Dashboard
          </Button>
          <Button variant="outlined" onClick={() => navigate('/admin/dashboard')}>
            Back
          </Button>
        </Stack>
      </Stack>

      {error && (
        <Alert severity="error" sx={{ mb: 2 }}>
          {error}
        </Alert>
      )}
      {success && (
        <Alert severity="success" sx={{ mb: 2 }}>
          {success}
        </Alert>
      )}

      <Card sx={{ mb: 2 }}>
        <CardContent>
          <MobileAdminGlobalSearchBar companyId={companyId || undefined} />
        </CardContent>
      </Card>

      <Card sx={{ mb: 2 }}>
        <CardContent>
          <Grid container spacing={2}>
            <Grid size={{ xs: 12, md: 4 }}>
              <TextField
                fullWidth
                size="small"
                label="Search"
                placeholder="Name, mobile, email, business"
                value={search}
                onChange={(e) => {
                  setSearch(e.target.value);
                  setPage(0);
                }}
              />
            </Grid>
            <Grid size={{ xs: 12, sm: 6, md: 3 }}>
              <TextField
                select
                fullWidth
                size="small"
                label="Company"
                value={companyId}
                onChange={(e) => {
                  setCompanyId(e.target.value);
                  setPage(0);
                }}
              >
                <MenuItem value="">All Companies</MenuItem>
                {companies.map((company) => (
                  <MenuItem key={company.id} value={company.id}>
                    {company.name}
                  </MenuItem>
                ))}
              </TextField>
            </Grid>
            <Grid size={{ xs: 12, sm: 6, md: 2.5 }}>
              <TextField
                select
                fullWidth
                size="small"
                label="User Status"
                value={userStatus}
                onChange={(e) => {
                  setUserStatus(e.target.value);
                  setPage(0);
                }}
              >
                <MenuItem value="">All</MenuItem>
                <MenuItem value="Active">Active</MenuItem>
                <MenuItem value="Suspended">Suspended</MenuItem>
                <MenuItem value="Disabled">Disabled</MenuItem>
              </TextField>
            </Grid>
            <Grid size={{ xs: 12, sm: 6, md: 2.5 }}>
              <TextField
                select
                fullWidth
                size="small"
                label="Subscription"
                value={subscriptionStatus}
                onChange={(e) => {
                  setSubscriptionStatus(e.target.value);
                  setPage(0);
                }}
              >
                <MenuItem value="">All</MenuItem>
                <MenuItem value="Trial">Trial</MenuItem>
                <MenuItem value="Active">Active</MenuItem>
                <MenuItem value="Grace">Grace</MenuItem>
                <MenuItem value="Suspended">Suspended</MenuItem>
                <MenuItem value="Cancelled">Cancelled</MenuItem>
                <MenuItem value="Expired">Expired</MenuItem>
              </TextField>
            </Grid>
          </Grid>
          <Stack direction="row" spacing={1} sx={{ mt: 2 }}>
            <Button
              variant="contained"
              onClick={() => {
                setPage(0);
                fetchCustomers().catch(() => {
                  setError('Unable to load mobile customers.');
                });
              }}
            >
              Apply Filters
            </Button>
            <Button
              variant="outlined"
              onClick={() => {
                setSearch('');
                setCompanyId('');
                setUserStatus('');
                setSubscriptionStatus('');
                setPage(0);
              }}
            >
              Reset
            </Button>
          </Stack>
        </CardContent>
      </Card>

      <Card>
        <CardContent sx={{ p: 0 }}>
          {loading ? (
            <Box sx={{ display: 'flex', justifyContent: 'center', py: 6 }}>
              <CircularProgress />
            </Box>
          ) : (
            <>
              <TableContainer>
                <Table size="small">
                  <TableHead>
                    <TableRow>
                      <TableCell><strong>Customer</strong></TableCell>
                      <TableCell><strong>Subscription</strong></TableCell>
                      <TableCell><strong>Status</strong></TableCell>
                      <TableCell><strong>Devices</strong></TableCell>
                      <TableCell><strong>Remaining</strong></TableCell>
                      <TableCell align="right"><strong>Actions</strong></TableCell>
                    </TableRow>
                  </TableHead>
                  <TableBody>
                    {rows.map((row) => (
                      <TableRow key={row.mobileUserId} hover>
                        <TableCell>
                          <Typography fontWeight={600}>{row.customerName}</Typography>
                          <Typography variant="caption" color="text.secondary" sx={{ display: 'block' }}>
                            {row.businessName || '—'}
                          </Typography>
                          <Typography variant="caption" color="text.secondary" sx={{ display: 'block' }}>
                            {row.mobile} {row.email ? `• ${row.email}` : ''}
                          </Typography>
                        </TableCell>
                        <TableCell>
                          <Typography variant="body2">{row.planName || row.planCode || '—'}</Typography>
                          <Typography variant="caption" color="text.secondary">
                            {row.subscriptionStatus}
                          </Typography>
                        </TableCell>
                        <TableCell>
                          <Stack direction="row" spacing={1}>
                            <Chip size="small" label={row.userStatus} color={row.userStatus === 'Active' ? 'success' : 'default'} />
                            <Chip size="small" label={row.subscriptionStatus} variant="outlined" />
                          </Stack>
                        </TableCell>
                        <TableCell>
                          <Typography variant="body2">
                            {row.onlineDevices}/{row.totalDevices}
                          </Typography>
                          <Typography variant="caption" color="text.secondary">
                            online/total
                          </Typography>
                        </TableCell>
                        <TableCell>{row.remainingDays} days</TableCell>
                        <TableCell align="right">
                          <Stack direction="row" spacing={1} justifyContent="flex-end" flexWrap="wrap">
                            <Button
                              size="small"
                              onClick={() =>
                                navigate(`/admin/mobile/customers/${row.companyId}/${row.mobileUserId}`)
                              }
                            >
                              View
                            </Button>
                            <Button size="small" onClick={() => openAction('UPGRADE', row)}>
                              Upgrade Plan
                            </Button>
                            <Button size="small" color="warning" onClick={() => openAction('SUSPEND', row)}>
                              Suspend
                            </Button>
                            <Button size="small" color="success" onClick={() => openAction('RENEW', row)}>
                              Renew
                            </Button>
                            <Button size="small" color="error" onClick={() => openAction('RESET_DEVICE', row)}>
                              Reset Device
                            </Button>
                          </Stack>
                        </TableCell>
                      </TableRow>
                    ))}
                    {rows.length === 0 && (
                      <TableRow>
                        <TableCell colSpan={6} align="center">
                          No mobile customers found.
                        </TableCell>
                      </TableRow>
                    )}
                  </TableBody>
                </Table>
              </TableContainer>
              <TablePagination
                component="div"
                count={totalCount}
                page={page}
                onPageChange={(_, nextPage) => setPage(nextPage)}
                rowsPerPage={pageSize}
                onRowsPerPageChange={(e) => {
                  setPageSize(Number(e.target.value));
                  setPage(0);
                }}
                rowsPerPageOptions={[10, 20, 50]}
              />
            </>
          )}
        </CardContent>
      </Card>

      <Dialog open={actionOpen} onClose={() => setActionOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>
          {actionKind === 'UPGRADE' && 'Upgrade Plan'}
          {actionKind === 'SUSPEND' && 'Suspend Customer'}
          {actionKind === 'RENEW' && 'Renew Subscription'}
          {actionKind === 'RESET_DEVICE' && 'Reset Device'}
        </DialogTitle>
        <DialogContent dividers>
          {!selected ? (
            <Alert severity="warning">No customer selected.</Alert>
          ) : (
            <Stack spacing={2}>
              <Typography variant="body2" color="text.secondary">
                Customer: {selected.customerName}
              </Typography>

              {(actionKind === 'UPGRADE' || actionKind === 'RENEW') && (
                <TextField
                  select
                  fullWidth
                  label="Billing Cycle"
                  value={billingCycle}
                  onChange={(e) => setBillingCycle(e.target.value)}
                >
                  <MenuItem value="monthly">Monthly</MenuItem>
                  <MenuItem value="quarterly">Quarterly</MenuItem>
                  <MenuItem value="half-yearly">Half-Yearly</MenuItem>
                  <MenuItem value="yearly">Yearly</MenuItem>
                </TextField>
              )}

              {actionKind === 'UPGRADE' && (
                <>
                  <TextField
                    select
                    fullWidth
                    label="Target Plan"
                    value={selectedPlanId}
                    onChange={(e) => setSelectedPlanId(e.target.value)}
                  >
                    <MenuItem value="">Select Plan</MenuItem>
                    {plans.map((plan) => (
                      <MenuItem key={plan.id} value={plan.id}>
                        {plan.name} ({plan.code})
                      </MenuItem>
                    ))}
                  </TextField>
                  {selectedPlan && (
                    <Alert severity="info">
                      Selected plan: {selectedPlan.name} ({selectedPlan.code})
                    </Alert>
                  )}
                </>
              )}

              {actionKind === 'RESET_DEVICE' && (
                <TextField
                  fullWidth
                  label="Device Id (optional)"
                  value={targetDeviceId}
                  onChange={(e) => setTargetDeviceId(e.target.value)}
                  placeholder="Leave blank to reset most recent device"
                />
              )}

              {actionKind === 'SUSPEND' && (
                <Alert severity="warning">
                  This will suspend user access, subscriptions, and associated devices.
                </Alert>
              )}
            </Stack>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setActionOpen(false)}>Cancel</Button>
          <Button variant="contained" onClick={submitAction} disabled={actionLoading || !selected}>
            {actionLoading ? 'Processing…' : 'Confirm'}
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default MobileAdminCustomersPage;