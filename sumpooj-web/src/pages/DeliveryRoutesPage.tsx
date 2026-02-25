
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
import { Button, TextField, Card, CardContent, Typography, Chip, Grid, CircularProgress, Table, TableBody, TableCell, TableHead, TableRow, Dialog, DialogTitle, DialogContent, DialogActions } from '@mui/material';
import { useToast } from '../hooks/useToast';
  // Generate Suggested Routes state
  const [generating, setGenerating] = useState(false);
  const [confirmOpen, setConfirmOpen] = useState(false);
  // Generate Suggested Routes handler
  const handleGenerateSuggestedRoutes = async () => {
    if (unassignedDeliveries.length === 0) {
      toast.warning('No unassigned deliveries available for route generation.');
      return;
    }
    if (draftRoutesCount > 0) {
      setConfirmOpen(true);
      return;
    }
    await generateRoutes();
  };

  // Confirm modal handler
  const handleConfirmGenerate = async () => {
    setConfirmOpen(false);
    await generateRoutes();
  };

  // Actual API call
  const generateRoutes = async () => {
    setGenerating(true);
    try {
      const res = await fetch('/api/delivery-routes/generate', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ date: selectedDate })
      });
      if (!res.ok) throw new Error('Failed to generate routes');
      await res.json();
      await fetchRoutes(selectedDate);
      await fetchUnassignedDeliveries(selectedDate);
      toast.success('Suggested routes generated successfully.');
    } catch (e) {
      toast.error('Failed to generate suggested routes');
    }
    setGenerating(false);
  };

