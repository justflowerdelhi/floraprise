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

// ─── API Functions ──────────────────────────────────────────

export const getDayCloseById = async (id: string) => {
  const res = await api.get(`/day-close/${id}`);
  return res.data;
};

export const getDayCloseSummary = async (params: DayCloseSummaryParams = {}) => {
  const res = await api.get('/day-close/summary', { params });
  return res.data;
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
