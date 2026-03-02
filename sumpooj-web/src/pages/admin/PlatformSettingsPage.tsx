/**
 * PlatformSettingsPage.tsx — Platform-wide settings
 */
import React from 'react';
import { Box, Typography, Alert, Button } from '@mui/material';
import { useNavigate } from 'react-router-dom';

const PlatformSettingsPage: React.FC = () => {
  const navigate = useNavigate();

  return (
    <Box sx={{ p: 3 }}>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 3 }}>
        <Typography variant="h5" fontWeight={700}>Platform Settings</Typography>
        <Button variant="outlined" onClick={() => navigate('/admin/dashboard')}>Back</Button>
      </Box>
      <Alert severity="info">
        Platform-wide settings (default plans, feature flags, system notifications) will be configurable here.
      </Alert>
    </Box>
  );
};

export default PlatformSettingsPage;
