/**
 * RevenueGuardBanner.tsx — Revenue Guard warnings & high-discount confirmation
 *
 * Self-contained component that:
 *  - Shows amber/red warning banners for high discounts, missing delivery fees, below-cost items
 *  - Pops a MUI Dialog for discount > 15 % confirmation
 *  - Displays real-time margin % bar
 *  - Shows a compact audit trail indicator
 *
 * Does NOT block sales — all warnings are dismissible.
 */
import React, { useState } from 'react';
import {
  Warning as WarningIcon,
  LocalShipping as DeliveryIcon,
  TrendingDown as BelowCostIcon,
  CheckCircle as ConfirmIcon,
  Cancel as CancelIcon,
  Shield as ShieldIcon,
  ExpandMore as ExpandIcon,
  ExpandLess as CollapseIcon,
  Receipt as AuditIcon,
} from '@mui/icons-material';
import { Dialog, DialogTitle, DialogContent, DialogActions, Button } from '@mui/material';
import {
  useRevenueGuard,
  HIGH_DISCOUNT_THRESHOLD,
  type DiscountAuditEntry,
} from './useRevenueGuard';
import { formatCurrency } from '../../core/i18n';

// ─── Component ──────────────────────────────────────────────

const RevenueGuardBanner: React.FC = () => {
  const {
    warnings,
    belowCostItems,
    hasHighDiscount,
    maxDiscountPercent,
    missingDeliveryFee,
    marginPercent,
    marginColor,
    marginBg,
    marginBorder,
    showHighDiscountModal,
    confirmHighDiscount,
    dismissHighDiscount,
    auditLog,
  } = useRevenueGuard();

  const [showAuditLog, setShowAuditLog] = useState(false);

  const hasWarnings = warnings.length > 0;
  const hasContent = hasWarnings || auditLog.length > 0;

  if (!hasContent) return null;

  const alertCount = warnings.length;

  return (
    <>
      {/* ── Warning Banners ────────────────────────────────── */}
      {hasWarnings && (
        <div className="px-4 py-2 space-y-1.5">
          {/* High Discount */}
          {hasHighDiscount && (
            <div className="flex items-center gap-2 px-3 py-2 bg-amber-50 border border-amber-200 rounded-lg animate-in fade-in">
              <WarningIcon className="w-4 h-4 text-amber-500 shrink-0" />
              <span className="text-xs font-medium text-amber-700 flex-1">
                High discount applied ({maxDiscountPercent.toFixed(1)}%)
              </span>
              <span className="px-1.5 py-0.5 bg-amber-200/60 text-amber-800 text-[10px] font-bold rounded">
                &gt;{HIGH_DISCOUNT_THRESHOLD}%
              </span>
            </div>
          )}

          {/* Missing Delivery Fee */}
          {missingDeliveryFee && (
            <div className="flex items-center gap-2 px-3 py-2 bg-orange-50 border border-orange-200 rounded-lg">
              <DeliveryIcon className="w-4 h-4 text-orange-500 shrink-0" />
              <span className="text-xs font-medium text-orange-700 flex-1">
                Delivery fee not added.
              </span>
              <span className="px-1.5 py-0.5 bg-orange-200/60 text-orange-800 text-[10px] font-bold rounded">
                $0.00
              </span>
            </div>
          )}

          {/* Below-Cost Items */}
          {belowCostItems.length > 0 && (
            <div className="flex items-start gap-2 px-3 py-2 bg-red-50 border border-red-200 rounded-lg">
              <BelowCostIcon className="w-4 h-4 text-red-500 shrink-0 mt-0.5" />
              <div className="flex-1 min-w-0">
                <span className="text-xs font-semibold text-red-700 block">
                  Selling below cost
                </span>
                {belowCostItems.map((item) => (
                  <div
                    key={item.id}
                    className="flex items-center justify-between mt-0.5"
                  >
                    <span className="text-[10px] text-red-600 truncate max-w-[140px]">
                      {item.productName}
                    </span>
                    <span className="text-[10px] font-mono font-semibold text-red-700">
                      {item.marginPercent.toFixed(1)}%
                    </span>
                  </div>
                ))}
              </div>
            </div>
          )}
        </div>
      )}

      {/* ── Shield badge + audit trail toggle ────────────── */}
      {hasContent && (
        <div className="px-4 pb-1 flex items-center justify-between">
          <div className="flex items-center gap-1.5 text-[10px] text-gray-400">
            <ShieldIcon className="w-3 h-3" />
            <span>
              Revenue Guard
              {alertCount > 0 && (
                <> &bull; {alertCount} alert{alertCount !== 1 ? 's' : ''}</>
              )}
            </span>
          </div>

          {auditLog.length > 0 && (
            <button
              onClick={() => setShowAuditLog((v) => !v)}
              className="flex items-center gap-1 text-[10px] text-gray-400 hover:text-gray-600 transition-colors"
            >
              <AuditIcon className="w-3 h-3" />
              <span>{auditLog.length} logged</span>
              {showAuditLog ? (
                <CollapseIcon className="w-3 h-3" />
              ) : (
                <ExpandIcon className="w-3 h-3" />
              )}
            </button>
          )}
        </div>
      )}

      {/* ── Collapsible audit log ────────────────────────── */}
      {showAuditLog && auditLog.length > 0 && (
        <div className="px-4 pb-2">
          <div className="bg-gray-50 border border-gray-200 rounded-lg p-2 max-h-32 overflow-y-auto">
            {auditLog.slice(-10).reverse().map((e: DiscountAuditEntry) => (
              <div
                key={e.id}
                className="flex items-center justify-between py-1 border-b border-gray-100 last:border-0"
              >
                <div className="flex items-center gap-1.5 min-w-0">
                  <span
                    className={`w-1.5 h-1.5 rounded-full shrink-0 ${
                      e.isHighDiscount
                        ? e.confirmed
                          ? 'bg-amber-400'
                          : 'bg-red-400'
                        : 'bg-gray-400'
                    }`}
                  />
                  <span className="text-[10px] text-gray-600 truncate">
                    {e.scope === 'ORDER' ? 'Order' : e.productName ?? 'Line'}{' '}
                    {e.discountPercent.toFixed(1)}%
                  </span>
                </div>
                <div className="flex items-center gap-1.5 shrink-0">
                  <span className="text-[10px] font-mono text-gray-500">
                    {formatCurrency(e.discountAmount)}
                  </span>
                  {e.isHighDiscount && (
                    <span
                      className={`text-[9px] font-bold px-1 py-0.5 rounded ${
                        e.confirmed
                          ? 'bg-amber-100 text-amber-700'
                          : 'bg-red-100 text-red-600'
                      }`}
                    >
                      {e.confirmed ? 'OK' : 'REV'}
                    </span>
                  )}
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* ── High Discount Confirmation Modal ─────────────── */}
      <Dialog
        open={showHighDiscountModal}
        onClose={confirmHighDiscount} // closing = acknowledge
        maxWidth="xs"
        fullWidth
        PaperProps={{
          sx: {
            borderRadius: '16px',
            overflow: 'hidden',
          },
        }}
      >
        {/* ─ Header ─ */}
        <div className="bg-amber-50 px-6 py-4 flex items-center gap-3 border-b border-amber-200">
          <div className="w-10 h-10 rounded-full bg-amber-100 flex items-center justify-center shrink-0">
            <WarningIcon className="w-5 h-5 text-amber-600" />
          </div>
          <div>
            <DialogTitle sx={{ p: 0, fontSize: '1rem', fontWeight: 700 }}>
              High Discount Applied
            </DialogTitle>
            <p className="text-xs text-amber-700 mt-0.5">Revenue Guard Alert</p>
          </div>
        </div>

        {/* ─ Body ─ */}
        <DialogContent sx={{ px: 3, py: 2.5 }}>
          <p className="text-sm text-gray-700 mb-3">
            A discount of{' '}
            <strong className="text-amber-700">
              {maxDiscountPercent.toFixed(1)}%
            </strong>{' '}
            has been applied, exceeding the {HIGH_DISCOUNT_THRESHOLD}% threshold.
          </p>

          <div className="bg-gray-50 rounded-lg p-3 text-xs text-gray-600 space-y-1.5">
            <div className="flex justify-between">
              <span>Discount applied</span>
              <span className="font-semibold text-amber-700">
                {maxDiscountPercent.toFixed(1)}%
              </span>
            </div>
            <div className="flex justify-between">
              <span>Threshold</span>
              <span className="font-semibold">{HIGH_DISCOUNT_THRESHOLD}.0%</span>
            </div>
            <div className="flex justify-between">
              <span>Current margin</span>
              <span className={`font-semibold ${marginColor}`}>
                {marginPercent.toFixed(1)}%
              </span>
            </div>
          </div>
        </DialogContent>

        {/* ─ Actions ─ */}
        <DialogActions sx={{ px: 3, pb: 2.5, gap: 1 }}>
          <Button
            onClick={dismissHighDiscount}
            variant="outlined"
            color="inherit"
            size="small"
            startIcon={<CancelIcon />}
            sx={{
              borderRadius: '8px',
              textTransform: 'none',
              fontWeight: 600,
            }}
          >
            Revert Discount
          </Button>
          <Button
            onClick={confirmHighDiscount}
            variant="contained"
            size="small"
            startIcon={<ConfirmIcon />}
            sx={{
              borderRadius: '8px',
              textTransform: 'none',
              fontWeight: 600,
              bgcolor: '#d97706',
              '&:hover': { bgcolor: '#b45309' },
            }}
          >
            Confirm Discount
          </Button>
        </DialogActions>
      </Dialog>
    </>
  );
};

export default RevenueGuardBanner;
