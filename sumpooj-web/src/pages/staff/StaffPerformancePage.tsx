/**
 * StaffPerformancePage.tsx — Staff Performance Detail Page
 *
 * Features:
 * - Staff header with info
 * - Date range selector
 * - Performance metrics cards (Sales, Events, Production, Deliveries)
 * - Commission calculation display
 * - Role-based metric visibility
 */
import React, { useState, useMemo, useEffect } from 'react';
import {
  Box,
  Typography,
  Breadcrumbs,
  Link,
  Button,
  useTheme,
  alpha,
  Card,
  Grid,
  Avatar,
  Chip,
  TextField,
  MenuItem,
  Select,
  FormControl,
  InputLabel,
  LinearProgress,
  Divider,
  CircularProgress,
} from '@mui/material';
import {
  NavigateNext as NavIcon,
  ArrowBack as BackIcon,
  Warning as WarningIcon,
  TrendingUp as TrendingUpIcon,
  ShoppingCart as OrderIcon,
  ShoppingCart,
  Celebration as EventIcon,
  LocalFlorist as ProductionIcon,
  LocalShipping as DeliveryIcon,
  AttachMoney as MoneyIcon,
  Edit as EditIcon,
  CalendarToday as CalendarIcon,
  Receipt as ReceiptIcon,
  Discount as DiscountIcon,
  Schedule as ScheduleIcon,
  Assignment as AssignmentIcon,
  CheckCircle as CheckIcon,
  Speed as SpeedIcon,
  Place as PlaceIcon,
} from '@mui/icons-material';
import { useNavigate, useParams, Link as RouterLink } from 'react-router-dom';
import type { DateRangePreset, StaffPerformance, Staff } from './StaffTypes';
import {
  STAFF_ROLE_CONFIG,
  DATE_RANGE_PRESETS,
  getDateRangeFromPreset,
  normalizeRole,
} from './StaffTypes';
import { getStaffById } from '../../api/staff.api';
import { useApiCall } from '../../hooks/useApiCall';

// TODO: Replace with real API endpoint when staff performance API is available
const getStaffPerformance = async (
  _staffId: string,
  _periodStart: string,
  _periodEnd: string,
): Promise<StaffPerformance | null> => {
  return null;
};

// ─── Currency Formatter (tenant-aware) ───────────────────────

import { formatCurrency, formatPercent } from '../../core/i18n';

const fmtCurrency = (value: number) => formatCurrency(value);
const fmtPercent = (value: number) => formatPercent(value);

// ─── Metric Card Component ──────────────────────────────────

interface MetricCardProps {
  label: string;
  value: string | number;
  color: string;
  icon?: React.ReactNode;
  sublabel?: string;
}

const MetricCard: React.FC<MetricCardProps> = ({ label, value, color, icon, sublabel }) => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';

  return (
    <Card
      sx={{
        p: 2,
        bgcolor: dk ? alpha(color, 0.08) : alpha(color, 0.05),
        border: `1px solid ${alpha(color, 0.15)}`,
        borderRadius: 2,
        height: '100%',
      }}
    >
      <Box sx={{ display: 'flex', alignItems: 'flex-start', gap: 1.5 }}>
        {icon && (
          <Box
            sx={{
              p: 1,
              borderRadius: 1.5,
              bgcolor: alpha(color, 0.15),
              color,
              display: 'flex',
            }}
          >
            {icon}
          </Box>
        )}
        <Box sx={{ flex: 1 }}>
          <Typography
            variant="caption"
            sx={{ color: dk ? 'rgba(255,255,255,0.5)' : 'text.secondary', fontWeight: 500 }}
          >
            {label}
          </Typography>
          <Typography variant="h5" sx={{ fontWeight: 700, color, mt: 0.25 }}>
            {value}
          </Typography>
          {sublabel && (
            <Typography
              variant="caption"
              sx={{ color: dk ? 'rgba(255,255,255,0.4)' : 'text.disabled', display: 'block', mt: 0.25 }}
            >
              {sublabel}
            </Typography>
          )}
        </Box>
      </Box>
    </Card>
  );
};

