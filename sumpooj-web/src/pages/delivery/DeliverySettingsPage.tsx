/**
 * DeliverySettingsPage.tsx — Delivery management settings
 * 
 * Features:
 * - Tracking interval
 * - Geofence radius
 * - Delay threshold
 * - OTP requirement
 * - Proof requirements (Photo mandatory, Signature mandatory)
 * - Battery optimization
 */
import React, { useState, useEffect } from 'react';
import {
  Box, Typography, Paper, Card, CardContent, Stack,
  TextField, Switch, Button, Divider, useTheme, alpha,
  CircularProgress, Alert, Grid, FormControlLabel, Slider
} from '@mui/material';
import {
  Settings, LocationOn, AccessTime, Warning,
  Camera, Edit, BatteryChargingFull, Save
} from '@mui/icons-material';

interface DeliverySettings {
  trackingInterval: number; // seconds
  geofenceRadius: number; // meters
  delayThreshold: number; // minutes
  otpRequired: boolean;
  photoMandatory: boolean;
  signatureMandatory: boolean;
  batteryOptimization: boolean;
  autoAssignDriver: boolean;
  notifyCustomerOnDeparture: boolean;
  notifyCustomerOnArrival: boolean;
  notifyCustomerOnDelivery: boolean;
}

export default function DeliverySettingsPage() {
  const theme = useTheme();
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState(false);
  const [settings, setSettings] = useState<DeliverySettings>({
    trackingInterval: 30,
    geofenceRadius: 100,
    delayThreshold: 15,
    otpRequired: true,
    photoMandatory: true,
    signatureMandatory: false,
    batteryOptimization: true,
    autoAssignDriver: false,
    notifyCustomerOnDeparture: true,
    notifyCustomerOnArrival: true,
    notifyCustomerOnDelivery: true
  });

  const fetchSettings = async () => {
    setLoading(true);
    try {
      const response = await fetch('/api/delivery/settings');
      if (response.ok) {
        const data = await response.json();
        setSettings(data);
      }
    } catch (err) {
      console.error('Failed to fetch settings:', err);
    } finally {
      setLoading(false);
    }
  };

  const saveSettings = async () => {
    setSaving(true);
    setError(null);
    setSuccess(false);
    try {
      const response = await fetch('/api/delivery/settings', {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(settings)
      });
      if (!response.ok) throw new Error('Failed to save settings');
      setSuccess(true);
      setTimeout(() => setSuccess(false), 3000);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Unknown error');
    } finally {
      setSaving(false);
    }
  };

  useEffect(() => {
    fetchSettings();
  }, []);

  const handleSliderChange = (field: keyof DeliverySettings) => (event: Event, value: number | number[]) => {
    setSettings({ ...settings, [field]: value as number });
  };

  const handleSwitchChange = (field: keyof DeliverySettings) => (event: React.ChangeEvent<HTMLInputElement>) => {
    setSettings({ ...settings, [field]: event.target.checked });
  };

  const handleTextFieldChange = (field: keyof DeliverySettings) => (event: React.ChangeEvent<HTMLInputElement>) => {
    setSettings({ ...settings, [field]: Number(event.target.value) });
  };

  if (loading) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', minHeight: '60vh' }}>
        <CircularProgress />
      </Box>
    );
  }

  return (
    <Box sx={{ p: 3, maxWidth: 900, mx: 'auto' }}>
      {/* Header */}
      <Stack direction="row" justifyContent="space-between" alignItems="center" sx={{ mb: 3 }}>
        <Box>
          <Typography variant="h4" sx={{ fontWeight: 700 }}>
            Delivery Settings
          </Typography>
          <Typography variant="body2" color="text.secondary">
            Configure delivery tracking and proof requirements
          </Typography>
        </Box>
        <Button
          variant="contained"
          startIcon={<Save />}
          onClick={saveSettings}
          disabled={saving}
        >
          {saving ? 'Saving...' : 'Save Settings'}
        </Button>
      </Stack>

      {error && (
        <Alert severity="error" sx={{ mb: 3 }}>
          {error}
        </Alert>
      )}

      {success && (
        <Alert severity="success" sx={{ mb: 3 }}>
          Settings saved successfully!
        </Alert>
      )}

      <Stack spacing={3}>
        {/* Tracking Settings */}
        <Card>
          <CardContent>
            <Stack spacing={3}>
              <Stack direction="row" alignItems="center" spacing={2}>
                <LocationOn color="primary" />
                <Typography variant="h6" sx={{ fontWeight: 600 }}>
                  Tracking Settings
                </Typography>
              </Stack>

              <Divider />

              <Stack spacing={2}>
                <Typography variant="body2" color="text.secondary">
                  GPS Tracking Interval (seconds)
                </Typography>
                <Slider
                  value={settings.trackingInterval}
                  onChange={handleSliderChange('trackingInterval')}
                  min={10}
                  max={120}
                  step={10}
                  valueLabelDisplay="auto"
                  marks={[
                    { value: 10, label: '10s' },
                    { value: 30, label: '30s' },
                    { value: 60, label: '60s' },
                    { value: 120, label: '120s' }
                  ]}
                />
                <Typography variant="caption" color="text.secondary">
                  Lower intervals provide more accurate tracking but use more battery
                </Typography>
              </Stack>

              <Stack spacing={2}>
                <Typography variant="body2" color="text.secondary">
                  Geofence Radius (meters)
                </Typography>
                <TextField
                  type="number"
                  value={settings.geofenceRadius}
                  onChange={handleTextFieldChange('geofenceRadius')}
                  inputProps={{ min: 50, max: 500 }}
                  size="small"
                  sx={{ width: 200 }}
                />
                <Typography variant="caption" color="text.secondary">
                  Radius around delivery location to trigger "Arrived" status
                </Typography>
              </Stack>

              <FormControlLabel
                control={
                  <Switch
                    checked={settings.batteryOptimization}
                    onChange={handleSwitchChange('batteryOptimization')}
                  />
                }
                label={
                  <Stack>
                    <Typography variant="body2">Battery Optimization</Typography>
                    <Typography variant="caption" color="text.secondary">
                      Adaptive tracking based on movement (15s when moving, 60s when stationary)
                    </Typography>
                  </Stack>
                }
              />
            </Stack>
          </CardContent>
        </Card>

        {/* Delay Settings */}
        <Card>
          <CardContent>
            <Stack spacing={3}>
              <Stack direction="row" alignItems="center" spacing={2}>
                <Warning color="warning" />
                <Typography variant="h6" sx={{ fontWeight: 600 }}>
                  Delay Threshold
                </Typography>
              </Stack>

              <Divider />

              <Stack spacing={2}>
                <Typography variant="body2" color="text.secondary">
                  Delay Threshold (minutes)
                </Typography>
                <TextField
                  type="number"
                  value={settings.delayThreshold}
                  onChange={handleTextFieldChange('delayThreshold')}
                  inputProps={{ min: 5, max: 60 }}
                  size="small"
                  sx={{ width: 200 }}
                />
                <Typography variant="caption" color="text.secondary">
                  Deliveries exceeding this threshold beyond scheduled time will be marked as delayed
                </Typography>
              </Stack>
            </Stack>
          </CardContent>
        </Card>

        {/* Proof Requirements */}
        <Card>
          <CardContent>
            <Stack spacing={3}>
              <Stack direction="row" alignItems="center" spacing={2}>
                <Camera color="info" />
                <Typography variant="h6" sx={{ fontWeight: 600 }}>
                  Proof Requirements
                </Typography>
              </Stack>

              <Divider />

              <Stack spacing={2}>
                <FormControlLabel
                  control={
                    <Switch
                      checked={settings.otpRequired}
                      onChange={handleSwitchChange('otpRequired')}
                    />
                  }
                  label={
                    <Stack>
                      <Typography variant="body2">OTP Required</Typography>
                      <Typography variant="caption" color="text.secondary">
                        Require customer OTP to complete delivery
                      </Typography>
                    </Stack>
                  }
                />

                <FormControlLabel
                  control={
                    <Switch
                      checked={settings.photoMandatory}
                      onChange={handleSwitchChange('photoMandatory')}
                    />
                  }
                  label={
                    <Stack>
                      <Typography variant="body2">Photo Mandatory</Typography>
                      <Typography variant="caption" color="text.secondary">
                        Require photo proof for all deliveries
                      </Typography>
                    </Stack>
                  }
                />

                <FormControlLabel
                  control={
                    <Switch
                      checked={settings.signatureMandatory}
                      onChange={handleSwitchChange('signatureMandatory')}
                    />
                  }
                  label={
                    <Stack>
                      <Typography variant="body2">Signature Mandatory</Typography>
                      <Typography variant="caption" color="text.secondary">
                        Require customer signature for all deliveries
                      </Typography>
                    </Stack>
                  }
                />
              </Stack>
            </Stack>
          </CardContent>
        </Card>

        {/* Customer Notifications */}
        <Card>
          <CardContent>
            <Stack spacing={3}>
              <Stack direction="row" alignItems="center" spacing={2}>
                <AccessTime color="success" />
                <Typography variant="h6" sx={{ fontWeight: 600 }}>
                  Customer Notifications
                </Typography>
              </Stack>

              <Divider />

              <Stack spacing={2}>
                <FormControlLabel
                  control={
                    <Switch
                      checked={settings.notifyCustomerOnDeparture}
                      onChange={handleSwitchChange('notifyCustomerOnDeparture')}
                    />
                  }
                  label="Notify when driver leaves shop"
                />

                <FormControlLabel
                  control={
                    <Switch
                      checked={settings.notifyCustomerOnArrival}
                      onChange={handleSwitchChange('notifyCustomerOnArrival')}
                    />
                  }
                  label="Notify when driver arrives nearby"
                />

                <FormControlLabel
                  control={
                    <Switch
                      checked={settings.notifyCustomerOnDelivery}
                      onChange={handleSwitchChange('notifyCustomerOnDelivery')}
                    />
                  }
                  label="Notify when delivery is completed"
                />
              </Stack>
            </Stack>
          </CardContent>
        </Card>

        {/* Automation */}
        <Card>
          <CardContent>
            <Stack spacing={3}>
              <Stack direction="row" alignItems="center" spacing={2}>
                <Settings color="action" />
                <Typography variant="h6" sx={{ fontWeight: 600 }}>
                  Automation
                </Typography>
              </Stack>

              <Divider />

              <FormControlLabel
                control={
                  <Switch
                    checked={settings.autoAssignDriver}
                    onChange={handleSwitchChange('autoAssignDriver')}
                  />
                }
                label={
                  <Stack>
                    <Typography variant="body2">Auto-assign Driver</Typography>
                    <Typography variant="caption" color="text.secondary">
                      Automatically assign nearest available driver to new deliveries
                    </Typography>
                  </Stack>
                }
              />
            </Stack>
          </CardContent>
        </Card>
      </Stack>
    </Box>
  );
}
