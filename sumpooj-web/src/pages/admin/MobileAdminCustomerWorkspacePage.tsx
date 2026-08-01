import React, { useCallback, useEffect, useMemo, useState } from 'react';
import {
  Alert,
  Box,
  Button,
  Card,
  CardContent,
  Chip,
  CircularProgress,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  Divider,
  Grid,
  MenuItem,
  Stack,
  Tab,
  Tabs,
  TextField,
  Typography,
} from '@mui/material';
import { useNavigate, useParams } from 'react-router-dom';
import {
  forceLogoutMobileAdminCustomer,
  getMobileAdminCustomerDetails,
  getMobileAdminPlans,
  renewMobileAdminCustomer,
  resetMobileAdminCustomerDevice,
  suspendMobileAdminCustomer,
  type MobileAdminCustomerDetail,
  type MobileAdminTimelineItem,
  type MobileSubscriptionPlanDto,
  upgradeMobileAdminCustomerPlan,
} from '../../api/mobile-admin.api';

type WorkspaceAction = 'UPGRADE' | 'RENEW' | 'SUSPEND' | 'RESET_DEVICE' | 'FORCE_LOGOUT';
type TimelineFilter = 'ALL' | 'AUTHENTICATION' | 'SUBSCRIPTION' | 'PAYMENT' | 'DEVICE' | 'SUPPORT';

const formatDateTime = (value?: string | null) => {
  if (!value) return '—';
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return '—';
  return date.toLocaleString('en-IN');
};

const formatDate = (value?: string | null) => {
  if (!value) return '—';
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return '—';
  return date.toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' });
};

const formatCurrency = (value?: number | null) => {
  if (value == null) return '—';
  return new Intl.NumberFormat('en-IN', {
    style: 'currency',
    currency: 'INR',
    maximumFractionDigits: 0,
  }).format(value);
};

const isToday = (date: Date) => {
  const now = new Date();
  return date.getFullYear() === now.getFullYear()
    && date.getMonth() === now.getMonth()
    && date.getDate() === now.getDate();
};

const isYesterday = (date: Date) => {
  const now = new Date();
  const y = new Date(now.getFullYear(), now.getMonth(), now.getDate() - 1);
  return date.getFullYear() === y.getFullYear()
    && date.getMonth() === y.getMonth()
    && date.getDate() === y.getDate();
};

const dayLabel = (value: string) => {
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return 'Unknown';
  if (isToday(date)) return 'Today';
  if (isYesterday(date)) return 'Yesterday';
  return date.toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' });
};

const relativeTime = (value?: string | null) => {
  if (!value) return '—';
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return '—';
  const ms = Date.now() - date.getTime();
  if (ms < 0) return 'just now';
  const mins = Math.floor(ms / 60000);
  if (mins < 1) return 'just now';
  if (mins < 60) return `${mins} min ago`;
  const hours = Math.floor(mins / 60);
  if (hours < 24) return `${hours} hr ago`;
  const days = Math.floor(hours / 24);
  return `${days} day${days > 1 ? 's' : ''} ago`;
};

const isRecent = (value?: string | null, hours = 24) => {
  if (!value) return false;
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return false;
  return (Date.now() - date.getTime()) <= hours * 60 * 60 * 1000;
};

const tabSx = {
  textTransform: 'none',
  fontWeight: 600,
  minHeight: 42,
};

