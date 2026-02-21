/**
 * location.api.ts — Locations API Service
 *
 * Endpoints:
 *   GET  /locations
 *   POST /locations
 *   GET  /locations/:id
 *   PUT  /locations/:id
 *   PUT  /locations/:id/deactivate
 */
import api from './axios';

// ─── Types ──────────────────────────────────────────────────

export interface CreateLocationRequest {
  name: string;
  code: string;
  locationType: string;
  address?: string | null;
  isDefault: boolean;
}

export interface UpdateLocationRequest {
  name?: string | null;
  address?: string | null;
  isDefault?: boolean | null;
}

// ─── API Functions ──────────────────────────────────────────

export const getLocations = async () => {
  const res = await api.get('/locations');
  return res.data;
};

export const createLocation = async (data: CreateLocationRequest) => {
  const res = await api.post('/locations', data);
  return res.data;
};

export const getLocationById = async (id: string) => {
  const res = await api.get(`/locations/${id}`);
  return res.data;
};

export const updateLocation = async (id: string, data: UpdateLocationRequest) => {
  const res = await api.put(`/locations/${id}`, data);
  return res.data;
};

export const deactivateLocation = async (id: string) => {
  const res = await api.put(`/locations/${id}/deactivate`);
  return res.data;
};
