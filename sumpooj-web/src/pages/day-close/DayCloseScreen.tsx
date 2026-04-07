// =============================================================================
// DAY CLOSE SCREEN - POS End-of-Day Reconciliation
// =============================================================================

import React, { useState, useEffect, useCallback } from 'react';
import {
  Box,
  Typography,
  Card,
  CardContent,
  Grid,
  TextField,
  Button,
  Divider,
  Chip,
  Alert,
  LinearProgress,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  alpha,
  Paper,
  useTheme,
  InputAdornment,
} from '@mui/material';
import {
  Lock,
  LockOpen,
  CheckCircle,
  Warning,
  Error,
  Help,
  PointOfSale,
  Phone,
  Language,
  CreditCard,
  AccountBalance,
  Smartphone,
  Receipt,
  TrendingUp,
  TrendingDown,
  MoneyOff,
  CalendarToday,
} from '@mui/icons-material';
import type { DayCloseSummary, DayCloseStatus } from '../../core/audit/AuditTypes';
import { useSensitiveAction } from '../../core/audit/SensitiveActionModal';
import { formatCurrency, useCurrency } from '../../core/i18n';
import { getDayCloseSummary, closeDay } from '../../api/day-close.api';
import { useToast } from '../../hooks/useToast';
import { useApiCall } from '../../hooks/useApiCall';
import { useLocation } from '../../core/location';

// -----------------------------------------------------------------------------
// Status Badge
// -----------------------------------------------------------------------------

const STATUS_CONFIG: Record<DayCloseStatus, { color: string; icon: React.ReactNode; label: string }> = {
  OPEN: { color: '#4caf50', icon: <LockOpen />, label: 'Day Open' },
  PENDING_REVIEW: { color: '#ff9800', icon: <Warning />, label: 'Pending Review' },
  CLOSED: { color: '#9e9e9e', icon: <Lock />, label: 'Day Closed' },
  REOPENED: { color: '#2196f3', icon: <LockOpen />, label: 'Reopened' },
};

const formatLocalDate = (date = new Date()) => {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
};

interface DayStatusBadgeProps {
  status?: DayCloseStatus | null;
}

function DayStatusBadge({ status }: DayStatusBadgeProps) {
  // Fallback config if status is undefined or not in STATUS_CONFIG
  const defaultConfig = { color: '#9e9e9e', icon: <Help />, label: 'Unknown Status' };
  const config = status ? STATUS_CONFIG[status] : defaultConfig;
  
  // Use default if config is still undefined
  const safeConfig = config || defaultConfig;
  
  return (
    <Chip
      icon={safeConfig.icon as React.ReactElement}
      label={safeConfig.label}
      sx={{
        bgcolor: alpha(safeConfig.color, 0.15),
        color: safeConfig.color,
        fontWeight: 600,
        '& .MuiChip-icon': { color: safeConfig.color },
      }}
    />
  );
}

// -----------------------------------------------------------------------------
// Stat Card
// -----------------------------------------------------------------------------

interface StatCardProps {
  title: string;
  value: string | number;
  subtitle?: string;
  icon: React.ReactNode;
  color?: string;
  trend?: 'up' | 'down' | 'neutral';
  trendValue?: string;
}

