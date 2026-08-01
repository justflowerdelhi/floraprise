import React, { useCallback, useEffect, useState } from 'react';
import type { RouteDetail, Driver, Delivery } from '../types/deliveryRouteTypes';
import { Alert, Button, Card, CardContent, Typography, Chip, Select, MenuItem, CircularProgress, IconButton, Dialog, DialogTitle, DialogContent, DialogActions, Stack, Box } from '@mui/material';
import ArrowUpwardIcon from '@mui/icons-material/ArrowUpward';
import ArrowDownwardIcon from '@mui/icons-material/ArrowDownward';
import MoreVertIcon from '@mui/icons-material/MoreVert';
import RouteIcon from '@mui/icons-material/Route';
import AccessTimeIcon from '@mui/icons-material/AccessTime';
import { useParams } from 'react-router-dom';
import { useToast } from '../hooks/useToast';
import { apiClient } from '../core/api/apiClient';

type DraftRouteOption = {
  id: string;
  name: string;
};

const fetchRouteDetail = async (routeId: string): Promise<RouteDetail> => {
  const res = await apiClient.get(`/delivery-routes/${routeId}`);
  return res.data as RouteDetail;
};
const fetchAvailableDrivers = async (): Promise<Driver[]> => {
  const res = await apiClient.get('/staff/available-drivers');
  return Array.isArray(res.data) ? res.data : res.data?.items ?? [];
};
const fetchDraftRoutes = async (date: string, excludeRouteId: string): Promise<DraftRouteOption[]> => {
  const res = await apiClient.get('/delivery-routes', { params: { date, status: 'Draft' } });
  const items = Array.isArray(res.data) ? res.data : res.data?.items ?? [];
  return items.filter((route: DraftRouteOption) => route.id !== excludeRouteId);
};
const reorderStop = async (routeId: string, stopId: string, newPosition: number): Promise<void> => {
  await apiClient.put(`/delivery-routes/${routeId}/reorder-stop`, {
    stopId,
    newPosition,
  });
};
const moveStop = async (routeId: string, stopId: string, targetRouteId: string): Promise<void> => {
  await apiClient.put(`/delivery-routes/${routeId}/move-stop`, {
    stopId,
    targetRouteId,
  });
};
const assignDriver = async (routeId: string, driverId: string): Promise<void> => {
  await apiClient.put(`/delivery-routes/${routeId}/assign-driver`, {
    driverId,
  });
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
  const [error, setError] = useState<string>('');
  const toast = useToast();
  const [moveModalOpen, setMoveModalOpen] = useState(false);
  const [moveStopId, setMoveStopId] = useState<string | null>(null);
  const [targetDraftRouteId, setTargetDraftRouteId] = useState<string>('');
  const [draftRoutes, setDraftRoutes] = useState<DraftRouteOption[]>([]);
  const [totalDistance, setTotalDistance] = useState<number>(0);
  const [expectedCompletion, setExpectedCompletion] = useState<string>('');

  const loadRoute = useCallback(async () => {
    setLoading(true);
    setError('');
    if (!routeId) {
      setLoading(false);
      return;
    }
    try {
      const data = await fetchRouteDetail(routeId);
      setRoute(data);

      // Calculate total distance and expected completion
      if (data.deliveries && data.deliveries.length > 0) {
        let distance = 0;
        const sortedDeliveries = [...data.deliveries].sort((a, b) => a.stopOrder - b.stopOrder);
        
        for (let i = 0; i < sortedDeliveries.length - 1; i++) {
          const current = sortedDeliveries[i];
          const next = sortedDeliveries[i + 1];
          if (current.latitude && current.longitude && next.latitude && next.longitude) {
            distance += calculateDistance(current.latitude, current.longitude, next.latitude, next.longitude);
          }
        }
        
        setTotalDistance(distance);
        
        // Estimate completion time (assuming 30 km/h average speed in city)
        const avgSpeedKph = 30;
        const travelTimeHours = distance / avgSpeedKph;
        const deliveryTimePerStop = 0.1; // 6 minutes per stop
        const totalDeliveryTime = sortedDeliveries.length * deliveryTimePerStop;
        const totalHours = travelTimeHours + totalDeliveryTime;
        
        const startTime = new Date();
        const completionTime = new Date(startTime.getTime() + totalHours * 60 * 60 * 1000);
        setExpectedCompletion(completionTime.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }));
      }
    } catch (err: any) {
      setRoute(null);
      setError(err?.response?.data?.message ?? err?.message ?? 'Failed to load route details.');
    } finally {
      setLoading(false);
    }
  }, [routeId]);

  // Haversine formula for distance calculation
  const calculateDistance = (lat1: number, lon1: number, lat2: number, lon2: number): number => {
    const R = 6371; // Earth's radius in km
    const dLat = (lat2 - lat1) * Math.PI / 180;
    const dLon = (lon2 - lon1) * Math.PI / 180;
    const a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
              Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
              Math.sin(dLon / 2) * Math.sin(dLon / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
  };

  useEffect(() => {
    loadRoute();
  }, [loadRoute]);

  useEffect(() => {
    if (route && route.status === 'Draft') {
      fetchAvailableDrivers()
        .then(setDrivers)
        .catch(() => {
          setDrivers([]);
          toast.error('Failed to load available drivers. Please refresh.');
        });
    }
  }, [route]);

  useEffect(() => {
    async function loadDraftRoutes() {
      if (route && route.status === 'Draft') {
        try {
          const routeDate = String(route.routeDate).slice(0, 10);
          const data = await fetchDraftRoutes(routeDate, route.id);
          setDraftRoutes(data);
        } catch {
          setDraftRoutes([]);
        }
      }
    }
    loadDraftRoutes();
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

  const handleReorder = async (stopId: string, newPosition: number) => {
    setLoading(true);
    try {
      if (!routeId) throw new Error('Missing routeId');
      await reorderStop(routeId, stopId, newPosition);
      toast.success('Stop reordered!');
      await loadRoute();
    } catch (e) {
      toast.error('Failed to reorder stop');
    }
    setLoading(false);
  };

  const handleMove = async () => {
    setLoading(true);
    try {
      if (!routeId || !moveStopId || !targetDraftRouteId) throw new Error('Missing info');
      await moveStop(routeId, moveStopId, targetDraftRouteId);
      toast.success('Stop moved!');
      setMoveModalOpen(false);
      setTargetDraftRouteId('');
      setMoveStopId(null);
      await loadRoute();
    } catch (e) {
      toast.error('Failed to move stop');
    }
    setLoading(false);
  };

  if (loading && !route) return <div style={{textAlign:'center',marginTop:40}}><CircularProgress /></div>;

  if (!route) {
    return (
      <div style={{ maxWidth: 800, margin: '40px auto', padding: 24 }}>
        <Alert severity="error">{error || 'Route not found.'}</Alert>
      </div>
    );
  }

  return (
    <div style={{ maxWidth: 800, margin: '0 auto', padding: 24 }}>
      {error && <Alert severity="error" style={{ marginBottom: 16 }}>{error}</Alert>}
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

      {/* Route Statistics */}
      <Card sx={{ mb: 3 }}>
        <CardContent>
          <Stack direction="row" spacing={4} alignItems="center">
            <Stack direction="row" spacing={1} alignItems="center">
              <RouteIcon color="action" />
              <Box>
                <Typography variant="caption" color="text.secondary">Total Distance</Typography>
                <Typography variant="body1" sx={{ fontWeight: 600 }}>
                  {totalDistance.toFixed(1)} km
                </Typography>
              </Box>
            </Stack>
            <Stack direction="row" spacing={1} alignItems="center">
              <AccessTimeIcon color="action" />
              <Box>
                <Typography variant="caption" color="text.secondary">Expected Completion</Typography>
                <Typography variant="body1" sx={{ fontWeight: 600 }}>
                  {expectedCompletion || '--:--'}
                </Typography>
              </Box>
            </Stack>
            <Stack direction="row" spacing={1} alignItems="center">
              <Typography variant="caption" color="text.secondary">Stops:</Typography>
              <Typography variant="body1" sx={{ fontWeight: 600 }}>
                {route.deliveries.length}
              </Typography>
            </Stack>
          </Stack>
        </CardContent>
      </Card>
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
        <div style={{ display: 'grid', gridTemplateColumns: '60px 140px 180px 120px 120px 120px 60px', gap: 8, fontWeight: 600, marginBottom: 8 }}>
          <div>Stop</div>
          <div>Order Number</div>
          <div>Customer</div>
          <div>Time Slot</div>
          <div>Postal Code</div>
          <div>Status</div>
          <div>Actions</div>
        </div>
        {route.deliveries.sort((a: Delivery, b: Delivery) => a.stopOrder - b.stopOrder).map((delivery: Delivery, idx: number, arr: Delivery[]) => {
          const isDraft = route.status === 'Draft';
          const isPending = delivery.status === 'Pending' || !['Delivered', 'Failed'].includes(delivery.status ?? 'Pending');
          const isFirst = idx === 0;
          const isLast = idx === arr.length - 1;
          const canMoveUp = isDraft && isPending && !isFirst && (arr[idx - 1].status ?? 'Pending') !== 'Delivered' && (arr[idx - 1].status ?? 'Pending') !== 'Failed';
          const canMoveDown = isDraft && isPending && !isLast && (arr[idx + 1].status ?? 'Pending') !== 'Delivered' && (arr[idx + 1].status ?? 'Pending') !== 'Failed';
          return (
            <div key={delivery.id} style={{ display: 'grid', gridTemplateColumns: '60px 140px 180px 120px 120px 120px 60px', gap: 8, alignItems: 'center', borderBottom: '1px solid #eee', padding: '8px 0' }}>
              <div>{delivery.stopOrder}</div>
              <div>{delivery.orderNumber}</div>
              <div>{delivery.customerName}</div>
              <div>{delivery.timeSlot}</div>
              <div>{delivery.postalCode}</div>
              <div>{delivery.status ?? 'Pending'}</div>
              <div style={{ display: 'flex', gap: 4 }}>
                {isDraft && isPending && (
                  <>
                    <IconButton size="small" disabled={!canMoveUp || loading} onClick={() => handleReorder(delivery.id, delivery.stopOrder - 1)}><ArrowUpwardIcon fontSize="small" /></IconButton>
                    <IconButton size="small" disabled={!canMoveDown || loading} onClick={() => handleReorder(delivery.id, delivery.stopOrder + 1)}><ArrowDownwardIcon fontSize="small" /></IconButton>
                    {draftRoutes.length > 0 && (
                      <>
                        <IconButton size="small" onClick={() => { setMoveModalOpen(true); setMoveStopId(delivery.id); }}><MoreVertIcon fontSize="small" /></IconButton>
                      </>
                    )}
                  </>
                )}
              </div>
            </div>
          );
        })}
        {/* Move modal */}
        <Dialog open={moveModalOpen} onClose={() => setMoveModalOpen(false)}>
          <DialogTitle>Move Stop to Another Draft Route</DialogTitle>
          <DialogContent>
            <Select
              value={targetDraftRouteId}
              onChange={e => setTargetDraftRouteId(e.target.value)}
              displayEmpty
              style={{ minWidth: 200 }}
            >
              <MenuItem value="" disabled>Select Route</MenuItem>
              {draftRoutes.map((r: DraftRouteOption) => (
                <MenuItem key={r.id} value={r.id}>{r.name}</MenuItem>
              ))}
            </Select>
          </DialogContent>
          <DialogActions>
            <Button onClick={() => setMoveModalOpen(false)} color="secondary">Cancel</Button>
            <Button onClick={handleMove} color="primary" disabled={!targetDraftRouteId || loading}>Move</Button>
          </DialogActions>
        </Dialog>
        {/* Route Locked badge for non-Draft */}
        {route.status !== 'Draft' && (
          <div style={{ marginTop: 16 }}>
            <Chip label="Route Locked" color="warning" />
          </div>
        )}
      </div>
    </div>
  );
}
