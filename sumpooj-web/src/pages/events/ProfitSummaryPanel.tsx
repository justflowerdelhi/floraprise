/**
 * ProfitSummaryPanel.tsx — Margin Intelligence Panel
 * 
 * Shows real-time profit calculations with color-coded warnings:
 * - Green (≥30%): Healthy margin
 * - Yellow (≥20%, <30%): Warning
 * - Red (<20%): Danger zone
 */
import React from 'react';
import {
  Box,
  Paper,
  Typography,
  Divider,
  Chip,
  LinearProgress,
  TextField,
  MenuItem,
  Stack,
  Tooltip,
  IconButton,
  Alert,
} from '@mui/material';
import {
  TrendingUp as ProfitIcon,
  Warning as WarningIcon,
  MonetizationOn as RevenueIcon,
  AccountBalance as CostIcon,
  Info as InfoIcon,
  LocalOffer as DiscountIcon,
  Receipt as TaxIcon,
} from '@mui/icons-material';
import { getMarginColor, getMarginStatus, MARGIN_THRESHOLDS } from './ProposalTypes';

// ─── Types ──────────────────────────────────────────────────

interface ProfitSummaryPanelProps {
  subtotal: number;
  discountType: 'FIXED' | 'PERCENTAGE';
  discountValue: number;
  discount: number;
  taxRate: number;
  tax: number;
  grandTotal: number;
  totalCost: number;
  grossProfit: number;
  marginPercentage: number;
  onDiscountTypeChange?: (type: 'FIXED' | 'PERCENTAGE') => void;
  onDiscountValueChange?: (value: number) => void;
  onTaxRateChange?: (rate: number) => void;
  readonly?: boolean;
}

// ─── Styling Constants ──────────────────────────────────────

const cardBg = '#1a1a2e';
const borderColor = '#2d2d44';
const yellowAccent = '#fdd835';

// ─── Format Currency ────────────────────────────────────────

const formatCurrency = (amount: number): string => {
  return new Intl.NumberFormat('en-IN', {
    style: 'currency',
    currency: 'INR',
    maximumFractionDigits: 0,
  }).format(amount);
};

// ─── Margin Indicator Bar ───────────────────────────────────

interface MarginBarProps {
  margin: number;
}

const MarginBar: React.FC<MarginBarProps> = ({ margin }) => {
  const clampedMargin = Math.min(Math.max(margin, 0), 100);
  const color = getMarginColor(margin);

  return (
    <Box sx={{ width: '100%', mt: 1 }}>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 0.5 }}>
        <Typography variant="caption" sx={{ color: '#888' }}>
          0%
        </Typography>
        <Typography variant="caption" sx={{ color: '#888' }}>
          50%
        </Typography>
        <Typography variant="caption" sx={{ color: '#888' }}>
          100%
        </Typography>
      </Box>
      <Box sx={{ position: 'relative' }}>
        <LinearProgress
          variant="determinate"
          value={clampedMargin}
          sx={{
            height: 8,
            borderRadius: 4,
            backgroundColor: '#2d2d44',
            '& .MuiLinearProgress-bar': {
              backgroundColor: color,
              borderRadius: 4,
            },
          }}
        />
        {/* Threshold markers */}
        <Box
          sx={{
            position: 'absolute',
            left: '20%',
            top: 0,
            bottom: 0,
            width: 2,
            backgroundColor: '#ef5350',
            opacity: 0.5,
          }}
        />
        <Box
          sx={{
            position: 'absolute',
            left: '30%',
            top: 0,
            bottom: 0,
            width: 2,
            backgroundColor: '#ff9800',
            opacity: 0.5,
          }}
        />
      </Box>
      <Box sx={{ display: 'flex', mt: 0.5, gap: 1 }}>
        <Typography variant="caption" sx={{ color: '#ef5350', fontSize: '0.65rem' }}>
          ▲ Danger 20%
        </Typography>
        <Typography variant="caption" sx={{ color: '#ff9800', fontSize: '0.65rem' }}>
          ▲ Warning 30%
        </Typography>
      </Box>
    </Box>
  );
};

// ─── Summary Row Component ──────────────────────────────────

interface SummaryRowProps {
  label: string;
  value: string;
  icon?: React.ReactNode;
  highlight?: boolean;
  negative?: boolean;
  large?: boolean;
  color?: string;
}

