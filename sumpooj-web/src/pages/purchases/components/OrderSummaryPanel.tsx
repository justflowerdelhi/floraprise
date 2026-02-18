/**
 * Order Summary Panel
 * Sticky right-side panel showing live totals, margin preview,
 * cost impact summary, and expiry warnings.
 */

import {
  Paper,
  Typography,
  Divider,
  Box,
  Chip,
  Alert,
  alpha,
  useTheme,
  LinearProgress,
} from '@mui/material';
import ReceiptLongIcon from '@mui/icons-material/ReceiptLong';
import TrendingUpIcon from '@mui/icons-material/TrendingUp';
import WarningAmberIcon from '@mui/icons-material/WarningAmber';
import AcUnitIcon from '@mui/icons-material/AcUnit';
import CalendarTodayIcon from '@mui/icons-material/CalendarToday';
import type { OrderSummary as OrderSummaryType } from '../types/purchase.types';
import { fmt, getMarginColor, getExpiryStatus } from '../utils/purchase.utils';

interface OrderSummaryPanelProps {
  summary: OrderSummaryType;
  darkMode?: boolean;
}

const SummaryRow = ({
  label,
  value,
  bold,
  color,
  darkMode,
}: {
  label: string;
  value: string;
  bold?: boolean;
  color?: string;
  darkMode?: boolean;
}) => (
  <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', py: 0.5 }}>
    <Typography
      variant="body2"
      sx={{ color: darkMode ? 'grey.400' : 'grey.600', fontWeight: bold ? 600 : 400 }}
    >
      {label}
    </Typography>
    <Typography
      variant="body2"
      sx={{
        fontWeight: bold ? 700 : 500,
        color: color || (darkMode ? 'grey.100' : 'grey.900'),
        fontFamily: 'monospace',
      }}
    >
      {value}
    </Typography>
  </Box>
);

