// =============================================================================
// LOYALTY SYSTEM COMPONENTS - Points, Tiers, and Rewards UI
// Florist ERP SaaS — CRM & Customer Retention
// =============================================================================

import { useState } from 'react';
import {
  Box,
  Paper,
  Typography,
  Grid,
  Chip,
  Avatar,
  Button,
  LinearProgress,
  Stack,
  Card,
  CardContent,
  IconButton,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  Tooltip,
  Divider,
  List,
  ListItem,
  ListItemIcon,
  ListItemText,
  Alert,
  useTheme,
} from '@mui/material';
import {
  EmojiEvents,
  Star,
  StarBorder,
  StarHalf,
  LocalOffer,
  Redeem,
  Add,
  Remove,
  History,
  CheckCircle,
  ArrowUpward,
  CardGiftcard,
  TrendingUp,
  Info,
} from '@mui/icons-material';
import type {
  Customer,
  LoyaltyTier,
  LoyaltyTransaction,
  LoyaltyTransactionType,
} from './CRMTypes';
import {
  LOYALTY_TIER_CONFIGS,
  DEFAULT_LOYALTY_CONFIG,
  formatCurrency,
  getTierFromPoints,
  getPointsToNextTier,
  calculatePointsEarned,
} from './CRMTypes';
import { getCurrencySymbol } from '../../core/i18n';

// -----------------------------------------------------------------------------
// Loyalty Tier Badge
// -----------------------------------------------------------------------------

interface LoyaltyTierBadgeProps {
  tier: LoyaltyTier;
  size?: 'small' | 'medium' | 'large';
  showLabel?: boolean;
}

export function LoyaltyTierBadge({ tier, size = 'medium', showLabel = true }: LoyaltyTierBadgeProps) {
  const config = LOYALTY_TIER_CONFIGS[tier];
  
  const sizeMap = {
    small: { icon: 16, chip: 20 },
    medium: { icon: 20, chip: 24 },
    large: { icon: 24, chip: 28 },
  };

  return (
    <Tooltip title={config.description}>
      <Chip
        icon={<EmojiEvents sx={{ fontSize: sizeMap[size].icon, color: `${config.color} !important` }} />}
        label={showLabel ? config.label : undefined}
        size="small"
        sx={{
          bgcolor: config.backgroundColor,
          color: config.color,
          fontWeight: 600,
          height: sizeMap[size].chip,
          '& .MuiChip-label': { px: showLabel ? 1 : 0 },
        }}
      />
    </Tooltip>
  );
}

// -----------------------------------------------------------------------------
// Points Display
// -----------------------------------------------------------------------------

interface PointsDisplayProps {
  points: number;
  size?: 'small' | 'medium' | 'large';
  showIcon?: boolean;
}

export function PointsDisplay({ points, size = 'medium', showIcon = true }: PointsDisplayProps) {
  const sizeMap = {
    small: { fontSize: 14, iconSize: 16 },
    medium: { fontSize: 18, iconSize: 20 },
    large: { fontSize: 24, iconSize: 28 },
  };

  return (
    <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
      {showIcon && <Star sx={{ fontSize: sizeMap[size].iconSize, color: '#fdd835' }} />}
      <Typography
        variant="body1"
        fontWeight={600}
        sx={{ fontSize: sizeMap[size].fontSize }}
      >
        {points.toLocaleString()}
      </Typography>
    </Box>
  );
}

// -----------------------------------------------------------------------------
// Tier Progress Card
// -----------------------------------------------------------------------------

interface TierProgressCardProps {
  customer: Customer;
  compact?: boolean;
}

