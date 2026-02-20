/**
 * OrderDiscountModal.tsx — Compact modal for applying order-level discounts
 *
 * Features:
 * - Toggle between Percentage and Flat discount types
 * - Preset buttons for common discounts (5%, 10%, 15%, $5, $10)
 * - Manual numeric input for custom values
 * - Optional reason field
 * - Touch-friendly design with smooth transitions
 * - Role-based permission checks with approval workflow
 */
import React, { useState, useEffect, useCallback } from 'react';
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  TextField,
  Box,
  Typography,
  ToggleButton,
  ToggleButtonGroup,
  IconButton,
  useTheme,
  Chip,
  Alert,
  CircularProgress,
} from '@mui/material';
import {
  Close as CloseIcon,
  LocalOffer as DiscountIcon,
  Security as SecurityIcon,
} from '@mui/icons-material';
import type { OrderDiscount } from '../orders/OrderTypes';
import { fmtCurrency, fmtPercent } from './CartUtils';
import { useDiscountPermissions } from '../../core/rbac/useDiscountPermissions';

interface Props {
  open: boolean;
  onClose: () => void;
  onApply: (discount: OrderDiscount) => void;
  currentDiscount: OrderDiscount | null;
  subtotal: number;
}

const PERCENT_PRESETS = [5, 10, 15];
const FLAT_PRESETS = [5, 10, 20];

