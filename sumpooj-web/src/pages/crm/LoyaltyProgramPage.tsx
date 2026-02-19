// =============================================================================
// LOYALTY PROGRAM PAGE - Customer Loyalty Program Overview
// Florist ERP SaaS — CRM & Customer Retention
// =============================================================================

import { Box, Typography, Grid, Paper, useTheme } from '@mui/material';
import { TierComparisonCard, PointsDisplay } from './LoyaltyComponents';
import {
  DEFAULT_LOYALTY_CONFIG,
  formatCurrency,
} from './CRMTypes';

export default function LoyaltyProgramPage() {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';
  return (
    <Box sx={{ p: 3, bgcolor: dk ? '#0f0f0f' : '#f5f5f5', minHeight: '100vh' }}>
      {/* Header */}
      <Box sx={{ mb: 3 }}>
        <Typography variant="h5" fontWeight={600} sx={{ color: dk ? '#fff' : 'text.primary' }}>
          Loyalty Program
        </Typography>
        <Typography variant="body2" sx={{ opacity: 0.7 }}>
          Manage customer loyalty tiers and rewards
        </Typography>
      </Box>

      {/* Program Overview */}
      <Paper sx={{ p: 3, bgcolor: dk ? '#1a1a2e' : '#fff', mb: 3 }}>
        <Typography variant="h6" fontWeight={600} sx={{ mb: 2 }}>
          Program Configuration
        </Typography>
        <Grid container spacing={3}>
          <Grid size={{ xs: 6, sm: 3 }}>
            <Typography variant="caption" sx={{ opacity: 0.7 }}>Points per ₹100</Typography>
            <Typography variant="h5" fontWeight={600} sx={{ color: '#e91e63' }}>
              {DEFAULT_LOYALTY_CONFIG.pointsPerCurrency}
            </Typography>
          </Grid>
          <Grid size={{ xs: 6, sm: 3 }}>
            <Typography variant="caption" sx={{ opacity: 0.7 }}>Point Value</Typography>
            <Typography variant="h5" fontWeight={600} sx={{ color: '#4caf50' }}>
              ₹{DEFAULT_LOYALTY_CONFIG.currencyPerPoint}
            </Typography>
          </Grid>
          <Grid size={{ xs: 6, sm: 3 }}>
            <Typography variant="caption" sx={{ opacity: 0.7 }}>Min Redeem</Typography>
            <Typography variant="h5" fontWeight={600}>
              {DEFAULT_LOYALTY_CONFIG.minRedeemPoints} pts
            </Typography>
          </Grid>
          <Grid size={{ xs: 6, sm: 3 }}>
            <Typography variant="caption" sx={{ opacity: 0.7 }}>Welcome Bonus</Typography>
            <Typography variant="h5" fontWeight={600} sx={{ color: '#9c27b0' }}>
              {DEFAULT_LOYALTY_CONFIG.welcomeBonus} pts
            </Typography>
          </Grid>
        </Grid>
      </Paper>

      {/* Tier Comparison */}
      <TierComparisonCard />
    </Box>
  );
}