export function TierProgressCard({ customer, compact = false }: TierProgressCardProps) {
  const tierConfig = LOYALTY_TIER_CONFIGS[customer.loyaltyTier];
  const pointsToNext = getPointsToNextTier(customer.loyaltyPoints, customer.loyaltyTier);
  const nextTier = customer.loyaltyTier === 'SILVER' ? 'GOLD' : customer.loyaltyTier === 'GOLD' ? 'PLATINUM' : null;
  
  const progressValue = nextTier
    ? (customer.loyaltyPoints / LOYALTY_TIER_CONFIGS[nextTier].minPoints) * 100
    : 100;

  if (compact) {
    return (
      <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
        <LoyaltyTierBadge tier={customer.loyaltyTier} size="small" />
        <Box sx={{ flex: 1 }}>
          <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
            <PointsDisplay points={customer.loyaltyPoints} size="small" />
            {nextTier && pointsToNext !== null && (
              <Typography variant="caption" sx={{ opacity: 0.7 }}>
                {pointsToNext} to {nextTier}
              </Typography>
            )}
          </Box>
          {nextTier && (
            <LinearProgress
              variant="determinate"
              value={Math.min(progressValue, 100)}
              sx={{
                height: 4,
                borderRadius: 2,
                mt: 0.5,
                bgcolor: 'rgba(255,255,255,0.1)',
                '& .MuiLinearProgress-bar': { bgcolor: tierConfig.color },
              }}
            />
          )}
        </Box>
      </Box>
    );
  }

  return (
    <Card sx={{ bgcolor: tierConfig.backgroundColor, border: `1px solid ${tierConfig.color}30` }}>
      <CardContent>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 2 }}>
          <Avatar sx={{ bgcolor: tierConfig.color, width: 48, height: 48 }}>
            <EmojiEvents />
          </Avatar>
          <Box>
            <Typography variant="h6" fontWeight={600} sx={{ color: tierConfig.color }}>
              {tierConfig.label} Member
            </Typography>
            <Typography variant="caption" sx={{ opacity: 0.8 }}>
              {tierConfig.description}
            </Typography>
          </Box>
        </Box>

        <Box sx={{ display: 'flex', alignItems: 'baseline', gap: 1, mb: 2 }}>
          <Typography variant="h3" fontWeight={700}>
            {customer.loyaltyPoints.toLocaleString()}
          </Typography>
          <Typography variant="body2" sx={{ opacity: 0.7 }}>
            points
          </Typography>
        </Box>

        {nextTier && pointsToNext !== null && (
          <>
            <LinearProgress
              variant="determinate"
              value={Math.min(progressValue, 100)}
              sx={{
                height: 8,
                borderRadius: 4,
                bgcolor: 'rgba(255,255,255,0.1)',
                '& .MuiLinearProgress-bar': { bgcolor: tierConfig.color },
              }}
            />
            <Box sx={{ display: 'flex', justifyContent: 'space-between', mt: 1 }}>
              <Typography variant="caption" sx={{ opacity: 0.7 }}>
                {customer.loyaltyPoints} pts
              </Typography>
              <Typography variant="caption" sx={{ opacity: 0.7 }}>
                {LOYALTY_TIER_CONFIGS[nextTier].minPoints} pts ({nextTier})
              </Typography>
            </Box>
          </>
        )}

        {customer.loyaltyTier === 'PLATINUM' && (
          <Alert severity="success" sx={{ mt: 2, bgcolor: 'rgba(76,175,80,0.1)' }}>
            You've reached the highest tier!
          </Alert>
        )}

        <Divider sx={{ my: 2, borderColor: 'rgba(255,255,255,0.1)' }} />

        <Typography variant="subtitle2" sx={{ mb: 1 }}>
          Your Benefits
        </Typography>
        <List dense disablePadding>
          {tierConfig.benefits.map((benefit, idx) => (
            <ListItem key={idx} disableGutters sx={{ py: 0.5 }}>
              <ListItemIcon sx={{ minWidth: 28 }}>
                <CheckCircle sx={{ fontSize: 16, color: tierConfig.color }} />
              </ListItemIcon>
              <ListItemText
                primary={benefit.replace(/\{symbol\}/g, getCurrencySymbol())}
                primaryTypographyProps={{ variant: 'body2', sx: { opacity: 0.9 } }}
              />
            </ListItem>
          ))}
        </List>
      </CardContent>
    </Card>
  );
}

// -----------------------------------------------------------------------------
// Points Earning Preview
// -----------------------------------------------------------------------------

interface PointsEarningPreviewProps {
  amount: number;
  tier: LoyaltyTier;
}