const MobileAdminCustomerWorkspacePage: React.FC = () => {
  const navigate = useNavigate();
  const { companyId = '', mobileUserId = '' } = useParams();

  const [tab, setTab] = useState<number>(0);
  const [details, setDetails] = useState<MobileAdminCustomerDetail | null>(null);
  const [plans, setPlans] = useState<MobileSubscriptionPlanDto[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string>('');
  const [success, setSuccess] = useState<string>('');

  const [actionOpen, setActionOpen] = useState<boolean>(false);
  const [actionType, setActionType] = useState<WorkspaceAction>('UPGRADE');
  const [actionLoading, setActionLoading] = useState<boolean>(false);
  const [selectedPlanId, setSelectedPlanId] = useState<string>('');
  const [billingCycle, setBillingCycle] = useState<string>('monthly');
  const [deviceId, setDeviceId] = useState<string>('');
  const [timelineFilter, setTimelineFilter] = useState<TimelineFilter>('ALL');

  const selectedPlan = useMemo(
    () => plans.find((plan) => plan.id === selectedPlanId),
    [plans, selectedPlanId],
  );

  const currentPlan = useMemo(() => {
    if (!details) return null;
    return plans.find((plan) => plan.code === details.planCode)
      || plans.find((plan) => plan.name === details.planName)
      || null;
  }, [details, plans]);

  const planPriceAndCycle = useMemo(() => {
    if (!currentPlan) return { label: '—', value: null as number | null };
    const name = `${currentPlan.name} ${currentPlan.code}`.toLowerCase();
    if (name.includes('annual') || name.includes('year')) {
      return { label: 'year', value: currentPlan.annualPrice };
    }
    if (name.includes('life')) {
      return { label: 'lifetime', value: currentPlan.lifetimePrice };
    }
    return { label: 'month', value: currentPlan.monthlyPrice };
  }, [currentPlan]);

  const rawTimeline = useMemo<MobileAdminTimelineItem[]>(() => {
    return [...(details?.activityTimeline ?? [])].sort(
      (a, b) => new Date(b.timestampUtc).getTime() - new Date(a.timestampUtc).getTime(),
    );
  }, [details?.activityTimeline]);

  const classifyTimeline = useCallback((event: MobileAdminTimelineItem): TimelineFilter => {
    const cat = (event.category || '').toLowerCase();
    const text = `${event.title} ${event.description}`.toLowerCase();

    if (cat.includes('payment')) return 'PAYMENT';
    if (cat.includes('subscription')) return 'SUBSCRIPTION';
    if (cat.includes('support') || cat.includes('customer')) return 'SUPPORT';
    if (cat.includes('device')) {
      if (text.includes('login') || text.includes('logout') || text.includes('heartbeat') || text.includes('auth')) {
        return 'AUTHENTICATION';
      }
      return 'DEVICE';
    }

    if (text.includes('payment')) return 'PAYMENT';
    if (text.includes('plan') || text.includes('trial') || text.includes('renew') || text.includes('subscription')) return 'SUBSCRIPTION';
    if (text.includes('login') || text.includes('logout') || text.includes('heartbeat') || text.includes('auth')) return 'AUTHENTICATION';
    if (text.includes('device')) return 'DEVICE';
    return 'SUPPORT';
  }, []);

  const filteredTimeline = useMemo(() => {
    if (timelineFilter === 'ALL') return rawTimeline;
    return rawTimeline.filter((event) => classifyTimeline(event) === timelineFilter);
  }, [rawTimeline, timelineFilter, classifyTimeline]);

  const groupedTimeline = useMemo(() => {
    const groups = new Map<string, MobileAdminTimelineItem[]>();
    filteredTimeline.forEach((event) => {
      const label = dayLabel(event.timestampUtc);
      const existing = groups.get(label) ?? [];
      existing.push(event);
      groups.set(label, existing);
    });
    return Array.from(groups.entries());
  }, [filteredTimeline]);

  const lastSeenAt = useMemo(() => {
    if (!details?.devices?.length) return null;
    const timestamps = details.devices.flatMap((device) => [device.lastHeartbeatAtUtc, device.lastLoginAtUtc])
      .filter((value): value is string => Boolean(value));
    if (timestamps.length === 0) return null;
    return timestamps.sort((a, b) => new Date(b).getTime() - new Date(a).getTime())[0];
  }, [details?.devices]);

  const onlineDeviceCount = useMemo(() => (
    details?.devices?.filter((device) => device.status.toLowerCase() === 'active' && isRecent(device.lastHeartbeatAtUtc, 24)).length ?? 0
  ), [details?.devices]);

  const health = useMemo(() => {
    if (!details) {
      return { label: 'Unknown', color: 'default' as const, positives: [] as string[], warnings: [] as string[] };
    }

    const positives: string[] = [];
    const warnings: string[] = [];

    const subscriptionActive = ['active', 'trial', 'grace'].includes(details.subscriptionStatus.toLowerCase());
    const anyDeviceOnline = onlineDeviceCount > 0;
    const dailyUsage = details.devices.some((device) => isRecent(device.lastHeartbeatAtUtc, 24) || isRecent(device.lastLoginAtUtc, 24));
    const lastSyncToday = details.devices.some((device) => {
      if (!device.lastSyncAtUtc) return false;
      const date = new Date(device.lastSyncAtUtc);
      return !Number.isNaN(date.getTime()) && isToday(date);
    });

    if (subscriptionActive) positives.push('Subscription Active');
    if (anyDeviceOnline) positives.push('Device Online');
    if (dailyUsage) positives.push('Daily Usage');
    if (lastSyncToday) positives.push('Last Sync Today');

    if (details.subscriptionStatus.toLowerCase() === 'trial' && details.remainingDays <= 1) {
      warnings.push(details.remainingDays <= 0 ? 'Trial expired today' : 'Trial expires tomorrow');
    }

    if (lastSeenAt) {
      const daysIdle = Math.floor((Date.now() - new Date(lastSeenAt).getTime()) / (24 * 60 * 60 * 1000));
      if (daysIdle >= 18) {
        warnings.push(`No login for ${daysIdle} days`);
      }
    } else {
      warnings.push('No activity recorded yet');
    }

    if (!anyDeviceOnline) warnings.push('No device online in last 24 hours');
    if (details.remainingDays <= 7 && details.subscriptionStatus.toLowerCase() !== 'trial') {
      warnings.push('Subscription near expiry');
    }

    if (warnings.length > 0) {
      return { label: 'Attention Needed', color: 'warning' as const, positives, warnings };
    }

    if (positives.length >= 4) {
      return { label: 'Excellent', color: 'success' as const, positives, warnings };
    }

    return { label: 'Good', color: 'info' as const, positives, warnings };
  }, [details, onlineDeviceCount, lastSeenAt]);

  const loadPage = useCallback(async () => {
    if (!companyId || !mobileUserId) {
      setError('Missing customer route parameters.');
      setLoading(false);
      return;
    }

    setLoading(true);
    setError('');
    try {
      const [customerDetails, activePlans] = await Promise.all([
        getMobileAdminCustomerDetails(companyId, mobileUserId),
        getMobileAdminPlans(),
      ]);
      setDetails(customerDetails);
      setPlans(activePlans ?? []);
    } catch (err: any) {
      setError(err?.response?.data?.message || 'Unable to load mobile customer workspace.');
    } finally {
      setLoading(false);
    }
  }, [companyId, mobileUserId]);

  useEffect(() => {
    loadPage().catch(() => {
      setError('Unable to load mobile customer workspace.');
      setLoading(false);
    });
  }, [loadPage]);

  const openActionDialog = (action: WorkspaceAction, targetId?: string) => {
    setActionType(action);
    setSelectedPlanId('');
    setBillingCycle('monthly');
    setDeviceId(targetId || '');
    setActionOpen(true);
  };

  const executeAction = async () => {
    if (!details) return;

    setActionLoading(true);
    setError('');
    setSuccess('');

    try {
      if (actionType === 'UPGRADE') {
        if (!selectedPlanId) {
          setError('Please select a target plan.');
          setActionLoading(false);
          return;
        }
        await upgradeMobileAdminCustomerPlan(details.mobileUserId, {
          companyId: details.companyId,
          planId: selectedPlanId,
          billingCycle,
        });
        setSuccess('Plan upgraded successfully.');
      }

      if (actionType === 'RENEW') {
        await renewMobileAdminCustomer(details.mobileUserId, {
          companyId: details.companyId,
          billingCycle,
          autoRenew: true,
        });
        setSuccess('Subscription renewed successfully.');
      }

      if (actionType === 'SUSPEND') {
        await suspendMobileAdminCustomer(details.mobileUserId, {
          companyId: details.companyId,
        });
        setSuccess('Customer suspended successfully.');
      }

      if (actionType === 'RESET_DEVICE') {
        await resetMobileAdminCustomerDevice(details.mobileUserId, {
          companyId: details.companyId,
          deviceId: deviceId || undefined,
        });
        setSuccess('Device reset completed.');
      }

      if (actionType === 'FORCE_LOGOUT') {
        await forceLogoutMobileAdminCustomer(details.mobileUserId, {
          companyId: details.companyId,
          deviceId: deviceId || undefined,
        });
        setSuccess('Force logout completed.');
      }

      setActionOpen(false);
      await loadPage();
    } catch (err: any) {
      setError(err?.response?.data?.message || 'Action failed.');
    } finally {
      setActionLoading(false);
    }
  };

  return (
    <Box sx={{ p: 3 }}>
      <Stack
        direction={{ xs: 'column', md: 'row' }}
        spacing={2}
        alignItems={{ xs: 'stretch', md: 'center' }}
        justifyContent="space-between"
        sx={{ mb: 3 }}
      >
        <Box>
          <Typography variant="h5" fontWeight={700}>
            Mobile Customer Workspace
          </Typography>
          <Typography variant="body2" color="text.secondary">
            Single-page support workspace with details, timeline, and direct actions.
          </Typography>
        </Box>
        <Stack direction="row" spacing={1}>
          <Button variant="outlined" onClick={() => navigate('/admin/mobile/customers')}>
            Back to Grid
          </Button>
          <Button variant="outlined" onClick={() => navigate('/admin/mobile/dashboard')}>
            Dashboard
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

      {loading ? (
        <Box sx={{ display: 'flex', justifyContent: 'center', py: 10 }}>
          <CircularProgress />
        </Box>
      ) : !details ? (
        <Alert severity="warning">Customer not found.</Alert>
      ) : (
        <>
          <Card sx={{ mb: 2 }}>
            <CardContent>
              <Grid container spacing={2}>
                <Grid size={{ xs: 12, md: 8 }}>
                  <Typography variant="h4" fontWeight={800} sx={{ mb: 0.5 }}>
                    {details.businessName || details.customerName}
                  </Typography>
                  <Typography variant="body2" color="text.secondary" sx={{ mb: 1.5 }}>
                    {details.mobile} {details.email ? `• ${details.email}` : ''}
                  </Typography>
                  <Stack direction="row" spacing={1} useFlexGap flexWrap="wrap" alignItems="center" sx={{ mb: 1.25 }}>
                    <Chip
                      label={details.userStatus}
                      color={details.userStatus.toLowerCase() === 'active' ? 'success' : 'default'}
                      sx={{ fontWeight: 700, px: 0.5 }}
                    />
                    <Typography variant="body2" fontWeight={600}>{details.planName || details.planCode || '—'}</Typography>
                    <Typography variant="body2" color="text.secondary">Expires in {details.remainingDays} days</Typography>
                    <Typography variant="body2" color="text.secondary">{details.devices.length} Devices</Typography>
                    <Typography variant="body2" color="text.secondary">Last Seen {relativeTime(lastSeenAt)}</Typography>
                    <Typography variant="body2" color="text.secondary">
                      {details.city || details.state || details.country || 'Location not available'}
                    </Typography>
                  </Stack>
                  <Typography variant="body2" color="text.secondary">
                    Owner: {details.ownerName || details.customerName}
                  </Typography>
                </Grid>
                <Grid size={{ xs: 12, md: 4 }}>
                  <Card variant="outlined" sx={{ height: '100%' }}>
                    <CardContent>
                      <Typography variant="subtitle2" sx={{ mb: 1 }}>Customer Health</Typography>
                      <Chip
                        label={health.label}
                        color={health.color}
                        sx={{ mb: 1.25, fontWeight: 700 }}
                      />
                      <Stack spacing={0.75}>
                        {health.warnings.length > 0 ? health.warnings.map((warning) => (
                          <Typography key={warning} variant="body2" color="warning.main">⚠ {warning}</Typography>
                        )) : health.positives.map((reason) => (
                          <Typography key={reason} variant="body2" color="text.secondary">✓ {reason}</Typography>
                        ))}
                      </Stack>
                    </CardContent>
                  </Card>
                </Grid>
              </Grid>

              <Divider sx={{ my: 2 }} />

              <Stack direction="row" spacing={1} useFlexGap flexWrap="wrap">
                <Button size="small" variant="contained" onClick={() => openActionDialog('UPGRADE')}>Upgrade Plan</Button>
                <Button size="small" variant="contained" color="success" onClick={() => openActionDialog('RENEW')}>Renew</Button>
                <Button size="small" variant="contained" color="warning" onClick={() => openActionDialog('SUSPEND')}>Suspend</Button>
                <Button size="small" variant="outlined" color="error" onClick={() => openActionDialog('RESET_DEVICE')}>Reset Device</Button>
                <Button size="small" variant="outlined" onClick={() => openActionDialog('FORCE_LOGOUT')}>Force Logout</Button>
              </Stack>
            </CardContent>
          </Card>

          <Card>
            <CardContent>
              <Tabs value={tab} onChange={(_, value) => setTab(value)} variant="scrollable" scrollButtons="auto" sx={{ mb: 2 }}>
                <Tab label="Overview" sx={tabSx} />
                <Tab label="Devices" sx={tabSx} />
                <Tab label="Subscription" sx={tabSx} />
                <Tab label="Payments" sx={tabSx} />
                <Tab label="Activity Timeline" sx={tabSx} />
              </Tabs>

              {tab === 0 && (
                <Grid container spacing={2}>
                  <Grid size={{ xs: 12, md: 5 }}>
                    <Card variant="outlined"><CardContent>
                      <Typography variant="subtitle2" sx={{ mb: 1 }}>Customer Snapshot</Typography>
                      <Typography variant="body2">Business: {details.businessName || '—'}</Typography>
                      <Typography variant="body2">Owner: {details.ownerName || details.customerName}</Typography>
                      <Typography variant="body2">Mobile: {details.mobile}</Typography>
                      <Typography variant="body2">Email: {details.email || '—'}</Typography>
                      <Typography variant="body2">Location: {[details.city, details.state, details.country].filter(Boolean).join(', ') || '—'}</Typography>
                    </CardContent></Card>
                  </Grid>
                  <Grid size={{ xs: 12, md: 7 }}>
                    <Card variant="outlined"><CardContent>
                      <Typography variant="subtitle2" sx={{ mb: 1 }}>Support Prioritization</Typography>
                      <Typography variant="body2" sx={{ mb: 0.75 }}>Status: {details.userStatus}</Typography>
                      <Typography variant="body2" sx={{ mb: 0.75 }}>Subscription: {details.subscriptionStatus}</Typography>
                      <Typography variant="body2" sx={{ mb: 0.75 }}>Online Devices: {onlineDeviceCount}/{details.devices.length}</Typography>
                      <Typography variant="body2">Last Seen: {relativeTime(lastSeenAt)}</Typography>
                    </CardContent></Card>
                  </Grid>
                </Grid>
              )}

              {tab === 1 && (
                <Stack spacing={1.25}>
                  {details.devices.length === 0 ? (
                    <Alert severity="info">No devices registered.</Alert>
                  ) : (
                    details.devices.map((device) => (
                      <Card key={`${device.deviceId}-${device.platform}`} variant="outlined">
                        <CardContent>
                          <Grid container spacing={2} alignItems="center">
                            <Grid size={{ xs: 12, md: 8 }}>
                              <Typography fontWeight={700}>{device.deviceId}</Typography>
                              <Typography variant="body2" color="text.secondary" sx={{ mb: 1 }}>
                                {device.platform} • v{device.appVersion}
                              </Typography>
                              <Stack direction="row" spacing={1} useFlexGap flexWrap="wrap" sx={{ mb: 1 }}>
                                <Chip
                                  size="small"
                                  label={device.status}
                                  color={device.status.toLowerCase() === 'active' && isRecent(device.lastHeartbeatAtUtc, 24) ? 'success' : 'default'}
                                />
                                <Chip size="small" label={`Last Seen ${relativeTime(device.lastHeartbeatAtUtc || device.lastLoginAtUtc)}`} variant="outlined" />
                                <Chip size="small" label="Battery Last Report: N/A" variant="outlined" />
                              </Stack>
                              <Typography variant="caption" color="text.secondary" sx={{ display: 'block' }}>
                                Last Login: {formatDateTime(device.lastLoginAtUtc)}
                              </Typography>
                              <Typography variant="caption" color="text.secondary" sx={{ display: 'block' }}>
                                Last Heartbeat: {formatDateTime(device.lastHeartbeatAtUtc)}
                              </Typography>
                              <Typography variant="caption" color="text.secondary" sx={{ display: 'block' }}>
                                Last Sync: {formatDateTime(device.lastSyncAtUtc)}
                              </Typography>
                            </Grid>
                            <Grid size={{ xs: 12, md: 4 }}>
                              <Stack spacing={1}>
                                <Button size="small" variant="outlined" onClick={() => openActionDialog('FORCE_LOGOUT', device.deviceId)}>
                                  Force Logout
                                </Button>
                                <Button size="small" variant="outlined" color="error" onClick={() => openActionDialog('RESET_DEVICE', device.deviceId)}>
                                  Reset
                                </Button>
                              </Stack>
                            </Grid>
                          </Grid>
                        </CardContent>
                      </Card>
                    ))
                  )}
                </Stack>
              )}

              {tab === 2 && (
                <Card variant="outlined">
                  <CardContent>
                    <Typography variant="subtitle2" sx={{ mb: 1.25 }}>Current Plan</Typography>
                    <Typography variant="h6" fontWeight={700}>{details.planName || details.planCode || '—'}</Typography>
                    <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
                      {formatCurrency(planPriceAndCycle.value)}{planPriceAndCycle.value != null ? `/${planPriceAndCycle.label}` : ''}
                    </Typography>

                    <Grid container spacing={1.5} sx={{ mb: 2 }}>
                      <Grid size={{ xs: 12, sm: 6 }}>
                        <Typography variant="caption" color="text.secondary">Expires</Typography>
                        <Typography variant="body2" fontWeight={600}>{formatDate(details.subscriptionEndUtc)}</Typography>
                      </Grid>
                      <Grid size={{ xs: 12, sm: 6 }}>
                        <Typography variant="caption" color="text.secondary">Auto Renewal</Typography>
                        <Typography variant="body2" fontWeight={600}>
                          {details.autoRenew == null ? 'Not Available' : (details.autoRenew ? 'Enabled' : 'Disabled')}
                        </Typography>
                      </Grid>
                      <Grid size={{ xs: 12, sm: 6 }}>
                        <Typography variant="caption" color="text.secondary">Status</Typography>
                        <Typography variant="body2" fontWeight={600}>{details.subscriptionStatus}</Typography>
                      </Grid>
                      <Grid size={{ xs: 12, sm: 6 }}>
                        <Typography variant="caption" color="text.secondary">Remaining</Typography>
                        <Typography variant="body2" fontWeight={600}>{details.remainingDays} Days</Typography>
                      </Grid>
                    </Grid>

                    <Stack direction="row" spacing={1} useFlexGap flexWrap="wrap">
                      <Button size="small" variant="contained" onClick={() => openActionDialog('UPGRADE')}>Upgrade</Button>
                      <Button size="small" variant="contained" color="success" onClick={() => openActionDialog('RENEW')}>Renew</Button>
                      <Button size="small" variant="contained" color="warning" onClick={() => openActionDialog('SUSPEND')}>Suspend</Button>
                    </Stack>
                  </CardContent>
                </Card>
              )}

              {tab === 3 && (
                <Stack spacing={1}>
                  {details.recentPayments.length === 0 ? (
                    <Alert severity="info">No payment history available.</Alert>
                  ) : (
                    details.recentPayments.map((payment) => (
                      <Card key={payment.transactionRef} variant="outlined">
                        <CardContent>
                          <Stack direction={{ xs: 'column', md: 'row' }} justifyContent="space-between" spacing={1}>
                            <Box>
                              <Typography fontWeight={600}>{payment.transactionRef}</Typography>
                              <Typography variant="body2" color="text.secondary">
                                {payment.paymentType} • {payment.paymentStatus}
                              </Typography>
                            </Box>
                            <Box sx={{ textAlign: { xs: 'left', md: 'right' } }}>
                              <Typography fontWeight={600}>{payment.currency} {payment.amount}</Typography>
                              <Typography variant="caption" color="text.secondary" sx={{ display: 'block' }}>
                                Created: {formatDateTime(payment.createdAtUtc)}
                              </Typography>
                              <Typography variant="caption" color="text.secondary" sx={{ display: 'block' }}>
                                Paid: {formatDateTime(payment.paidAtUtc)}
                              </Typography>
                            </Box>
                          </Stack>
                        </CardContent>
                      </Card>
                    ))
                  )}
                </Stack>
              )}

              {tab === 4 && (
                <Stack spacing={2}>
                  <Stack direction="row" spacing={1} useFlexGap flexWrap="wrap">
                    {(['ALL', 'AUTHENTICATION', 'SUBSCRIPTION', 'PAYMENT', 'DEVICE', 'SUPPORT'] as TimelineFilter[]).map((filter) => (
                      <Chip
                        key={filter}
                        label={filter === 'ALL' ? 'All' : filter[0] + filter.slice(1).toLowerCase()}
                        color={timelineFilter === filter ? 'primary' : 'default'}
                        variant={timelineFilter === filter ? 'filled' : 'outlined'}
                        onClick={() => setTimelineFilter(filter)}
                      />
                    ))}
                  </Stack>
                  {groupedTimeline.length === 0 ? (
                    <Alert severity="info">No activity timeline events available for this filter.</Alert>
                  ) : groupedTimeline.map(([group, events]) => (
                    <Box key={group}>
                      <Typography variant="subtitle2" sx={{ mb: 1 }}>{group}</Typography>
                      <Stack spacing={1.1} sx={{ mb: 2 }}>
                        {events.map((event, index) => (
                          <Card key={`${event.timestampUtc}-${event.title}-${index}`} variant="outlined">
                            <CardContent>
                              <Stack direction={{ xs: 'column', md: 'row' }} justifyContent="space-between" spacing={1}>
                                <Box>
                                  <Typography fontWeight={600}>{event.title}</Typography>
                                  <Typography variant="body2" color="text.secondary">{event.description}</Typography>
                                </Box>
                                <Box sx={{ textAlign: { xs: 'left', md: 'right' } }}>
                                  <Chip label={classifyTimeline(event).replace('_', ' ')} size="small" sx={{ mb: 0.5 }} />
                                  <Typography variant="caption" color="text.secondary" sx={{ display: 'block' }}>
                                    {formatDateTime(event.timestampUtc)}
                                  </Typography>
                                </Box>
                              </Stack>
                            </CardContent>
                          </Card>
                        ))}
                      </Stack>
                      <Divider sx={{ my: 1 }} />
                    </Box>
                  ))}
                </Stack>
              )}
            </CardContent>
          </Card>
        </>
      )}

      <Dialog open={actionOpen} onClose={() => setActionOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>
          {actionType === 'UPGRADE' && 'Upgrade Plan'}
          {actionType === 'RENEW' && 'Renew Subscription'}
          {actionType === 'SUSPEND' && 'Suspend Customer'}
          {actionType === 'RESET_DEVICE' && 'Reset Device'}
          {actionType === 'FORCE_LOGOUT' && 'Force Logout'}
        </DialogTitle>
        <DialogContent dividers>
          <Stack spacing={2}>
            {(actionType === 'UPGRADE' || actionType === 'RENEW') && (
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

            {actionType === 'UPGRADE' && (
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

            {(actionType === 'RESET_DEVICE' || actionType === 'FORCE_LOGOUT') && (
              <TextField
                fullWidth
                label="Device Id (optional)"
                value={deviceId}
                onChange={(e) => setDeviceId(e.target.value)}
                placeholder={actionType === 'RESET_DEVICE' ? 'Leave blank to reset most recent device' : 'Leave blank to logout all active sessions'}
              />
            )}

            {(actionType === 'SUSPEND' || actionType === 'FORCE_LOGOUT') && (
              <Alert severity="warning">
                {actionType === 'SUSPEND'
                  ? 'This will suspend access and associated subscription/device usage.'
                  : 'This will terminate active session(s) for this customer.'}
              </Alert>
            )}
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setActionOpen(false)}>Cancel</Button>
          <Button variant="contained" onClick={executeAction} disabled={actionLoading}>
            {actionLoading ? 'Processing…' : 'Confirm'}
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default MobileAdminCustomerWorkspacePage;