const OrderSummaryPanel = ({ summary, darkMode = false }: OrderSummaryPanelProps) => {
  const theme = useTheme();

  const marginColor = getMarginColor(summary.averageMargin);
  const expiryInfo = summary.earliestExpiry ? getExpiryStatus(summary.earliestExpiry) : null;

  return (
    <Paper
      elevation={0}
      sx={{
        position: 'sticky',
        top: 24,
        p: 2.5,
        borderRadius: 2,
        border: `1px solid ${darkMode ? theme.palette.grey[800] : theme.palette.grey[200]}`,
        backgroundColor: darkMode
          ? alpha(theme.palette.grey[900], 0.85)
          : 'white',
        transition: 'all 0.2s ease',
      }}
    >
      {/* Header */}
      <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 2 }}>
        <ReceiptLongIcon sx={{ color: theme.palette.primary.main, fontSize: 22 }} />
        <Typography variant="subtitle1" fontWeight={700} sx={{ color: darkMode ? 'grey.100' : 'grey.900' }}>
          Order Summary
        </Typography>
      </Box>

      {/* Counts */}
      <Box sx={{ display: 'flex', gap: 1, flexWrap: 'wrap', mb: 2 }}>
        <Chip
          label={`${summary.itemCount} item${summary.itemCount !== 1 ? 's' : ''}`}
          size="small"
          sx={{
            backgroundColor: darkMode
              ? alpha(theme.palette.primary.main, 0.15)
              : alpha(theme.palette.primary.main, 0.08),
            color: theme.palette.primary.main,
            fontWeight: 600,
          }}
        />
        {summary.perishableItems > 0 && (
          <Chip
            icon={<AcUnitIcon sx={{ fontSize: 14 }} />}
            label={`${summary.perishableItems} perishable`}
            size="small"
            color="info"
            variant="outlined"
            sx={{ height: 24 }}
          />
        )}
      </Box>

      <Divider sx={{ borderColor: darkMode ? 'grey.800' : 'grey.100', mb: 1.5 }} />

      {/* Totals */}
      <SummaryRow label="Subtotal" value={fmt(summary.subtotal)} darkMode={darkMode} />
      <SummaryRow
        label={`Tax (${summary.taxRate}%)`}
        value={summary.taxAmount > 0 ? fmt(summary.taxAmount) : '—'}
        darkMode={darkMode}
      />
      <SummaryRow
        label="Shipping"
        value={summary.shippingCost > 0 ? fmt(summary.shippingCost) : '—'}
        darkMode={darkMode}
      />

      <Divider sx={{ borderColor: darkMode ? 'grey.800' : 'grey.100', my: 1 }} />

      <SummaryRow label="Grand Total" value={fmt(summary.grandTotal)} bold darkMode={darkMode} />

      {/* Margin Preview */}
      {summary.averageMargin > 0 && (
        <>
          <Divider sx={{ borderColor: darkMode ? 'grey.800' : 'grey.100', my: 1.5 }} />
          <Box sx={{ mb: 1 }}>
            <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', mb: 0.5 }}>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
                <TrendingUpIcon sx={{ fontSize: 16, color: marginColor }} />
                <Typography variant="caption" fontWeight={600} sx={{ color: darkMode ? 'grey.300' : 'grey.700' }}>
                  Avg. Margin
                </Typography>
              </Box>
              <Typography variant="body2" fontWeight={700} sx={{ color: marginColor }}>
                {summary.averageMargin}%
              </Typography>
            </Box>
            <LinearProgress
              variant="determinate"
              value={Math.min(summary.averageMargin, 100)}
              sx={{
                height: 6,
                borderRadius: 3,
                backgroundColor: darkMode ? 'grey.800' : 'grey.100',
                '& .MuiLinearProgress-bar': {
                  borderRadius: 3,
                  backgroundColor: marginColor,
                },
              }}
            />
          </Box>
        </>
      )}

      {/* Low Margin Warning */}
      {summary.lowMarginItems > 0 && (
        <Alert
          severity="warning"
          icon={<WarningAmberIcon sx={{ fontSize: 18 }} />}
          sx={{
            mt: 1.5,
            py: 0.5,
            '& .MuiAlert-message': { fontSize: '0.75rem' },
          }}
        >
          {summary.lowMarginItems} item{summary.lowMarginItems > 1 ? 's' : ''} below 15% margin
        </Alert>
      )}

      {/* Earliest Expiry */}
      {expiryInfo && summary.earliestExpiry && (
        <Box
          sx={{
            mt: 1.5,
            p: 1,
            borderRadius: 1,
            display: 'flex',
            alignItems: 'center',
            gap: 0.75,
            backgroundColor: alpha(expiryInfo.color, 0.08),
          }}
        >
          <CalendarTodayIcon sx={{ fontSize: 16, color: expiryInfo.color }} />
          <Box>
            <Typography variant="caption" fontWeight={600} sx={{ color: expiryInfo.color, display: 'block' }}>
              Earliest Expiry: {expiryInfo.label}
            </Typography>
            <Typography variant="caption" sx={{ color: darkMode ? 'grey.500' : 'grey.600' }}>
              {summary.earliestExpiry}
            </Typography>
          </Box>
        </Box>
      )}

      {/* Cost Impact Summary */}
      {summary.grandTotal > 0 && (
        <>
          <Divider sx={{ borderColor: darkMode ? 'grey.800' : 'grey.100', my: 1.5 }} />
          <Typography variant="caption" fontWeight={600} sx={{ color: darkMode ? 'grey.300' : 'grey.700', mb: 0.5, display: 'block' }}>
            Cost Impact
          </Typography>
          <SummaryRow
            label="Avg. cost / item"
            value={summary.itemCount > 0 ? fmt(summary.subtotal / summary.itemCount) : '—'}
            darkMode={darkMode}
          />
          <SummaryRow
            label="Tax burden"
            value={summary.subtotal > 0 ? `${((summary.taxAmount / summary.subtotal) * 100).toFixed(1)}%` : '—'}
            darkMode={darkMode}
          />
          <SummaryRow
            label="Shipping % of total"
            value={
              summary.grandTotal > 0
                ? `${((summary.shippingCost / summary.grandTotal) * 100).toFixed(1)}%`
                : '—'
            }
            darkMode={darkMode}
          />
        </>
      )}
    </Paper>
  );
};

export default OrderSummaryPanel;
