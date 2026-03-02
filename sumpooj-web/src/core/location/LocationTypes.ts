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

// Kept as fallback — LocationContext fetches real data from GET /locations
export const MOCK_LOCATIONS: Location[] = [];

// ─── Location State (populated at runtime by LocationContext) ──

let _locations: Location[] = [];

export function setLocationsData(locations: Location[]) {
  _locations = locations;
}

// ─── Location Helper Functions ──────────────────────────────

/**
 * Get all active locations
 */
export const getActiveLocations = (): Location[] => 
  _locations.filter(loc => loc.isActive);

/**
 * Get location by ID
 */
export const getLocationById = (id: string): Location | null => 
  _locations.find(loc => loc.id === id) || null;

/**
 * Get locations by IDs
 */
export const getLocationsByIds = (ids: string[]): Location[] => 
  _locations.filter(loc => ids.includes(loc.id));

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