// ─── Section Card Component ─────────────────────────────────

interface SectionCardProps {
  title: string;
  icon: React.ReactNode;
  color: string;
  children: React.ReactNode;
}

const SectionCard: React.FC<SectionCardProps> = ({ title, icon, color, children }) => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';

  return (
    <Card
      sx={{
        bgcolor: dk ? '#1a1a2e' : '#fff',
        border: `1px solid ${dk ? 'rgba(255,255,255,0.06)' : '#e0e0e0'}`,
        borderRadius: 2,
        overflow: 'hidden',
      }}
    >
      <Box
        sx={{
          p: 2,
          bgcolor: dk ? 'rgba(255,255,255,0.02)' : '#fafafa',
          borderBottom: `1px solid ${dk ? 'rgba(255,255,255,0.06)' : '#e0e0e0'}`,
          display: 'flex',
          alignItems: 'center',
          gap: 1.5,
        }}
      >
        <Box sx={{ color }}>{icon}</Box>
        <Typography variant="subtitle1" sx={{ fontWeight: 700 }}>
          {title}
        </Typography>
      </Box>
      <Box sx={{ p: 2 }}>{children}</Box>
    </Card>
  );
};

// ─── Progress Bar Component ─────────────────────────────────

interface ProgressMetricProps {
  label: string;
  value: number;
  total: number;
  color: string;
}

const ProgressMetric: React.FC<ProgressMetricProps> = ({ label, value, total, color }) => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';
  const percent = total > 0 ? (value / total) * 100 : 0;

  return (
    <Box sx={{ mb: 2 }}>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 0.5 }}>
        <Typography variant="body2" sx={{ color: dk ? 'rgba(255,255,255,0.7)' : 'text.secondary' }}>
          {label}
        </Typography>
        <Typography variant="body2" sx={{ fontWeight: 600 }}>
          {value} / {total}
        </Typography>
      </Box>
      <LinearProgress
        variant="determinate"
        value={percent}
        sx={{
          height: 8,
          borderRadius: 4,
          bgcolor: alpha(color, 0.1),
          '& .MuiLinearProgress-bar': {
            bgcolor: color,
            borderRadius: 4,
          },
        }}
      />
    </Box>
  );
};

// ─── Main Component ─────────────────────────────────────────

