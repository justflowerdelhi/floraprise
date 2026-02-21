/**
 * shift.api.ts — Shift Open / Close API Service
 *
 * Endpoints:
 *   GET  /shifts/active?locationId=
 *   GET  /shifts/:id
 *   GET  /shifts/history?locationId=&count=
 *   POST /shifts/open
 *   POST /shifts/:id/close
 */
import api from './axios';

// ─── Types ──────────────────────────────────────────────────

export interface ShiftDto {
  id: string;
  locationId: string;
  openedByUserId: string;
  openedByName: string;
  openedAt: string;
  openingCash: number;
  closedByUserId: string | null;
  closedByName: string | null;
  closedAt: string | null;
  closingCashCount: number | null;
  cashDifference: number | null;
  cashSales: number;
  cardSales: number;
  upiSales: number;
  giftCardSales: number;
  otherSales: number;
  totalRefunds: number;
  paidOuts: number;
  transactionCount: number;
  expectedCash: number;
  status: string;
  isClosed: boolean;
  notes: string | null;
}

export interface OpenShiftRequest {
  locationId: string;
  openingCash: number;
}

export interface CloseShiftRequest {
  closingCashCount: number;
  notes?: string | null;
}

// ─── API Functions ──────────────────────────────────────────

/** Get the active (open) shift for a location. Returns null if 204 No Content. */
export const getActiveShift = async (locationId: string): Promise<ShiftDto | null> => {
  const res = await api.get('/shifts/active', { params: { locationId } });
  // 204 No Content → no active shift
  if (res.status === 204 || !res.data) return null;
  return res.data;
};

/** Get a specific shift by ID. */
export const getShiftById = async (id: string): Promise<ShiftDto> => {
  const res = await api.get(`/shifts/${id}`);
  return res.data;
};

/** Get shift history for a location. */
export const getShiftHistory = async (locationId: string, count = 20): Promise<ShiftDto[]> => {
  const res = await api.get('/shifts/history', { params: { locationId, count } });
  return res.data;
};

/** Open a new shift. Returns the new shift ID. */
export const openShift = async (data: OpenShiftRequest): Promise<{ id: string }> => {
  const res = await api.post('/shifts/open', data);
  return res.data;
};

/** Close an active shift. */
export const closeShift = async (id: string, data: CloseShiftRequest): Promise<void> => {
  await api.post(`/shifts/${id}/close`, data);
};
