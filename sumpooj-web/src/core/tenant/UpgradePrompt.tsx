// =============================================================================
// UPGRADE PROMPT - Modal for Prompting Plan Upgrades
// =============================================================================

import React from 'react';
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  Box,
  Typography,
  Chip,
  List,
  ListItem,
  ListItemIcon,
  ListItemText,
  Divider,
  alpha,
} from '@mui/material';
import {
  LockOutlined,
  CheckCircle,
  Star,
  RocketLaunch,
  ArrowForward,
} from '@mui/icons-material';
import { useTenant } from './TenantContext';
import { FEATURE_METADATA } from './FeatureFlags';
import type { TenantPlan } from './TenantTypes';
import { PLAN_CONFIGS, formatPlanPrice } from './TenantTypes';

export function UpgradePromptModal() {
  const {
    showUpgradeModal,
    setShowUpgradeModal,
    upgradeFeature,
    plan: currentPlan,
    getUpgradePlan,
    upgradePlan,
  } = useTenant();
  
  if (!upgradeFeature) return null;
  
  const featureInfo = FEATURE_METADATA[upgradeFeature];
  const requiredPlan = getUpgradePlan(upgradeFeature);
  
  if (!requiredPlan) return null;
  
  const requiredPlanConfig = PLAN_CONFIGS[requiredPlan];
  const currentPlanConfig = PLAN_CONFIGS[currentPlan];
  
  const handleUpgrade = () => {
    upgradePlan(requiredPlan);
  };
  
  const handleClose = () => {
    setShowUpgradeModal(false);
  };
  
  return (
    <Dialog
      open={showUpgradeModal}
      onClose={handleClose}
      maxWidth="sm"
      fullWidth
      PaperProps={{
        sx: {
          bgcolor: '#1a1a2e',
          backgroundImage: 'none',
        },
      }}
    >
      <DialogTitle
        sx={{
          display: 'flex',
          alignItems: 'center',
          gap: 2,
          borderBottom: 1,
          borderColor: 'divider',
        }}
      >
        <Box
          sx={{
            width: 48,
            height: 48,
            borderRadius: 2,
            bgcolor: alpha('#fdd835', 0.15),
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
          }}
        >
          <LockOutlined sx={{ color: '#fdd835', fontSize: 24 }} />
        </Box>
        <Box>
          <Typography variant="h6" fontWeight={600}>
            Unlock {featureInfo.name}
          </Typography>
          <Typography variant="body2" color="text.secondary">
            Upgrade to access this feature
          </Typography>
        </Box>
      </DialogTitle>
      
      <DialogContent sx={{ pt: 3 }}>
        <Box
          sx={{
            p: 2,
            bgcolor: alpha('#fdd835', 0.08),
            borderRadius: 2,
            border: 1,
            borderColor: alpha('#fdd835', 0.2),
            mb: 3,
          }}
        >
          <Typography variant="body1" color="text.primary" mb={1}>
            {featureInfo.description}
          </Typography>
          <Chip
            label={`Requires ${requiredPlanConfig.name} Plan`}
            size="small"
            sx={{
              bgcolor: alpha('#fdd835', 0.2),
              color: '#fdd835',
            }}
          />
        </Box>
        
        <Box
          sx={{
            display: 'flex',
            alignItems: 'center',
            gap: 2,
            mb: 3,
          }}
        >
          <Box
            sx={{
              flex: 1,
              p: 2,
              bgcolor: '#0f0f0f',
              borderRadius: 2,
              textAlign: 'center',
            }}
          >
            <Typography variant="caption" color="text.secondary">
              Current Plan
            </Typography>
            <Typography variant="h6" fontWeight={600}>
              {currentPlanConfig.name}
            </Typography>
            <Typography variant="body2" color="text.secondary">
              {formatPlanPrice(currentPlan)}/mo
            </Typography>
          </Box>
          
          <ArrowForward sx={{ color: '#fdd835' }} />
          
          <Box
            sx={{
              flex: 1,
              p: 2,
              bgcolor: alpha('#fdd835', 0.1),
              borderRadius: 2,
              textAlign: 'center',
              border: 1,
              borderColor: '#fdd835',
            }}
          >
            <Typography variant="caption" color="#fdd835">
              Recommended
            </Typography>
            <Typography variant="h6" fontWeight={600} color="#fdd835">
              {requiredPlanConfig.name}
            </Typography>
            <Typography variant="body2" color="text.secondary">
              {formatPlanPrice(requiredPlan)}/mo
            </Typography>
          </Box>
        </Box>
        
        <Typography variant="subtitle2" color="text.secondary" mb={1}>
          What you'll get with {requiredPlanConfig.name}:
        </Typography>
        
        <List dense sx={{ bgcolor: '#0f0f0f', borderRadius: 2 }}>
          {requiredPlanConfig.features.slice(0, 5).map((feature, index) => (
            <ListItem key={index}>
              <ListItemIcon sx={{ minWidth: 36 }}>
                <CheckCircle sx={{ color: '#4caf50', fontSize: 18 }} />
              </ListItemIcon>
              <ListItemText
                primary={feature}
                primaryTypographyProps={{ variant: 'body2' }}
              />
            </ListItem>
          ))}
          {requiredPlanConfig.features.length > 5 && (
            <ListItem>
              <ListItemText
                primary={`+${requiredPlanConfig.features.length - 5} more features`}
                primaryTypographyProps={{
                  variant: 'body2',
                  color: 'text.secondary',
                  sx: { pl: 4.5 },
                }}
              />
            </ListItem>
          )}
        </List>
      </DialogContent>
      
      <Divider />
      
      <DialogActions sx={{ p: 2, gap: 1 }}>
        <Button onClick={handleClose} color="inherit">
          Maybe Later
        </Button>
        <Button
          variant="contained"
          onClick={handleUpgrade}
          startIcon={<RocketLaunch />}
          sx={{
            bgcolor: '#fdd835',
            color: '#0f0f0f',
            '&:hover': { bgcolor: '#ffeb3b' },
          }}
        >
          Upgrade to {requiredPlanConfig.name}
        </Button>
      </DialogActions>
    </Dialog>
  );
}

