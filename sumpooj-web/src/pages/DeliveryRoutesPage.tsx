import React, { useCallback, useEffect, useMemo, useState } from 'react';
import {
  Alert,
  Box,
  Button,
  Card,
  CardContent,
  Checkbox,
  CircularProgress,
  Paper,
  Stack,
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableRow,
  TextField,
  Typography,
} from '@mui/material';
import { useNavigate } from 'react-router-dom';
import { useToast } from '../hooks/useToast';
import { apiClient } from '../core/api/apiClient';

type Delivery = {
  id: string;
  orderNumber: string;
  customerName: string;
  timeSlot: string;
  postalCode: string;
  address?: string;
  status?: string;
};

type Route = {
  id: string;
  name: string;
  stopCount: number;
  status: string;
};

type DeliveryListDto = {
  deliveryId: string;
  orderNumber: string;
  customerName: string;
  timeSlot: string;
  postalCode?: string | null;
  address?: string;
  status?: string;
};

const fetchDeliveries = async (date: string): Promise<Delivery[]> => {
  const res = await apiClient.get('/deliveries', {
    params: { date, status: 'Scheduled', routeId: 'null' },
  });

  const items = Array.isArray(res.data) ? res.data : res.data?.items ?? [];

  return items.map((delivery: DeliveryListDto) => ({
    id: delivery.deliveryId,
    orderNumber: delivery.orderNumber,
    customerName: delivery.customerName,
    timeSlot: delivery.timeSlot,
    postalCode: delivery.postalCode ?? '',
    address: delivery.address,
    status: delivery.status,
  }));
};

const fetchRoutes = async (date: string): Promise<Route[]> => {
  const res = await apiClient.get('/delivery-routes', { params: { date } });
  return Array.isArray(res.data) ? res.data : res.data?.items ?? [];
};

const createRoute = async (routeDate: string, deliveryIds: string[]): Promise<{ routeId: string }> => {
  const res = await apiClient.post('/delivery-routes', { routeDate, deliveryIds });
  return res.data;
};

const formatLocalDate = (date = new Date()) => {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
};

