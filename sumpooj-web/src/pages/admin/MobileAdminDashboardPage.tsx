import React, { useCallback, useEffect, useMemo, useState } from 'react';
import {
  Alert,
  Box,
  Button,
  Card,
  CardContent,
  CircularProgress,
  Grid,
  MenuItem,
  Stack,
  TextField,
  Typography,
} from '@mui/material';
import { useNavigate } from 'react-router-dom';
import { getCompanies } from '../../api/company.api';
import { getMobileAdminDashboard, type MobileAdminDashboardMetrics } from '../../api/mobile-admin.api';
import MobileAdminGlobalSearchBar from './components/MobileAdminGlobalSearchBar';

interface CompanyOption {
  id: string;
  name: string;
}

const EMPTY_METRICS: MobileAdminDashboardMetrics = {
  activeUsers: 0,
  trialUsers: 0,
  activeSubscriptions: 0,
  renewalsDue: 0,
  revenue: 0,
  onlineDevices: 0,
};

const MetricCard: React.FC<{ label: string; value: string | number; color?: string }> = ({
  label,
  value,
  color,
}) => {
  return (
    <Card>
      <CardContent>
        <Typography variant="body2" color="text.secondary">
          {label}
        </Typography>
        <Typography variant="h4" fontWeight={700} color={color ?? 'text.primary'}>
          {value}
        </Typography>
      </CardContent>
    </Card>
  );
};