function StatCard({ title, value, subtitle, icon, color = '#fdd835', trend, trendValue }: StatCardProps) {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';
  
  return (
    <Card sx={{ bgcolor: dk ? '#1a1a2e' : '#fff', height: '100%' }}>
      <CardContent>
        <Box sx={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', mb: 2 }}>
          <Box
            sx={{
              width: 44,
              height: 44,
              borderRadius: 2,
              bgcolor: alpha(color, 0.15),
              color: color,
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
            }}
          >
            {icon}
          </Box>
          {trend && trendValue && (
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
              {trend === 'up' ? (
                <TrendingUp sx={{ fontSize: 16, color: '#4caf50' }} />
              ) : trend === 'down' ? (
                <TrendingDown sx={{ fontSize: 16, color: '#f44336' }} />
              ) : null}
              <Typography
                variant="caption"
                sx={{ color: trend === 'up' ? '#4caf50' : trend === 'down' ? '#f44336' : 'text.secondary' }}
              >
                {trendValue}
              </Typography>
            </Box>
          )}
        </Box>
        <Typography variant="h4" fontWeight={700} mb={0.5}>
          {typeof value === 'number' ? formatCurrency(value) : value}
        </Typography>
        <Typography variant="body2" color="text.secondary">
          {title}
        </Typography>
        {subtitle && (
          <Typography variant="caption" color="text.disabled">
            {subtitle}
          </Typography>
        )}
      </CardContent>
    </Card>
  );
}

// -----------------------------------------------------------------------------
// Main Day Close Screen
// -----------------------------------------------------------------------------

export default function DayCloseScreen() {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';
  const { requestConfirmation } = useSensitiveAction();
  const toast = useToast();
  const { execute, loading: apiLoading } = useApiCall();
  const { currentLocationId } = useLocation();
  const { currencySymbol } = useCurrency();
  const [summary, setSummary] = useState<DayCloseSummary | null>(null);
  const [countedCash, setCountedCash] = useState<string>('');
  const [notes, setNotes] = useState<string>('');
  const [isClosing, setIsClosing] = useState(false);

  const loadSummary = useCallback(async () => {
    const data = await execute(
      () => getDayCloseSummary({
        locationId: currentLocationId !== 'ALL' ? currentLocationId : undefined,
        date: formatLocalDate(),
      }),
      { errorMessage: 'Failed to load day close summary' }
    );
    if (data) {
      setSummary(data);
    }
  }, [execute, currentLocationId]);

  useEffect(() => {
    loadSummary();
  }, [loadSummary]);
  
  const cashVariance = countedCash && summary
    ? parseFloat(countedCash) - summary.expectedCash
    : null;
  
  const handleCloseDay = async () => {
    if (!countedCash || !summary) {
      return;
    }

    if (!currentLocationId || currentLocationId === 'ALL') {
      toast.error('Please select a specific location before closing the day.');
      return;
    }
    
    const result = await requestConfirmation('DAY_CLOSE', {
      metadata: {
        date: summary.date,
        total_sales: formatCurrency(summary.totalSales),
        expected_cash: formatCurrency(summary.expectedCash),
        counted_cash: formatCurrency(parseFloat(countedCash)),
        variance: cashVariance ? formatCurrency(cashVariance) : formatCurrency(0),
      },
    });
    
    if (result.confirmed) {
      setIsClosing(true);
      try {
        const data = await execute(
          () => closeDay({
            locationId: currentLocationId,
            businessDate: summary.date,
            actualCash: parseFloat(countedCash),
            notes: notes || null,
          }),
          { successMessage: 'Day closed successfully', errorMessage: 'Failed to close day' }
        );
        if (data) {
          setSummary({
            ...summary,
            status: 'CLOSED',
            countedCash: parseFloat(countedCash),
            cashVariance: cashVariance || 0,
            closedBy: data.closedBy ?? 'Admin User',
            closedAt: data.closedAt ?? new Date().toISOString(),
            notes: notes || undefined,
          });
          toast.success('Day has been closed and reconciled.');
        }
      } catch {
        toast.error('An error occurred while closing the day.');
      } finally {
        setIsClosing(false);
      }
    }
  };
  
  const handleReopenDay = async () => {
    if (!summary) return;
    const result = await requestConfirmation('UNLOCK_CLOSED_DAY', {
      metadata: {
        date: summary.date,
        closed_by: summary.closedBy,
        closed_at: summary.closedAt,
      },
    });
    
    if (result.confirmed) {
      setSummary({
        ...summary,
        status: 'REOPENED',
      });
    }
  };
  
  const formatDate = (dateStr: string) => {
    const date = new Date(dateStr);
    return date.toLocaleDateString('en-IN', {
      weekday: 'long',
      year: 'numeric',
      month: 'long',
      day: 'numeric',
    });
  };
  
  const isDayClosed = summary?.status === 'CLOSED';
  
  if (apiLoading || !summary) {
    return (
      <Box sx={{ p: 3, maxWidth: 1400, mx: 'auto' }}>
        <Typography variant="h4" fontWeight={700} mb={2}>Day Close</Typography>
        <LinearProgress />
      </Box>
    );
  }
  
  return (
    <Box sx={{ p: 3, maxWidth: 1400, mx: 'auto' }}>
      {/* Header */}
      <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', mb: 4 }}>
        <Box>
          <Typography variant="h4" fontWeight={700} mb={0.5}>
            Day Close
          </Typography>
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
              <CalendarToday sx={{ fontSize: 18, color: 'text.secondary' }} />
              <Typography color="text.secondary">
                {formatDate(summary.date)}
              </Typography>
            </Box>
            <DayStatusBadge status={summary.status} />
          </Box>
        </Box>
        
        {isDayClosed && (
          <Button
            variant="outlined"
            color="warning"
            startIcon={<LockOpen />}
            onClick={handleReopenDay}
          >
            Reopen Day
          </Button>
        )}
      </Box>
      
      {/* Closed Day Info */}
      {isDayClosed && summary.closedBy && (
        <Alert
          severity="info"
          icon={<Lock />}
          sx={{ mb: 3, bgcolor: alpha('#2196f3', 0.1), border: 1, borderColor: alpha('#2196f3', 0.3) }}
        >
          <Typography variant="body2">
            Day closed by <strong>{summary.closedBy}</strong> on{' '}
            {summary.closedAt && new Date(summary.closedAt).toLocaleString()}
            {summary.notes && ` • Notes: ${summary.notes}`}
          </Typography>
        </Alert>
      )}
      
      {/* Sales Overview */}
      <Grid container spacing={3} sx={{ mb: 3 }}>
        <Grid size={{ xs: 12, sm: 6, md: 3 }}>
          <StatCard
            title="Total Sales"
            value={summary.totalSales}
            subtitle={`${summary.totalOrders} orders`}
            icon={<Receipt />}
            color="#4caf50"
            trend="up"
            trendValue="+12% vs yesterday"
          />
        </Grid>
        <Grid size={{ xs: 12, sm: 6, md: 3 }}>
          <StatCard
            title="Walk-In Sales"
            value={summary.walkInSales}
            subtitle={`${summary.walkInOrders} orders`}
            icon={<PointOfSale />}
            color="#2196f3"
          />
        </Grid>
        <Grid size={{ xs: 12, sm: 6, md: 3 }}>
          <StatCard
            title="Phone Orders"
            value={summary.phoneOrdersAmount}
            subtitle={`${summary.phoneOrders} orders`}
            icon={<Phone />}
            color="#9c27b0"
          />
        </Grid>
        <Grid size={{ xs: 12, sm: 6, md: 3 }}>
          <StatCard
            title="Online Orders"
            value={summary.onlineOrdersAmount}
            subtitle={`${summary.onlineOrders} orders`}
            icon={<Language />}
            color="#ff9800"
          />
        </Grid>
      </Grid>
      
      <Grid container spacing={3}>
        {/* Payment Breakdown */}
        <Grid size={{ xs: 12, md: 6 }}>
          <Card sx={{ bgcolor: dk ? '#1a1a2e' : '#fff', height: '100%' }}>
            <CardContent sx={{ p: 3 }}>
              <Typography variant="h6" fontWeight={600} mb={3}>
                Payment Breakdown
              </Typography>
              
              <TableContainer>
                <Table size="small">
                  <TableHead>
                    <TableRow>
                      <TableCell>Payment Method</TableCell>
                      <TableCell align="right">Amount</TableCell>
                      <TableCell align="right">%</TableCell>
                    </TableRow>
                  </TableHead>
                  <TableBody>
                    <TableRow>
                      <TableCell>
                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                          <AccountBalance sx={{ fontSize: 18, color: '#4caf50' }} />
                          Cash
                        </Box>
                      </TableCell>
                      <TableCell align="right">{formatCurrency(summary.cashSales)}</TableCell>
                      <TableCell align="right">
                        {safePercent(summary.cashSales, summary.totalSales)}%
                      </TableCell>
                    </TableRow>
                    <TableRow>
                      <TableCell>
                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                          <CreditCard sx={{ fontSize: 18, color: '#2196f3' }} />
                          Card
                        </Box>
                      </TableCell>
                      <TableCell align="right">{formatCurrency(summary.cardSales)}</TableCell>
                      <TableCell align="right">
                        {safePercent(summary.cardSales, summary.totalSales)}%
                      </TableCell>
                    </TableRow>
                    <TableRow>
                      <TableCell>
                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                          <Smartphone sx={{ fontSize: 18, color: '#9c27b0' }} />
                          UPI
                        </Box>
                      </TableCell>
                      <TableCell align="right">{formatCurrency(summary.upiSales)}</TableCell>
                      <TableCell align="right">
                        {safePercent(summary.upiSales, summary.totalSales)}%
                      </TableCell>
                    </TableRow>
                    {summary.otherPayments > 0 && (
                      <TableRow>
                        <TableCell>Other</TableCell>
                        <TableCell align="right">{formatCurrency(summary.otherPayments)}</TableCell>
                        <TableCell align="right">
                          {safePercent(summary.otherPayments, summary.totalSales)}%
                        </TableCell>
                      </TableRow>
                    )}
                  </TableBody>
                </Table>
              </TableContainer>
              
              <Divider sx={{ my: 2 }} />
              
              {/* Refunds */}
              <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                  <MoneyOff sx={{ fontSize: 18, color: '#f44336' }} />
                  <Typography variant="body2">Refunds ({summary.refundCount})</Typography>
                </Box>
                <Typography variant="body2" color="error">
                  -{formatCurrency(summary.totalRefunds)}
                </Typography>
              </Box>
            </CardContent>
          </Card>
        </Grid>
        
        {/* Cash Reconciliation */}
        <Grid size={{ xs: 12, md: 6 }}>
          <Card sx={{ bgcolor: dk ? '#1a1a2e' : '#fff', height: '100%' }}>
            <CardContent sx={{ p: 3 }}>
              <Typography variant="h6" fontWeight={600} mb={3}>
                Cash Reconciliation
              </Typography>
              
              <Box sx={{ mb: 3 }}>
                <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
                  <Typography variant="body2" color="text.secondary">
                    Expected Cash in Drawer
                  </Typography>
                  <Typography variant="h5" fontWeight={700}>
                    {formatCurrency(summary.expectedCash)}
                  </Typography>
                </Box>
                <Typography variant="caption" color="text.disabled">
                  Based on cash sales minus cash refunds
                </Typography>
              </Box>
              
              <Divider sx={{ my: 2 }} />
              
              {isDayClosed ? (
                // Show closed day summary
                <Box>
                  <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 2 }}>
                    <Typography variant="body2" color="text.secondary">
                      Cash Counted
                    </Typography>
                    <Typography variant="h5" fontWeight={700}>
                      {formatCurrency(summary.countedCash ?? 0)}
                    </Typography>
                  </Box>
                  
                  {summary.cashVariance !== undefined && summary.cashVariance !== 0 && (
                    <Alert
                      severity={summary.cashVariance > 0 ? 'success' : 'error'}
                      icon={summary.cashVariance > 0 ? <TrendingUp /> : <TrendingDown />}
                      sx={{
                        bgcolor: alpha(summary.cashVariance > 0 ? '#4caf50' : '#f44336', 0.1),
                        border: 1,
                        borderColor: alpha(summary.cashVariance > 0 ? '#4caf50' : '#f44336', 0.3),
                      }}
                    >
                      Cash {summary.cashVariance > 0 ? 'Over' : 'Short'} by{' '}
                      <strong>{formatCurrency(Math.abs(summary.cashVariance))}</strong>
                    </Alert>
                  )}
                  
                  {summary.cashVariance === 0 && (
                    <Alert
                      severity="success"
                      icon={<CheckCircle />}
                      sx={{
                        bgcolor: alpha('#4caf50', 0.1),
                        border: 1,
                        borderColor: alpha('#4caf50', 0.3),
                      }}
                    >
                      Cash drawer balanced perfectly!
                    </Alert>
                  )}
                </Box>
              ) : (
                // Show input form
                <Box>
                  <TextField
                    fullWidth
                    label="Counted Cash Amount"
                    type="number"
                    value={countedCash}
                    onChange={(e) => setCountedCash(e.target.value)}
                    placeholder="Enter the amount in drawer"
                    InputProps={{
                      startAdornment: <InputAdornment position="start">{currencySymbol}</InputAdornment>,
                    }}
                    sx={{ mb: 2 }}
                  />
                  
                  {cashVariance !== null && (
                    <Alert
                      severity={cashVariance === 0 ? 'success' : cashVariance > 0 ? 'warning' : 'error'}
                      icon={
                        cashVariance === 0 ? <CheckCircle /> :
                        cashVariance > 0 ? <TrendingUp /> : <TrendingDown />
                      }
                      sx={{ mb: 2 }}
                    >
                      {cashVariance === 0 ? (
                        'Cash drawer balanced!'
                      ) : cashVariance > 0 ? (
                        <>Cash <strong>over</strong> by {formatCurrency(cashVariance)}</>
                      ) : (
                        <>Cash <strong>short</strong> by {formatCurrency(Math.abs(cashVariance))}</>
                      )}
                    </Alert>
                  )}
                  
                  <TextField
                    fullWidth
                    label="Closing Notes (Optional)"
                    multiline
                    rows={2}
                    value={notes}
                    onChange={(e) => setNotes(e.target.value)}
                    placeholder="Any notes about discrepancies or issues..."
                    sx={{ mb: 3 }}
                  />
                  
                  <Button
                    fullWidth
                    variant="contained"
                    size="large"
                    onClick={handleCloseDay}
                    disabled={!countedCash || isClosing}
                    startIcon={isClosing ? null : <Lock />}
                    sx={{
                      bgcolor: '#fdd835',
                      color: '#0f0f0f',
                      '&:hover': { bgcolor: '#ffeb3b' },
                      py: 1.5,
                    }}
                  >
                    {isClosing ? (
                      <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                        <LinearProgress sx={{ width: 100 }} />
                        Closing Day...
                      </Box>
                    ) : (
                      'Close Business Day'
                    )}
                  </Button>
                </Box>
              )}
            </CardContent>
          </Card>
        </Grid>
      </Grid>
      
      {/* Daily Summary Breakdown */}
      <Card sx={{ bgcolor: dk ? '#1a1a2e' : '#fff', mt: 3 }}>
        <CardContent sx={{ p: 3 }}>
          <Typography variant="h6" fontWeight={600} mb={3}>
            Day Summary
          </Typography>
          
          <Grid container spacing={3}>
            <Grid size={{ xs: 12, md: 4 }}>
              <Box
                sx={{
                  p: 2,
                  bgcolor: dk ? '#0f0f0f' : '#f5f5f5',
                  borderRadius: 2,
                }}
              >
                <Typography variant="subtitle2" color="text.secondary" mb={2}>
                  Revenue
                </Typography>
                <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
                  <Typography variant="body2">Gross Sales</Typography>
                  <Typography variant="body2" fontWeight={600}>
                    {formatCurrency(summary.totalSales + summary.totalRefunds)}
                  </Typography>
                </Box>
                <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
                  <Typography variant="body2" color="error">Refunds</Typography>
                  <Typography variant="body2" color="error">
                    -{formatCurrency(summary.totalRefunds)}
                  </Typography>
                </Box>
                <Divider sx={{ my: 1 }} />
                <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                  <Typography variant="body2" fontWeight={600}>Net Sales</Typography>
                  <Typography variant="body2" fontWeight={600} color="#4caf50">
                    {formatCurrency(summary.totalSales)}
                  </Typography>
                </Box>
              </Box>
            </Grid>
            
            <Grid size={{ xs: 12, md: 4 }}>
              <Box
                sx={{
                  p: 2,
                  bgcolor: dk ? '#0f0f0f' : '#f5f5f5',
                  borderRadius: 2,
                }}
              >
                <Typography variant="subtitle2" color="text.secondary" mb={2}>
                  Order Stats
                </Typography>
                <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
                  <Typography variant="body2">Total Orders</Typography>
                  <Typography variant="body2" fontWeight={600}>
                    {summary.totalOrders}
                  </Typography>
                </Box>
                <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
                  <Typography variant="body2">Average Order Value</Typography>
                  <Typography variant="body2" fontWeight={600}>
                    {formatCurrency(safeAverage(summary.totalSales, summary.totalOrders))}
                  </Typography>
                </Box>
                <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                  <Typography variant="body2">Refund Rate</Typography>
                  <Typography variant="body2" fontWeight={600}>
                    {safePercent(summary.refundCount, summary.totalOrders)}%
                  </Typography>
                </Box>
              </Box>
            </Grid>
            
            <Grid size={{ xs: 12, md: 4 }}>
              <Box
                sx={{
                  p: 2,
                  bgcolor: dk ? '#0f0f0f' : '#f5f5f5',
                  borderRadius: 2,
                }}
              >
                <Typography variant="subtitle2" color="text.secondary" mb={2}>
                  Channel Mix
                </Typography>
                <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
                  <Typography variant="body2">Walk-In</Typography>
                  <Typography variant="body2" fontWeight={600}>
                    {safePercent(summary.walkInSales, summary.totalSales)}%
                  </Typography>
                </Box>
                <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
                  <Typography variant="body2">Phone</Typography>
                  <Typography variant="body2" fontWeight={600}>
                    {safePercent(summary.phoneOrdersAmount, summary.totalSales)}%
                  </Typography>
                </Box>
                <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                  <Typography variant="body2">Online</Typography>
                  <Typography variant="body2" fontWeight={600}>
                    {safePercent(summary.onlineOrdersAmount, summary.totalSales)}%
                  </Typography>
                </Box>
              </Box>
            </Grid>
          </Grid>
        </CardContent>
      </Card>
    </Box>
  );
}

function safePercent(part: number, total: number): number {
  if (!total || total === 0) return 0;
  return Math.round((part / total) * 100);
}

function safeAverage(total: number, count: number): number {
  if (!count || count === 0) return 0;
  return Math.round(total / count);
}
