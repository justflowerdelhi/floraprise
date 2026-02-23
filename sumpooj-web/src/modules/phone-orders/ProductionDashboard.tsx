import React, { useCallback, useEffect, useState } from 'react';
import {
  Box,
  Button,
  CircularProgress,
  Paper,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Typography,
  useTheme,
  alpha,
} from '@mui/material';
import {
  PlayArrow as StartIcon,
  Construction as ProductionIcon,
} from '@mui/icons-material';
import { useApiCall } from '../../hooks/useApiCall';
import {
  getPhoneOrders,
  startProductionForPhoneLocalOrder,
  type PhoneOrderResponse,
} from './phoneOrders.api';

// ── Component ────────────────────────────────────────────────────────────

const ProductionDashboard: React.FC = () => {
  const theme = useTheme();
  const { loading: fetching, execute: fetchExec } = useApiCall();
  const { loading: starting, execute: startExec } = useApiCall();

  const [orders, setOrders] = useState<PhoneOrderResponse[]>([]);
  const [startingId, setStartingId] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  // ── Fetch confirmed PhoneLocal orders ────────────────────────────────

  const loadOrders = useCallback(async () => {
    setError(null);
    const data = await fetchExec(
      () => getPhoneOrders({ status: 'Confirmed', type: 'PhoneLocal' }),
      { errorMessage: 'Failed to load production queue', showErrorToast: false },
    );
    if (data) {
      setOrders(data);
    } else {
      setError('Could not load orders. The API endpoint may not be deployed yet.');
    }
  }, [fetchExec]);

  useEffect(() => {
    loadOrders();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  // ── Start production handler ─────────────────────────────────────────

  const handleStartProduction = async (orderId: string) => {
    setStartingId(orderId);
    const result = await startExec(
      () => startProductionForPhoneLocalOrder(orderId),
      {
        successMessage: 'Production started',
        errorMessage: 'Failed to start production',
      },
    );
    setStartingId(null);
    if (result) loadOrders();
  };

  // ── Format date helper ──────────────────────────────────────────────

  const fmtDate = (iso: string) => {
    try {
      return new Date(iso).toLocaleDateString(undefined, {
        year: 'numeric',
        month: 'short',
        day: 'numeric',
      });
    } catch {
      return iso;
    }
  };

  // ── Render ───────────────────────────────────────────────────────────

  return (
    <Box>
      <Typography variant="h5" sx={{ mb: 3, fontWeight: 700, display: 'flex', alignItems: 'center', gap: 1 }}>
        <ProductionIcon /> Production Queue
      </Typography>

      {fetching ? (
        <Box sx={{ display: 'flex', justifyContent: 'center', py: 6 }}>
          <CircularProgress />
        </Box>
      ) : error ? (
        <Paper
          variant="outlined"
          sx={{
            py: 6,
            px: 3,
            display: 'flex',
            flexDirection: 'column',
            justifyContent: 'center',
            alignItems: 'center',
            gap: 2,
          }}
        >
          <Typography variant="body1" color="text.secondary">
            {error}
          </Typography>
          <Button variant="outlined" size="small" onClick={loadOrders}>
            Retry
          </Button>
        </Paper>
      ) : orders.length === 0 ? (
        <Paper
          variant="outlined"
          sx={{
            py: 6,
            display: 'flex',
            justifyContent: 'center',
            alignItems: 'center',
          }}
        >
          <Typography variant="body1" color="text.secondary">
            No orders pending production
          </Typography>
        </Paper>
      ) : (
        <TableContainer component={Paper} variant="outlined">
          <Table size="small">
            <TableHead>
              <TableRow
                sx={{ bgcolor: alpha(theme.palette.primary.main, 0.06) }}
              >
                <TableCell sx={{ fontWeight: 700 }}>Order Number</TableCell>
                <TableCell sx={{ fontWeight: 700 }}>Customer</TableCell>
                <TableCell sx={{ fontWeight: 700 }}>Delivery Date</TableCell>
                <TableCell sx={{ fontWeight: 700 }}>Time Slot</TableCell>
                <TableCell align="center" sx={{ fontWeight: 700 }}>Action</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {orders.map((order) => {
                const isStarting = startingId === order.id;

                return (
                  <TableRow key={order.id} hover>
                    <TableCell sx={{ fontFamily: 'monospace' }}>
                      {order.orderNumber}
                    </TableCell>
                    <TableCell>
                      {order.customerName ?? order.customerId}
                    </TableCell>
                    <TableCell>{fmtDate(order.deliveryDate)}</TableCell>
                    <TableCell>{order.timeSlot ?? '—'}</TableCell>
                    <TableCell align="center">
                      <Button
                        variant="contained"
                        size="small"
                        color="warning"
                        startIcon={
                          isStarting ? (
                            <CircularProgress size={16} color="inherit" />
                          ) : (
                            <StartIcon />
                          )
                        }
                        disabled={starting}
                        onClick={() => handleStartProduction(order.id)}
                        sx={{ textTransform: 'none', fontWeight: 700 }}
                      >
                        Start Production
                      </Button>
                    </TableCell>
                  </TableRow>
                );
              })}
            </TableBody>
          </Table>
        </TableContainer>
      )}
    </Box>
  );
};

export default ProductionDashboard;