const SummaryRow: React.FC<SummaryRowProps> = ({
  label,
  value,
  icon,
  highlight,
  negative,
  large,
  color,
}) => (
  <Box
    sx={{
      display: 'flex',
      justifyContent: 'space-between',
      alignItems: 'center',
      py: large ? 1.5 : 0.75,
      px: highlight ? 1.5 : 0,
      mx: highlight ? -1.5 : 0,
      borderRadius: highlight ? 1 : 0,
      backgroundColor: highlight ? 'rgba(253, 216, 53, 0.08)' : 'transparent',
    }}
  >
    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
      {icon && (
        <Box sx={{ color: color || (negative ? '#ef5350' : '#888'), display: 'flex' }}>
          {icon}
        </Box>
      )}
      <Typography
        variant={large ? 'subtitle1' : 'body2'}
        sx={{
          color: highlight ? '#fff' : '#aaa',
          fontWeight: highlight || large ? 600 : 400,
        }}
      >
        {label}
      </Typography>
    </Box>
    <Typography
      variant={large ? 'h6' : 'body2'}
      sx={{
        color: color || (negative ? '#ef5350' : highlight ? yellowAccent : '#fff'),
        fontWeight: highlight || large ? 700 : 500,
        fontFamily: 'monospace',
      }}
    >
      {negative ? `- ${value}` : value}
    </Typography>
  </Box>
);

// ─── Main Component ─────────────────────────────────────────

