/**
 * PublicTrackingPage.tsx — Customer-facing delivery tracking page
 * 
 * Features:
 * - No authentication required
 * - Business logo
 * - Order number
 * - Current status
 * - ETA
 * - Driver first name
 * - Live map
 * - Timeline
 * - Delivery proof after completion
 */
import React, { useState, useEffect, useCallback } from 'react';
import {
  Box, Typography, Paper, Chip, Stack, Avatar, Card,
  CardContent, LinearProgress, useTheme, alpha, CircularProgress,
  Alert, Divider, Button, IconButton
} from '@mui/material';
import {
  LocalShipping, CheckCircle, Schedule, Person,
  Phone, LocationOn, AccessTime, Refresh, DirectionsCar
} from '@mui/icons-material';
import { useParams } from 'react-router-dom';
import { GoogleMap, LoadScript, Marker, Polyline } from '@react-google-maps/api';

interface TrackingData {
  orderId: string;
  orderNumber: string;
  customerName: string;
  deliveryAddress: string;
  timeSlot: string;
  status: string;
  tracking: {
    driverName?: string;
    driverPhone?: string;
    driverPhoto?: string;
    lastLocation?: {
      latitude: number;
      longitude: number;
      accuracy: number;
      speed: number;
      heading: number;
      timestamp: string;
    };
    destination?: {
      latitude: number;
      longitude: number;
    };
    eta?: string;
    remainingDistanceKm?: number;
    route?: Array<{
      latitude: number;
      longitude: number;
      timestamp: string;
    }>;
    timeline?: Array<{
      status: string;
      note?: string;
      timestamp: string;
      changedBy?: string;
    }>;
    proof?: {
      photoUrl?: string;
      recipientName?: string;
      note?: string;
      timestamp?: string;
    };
  };
}

