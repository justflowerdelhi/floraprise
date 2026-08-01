/**
 * DeliveryWorkspace.tsx — Single page delivery workspace
 * 
 * Features:
 * - Order, customer, phone, address, assigned driver, ETA, current status
 * - Tabs: Overview, Timeline, Tracking, Proof, Notes
 * - Quick actions: Assign Driver, Reassign, Start Delivery, Mark Arrived, Complete, Cancel
 */
import React, { useState, useEffect } from 'react';
import {
  Box, Typography, Paper, Tabs, Tab, Chip, Stack,
  Avatar, IconButton, Tooltip, Divider, useTheme, alpha,
  Card, CardContent, Button, Grid, LinearProgress
} from '@mui/material';
import {
  Phone, LocationOn, Schedule, LocalShipping, Person,
  Edit, CheckCircle, Cancel, PlayArrow, Navigation, AccessTime
} from '@mui/icons-material';
import { useParams, useNavigate } from 'react-router-dom';

interface TabPanelProps {
  children?: React.ReactNode;
  index: number;
  value: number;
}

interface DeliveryData {
  orderId: string;
  orderNumber: string;
  customerName: string;
  customerPhone: string;
  deliveryAddress: string;
  timeSlot: string;
  assignedDriver: string;
  driverPhone: string;
  eta: string;
  status: string;
  routeId?: string;
  routeName?: string;
  stopOrder?: number;
}

interface TimelineEvent {
  status: string;
  note?: string;
  timestamp: string;
  changedBy?: string;
}

interface LocationPoint {
  latitude: number;
  longitude: number;
  timestamp: string;
  speedKph?: number;
}

interface ProofData {
  photoUrl?: string;
  recipientName?: string;
  note?: string;
  timestamp?: string;
  signature?: string;
}

function TabPanel(props: TabPanelProps) {
  const { children, value, index, ...other } = props;
  return (
    <div role="tabpanel" hidden={value !== index} {...other}>
      {value === index && <Box sx={{ p: 3 }}>{children}</Box>}
    </div>
  );
}

