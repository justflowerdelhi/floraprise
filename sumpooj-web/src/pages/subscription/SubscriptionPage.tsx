// =============================================================================
// SUBSCRIPTION PAGE - SaaS Plan Management
// =============================================================================

import React, { useState } from 'react';
import {
  Box,
  Typography,
  Card,
  CardContent,
  Button,
  Grid,
  Chip,
  LinearProgress,
  List,
  ListItem,
  ListItemIcon,
  ListItemText,
  Divider,
  alpha,
  Switch,
  FormControlLabel,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Alert,
  Stack,
} from '@mui/material';
import {
  CheckCircle,
  Cancel,
  Star,
  RocketLaunch,
  CreditCard,
  AccessTime,
  ShowChart,
  People,
  LocationOn,
  Storage,
  ArrowUpward,
  Celebration,
} from '@mui/icons-material';
import { useTenant } from '../../core/tenant/TenantContext';
import type { TenantPlan, PlanConfig } from '../../core/tenant/TenantTypes';
import { PLAN_CONFIGS, formatPlanPrice, getUsagePercentage } from '../../core/tenant/TenantTypes';
import type { FeatureFlag } from '../../core/tenant/FeatureFlags';
import { FEATURE_METADATA, hasFeature } from '../../core/tenant/FeatureFlags';

// -----------------------------------------------------------------------------
// Main Subscription Page
// -----------------------------------------------------------------------------

