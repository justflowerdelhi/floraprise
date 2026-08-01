/**
 * DeliveryControlCenter.tsx — Main dispatcher dashboard
 * 
 * Features:
 * - Today's deliveries overview
 * - Online/offline drivers
 * - Interactive widgets
 * - Real-time updates via SignalR
 */
import React, { useState, useEffect } from 'react';
import {
  Box, Grid, Card, CardContent, Typography, Chip, Avatar,
  LinearProgress, IconButton, Tooltip, useTheme, alpha,
  Table, TableBody, TableCell, TableContainer, TableHead, TableRow,
  Paper, Stack, Badge, Alert, CircularProgress
} from '@mui/material';
import {
  LocalShipping, People, Schedule, CheckCircle, Warning,
  Refresh, Phone, LocationOn, Speed, AccessTime,
  TrendingUp, TrendingDown, ErrorOutline
} from '@mui/icons-material';
import { useNavigate } from 'react-router-dom';

interface DashboardStats {
  totalDrivers: number;
  totalWaiting: number;
  totalInProgress: number;
  totalDelayed: number;
  totalCompleted: number;
}

interface OnlineDriver {
  driverId: string;
  driverName: string;
  driverPhone: string;
  vehicle?: string;
  routeId: string;
  routeName: string;
  status: string;
  isOnline: boolean;
  lastLocationUpdate?: string;
}

interface WaitingOrder {
  deliveryId: string;
  orderId: string;
  orderNumber: string;
  customerName: string;
  customerPhone?: string;
  deliveryAddress: string;
  timeSlot: string;
  postalCode?: string;
}

interface InProgressDelivery {
  deliveryId: string;
  orderId: string;
  orderNumber: string;
  customerName: string;
  customerPhone?: string;
  deliveryAddress: string;
  timeSlot: string;
  routeId?: string;
  routeName?: string;
  stopOrder?: number;
  status: string;
}

interface DelayedDelivery {
  deliveryId: string;
  orderId: string;
  orderNumber: string;
  customerName: string;
  customerPhone?: string;
  deliveryAddress: string;
  timeSlot: string;
  scheduledTime: string;
  delayMinutes: number;
  routeId?: string;
  routeName?: string;
  status: string;
}

interface DriverLocation {
  driverId: string;
  driverName: string;
  driverPhone: string;
  vehicle?: string;
  latitude: number;
  longitude: number;
  speedKph: number;
  lastUpdate?: string;
  isOnline: boolean;
}

interface CompletedDelivery {
  deliveryId: string;
  orderId: string;
  orderNumber: string;
  customerName: string;
  deliveryAddress: string;
  timeSlot: string;
  completedAt: string;
  status: string;
}

interface DashboardData {
  date: string;
  onlineDrivers: OnlineDriver[];
  waitingOrders: WaitingOrder[];
  inProgressDeliveries: InProgressDelivery[];
  delayedDeliveries: DelayedDelivery[];
  driverLocations: DriverLocation[];
  completedDeliveries: CompletedDelivery[];
  summary: DashboardStats;
}