const OrderDiscountModal: React.FC<Props> = ({
  open,
  onClose,
  onApply,
  currentDiscount,
  subtotal,
}) => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';

  const { permissions, applyDiscount, checkDiscount, calculateDiscountAmount } =
    useDiscountPermissions();

  const [discountType, setDiscountType] = useState<'PERCENT' | 'FLAT'>(
    currentDiscount?.type ?? 'PERCENT'
  );
  const [value, setValue] = useState<string>(
    currentDiscount?.value?.toString() ?? ''
  );
  const [reason, setReason] = useState(currentDiscount?.reason ?? '');
  const [isApplying, setIsApplying] = useState(false);
  const [applyError, setApplyError] = useState<string | null>(null);

  // Reset form when modal opens with current discount
  useEffect(() => {
    if (open) {
      setDiscountType(currentDiscount?.type ?? 'PERCENT');
      setValue(currentDiscount?.value?.toString() ?? '');
      setReason(currentDiscount?.reason ?? '');
      setApplyError(null);
    }
  }, [open, currentDiscount]);

  const handleTypeChange = (_: React.MouseEvent, newType: 'PERCENT' | 'FLAT' | null) => {
    if (newType) {
      setDiscountType(newType);
      setValue(''); // Clear value when switching types
      setApplyError(null);
    }
  };

  const handlePresetClick = (preset: number) => {
    setValue(preset.toString());
    setApplyError(null);
  };

  const handleApply = useCallback(async () => {
    const numValue = parseFloat(value);
    if (isNaN(numValue) || numValue <= 0) return;

    // Validate: discount cannot exceed subtotal
    const maxDiscount = discountType === 'PERCENT' ? 100 : subtotal;
    const clampedValue = Math.min(numValue, maxDiscount);

    setIsApplying(true);
    setApplyError(null);

    try {
      // Apply with permission check and potential approval flow
      const result = await applyDiscount({
        discountType: 'ORDER',
        discountMethod: discountType,
        discountValue: clampedValue,
        subtotalOrLineGross: subtotal,
      });

      if (result.success) {
        onApply({
          type: discountType,
          value: clampedValue,
          reason: reason.trim() || undefined,
        });
        onClose();
      } else {
        setApplyError(result.error || 'Discount was not approved');
      }
    } catch (err) {
      setApplyError('An error occurred while applying the discount');
    } finally {
      setIsApplying(false);
    }
  }, [value, discountType, reason, subtotal, onApply, onClose, applyDiscount]);

  // Calculate preview amount
  const numValue = parseFloat(value) || 0;
  const previewAmount =
    discountType === 'PERCENT'
      ? Math.min(subtotal * (numValue / 100), subtotal)
      : Math.min(numValue, subtotal);

  const isValid = numValue > 0;

  // Check if current value exceeds user's limit (for visual indicator)
  const validation = isValid
    ? checkDiscount({
        discountType: 'ORDER',
        discountMethod: discountType,
        discountValue: numValue,
        subtotalOrLineGross: subtotal,
      })
    : null;

  // User's max limit display
  const userMaxDisplay =
    permissions.maxOrderPercent !== null ? `${permissions.maxOrderPercent}%` : 'Unlimited';

  const PresetButton = ({ preset }: { preset: number }) => {
    const isSelected = value === preset.toString();
    const label = discountType === 'PERCENT' ? `${preset}%` : fmtCurrency(preset);

    return (
      <Button
        variant={isSelected ? 'contained' : 'outlined'}
        onClick={() => handlePresetClick(preset)}
        sx={{
          minWidth: 64,
          minHeight: 48,
          fontWeight: 700,
          fontSize: '0.95rem',
          borderRadius: 2,
          transition: 'all 0.15s ease-out',
          ...(dk
            ? {
                borderColor: isSelected ? undefined : 'rgba(255,255,255,0.2)',
                color: isSelected ? '#000' : '#e0e0e0',
                bgcolor: isSelected ? '#fdd835' : 'transparent',
                '&:hover': {
                  bgcolor: isSelected ? '#fbc02d' : 'rgba(255,255,255,0.08)',
                  borderColor: 'rgba(255,255,255,0.4)',
                },
              }
            : {}),
        }}
      >
        {label}
      </Button>
    );
  };

  return (
    <Dialog
      open={open}
      onClose={onClose}
      maxWidth="xs"
      fullWidth
      PaperProps={{
        sx: {
          borderRadius: 3,
          bgcolor: dk ? '#1a1a2e' : '#fff',
          backgroundImage: 'none',
        },
      }}
      TransitionProps={{
        timeout: { enter: 200, exit: 150 },
      }}
    >
      {/* Header */}
      <DialogTitle
        sx={{
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          pb: 1,
        }}
      >
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
          <DiscountIcon sx={{ color: theme.palette.primary.main }} />
          <Typography variant="h6" sx={{ fontWeight: 700 }}>
            Order Discount
          </Typography>
        </Box>
        <IconButton onClick={onClose} size="small">
          <CloseIcon />
        </IconButton>
      </DialogTitle>

      <DialogContent sx={{ pt: 1 }}>
        {/* Discount Type Toggle */}
        <Box sx={{ mb: 2.5 }}>
          <Typography variant="caption" sx={{ color: 'text.secondary', mb: 1, display: 'block' }}>
            Discount Type
          </Typography>
          <ToggleButtonGroup
            value={discountType}
            exclusive
            onChange={handleTypeChange}
            fullWidth
            sx={{
              '& .MuiToggleButton-root': {
                py: 1.25,
                fontWeight: 700,
                textTransform: 'none',
                fontSize: '0.9rem',
                ...(dk
                  ? {
                      color: 'rgba(255,255,255,0.7)',
                      borderColor: 'rgba(255,255,255,0.15)',
                      '&.Mui-selected': {
                        bgcolor: 'rgba(253,216,53,0.15)',
                        color: '#fdd835',
                        borderColor: '#fdd835',
                      },
                    }
                  : {}),
              },
            }}
          >
            <ToggleButton value="PERCENT">Percentage (%)</ToggleButton>
            <ToggleButton value="FLAT">Flat Amount ($)</ToggleButton>
          </ToggleButtonGroup>
        </Box>

        {/* Preset Buttons - Touch Friendly */}
        <Box sx={{ mb: 2.5 }}>
          <Typography variant="caption" sx={{ color: 'text.secondary', mb: 1, display: 'block' }}>
            Quick Select
          </Typography>
          <Box sx={{ display: 'flex', gap: 1, justifyContent: 'center' }}>
            {(discountType === 'PERCENT' ? PERCENT_PRESETS : FLAT_PRESETS).map((preset) => (
              <PresetButton key={preset} preset={preset} />
            ))}
          </Box>
        </Box>

        {/* Manual Input */}
        <Box sx={{ mb: 2.5 }}>
          <Typography variant="caption" sx={{ color: 'text.secondary', mb: 1, display: 'block' }}>
            Custom Amount
          </Typography>
          <TextField
            type="number"
            fullWidth
            size="medium"
            placeholder={discountType === 'PERCENT' ? 'Enter percentage' : 'Enter amount'}
            value={value}
            onChange={(e) => setValue(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === 'Enter' && isValid) handleApply();
            }}
            slotProps={{
              input: {
                startAdornment: (
                  <Typography
                    sx={{
                      color: dk ? 'rgba(255,255,255,0.5)' : 'text.secondary',
                      mr: 0.5,
                      fontWeight: 600,
                    }}
                  >
                    {discountType === 'PERCENT' ? '%' : '$'}
                  </Typography>
                ),
                sx: {
                  fontSize: '1.1rem',
                  fontWeight: 600,
                  ...(dk ? { color: '#e0e0e0' } : {}),
                },
              },
            }}
            sx={{
              '& .MuiOutlinedInput-root': {
                ...(dk ? { '& fieldset': { borderColor: 'rgba(255,255,255,0.15)' } } : {}),
              },
            }}
          />
        </Box>

        {/* Optional Reason */}
        <Box sx={{ mb: 2 }}>
          <Typography variant="caption" sx={{ color: 'text.secondary', mb: 1, display: 'block' }}>
            Reason (optional)
          </Typography>
          <TextField
            fullWidth
            size="small"
            placeholder="e.g., Loyalty customer, Manager approval"
            value={reason}
            onChange={(e) => setReason(e.target.value)}
            sx={{
              '& .MuiOutlinedInput-root': {
                ...(dk ? { '& fieldset': { borderColor: 'rgba(255,255,255,0.15)' } } : {}),
              },
            }}
          />
        </Box>

        {/* Preview */}
        {isValid && (
          <Box
            sx={{
              p: 1.5,
              borderRadius: 2,
              bgcolor: validation?.allowed
                ? dk ? 'rgba(76,175,80,0.15)' : 'rgba(76,175,80,0.08)'
                : dk ? 'rgba(255,193,7,0.15)' : 'rgba(255,193,7,0.08)',
              border: `1px solid ${
                validation?.allowed
                  ? dk ? 'rgba(76,175,80,0.3)' : 'rgba(76,175,80,0.2)'
                  : dk ? 'rgba(255,193,7,0.3)' : 'rgba(255,193,7,0.2)'
              }`,
            }}
          >
            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <Typography variant="body2" sx={{ color: 'text.secondary' }}>
                Discount Amount
              </Typography>
              <Typography
                variant="body1"
                sx={{ fontWeight: 700, color: theme.palette.success.main }}
              >
                -{fmtCurrency(previewAmount)}
              </Typography>
            </Box>
            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mt: 0.5 }}>
              <Typography variant="body2" sx={{ color: 'text.secondary' }}>
                New Total
              </Typography>
              <Typography variant="body1" sx={{ fontWeight: 700 }}>
                {fmtCurrency(Math.max(0, subtotal - previewAmount))}
              </Typography>
            </Box>

            {/* Permission indicator */}
            {validation && !validation.allowed && validation.requiresApproval && (
              <Box
                sx={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: 0.75,
                  mt: 1.5,
                  pt: 1,
                  borderTop: `1px solid ${dk ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.1)'}`,
                }}
              >
                <SecurityIcon sx={{ fontSize: 16, color: theme.palette.warning.main }} />
                <Typography variant="caption" sx={{ color: theme.palette.warning.main, fontWeight: 600 }}>
                  Exceeds your limit ({validation.maxAllowed}%) — Manager approval required
                </Typography>
              </Box>
            )}
          </Box>
        )}

        {/* Your Limit Info */}
        <Box
          sx={{
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
            mt: 2,
            px: 0.5,
          }}
        >
          <Typography variant="caption" sx={{ color: 'text.disabled' }}>
            Your limit: {userMaxDisplay}
          </Typography>
          <Chip
            label={permissions.role}
            size="small"
            sx={{
              height: 20,
              fontSize: '0.65rem',
              fontWeight: 600,
              bgcolor: dk ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.06)',
            }}
          />
        </Box>

        {/* Apply Error */}
        {applyError && (
          <Alert severity="error" sx={{ mt: 1.5, fontSize: '0.85rem' }}>
            {applyError}
          </Alert>
        )}
      </DialogContent>

      <DialogActions sx={{ px: 3, pb: 2.5, pt: 1 }}>
        <Button
          onClick={onClose}
          disabled={isApplying}
          sx={{
            fontWeight: 600,
            ...(dk ? { color: 'rgba(255,255,255,0.7)' } : {}),
          }}
        >
          Cancel
        </Button>
        <Button
          variant="contained"
          disabled={!isValid || isApplying}
          onClick={handleApply}
          startIcon={isApplying ? <CircularProgress size={18} color="inherit" /> : undefined}
          sx={{
            minWidth: 120,
            minHeight: 44,
            fontWeight: 700,
            fontSize: '0.95rem',
            transition: 'all 0.15s ease-out',
            ...(dk
              ? {
                  bgcolor: '#fdd835',
                  color: '#000',
                  '&:hover': {
                    bgcolor: '#fbc02d',
                    transform: 'translateY(-1px)',
                  },
                  '&.Mui-disabled': {
                    bgcolor: 'rgba(255,255,255,0.12)',
                    color: 'rgba(255,255,255,0.3)',
                  },
                }
              : {}),
          }}
        >
          {isApplying ? 'Checking...' : 'Apply Discount'}
        </Button>
      </DialogActions>
    </Dialog>
  );
};

export default OrderDiscountModal;
