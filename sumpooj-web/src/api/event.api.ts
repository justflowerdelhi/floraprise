/**
 * event.api.ts — Events API Service
 *
 * Endpoints:
 *   GET  /Events/search
 *   GET  /Events/upcoming
 *   GET  /Events/:id
 *   PUT  /Events/:id
 *   POST /Events
 */
import api from './axios';

// ─── Types ──────────────────────────────────────────────────

export interface EventSearchParams {
  Query?: string;
  EventType?: string;
  Status?: string;
  FromDate?: string;
  ToDate?: string;
  Page?: number;
  PageSize?: number;
}

export interface CreateEventRequest {
  eventName: string;
  eventType: string;
  eventDate: string;
  clientName: string;
  clientPhone: string;
  clientEmail?: string | null;
  venueName: string;
  venueAddress?: string | null;
  estimatedGuestCount?: number | null;
  budget?: number | null;
  colorTheme?: string | null;
  moodNotes?: string | null;
  moodBoardLink?: string | null;
  assignedDesignerId?: string | null;
  status?: string | null;
  internalNotes?: string | null;
}

export interface UpdateEventRequest {
  eventName?: string | null;
  eventType?: string | null;
  eventDate?: string | null;
  clientName?: string | null;
  clientPhone?: string | null;
  clientEmail?: string | null;
  venueName?: string | null;
  venueAddress?: string | null;
  estimatedGuestCount?: number | null;
  budget?: number | null;
  colorTheme?: string | null;
  moodNotes?: string | null;
  moodBoardLink?: string | null;
  assignedDesignerId?: string | null;
  status?: string | null;
  internalNotes?: string | null;
}

// ─── API Functions ──────────────────────────────────────────

export const searchEvents = async (params: EventSearchParams = {}) => {
  const res = await api.get('/Events/search', { params });
  return res.data;
};

export const getUpcomingEvents = async (days = 30) => {
  const res = await api.get('/Events/upcoming', { params: { days } });
  return res.data;
};

export const getEventById = async (id: string) => {
  const res = await api.get(`/Events/${id}`);
  return res.data;
};

export const updateEvent = async (id: string, data: UpdateEventRequest) => {
  const res = await api.put(`/Events/${id}`, data);
  return res.data;
};

export const createEvent = async (data: CreateEventRequest) => {
  const res = await api.post('/Events', data);
  return res.data;
};
