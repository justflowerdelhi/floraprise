import React, { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  Alert,
  Badge,
  Box,
  Button,
  Card,
  CardContent,
  Chip,
  Container,
  Fab,
  Grid,
  Paper,
  Skeleton,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Typography,
  useTheme,
} from '@mui/material';
import {
  AddCircleOutline as AddIcon,
  Add as AddFabIcon,
  PrecisionManufacturing as ProductionIcon,
  ListAlt as ListIcon,
  Today as TodayIcon,
  Pending as PendingIcon,
  LocalShipping as DeliveryIcon,
  AttachMoney as RevenueIcon,
  PlayArrow as StartIcon,
} from '@mui/icons-material';
import {
  getDashboardSummary,
  getPhoneOrders,
  type DashboardSummaryResponse,
  type PhoneOrderResponse,
} from './phoneOrders.api';

// ── Card data ────────────────────────────────────────────────────────────

const ACTION_CARDS = [
  {
    title: 'New Phone Order',
    description: 'Create a new local or outstation phone order',
    icon: AddIcon,
    buttonText: 'Create Order',
    path: '/phone-orders/new',
  },
  {
    title: 'Production Queue',
    description: 'View confirmed local orders waiting for production',
    icon: ProductionIcon,
    buttonText: 'Open Production',
    path: '/phone-orders/production',
  },
  {
    title: 'All Phone Orders',
    description: 'Browse and manage all phone orders',
    icon: ListIcon,
    buttonText: 'View Orders',
    path: '/phone-orders/list',
  },
];

// ── Component ────────────────────────────────────────────────────────────

