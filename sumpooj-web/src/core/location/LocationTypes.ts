/**
 * LocationTypes.ts — Multi-Location Architecture Types
 *
 * Supports:
 * - Location model and data
 * - Location-based filtering
 * - Role-based location access
 */

// ─── Location Model ─────────────────────────────────────────

export interface Location {
  id: string;
  name: string;
  code: string; // Short code (e.g., "MUM-01")
  address: string;
  city: string;
  phone?: string;
  email?: string;
  isActive: boolean;
  timezone?: string;
  createdAt: string;
  updatedAt: string;
}

// ─── Location Access Level ──────────────────────────────────

export type LocationAccessLevel = 
  | 'SINGLE'      // Staff: can only access assigned location
  | 'MULTIPLE'    // Manager: can access specific locations
  | 'ALL';        // Admin: can access all locations

// ─── Location Filter Options ────────────────────────────────

export type LocationFilterValue = string | 'ALL';

export interface LocationFilter {
  locationId: LocationFilterValue;
  includeInactive?: boolean;
}

// ─── Mock Locations ─────────────────────────────────────────

export const MOCK_LOCATIONS: Location[] = [
  {
    id: 'loc-001',
    name: 'Florist Hub - Bandra',
    code: 'MUM-BAN',
    address: '123 Linking Road, Bandra West',
    city: 'Mumbai',
    phone: '+91 22 2648 1234',
    email: 'bandra@floristhub.com',
    isActive: true,
    timezone: 'Asia/Kolkata',
    createdAt: '2020-01-15T10:00:00Z',
    updatedAt: '2026-01-01T10:00:00Z',
  },
  {
    id: 'loc-002',
    name: 'Florist Hub - Andheri',
    code: 'MUM-AND',
    address: '456 DN Nagar, Andheri West',
    city: 'Mumbai',
    phone: '+91 22 2671 5678',
    email: 'andheri@floristhub.com',
    isActive: true,
    timezone: 'Asia/Kolkata',
    createdAt: '2021-06-01T10:00:00Z',
    updatedAt: '2026-01-01T10:00:00Z',
  },
  {
    id: 'loc-003',
    name: 'Florist Hub - Powai',
    code: 'MUM-POW',
    address: '789 Hiranandani Gardens, Powai',
    city: 'Mumbai',
    phone: '+91 22 2570 9012',
    email: 'powai@floristhub.com',
    isActive: true,
    timezone: 'Asia/Kolkata',
    createdAt: '2023-03-15T10:00:00Z',
    updatedAt: '2026-01-01T10:00:00Z',
  },
  {
    id: 'loc-004',
    name: 'Florist Hub - Pune',
    code: 'PUN-KOR',
    address: '321 Koregaon Park',
    city: 'Pune',
    phone: '+91 20 2615 3456',
    email: 'pune@floristhub.com',
    isActive: true,
    timezone: 'Asia/Kolkata',
    createdAt: '2024-09-01T10:00:00Z',
    updatedAt: '2026-01-01T10:00:00Z',
  },
  {
    id: 'loc-005',
    name: 'Florist Hub - Thane (Closed)',
    code: 'MUM-THA',
    address: '555 Ghodbunder Road, Thane',
    city: 'Thane',
    phone: '+91 22 2597 7890',
    email: 'thane@floristhub.com',
    isActive: false,
    timezone: 'Asia/Kolkata',
    createdAt: '2022-01-01T10:00:00Z',
    updatedAt: '2025-06-01T10:00:00Z',
  },
];

// ─── Location Helper Functions ──────────────────────────────

/**
 * Get all active locations
 */
export const getActiveLocations = (): Location[] => 
  MOCK_LOCATIONS.filter(loc => loc.isActive);

/**
 * Get location by ID
 */
export const getLocationById = (id: string): Location | null => 
  MOCK_LOCATIONS.find(loc => loc.id === id) || null;

/**
 * Get locations by IDs
 */
export const getLocationsByIds = (ids: string[]): Location[] => 
  MOCK_LOCATIONS.filter(loc => ids.includes(loc.id));

/**
 * Get location display name (short)
 */
export const getLocationShortName = (location: Location): string => {
  const nameParts = location.name.split(' - ');
  return nameParts.length > 1 ? nameParts[1] : location.name;
};

/**
 * Filter items by location
 */
export const filterByLocation = <T extends { locationId?: string }>(
  items: T[],
  locationId: LocationFilterValue
): T[] => {
  if (locationId === 'ALL') return items;
  return items.filter(item => item.locationId === locationId);
};

// ─── Location Config ────────────────────────────────────────

export const LOCATION_CONFIG = {
  ALL_LOCATIONS_ID: 'ALL' as const,
  ALL_LOCATIONS_LABEL: 'All Locations',
  DEFAULT_LOCATION_ID: 'loc-001', // Bandra is the primary location
};
