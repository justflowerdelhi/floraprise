
type Delivery = {
  id: string;
  orderNumber: string;
  customerName: string;
  timeSlot: string;
  postalCode: string;
};

type Route = {
  id: string;
  name: string;
  stopCount: number;
  status: string;
};

const fetchDeliveries = async (date: string): Promise<Delivery[]> => {
  const res = await fetch(`/api/deliveries?date=${date}&status=Scheduled&routeId=null`);
  return await res.json();
};
const fetchRoutes = async (date: string): Promise<Route[]> => {
  const res = await fetch(`/api/delivery-routes?date=${date}`);
  return await res.json();
};
const createRoute = async (routeDate: string, deliveryIds: string[]): Promise<{ routeId: string }> => {
  const res = await fetch('/api/delivery-routes', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ routeDate, deliveryIds })
  });
  if (!res.ok) throw new Error('Failed to create route');
  return await res.json();
};

import React, { useState, useEffect } from 'react';
import { Button, TextField, Card, CardContent, Typography, Checkbox, Table, TableBody, TableCell, TableHead, TableRow, CircularProgress } from '@mui/material';
import { useNavigate } from 'react-router-dom';
import { useToast } from '../hooks/useToast';

export default function DeliveryRoutesPage() {
  const [date, setDate] = useState<string>(new Date().toISOString().slice(0, 10));
  const [deliveries, setDeliveries] = useState<Delivery[]>([]);
  const [selected, setSelected] = useState<string[]>([]);
  const [routes, setRoutes] = useState<Route[]>([]);
  const [loading, setLoading] = useState(false);
  const toast = useToast();
  const navigate = useNavigate();

  const loadDeliveries = async () => {
    setLoading(true);
    const data = await fetchDeliveries(date);
    setDeliveries(data);
    setLoading(false);
  };

  const loadRoutes = async () => {
    const data = await fetchRoutes(date);
    setRoutes(data);
  };

  useEffect(() => {
    loadDeliveries();
    loadRoutes();
    setSelected([]);
  }, [date]);

  const handleSelect = (id: string) => {
    setSelected(selected.includes(id) ? selected.filter((x: string) => x !== id) : [...selected, id]);
  };

  const handleCreateRoute = async () => {
    setLoading(true);
    try {
      const result = await createRoute(date, selected);
      toast.success('Route created!');
      navigate(`/delivery-routes/${result.routeId}`);
    } catch (e) {
      toast.error('Failed to create route');
    }
    setLoading(false);
  };

  return (
    <div style={{ maxWidth: 900, margin: '0 auto', padding: 24 }}>
      <div style={{ display: 'flex', gap: 16, marginBottom: 24 }}>
        <TextField
          label="Date"
          type="date"
          value={date}
          onChange={e => setDate(e.target.value)}
          InputLabelProps={{ shrink: true }}
        />
      </div>
      <Typography variant="h6" gutterBottom>Scheduled Deliveries</Typography>
      {loading ? <CircularProgress /> : (
        <Table>
          <TableHead>
            <TableRow>
              <TableCell></TableCell>
              <TableCell>Order Number</TableCell>
              <TableCell>Customer</TableCell>
              <TableCell>Time Slot</TableCell>
              <TableCell>Postal Code</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {deliveries.map(delivery => (
              <TableRow key={delivery.id}>
                <TableCell>
                  <Checkbox
                    checked={selected.includes(delivery.id)}
                    onChange={() => handleSelect(delivery.id)}
                    disabled={loading}
                  />
                </TableCell>
                <TableCell>{delivery.orderNumber}</TableCell>
                <TableCell>{delivery.customerName}</TableCell>
                <TableCell>{delivery.timeSlot}</TableCell>
                <TableCell>{delivery.postalCode}</TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      )}
      <Button
        variant="contained"
        color="primary"
        disabled={selected.length === 0 || loading}
        onClick={handleCreateRoute}
        style={{ marginTop: 16 }}
      >
        Create Route
      </Button>
      <Typography variant="h6" style={{ marginTop: 32 }}>Existing Routes</Typography>
      <div>
        {routes.map(route => (
          <Card key={route.id} style={{ marginBottom: 16 }}>
            <CardContent>
              <Typography variant="h6">{route.name}</Typography>
              <Typography>Stops: {route.stopCount}</Typography>
              <Typography>Status: {route.status}</Typography>
              <Button variant="outlined" style={{ marginTop: 8 }} onClick={() => navigate(`/delivery-routes/${route.id}`)}>View</Button>
            </CardContent>
          </Card>
        ))}
      </div>
    </div>
  );
}