export function PointsEarningPreview({ amount, tier }: PointsEarningPreviewProps) {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';
  
  const points = calculatePointsEarned(amount, tier);
  const tierConfig = LOYALTY_TIER_CONFIGS[tier];

  return (
    <Paper sx={{ p: 2, bgcolor: dk ? '#1a1a2e' : '#fff', border: `1px solid rgba(253,216,53,${dk ? 0.2 : 0.3})` }}>
      <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
        <Star sx={{ color: '#fdd835', fontSize: 28 }} />
        <Box>
          <Typography variant="body2" sx={{ opacity: 0.7 }}>
            Points to earn
          </Typography>
          <Typography variant="h6" fontWeight={600} sx={{ color: '#fdd835' }}>
            +{points} points
          </Typography>
          {tier !== 'SILVER' && (
            <Typography variant="caption" sx={{ opacity: 0.6 }}>
              {tierConfig.pointsMultiplier}x {tierConfig.label} bonus applied
            </Typography>
          )}
        </Box>
      </Box>
    </Paper>
  );
}

// -----------------------------------------------------------------------------
// Points Redemption Dialog
// -----------------------------------------------------------------------------

interface PointsRedemptionDialogProps {
  open: boolean;
  onClose: () => void;
  customer: Customer;
  onRedeem: (points: number) => void;
  maxRedeemable?: number;
}

export function PointsRedemptionDialog({
  open,
  onClose,
  customer,
  onRedeem,
  maxRedeemable,
}: PointsRedemptionDialogProps) {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';
  
  const [pointsToRedeem, setPointsToRedeem] = useState(100);
  const availablePoints = customer.loyaltyPoints;
  const maxPoints = maxRedeemable ?? availablePoints;
  const minPoints = DEFAULT_LOYALTY_CONFIG.minRedeemPoints;
  const discountValue = pointsToRedeem * DEFAULT_LOYALTY_CONFIG.currencyPerPoint;

  const canRedeem = pointsToRedeem >= minPoints && pointsToRedeem <= maxPoints;

  return (
    <Dialog open={open} onClose={onClose} maxWidth="sm" fullWidth>
      <DialogTitle>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
          <Redeem sx={{ color: '#fdd835' }} />
          Redeem Loyalty Points
        </Box>
      </DialogTitle>
      <DialogContent>
        <Box sx={{ py: 2 }}>
          {/* Available Points */}
          <Paper sx={{ p: 2, bgcolor: dk ? '#1a1a2e' : '#fff', mb: 3 }}>
            <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
              <Typography variant="body2" sx={{ opacity: 0.7 }}>
                Available Points
              </Typography>
              <PointsDisplay points={availablePoints} />
            </Box>
          </Paper>

          {/* Points Input */}
          <Typography variant="subtitle2" sx={{ mb: 1 }}>
            Points to Redeem
          </Typography>
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 2 }}>
            <IconButton
              onClick={() => setPointsToRedeem((p) => Math.max(minPoints, p - 50))}
              disabled={pointsToRedeem <= minPoints}
            >
              <Remove />
            </IconButton>
            <TextField
              type="number"
              value={pointsToRedeem}
              onChange={(e) => setPointsToRedeem(Math.min(maxPoints, Math.max(0, Number(e.target.value))))}
              size="small"
              sx={{ width: 120, textAlign: 'center' }}
              inputProps={{ style: { textAlign: 'center' } }}
            />
            <IconButton
              onClick={() => setPointsToRedeem((p) => Math.min(maxPoints, p + 50))}
              disabled={pointsToRedeem >= maxPoints}
            >
              <Add />
            </IconButton>
          </Box>

          {/* Quick Select */}
          <Stack direction="row" spacing={1} sx={{ mb: 3 }}>
            {[100, 200, 500, 1000].filter(p => p <= maxPoints).map((pts) => (
              <Chip
                key={pts}
                label={`${pts} pts`}
                onClick={() => setPointsToRedeem(pts)}
                variant={pointsToRedeem === pts ? 'filled' : 'outlined'}
                sx={{
                  bgcolor: pointsToRedeem === pts ? '#fdd835' : 'transparent',
                  color: pointsToRedeem === pts ? '#000' : 'inherit',
                }}
              />
            ))}
            <Chip
              label="Max"
              onClick={() => setPointsToRedeem(maxPoints)}
              variant={pointsToRedeem === maxPoints ? 'filled' : 'outlined'}
              sx={{
                bgcolor: pointsToRedeem === maxPoints ? '#fdd835' : 'transparent',
                color: pointsToRedeem === maxPoints ? '#000' : 'inherit',
              }}
            />
          </Stack>

          {/* Discount Preview */}
          <Paper sx={{ p: 2, bgcolor: 'rgba(76,175,80,0.1)', border: '1px solid rgba(76,175,80,0.3)' }}>
            <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
              <Typography variant="body2">
                Discount Value
              </Typography>
              <Typography variant="h5" fontWeight={600} sx={{ color: '#4caf50' }}>
                {formatCurrency(discountValue)}
              </Typography>
            </Box>
            <Typography variant="caption" sx={{ opacity: 0.7 }}>
              1 point = {getCurrencySymbol()}{DEFAULT_LOYALTY_CONFIG.currencyPerPoint}
            </Typography>
          </Paper>

          {pointsToRedeem < minPoints && (
            <Alert severity="warning" sx={{ mt: 2 }}>
              Minimum {minPoints} points required to redeem
            </Alert>
          )}
        </Box>
      </DialogContent>
      <DialogActions>
        <Button onClick={onClose}>Cancel</Button>
        <Button
          variant="contained"
          onClick={() => {
            onRedeem(pointsToRedeem);
            onClose();
          }}
          disabled={!canRedeem}
          sx={{ bgcolor: '#fdd835', color: '#000' }}
        >
          Redeem {pointsToRedeem} Points
        </Button>
      </DialogActions>
    </Dialog>
  );
}

