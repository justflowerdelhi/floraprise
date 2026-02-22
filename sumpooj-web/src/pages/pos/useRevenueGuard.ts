/**
 * useRevenueGuard.ts — Revenue Guard hook for POS
 *
 * Prevents revenue leakage with intelligent warnings:
 *  1. High discount (>15%) → confirmation modal
 *  2. Missing delivery fee → warning banner
 *  3. Below-cost selling  → red margin badge
 *  4. Real-time margin %  → displayed near Grand Total
 *  5. Discount audit log  → every discount change recorded
 *
 * Does NOT block sales — only warns.
 */
import { useState, useEffect, useRef, useCallback, useMemo } from 'react';
import { usePOS } from './POSContext';
import type { CartItem } from '../orders/OrderTypes';

// ─── Constants ──────────────────────────────────────────────

export const HIGH_DISCOUNT_THRESHOLD = 15; // percent
const AUDIT_STORAGE_KEY = 'pos_discount_audit';

// ─── Types ──────────────────────────────────────────────────

export type WarningType = 'HIGH_DISCOUNT' | 'MISSING_DELIVERY_FEE' | 'BELOW_COST';
export type WarningSeverity = 'warning' | 'error';

export interface RevenueGuardWarning {
  id: string;
  type: WarningType;
  severity: WarningSeverity;
  message: string;
}

export interface DiscountAuditEntry {
  id: string;
  timestamp: string;
  transactionId: string | null;
  scope: 'LINE' | 'ORDER';
  productName?: string;
  discountPercent: number;
  discountAmount: number;
  isHighDiscount: boolean;
  confirmed: boolean;
}

// ─── Hook ───────────────────────────────────────────────────

