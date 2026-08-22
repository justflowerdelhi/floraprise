import React, { useState, useEffect, useCallback } from 'react';
import {
  Box, Typography, Chip, Stack, useTheme, alpha,
  Paper, CircularProgress, Alert, Tooltip, IconButton
} from '@mui/material';
import { Refresh, DirectionsCar, LocationOn, LocalShipping, PauseCircle, CheckCircle, Error } from '@mui/icons-material';
import { GoogleMap, LoadScript, Marker, InfoWindow, Polyline } from '@react-google-maps/api';
import { apiClient } from '../../core/api/apiClient';

const mapContainerStyle = {
  width: '100%',
  height: '100%',
};

const defaultCenter = {
  lat: 28.6139,
  lng: 77.2090,
};

interface Driver {
  id: string;
  name: string;
  phone: string;
  status: 'Available' | 'Assigned' | 'Moving' | 'Paused' | 'Offline' | 'Delivered';
  currentLocation?: {
    lat: number;
    lng: number;
    accuracy: number;
    speed: number;
    heading: number;
    updatedAt: string;
  };
  currentDelivery?: {
    id: string;
    orderNumber: string;
    customerName: string;
    address: string;
    destination: {
      lat: number;
      lng: number;
    };
    status: string;
    eta?: string;
  };
}

interface DriverLocationResponse {
  driverId: string;
  driverName: string;
  driverPhone: string;
  latitude: number;
  longitude: number;
  speedKph: number;
  lastUpdate?: string;
  isOnline: boolean;
}

