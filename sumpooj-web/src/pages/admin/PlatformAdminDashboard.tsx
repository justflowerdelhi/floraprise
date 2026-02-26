/**
 * PlatformAdminDashboard.tsx — Landing page for platform administrators
 * 
 * Platform admins manage multiple companies and system-wide settings.
 * This dashboard provides access to:
 * - Company management
 * - System configuration
 * - Audit logs
 * - Platform analytics
 */
import React from 'react';
import { useNavigate } from 'react-router-dom';
import {
  Box,
  Card,
  CardContent,
  Typography,
  Grid,
  Button,
  Alert,
} from '@mui/material';
import {
  Business as CompanyIcon,
  Assessment as AnalyticsIcon,
  History as AuditIcon,
  Settings as SettingsIcon,
} from '@mui/icons-material';

const PlatformAdminDashboard: React.FC = () => {
  const navigate = useNavigate();

  const adminCards = [
    {
      title: 'Company Management',
      description: 'View and manage all companies on the platform',
      icon: <CompanyIcon sx={{ fontSize: 48, color: '#1B5E20' }} />,
      action: () => navigate('/admin/companies'),
      disabled: true, // TODO: Implement company management page
    },
    {
      title: 'Audit Logs',
      description: 'View system-wide audit logs and activity',
      icon: <AuditIcon sx={{ fontSize: 48, color: '#2196f3' }} />,
      action: () => navigate('/admin/audit-logs'),
      disabled: false,
    },
    {
      title: 'Platform Analytics',
      description: 'Monitor platform performance and usage',
      icon: <AnalyticsIcon sx={{ fontSize: 48, color: '#F4C430' }} />,
      action: () => navigate('/admin/analytics'),
      disabled: true, // TODO: Implement analytics page
    },
    {
      title: 'System Settings',
      description: 'Configure platform-wide settings',
      icon: <SettingsIcon sx={{ fontSize: 48, color: '#9c27b0' }} />,
      action: () => navigate('/admin/settings'),
      disabled: true, // TODO: Implement settings page
    },
  ];

  return (
    <Box sx={{ p: 3 }}>
      {/* Header */}
      <Box sx={{ mb: 4 }}>
        <Typography variant="h4" fontWeight={700} gutterBottom>
          Platform Administration
        </Typography>
        <Typography variant="body1" color="text.secondary">
          Manage companies, monitor system health, and configure platform settings
        </Typography>
      </Box>

      {/* Info Alert */}
      <Alert severity="info" sx={{ mb: 4 }}>
        <Typography variant="body2">
          <strong>Platform Admin Access:</strong> You have system-wide administration privileges. 
          Use this dashboard to manage companies and platform settings. Individual company features 
          (POS, Orders, Inventory) are restricted to company-level users.
        </Typography>
      </Alert>

      {/* Admin Cards */}
      <Grid container spacing={3}>
        {adminCards.map((card) => (
          <Grid size={{ xs: 12, sm: 6, md: 3 }} key={card.title}>
            <Card
              sx={{
                height: '100%',
                display: 'flex',
                flexDirection: 'column',
                transition: 'all 0.2s',
                '&:hover': {
                  transform: card.disabled ? 'none' : 'translateY(-4px)',
                  boxShadow: card.disabled ? 1 : 4,
                },
                opacity: card.disabled ? 0.6 : 1,
                cursor: card.disabled ? 'not-allowed' : 'pointer',
              }}
              onClick={() => !card.disabled && card.action()}
            >
              <CardContent
                sx={{
                  flexGrow: 1,
                  display: 'flex',
                  flexDirection: 'column',
                  alignItems: 'center',
                  textAlign: 'center',
                  py: 4,
                }}
              >
                {card.icon}
                <Typography variant="h6" fontWeight={600} sx={{ mt: 2, mb: 1 }}>
                  {card.title}
                </Typography>
                <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
                  {card.description}
                </Typography>
                {card.disabled && (
                  <Typography variant="caption" color="warning.main" fontWeight={500}>
                    Coming Soon
                  </Typography>
                )}
              </CardContent>
            </Card>
          </Grid>
        ))}
      </Grid>

      {/* Quick Stats Section (Future Enhancement) */}
      <Box sx={{ mt: 6 }}>
        <Typography variant="h5" fontWeight={600} gutterBottom>
          Platform Overview
        </Typography>
        <Grid container spacing={3} sx={{ mt: 2 }}>
          <Grid size={{ xs: 12, sm: 6, md: 3 }}>
            <Card>
              <CardContent>
                <Typography variant="body2" color="text.secondary">
                  Total Companies
                </Typography>
                <Typography variant="h4" fontWeight={700}>
                  --
                </Typography>
              </CardContent>
            </Card>
          </Grid>
          <Grid size={{ xs: 12, sm: 6, md: 3 }}>
            <Card>
              <CardContent>
                <Typography variant="body2" color="text.secondary">
                  Active Users
                </Typography>
                <Typography variant="h4" fontWeight={700}>
                  --
                </Typography>
              </CardContent>
            </Card>
          </Grid>
          <Grid size={{ xs: 12, sm: 6, md: 3 }}>
            <Card>
              <CardContent>
                <Typography variant="body2" color="text.secondary">
                  System Health
                </Typography>
                <Typography variant="h4" fontWeight={700} color="success.main">
                  ✓
                </Typography>
              </CardContent>
            </Card>
          </Grid>
          <Grid size={{ xs: 12, sm: 6, md: 3 }}>
            <Card>
              <CardContent>
                <Typography variant="body2" color="text.secondary">
                  API Status
                </Typography>
                <Typography variant="h4" fontWeight={700} color="success.main">
                  ✓
                </Typography>
              </CardContent>
            </Card>
          </Grid>
        </Grid>
      </Box>
    </Box>
  );
};

export default PlatformAdminDashboard;