export default function SubscriptionPage() {
  const {
    tenant,
    plan,
    planConfig,
    subscriptionStatus,
    isTrialActive,
    trialDaysRemaining,
    isActive,
    isPastDue,
    upgradePlan,
  } = useTenant();
  
  const [yearlyBilling, setYearlyBilling] = useState(false);
  const [showUpgradeDialog, setShowUpgradeDialog] = useState(false);
  const [selectedPlan, setSelectedPlan] = useState<TenantPlan | null>(null);
  
  const handleUpgradeClick = (newPlan: TenantPlan) => {
    setSelectedPlan(newPlan);
    setShowUpgradeDialog(true);
  };
  
  const handleConfirmUpgrade = () => {
    if (selectedPlan) {
      upgradePlan(selectedPlan);
      setShowUpgradeDialog(false);
      setSelectedPlan(null);
    }
  };
  
  return (
    <Box sx={{ p: 3, maxWidth: 1400, mx: 'auto' }}>
      {/* Header */}
      <Box sx={{ mb: 4 }}>
        <Typography variant="h4" fontWeight={700} mb={1}>
          Subscription
        </Typography>
        <Typography color="text.secondary">
          Manage your subscription plan and billing
        </Typography>
      </Box>
      
      {/* Alerts */}
      {isPastDue && (
        <Alert
          severity="error"
          sx={{ mb: 3 }}
          action={
            <Button color="inherit" size="small">
              Update Payment
            </Button>
          }
        >
          Your payment is past due. Please update your payment method to avoid service interruption.
        </Alert>
      )}
      
      {isTrialActive && (
        <Alert
          severity={trialDaysRemaining <= 3 ? 'warning' : 'info'}
          sx={{ mb: 3 }}
          icon={<AccessTime />}
        >
          {trialDaysRemaining === 0
            ? 'Your trial ends today! Subscribe now to continue using all features.'
            : `You have ${trialDaysRemaining} day${trialDaysRemaining !== 1 ? 's' : ''} left in your trial. Subscribe to keep your access.`}
        </Alert>
      )}
      
      <Grid container spacing={3}>
        {/* Current Plan Card */}
        <Grid size={{ xs: 12, lg: 4 }}>
          <Card sx={{ bgcolor: '#1a1a2e', height: '100%' }}>
            <CardContent sx={{ p: 3 }}>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 3 }}>
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
                  <Star sx={{ color: '#fdd835', fontSize: 24 }} />
                </Box>
                <Box>
                  <Typography variant="h6" fontWeight={600}>
                    Current Plan
                  </Typography>
                  <StatusChip status={subscriptionStatus} />
                </Box>
              </Box>
              
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
                <Typography variant="h4" fontWeight={700} color="#fdd835">
                  {planConfig.name}
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  {planConfig.description}
                </Typography>
                <Box sx={{ mt: 2 }}>
                  <Typography variant="h5" fontWeight={600}>
                    {formatPlanPrice(plan)}<Typography component="span" variant="body2" color="text.secondary">/month</Typography>
                  </Typography>
                </Box>
              </Box>
              
              {isTrialActive && (
                <Box
                  sx={{
                    p: 2,
                    bgcolor: '#0f0f0f',
                    borderRadius: 2,
                    mb: 3,
                  }}
                >
                  <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
                    <Typography variant="body2" color="text.secondary">
                      Trial Period
                    </Typography>
                    <Typography variant="body2" fontWeight={600} color={trialDaysRemaining <= 3 ? '#f44336' : '#fdd835'}>
                      {trialDaysRemaining} days left
                    </Typography>
                  </Box>
                  <LinearProgress
                    variant="determinate"
                    value={((14 - trialDaysRemaining) / 14) * 100}
                    sx={{
                      height: 6,
                      borderRadius: 3,
                      bgcolor: alpha('#fdd835', 0.2),
                      '& .MuiLinearProgress-bar': {
                        bgcolor: trialDaysRemaining <= 3 ? '#f44336' : '#fdd835',
                      },
                    }}
                  />
                </Box>
              )}
              
              <Typography variant="subtitle2" color="text.secondary" mb={1.5}>
                Current Plan Features
              </Typography>
              <List dense sx={{ bgcolor: '#0f0f0f', borderRadius: 2, mb: 2 }}>
                {planConfig.features.slice(0, 6).map((feature, index) => (
                  <ListItem key={index} sx={{ py: 0.5 }}>
                    <ListItemIcon sx={{ minWidth: 32 }}>
                      <CheckCircle sx={{ color: '#4caf50', fontSize: 16 }} />
                    </ListItemIcon>
                    <ListItemText
                      primary={feature}
                      primaryTypographyProps={{ variant: 'body2' }}
                    />
                  </ListItem>
                ))}
              </List>
              
              <Button
                fullWidth
                variant="outlined"
                startIcon={<CreditCard />}
                sx={{ borderColor: alpha('#fdd835', 0.3) }}
              >
                Manage Billing
              </Button>
            </CardContent>
          </Card>
        </Grid>
        
        {/* Usage Overview */}
        <Grid size={{ xs: 12, lg: 8 }}>
          <Card sx={{ bgcolor: '#1a1a2e', mb: 3 }}>
            <CardContent sx={{ p: 3 }}>
              <Typography variant="h6" fontWeight={600} mb={3}>
                Usage Overview
              </Typography>
              
              <Grid container spacing={3}>
                <Grid size={{ xs: 12, sm: 6 }}>
                  <UsageCard
                    icon={<ShowChart />}
                    label="Orders This Month"
                    used={tenant.usageStats?.ordersThisMonth ?? 0}
                    limit={tenant.usageStats?.ordersLimit ?? 0}
                  />
                </Grid>
                <Grid size={{ xs: 12, sm: 6 }}>
                  <UsageCard
                    icon={<People />}
                    label="Staff Members"
                    used={tenant.usageStats?.staffCount ?? 0}
                    limit={tenant.usageStats?.staffLimit ?? 0}
                  />
                </Grid>
                <Grid size={{ xs: 12, sm: 6 }}>
                  <UsageCard
                    icon={<LocationOn />}
                    label="Locations"
                    used={tenant.usageStats?.locationsCount ?? 0}
                    limit={tenant.usageStats?.locationsLimit ?? 0}
                  />
                </Grid>
                <Grid size={{ xs: 12, sm: 6 }}>
                  <UsageCard
                    icon={<Storage />}
                    label="Storage Used"
                    used={tenant.usageStats?.storageUsedMB ?? 0}
                    limit={tenant.usageStats?.storageLimitMB ?? 0}
                    unit="MB"
                  />
                </Grid>
              </Grid>
            </CardContent>
          </Card>
          
          {/* Feature Access Matrix */}
          <Card sx={{ bgcolor: '#1a1a2e' }}>
            <CardContent sx={{ p: 3 }}>
              <Typography variant="h6" fontWeight={600} mb={3}>
                Feature Access
              </Typography>
              
              <Grid container spacing={2}>
                {(Object.keys(FEATURE_METADATA) as FeatureFlag[]).map((feature) => {
                  const meta = FEATURE_METADATA[feature];
                  const isAvailable = hasFeature(plan, feature);
                  
                  return (
                    <Grid size={{ xs: 12, sm: 6, md: 4 }} key={feature}>
                      <Box
                        sx={{
                          p: 2,
                          borderRadius: 2,
                          bgcolor: isAvailable ? alpha('#4caf50', 0.1) : '#0f0f0f',
                          border: 1,
                          borderColor: isAvailable ? alpha('#4caf50', 0.3) : 'transparent',
                        }}
                      >
                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 0.5 }}>
                          {isAvailable ? (
                            <CheckCircle sx={{ color: '#4caf50', fontSize: 18 }} />
                          ) : (
                            <Cancel sx={{ color: 'text.disabled', fontSize: 18 }} />
                          )}
                          <Typography
                            variant="body2"
                            fontWeight={600}
                            color={isAvailable ? 'text.primary' : 'text.secondary'}
                          >
                            {meta.name}
                          </Typography>
                        </Box>
                        {!isAvailable && (
                          <Typography variant="caption" color="text.disabled" sx={{ pl: 3.5 }}>
                            Requires {PLAN_CONFIGS[meta.requiredPlan].name}
                          </Typography>
                        )}
                      </Box>
                    </Grid>
                  );
                })}
              </Grid>
            </CardContent>
          </Card>
        </Grid>
      </Grid>
      
      {/* Plan Comparison */}
      <Box sx={{ mt: 4 }}>
        <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', mb: 3 }}>
          <Box>
            <Typography variant="h5" fontWeight={700}>
              Available Plans
            </Typography>
            <Typography color="text.secondary">
              Compare plans and choose the best fit for your business
            </Typography>
          </Box>
          
          <FormControlLabel
            control={
              <Switch
                checked={yearlyBilling}
                onChange={(e) => setYearlyBilling(e.target.checked)}
                sx={{
                  '& .MuiSwitch-switchBase.Mui-checked': {
                    color: '#fdd835',
                  },
                  '& .MuiSwitch-switchBase.Mui-checked + .MuiSwitch-track': {
                    bgcolor: alpha('#fdd835', 0.5),
                  },
                }}
              />
            }
            label={
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                <Typography variant="body2">Yearly billing</Typography>
                <Chip
                  label="Save 17%"
                  size="small"
                  sx={{
                    bgcolor: alpha('#4caf50', 0.2),
                    color: '#4caf50',
                    height: 20,
                    fontSize: '0.7rem',
                  }}
                />
              </Box>
            }
          />
        </Box>
        
        <Grid container spacing={3}>
          {(['STARTER', 'GROWTH', 'PRO', 'ENTERPRISE'] as TenantPlan[]).map((planId) => (
            <Grid size={{ xs: 12, sm: 6, lg: 3 }} key={planId}>
              <PlanCard
                plan={planId}
                currentPlan={plan}
                yearlyBilling={yearlyBilling}
                onUpgrade={() => handleUpgradeClick(planId)}
              />
            </Grid>
          ))}
        </Grid>
      </Box>
      
      {/* Upgrade Confirmation Dialog */}
      <Dialog
        open={showUpgradeDialog}
        onClose={() => setShowUpgradeDialog(false)}
        PaperProps={{
          sx: { bgcolor: '#1a1a2e' },
        }}
      >
        <DialogTitle>
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
            <Celebration sx={{ color: '#fdd835' }} />
            Confirm Plan Upgrade
          </Box>
        </DialogTitle>
        <DialogContent>
          {selectedPlan && (
            <Typography>
              You're about to upgrade to the <strong>{PLAN_CONFIGS[selectedPlan].name}</strong> plan
              at <strong>{formatPlanPrice(selectedPlan)}/month</strong>.
              {yearlyBilling && ' (billed annually)'}
            </Typography>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setShowUpgradeDialog(false)}>Cancel</Button>
          <Button
            variant="contained"
            onClick={handleConfirmUpgrade}
            sx={{
              bgcolor: '#fdd835',
              color: '#0f0f0f',
              '&:hover': { bgcolor: '#ffeb3b' },
            }}
          >
            Confirm Upgrade
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}