const PhoneOrdersHome: React.FC = () => {
  const navigate = useNavigate();
  const theme = useTheme();
  // ── KPI Summary State ─────────────────────────────────────────────────
  const [summary, setSummary] = useState<DashboardSummaryResponse | null>(null);
  const [loading, setLoading] = useState(true);

  // ── Today's Orders State ──────────────────────────────────────────────
  const [todayOrders, setTodayOrders] = useState<PhoneOrderResponse[]>([]);
  const [ordersLoading, setOrdersLoading] = useState(true);

  // ── Data Fetching ─────────────────────────────────────────────────────
  const fetchData = (isInitial = false) => {
    // Fetch dashboard summary
    getDashboardSummary()
      .then(setSummary)
      .catch((err) => console.error('Failed to load dashboard summary:', err))
      .finally(() => isInitial && setLoading(false));

    // Fetch today's orders (limit 5)
    getPhoneOrders({ filter: 'today', limit: 5 })
      .then(setTodayOrders)
      .catch((err) => console.error('Failed to load today orders:', err))
      .finally(() => isInitial && setOrdersLoading(false));
  };

  useEffect(() => {
    // Initial fetch
    fetchData(true);

    // Auto-refresh every 60 seconds
    const intervalId = setInterval(() => fetchData(false), 60_000);

    // Cleanup on unmount
    return () => clearInterval(intervalId);
  }, []);

  // ── Helpers ───────────────────────────────────────────────────────────
  const getStatusColor = (status: string): 'default' | 'warning' | 'info' | 'success' | 'error' => {
    switch (status) {
      case 'Draft': return 'default';
      case 'Confirmed': return 'info';
      case 'InProduction': return 'warning';
      case 'Ready': return 'success';
      case 'Delivered': return 'success';
      case 'Cancelled': return 'error';
      default: return 'default';
    }
  };

  const handleStartProduction = (orderId: string) => {
    navigate(`/phone-orders/production/${orderId}`);
  };

  // ── KPI Card Data ─────────────────────────────────────────────────────
  // Dynamic color logic for Pending Production and Pending Delivery
  const pendingProdValue = summary?.pendingProduction ?? 0;
  const pendingDeliveryValue = summary?.pendingDelivery ?? 0;

  const getPendingProductionColors = () => {
    if (pendingProdValue > 10) {
      return { bgColor: '#FFEBEE', iconColor: '#C62828' }; // Red
    } else if (pendingProdValue > 5) {
      return { bgColor: '#FFF3E0', iconColor: '#E65100' }; // Orange
    }
    return { bgColor: '#FFF3E0', iconColor: '#FB8C00' }; // Default orange
  };

  const getPendingDeliveryColors = () => {
    if (pendingDeliveryValue > 5) {
      return { bgColor: '#FFF3E0', iconColor: '#E65100' }; // Orange
    }
    return { bgColor: '#FCE4EC', iconColor: '#E91E63' }; // Default pink
  };

  const prodColors = getPendingProductionColors();
  const deliveryColors = getPendingDeliveryColors();

  const kpiCards = [
    {
      label: "Today's Orders",
      value: summary?.todayOrders ?? 0,
      icon: TodayIcon,
      bgColor: '#E3F2FD',
      iconColor: '#1976D2',
      path: '/phone-orders/list',
    },
    {
      label: 'Pending Production',
      value: pendingProdValue,
      icon: PendingIcon,
      bgColor: prodColors.bgColor,
      iconColor: prodColors.iconColor,
      path: '/phone-orders/production',
    },
    {
      label: 'Pending Delivery',
      value: pendingDeliveryValue,
      icon: DeliveryIcon,
      bgColor: deliveryColors.bgColor,
      iconColor: deliveryColors.iconColor,
      path: '/phone-orders/list?status=InProduction',
    },
    {
      label: "Today's Revenue",
      value: summary?.todayRevenue ?? 0,
      icon: RevenueIcon,
      bgColor: '#E8F5E9',
      iconColor: '#43A047',
      isCurrency: true,
      path: undefined,
    },
  ];
  return (
    <Container maxWidth="md" sx={{ py: 4 }}>
      {/* ── Page Title ─────────────────────────────────────────────── */}
      <Typography
        variant="h4"
        component="h1"
        sx={{
          fontWeight: 700,
          textAlign: 'center',
          mb: 4,
        }}
      >
        📞 Phone Orders
      </Typography>

      {/* ── KPI Summary Section ────────────────────────────────────── */}
      <Grid container spacing={2} sx={{ mb: 4 }}>
        {kpiCards.map((kpi) => {
          const IconComp = kpi.icon;
          return (
            <Grid size={{ xs: 6, sm: 3 }} key={kpi.label}>
              {loading ? (
                <Skeleton
                  variant="rounded"
                  height={100}
                  sx={{ borderRadius: 2 }}
                />
              ) : (
                <Card
                  elevation={0}
                  onClick={() => kpi.path && navigate(kpi.path)}
                  sx={{
                    bgcolor: kpi.bgColor,
                    borderRadius: 2,
                    p: 2,
                    height: '100%',
                    display: 'flex',
                    flexDirection: 'column',
                    justifyContent: 'center',
                    cursor: kpi.path ? 'pointer' : 'default',
                    transition: 'transform 0.2s ease, box-shadow 0.2s ease',
                    '&:hover': kpi.path
                      ? {
                          transform: 'translateY(-2px)',
                          boxShadow: theme.shadows[4],
                        }
                      : {},
                  }}
                >
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5, mb: 1 }}>
                    <IconComp sx={{ color: kpi.iconColor, fontSize: 28 }} />
                    <Typography
                      variant="h5"
                      sx={{ fontWeight: 700, color: kpi.iconColor }}
                    >
                      {kpi.isCurrency ? `₹${kpi.value.toLocaleString()}` : kpi.value}
                    </Typography>
                  </Box>
                  <Typography variant="body2" sx={{ color: 'text.secondary', fontWeight: 500 }}>
                    {kpi.label}
                  </Typography>
                </Card>
              )}
            </Grid>
          );
        })}
      </Grid>

      {/* ── Pending Production Alert ──────────────────────────────── */}
      {!loading && summary && summary.pendingProduction > 0 && (
        <Alert
          severity="warning"
          onClick={() => navigate('/phone-orders/production')}
          sx={{
            mb: 3,
            cursor: 'pointer',
            transition: 'background-color 0.2s ease',
            '&:hover': {
              bgcolor: 'warning.light',
            },
          }}
        >
          ⚠ {summary.pendingProduction} order{summary.pendingProduction > 1 ? 's' : ''} waiting for production
        </Alert>
      )}

      {/* ── Today's Orders Section ─────────────────────────────────── */}
      <Box sx={{ mb: 4 }}>
        <Typography variant="h6" sx={{ fontWeight: 600, mb: 2 }}>
          Today's Orders
        </Typography>
        {ordersLoading ? (
          <Skeleton variant="rounded" height={200} sx={{ borderRadius: 2 }} />
        ) : todayOrders.length === 0 ? (
          <Paper
            elevation={0}
            sx={{
              p: 3,
              textAlign: 'center',
              bgcolor: 'grey.50',
              borderRadius: 2,
              border: '1px dashed',
              borderColor: 'grey.300',
            }}
          >
            <Typography color="text.secondary">No phone orders today</Typography>
          </Paper>
        ) : (
          <TableContainer component={Paper} elevation={1} sx={{ borderRadius: 2 }}>
            <Table size="small">
              <TableHead>
                <TableRow sx={{ bgcolor: 'grey.50' }}>
                  <TableCell sx={{ fontWeight: 600 }}>Order #</TableCell>
                  <TableCell sx={{ fontWeight: 600 }}>Customer</TableCell>
                  <TableCell sx={{ fontWeight: 600 }}>Delivery Time</TableCell>
                  <TableCell sx={{ fontWeight: 600 }}>Status</TableCell>
                  <TableCell sx={{ fontWeight: 600 }} align="right">Action</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {todayOrders.map((order) => (
                  <TableRow
                    key={order.id}
                    hover
                    sx={{ cursor: 'pointer' }}
                    onClick={() => navigate(`/phone-orders/${order.id}`)}
                  >
                    <TableCell sx={{ fontFamily: 'monospace', fontSize: '0.85rem' }}>
                      {order.orderNumber}
                    </TableCell>
                    <TableCell>{order.customerName || '—'}</TableCell>
                    <TableCell>{order.timeSlot || '—'}</TableCell>
                    <TableCell>
                      <Chip
                        label={order.status}
                        color={getStatusColor(order.status)}
                        size="small"
                        variant="filled"
                      />
                    </TableCell>
                    <TableCell align="right">
                      {order.status === 'Confirmed' && (
                        <Button
                          size="small"
                          variant="contained"
                          color="warning"
                          startIcon={<StartIcon />}
                          onClick={(e) => {
                            e.stopPropagation();
                            handleStartProduction(order.id);
                          }}
                        >
                          Start Production
                        </Button>
                      )}
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </TableContainer>
        )}
      </Box>

      {/* ── Action Cards Grid ──────────────────────────────────────── */}
      <Grid container spacing={3} justifyContent="center">
        {ACTION_CARDS.map((card) => {
          const IconComponent = card.icon;
          const isNewOrder = card.title === 'New Phone Order';
          const isProduction = card.title === 'Production Queue';
          const badgeCount = isProduction ? (summary?.pendingProduction ?? 0) : 0;

          return (
            <Grid size={{ xs: 12, sm: 6, md: 4 }} key={card.title}>
              <Card
                elevation={isNewOrder ? 4 : 2}
                onClick={() => navigate(card.path)}
                sx={{
                  height: '100%',
                  display: 'flex',
                  flexDirection: 'column',
                  cursor: 'pointer',
                  transition: 'transform 0.2s ease-in-out, box-shadow 0.2s ease-in-out',
                  bgcolor: isNewOrder ? 'primary.main' : 'background.paper',
                  color: isNewOrder ? 'primary.contrastText' : 'text.primary',
                  '&:hover': {
                    transform: 'translateY(-4px)',
                    boxShadow: theme.shadows[10],
                  },
                }}
              >
                <CardContent
                  sx={{
                    flexGrow: 1,
                    display: 'flex',
                    flexDirection: 'column',
                    alignItems: 'center',
                    textAlign: 'center',
                    py: 4,
                  }}
                >
                  <Badge
                    badgeContent={badgeCount}
                    color="error"
                    invisible={badgeCount === 0}
                    sx={{ mb: 2 }}
                  >
                    <Box
                      sx={{
                        p: 2,
                        borderRadius: '50%',
                        bgcolor: isNewOrder
                          ? 'rgba(255,255,255,0.2)'
                          : theme.palette.primary.main + '14',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                      }}
                    >
                      <IconComponent
                        fontSize="large"
                        sx={{
                          color: isNewOrder ? 'white' : theme.palette.primary.main,
                          fontSize: 48,
                        }}
                      />
                    </Box>
                  </Badge>

                  <Typography
                    variant="h6"
                    component="h2"
                    sx={{
                      fontWeight: 700,
                      mb: 1,
                      color: isNewOrder ? 'inherit' : 'text.primary',
                    }}
                  >
                    {card.title}
                  </Typography>

                  <Typography
                    variant="body2"
                    sx={{
                      color: isNewOrder ? 'rgba(255,255,255,0.85)' : 'text.secondary',
                    }}
                  >
                    {card.description}
                  </Typography>
                </CardContent>
              </Card>
            </Grid>
          );
        })}
      </Grid>

      {/* ── Floating Action Button ──────────────────────────────── */}
      <Fab
        color="primary"
        aria-label="New Phone Order"
        onClick={() => navigate('/phone-orders/new')}
        sx={{
          position: 'fixed',
          bottom: 24,
          right: 24,
        }}
      >
        <AddFabIcon />
      </Fab>
    </Container>
  );
};

export default PhoneOrdersHome;
