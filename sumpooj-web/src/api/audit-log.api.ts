/**
 * audit-log.api.ts — Audit Logs API Service
 *
 * Endpoints:
 *   GET /audit-logs/search
 *   GET /audit-logs/recent
 *   GET /audit-logs/:id
 *   GET /audit-logs/entity/:entityType/:entityId
 *   GET /audit-logs/user/:userId
 *   GET /audit-logs/summary
 *   GET /audit-logs/user-activity
 */
import api from './axios';

// ─── Types ──────────────────────────────────────────────────

export interface AuditLogSearchParams {
  UserId?: string;
  UserName?: string;
  Action?: string;
  EntityType?: string;
  EntityId?: string;
  FromDate?: string;
  ToDate?: string;
  IsSuccess?: boolean;
  Page?: number;
  PageSize?: number;
}

// ─── API Functions ──────────────────────────────────────────

export const searchAuditLogs = async (params: AuditLogSearchParams = {}) => {
  const res = await api.get('/audit-logs/search', { params });
  return res.data;
};

export const getRecentAuditLogs = async (limit = 100) => {
  const res = await api.get('/audit-logs/recent', { params: { limit } });
  return res.data;
};

export const getAuditLogById = async (id: string) => {
  const res = await api.get(`/audit-logs/${id}`);
  return res.data;
};

export const getAuditLogsByEntity = async (entityType: string, entityId: string) => {
  const res = await api.get(`/audit-logs/entity/${entityType}/${entityId}`);
  return res.data;
};

export const getAuditLogsByUser = async (userId: string, limit = 100) => {
  const res = await api.get(`/audit-logs/user/${userId}`, { params: { limit } });
  return res.data;
};

export const getAuditLogSummary = async (date?: string) => {
  const res = await api.get('/audit-logs/summary', { params: { date } });
  return res.data;
};

export const getUserActivity = async (fromDate?: string, toDate?: string) => {
  const res = await api.get('/audit-logs/user-activity', { params: { fromDate, toDate } });
  return res.data;
};