// -----------------------------------------------------------------------------
// Usage Card Component
// -----------------------------------------------------------------------------

interface UsageCardProps {
  icon: React.ReactNode;
  label: string;
  used: number;
  limit: number;
  unit?: string;
}

function UsageCard({ icon, label, used, limit, unit }: UsageCardProps) {
  const percentage = getUsagePercentage(used, limit);
  const isUnlimited = limit === -1;
  const isWarning = percentage >= 80;
  const isDanger = percentage >= 95;
  
  let color = '#4caf50';
  if (isWarning) color = '#ff9800';
  if (isDanger) color = '#f44336';
  
  return (
    <Box
      sx={{
        p: 2,
        bgcolor: '#0f0f0f',
        borderRadius: 2,
      }}
    >
      <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5, mb: 2 }}>
        <Box
          sx={{
            width: 36,
            height: 36,
            borderRadius: 1,
            bgcolor: alpha(color, 0.15),
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            color: color,
          }}
        >
          {icon}
        </Box>
        <Typography variant="body2" color="text.secondary">
          {label}
        </Typography>
      </Box>
      
      <Box sx={{ display: 'flex', alignItems: 'baseline', gap: 1, mb: 1 }}>
        <Typography variant="h5" fontWeight={700}>
          {used.toLocaleString()}{unit && ` ${unit}`}
        </Typography>
        <Typography variant="body2" color="text.secondary">
          / {isUnlimited ? 'Unlimited' : `${limit.toLocaleString()}${unit ? ` ${unit}` : ''}`}
        </Typography>
      </Box>
      
      {!isUnlimited && (
        <LinearProgress
          variant="determinate"
          value={percentage}
          sx={{
            height: 6,
            borderRadius: 3,
            bgcolor: alpha(color, 0.2),
            '& .MuiLinearProgress-bar': {
              bgcolor: color,
            },
          }}
        />
      )}
    </Box>
  );
}