export default function DeliveryLiveMap() {
  const theme = useTheme();
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [drivers, setDrivers] = useState<Driver[]>([]);
  const [selectedDriver, setSelectedDriver] = useState<Driver | null>(null);
  const [mapCenter, setMapCenter] = useState(defaultCenter);
  const [isLoaded, setIsLoaded] = useState(false);

  const fetchDrivers = useCallback(async () => {
    try {
      const response = await apiClient.get<{ items: DriverLocationResponse[] }>(
        '/delivery/control-center/drivers/locations',
      );
      const mappedDrivers: Driver[] = (response.data.items || []).map((driver) => ({
        id: driver.driverId,
        name: driver.driverName,
        phone: driver.driverPhone,
        status: driver.isOnline ? 'Moving' : 'Offline',
        currentLocation: {
          lat: driver.latitude,
          lng: driver.longitude,
          accuracy: 0,
          speed: driver.speedKph / 3.6,
          heading: 0,
          updatedAt: driver.lastUpdate || new Date().toISOString(),
        },
      }));
      setDrivers(mappedDrivers);
      const firstLocation = mappedDrivers[0]?.currentLocation;
      if (firstLocation) {
        setMapCenter({ lat: firstLocation.lat, lng: firstLocation.lng });
      }
      setError(null);
    } catch (err) {
      console.error('Failed to fetch drivers:', err);
      setError('Failed to load driver data');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchDrivers();
    const interval = setInterval(fetchDrivers, 15000);
    return () => clearInterval(interval);
  }, [fetchDrivers]);

  const getDriverColor = (status: string) => {
    switch (status) {
      case 'Available': return '#4caf50';
      case 'Assigned': return '#2196f3';
      case 'Moving': return '#ff9800';
      case 'Paused': return '#9c27b0';
      case 'Offline': return '#9e9e9e';
      case 'Delivered': return '#00bcd4';
      default: return '#f44336';
    }
  };

  const onlineCount = drivers.filter(d => d.status !== 'Offline').length;
  const activeCount = drivers.filter(d => ['Moving', 'Assigned'].includes(d.status)).length;
  const completedCount = drivers.filter(d => d.status === 'Delivered').length;

  return (
    <Box sx={{ height: '100vh', display: 'flex', flexDirection: 'column' }}>
      <Box sx={{ p: 2, bgcolor: 'white', borderBottom: 1, borderColor: 'divider' }}>
        <Stack direction="row" justifyContent="space-between" alignItems="center">
          <Typography variant="h6" sx={{ fontWeight: 700 }}>
            Live Delivery Map
          </Typography>
          <Stack direction="row" spacing={1} alignItems="center">
            <Chip label={`Online: ${onlineCount}`} color="success" size="small" />
            <Chip label={`Active: ${activeCount}`} color="primary" size="small" />
            <Chip label={`Completed: ${completedCount}`} color="default" size="small" />
            <Tooltip title="Refresh">
              <IconButton onClick={fetchDrivers} size="small">
                <Refresh />
              </IconButton>
            </Tooltip>
          </Stack>
        </Stack>
      </Box>

      <Box sx={{ flex: 1, position: 'relative' }}>
        {error && (
          <Alert severity="error" sx={{ position: 'absolute', top: 16, left: 16, right: 16, zIndex: 1000 }}>
            {error}
          </Alert>
        )}

        {loading ? (
          <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '100%' }}>
            <CircularProgress />
          </Box>
        ) : (
          <LoadScript
            googleMapsApiKey={import.meta.env.VITE_GOOGLE_MAPS_API_KEY || ''}
            onLoad={() => setIsLoaded(true)}
          >
            {isLoaded && (
              <GoogleMap
                mapContainerStyle={mapContainerStyle}
                center={mapCenter}
                zoom={13}
                options={{
                  streetViewControl: false,
                  mapTypeControl: true,
                  fullscreenControl: false,
                }}
              >
                {drivers.map((driver) => {
                  if (!driver.currentLocation) return null;

                  return (
                    <Marker
                      key={driver.id}
                      position={{ lat: driver.currentLocation.lat, lng: driver.currentLocation.lng }}
                      onClick={() => setSelectedDriver(driver)}
                      icon={{
                        path: 'M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7zm0 9.5c-1.38 0-2.5-1.12-2.5-2.5s1.12-2.5 2.5-2.5 2.5 1.12 2.5 2.5-1.12 2.5-2.5 2.5z',
                        fillColor: getDriverColor(driver.status),
                        fillOpacity: 1,
                        strokeColor: '#ffffff',
                        strokeWeight: 2,
                        scale: 1.5,
                        anchor: new google.maps.Point(12, 24),
                      }}
                    >
                      {selectedDriver?.id === driver.id && (
                        <InfoWindow
                          position={{ lat: driver.currentLocation.lat, lng: driver.currentLocation.lng }}
                          onCloseClick={() => setSelectedDriver(null)}
                        >
                          <Paper sx={{ p: 2, minWidth: 250 }}>
                            <Typography variant="subtitle2" sx={{ fontWeight: 700 }}>
                              {driver.name}
                            </Typography>
                            <Chip
                              label={driver.status}
                              size="small"
                              sx={{ mt: 1, bgcolor: getDriverColor(driver.status), color: 'white' }}
                            />
                            {driver.currentDelivery && (
                              <Box sx={{ mt: 2 }}>
                                <Typography variant="caption" color="text.secondary">
                                  Order: {driver.currentDelivery.orderNumber}
                                </Typography>
                                <Typography variant="body2">
                                  {driver.currentDelivery.customerName}
                                </Typography>
                                <Typography variant="caption" color="text.secondary">
                                  {driver.currentDelivery.address}
                                </Typography>
                                {driver.currentDelivery.eta && (
                                  <Typography variant="caption" color="primary" sx={{ display: 'block', mt: 1 }}>
                                    ETA: {driver.currentDelivery.eta}
                                  </Typography>
                                )}
                              </Box>
                            )}
                            <Typography variant="caption" color="text.secondary" sx={{ display: 'block', mt: 1 }}>
                              Speed: {driver.currentLocation.speed.toFixed(1)} m/s
                            </Typography>
                            <Typography variant="caption" color="text.secondary">
                              Updated: {new Date(driver.currentLocation.updatedAt).toLocaleTimeString()}
                            </Typography>
                          </Paper>
                        </InfoWindow>
                      )}
                    </Marker>
                  );
                })}

                {drivers
                  .filter(d => d.currentDelivery && d.currentDelivery.destination)
                  .map((driver) => (
                    <Marker
                      key={`dest-${driver.id}`}
                      position={driver.currentDelivery!.destination}
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
                  ))}

                {drivers
                  .filter(d => d.currentLocation && d.currentDelivery?.destination)
                  .map((driver) => (
                    <Polyline
                      key={`route-${driver.id}`}
                      path={[
                        { lat: driver.currentLocation!.lat, lng: driver.currentLocation!.lng },
                        driver.currentDelivery!.destination,
                      ]}
                      options={{
                        strokeColor: getDriverColor(driver.status),
                        strokeOpacity: 0.8,
                        strokeWeight: 3,
                      }}
                    />
                  ))}
              </GoogleMap>
            )}
          </LoadScript>
        )}

        <Paper
          sx={{
            position: 'absolute',
            bottom: 16,
            left: 16,
            p: 2,
            zIndex: 1000,
            bgcolor: 'white',
          }}
        >
          <Typography variant="caption" sx={{ fontWeight: 700, display: 'block', mb: 1 }}>
            Driver Status
          </Typography>
          <Stack spacing={0.5}>
            {[
              { status: 'Available', color: '#4caf50' },
              { status: 'Assigned', color: '#2196f3' },
              { status: 'Moving', color: '#ff9800' },
              { status: 'Paused', color: '#9c27b0' },
              { status: 'Offline', color: '#9e9e9e' },
              { status: 'Delivered', color: '#00bcd4' },
            ].map(({ status, color }) => (
              <Stack key={status} direction="row" spacing={1} alignItems="center">
                <Box
                  sx={{
                    width: 12,
                    height: 12,
                    borderRadius: '50%',
                    bgcolor: color,
                  }}
                />
                <Typography variant="caption">{status}</Typography>
              </Stack>
            ))}
          </Stack>
        </Paper>
      </Box>
    </Box>
  );
}