const ProfitSummaryPanel: React.FC<ProfitSummaryPanelProps> = ({
  subtotal,
  discountType,
  discountValue,
  discount,
  taxRate,
  tax,
  grandTotal,
  totalCost,
  grossProfit,
  marginPercentage,
  onDiscountTypeChange,
  onDiscountValueChange,
  onTaxRateChange,
  readonly = false,
}) => {
  const marginColor = getMarginColor(marginPercentage);
  const marginStatus = getMarginStatus(marginPercentage);

  const showWarning = marginPercentage < MARGIN_THRESHOLDS.WARNING;
  const showDanger = marginPercentage < MARGIN_THRESHOLDS.DANGER;

  return (
    <Paper
      sx={{
        backgroundColor: cardBg,
        border: `1px solid ${borderColor}`,
        borderRadius: 2,
        p: 2.5,
        height: '100%',
      }}
    >
      {/* Header */}
      <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', mb: 2 }}>
        <Typography variant="h6" sx={{ color: '#fff', fontWeight: 600 }}>
          Profit Summary
        </Typography>
        <Tooltip title="Real-time margin calculations">
          <IconButton size="small" sx={{ color: '#666' }}>
            <InfoIcon fontSize="small" />
          </IconButton>
        </Tooltip>
      </Box>

      {/* Margin Alert */}
      {(showWarning || showDanger) && (
        <Alert
          severity={showDanger ? 'error' : 'warning'}
          icon={<WarningIcon fontSize="small" />}
          sx={{
            mb: 2,
            backgroundColor: showDanger ? 'rgba(239, 83, 80, 0.1)' : 'rgba(255, 152, 0, 0.1)',
            border: `1px solid ${showDanger ? '#ef5350' : '#ff9800'}`,
            '& .MuiAlert-message': {
              color: '#fff',
            },
          }}
        >
          {showDanger
            ? 'Margin below 20%! Review pricing urgently.'
            : 'Margin below 30%. Consider adjustments.'}
        </Alert>
      )}

      {/* Margin Display */}
      <Box
        sx={{
          textAlign: 'center',
          py: 2,
          mb: 2,
          borderRadius: 2,
          backgroundColor: 'rgba(0,0,0,0.2)',
          border: `1px solid ${marginColor}40`,
        }}
      >
        <Typography variant="caption" sx={{ color: '#888', textTransform: 'uppercase' }}>
          Gross Margin
        </Typography>
        <Typography
          variant="h3"
          sx={{
            color: marginColor,
            fontWeight: 700,
            fontFamily: 'monospace',
          }}
        >
          {marginPercentage.toFixed(1)}%
        </Typography>
        <Chip
          label={marginStatus}
          size="small"
          sx={{
            backgroundColor: `${marginColor}20`,
            color: marginColor,
            fontWeight: 600,
            mt: 1,
          }}
        />
        <MarginBar margin={marginPercentage} />
      </Box>

      <Divider sx={{ borderColor: borderColor, my: 2 }} />

      {/* Revenue Section */}
      <Typography variant="overline" sx={{ color: '#666', fontSize: '0.65rem' }}>
        Revenue
      </Typography>

      <SummaryRow
        label="Subtotal"
        value={formatCurrency(subtotal)}
        icon={<RevenueIcon fontSize="small" />}
      />

      {/* Discount Controls */}
      {!readonly ? (
        <Box sx={{ py: 1 }}>
          <Stack direction="row" spacing={1} alignItems="center">
            <DiscountIcon fontSize="small" sx={{ color: '#ef5350' }} />
            <TextField
              select
              size="small"
              value={discountType}
              onChange={(e) => onDiscountTypeChange?.(e.target.value as 'FIXED' | 'PERCENTAGE')}
              sx={{
                width: 100,
                '& .MuiOutlinedInput-root': {
                  backgroundColor: '#0f0f0f',
                  '& fieldset': { borderColor },
                },
                '& .MuiSelect-select': { color: '#fff', py: 0.5 },
              }}
            >
              <MenuItem value="PERCENTAGE">%</MenuItem>
              <MenuItem value="FIXED">₹</MenuItem>
            </TextField>
            <TextField
              type="number"
              size="small"
              value={discountValue}
              onChange={(e) => onDiscountValueChange?.(Number(e.target.value))}
              sx={{
                flex: 1,
                '& .MuiOutlinedInput-root': {
                  backgroundColor: '#0f0f0f',
                  '& fieldset': { borderColor },
                },
                '& .MuiInputBase-input': { color: '#fff', py: 0.5 },
              }}
              inputProps={{ min: 0, step: discountType === 'PERCENTAGE' ? 1 : 100 }}
            />
          </Stack>
          {discount > 0 && (
            <Typography
              variant="caption"
              sx={{ color: '#ef5350', display: 'block', textAlign: 'right', mt: 0.5 }}
            >
              {formatCurrency(discount)} discount applied
            </Typography>
          )}
        </Box>
      ) : (
        discount > 0 && (
          <SummaryRow
            label={`Discount (${discountType === 'PERCENTAGE' ? `${discountValue}%` : 'Fixed'})`}
            value={formatCurrency(discount)}
            icon={<DiscountIcon fontSize="small" />}
            negative
          />
        )
      )}

      {/* Tax Controls */}
      {!readonly ? (
        <Box sx={{ py: 1 }}>
          <Stack direction="row" spacing={1} alignItems="center">
            <TaxIcon fontSize="small" sx={{ color: '#888' }} />
            <Typography variant="body2" sx={{ color: '#aaa', flex: 1 }}>
              GST Rate
            </Typography>
            <TextField
              type="number"
              size="small"
              value={taxRate}
              onChange={(e) => onTaxRateChange?.(Number(e.target.value))}
              sx={{
                width: 80,
                '& .MuiOutlinedInput-root': {
                  backgroundColor: '#0f0f0f',
                  '& fieldset': { borderColor },
                },
                '& .MuiInputBase-input': { color: '#fff', py: 0.5, textAlign: 'right' },
              }}
              inputProps={{ min: 0, max: 28, step: 1 }}
              InputProps={{
                endAdornment: <Typography sx={{ color: '#666', ml: 0.5 }}>%</Typography>,
              }}
            />
          </Stack>
          {tax > 0 && (
            <Typography
              variant="caption"
              sx={{ color: '#888', display: 'block', textAlign: 'right', mt: 0.5 }}
            >
              {formatCurrency(tax)} tax
            </Typography>
          )}
        </Box>
      ) : (
        tax > 0 && (
          <SummaryRow
            label={`Tax (${taxRate}%)`}
            value={formatCurrency(tax)}
            icon={<TaxIcon fontSize="small" />}
          />
        )
      )}

      <Divider sx={{ borderColor: borderColor, my: 2 }} />

      {/* Grand Total */}
      <SummaryRow
        label="Grand Total"
        value={formatCurrency(grandTotal)}
        icon={<RevenueIcon fontSize="small" />}
        highlight
        large
      />

      <Divider sx={{ borderColor: borderColor, my: 2 }} />

      {/* Cost & Profit Section */}
      <Typography variant="overline" sx={{ color: '#666', fontSize: '0.65rem' }}>
        Profitability
      </Typography>

      <SummaryRow
        label="Total Cost"
        value={formatCurrency(totalCost)}
        icon={<CostIcon fontSize="small" />}
      />

      <SummaryRow
        label="Gross Profit"
        value={formatCurrency(grossProfit)}
        icon={<ProfitIcon fontSize="small" />}
        color={marginColor}
        large
      />

      <Divider sx={{ borderColor: borderColor, my: 2 }} />

      {/* Margin Thresholds Legend */}
      <Box sx={{ mt: 2 }}>
        <Typography variant="overline" sx={{ color: '#666', fontSize: '0.65rem' }}>
          Margin Thresholds
        </Typography>
        <Stack direction="row" spacing={1} sx={{ mt: 1, flexWrap: 'wrap', gap: 0.5 }}>
          <Chip
            size="small"
            label="≥30% Healthy"
            sx={{ backgroundColor: '#4caf5020', color: '#4caf50', fontSize: '0.7rem' }}
          />
          <Chip
            size="small"
            label="20-30% Warning"
            sx={{ backgroundColor: '#ff980020', color: '#ff9800', fontSize: '0.7rem' }}
          />
          <Chip
            size="small"
            label="<20% Danger"
            sx={{ backgroundColor: '#ef535020', color: '#ef5350', fontSize: '0.7rem' }}
          />
        </Stack>
      </Box>
    </Paper>
  );
};

export default ProfitSummaryPanel;
