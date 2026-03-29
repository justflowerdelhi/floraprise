import React, { useEffect, useState } from 'react';
import type { RouteDetail, Driver, Delivery } from '../types/deliveryRouteTypes';
import { Button, Card, CardContent, Typography, Chip, Select, MenuItem, CircularProgress } from '@mui/material';
import { useParams } from 'react-router-dom';
import { useToast } from '../hooks/useToast';
import { apiClient } from '../core/api/apiClient';

const fetchRouteDetail = async (routeId: string): Promise<RouteDetail> => {
  const res = await apiClient.get(`/delivery-routes/${routeId}`);
  return res.data as RouteDetail;
};
const fetchAvailableDrivers = async (): Promise<Driver[]> => {
  const res = await apiClient.get('/staff/available-drivers');
  return Array.isArray(res.data) ? res.data : res.data?.items ?? [];
};
const assignDriver = async (routeId: string, driverId: string): Promise<void> => {
  await apiClient.put(`/delivery-routes/${routeId}/assign-driver`, { driverId });
};
const startRoute = async (routeId: string): Promise<void> => {
  await apiClient.put(`/delivery-routes/${routeId}/start`);
};
const completeRoute = async (routeId: string): Promise<void> => {
  await apiClient.put(`/delivery-routes/${routeId}/complete`);
};

export default function DeliveryRouteDetailPage() {
  const { routeId } = useParams<{ routeId: string }>();
  const [route, setRoute] = useState<RouteDetail | null>(null);
  const [drivers, setDrivers] = useState<Driver[]>([]);
  const [selectedDriver, setSelectedDriver] = useState<string>('');
  const [loading, setLoading] = useState<boolean>(false);
  const toast = useToast();

  const loadRoute = async () => {
    setLoading(true);
    if (!routeId) {
      setLoading(false);
      return;
    }
    const data = await fetchRouteDetail(routeId);
    setRoute(data);
    setLoading(false);
  };

  useEffect(() => {
    loadRoute();
  }, [routeId]);

  useEffect(() => {
    if (route && route.status === 'Draft') {
      fetchAvailableDrivers().then(setDrivers);
    }
  }, [route]);

  const handleAssignDriver = async () => {
    setLoading(true);
    try {
      if (!routeId || !selectedDriver) throw new Error('Missing routeId or driver');
      await assignDriver(routeId, selectedDriver);
      toast.success('Driver assigned successfully!');
      await loadRoute();
    } catch (e) {
      toast.error('Failed to assign driver');
    }
    setLoading(false);
  };

  const handleStart = async () => {
    setLoading(true);
    try {
      if (!routeId) throw new Error('Missing routeId');
      await startRoute(routeId);
      toast.success('Route started!');
      await loadRoute();
    } catch (e) {
      toast.error('Failed to start route');
    }
    setLoading(false);
  };

  const handleComplete = async () => {
    setLoading(true);
    try {
      if (!routeId) throw new Error('Missing routeId');
      await completeRoute(routeId);
      toast.success('Route completed!');
      await loadRoute();
    } catch (e) {
      toast.error('Failed to complete route');
    }
    setLoading(false);
  };

  if (!route) return <div style={{textAlign:'center',marginTop:40}}><CircularProgress /></div>;

  return (
    <div style={{ maxWidth: 800, margin: '0 auto', padding: 24 }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 16, marginBottom: 24 }}>
        <Typography variant="h5">{route.name}</Typography>
        <Chip label={route.status} color={route.status === 'Completed' ? 'success' : route.status === 'Assigned' ? 'primary' : route.status === 'InProgress' ? 'warning' : 'default'} />
        {route.status === 'Assigned' && route.deliveryPersonName && (
          <Chip label={route.deliveryPersonName} color="success" />
        )}
        {route.status === 'InProgress' && route.deliveryPersonName && (
          <Chip label={route.deliveryPersonName} color="info" />
        )}
        {route.status === 'Completed' && (
          <Chip label="Completed" color="success" />
        )}
      </div>
      {route.status === 'Draft' && (
        <div style={{ display: 'flex', gap: 16, alignItems: 'center', marginBottom: 24 }}>
          <Select
            value={selectedDriver}
            onChange={e => setSelectedDriver(e.target.value)}
            displayEmpty
            style={{ minWidth: 200 }}
            disabled={loading}
          >
            <MenuItem value="" disabled>Select Driver</MenuItem>
            {drivers.map((d: Driver) => (
              <MenuItem key={d.id} value={d.id}>{d.name}</MenuItem>
            ))}
          </Select>
          <Button
            variant="contained"
            disabled={!selectedDriver || loading}
            onClick={handleAssignDriver}
          >
            Assign Driver
          </Button>
        </div>
      )}
      {route.status === 'Assigned' && (
        <Button variant="contained" color="primary" disabled={loading} onClick={handleStart} style={{ marginBottom: 24 }}>Start Route</Button>
      )}
      {route.status === 'InProgress' && (
        <Button variant="contained" color="success" disabled={loading} onClick={handleComplete} style={{ marginBottom: 24 }}>Complete Route</Button>
      )}
      <div style={{ marginTop: 24 }}>
        <Typography variant="h6" gutterBottom>Deliveries</Typography>
        <div style={{ display: 'grid', gridTemplateColumns: '60px 140px 180px 120px 120px', gap: 8, fontWeight: 600, marginBottom: 8 }}>
          <div>Stop</div>
          <div>Order Number</div>
          <div>Customer</div>
          <div>Time Slot</div>
          <div>Postal Code</div>
        </div>
        {route.deliveries.sort((a: Delivery, b: Delivery) => a.stopOrder - b.stopOrder).map((delivery: Delivery) => (
          <div key={delivery.id} style={{ display: 'grid', gridTemplateColumns: '60px 140px 180px 120px 120px', gap: 8, alignItems: 'center', borderBottom: '1px solid #eee', padding: '8px 0' }}>
            <div>{delivery.stopOrder}</div>
            <div>{delivery.orderNumber}</div>
            <div>{delivery.customerName}</div>
            <div>{delivery.timeSlot}</div>
            <div>{delivery.postalCode}</div>
          </div>
        ))}
      </div>
    </div>
  );
}