const MobileAdminDashboardPage: React.FC = () => {
  const navigate = useNavigate();
  const [companies, setCompanies] = useState<CompanyOption[]>([]);
  const [companyId, setCompanyId] = useState<string>('');
  const [metrics, setMetrics] = useState<MobileAdminDashboardMetrics>(EMPTY_METRICS);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string>('');

  const loadCompanies = useCallback(async () => {
    const rows = await getCompanies();
    const mapped = (rows ?? []).map((row: any) => ({ id: String(row.id), name: String(row.name ?? row.id) }));
    setCompanies(mapped);
  }, []);

  const loadMetrics = useCallback(async (selectedCompanyId?: string) => {
    setLoading(true);
    setError('');
    try {
      const data = await getMobileAdminDashboard(selectedCompanyId || undefined);
      setMetrics(data);
    } catch (err: any) {
      setError(err?.response?.data?.message || 'Unable to load mobile administration metrics.');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    loadCompanies().catch(() => {
      setError('Unable to load companies.');
    });
    loadMetrics().catch(() => {
      setError('Unable to load dashboard metrics.');
    });
  }, [loadCompanies, loadMetrics]);

  const revenueLabel = useMemo(() => {
    return new Intl.NumberFormat('en-IN', {
      style: 'currency',
      currency: 'INR',
      maximumFractionDigits: 0,
    }).format(metrics.revenue ?? 0);
  }, [metrics.revenue]);

  return (
    <Box sx={{ p: 3 }}>
      <Stack direction={{ xs: 'column', md: 'row' }} spacing={2} alignItems={{ xs: 'stretch', md: 'center' }} justifyContent="space-between" sx={{ mb: 3 }}>
        <Box>
          <Typography variant="h5" fontWeight={700}>
            ERP Mobile Administration Dashboard
          </Typography>
          <Typography variant="body2" color="text.secondary">
            Support operations view for mobile licensing, devices, subscriptions, and recovery actions.
          </Typography>
        </Box>
        <Stack direction="row" spacing={1}>
          <Button variant="outlined" onClick={() => navigate('/admin/dashboard')}>
            Back
          </Button>
          <Button variant="contained" onClick={() => navigate('/admin/mobile/customers')}>
            Mobile Customers
          </Button>
          <Button variant="outlined" onClick={() => navigate('/admin/mobile/devices')}>
            Devices
          </Button>
          <Button variant="outlined" onClick={() => navigate('/admin/mobile/licenses')}>
            Licenses
          </Button>
          <Button variant="outlined" onClick={() => navigate('/admin/mobile/support-activity')}>
            Support Activity
          </Button>
        </Stack>
      </Stack>

      <Card sx={{ mb: 2 }}>
        <CardContent>
          <MobileAdminGlobalSearchBar companyId={companyId || undefined} />
        </CardContent>
      </Card>

      <Card sx={{ mb: 3 }}>
        <CardContent>
          <Stack direction={{ xs: 'column', md: 'row' }} spacing={2} alignItems={{ xs: 'stretch', md: 'center' }}>
            <TextField
              select
              label="Company Filter"
              size="small"
              value={companyId}
              onChange={(e) => {
                const value = e.target.value;
                setCompanyId(value);
                loadMetrics(value || undefined).catch(() => {
                  setError('Unable to refresh dashboard metrics.');
                });
              }}
              sx={{ minWidth: 260 }}
            >
              <MenuItem value="">All Companies</MenuItem>
              {companies.map((company) => (
                <MenuItem key={company.id} value={company.id}>
                  {company.name}
                </MenuItem>
              ))}
            </TextField>
            <Button
              variant="outlined"
              onClick={() => {
                loadMetrics(companyId || undefined).catch(() => {
                  setError('Unable to refresh dashboard metrics.');
                });
              }}
            >
              Refresh
            </Button>
            <Typography variant="caption" color="text.secondary">
              Online devices are counted by heartbeat activity in the last 24 hours.
            </Typography>
          </Stack>
        </CardContent>
      </Card>

      {error && (
        <Alert severity="error" sx={{ mb: 2 }}>
          {error}
        </Alert>
      )}

      {loading ? (
        <Box sx={{ display: 'flex', justifyContent: 'center', py: 6 }}>
          <CircularProgress />
        </Box>
      ) : (
        <Grid container spacing={2}>
          <Grid size={{ xs: 12, sm: 6, md: 4 }}>
            <MetricCard label="Active Users" value={metrics.activeUsers} color="success.main" />
          </Grid>
          <Grid size={{ xs: 12, sm: 6, md: 4 }}>
            <MetricCard label="Trial Users" value={metrics.trialUsers} color="warning.main" />
          </Grid>
          <Grid size={{ xs: 12, sm: 6, md: 4 }}>
            <MetricCard label="Active Subscriptions" value={metrics.activeSubscriptions} color="primary.main" />
          </Grid>
          <Grid size={{ xs: 12, sm: 6, md: 4 }}>
            <MetricCard label="Renewals Due (30 days)" value={metrics.renewalsDue} color="error.main" />
          </Grid>
          <Grid size={{ xs: 12, sm: 6, md: 4 }}>
            <MetricCard label="Revenue Collected" value={revenueLabel} color="secondary.main" />
          </Grid>
          <Grid size={{ xs: 12, sm: 6, md: 4 }}>
            <MetricCard label="Online Devices" value={metrics.onlineDevices} />
          </Grid>
          <Grid size={{ xs: 12, sm: 6, md: 4 }}>
            <Card>
              <CardContent>
                <Typography variant="body2" color="text.secondary">Trial Expiring Today</Typography>
                <Typography variant="h4" fontWeight={700} color="warning.main">{metrics.trialExpiringToday}</Typography>
                <Button size="small" sx={{ mt: 1 }} onClick={() => navigate('/admin/mobile/customers?subscriptionStatus=Trial')}>
                  Open List
                </Button>
              </CardContent>
            </Card>
          </Grid>
          <Grid size={{ xs: 12, sm: 6, md: 4 }}>
            <Card>
              <CardContent>
                <Typography variant="body2" color="text.secondary">Renewals Due Today</Typography>
                <Typography variant="h4" fontWeight={700} color="error.main">{metrics.renewalsDueToday}</Typography>
                <Button size="small" sx={{ mt: 1 }} onClick={() => navigate('/admin/mobile/customers?subscriptionStatus=Active')}>
                  Open List
                </Button>
              </CardContent>
            </Card>
          </Grid>
          <Grid size={{ xs: 12, sm: 6, md: 4 }}>
            <Card>
              <CardContent>
                <Typography variant="body2" color="text.secondary">Devices Offline &gt; 7 Days</Typography>
                <Typography variant="h4" fontWeight={700}>{metrics.devicesOffline7Days}</Typography>
                <Button size="small" sx={{ mt: 1 }} onClick={() => navigate('/admin/mobile/devices?connectionStatus=offline')}>
                  Open Devices
                </Button>
              </CardContent>
            </Card>
          </Grid>
          <Grid size={{ xs: 12, sm: 6, md: 4 }}>
            <Card>
              <CardContent>
                <Typography variant="body2" color="text.secondary">Failed Payments</Typography>
                <Typography variant="h4" fontWeight={700} color="error.main">{metrics.failedPayments}</Typography>
                <Button size="small" sx={{ mt: 1 }} onClick={() => navigate('/admin/mobile/customers')}>
                  Open Customers
                </Button>
              </CardContent>
            </Card>
          </Grid>
          <Grid size={{ xs: 12, sm: 6, md: 4 }}>
            <Card>
              <CardContent>
                <Typography variant="body2" color="text.secondary">Recently Suspended Accounts</Typography>
                <Typography variant="h4" fontWeight={700} color="warning.main">{metrics.recentlySuspendedAccounts}</Typography>
                <Button size="small" sx={{ mt: 1 }} onClick={() => navigate('/admin/mobile/customers?userStatus=Suspended')}>
                  Open List
                </Button>
              </CardContent>
            </Card>
          </Grid>
          <Grid size={{ xs: 12, sm: 6, md: 4 }}>
            <Card>
              <CardContent>
                <Typography variant="body2" color="text.secondary">New Customers (Last 7 Days)</Typography>
                <Typography variant="h4" fontWeight={700} color="success.main">{metrics.newCustomersLast7Days}</Typography>
                <Button size="small" sx={{ mt: 1 }} onClick={() => navigate('/admin/mobile/customers')}>
                  Open Customers
                </Button>
              </CardContent>
            </Card>
          </Grid>
        </Grid>
      )}
    </Box>
  );
};

export default MobileAdminDashboardPage;