export default function DeliveryControlCenter() {
  const theme = useTheme();
  const navigate = useNavigate();
  const [loading, setLoading] = useState(true);
  const [data, setData] = useState<DashboardData | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [selectedDate, setSelectedDate] = useState(new Date().toISOString().split('T')[0]);

  const fetchDashboardData = async () => {
    setLoading(true);
    setError(null);
    try {
      const response = await fetch(`/api/delivery/control-center/dashboard?date=${selectedDate}`);
      if (!response.ok) throw new Error('Failed to fetch dashboard data');
      const dashboardData = await response.json();
      setData(dashboardData);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Unknown error');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchDashboardData();
    // Refresh every 30 seconds
    const interval = setInterval(fetchDashboardData, 30000);
    return () => clearInterval(interval);
  }, [selectedDate]);

  const StatCard = ({ title, value, icon, color, subtitle, onClick }: any) => (
    <Card
      sx={{
        height: '100%',
        cursor: onClick ? 'pointer' : 'default',
        transition: 'all 0.2s',
        '&:hover': onClick ? {
          transform: 'translateY(-4px)',
          boxShadow: theme.shadows[8]
        } : {}
      }}
      onClick={onClick}
    >
      <CardContent>
        <Stack direction="row" alignItems="center" spacing={2}>
          <Avatar
            sx={{
              bgcolor: alpha(color, 0.15),
              color: color,
              width: 56,
              height: 56
            }}
          >
            {icon}
          </Avatar>
          <Box sx={{ flex: 1 }}>
            <Typography variant="caption" color="text.secondary" sx={{ textTransform: 'uppercase', fontWeight: 600 }}>
              {title}
            </Typography>
            <Typography variant="h4" sx={{ fontWeight: 700, color }}>
              {value}
            </Typography>
            {subtitle && (
              <Typography variant="caption" color="text.secondary">
                {subtitle}
              </Typography>
            )}
          </Box>
        </Stack>
      </CardContent>
    </Card>
  );

  if (loading) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', minHeight: '60vh' }}>
        <CircularProgress />
      </Box>
    );
  }

  if (error) {
    return (
      <Alert severity="error" sx={{ m: 2 }}>
        {error}
        <IconButton onClick={fetchDashboardData} size="small">
          <Refresh />
        </IconButton>
      </Alert>
    );
  }

  if (!data) return null;

  return (
    <Box sx={{ p: 3 }}>
      {/* Header */}
      <Stack direction="row" justifyContent="space-between" alignItems="center" sx={{ mb: 3 }}>
        <Box>
          <Typography variant="h4" sx={{ fontWeight: 700 }}>
            Delivery Control Center
          </Typography>
          <Typography variant="body2" color="text.secondary">
            Real-time delivery operations dashboard
          </Typography>
        </Box>
        <Stack direction="row" spacing={2} alignItems="center">
          <input
            type="date"
            value={selectedDate}
            onChange={(e) => setSelectedDate(e.target.value)}
            style={{
              padding: '8px 12px',
              borderRadius: '8px',
              border: `1px solid ${theme.palette.divider}`,
              background: theme.palette.background.paper
            }}
          />
          <IconButton onClick={fetchDashboardData}>
            <Refresh />
          </IconButton>
        </Stack>
      </Stack>

      {/* Stats Grid */}
      <Grid container spacing={3} sx={{ mb: 3 }}>
        <Grid item xs={12} sm={6} md={2.4}>
          <StatCard
            title="Online Drivers"
            value={data.summary.totalDrivers}
            icon={<People />}
            color="#4caf50"
            subtitle="Currently active"
            onClick={() => navigate('/delivery/live-map')}
          />
        </Grid>
        <Grid item xs={12} sm={6} md={2.4}>
          <StatCard
            title="Waiting Assignment"
            value={data.summary.totalWaiting}
            icon={<Schedule />}
            color="#ff9800"
            subtitle="Need drivers"
            onClick={() => {}}
          />
        </Grid>
        <Grid item xs={12} sm={6} md={2.4}>
          <StatCard
            title="In Progress"
            value={data.summary.totalInProgress}
            icon={<LocalShipping />}
            color="#2196f3"
            subtitle="On the road"
            onClick={() => navigate('/delivery/live-map')}
          />
        </Grid>
        <Grid item xs={12} sm={6} md={2.4}>
          <StatCard
            title="Delayed"
            value={data.summary.totalDelayed}
            icon={<Warning />}
            color="#f44336"
            subtitle="Needs attention"
            onClick={() => {}}
          />
        </Grid>
        <Grid item xs={12} sm={6} md={2.4}>
          <StatCard
            title="Completed"
            value={data.summary.totalCompleted}
            icon={<CheckCircle />}
            color="#00bcd4"
            subtitle="Today"
            onClick={() => {}}
          />
        </Grid>
      </Grid>

      {/* Main Content Grid */}
      <Grid container spacing={3}>
        {/* Online Drivers */}
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Stack direction="row" justifyContent="space-between" alignItems="center" sx={{ mb: 2 }}>
                <Typography variant="h6" sx={{ fontWeight: 600 }}>
                  Online Drivers
                </Typography>
                <Badge badgeContent={data.onlineDrivers.length} color="success">
                  <People />
                </Badge>
              </Stack>
              <TableContainer component={Paper} variant="outlined">
                <Table size="small">
                  <TableHead>
                    <TableRow>
                      <TableCell>Driver</TableCell>
                      <TableCell>Vehicle</TableCell>
                      <TableCell>Route</TableCell>
                      <TableCell>Status</TableCell>
                      <TableCell>Actions</TableCell>
                    </TableRow>
                  </TableHead>
                  <TableBody>
                    {data.onlineDrivers.map((driver) => (
                      <TableRow key={driver.driverId} hover>
                        <TableCell>
                          <Stack>
                            <Typography variant="body2" sx={{ fontWeight: 600 }}>
                              {driver.driverName}
                            </Typography>
                            <Typography variant="caption" color="text.secondary">
                              {driver.driverPhone}
                            </Typography>
                          </Stack>
                        </TableCell>
                        <TableCell>{driver.vehicle || '-'}</TableCell>
                        <TableCell>{driver.routeName}</TableCell>
                        <TableCell>
                          <Chip
                            label={driver.status}
                            size="small"
                            color={driver.isOnline ? 'success' : 'default'}
                          />
                        </TableCell>
                        <TableCell>
                          <Stack direction="row" spacing={1}>
                            <Tooltip title="Call">
                              <IconButton size="small">
                                <Phone fontSize="small" />
                              </IconButton>
                            </Tooltip>
                            <Tooltip title="View Location">
                              <IconButton size="small" onClick={() => navigate('/delivery/live-map')}>
                                <LocationOn fontSize="small" />
                              </IconButton>
                            </Tooltip>
                          </Stack>
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </TableContainer>
            </CardContent>
          </Card>
        </Grid>

        {/* Waiting Orders */}
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Stack direction="row" justifyContent="space-between" alignItems="center" sx={{ mb: 2 }}>
                <Typography variant="h6" sx={{ fontWeight: 600 }}>
                  Waiting Assignment
                </Typography>
                <Badge badgeContent={data.waitingOrders.length} color="warning">
                  <Schedule />
                </Badge>
              </Stack>
              <TableContainer component={Paper} variant="outlined" sx={{ maxHeight: 300 }}>
                <Table size="small">
                  <TableHead>
                    <TableRow>
                      <TableCell>Order</TableCell>
                      <TableCell>Customer</TableCell>
                      <TableCell>Time Slot</TableCell>
                      <TableCell>Address</TableCell>
                    </TableRow>
                  </TableHead>
                  <TableBody>
                    {data.waitingOrders.map((order) => (
                      <TableRow key={order.deliveryId} hover>
                        <TableCell>
                          <Typography variant="body2" sx={{ fontWeight: 600 }}>
                            {order.orderNumber}
                          </Typography>
                        </TableCell>
                        <TableCell>{order.customerName}</TableCell>
                        <TableCell>
                          <Chip label={order.timeSlot} size="small" variant="outlined" />
                        </TableCell>
                        <TableCell>
                          <Typography variant="caption" noWrap sx={{ maxWidth: 150 }}>
                            {order.deliveryAddress}
                          </Typography>
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </TableContainer>
            </CardContent>
          </Card>
        </Grid>

        {/* In Progress Deliveries */}
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Stack direction="row" justifyContent="space-between" alignItems="center" sx={{ mb: 2 }}>
                <Typography variant="h6" sx={{ fontWeight: 600 }}>
                  In Progress
                </Typography>
                <Badge badgeContent={data.inProgressDeliveries.length} color="info">
                  <LocalShipping />
                </Badge>
              </Stack>
              <TableContainer component={Paper} variant="outlined" sx={{ maxHeight: 300 }}>
                <Table size="small">
                  <TableHead>
                    <TableRow>
                      <TableCell>Order</TableCell>
                      <TableCell>Customer</TableCell>
                      <TableCell>Route</TableCell>
                      <TableCell>Status</TableCell>
                      <TableCell>Actions</TableCell>
                    </TableRow>
                  </TableHead>
                  <TableBody>
                    {data.inProgressDeliveries.map((delivery) => (
                      <TableRow key={delivery.deliveryId} hover>
                        <TableCell>
                          <Typography variant="body2" sx={{ fontWeight: 600 }}>
                            {delivery.orderNumber}
                          </Typography>
                        </TableCell>
                        <TableCell>{delivery.customerName}</TableCell>
                        <TableCell>{delivery.routeName || '-'}</TableCell>
                        <TableCell>
                          <Chip label={delivery.status} size="small" color="info" />
                        </TableCell>
                        <TableCell>
                          <IconButton
                            size="small"
                            onClick={() => navigate(`/delivery/workspace/${delivery.deliveryId}`)}
                          >
                            <LocationOn fontSize="small" />
                          </IconButton>
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </TableContainer>
            </CardContent>
          </Card>
        </Grid>

        {/* Delayed Deliveries */}
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Stack direction="row" justifyContent="space-between" alignItems="center" sx={{ mb: 2 }}>
                <Typography variant="h6" sx={{ fontWeight: 600 }}>
                  Delayed Deliveries
                </Typography>
                <Badge badgeContent={data.delayedDeliveries.length} color="error">
                  <Warning />
                </Badge>
              </Stack>
              <TableContainer component={Paper} variant="outlined" sx={{ maxHeight: 300 }}>
                <Table size="small">
                  <TableHead>
                    <TableRow>
                      <TableCell>Order</TableCell>
                      <TableCell>Customer</TableCell>
                      <TableCell>Scheduled</TableCell>
                      <TableCell>Delay</TableCell>
                      <TableCell>Actions</TableCell>
                    </TableRow>
                  </TableHead>
                  <TableBody>
                    {data.delayedDeliveries.map((delivery) => (
                      <TableRow key={delivery.deliveryId} hover>
                        <TableCell>
                          <Typography variant="body2" sx={{ fontWeight: 600 }}>
                            {delivery.orderNumber}
                          </Typography>
                        </TableCell>
                        <TableCell>{delivery.customerName}</TableCell>
                        <TableCell>
                          <Typography variant="caption">
                            {new Date(delivery.scheduledTime).toLocaleTimeString()}
                          </Typography>
                        </TableCell>
                        <TableCell>
                          <Chip
                            label={`${delivery.delayMinutes}m`}
                            size="small"
                            color="error"
                          />
                        </TableCell>
                        <TableCell>
                          <IconButton
                            size="small"
                            onClick={() => navigate(`/delivery/workspace/${delivery.deliveryId}`)}
                          >
                            <ErrorOutline fontSize="small" />
                          </IconButton>
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </TableContainer>
            </CardContent>
          </Card>
        </Grid>
      </Grid>
    </Box>
  );
}
