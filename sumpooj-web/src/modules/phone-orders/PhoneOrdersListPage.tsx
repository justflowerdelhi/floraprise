import React, { useEffect, useState } from 'react';
import {
  Box,
  Chip,
  CircularProgress,
  Container,
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
import { ListAlt as ListIcon } from '@mui/icons-material';
import { useNavigate } from 'react-router-dom';
import { useApiCall } from '../../hooks/useApiCall';
import { getPhoneOrders, type PhoneOrderResponse } from './phoneOrders.api';

const PhoneOrdersListPage: React.FC = () => {
  const theme = useTheme();
  const navigate = useNavigate();
  const { loading, execute } = useApiCall();
  const [orders, setOrders] = useState<PhoneOrderResponse[]>([]);

  useEffect(() => {
    const load = async () => {
      const data = await execute(() => getPhoneOrders(), {
        errorMessage: 'Failed to load phone orders',
      });
      if (data) setOrders(data);
    };
    load();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'Draft':
        return 'default';
      case 'Confirmed':
        return 'info';
      case 'InProduction':
        return 'warning';
      case 'SentToVendor':
        return 'secondary';
      case 'Delivered':
        return 'success';
      case 'Cancelled':
        return 'error';
      default:
        return 'default';
    }
  };

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

  return (
    <Container maxWidth="lg" sx={{ py: 4 }}>
      <Typography
        variant="h5"
        sx={{ fontWeight: 700, display: 'flex', alignItems: 'center', gap: 1, mb: 3 }}
      >
        <ListIcon /> All Phone Orders
      </Typography>

      {loading ? (
        <Box sx={{ display: 'flex', justifyContent: 'center', py: 6 }}>
          <CircularProgress />
        </Box>
      ) : orders.length === 0 ? (
        <Paper
          variant="outlined"
          sx={{ py: 6, display: 'flex', justifyContent: 'center', alignItems: 'center' }}
        >
          <Typography variant="body1" color="text.secondary">
            No phone orders found
          </Typography>
        </Paper>
      ) : (
        <TableContainer component={Paper} variant="outlined">
          <Table size="small">
            <TableHead>
              <TableRow sx={{ bgcolor: alpha(theme.palette.primary.main, 0.06) }}>
                <TableCell sx={{ fontWeight: 700 }}>Order Number</TableCell>
                <TableCell sx={{ fontWeight: 700 }}>Customer</TableCell>
                <TableCell sx={{ fontWeight: 700 }}>Type</TableCell>
                <TableCell sx={{ fontWeight: 700 }}>Status</TableCell>
                <TableCell sx={{ fontWeight: 700 }}>Delivery Date</TableCell>
                <TableCell sx={{ fontWeight: 700 }}>City</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {orders.map((order) => (
                <TableRow
                  key={order.id}
                  hover
                  sx={{ cursor: 'pointer' }}
                  onClick={() => navigate(`/phone-orders/${order.id}`)}
                >
                  <TableCell sx={{ fontFamily: 'monospace' }}>{order.orderNumber}</TableCell>
                  <TableCell>{order.customerName ?? order.customerId}</TableCell>
                  <TableCell>
                    <Chip
                      label={order.orderType === 'PhoneLocal' ? 'Local' : 'Outstation'}
                      size="small"
                      variant="outlined"
                      color={order.orderType === 'PhoneLocal' ? 'primary' : 'secondary'}
                    />
                  </TableCell>
                  <TableCell>
                    <Chip
                      label={order.status}
                      size="small"
                      color={getStatusColor(order.status)}
                    />
                  </TableCell>
                  <TableCell>{fmtDate(order.deliveryDate)}</TableCell>
                  <TableCell>{order.deliveryCity ?? '—'}</TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </TableContainer>
      )}
    </Container>
  );
};

export default PhoneOrdersListPage;
