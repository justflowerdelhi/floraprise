import React, { useEffect, useState } from 'react';
import type { RouteDetail, Driver, Delivery } from '../types/deliveryRouteTypes';
import { Button, Card, CardContent, Typography, Chip, Select, MenuItem, CircularProgress, IconButton, Dialog, DialogTitle, DialogContent, DialogActions } from '@mui/material';
import ArrowUpwardIcon from '@mui/icons-material/ArrowUpward';
import ArrowDownwardIcon from '@mui/icons-material/ArrowDownward';
import MoreVertIcon from '@mui/icons-material/MoreVert';
// ...existing code...
// Reorder stop API
const reorderStop = async (routeId: string, stopId: string, newPosition: number): Promise<void> => {
  await fetch(`/api/delivery-routes/${routeId}/reorder-stop`, {
    method: 'PUT',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ stopId, newPosition })
  });
};
// Move stop API
const moveStop = async (routeId: string, stopId: string, targetRouteId: string): Promise<void> => {
  await fetch(`/api/delivery-routes/${routeId}/move-stop`, {
    method: 'PUT',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ stopId, targetRouteId })
  });
};
  // Move modal state
  const [moveModalOpen, setMoveModalOpen] = useState(false);
  const [moveStopId, setMoveStopId] = useState<string | null>(null);
  const [targetDraftRouteId, setTargetDraftRouteId] = useState<string>('');
  const [draftRoutes, setDraftRoutes] = useState<RouteDetail[]>([]);
  // Fetch all draft routes for move dropdown
  useEffect(() => {
    async function fetchDraftRoutes() {
      if (route && route.status === 'Draft') {
        const res = await fetch(`/api/delivery-routes?date=${route.routeDate}&status=Draft`);
        const data = await res.json();
        setDraftRoutes(data.filter((r: RouteDetail) => r.id !== route.id));
      }
    }
    fetchDraftRoutes();
  }, [route]);
  // Reorder handler
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

  // Move handler
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
import { useParams } from 'react-router-dom';
import { useToast } from '../hooks/useToast';

const fetchRouteDetail = async (routeId: string): Promise<RouteDetail> => {
  const res = await fetch(`/api/delivery-routes/${routeId}`);
  return await res.json() as RouteDetail;
};
const fetchAvailableDrivers = async (): Promise<Driver[]> => {
  const res = await fetch('/api/staff/available-drivers');
  return await res.json();
};
const assignDriver = async (routeId: string, driverId: string): Promise<void> => {
  await fetch(`/api/delivery-routes/${routeId}/assign-driver`, {
    method: 'PUT',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ driverId })
  });
};
const startRoute = async (routeId: string): Promise<void> => {
  await fetch(`/api/delivery-routes/${routeId}/start`, { method: 'PUT' });
};
const completeRoute = async (routeId: string): Promise<void> => {
  await fetch(`/api/delivery-routes/${routeId}/complete`, { method: 'PUT' });
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
          const isPending = delivery.status === 'Pending' || !['Delivered', 'Failed'].includes(delivery.status);
          const isFirst = idx === 0;
          const isLast = idx === arr.length - 1;
          const canMoveUp = isDraft && isPending && !isFirst && arr[idx - 1].status !== 'Delivered' && arr[idx - 1].status !== 'Failed';
          const canMoveDown = isDraft && isPending && !isLast && arr[idx + 1].status !== 'Delivered' && arr[idx + 1].status !== 'Failed';
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
              {draftRoutes.map((r: RouteDetail) => (
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