// -----------------------------------------------------------------------------
// Loyalty Transaction Item
// -----------------------------------------------------------------------------

interface LoyaltyTransactionItemProps {
  transaction: LoyaltyTransaction;
}

export function LoyaltyTransactionItem({ transaction }: LoyaltyTransactionItemProps) {
  const isPositive = transaction.type === 'EARN' || transaction.type === 'BONUS';
  const typeColors: Record<LoyaltyTransactionType, string> = {
    EARN: '#4caf50',
    REDEEM: '#2196f3',
    EXPIRE: '#f44336',
    ADJUST: '#ff9800',
    BONUS: '#9c27b0',
  };

  return (
    <Box
      sx={{
        display: 'flex',
        alignItems: 'center',
        gap: 2,
        py: 1.5,
        borderBottom: '1px solid rgba(255,255,255,0.05)',
      }}
    >
      <Avatar
        sx={{
          bgcolor: `${typeColors[transaction.type]}20`,
          color: typeColors[transaction.type],
          width: 36,
          height: 36,
        }}
      >
        {transaction.type === 'EARN' && <TrendingUp sx={{ fontSize: 18 }} />}
        {transaction.type === 'REDEEM' && <Redeem sx={{ fontSize: 18 }} />}
        {transaction.type === 'BONUS' && <CardGiftcard sx={{ fontSize: 18 }} />}
        {transaction.type === 'EXPIRE' && <History sx={{ fontSize: 18 }} />}
        {transaction.type === 'ADJUST' && <Info sx={{ fontSize: 18 }} />}
      </Avatar>

      <Box sx={{ flex: 1 }}>
        <Typography variant="body2" fontWeight={500}>
          {transaction.description}
        </Typography>
        <Typography variant="caption" sx={{ opacity: 0.6 }}>
          {new Date(transaction.createdAt).toLocaleDateString()}
        </Typography>
      </Box>

      <Box sx={{ textAlign: 'right' }}>
        <Typography
          variant="body2"
          fontWeight={600}
          sx={{ color: isPositive ? '#4caf50' : '#f44336' }}
        >
          {isPositive ? '+' : ''}{transaction.points}
        </Typography>
        <Typography variant="caption" sx={{ opacity: 0.6 }}>
          Bal: {transaction.balance}
        </Typography>
      </Box>
    </Box>
  );
}

// -----------------------------------------------------------------------------
// Tier Comparison Card
// -----------------------------------------------------------------------------

