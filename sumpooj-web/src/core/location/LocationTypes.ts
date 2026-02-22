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

// IDs match remote DB locations for the demo company
export const MOCK_LOCATIONS: Location[] = [
  {
    id: '795f4658-53aa-4016-8484-94cc5d40a7f4',
    name: 'Main Store',
    code: 'MAIN-01',
    address: 'Main Store Location',
    city: 'Delhi NCR',
    phone: '+91 11 1234 5678',
    email: 'main@demoflorist.com',
    isActive: true,
    timezone: 'Asia/Kolkata',
    createdAt: '2020-01-15T10:00:00Z',
    updatedAt: '2026-01-01T10:00:00Z',
  },
  {
    id: 'ce51c174-be15-4691-92f9-f4be76fb58eb',
    name: 'Gurugram',
    code: 'GGN-01',
    address: 'Gurugram Location',
    city: 'Gurugram',
    phone: '+91 124 456 7890',
    email: 'gurugram@demoflorist.com',
    isActive: true,
    timezone: 'Asia/Kolkata',
    createdAt: '2021-06-01T10:00:00Z',
    updatedAt: '2026-01-01T10:00:00Z',
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
  DEFAULT_LOCATION_ID: '795f4658-53aa-4016-8484-94cc5d40a7f4', // Main Store
};