export const useRevenueGuard = () => {
  const { state, clearOrderDiscount } = usePOS();
  const {
    items,
    totals,
    orderDiscount,
    orderIntent,
    deliveryDetails,
    transactionId,
  } = state;

  // ── High-discount modal state ─────────────────────────────
  const [showHighDiscountModal, setShowHighDiscountModal] = useState(false);
  const acknowledgedRef = useRef<Set<string>>(new Set());

  // ── Discount audit log (session-persisted) ────────────────
  const [auditLog, setAuditLog] = useState<DiscountAuditEntry[]>(() => {
    try {
      const raw = sessionStorage.getItem(AUDIT_STORAGE_KEY);
      return raw ? JSON.parse(raw) : [];
    } catch {
      return [];
    }
  });

  useEffect(() => {
    try {
      sessionStorage.setItem(AUDIT_STORAGE_KEY, JSON.stringify(auditLog));
    } catch {
      /* quota exceeded — ignore */
    }
  }, [auditLog]);

  // ── Computed data ─────────────────────────────────────────

  /** Line items whose effective discount > 15 % */
  const highDiscountItems = useMemo(
    () => items.filter((i) => i.discountPercent > HIGH_DISCOUNT_THRESHOLD),
    [items],
  );

  /** Is there a PERCENT order-level discount > 15 %? */
  const hasHighOrderDiscount =
    orderDiscount !== null &&
    orderDiscount.type === 'PERCENT' &&
    orderDiscount.value > HIGH_DISCOUNT_THRESHOLD;

  const hasHighDiscount = highDiscountItems.length > 0 || hasHighOrderDiscount;

  const maxLineDiscount =
    items.length > 0 ? Math.max(0, ...items.map((i) => i.discountPercent)) : 0;

  const maxDiscountPercent = hasHighOrderDiscount
    ? Math.max(maxLineDiscount, orderDiscount!.value)
    : maxLineDiscount;

  /** Items selling below FIFO cost */
  const belowCostItems = useMemo(
    () => items.filter((i) => i.lineCost > 0 && i.lineTotal < i.lineCost),
    [items],
  );

  /** Delivery intent selected but delivery fee = $0 */
  const missingDeliveryFee =
    orderIntent === 'DELIVERY' &&
    items.length > 0 &&
    deliveryDetails.deliveryFee === 0;

  // ── Warning list ──────────────────────────────────────────

  const warnings = useMemo<RevenueGuardWarning[]>(() => {
    const w: RevenueGuardWarning[] = [];

    if (hasHighDiscount) {
      w.push({
        id: 'high-discount',
        type: 'HIGH_DISCOUNT',
        severity: 'warning',
        message: `High discount applied (${maxDiscountPercent.toFixed(1)}%).`,
      });
    }

    if (missingDeliveryFee) {
      w.push({
        id: 'missing-delivery-fee',
        type: 'MISSING_DELIVERY_FEE',
        severity: 'warning',
        message: 'Delivery fee not added.',
      });
    }

    if (belowCostItems.length > 0) {
      w.push({
        id: 'below-cost',
        type: 'BELOW_COST',
        severity: 'error',
        message: `Selling below cost: ${belowCostItems.map((i) => i.productName).join(', ')}`,
      });
    }

    return w;
  }, [hasHighDiscount, maxDiscountPercent, missingDeliveryFee, belowCostItems]);

  // ── Fingerprint for high discounts (detect new ones) ──────

  const discountFingerprint = useMemo(() => {
    const parts: string[] = [];
    for (const item of items) {
      if (item.discountPercent > HIGH_DISCOUNT_THRESHOLD) {
        parts.push(`${item.id}:${item.discountPercent}`);
      }
    }
    if (hasHighOrderDiscount) {
      parts.push(`order:${orderDiscount!.value}`);
    }
    return parts.join('|') || '';
  }, [items, hasHighOrderDiscount, orderDiscount]);

  const prevFpRef = useRef('');

  /** Show modal when a *new* high discount shows up */
  useEffect(() => {
    if (
      discountFingerprint &&
      discountFingerprint !== prevFpRef.current &&
      !acknowledgedRef.current.has(discountFingerprint)
    ) {
      setShowHighDiscountModal(true);
    }
    prevFpRef.current = discountFingerprint;
  }, [discountFingerprint]);

  // ── Modal handlers ────────────────────────────────────────

  const confirmHighDiscount = useCallback(() => {
    acknowledgedRef.current.add(discountFingerprint);
    setShowHighDiscountModal(false);

    const entry: DiscountAuditEntry = {
      id: `da_${Date.now()}`,
      timestamp: new Date().toISOString(),
      transactionId,
      scope: hasHighOrderDiscount ? 'ORDER' : 'LINE',
      productName:
        highDiscountItems.length > 0
          ? highDiscountItems.map((i) => i.productName).join(', ')
          : undefined,
      discountPercent: maxDiscountPercent,
      discountAmount: totals.discountTotal + totals.orderDiscountAmount,
      isHighDiscount: true,
      confirmed: true,
    };
    setAuditLog((prev) => [...prev, entry]);

    console.info('[RevenueGuard] High discount CONFIRMED', {
      percent: maxDiscountPercent,
      amount: totals.discountTotal + totals.orderDiscountAmount,
      transactionId,
    });
  }, [
    discountFingerprint,
    transactionId,
    hasHighOrderDiscount,
    highDiscountItems,
    maxDiscountPercent,
    totals,
  ]);

  const dismissHighDiscount = useCallback(() => {
    acknowledgedRef.current.add(discountFingerprint);
    setShowHighDiscountModal(false);

    // Revert order-level discount when possible
    if (hasHighOrderDiscount) {
      clearOrderDiscount();
    }

    const entry: DiscountAuditEntry = {
      id: `da_${Date.now()}`,
      timestamp: new Date().toISOString(),
      transactionId,
      scope: hasHighOrderDiscount ? 'ORDER' : 'LINE',
      discountPercent: maxDiscountPercent,
      discountAmount: totals.discountTotal + totals.orderDiscountAmount,
      isHighDiscount: true,
      confirmed: false,
    };
    setAuditLog((prev) => [...prev, entry]);

    console.info('[RevenueGuard] High discount REVERTED', {
      percent: maxDiscountPercent,
      transactionId,
    });
  }, [
    discountFingerprint,
    hasHighOrderDiscount,
    clearOrderDiscount,
    transactionId,
    maxDiscountPercent,
    totals,
  ]);

  // ── Log ALL discount changes (non-high ones auto-logged) ──

  const prevDiscountRef = useRef(0);

  useEffect(() => {
    const total = totals.discountTotal + totals.orderDiscountAmount;
    if (total > 0 && total !== prevDiscountRef.current && !hasHighDiscount) {
      const entry: DiscountAuditEntry = {
        id: `da_${Date.now()}`,
        timestamp: new Date().toISOString(),
        transactionId,
        scope: totals.orderDiscountAmount > 0 ? 'ORDER' : 'LINE',
        discountPercent: maxDiscountPercent || maxLineDiscount,
        discountAmount: total,
        isHighDiscount: false,
        confirmed: true,
      };
      setAuditLog((prev) => [...prev, entry]);

      console.info('[RevenueGuard] Discount logged', {
        percent: maxLineDiscount,
        amount: total,
      });
    }
    prevDiscountRef.current = total;
  }, [
    totals.discountTotal,
    totals.orderDiscountAmount,
    transactionId,
    hasHighDiscount,
    maxDiscountPercent,
    maxLineDiscount,
  ]);

  // ── Margin styling helpers ────────────────────────────────

  const marginPercent = totals.marginPercent;

  const marginColor =
    marginPercent >= 40
      ? 'text-green-600'
      : marginPercent >= 20
        ? 'text-amber-600'
        : 'text-red-600';

  const marginBg =
    marginPercent >= 40
      ? 'bg-green-50'
      : marginPercent >= 20
        ? 'bg-amber-50'
        : 'bg-red-50';

  const marginBorder =
    marginPercent >= 40
      ? 'border-green-200'
      : marginPercent >= 20
        ? 'border-amber-200'
        : 'border-red-200';

  // ── Reset on cart clear ───────────────────────────────────

  useEffect(() => {
    if (state.lifecycle === 'idle' && items.length === 0) {
      acknowledgedRef.current.clear();
      prevFpRef.current = '';
      prevDiscountRef.current = 0;
    }
  }, [state.lifecycle, items.length]);

  return {
    // Warnings
    warnings,
    belowCostItems,
    highDiscountItems,
    hasHighDiscount,
    maxDiscountPercent,
    missingDeliveryFee,

    // Margin
    marginPercent,
    marginColor,
    marginBg,
    marginBorder,

    // High-discount modal
    showHighDiscountModal,
    confirmHighDiscount,
    dismissHighDiscount,

    // Audit trail
    auditLog,
  };
};