export function TierComparisonCard() {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';
  
  return (
    <Paper sx={{ p: 3, bgcolor: dk ? '#1a1a2e' : '#fff' }}>
      <Typography variant="h6" fontWeight={600} sx={{ mb: 2 }}>
        Loyalty Tiers
      </Typography>
      
      <Grid container spacing={2}>
        {(['SILVER', 'GOLD', 'PLATINUM'] as LoyaltyTier[]).map((tier) => {
          const config = LOYALTY_TIER_CONFIGS[tier];
          return (
            <Grid size={{ xs: 12, md: 4 }} key={tier}>
              <Card
                sx={{
                  bgcolor: config.backgroundColor,
                  border: `1px solid ${config.color}30`,
                  height: '100%',
                }}
              >
                <CardContent>
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 2 }}>
                    <EmojiEvents sx={{ color: config.color }} />
                    <Typography variant="h6" sx={{ color: config.color }}>
                      {config.label}
                    </Typography>
                  </Box>

                  <Typography variant="body2" sx={{ mb: 2, opacity: 0.8 }}>
                    {tier === 'SILVER' ? 'Starting tier' : `${config.minPoints}+ points`}
                  </Typography>

                  <Chip
                    label={`${config.pointsMultiplier}x Points`}
                    size="small"
                    sx={{
                      bgcolor: `${config.color}30`,
                      color: config.color,
                      fontWeight: 600,
                      mb: 2,
                    }}
                  />

                  <List dense disablePadding>
                    {config.benefits.map((benefit, idx) => (
                      <ListItem key={idx} disableGutters sx={{ py: 0.25 }}>
                        <ListItemIcon sx={{ minWidth: 24 }}>
                          <CheckCircle sx={{ fontSize: 14, color: config.color }} />
                        </ListItemIcon>
                        <ListItemText
                          primary={benefit.replace(/\{symbol\}/g, getCurrencySymbol())}
                          primaryTypographyProps={{ variant: 'caption' }}
                        />
                      </ListItem>
                    ))}
                  </List>
                </CardContent>
              </Card>
            </Grid>
          );
        })}
      </Grid>
    </Paper>
  );
}

// -----------------------------------------------------------------------------
// Points Summary Widget (for POS/checkout)
// -----------------------------------------------------------------------------

interface PointsSummaryWidgetProps {
  customer: Customer;
  orderAmount: number;
  onRedeem?: () => void;
}

export function PointsSummaryWidget({ customer, orderAmount, onRedeem }: PointsSummaryWidgetProps) {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';
  
  const pointsToEarn = calculatePointsEarned(orderAmount, customer.loyaltyTier);
  const tierConfig = LOYALTY_TIER_CONFIGS[customer.loyaltyTier];

  return (
    <Paper sx={{ p: 2, bgcolor: dk ? '#1a1a2e' : '#fff', border: `1px solid rgba(253,216,53,${dk ? 0.2 : 0.3})` }}>
      <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', mb: 2 }}>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
          <Star sx={{ color: '#fdd835' }} />
          <Typography variant="subtitle1" fontWeight={600}>
            Loyalty Points
          </Typography>
        </Box>
        <LoyaltyTierBadge tier={customer.loyaltyTier} size="small" />
      </Box>

      <Grid container spacing={2}>
        <Grid size={{ xs: 6 }}>
          <Typography variant="caption" sx={{ opacity: 0.7 }}>
            Available
          </Typography>
          <Typography variant="h6" fontWeight={600}>
            {customer.loyaltyPoints.toLocaleString()}
          </Typography>
        </Grid>
        <Grid size={{ xs: 6 }}>
          <Typography variant="caption" sx={{ opacity: 0.7 }}>
            Will Earn
          </Typography>
          <Typography variant="h6" fontWeight={600} sx={{ color: '#4caf50' }}>
            +{pointsToEarn}
          </Typography>
        </Grid>
      </Grid>

      {customer.loyaltyPoints >= DEFAULT_LOYALTY_CONFIG.minRedeemPoints && onRedeem && (
        <Button
          fullWidth
          variant="outlined"
          startIcon={<Redeem />}
          onClick={onRedeem}
          sx={{
            mt: 2,
            borderColor: '#fdd835',
            color: '#fdd835',
            '&:hover': { bgcolor: 'rgba(253,216,53,0.1)' },
          }}
        >
          Redeem Points
        </Button>
      )}
    </Paper>
  );
}
