/**
 * CartSummaryPanel.tsx — Cart totals: subtotal, tax, discount, grand total, margin
 * Now supports commission breakdown for external orders (FTD / BloomNation).
 */
import React from 'react';
import {
  Card, CardContent, Typography, Box, Divider, Chip, useTheme,
} from '@mui/material';
import { WarningAmber as WarnIcon, AccountBalance as CommissionIcon } from '@mui/icons-material';
import type { CartSummary, OrderSource } from '../orders/OrderTypes';
import { fmtCurrency, fmtPercent } from './CartUtils';
import { isExternalSource, calcPlatformCommission } from '../orders/OrderUtils';

interface CommissionData {
  grossAmount: number;
  commission: number;
  fees: number;
  netPayout: number;
}

interface Props {
  totals: CartSummary;
  /** @deprecated Use orderSource instead */
  isFTD?: boolean;
  orderSource?: OrderSource;
  commissionData?: CommissionData;
}

const CartSummaryPanel: React.FC<Props> = ({ totals, isFTD, orderSource, commissionData }) => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';
  const external = orderSource ? isExternalSource(orderSource) : !!isFTD;

  // Auto-compute commission if not provided but order is external
  const commission: CommissionData | null = commissionData ?? (
    external && orderSource && (orderSource === 'FTD' || orderSource === 'BLOOMNATION')
      ? (() => {
          const c = calcPlatformCommission(orderSource as 'FTD' | 'BLOOMNATION', totals.grandTotal);
          return {
            grossAmount: totals.grandTotal,
            commission: c.commission,
            fees: c.fees,
            netPayout: totals.grandTotal - c.commission - c.fees,
          };
        })()
      : null
  );

  const Row = ({ label, value, bold, color }: { label: string; value: string; bold?: boolean; color?: string }) => (
    <Box sx={{ display: 'flex', justifyContent: 'space-between', py: 0.5 }}>
      <Typography variant="body2" sx={{ color: dk ? 'rgba(255,255,255,0.6)' : 'text.secondary' }}>
        {label}
      </Typography>
      <Typography
        variant="body2"
        sx={{ fontWeight: bold ? 800 : 500, color: color ?? 'inherit', fontSize: bold ? '1rem' : undefined }}
      >
        {value}
      </Typography>
    </Box>
  );

  const platformLabel = orderSource === 'BLOOMNATION' ? 'BloomNation' : orderSource === 'FTD' ? 'FTD' : 'External';

  return (
    <Card
      elevation={dk ? 0 : 1}
      sx={{
        bgcolor: dk ? '#1a1a2e' : '#fff',
        border: dk ? '1px solid rgba(255,255,255,0.08)' : 'none',
        borderRadius: 2,
      }}
    >
      <CardContent>
        <Typography variant="subtitle2" sx={{ fontWeight: 700, mb: 1.5 }}>
          Order Summary
        </Typography>

        {external && (
          <Chip
            label={`${platformLabel} Order — Prices Locked`}
            color="warning"
            size="small"
            variant="outlined"
            sx={{ mb: 1.5, fontWeight: 600 }}
          />
        )}

        <Row label="Items" value={`${totals.itemCount} items (${totals.lineCount} lines)`} />
        <Row label="Subtotal" value={fmtCurrency(totals.subtotal)} />
        {totals.discountTotal > 0 && (
          <Row label="Discount" value={`-${fmtCurrency(totals.discountTotal)}`} color={theme.palette.success.main} />
        )}
        <Row label="Tax" value={fmtCurrency(totals.taxTotal)} />

        <Divider sx={{ my: 1, borderColor: dk ? 'rgba(255,255,255,0.08)' : undefined }} />

        <Row label="Grand Total" value={fmtCurrency(totals.grandTotal)} bold />

        {/* ── Commission Breakdown for external orders ── */}
        {commission && (
          <>
            <Divider sx={{ my: 1, borderColor: dk ? 'rgba(255,255,255,0.08)' : undefined }} />
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5, mb: 0.5 }}>
              <CommissionIcon sx={{ fontSize: 16, color: theme.palette.warning.main }} />
              <Typography variant="caption" sx={{ fontWeight: 700, color: theme.palette.warning.main }}>
                {platformLabel} Commission Breakdown
              </Typography>
            </Box>
            <Row label="Gross Revenue" value={fmtCurrency(commission.grossAmount)} />
            <Row
              label={`${platformLabel} Commission`}
              value={`-${fmtCurrency(commission.commission)}`}
              color={theme.palette.error.main}
            />
            {commission.fees > 0 && (
              <Row
                label="Platform Fees"
                value={`-${fmtCurrency(commission.fees)}`}
                color={theme.palette.error.main}
              />
            )}
            <Row label="Net Payout" value={fmtCurrency(commission.netPayout)} bold color="#fdd835" />
          </>
        )}

        <Divider sx={{ my: 1, borderColor: dk ? 'rgba(255,255,255,0.08)' : undefined }} />

        <Row label="Cost (FIFO)" value={fmtCurrency(totals.totalCost)} />

        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', py: 0.5 }}>
          <Typography variant="body2" sx={{ color: dk ? 'rgba(255,255,255,0.6)' : 'text.secondary' }}>
            Margin
          </Typography>
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
            {totals.marginWarning && (
              <WarnIcon sx={{ fontSize: 16, color: theme.palette.error.main }} />
            )}
            <Chip
              label={fmtPercent(totals.marginPercent)}
              size="small"
              color={totals.marginWarning ? 'error' : totals.marginPercent < 35 ? 'warning' : 'success'}
              variant={dk ? 'outlined' : 'filled'}
              sx={{ fontWeight: 700 }}
            />
          </Box>
        </Box>

        {totals.marginWarning && (
          <Typography
            variant="caption"
            sx={{ color: theme.palette.error.main, display: 'block', mt: 1, fontWeight: 600 }}
          >
            ⚠ Margin below 20% — review pricing!
          </Typography>
        )}
      </CardContent>
    </Card>
  );
};

export default CartSummaryPanel;