// -----------------------------------------------------------------------------
// Status Chip Component
// -----------------------------------------------------------------------------

function StatusChip({ status }: { status: string }) {
  const config = {
    TRIAL: { color: '#2196f3', label: 'Trial' },
    ACTIVE: { color: '#4caf50', label: 'Active' },
    PAST_DUE: { color: '#f44336', label: 'Past Due' },
    CANCELLED: { color: '#9e9e9e', label: 'Cancelled' },
  }[status] ?? { color: '#9e9e9e', label: status };
  
  return (
    <Chip
      label={config.label}
      size="small"
      sx={{
        bgcolor: alpha(config.color, 0.2),
        color: config.color,
        fontWeight: 600,
        height: 20,
        fontSize: '0.7rem',
      }}
    />
  );
}

// -----------------------------------------------------------------------------
// Plan Card Component
// -----------------------------------------------------------------------------

interface PlanCardProps {
  plan: TenantPlan;
  currentPlan: TenantPlan;
  yearlyBilling: boolean;
  onUpgrade: () => void;
}

function PlanCard({ plan, currentPlan, yearlyBilling, onUpgrade }: PlanCardProps) {
  const config = PLAN_CONFIGS[plan];
  const isCurrent = plan === currentPlan;
  const planOrder: TenantPlan[] = ['STARTER', 'GROWTH', 'PRO', 'ENTERPRISE'];
  const isDowngrade = planOrder.indexOf(plan) < planOrder.indexOf(currentPlan);
  const isRecommended = config.recommended;
  
  const price = yearlyBilling ? config.yearlyPrice : config.monthlyPrice;
  const monthlyEquivalent = yearlyBilling ? Math.round(config.yearlyPrice / 12) : config.monthlyPrice;
  
  return (
    <Card
      sx={{
        bgcolor: '#1a1a2e',
        height: '100%',
        display: 'flex',
        flexDirection: 'column',
        position: 'relative',
        border: isCurrent || isRecommended ? 2 : 1,
        borderColor: isCurrent ? '#fdd835' : isRecommended ? alpha('#fdd835', 0.5) : 'transparent',
      }}
    >
      {isRecommended && !isCurrent && (
        <Box
          sx={{
            position: 'absolute',
            top: -12,
            left: '50%',
            transform: 'translateX(-50%)',
            px: 2,
            py: 0.5,
            bgcolor: '#fdd835',
            color: '#0f0f0f',
            borderRadius: 1,
            fontSize: '0.7rem',
            fontWeight: 700,
            textTransform: 'uppercase',
          }}
        >
          Most Popular
        </Box>
      )}
      
      {isCurrent && (
        <Box
          sx={{
            position: 'absolute',
            top: -12,
            left: '50%',
            transform: 'translateX(-50%)',
            px: 2,
            py: 0.5,
            bgcolor: '#fdd835',
            color: '#0f0f0f',
            borderRadius: 1,
            fontSize: '0.7rem',
            fontWeight: 700,
            textTransform: 'uppercase',
          }}
        >
          Current Plan
        </Box>
      )}
      
      <CardContent sx={{ p: 3, flexGrow: 1, display: 'flex', flexDirection: 'column' }}>
        <Box sx={{ textAlign: 'center', mb: 3, pt: isCurrent || isRecommended ? 2 : 0 }}>
          <Typography variant="h6" fontWeight={700} mb={0.5}>
            {config.name}
          </Typography>
          <Typography variant="body2" color="text.secondary" mb={2}>
            {config.description}
          </Typography>
          
          <Box sx={{ display: 'flex', alignItems: 'baseline', justifyContent: 'center', gap: 0.5 }}>
            <Typography variant="h3" fontWeight={700}>
              ${monthlyEquivalent}
            </Typography>
            <Typography variant="body2" color="text.secondary">
              /month
            </Typography>
          </Box>
          
          {yearlyBilling && (
            <Typography variant="caption" color="text.secondary">
              ${price} billed annually
            </Typography>
          )}
        </Box>
        
        <Divider sx={{ mb: 2 }} />
        
        <Box sx={{ flexGrow: 1 }}>
          <Typography variant="subtitle2" color="text.secondary" mb={1.5}>
            Includes:
          </Typography>
          <List dense disablePadding>
            {config.features.map((feature, index) => (
              <ListItem key={index} sx={{ px: 0, py: 0.5 }}>
                <ListItemIcon sx={{ minWidth: 28 }}>
                  <CheckCircle sx={{ color: '#4caf50', fontSize: 16 }} />
                </ListItemIcon>
                <ListItemText
                  primary={feature}
                  primaryTypographyProps={{ variant: 'body2' }}
                />
              </ListItem>
            ))}
          </List>
          
          <Box sx={{ mt: 2, p: 1.5, bgcolor: '#0f0f0f', borderRadius: 1 }}>
            <Typography variant="caption" color="text.secondary" display="block" mb={0.5}>
              Limits:
            </Typography>
            <Typography variant="caption" display="block">
              • {config.limits.orders === -1 ? 'Unlimited' : config.limits.orders.toLocaleString()} orders/month
            </Typography>
            <Typography variant="caption" display="block">
              • {config.limits.staff === -1 ? 'Unlimited' : config.limits.staff} staff members
            </Typography>
            <Typography variant="caption" display="block">
              • {config.limits.locations === -1 ? 'Unlimited' : config.limits.locations} location{config.limits.locations !== 1 ? 's' : ''}
            </Typography>
          </Box>
        </Box>
        
        <Box sx={{ mt: 3 }}>
          {isCurrent ? (
            <Button
              fullWidth
              variant="outlined"
              disabled
              sx={{ borderColor: alpha('#fdd835', 0.3) }}
            >
              Current Plan
            </Button>
          ) : isDowngrade ? (
            <Button
              fullWidth
              variant="outlined"
              color="inherit"
            >
              Downgrade
            </Button>
          ) : (
            <Button
              fullWidth
              variant="contained"
              startIcon={<ArrowUpward />}
              onClick={onUpgrade}
              sx={{
                bgcolor: '#fdd835',
                color: '#0f0f0f',
                '&:hover': { bgcolor: '#ffeb3b' },
              }}
            >
              Upgrade
            </Button>
          )}
        </Box>
      </CardContent>
    </Card>
  );
}