export default function PublicTrackingPage() {
  const theme = useTheme();
  const { token } = useParams<{ token: string }>();
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [data, setData] = useState<TrackingData | null>(null);
  const [isMapLoaded, setIsMapLoaded] = useState(false);

  const fetchTrackingData = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const response = await fetch(`/api/public/tracking/${token}`);
      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.error || 'Failed to fetch tracking data');
      }
      const trackingData = await response.json();
      setData(trackingData);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Unknown error');
    } finally {
      setLoading(false);
    }
  }, [token]);

  useEffect(() => {
    if (token) {
      fetchTrackingData();
      // Refresh every 15 seconds for live updates
      const interval = setInterval(fetchTrackingData, 15000);
      return () => clearInterval(interval);
    }
  }, [token, fetchTrackingData]);

  const getStatusColor = (status: string) => {
    switch (status.toLowerCase()) {
      case 'scheduled':
        return 'default';
      case 'outfordelivery':
        return 'info';
      case 'delivered':
        return 'success';
      case 'failed':
        return 'error';
      case 'cancelled':
        return 'default';
      default:
        return 'default';
    }
  };

  const getStatusLabel = (status: string) => {
    switch (status.toLowerCase()) {
      case 'scheduled':
        return 'Scheduled';
      case 'outfordelivery':
        return 'Out for Delivery';
      case 'delivered':
        return 'Delivered';
      case 'failed':
        return 'Failed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  };

  if (loading) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', minHeight: '100vh' }}>
        <Stack alignItems="center" spacing={2}>
          <CircularProgress />
          <Typography variant="body2" color="text.secondary">
            Loading tracking information...
          </Typography>
        </Stack>
      </Box>
    );
  }

  if (error) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', minHeight: '100vh', p: 3 }}>
        <Alert severity="error" sx={{ maxWidth: 500 }}>
          {error}
        </Alert>
      </Box>
    );
  }

  if (!data) return null;

  const isDelivered = data.status.toLowerCase() === 'delivered';

  return (
    <Box sx={{ minHeight: '100vh', bgcolor: alpha(theme.palette.primary.main, 0.05) }}>
      {/* Header */}
      <Paper sx={{ p: 3, bgcolor: 'white', borderBottom: 1, borderColor: 'divider' }}>
        <Stack direction="row" justifyContent="space-between" alignItems="center">
          <Stack direction="row" alignItems="center" spacing={2}>
            <Avatar sx={{ bgcolor: theme.palette.primary.main }}>
              <LocalShipping />
            </Avatar>
            <Box>
              <Typography variant="h6" sx={{ fontWeight: 700 }}>
                Floraprise Delivery Tracking
              </Typography>
              <Typography variant="caption" color="text.secondary">
                Order #{data.orderNumber}
              </Typography>
            </Box>
          </Stack>
          <IconButton onClick={fetchTrackingData}>
            <Refresh />
          </IconButton>
        </Stack>
      </Paper>

      <Box sx={{ p: 3, maxWidth: 800, mx: 'auto' }}>
        {/* Status Card */}
        <Card sx={{ mb: 3 }}>
          <CardContent>
            <Stack spacing={3}>
              <Stack direction="row" justifyContent="space-between" alignItems="center">
                <Typography variant="h5" sx={{ fontWeight: 700 }}>
                  {isDelivered ? 'Delivered!' : 'On the Way'}
                </Typography>
                <Chip
                  label={getStatusLabel(data.status)}
                  color={getStatusColor(data.status) as any}
                  size="medium"
                />
              </Stack>

              <Divider />

              <Stack spacing={2}>
                <Stack direction="row" spacing={2} alignItems="center">
                  <Person color="action" />
                  <Box>
                    <Typography variant="caption" color="text.secondary">Customer</Typography>
                    <Typography variant="body1">{data.customerName}</Typography>
                  </Box>
                </Stack>

                <Stack direction="row" spacing={2} alignItems="center">
                  <LocationOn color="action" />
                  <Box>
                    <Typography variant="caption" color="text.secondary">Delivery Address</Typography>
                    <Typography variant="body1">{data.deliveryAddress}</Typography>
                  </Box>
                </Stack>

                <Stack direction="row" spacing={2} alignItems="center">
                  <Schedule color="action" />
                  <Box>
                    <Typography variant="caption" color="text.secondary">Time Slot</Typography>
                    <Typography variant="body1">{data.timeSlot}</Typography>
                  </Box>
                </Stack>
              </Stack>

              {/* Driver Info */}
              {data.tracking.driverName && !isDelivered && (
                <>
                  <Divider />
                  <Stack spacing={2}>
                    <Typography variant="h6" sx={{ fontWeight: 600 }}>
                      Your Driver
                    </Typography>
                    <Stack direction="row" spacing={2} alignItems="center">
                      <Avatar sx={{ bgcolor: theme.palette.secondary.main }}>
                        {data.tracking.driverName.charAt(0)}
                      </Avatar>
                      <Box>
                        <Typography variant="body1" sx={{ fontWeight: 600 }}>
                          {data.tracking.driverName}
                        </Typography>
                        {data.tracking.driverPhone && (
                          <Stack direction="row" spacing={1} alignItems="center">
                            <Phone fontSize="small" color="action" />
                            <Typography variant="body2" color="text.secondary">
                              {data.tracking.driverPhone}
                            </Typography>
                          </Stack>
                        )}
                      </Box>
                    </Stack>
                  </Stack>
                </>
              )}
            </Stack>
          </CardContent>
        </Card>

        {/* Live Map */}
        {!isDelivered && data.tracking.lastLocation && (
          <Card sx={{ mb: 3 }}>
            <CardContent>
              <Stack direction="row" justifyContent="space-between" alignItems="center" sx={{ mb: 2 }}>
                <Typography variant="h6" sx={{ fontWeight: 600 }}>
                  Live Tracking
                </Typography>
                {data.tracking.eta && (
                  <Chip
                    icon={<AccessTime />}
                    label={`ETA: ${data.tracking.eta}`}
                    color="primary"
                    size="small"
                  />
                )}
              </Stack>
              <Box sx={{ height: 300, borderRadius: 2, overflow: 'hidden' }}>
                <LoadScript
                  googleMapsApiKey={process.env.REACT_APP_GOOGLE_MAPS_API_KEY || ''}
                  onLoad={() => setIsMapLoaded(true)}
                >
                  {isMapLoaded && (
                    <GoogleMap
                      mapContainerStyle={{ width: '100%', height: '100%' }}
                      center={{
                        lat: data.tracking.lastLocation!.latitude,
                        lng: data.tracking.lastLocation!.longitude
                      }}
                      zoom={14}
                      options={{
                        streetViewControl: false,
                        mapTypeControl: false,
                        fullscreenControl: false,
                      }}
                    >
                      {/* Driver Marker */}
                      {data.tracking.lastLocation && (
                        <Marker
                          position={{
                            lat: data.tracking.lastLocation.latitude,
                            lng: data.tracking.lastLocation.longitude
                          }}
                          icon={{
                            path: 'M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7zm0 9.5c-1.38 0-2.5-1.12-2.5-2.5s1.12-2.5 2.5-2.5 2.5 1.12 2.5 2.5-1.12 2.5-2.5 2.5z',
                            fillColor: '#2196f3',
                            fillOpacity: 1,
                            strokeColor: '#ffffff',
                            strokeWeight: 2,
                            scale: 1.5,
                            anchor: new google.maps.Point(12, 24),
                          }}
                        />
                      )}

                      {/* Destination Marker */}
                      {data.tracking.destination && (
                        <Marker
                          position={{
                            lat: data.tracking.destination.latitude,
                            lng: data.tracking.destination.longitude
                          }}
                          icon={{
                            path: 'M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7zm0 9.5c-1.38 0-2.5-1.12-2.5-2.5s1.12-2.5 2.5-2.5 2.5 1.12 2.5 2.5-1.12 2.5-2.5 2.5z',
                            fillColor: '#f44336',
                            fillOpacity: 1,
                            strokeColor: '#ffffff',
                            strokeWeight: 2,
                            scale: 1.2,
                            anchor: new google.maps.Point(12, 24),
                          }}
                        />
                      )}

                      {/* Route Line */}
                      {data.tracking.lastLocation && data.tracking.destination && (
                        <Polyline
                          path={[
                            {
                              lat: data.tracking.lastLocation.latitude,
                              lng: data.tracking.lastLocation.longitude
                            },
                            {
                              lat: data.tracking.destination.latitude,
                              lng: data.tracking.destination.longitude
                            }
                          ]}
                          options={{
                            strokeColor: '#2196f3',
                            strokeOpacity: 0.8,
                            strokeWeight: 3,
                          }}
                        />
                      )}
                    </GoogleMap>
                  )}
                </LoadScript>
              </Box>
              {data.tracking.remainingDistanceKm && (
                <Stack direction="row" spacing={2} sx={{ mt: 2 }}>
                  <DirectionsCar fontSize="small" color="action" />
                  <Typography variant="caption" color="text.secondary">
                    {data.tracking.remainingDistanceKm.toFixed(1)} km remaining
                  </Typography>
                  <Typography variant="caption" color="text.secondary">
                    •
                  </Typography>
                  <Typography variant="caption" color="text.secondary">
                    Updated {new Date(data.tracking.lastLocation.timestamp).toLocaleTimeString()}
                  </Typography>
                </Stack>
              )}
            </CardContent>
          </Card>
        )}

        {/* Timeline */}
        <Card sx={{ mb: 3 }}>
          <CardContent>
            <Typography variant="h6" sx={{ fontWeight: 600, mb: 2 }}>
              Delivery Timeline
            </Typography>
            {data.tracking.timeline && data.tracking.timeline.length > 0 ? (
              <Stack spacing={2}>
                {data.tracking.timeline.map((event, index) => (
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
                          {getStatusLabel(event.status)}
                        </Typography>
                        <Typography variant="caption" color="text.secondary">
                          {new Date(event.timestamp).toLocaleString()}
                        </Typography>
                        {event.note && (
                          <Typography variant="body2" color="text.secondary" sx={{ mt: 0.5 }}>
                            {event.note}
                          </Typography>
                        )}
                      </Box>
                    </Stack>
                    {index < data.tracking.timeline!.length - 1 && (
                      <Box sx={{ height: 20, width: 2, bgcolor: theme.palette.divider, ml: 5 }} />
                    )}
                  </Stack>
                ))}
              </Stack>
            ) : (
              <Typography variant="body2" color="text.secondary">
                No timeline events yet
              </Typography>
            )}
          </CardContent>
        </Card>

        {/* Delivery Proof */}
        {isDelivered && data.tracking.proof && (
          <Card>
            <CardContent>
              <Typography variant="h6" sx={{ fontWeight: 600, mb: 2 }}>
                Delivery Proof
              </Typography>
              <Stack spacing={2}>
                {data.tracking.proof.photoUrl && (
                  <Box
                    component="img"
                    src={data.tracking.proof.photoUrl}
                    alt="Delivery Proof"
                    sx={{
                      width: '100%',
                      maxHeight: 300,
                      objectFit: 'contain',
                      borderRadius: 2
                    }}
                  />
                )}
                {data.tracking.proof.recipientName && (
                  <Stack direction="row" spacing={2}>
                    <Person color="action" />
                    <Typography variant="body2">
                      Received by: {data.tracking.proof.recipientName}
                    </Typography>
                  </Stack>
                )}
                {data.tracking.proof.note && (
                  <Typography variant="body2" color="text.secondary">
                    Note: {data.tracking.proof.note}
                  </Typography>
                )}
                {data.tracking.proof.timestamp && (
                  <Stack direction="row" spacing={1} alignItems="center">
                    <AccessTime fontSize="small" color="action" />
                    <Typography variant="caption" color="text.secondary">
                      Delivered at {new Date(data.tracking.proof.timestamp).toLocaleString()}
                    </Typography>
                  </Stack>
                )}
              </Stack>
            </CardContent>
          </Card>
        )}
      </Box>
    </Box>
  );
}
