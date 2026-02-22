/**
 * day-close.api.ts — Day Close API Service
 *
 * Endpoints:
 *   GET  /day-close/:id
 *   GET  /day-close/summary
 *   GET  /day-close/is-closed
 *   GET  /day-close/history
 *   POST /day-close
 */
import api from './axios';
import type { DayCloseSummary, DayCloseStatus } from '../core/audit/AuditTypes';

// ─── Types ──────────────────────────────────────────────────

export interface CloseDayRequest {
  locationId: string;
  businessDate: string;
  actualCash: number;
  notes?: string | null;
}

export interface DayCloseSummaryParams {
  locationId?: string;
  date?: string;
}

export interface DayCloseHistoryParams {
  locationId?: string;
  days?: number;
}

// ─── Data Validation & Normalization ────────────────────────

/**
 * Validate and normalize day status from API response
 * Maps any unrecognized values to 'OPEN' with a warning
 */
function normalizeDayStatus(status: unknown): DayCloseStatus {
  const validStatuses: DayCloseStatus[] = ['OPEN', 'PENDING_REVIEW', 'CLOSED', 'REOPENED'];
  
  if (typeof status === 'string' && validStatuses.includes(status as DayCloseStatus)) {
    return status as DayCloseStatus;
  }
  
  console.warn('⚠️ Unknown day close status from API:', status, 'defaulting to OPEN');
  return 'OPEN';
}

/**
 * Validate and normalize DayCloseSummary response from API
 * Provides safe defaults and validates all required fields
 */
export function validateDayCloseSummary(data: any): DayCloseSummary {
  return {
    date: data?.date ?? new Date().toISOString().split('T')[0],
    locationId: data?.locationId ?? '',
    status: normalizeDayStatus(data?.status),
    totalSales: typeof data?.totalSales === 'number' ? data.totalSales : 0,
    totalOrders: typeof data?.totalOrders === 'number' ? data.totalOrders : 0,
    walkInSales: typeof data?.walkInSales === 'number' ? data.walkInSales : 0,
    walkInOrders: typeof data?.walkInOrders === 'number' ? data.walkInOrders : 0,
    phoneOrders: typeof data?.phoneOrders === 'number' ? data.phoneOrders : 0,
    phoneOrdersAmount: typeof data?.phoneOrdersAmount === 'number' ? data.phoneOrdersAmount : 0,
    onlineOrders: typeof data?.onlineOrders === 'number' ? data.onlineOrders : 0,
    onlineOrdersAmount: typeof data?.onlineOrdersAmount === 'number' ? data.onlineOrdersAmount : 0,
    cashSales: typeof data?.cashSales === 'number' ? data.cashSales : 0,
    cardSales: typeof data?.cardSales === 'number' ? data.cardSales : 0,
    upiSales: typeof data?.upiSales === 'number' ? data.upiSales : 0,
    otherPayments: typeof data?.otherPayments === 'number' ? data.otherPayments : 0,
    countedCash: typeof data?.countedCash === 'number' ? data.countedCash : undefined,
    expectedCash: typeof data?.expectedCash === 'number' ? data.expectedCash : 0,
    cashVariance: typeof data?.cashVariance === 'number' ? data.cashVariance : undefined,
    totalRefunds: typeof data?.totalRefunds === 'number' ? data.totalRefunds : 0,
    refundCount: typeof data?.refundCount === 'number' ? data.refundCount : 0,
    closedBy: data?.closedBy ?? undefined,
    closedAt: data?.closedAt ?? undefined,
    notes: data?.notes ?? undefined,
  };
}

// ─── API Functions ──────────────────────────────────────────

export const getDayCloseById = async (id: string) => {
  const res = await api.get(`/day-close/${id}`);
  return res.data;
};

export const getDayCloseSummary = async (params: DayCloseSummaryParams = {}): Promise<DayCloseSummary> => {
  const res = await api.get('/day-close/summary', { params });
  console.log('📊 [getDayCloseSummary] Raw Response:', JSON.stringify(res.data, null, 2));
  const validated = validateDayCloseSummary(res.data);
  console.log('✅ [getDayCloseSummary] After Validation:', JSON.stringify(validated, null, 2));
  return validated;
};

export const isDayClosed = async (locationId?: string, date?: string) => {
  const res = await api.get('/day-close/is-closed', { params: { locationId, date } });
  return res.data;
};

export const getDayCloseHistory = async (params: DayCloseHistoryParams = {}) => {
  const res = await api.get('/day-close/history', { params });
  return res.data;
};

export const closeDay = async (data: CloseDayRequest) => {
  const res = await api.post('/day-close', data);
  return res.data;
};