export default function DeliveryRoutesPage() {
  // State
  const [selectedDate, setSelectedDate] = useState<string>(new Date().toISOString().slice(0, 10));
  const [routes, setRoutes] = useState<any[]>([]);
  const [unassignedDeliveries, setUnassignedDeliveries] = useState<any[]>([]);
  const [selectedRouteId, setSelectedRouteId] = useState<string | null>(null);
  const [loadingRoutes, setLoadingRoutes] = useState(false);
  const [loadingUnassigned, setLoadingUnassigned] = useState(false);
  const toast = useToast();

  // Fetch routes
  const fetchRoutes = async (date: string) => {
    setLoadingRoutes(true);
    try {
      const res = await fetch(`/api/delivery-routes?date=${date}`);
      const data = await res.json();
      setRoutes(data);
    } catch (e) {
      toast.error('Failed to load routes');
      setRoutes([]);
    }
    setLoadingRoutes(false);
  };

  // Fetch unassigned deliveries
  const fetchUnassignedDeliveries = async (date: string) => {
    setLoadingUnassigned(true);
    try {
      const res = await fetch(`/api/delivery-routes/unassigned?date=${date}`);
      const data = await res.json();
      setUnassignedDeliveries(data);
    } catch (e) {
      toast.error('Failed to load unassigned deliveries');
      setUnassignedDeliveries([]);
    }
    setLoadingUnassigned(false);
  };

  // Refetch on date change
  useEffect(() => {
    fetchRoutes(selectedDate);
    fetchUnassignedDeliveries(selectedDate);
    setSelectedRouteId(null);
  }, [selectedDate]);

  // KPI calculations
  const totalDeliveries = routes.reduce((acc, r) => acc + (r.deliveries?.length || 0), 0) + unassignedDeliveries.length;
  const unassignedCount = unassignedDeliveries.length;
  const draftRoutesCount = routes.filter(r => r.status === 'Draft').length;
  const assignedRoutesCount = routes.filter(r => r.status === 'Assigned').length;

  // UI
  return (
    <Grid container spacing={3} sx={{ p: 3 }}>
      {/* Section A: Header Control Panel */}
      <Grid item xs={12}>
        <Grid container spacing={2} alignItems="center">
          <Grid item>
            <TextField
              label="Date"
              type="date"
              value={selectedDate}
              onChange={e => setSelectedDate(e.target.value)}
              InputLabelProps={{ shrink: true }}
            />
          </Grid>
          <Grid item xs>
            <Grid container spacing={2}>
              <Grid item>
                <Card sx={{ minWidth: 180 }}>
                  <CardContent>
                    <Typography variant="subtitle2">Total Deliveries</Typography>
                    <Typography variant="h5">{totalDeliveries}</Typography>
                  </CardContent>
                </Card>
              </Grid>
              <Grid item>
                <Card sx={{ minWidth: 180 }}>
                  <CardContent>
                    <Typography variant="subtitle2">Unassigned Deliveries</Typography>
                    <Typography variant="h5">{unassignedCount}</Typography>
                  </CardContent>
                </Card>
              </Grid>
              <Grid item>
                <Card sx={{ minWidth: 180 }}>
                  <CardContent>
                    <Typography variant="subtitle2">Draft Routes</Typography>
                    <Typography variant="h5">{draftRoutesCount}</Typography>
                  </CardContent>
                </Card>
              </Grid>
              <Grid item>
                <Card sx={{ minWidth: 180 }}>
                  <CardContent>
                    <Typography variant="subtitle2">Assigned Routes</Typography>
                    <Typography variant="h5">{assignedRoutesCount}</Typography>
                  </CardContent>
                </Card>
              </Grid>
            </Grid>
          </Grid>
          <Grid item>
            <Button
              variant="contained"
              color="primary"
              sx={{ mr: 2 }}
              onClick={handleGenerateSuggestedRoutes}
              disabled={generating}
            >
              {generating ? <CircularProgress size={24} /> : 'Generate Suggested Routes'}
            </Button>
                  {/* Confirmation Modal for Regenerate */}
                  <Dialog open={confirmOpen} onClose={() => setConfirmOpen(false)}>
                    <DialogTitle>Draft routes already exist</DialogTitle>
                    <DialogContent>
                      <Typography>Draft routes already exist. Regenerate and overwrite?</Typography>
                    </DialogContent>
                    <DialogActions>
                      <Button onClick={() => setConfirmOpen(false)} color="secondary">Cancel</Button>
                      <Button onClick={handleConfirmGenerate} color="primary" autoFocus disabled={generating}>
                        {generating ? <CircularProgress size={20} /> : 'Regenerate'}
                      </Button>
                    </DialogActions>
                  </Dialog>
            <Button variant="outlined" color="secondary" onClick={() => toast.info('Create Manual Route (placeholder)')}>Create Manual Route</Button>
          </Grid>
        </Grid>
      </Grid>

      {/* Section B: Routes Panel */}
      <Grid item xs={12}>
        <Grid container spacing={2}>
          {/* Left Column: Draft Routes */}
          <Grid item xs={12} md={5}>
            <Typography variant="h6" sx={{ mb: 2 }}>Draft Routes</Typography>
            {loadingRoutes ? <CircularProgress /> : (
              routes.filter(r => r.status === 'Draft').length === 0 ? (
                <Typography color="text.secondary">No draft routes found.</Typography>
              ) : (
                routes.filter(r => r.status === 'Draft').map(route => (
                  <Card key={route.id} sx={{ mb: 2, cursor: 'pointer', border: selectedRouteId === route.id ? '2px solid #1976d2' : '1px solid #eee' }} onClick={() => setSelectedRouteId(route.id)}>
                    <CardContent>
                      <Typography variant="subtitle1">{route.name}</Typography>
                      <Typography variant="body2">Stops: {route.deliveries?.length || 0}</Typography>
                      <Chip label={route.status} color="default" size="small" sx={{ mt: 1, mr: 1 }} />
                      {route.codTotal !== undefined && (
                        <Chip label={`COD: $${route.codTotal}`} color="warning" size="small" sx={{ mt: 1 }} />
                      )}
                    </CardContent>
                  </Card>
                ))
              )
            )}
          </Grid>

          {/* Right Column: Route Details */}
          <Grid item xs={12} md={7}>
            <Typography variant="h6" sx={{ mb: 2 }}>Route Details</Typography>
            {selectedRouteId ? (
              (() => {
                const route = routes.find(r => r.id === selectedRouteId);
                if (!route || !route.deliveries || route.deliveries.length === 0) {
                  return <Typography color="text.secondary">No stops found for this route.</Typography>;
                }
                return (
                  <Table size="small">
                    <TableHead>
                      <TableRow>
                        <TableCell>Stop Order</TableCell>
                        <TableCell>Order Number</TableCell>
                        <TableCell>Customer Name</TableCell>
                        <TableCell>Time Window</TableCell>
                        <TableCell>Postal Code</TableCell>
                        <TableCell>Stop Status</TableCell>
                      </TableRow>
                    </TableHead>
                    <TableBody>
                      {route.deliveries.map((stop: any, idx: number) => (
                        <TableRow key={stop.id}>
                          <TableCell>{stop.stopOrder ?? idx + 1}</TableCell>
                          <TableCell>{stop.orderNumber}</TableCell>
                          <TableCell>{stop.customerName}</TableCell>
                          <TableCell>{stop.timeSlot}</TableCell>
                          <TableCell>{stop.postalCode}</TableCell>
                          <TableCell>{stop.status ?? 'Pending'}</TableCell>
                        </TableRow>
                      ))}
                    </TableBody>
                  </Table>
                );
              })()
            ) : (
              <Typography color="text.secondary">Select a route to view details.</Typography>
            )}
          </Grid>
        </Grid>
      </Grid>

      {/* Section C: Unassigned Deliveries */}
      <Grid item xs={12}>
        <Typography variant="h6" sx={{ mb: 2 }}>Unassigned Deliveries</Typography>
        {loadingUnassigned ? <CircularProgress /> : (
          <Table size="small" sx={{ maxHeight: 300, overflowY: 'auto', display: 'block' }}>
            <TableHead>
              <TableRow>
                <TableCell>Order Number</TableCell>
                <TableCell>Customer Name</TableCell>
                <TableCell>Time Window</TableCell>
                <TableCell>Postal Code</TableCell>
                <TableCell>Priority</TableCell>
                <TableCell>Action</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {unassignedDeliveries.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={6} align="center">No unassigned deliveries found.</TableCell>
                </TableRow>
              ) : (
                unassignedDeliveries.map((delivery: any) => (
                  <TableRow key={delivery.id}>
                    <TableCell>{delivery.orderNumber}</TableCell>
                    <TableCell>{delivery.customerName}</TableCell>
                    <TableCell>{delivery.timeSlot}</TableCell>
                    <TableCell>{delivery.postalCode}</TableCell>
                    <TableCell>
                      <Chip label={delivery.priority ?? 'Normal'} color={delivery.priority === 'High' ? 'error' : 'default'} size="small" />
                    </TableCell>
                    <TableCell>
                      <Button variant="outlined" size="small" disabled>Assign</Button>
                    </TableCell>
                  </TableRow>
                ))
              )}
            </TableBody>
          </Table>
        )}
      </Grid>
    </Grid>
  );
}
