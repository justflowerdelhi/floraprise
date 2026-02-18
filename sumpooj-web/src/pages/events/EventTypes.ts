/**
 * EventTypes.ts — Wedding & Event Module Type Definitions
 *
 * Phase 1: Event Core
 * Defines strict TypeScript interfaces for event management.
 */

// ─── Event Status ───────────────────────────────────────────

export type EventStatus =
  | 'INQUIRY'
  | 'QUOTED'
  | 'CONFIRMED'
  | 'IN_PRODUCTION'
  | 'COMPLETED'
  | 'CANCELLED';

export const EVENT_STATUSES: EventStatus[] = [
  'INQUIRY',
  'QUOTED',
  'CONFIRMED',
  'IN_PRODUCTION',
  'COMPLETED',
  'CANCELLED',
];

// ─── Event Type ─────────────────────────────────────────────

export type EventType =
  | 'WEDDING'
  | 'CORPORATE'
  | 'FUNERAL'
  | 'PARTY'
  | 'OTHER';

export const EVENT_TYPES: EventType[] = [
  'WEDDING',
  'CORPORATE',
  'FUNERAL',
  'PARTY',
  'OTHER',
];

// ─── Event Interface ────────────────────────────────────────

export interface Event {
  id: string;
  eventName: string;
  eventType: EventType;
  locationId?: string; // Multi-location support
  eventDate: string; // ISO date string
  clientName: string;
  clientPhone: string;
  venueName: string;
  venueAddress?: string;
  estimatedGuestCount?: number;
  budget?: number;
  colorTheme?: string;
  moodNotes?: string;
  moodBoardLink?: string;
  assignedDesigner?: string;
  status: EventStatus;
  internalNotes?: string;
  createdAt: string; // ISO timestamp
}

// ─── Form Data (for create/edit) ────────────────────────────

export interface EventFormData {
  eventName: string;
  eventType: EventType;
  eventDate: string;
  clientName: string;
  clientPhone: string;
  venueName: string;
  venueAddress: string;
  estimatedGuestCount: string; // string for form input
  budget: string; // string for form input
  colorTheme: string;
  moodNotes: string;
  moodBoardLink: string;
  assignedDesigner: string;
  status: EventStatus;
  internalNotes: string;
}

// ─── Status Configuration ───────────────────────────────────

export interface StatusConfig {
  label: string;
  color: string;
  bgColor: string;
  icon: string;
  description: string;
}

export const STATUS_CONFIG: Record<EventStatus, StatusConfig> = {
  INQUIRY: {
    label: 'Inquiry',
    color: '#2196f3',
    bgColor: 'rgba(33, 150, 243, 0.12)',
    icon: '📩',
    description: 'New inquiry received',
  },
  QUOTED: {
    label: 'Quoted',
    color: '#ff9800',
    bgColor: 'rgba(255, 152, 0, 0.12)',
    icon: '💰',
    description: 'Quote sent to client',
  },
  CONFIRMED: {
    label: 'Confirmed',
    color: '#4caf50',
    bgColor: 'rgba(76, 175, 80, 0.12)',
    icon: '✅',
    description: 'Event confirmed & booked',
  },
  IN_PRODUCTION: {
    label: 'In Production',
    color: '#9c27b0',
    bgColor: 'rgba(156, 39, 176, 0.12)',
    icon: '🌸',
    description: 'Arrangements being prepared',
  },
  COMPLETED: {
    label: 'Completed',
    color: '#607d8b',
    bgColor: 'rgba(96, 125, 139, 0.12)',
    icon: '🎉',
    description: 'Event successfully completed',
  },
  CANCELLED: {
    label: 'Cancelled',
    color: '#f44336',
    bgColor: 'rgba(244, 67, 54, 0.12)',
    icon: '❌',
    description: 'Event cancelled',
  },
};

// ─── Event Type Configuration ───────────────────────────────

export interface EventTypeConfig {
  label: string;
  color: string;
  icon: string;
}

export const EVENT_TYPE_CONFIG: Record<EventType, EventTypeConfig> = {
  WEDDING: {
    label: 'Wedding',
    color: '#e91e63',
    icon: '💒',
  },
  CORPORATE: {
    label: 'Corporate',
    color: '#3f51b5',
    icon: '🏢',
  },
  FUNERAL: {
    label: 'Funeral',
    color: '#607d8b',
    icon: '🕯️',
  },
  PARTY: {
    label: 'Party',
    color: '#ff5722',
    icon: '🎈',
  },
  OTHER: {
    label: 'Other',
    color: '#9e9e9e',
    icon: '📅',
  },
};

// ─── Filter Types ───────────────────────────────────────────

export interface EventFilters {
  search: string;
  status: EventStatus | '';
  eventType: EventType | '';
  dateFrom: string;
  dateTo: string;
}

// ─── API Request Types ──────────────────────────────────────

export interface CreateEventRequest {
  eventName: string;
  eventType: EventType;
  eventDate: string;
  clientName: string;
  clientPhone: string;
  venueName: string;
  venueAddress?: string;
  estimatedGuestCount?: number;
  budget?: number;
  colorTheme?: string;
  moodNotes?: string;
  moodBoardLink?: string;
  assignedDesigner?: string;
  status?: EventStatus;
  internalNotes?: string;
}

export interface UpdateEventRequest extends Partial<CreateEventRequest> {
  id: string;
}

// ─── Utility Functions ──────────────────────────────────────

export const getInitialFormData = (event?: Event): EventFormData => ({
  eventName: event?.eventName ?? '',
  eventType: event?.eventType ?? 'WEDDING',
  eventDate: event?.eventDate ?? '',
  clientName: event?.clientName ?? '',
  clientPhone: event?.clientPhone ?? '',
  venueName: event?.venueName ?? '',
  venueAddress: event?.venueAddress ?? '',
  estimatedGuestCount: event?.estimatedGuestCount?.toString() ?? '',
  budget: event?.budget?.toString() ?? '',
  colorTheme: event?.colorTheme ?? '',
  moodNotes: event?.moodNotes ?? '',
  moodBoardLink: event?.moodBoardLink ?? '',
  assignedDesigner: event?.assignedDesigner ?? '',
  status: event?.status ?? 'INQUIRY',
  internalNotes: event?.internalNotes ?? '',
});

export const formDataToRequest = (data: EventFormData): CreateEventRequest => ({
  eventName: data.eventName,
  eventType: data.eventType,
  eventDate: data.eventDate,
  clientName: data.clientName,
  clientPhone: data.clientPhone,
  venueName: data.venueName,
  venueAddress: data.venueAddress || undefined,
  estimatedGuestCount: data.estimatedGuestCount ? parseInt(data.estimatedGuestCount) : undefined,
  budget: data.budget ? parseFloat(data.budget) : undefined,
  colorTheme: data.colorTheme || undefined,
  moodNotes: data.moodNotes || undefined,
  moodBoardLink: data.moodBoardLink || undefined,
  assignedDesigner: data.assignedDesigner || undefined,
  status: data.status,
  internalNotes: data.internalNotes || undefined,
});

// ─── Designer List (Mock) ───────────────────────────────────

export const DESIGNERS = [
  { id: 'd1', name: 'Meera Patel' },
  { id: 'd2', name: 'Ananya Sharma' },
  { id: 'd3', name: 'Priya Gupta' },
  { id: 'd4', name: 'Kavita Reddy' },
];