const StaffPerformancePage: React.FC = () => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';
  const navigate = useNavigate();
  const { staffId } = useParams<{ staffId: string }>();
  const { execute, loading: apiLoading } = useApiCall();

  // Staff & performance state
  const [staff, setStaff] = useState<Staff | null>(null);
  const [performance, setPerformance] = useState<StaffPerformance | null>(null);
  const [staffLoaded, setStaffLoaded] = useState(false);

  // Date range state
  const [datePreset, setDatePreset] = useState<DateRangePreset>('MONTH');
  const [customDateFrom, setCustomDateFrom] = useState('');
  const [customDateTo, setCustomDateTo] = useState('');

  // Calculate date range
  const dateRange = useMemo(() => {
    if (datePreset === 'CUSTOM') {
      return { start: customDateFrom, end: customDateTo };
    }
    return getDateRangeFromPreset(datePreset);
  }, [datePreset, customDateFrom, customDateTo]);

  // Load staff data from API
  useEffect(() => {
    if (!staffId) return;
    const load = async () => {
      const data = await execute(() => getStaffById(staffId), {
        errorMessage: 'Failed to load staff member',
      });
      if (data) {
        setStaff({ ...data, role: normalizeRole(data.role) });
      } else {
        setStaff(null);
      }
      setStaffLoaded(true);
    };
    load();
  }, [staffId, execute]);

  // Load performance data
  useEffect(() => {
    if (!staffId || !dateRange.start || !dateRange.end) {
      setPerformance(null);
      return;
    }
    const load = async () => {
      const data = await getStaffPerformance(staffId, dateRange.start, dateRange.end);
      setPerformance(data);
    };
    load();
  }, [staffId, dateRange]);

  // Role configuration
  const roleConfig = staff ? (STAFF_ROLE_CONFIG[staff.role] ?? STAFF_ROLE_CONFIG.STAFF) : null;

  // Not found
  if (staffLoaded && !staff) {
    return (
      <Box sx={{ p: { xs: 2, md: 3 }, textAlign: 'center', maxWidth: 450, mx: 'auto', mt: 8 }}>
        <WarningIcon sx={{ fontSize: 64, color: '#f44336', opacity: 0.5, mb: 2 }} />
        <Typography variant="h5" sx={{ fontWeight: 700, mb: 1 }}>
          Staff Not Found
        </Typography>
        <Typography
          variant="body2"
          sx={{ color: dk ? 'rgba(255,255,255,0.5)' : 'text.secondary', mb: 3 }}
        >
          The staff member you're looking for doesn't exist or has been removed.
        </Typography>
        <Button
          variant="contained"
          startIcon={<BackIcon />}
          onClick={() => navigate('/staff')}
          sx={{
            bgcolor: '#7c4dff',
            color: '#fff',
            fontWeight: 600,
            '&:hover': { bgcolor: '#651fff' },
          }}
        >
          Back to Staff
        </Button>
      </Box>
    );
  }

  if (!staff) {
    return (
      <Box sx={{ p: 4, textAlign: 'center' }}>
        <CircularProgress />
      </Box>
    );
  }

  return (
    <Box sx={{ p: { xs: 2, md: 3 }, maxWidth: 1400, mx: 'auto' }}>
      {/* Breadcrumbs */}
      <Breadcrumbs separator={<NavIcon sx={{ fontSize: 16 }} />} sx={{ mb: 2 }}>
        <Link
          component={RouterLink}
          to="/staff"
          sx={{ color: dk ? 'rgba(255,255,255,0.7)' : 'text.secondary', textDecoration: 'none' }}
        >
          Staff
        </Link>
        <Typography sx={{ color: dk ? '#fff' : 'text.primary', fontWeight: 600 }}>
          {staff.name}
        </Typography>
      </Breadcrumbs>

      {/* Staff Header Card */}
      <Card
        sx={{
          mb: 3,
          p: 3,
          bgcolor: dk ? '#1a1a2e' : '#fff',
          border: `1px solid ${dk ? 'rgba(255,255,255,0.06)' : '#e0e0e0'}`,
          borderRadius: 2,
        }}
      >
        <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 3, alignItems: 'flex-start' }}>
          {/* Avatar & Info */}
          <Box sx={{ display: 'flex', gap: 2, alignItems: 'center', flex: '1 1 300px' }}>
            <Avatar
              sx={{
                width: 72,
                height: 72,
                bgcolor: alpha(roleConfig?.color || '#7c4dff', 0.2),
                color: roleConfig?.color || '#7c4dff',
                fontWeight: 800,
                fontSize: '1.5rem',
              }}
            >
              {staff.name.split(' ').map((n) => n[0]).join('').slice(0, 2)}
            </Avatar>
            <Box>
              <Typography variant="h5" sx={{ fontWeight: 800 }}>
                {staff.name}
              </Typography>
              <Chip
                label={`${roleConfig?.icon} ${roleConfig?.label}`}
                size="small"
                sx={{
                  mt: 0.5,
                  bgcolor: alpha(roleConfig?.color || '#7c4dff', 0.15),
                  color: roleConfig?.color || '#7c4dff',
                  fontWeight: 600,
                  border: `1px solid ${alpha(roleConfig?.color || '#7c4dff', 0.3)}`,
                }}
              />
              {!staff.isActive && (
                <Chip
                  label="Inactive"
                  size="small"
                  sx={{ ml: 1, bgcolor: alpha('#f44336', 0.1), color: '#f44336' }}
                />
              )}
            </Box>
          </Box>

          {/* Contact Info */}
          <Box sx={{ flex: '1 1 200px' }}>
            <Typography variant="caption" sx={{ color: dk ? 'rgba(255,255,255,0.5)' : 'text.secondary' }}>
              Contact
            </Typography>
            <Typography variant="body2" sx={{ fontWeight: 500 }}>
              {staff.email || '-'}
            </Typography>
            <Typography variant="body2" sx={{ color: dk ? 'rgba(255,255,255,0.7)' : 'text.secondary' }}>
              {staff.phone || '-'}
            </Typography>
          </Box>

          {/* Commission Info */}
          <Box sx={{ flex: '1 1 150px' }}>
            <Typography variant="caption" sx={{ color: dk ? 'rgba(255,255,255,0.5)' : 'text.secondary' }}>
              Commission
            </Typography>
            {staff.commissionType ? (
              <>
                <Typography variant="body2" sx={{ fontWeight: 600 }}>
                  {staff.commissionRate}% of {staff.commissionType.toLowerCase()}
                </Typography>
                {staff.hourlyRate && (
                  <Typography variant="caption" sx={{ color: dk ? 'rgba(255,255,255,0.5)' : 'text.secondary' }}>
                    + {fmtCurrency(staff.hourlyRate)}/hr
                  </Typography>
                )}
              </>
            ) : staff.hourlyRate ? (
              <Typography variant="body2" sx={{ fontWeight: 600 }}>
                {fmtCurrency(staff.hourlyRate)}/hr
              </Typography>
            ) : (
              <Typography variant="body2" sx={{ color: 'text.secondary' }}>N/A</Typography>
            )}
          </Box>

          {/* Edit Button */}
          <Box>
            <Button
              variant="outlined"
              startIcon={<EditIcon />}
              onClick={() => navigate(`/staff/${staffId}/edit`)}
              sx={{
                borderColor: '#7c4dff',
                color: '#7c4dff',
                '&:hover': { borderColor: '#651fff', bgcolor: alpha('#7c4dff', 0.05) },
              }}
            >
              Edit
            </Button>
          </Box>
        </Box>
      </Card>

      {/* Date Range Selector */}
      <Card
        sx={{
          mb: 3,
          p: 2,
          bgcolor: dk ? '#1a1a2e' : '#fff',
          border: `1px solid ${dk ? 'rgba(255,255,255,0.06)' : '#e0e0e0'}`,
          borderRadius: 2,
        }}
      >
        <Box sx={{ display: 'flex', gap: 2, flexWrap: 'wrap', alignItems: 'center' }}>
          <CalendarIcon sx={{ color: '#7c4dff' }} />
          <FormControl size="small" sx={{ minWidth: 180 }}>
            <InputLabel>Period</InputLabel>
            <Select
              value={datePreset}
              label="Period"
              onChange={(e) => setDatePreset(e.target.value as DateRangePreset)}
            >
              {DATE_RANGE_PRESETS.map((p) => (
                <MenuItem key={p.value} value={p.value}>
                  {p.label}
                </MenuItem>
              ))}
            </Select>
          </FormControl>

          {datePreset === 'CUSTOM' && (
            <>
              <TextField
                type="date"
                label="From"
                value={customDateFrom}
                onChange={(e) => setCustomDateFrom(e.target.value)}
                size="small"
                InputLabelProps={{ shrink: true }}
                sx={{ width: 160 }}
              />
              <TextField
                type="date"
                label="To"
                value={customDateTo}
                onChange={(e) => setCustomDateTo(e.target.value)}
                size="small"
                InputLabelProps={{ shrink: true }}
                sx={{ width: 160 }}
              />
            </>
          )}

          <Typography variant="body2" sx={{ color: dk ? 'rgba(255,255,255,0.5)' : 'text.secondary', ml: 'auto' }}>
            {dateRange.start && dateRange.end && (
              <>
                {new Date(dateRange.start).toLocaleDateString('en-IN', { day: 'numeric', month: 'short' })}
                {' — '}
                {new Date(dateRange.end).toLocaleDateString('en-IN', { day: 'numeric', month: 'short', year: 'numeric' })}
              </>
            )}
          </Typography>
        </Box>
      </Card>

      {/* Performance Sections */}
      {performance && (
        <Grid container spacing={3}>
          {/* Sales Metrics (if role tracks sales) */}
          {roleConfig?.tracksSales && (
            <Grid size={{ xs: 12 }}>
              <SectionCard title="Sales Performance" icon={<OrderIcon />} color="#2196f3">
                <Grid container spacing={2}>
                  <Grid size={{ xs: 6, sm: 4, md: 2 }}>
                    <MetricCard
                      label="Total Orders"
                      value={performance.sales.totalOrders}
                      color="#2196f3"
                      icon={<ReceiptIcon fontSize="small" />}
                    />
                  </Grid>
                  <Grid size={{ xs: 6, sm: 4, md: 2 }}>
                    <MetricCard
                      label="Total Revenue"
                      value={fmtCurrency(performance.sales.totalRevenue)}
                      color="#4caf50"
                      icon={<TrendingUpIcon fontSize="small" />}
                    />
                  </Grid>
                  <Grid size={{ xs: 6, sm: 4, md: 2 }}>
                    <MetricCard
                      label="Gross Profit"
                      value={fmtCurrency(performance.sales.grossProfit)}
                      color="#8bc34a"
                      icon={<MoneyIcon fontSize="small" />}
                    />
                  </Grid>
                  <Grid size={{ xs: 6, sm: 4, md: 2 }}>
                    <MetricCard
                      label="Avg Order Value"
                      value={fmtCurrency(performance.sales.averageOrderValue)}
                      color="#ff9800"
                      icon={<ShoppingCart fontSize="small" />}
                    />
                  </Grid>
                  <Grid size={{ xs: 6, sm: 4, md: 2 }}>
                    <MetricCard
                      label="Margin %"
                      value={fmtPercent(performance.sales.marginPercent)}
                      color="#9c27b0"
                      icon={<TrendingUpIcon fontSize="small" />}
                    />
                  </Grid>
                  <Grid size={{ xs: 6, sm: 4, md: 2 }}>
                    <MetricCard
                      label="Discounts Given"
                      value={fmtCurrency(performance.sales.totalDiscountsGiven)}
                      color="#f44336"
                      icon={<DiscountIcon fontSize="small" />}
                    />
                  </Grid>
                </Grid>

                {/* Sales Channel Breakdown */}
                <Divider sx={{ my: 2 }} />
                <Typography variant="subtitle2" sx={{ mb: 1.5, fontWeight: 600 }}>
                  Sales by Channel
                </Typography>
                <Grid container spacing={2}>
                  <Grid size={{ xs: 4 }}>
                    <Box sx={{ textAlign: 'center' }}>
                      <Typography variant="h6" sx={{ fontWeight: 700, color: '#fdd835' }}>
                        {fmtCurrency(performance.sales.walkInSales || 0)}
                      </Typography>
                      <Typography variant="caption" sx={{ color: 'text.secondary' }}>Walk-in</Typography>
                    </Box>
                  </Grid>
                  <Grid size={{ xs: 4 }}>
                    <Box sx={{ textAlign: 'center' }}>
                      <Typography variant="h6" sx={{ fontWeight: 700, color: '#03a9f4' }}>
                        {fmtCurrency(performance.sales.phoneSales || 0)}
                      </Typography>
                      <Typography variant="caption" sx={{ color: 'text.secondary' }}>Phone</Typography>
                    </Box>
                  </Grid>
                  <Grid size={{ xs: 4 }}>
                    <Box sx={{ textAlign: 'center' }}>
                      <Typography variant="h6" sx={{ fontWeight: 700, color: '#e91e63' }}>
                        {fmtCurrency(performance.sales.onlineSales || 0)}
                      </Typography>
                      <Typography variant="caption" sx={{ color: 'text.secondary' }}>Online</Typography>
                    </Box>
                  </Grid>
                </Grid>
              </SectionCard>
            </Grid>
          )}

          {/* Event Metrics (if role tracks events) */}
          {roleConfig?.tracksEvents && (
            <Grid size={{ xs: 12, md: 6 }}>
              <SectionCard title="Events Performance" icon={<EventIcon />} color="#e91e63">
                <Grid container spacing={2}>
                  <Grid size={{ xs: 6 }}>
                    <MetricCard
                      label="Events Assigned"
                      value={performance.events.eventsAssigned}
                      color="#e91e63"
                      icon={<AssignmentIcon fontSize="small" />}
                    />
                  </Grid>
                  <Grid size={{ xs: 6 }}>
                    <MetricCard
                      label="Events Completed"
                      value={performance.events.eventsCompleted}
                      color="#4caf50"
                      icon={<CheckIcon fontSize="small" />}
                    />
                  </Grid>
                  <Grid size={{ xs: 6 }}>
                    <MetricCard
                      label="Proposals Created"
                      value={performance.events.proposalsCreated}
                      color="#ff9800"
                    />
                  </Grid>
                  <Grid size={{ xs: 6 }}>
                    <MetricCard
                      label="Proposals Approved"
                      value={performance.events.proposalsApproved}
                      color="#8bc34a"
                    />
                  </Grid>
                </Grid>

                <Divider sx={{ my: 2 }} />

                <Grid container spacing={2}>
                  <Grid size={{ xs: 6 }}>
                    <MetricCard
                      label="Event Revenue"
                      value={fmtCurrency(performance.events.eventRevenue)}
                      color="#9c27b0"
                    />
                  </Grid>
                  <Grid size={{ xs: 6 }}>
                    <MetricCard
                      label="Event Profit"
                      value={fmtCurrency(performance.events.eventProfit)}
                      color="#4caf50"
                    />
                  </Grid>
                </Grid>
              </SectionCard>
            </Grid>
          )}

          {/* Production Metrics (if role tracks production) */}
          {roleConfig?.tracksProduction && (
            <Grid size={{ xs: 12, md: 6 }}>
              <SectionCard title="Production Performance" icon={<ProductionIcon />} color="#9c27b0">
                <Grid container spacing={2} sx={{ mb: 2 }}>
                  <Grid size={{ xs: 6 }}>
                    <MetricCard
                      label="Items Assigned"
                      value={performance.production.itemsAssigned}
                      color="#9c27b0"
                      icon={<AssignmentIcon fontSize="small" />}
                    />
                  </Grid>
                  <Grid size={{ xs: 6 }}>
                    <MetricCard
                      label="Items Completed"
                      value={performance.production.itemsCompleted}
                      color="#4caf50"
                      icon={<CheckIcon fontSize="small" />}
                    />
                  </Grid>
                </Grid>

                <ProgressMetric
                  label="Completion Rate"
                  value={performance.production.itemsCompleted}
                  total={performance.production.itemsAssigned}
                  color="#9c27b0"
                />

                <Grid container spacing={2}>
                  <Grid size={{ xs: 6 }}>
                    <MetricCard
                      label="In Progress"
                      value={performance.production.itemsInProgress || 0}
                      color="#ff9800"
                    />
                  </Grid>
                  <Grid size={{ xs: 6 }}>
                    <MetricCard
                      label="Avg Completion"
                      value={`${performance.production.averageCompletionTime?.toFixed(1) || '-'} hrs`}
                      color="#03a9f4"
                      icon={<ScheduleIcon fontSize="small" />}
                    />
                  </Grid>
                </Grid>
              </SectionCard>
            </Grid>
          )}

          {/* Delivery Metrics (if role tracks deliveries) */}
          {roleConfig?.tracksDeliveries && (
            <Grid size={{ xs: 12, md: 6 }}>
              <SectionCard title="Delivery Performance" icon={<DeliveryIcon />} color="#ff9800">
                <Grid container spacing={2} sx={{ mb: 2 }}>
                  <Grid size={{ xs: 6 }}>
                    <MetricCard
                      label="Deliveries Assigned"
                      value={performance.deliveries.deliveriesAssigned}
                      color="#ff9800"
                      icon={<AssignmentIcon fontSize="small" />}
                    />
                  </Grid>
                  <Grid size={{ xs: 6 }}>
                    <MetricCard
                      label="Deliveries Completed"
                      value={performance.deliveries.deliveriesCompleted}
                      color="#4caf50"
                      icon={<CheckIcon fontSize="small" />}
                    />
                  </Grid>
                </Grid>

                <ProgressMetric
                  label="On-Time Rate"
                  value={performance.deliveries.deliveriesOnTime}
                  total={performance.deliveries.deliveriesCompleted}
                  color="#4caf50"
                />

                <Grid container spacing={2}>
                  <Grid size={{ xs: 6 }}>
                    <MetricCard
                      label="On-Time %"
                      value={fmtPercent(performance.deliveries.onTimeRate || 0)}
                      color="#4caf50"
                      icon={<SpeedIcon fontSize="small" />}
                    />
                  </Grid>
                  <Grid size={{ xs: 6 }}>
                    <MetricCard
                      label="Total Distance"
                      value={`${performance.deliveries.totalDistance?.toFixed(0) || '-'} km`}
                      color="#03a9f4"
                      icon={<PlaceIcon fontSize="small" />}
                    />
                  </Grid>
                </Grid>
              </SectionCard>
            </Grid>
          )}

          {/* Commission Summary */}
          {staff.commissionType && (
            <Grid size={{ xs: 12 }}>
              <SectionCard title="Commission Summary" icon={<MoneyIcon />} color="#fdd835">
                <Grid container spacing={3} alignItems="center">
                  <Grid size={{ xs: 12, sm: 4 }}>
                    <Box sx={{ textAlign: 'center', py: 2 }}>
                      <Typography variant="caption" sx={{ color: dk ? 'rgba(255,255,255,0.5)' : 'text.secondary' }}>
                        Commission Base ({staff.commissionType.toLowerCase()})
                      </Typography>
                      <Typography variant="h4" sx={{ fontWeight: 800, color: '#7c4dff', mt: 0.5 }}>
                        {fmtCurrency(performance.commission.commissionBase)}
                      </Typography>
                    </Box>
                  </Grid>
                  <Grid size={{ xs: 12, sm: 4 }}>
                    <Box sx={{ textAlign: 'center', py: 2 }}>
                      <Typography variant="caption" sx={{ color: dk ? 'rgba(255,255,255,0.5)' : 'text.secondary' }}>
                        Commission Rate
                      </Typography>
                      <Typography variant="h4" sx={{ fontWeight: 800, color: '#ff9800', mt: 0.5 }}>
                        {staff.commissionRate}%
                      </Typography>
                    </Box>
                  </Grid>
                  <Grid size={{ xs: 12, sm: 4 }}>
                    <Box
                      sx={{
                        textAlign: 'center',
                        py: 2,
                        bgcolor: alpha('#fdd835', 0.1),
                        borderRadius: 2,
                        border: `2px solid ${alpha('#fdd835', 0.3)}`,
                      }}
                    >
                      <Typography variant="caption" sx={{ color: dk ? 'rgba(255,255,255,0.5)' : 'text.secondary' }}>
                        Commission Earned
                      </Typography>
                      <Typography variant="h3" sx={{ fontWeight: 800, color: '#fdd835', mt: 0.5 }}>
                        {fmtCurrency(performance.commission.commissionEarned)}
                      </Typography>
                    </Box>
                  </Grid>
                </Grid>
              </SectionCard>
            </Grid>
          )}
        </Grid>
      )}

      {/* No performance data */}
      {!performance && (
        <Card
          sx={{
            p: 4,
            textAlign: 'center',
            bgcolor: dk ? '#1a1a2e' : '#fff',
            border: `1px solid ${dk ? 'rgba(255,255,255,0.06)' : '#e0e0e0'}`,
            borderRadius: 2,
          }}
        >
          <Typography variant="body1" sx={{ color: 'text.secondary' }}>
            No performance data available for the selected period.
          </Typography>
        </Card>
      )}
    </Box>
  );
};

export default StaffPerformancePage;
