/**
 * LineItemDiscountPopover.tsx — Compact inline popover for line-item discounts
 *
 * Features:
 * - Toggle between Percentage and Flat discount types
 * - Preset buttons for common discounts (5%, 10%, $5)
 * - Manual numeric input for custom values
 * - Smooth animations and touch-friendly design
 * - Role-based permission checks with approval workflow
 */
import React, { useState, useEffect, useRef, useCallback } from 'react';
import {
  Popover,
  Box,
  Typography,
  Button,
  TextField,
  ToggleButton,
  ToggleButtonGroup,
  IconButton,
  useTheme,
  Alert,
  CircularProgress,
} from '@mui/material';
import {
  Close as CloseIcon,
  LocalOffer as DiscountIcon,
  Percent as PercentIcon,
  AttachMoney as MoneyIcon,
  Security as SecurityIcon,
} from '@mui/icons-material';
import type { LineItemDiscount } from '../orders/OrderTypes';
import { fmtCurrency } from './CartUtils';
import { useDiscountPermissions } from '../../core/rbac/useDiscountPermissions';

interface Props {
  anchorEl: HTMLElement | null;
  open: boolean;
  onClose: () => void;
  onApply: (discount: LineItemDiscount | null) => void;
  currentDiscount: LineItemDiscount | null | undefined;
  lineGross: number; // unitPrice * quantity (maximum discount)
  productName?: string; // For audit logging
  lineItemId?: string; // For audit logging
}

const PERCENT_PRESETS = [5, 10, 15];
const FLAT_PRESETS = [5, 10];