export default function DeliveryWorkspace() {
  const theme = useTheme();
  const navigate = useNavigate();
  const { deliveryId } = useParams<{ deliveryId: string }>();
  const [tabValue, setTabValue] = useState(0);
  const [loading, setLoading] = useState(true);
  const [data, setData] = useState<DeliveryData | null>(null);
  const [timeline, setTimeline] = useState<TimelineEvent[]>([]);
  const [locations, setLocations] = useState<LocationPoint[]>([]);
  const [proof, setProof] = useState<ProofData | null>(null);
  const [notes, setNotes] = useState<string>('');

  const fetchDeliveryData = async () => {
    if (!deliveryId) return;
    setLoading(true);
    try {
      // Fetch delivery data
      const response = await fetch(`/api/delivery/tracking/by-delivery/${deliveryId}`);
      if (response.ok) {
        const trackingData = await response.json();
        setData(trackingData);
        setTimeline(trackingData.timeline || []);
        setLocations(trackingData.route || []);
        setProof(trackingData.proof || null);
      }
    } catch (err) {
      console.error('Failed to fetch delivery data:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchDeliveryData();
    // Refresh every 30 seconds
    const interval = setInterval(fetchDeliveryData, 30000);
    return () => clearInterval(interval);
  }, [deliveryId]);

  return (
    <Box sx={{ p: 3 }}>
      {/* Header */}
      <Paper sx={{ p: 3, mb: 3 }}>
        <Box sx={{ display: 'flex', flexDirection: { xs: 'column', md: 'row' }, gap: 3 }}>
          <Box sx={{ flex: 1 }}>
            <Stack spacing={2}>
              <Stack direction="row" alignItems="center" spacing={2}>
                <Typography variant="h4" sx={{ fontWeight: 700 }}>
                  Order #ORD-001
                </Typography>
                <Chip label="Out for Delivery" color="info" />
              </Stack>
              <Stack direction="row" spacing={3} alignItems="center" flexWrap="wrap">
                <Stack direction="row" spacing={1} alignItems="center">
                  <Person color="action" />
                  <Typography variant="body2">John Doe</Typography>
                </Stack>
                <Stack direction="row" spacing={1} alignItems="center">
                  <Phone color="action" />
                  <Typography variant="body2">+1 234 567 8900</Typography>
                </Stack>
                <Stack direction="row" spacing={1} alignItems="center">
                  <LocationOn color="action" />
                  <Typography variant="body2">123 Main St, City, State 12345</Typography>
                </Stack>
              </Stack>
            </Stack>
          </Box>
          <Box sx={{ minWidth: { md: 300 } }}>
            <Stack spacing={2}>
              <Stack direction="row" justifyContent="space-between">
                <Typography variant="body2" color="text.secondary">Assigned Driver</Typography>
                <Typography variant="body2" sx={{ fontWeight: 600 }}>Mike Johnson</Typography>
              </Stack>
              <Stack direction="row" justifyContent="space-between">
                <Typography variant="body2" color="text.secondary">ETA</Typography>
                <Typography variant="body2" sx={{ fontWeight: 600 }}>15 mins</Typography>
              </Stack>
              <Stack direction="row" justifyContent="space-between">
                <Typography variant="body2" color="text.secondary">Current Status</Typography>
                <Chip label="Out for Delivery" size="small" color="info" />
              </Stack>
            </Stack>
          </Box>
        </Box>
      </Paper>

      {/* Quick Actions */}
      <Paper sx={{ p: 2, mb: 3 }}>
        <Stack direction="row" spacing={2} flexWrap="wrap">
          <Button variant="outlined" startIcon={<Person />}>
            Assign Driver
          </Button>
          <Button variant="outlined" startIcon={<Edit />}>
            Reassign
          </Button>
          <Button variant="contained" startIcon={<PlayArrow />}>
            Start Delivery
          </Button>
          <Button variant="contained" color="success" startIcon={<CheckCircle />}>
            Mark Arrived
          </Button>
          <Button variant="contained" color="primary" startIcon={<CheckCircle />}>
            Complete
          </Button>
          <Button variant="outlined" color="error" startIcon={<Cancel />}>
            Cancel
          </Button>
        </Stack>
      </Paper>

      {/* Tabs */}
      <Paper>
        <Tabs value={tabValue} onChange={(e, v) => setTabValue(v)}>
          <Tab label="Overview" />
          <Tab label="Timeline" />
          <Tab label="Tracking" />
          <Tab label="Proof" />
          <Tab label="Notes" />
        </Tabs>
        <Divider />

        <TabPanel value={tabValue} index={0}>
          <Typography variant="h6" sx={{ mb: 2 }}>Delivery Overview</Typography>
          {data ? (
            <Stack spacing={2}>
              <Card>
                <CardContent>
                  <Typography variant="subtitle2" color="text.secondary" sx={{ mb: 1 }}>Order Information</Typography>
                  <Stack spacing={1}>
                    <Stack direction="row" justifyContent="space-between">
                      <Typography variant="body2">Order Number:</Typography>
                      <Typography variant="body2" sx={{ fontWeight: 600 }}>{data.orderNumber}</Typography>
                    </Stack>
                    <Stack direction="row" justifyContent="space-between">
                      <Typography variant="body2">Customer:</Typography>
                      <Typography variant="body2" sx={{ fontWeight: 600 }}>{data.customerName}</Typography>
                    </Stack>
                    <Stack direction="row" justifyContent="space-between">
                      <Typography variant="body2">Phone:</Typography>
                      <Typography variant="body2" sx={{ fontWeight: 600 }}>{data.customerPhone}</Typography>
                    </Stack>
                  </Stack>
                </CardContent>
              </Card>
              <Card>
                <CardContent>
                  <Typography variant="subtitle2" color="text.secondary" sx={{ mb: 1 }}>Delivery Information</Typography>
                  <Stack spacing={1}>
                    <Stack direction="row" justifyContent="space-between">
                      <Typography variant="body2">Address:</Typography>
                      <Typography variant="body2" sx={{ fontWeight: 600 }}>{data.deliveryAddress}</Typography>
                    </Stack>
                    <Stack direction="row" justifyContent="space-between">
                      <Typography variant="body2">Time Slot:</Typography>
                      <Typography variant="body2" sx={{ fontWeight: 600 }}>{data.timeSlot}</Typography>
                    </Stack>
                    {data.routeName && (
                      <Stack direction="row" justifyContent="space-between">
                        <Typography variant="body2">Route:</Typography>
                        <Typography variant="body2" sx={{ fontWeight: 600 }}>{data.routeName}</Typography>
                      </Stack>
                    )}
                    {data.stopOrder && (
                      <Stack direction="row" justifyContent="space-between">
                        <Typography variant="body2">Stop Order:</Typography>
                        <Typography variant="body2" sx={{ fontWeight: 600 }}>#{data.stopOrder}</Typography>
                      </Stack>
                    )}
                  </Stack>
                </CardContent>
              </Card>
            </Stack>
          ) : (
            <Typography color="text.secondary">Loading...</Typography>
          )}
        </TabPanel>

        <TabPanel value={tabValue} index={1}>
          <Typography variant="h6" sx={{ mb: 2 }}>Delivery Timeline</Typography>
          {timeline.length > 0 ? (
            <Stack spacing={2}>
              {timeline.map((event, index) => (
                <Stack key={index} spacing={1}>
                  <Stack direction="row" spacing={2} alignItems="center">
                    <Box
                      sx={{
                        width: 12,
                        height: 12,
                        borderRadius: '50%',
                        bgcolor: index === 0 ? theme.palette.primary.main : theme.palette.grey[400]
                      }}
                    />
                    <Box sx={{ flex: 1 }}>
                      <Typography variant="body2" sx={{ fontWeight: 600 }}>
                        {event.status}
                      </Typography>
                      <Typography variant="caption" color="text.secondary">
                        {new Date(event.timestamp).toLocaleString()}
                      </Typography>
                      {event.changedBy && (
                        <Typography variant="caption" color="text.secondary" sx={{ ml: 1 }}>
                          by {event.changedBy}
                        </Typography>
                      )}
                      {event.note && (
                        <Typography variant="body2" color="text.secondary" sx={{ mt: 0.5 }}>
                          {event.note}
                        </Typography>
                      )}
                    </Box>
                  </Stack>
                  {index < timeline.length - 1 && (
                    <Box sx={{ height: 20, width: 2, bgcolor: theme.palette.divider, ml: 5 }} />
                  )}
                </Stack>
              ))}
            </Stack>
          ) : (
            <Typography color="text.secondary">No timeline events yet</Typography>
          )}
        </TabPanel>

        <TabPanel value={tabValue} index={2}>
          <Typography variant="h6" sx={{ mb: 2 }}>Live Tracking</Typography>
          <Box
            sx={{
              height: 400,
              bgcolor: alpha(theme.palette.primary.main, 0.1),
              borderRadius: 2,
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center'
            }}
          >
            <Stack alignItems="center" spacing={2}>
              <LocalShipping sx={{ fontSize: 48, color: theme.palette.primary.main }} />
              <Typography variant="body2" color="text.secondary">
                Live map coming soon
              </Typography>
              {locations.length > 0 && (
                <Typography variant="caption" color="text.secondary">
                  {locations.length} location points recorded
                </Typography>
              )}
            </Stack>
          </Box>
        </TabPanel>

        <TabPanel value={tabValue} index={3}>
          <Typography variant="h6" sx={{ mb: 2 }}>Delivery Proof</Typography>
          {proof ? (
            <Stack spacing={2}>
              {proof.photoUrl && (
                <Box
                  component="img"
                  src={proof.photoUrl}
                  alt="Delivery Proof"
                  sx={{
                    width: '100%',
                    maxHeight: 300,
                    objectFit: 'contain',
                    borderRadius: 2
                  }}
                />
              )}
              <Card>
                <CardContent>
                  <Stack spacing={2}>
                    {proof.recipientName && (
                      <Stack direction="row" spacing={2}>
                        <Person color="action" />
                        <Typography variant="body2">
                          Received by: {proof.recipientName}
                        </Typography>
                      </Stack>
                    )}
                    {proof.note && (
                      <Typography variant="body2" color="text.secondary">
                        Note: {proof.note}
                      </Typography>
                    )}
                    {proof.timestamp && (
                      <Stack direction="row" spacing={1} alignItems="center">
                        <AccessTime fontSize="small" color="action" />
                        <Typography variant="caption" color="text.secondary">
                          Delivered at {new Date(proof.timestamp).toLocaleString()}
                        </Typography>
                      </Stack>
                    )}
                  </Stack>
                </CardContent>
              </Card>
            </Stack>
          ) : (
            <Typography color="text.secondary">No proof of delivery yet</Typography>
          )}
        </TabPanel>

        <TabPanel value={tabValue} index={4}>
          <Typography variant="h6" sx={{ mb: 2 }}>Notes</Typography>
          <Stack spacing={2}>
            <Typography variant="body2" color="text.secondary">
              Add notes about this delivery
            </Typography>
            <textarea
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              placeholder="Enter delivery notes..."
              style={{
                width: '100%',
                minHeight: 150,
                padding: 12,
                borderRadius: 8,
                border: `1px solid ${theme.palette.divider}`,
                fontFamily: 'inherit',
                fontSize: 14
              }}
            />
            <Button variant="contained" onClick={() => {/* TODO: Save notes */}}>
              Save Notes
            </Button>
          </Stack>
        </TabPanel>
      </Paper>
    </Box>
  );
}