export default function DeliveryRoutesPage() {
  const [date, setDate] = useState<string>(formatLocalDate());
  const [deliveries, setDeliveries] = useState<Delivery[]>([]);
  const [selected, setSelected] = useState<string[]>([]);
  const [routes, setRoutes] = useState<Route[]>([]);
  const [loadingDeliveries, setLoadingDeliveries] = useState(false);
  const [loadingRoutes, setLoadingRoutes] = useState(false);
  const [creatingRoute, setCreatingRoute] = useState(false);
  const [error, setError] = useState<string>('');
  const toast = useToast();
  const navigate = useNavigate();

  const loading = loadingDeliveries || loadingRoutes || creatingRoute;

  const loadDeliveries = useCallback(async () => {
    setLoadingDeliveries(true);
    try {
      const data = await fetchDeliveries(date);
      setDeliveries(data);
    } catch (err: any) {
      setDeliveries([]);
      setError(err?.response?.data?.message ?? err?.message ?? 'Failed to load deliveries.');
    } finally {
      setLoadingDeliveries(false);
    }
  }, [date]);

  const loadRoutes = useCallback(async () => {
    setLoadingRoutes(true);
    try {
      const data = await fetchRoutes(date);
      setRoutes(data);
    } catch (err: any) {
      setRoutes([]);
      setError(err?.response?.data?.message ?? err?.message ?? 'Failed to load routes.');
    } finally {
      setLoadingRoutes(false);
    }
  }, [date]);

  useEffect(() => {
    setError('');
    loadDeliveries();
    loadRoutes();
    setSelected([]);
  }, [date, loadDeliveries, loadRoutes]);

  const handleSelect = (id: string) => {
    setSelected(selected.includes(id) ? selected.filter((x: string) => x !== id) : [...selected, id]);
  };

  const selectedDeliveries = useMemo(
    () => deliveries.filter((delivery) => selected.includes(delivery.id)),
    [deliveries, selected],
  );

  const handleCreateRoute = async () => {
    setCreatingRoute(true);
    try {
      const result = await createRoute(date, selected);
      toast.success('Route created!');
      navigate(`/delivery-routes/${result.routeId}`);
    } catch (err: any) {
      const message = err?.response?.data?.message ?? err?.message ?? 'Failed to create route';
      setError(message);
      toast.error(message);
    } finally {
      setCreatingRoute(false);
    }
  };

  return (
    <Box sx={{ maxWidth: 1100, mx: 'auto', p: 3 }}>
      <Stack direction={{ xs: 'column', md: 'row' }} justifyContent="space-between" spacing={2} sx={{ mb: 3 }}>
        <Box>
          <Typography variant="h5" sx={{ fontWeight: 700 }}>Delivery Routes</Typography>
          <Typography variant="body2" color="text.secondary">
            Create routes from scheduled deliveries and review existing routes for the selected date.
          </Typography>
        </Box>
        <TextField
          label="Date"
          type="date"
          value={date}
          onChange={e => setDate(e.target.value)}
          InputLabelProps={{ shrink: true }}
          size="small"
          sx={{ minWidth: 200 }}
        />
      </Stack>

      {error && (
        <Alert severity="error" sx={{ mb: 2 }}>
          {error}
        </Alert>
      )}

      <Stack spacing={3}>
        <Paper variant="outlined" sx={{ p: 2.5, borderRadius: 3 }}>
          <Stack direction={{ xs: 'column', md: 'row' }} justifyContent="space-between" spacing={2} sx={{ mb: 2 }}>
            <Box>
              <Typography variant="h6">Scheduled Deliveries</Typography>
              <Typography variant="body2" color="text.secondary">
                Select unassigned scheduled deliveries to create a route.
              </Typography>
            </Box>
            <Button
              variant="contained"
              disabled={selected.length === 0 || loading}
              onClick={handleCreateRoute}
            >
              Create Route{selected.length > 0 ? ` (${selected.length})` : ''}
            </Button>
          </Stack>

          {loadingDeliveries ? (
            <Box sx={{ display: 'flex', justifyContent: 'center', py: 6 }}>
              <CircularProgress />
            </Box>
          ) : deliveries.length === 0 ? (
            <Alert severity="info">No unassigned scheduled deliveries found for this date.</Alert>
          ) : (
            <Table size="small">
              <TableHead>
                <TableRow>
                  <TableCell padding="checkbox"></TableCell>
                  <TableCell>Order Number</TableCell>
                  <TableCell>Customer</TableCell>
                  <TableCell>Time Slot</TableCell>
                  <TableCell>Postal Code</TableCell>
                  <TableCell>Address</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {deliveries.map((delivery) => (
                  <TableRow key={delivery.id} hover selected={selected.includes(delivery.id)}>
                    <TableCell padding="checkbox">
                      <Checkbox
                        checked={selected.includes(delivery.id)}
                        onChange={() => handleSelect(delivery.id)}
                        disabled={loading}
                      />
                    </TableCell>
                    <TableCell>{delivery.orderNumber}</TableCell>
                    <TableCell>{delivery.customerName}</TableCell>
                    <TableCell>{delivery.timeSlot}</TableCell>
                    <TableCell>{delivery.postalCode || '-'}</TableCell>
                    <TableCell>{delivery.address || '-'}</TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          )}

          {selectedDeliveries.length > 0 && (
            <Typography variant="caption" color="text.secondary" sx={{ display: 'block', mt: 1.5 }}>
              Selected orders: {selectedDeliveries.map((delivery) => delivery.orderNumber).join(', ')}
            </Typography>
          )}
        </Paper>

        <Box>
          <Typography variant="h6" sx={{ mb: 1.5 }}>Existing Routes</Typography>

          {loadingRoutes ? (
            <Box sx={{ display: 'flex', justifyContent: 'center', py: 4 }}>
              <CircularProgress size={28} />
            </Box>
          ) : routes.length === 0 ? (
            <Alert severity="info">No delivery routes found for this date.</Alert>
          ) : (
            <Stack spacing={2}>
              {routes.map((route) => (
                <Card key={route.id} variant="outlined" sx={{ borderRadius: 3 }}>
                  <CardContent>
                    <Stack direction={{ xs: 'column', sm: 'row' }} justifyContent="space-between" spacing={2}>
                      <Box>
                        <Typography variant="h6">{route.name}</Typography>
                        <Typography variant="body2" color="text.secondary">
                          Stops: {route.stopCount} | Status: {route.status}
                        </Typography>
                      </Box>
                      <Box>
                        <Button variant="outlined" onClick={() => navigate(`/delivery-routes/${route.id}`)}>
                          View
                        </Button>
                      </Box>
                    </Stack>
                  </CardContent>
                </Card>
              ))}
            </Stack>
          )}
        </Box>
      </Stack>
    </Box>
  );
}