const LineItemDiscountPopover: React.FC<Props> = ({
  anchorEl,
  open,
  onClose,
  onApply,
  currentDiscount,
  lineGross,
  productName,
  lineItemId,
}) => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';
  const inputRef = useRef<HTMLInputElement>(null);

  const { permissions, applyDiscount, checkDiscount } = useDiscountPermissions();

  const [discountType, setDiscountType] = useState<'PERCENT' | 'FLAT'>(
    currentDiscount?.type ?? 'PERCENT'
  );
  const [value, setValue] = useState<string>(
    currentDiscount?.value?.toString() ?? ''
  );
  const [isApplying, setIsApplying] = useState(false);
  const [applyError, setApplyError] = useState<string | null>(null);

  // Reset form when popover opens
  useEffect(() => {
    if (open) {
      setDiscountType(currentDiscount?.type ?? 'PERCENT');
      setValue(currentDiscount?.value?.toString() ?? '');
      setApplyError(null);
      // Focus input after a short delay
      setTimeout(() => inputRef.current?.focus(), 100);
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
    if (isNaN(numValue) || numValue <= 0) {
      // Clear discount
      onApply(null);
      onClose();
      return;
    }

    // Clamp value
    const maxValue = discountType === 'PERCENT' ? 100 : lineGross;
    const clampedValue = Math.min(numValue, maxValue);

    setIsApplying(true);
    setApplyError(null);

    try {
      // Apply with permission check and potential approval flow
      const result = await applyDiscount({
        discountType: 'LINE',
        discountMethod: discountType,
        discountValue: clampedValue,
        subtotalOrLineGross: lineGross,
        productName,
        lineItemId,
      });

      if (result.success) {
        onApply({
          type: discountType,
          value: clampedValue,
        });
        onClose();
      } else {
        setApplyError(result.error || 'Discount was not approved');
      }
    } catch (err) {
      setApplyError('Error applying discount');
    } finally {
      setIsApplying(false);
    }
  }, [value, discountType, lineGross, productName, lineItemId, applyDiscount, onApply, onClose]);

  const handleClear = () => {
    onApply(null);
    onClose();
  };

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter') handleApply();
    if (e.key === 'Escape') onClose();
  };

  // Calculate preview amount
  const numValue = parseFloat(value) || 0;
  const previewAmount =
    discountType === 'PERCENT'
      ? Math.min(lineGross * (numValue / 100), lineGross)
      : Math.min(numValue, lineGross);

  // Check if current value exceeds user's limit
  const validation = numValue > 0
    ? checkDiscount({
        discountType: 'LINE',
        discountMethod: discountType,
        discountValue: numValue,
        subtotalOrLineGross: lineGross,
      })
    : null;

  const hasDiscount = currentDiscount && currentDiscount.value > 0;

  const PresetButton = ({ preset }: { preset: number }) => {
    const isSelected = value === preset.toString();
    const label = discountType === 'PERCENT' ? `${preset}%` : `$${preset}`;

    return (
      <Button
        variant={isSelected ? 'contained' : 'outlined'}
        size="small"
        onClick={() => handlePresetClick(preset)}
        sx={{
          minWidth: 44,
          minHeight: 36,
          fontWeight: 700,
          fontSize: '0.8rem',
          borderRadius: 1.5,
          px: 1,
          transition: 'all 0.12s ease-out',
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
    <Popover
      open={open}
      anchorEl={anchorEl}
      onClose={onClose}
      anchorOrigin={{
        vertical: 'bottom',
        horizontal: 'center',
      }}
      transformOrigin={{
        vertical: 'top',
        horizontal: 'center',
      }}
      slotProps={{
        paper: {
          sx: {
            borderRadius: 2,
            bgcolor: dk ? '#1a1a2e' : '#fff',
            backgroundImage: 'none',
            border: dk ? '1px solid rgba(255,255,255,0.1)' : '1px solid #e0e0e0',
            boxShadow: dk
              ? '0 8px 24px rgba(0,0,0,0.5)'
              : '0 8px 24px rgba(0,0,0,0.15)',
            minWidth: 220,
            maxWidth: 280,
          },
        },
      }}
      TransitionProps={{
        timeout: { enter: 150, exit: 100 },
      }}
    >
      <Box sx={{ p: 1.5 }}>
        {/* Header */}
        <Box
          sx={{
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
            mb: 1.5,
          }}
        >
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
            <DiscountIcon sx={{ fontSize: 16, color: theme.palette.primary.main }} />
            <Typography variant="subtitle2" sx={{ fontWeight: 700, fontSize: '0.85rem' }}>
              Line Discount
            </Typography>
          </Box>
          <IconButton size="small" onClick={onClose} sx={{ p: 0.25 }}>
            <CloseIcon sx={{ fontSize: 16 }} />
          </IconButton>
        </Box>

        {/* Type Toggle */}
        <ToggleButtonGroup
          value={discountType}
          exclusive
          onChange={handleTypeChange}
          fullWidth
          size="small"
          sx={{
            mb: 1.5,
            '& .MuiToggleButton-root': {
              py: 0.5,
              fontWeight: 600,
              fontSize: '0.75rem',
              textTransform: 'none',
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
          <ToggleButton value="PERCENT">
            <PercentIcon sx={{ fontSize: 14, mr: 0.5 }} />
            Percent
          </ToggleButton>
          <ToggleButton value="FLAT">
            <MoneyIcon sx={{ fontSize: 14, mr: 0.5 }} />
            Flat
          </ToggleButton>
        </ToggleButtonGroup>

        {/* Preset Buttons */}
        <Box sx={{ display: 'flex', gap: 0.75, mb: 1.5, justifyContent: 'center' }}>
          {(discountType === 'PERCENT' ? PERCENT_PRESETS : FLAT_PRESETS).map((preset) => (
            <PresetButton key={preset} preset={preset} />
          ))}
        </Box>

        {/* Manual Input */}
        <TextField
          inputRef={inputRef}
          type="number"
          fullWidth
          size="small"
          placeholder={discountType === 'PERCENT' ? 'Custom %' : 'Custom $'}
          value={value}
          onChange={(e) => setValue(e.target.value)}
          onKeyDown={handleKeyDown}
          slotProps={{
            input: {
              startAdornment: (
                <Typography
                  sx={{
                    color: dk ? 'rgba(255,255,255,0.5)' : 'text.secondary',
                    mr: 0.5,
                    fontSize: '0.85rem',
                    fontWeight: 600,
                  }}
                >
                  {discountType === 'PERCENT' ? '%' : '$'}
                </Typography>
              ),
              sx: {
                fontSize: '0.9rem',
                fontWeight: 600,
                py: 0.25,
                ...(dk ? { color: '#e0e0e0' } : {}),
              },
            },
          }}
          sx={{
            mb: 1.5,
            '& .MuiOutlinedInput-root': {
              ...(dk ? { '& fieldset': { borderColor: 'rgba(255,255,255,0.15)' } } : {}),
            },
          }}
        />

        {/* Preview */}
        {numValue > 0 && (
          <Box
            sx={{
              py: 0.75,
              px: 1,
              mb: 1.5,
              borderRadius: 1,
              bgcolor: validation?.allowed
                ? dk ? 'rgba(76,175,80,0.12)' : 'rgba(76,175,80,0.08)'
                : dk ? 'rgba(255,193,7,0.12)' : 'rgba(255,193,7,0.08)',
              border: `1px solid ${
                validation?.allowed
                  ? dk ? 'rgba(76,175,80,0.3)' : 'rgba(76,175,80,0.2)'
                  : dk ? 'rgba(255,193,7,0.3)' : 'rgba(255,193,7,0.2)'
              }`,
            }}
          >
            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <Typography variant="caption" sx={{ color: 'text.secondary' }}>
                Saves
              </Typography>
              <Typography
                variant="body2"
                sx={{ fontWeight: 700, color: theme.palette.success.main, fontSize: '0.85rem' }}
              >
                -{fmtCurrency(previewAmount)}
              </Typography>
            </Box>
            {/* Permission indicator */}
            {validation && !validation.allowed && validation.requiresApproval && (
              <Box
                sx={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: 0.5,
                  mt: 0.5,
                  pt: 0.5,
                  borderTop: `1px solid ${dk ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.08)'}`,
                }}
              >
                <SecurityIcon sx={{ fontSize: 12, color: theme.palette.warning.main }} />
                <Typography
                  variant="caption"
                  sx={{ color: theme.palette.warning.main, fontWeight: 600, fontSize: '0.65rem' }}
                >
                  Needs approval ({validation.maxAllowed}% max)
                </Typography>
              </Box>
            )}
          </Box>
        )}

        {/* Error */}
        {applyError && (
          <Alert severity="error" sx={{ mb: 1.5, py: 0.25, '& .MuiAlert-message': { fontSize: '0.75rem' } }}>
            {applyError}
          </Alert>
        )}

        {/* Actions */}
        <Box sx={{ display: 'flex', gap: 1 }}>
          {hasDiscount && (
            <Button
              variant="outlined"
              size="small"
              color="error"
              onClick={handleClear}
              disabled={isApplying}
              sx={{
                flex: 1,
                fontWeight: 600,
                fontSize: '0.75rem',
                textTransform: 'none',
                py: 0.75,
              }}
            >
              Clear
            </Button>
          )}
          <Button
            variant="contained"
            size="small"
            onClick={handleApply}
            disabled={isApplying}
            startIcon={isApplying ? <CircularProgress size={14} color="inherit" /> : undefined}
            sx={{
              flex: hasDiscount ? 1 : undefined,
              width: hasDiscount ? undefined : '100%',
              fontWeight: 700,
              fontSize: '0.8rem',
              textTransform: 'none',
              py: 0.75,
              transition: 'all 0.12s ease-out',
              ...(dk
                ? {
                    bgcolor: '#fdd835',
                    color: '#000',
                    '&:hover': {
                      bgcolor: '#fbc02d',
                    },
                    '&.Mui-disabled': {
                      bgcolor: 'rgba(255,255,255,0.12)',
                      color: 'rgba(255,255,255,0.3)',
                    },
                  }
                : {}),
            }}
          >
            {isApplying ? '...' : 'Apply'}
          </Button>
        </Box>
      </Box>
    </Popover>
  );
};

export default LineItemDiscountPopover;