// -----------------------------------------------------------------------------
// Feature Locked Overlay
// -----------------------------------------------------------------------------

interface FeatureLockedOverlayProps {
  featureName: string;
  requiredPlan: TenantPlan;
  onUpgrade?: () => void;
}

export function FeatureLockedOverlay({
  featureName,
  requiredPlan,
  onUpgrade,
}: FeatureLockedOverlayProps) {
  const planConfig = PLAN_CONFIGS[requiredPlan];
  
  return (
    <Box
      sx={{
        position: 'absolute',
        top: 0,
        left: 0,
        right: 0,
        bottom: 0,
        bgcolor: alpha('#0f0f0f', 0.9),
        backdropFilter: 'blur(4px)',
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        zIndex: 10,
        borderRadius: 2,
      }}
    >
      <Box
        sx={{
          width: 80,
          height: 80,
          borderRadius: '50%',
          bgcolor: alpha('#fdd835', 0.1),
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          mb: 2,
        }}
      >
        <LockOutlined sx={{ fontSize: 40, color: '#fdd835' }} />
      </Box>
      
      <Typography variant="h6" fontWeight={600} mb={1}>
        {featureName}
      </Typography>
      
      <Typography variant="body2" color="text.secondary" mb={2} textAlign="center">
        This feature requires the {planConfig.name} plan or higher
      </Typography>
      
      {onUpgrade && (
        <Button
          variant="contained"
          startIcon={<Star />}
          onClick={onUpgrade}
          sx={{
            bgcolor: '#fdd835',
            color: '#0f0f0f',
            '&:hover': { bgcolor: '#ffeb3b' },
          }}
        >
          Upgrade to {planConfig.name}
        </Button>
      )}
    </Box>
  );
}

// -----------------------------------------------------------------------------
// Trial Banner Component
// -----------------------------------------------------------------------------

export function TrialBanner() {
  const { isTrialActive, trialDaysRemaining, planConfig } = useTenant();
  
  if (!isTrialActive) return null;
  
  const isUrgent = trialDaysRemaining <= 3;
  
  return (
    <Box
      sx={{
        px: 3,
        py: 1.5,
        bgcolor: isUrgent ? alpha('#f44336', 0.15) : alpha('#fdd835', 0.1),
        borderBottom: 1,
        borderColor: isUrgent ? alpha('#f44336', 0.3) : alpha('#fdd835', 0.2),
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between',
      }}
    >
      <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
        <Star sx={{ color: isUrgent ? '#f44336' : '#fdd835', fontSize: 20 }} />
        <Typography variant="body2" color={isUrgent ? '#f44336' : 'text.primary'}>
          {trialDaysRemaining === 0
            ? 'Your trial ends today!'
            : `${trialDaysRemaining} day${trialDaysRemaining !== 1 ? 's' : ''} left in your ${planConfig.name} trial`}
        </Typography>
      </Box>
      
      <Button
        size="small"
        variant="contained"
        sx={{
          bgcolor: '#fdd835',
          color: '#0f0f0f',
          '&:hover': { bgcolor: '#ffeb3b' },
        }}
      >
        Subscribe Now
      </Button>
    </Box>
  );
}

// -----------------------------------------------------------------------------
// Past Due Banner Component
// -----------------------------------------------------------------------------

export function PastDueBanner() {
  const { isPastDue } = useTenant();
  
  if (!isPastDue) return null;
  
  return (
    <Box
      sx={{
        px: 3,
        py: 1.5,
        bgcolor: alpha('#f44336', 0.15),
        borderBottom: 1,
        borderColor: alpha('#f44336', 0.3),
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between',
      }}
    >
      <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
        <Typography variant="body2" color="#f44336" fontWeight={600}>
          ⚠️ Payment Past Due
        </Typography>
        <Typography variant="body2" color="text.secondary">
          Your subscription payment failed. Update your payment method to avoid service interruption.
        </Typography>
      </Box>
      
      <Button
        size="small"
        variant="contained"
        color="error"
      >
        Update Payment
      </Button>
    </Box>
  );
}
