/**
 * PlatformAnalyticsPage.tsx — Platform-wide analytics overview
 */
import React from 'react';
import { Box, Typography, Alert, Button } from '@mui/material';
import { useNavigate } from 'react-router-dom';

const PlatformAnalyticsPage: React.FC = () => {
  const navigate = useNavigate();

  return (
    <Box sx={{ p: 3 }}>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 3 }}>
        <Typography variant="h5" fontWeight={700}>Platform Analytics</Typography>
        <Button variant="outlined" onClick={() => navigate('/admin/dashboard')}>Back</Button>
      </Box>
      <Alert severity="info">
        Platform-wide analytics will be available here. Per-company analytics are available on each company's dashboard.
      </Alert>
    </Box>
  );
};

export default PlatformAnalyticsPage;
