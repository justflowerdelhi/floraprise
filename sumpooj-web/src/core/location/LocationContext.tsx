/**
 * LocationContext.tsx — Multi-Location State Management
 *
 * Provides:
 * - Current location state
 * - Location switching for Admin/Manager
 * - Location access control
 * - Filtering utilities
 */
import React, { createContext, useContext, useState, useCallback, useMemo, type ReactNode } from 'react';
import type { Location, LocationFilterValue, LocationAccessLevel } from './LocationTypes';
import {
  MOCK_LOCATIONS,
  getActiveLocations,
  getLocationById,
  LOCATION_CONFIG,
} from './LocationTypes';
import { useRBAC } from '../rbac/RBACContext';
import type { UserRole } from '../rbac/RBACTypes';

// ─── Location Access by Role ────────────────────────────────

const ROLE_LOCATION_ACCESS: Record<UserRole, LocationAccessLevel> = {
  PLATFORMSUPERADMIN: 'ALL',
  ADMIN: 'ALL',
  MANAGER: 'MULTIPLE',
  CASHIER: 'SINGLE',
  DESIGNER: 'SINGLE',
  DRIVER: 'SINGLE',
  STAFF: 'SINGLE',
};

// ─── User Location Assignments (Mock) ───────────────────────
// In production, this would come from the user profile/API

// IDs match Database/005_demo_data_seed.sql Locations for Demo Florist
const LOC_MAIN     = '795f4658-53aa-4016-8484-94cc5d40a7f4';
const LOC_GURUGRAM = 'ce51c174-be15-4691-92f9-f4be76fb58eb';

const USER_LOCATION_ASSIGNMENTS: Record<string, string[]> = {
  'user-admin': [LOC_MAIN, LOC_GURUGRAM], // All active locations
  'user-manager': [LOC_MAIN, LOC_GURUGRAM], // Both locations
  'user-cashier': [LOC_MAIN], // Main Store only
  'user-designer': [LOC_MAIN], // Main Store only
  'user-driver': [LOC_MAIN, LOC_GURUGRAM], // Both (for deliveries)
};

// ─── Context Types ──────────────────────────────────────────

interface LocationContextValue {
  // Current selection
  currentLocation: Location | null;
  currentLocationId: LocationFilterValue;
  isAllLocations: boolean;

  // Available locations for current user
  accessibleLocations: Location[];
  accessLevel: LocationAccessLevel;
  canSwitchLocation: boolean;
  canViewAllLocations: boolean;

  // Actions
  setCurrentLocationId: (locationId: LocationFilterValue) => void;
  switchToAllLocations: () => void;

  // Filtering helpers
  getFilteredItems: <T extends { locationId?: string }>(items: T[]) => T[];
  isLocationAccessible: (locationId: string) => boolean;

  // Location data
  allLocations: Location[];
  activeLocations: Location[];
  getLocation: (id: string) => Location | null;
}

// ─── Context Creation ───────────────────────────────────────

const LocationContext = createContext<LocationContextValue | null>(null);

// ─── Provider Component ─────────────────────────────────────

interface LocationProviderProps {
  children: ReactNode;
}

export const LocationProvider: React.FC<LocationProviderProps> = ({ children }) => {
  const { user, role } = useRBAC();

  // Get user's accessible locations
  const accessibleLocations = useMemo(() => {
    if (!user || !role) return [];

    const accessLevel = ROLE_LOCATION_ACCESS[role];
    const assignedIds = USER_LOCATION_ASSIGNMENTS[user.id] || [];

    if (accessLevel === 'ALL') {
      return getActiveLocations();
    }

    return MOCK_LOCATIONS.filter(
      (loc) => loc.isActive && assignedIds.includes(loc.id)
    );
  }, [user, role]);

  // Determine access level
  const accessLevel = useMemo((): LocationAccessLevel => {
    if (!role) return 'SINGLE';
    return ROLE_LOCATION_ACCESS[role];
  }, [role]);

  // Default location — always pick a specific location so POS / shifts work out of the box.
  // Admin can still switch to "All Locations" from the dropdown if they want a cross-store view.
  const defaultLocationId = useMemo((): LocationFilterValue => {
    if (accessibleLocations.length > 0) return accessibleLocations[0].id;
    return LOCATION_CONFIG.DEFAULT_LOCATION_ID;
  }, [accessibleLocations]);

  // Current location state
  const [currentLocationId, setCurrentLocationId] = useState<LocationFilterValue>(defaultLocationId);

  // Current location object
  const currentLocation = useMemo((): Location | null => {
    if (currentLocationId === LOCATION_CONFIG.ALL_LOCATIONS_ID) return null;
    return getLocationById(currentLocationId);
  }, [currentLocationId]);

  // Computed flags
  const isAllLocations = currentLocationId === LOCATION_CONFIG.ALL_LOCATIONS_ID;
  const canSwitchLocation = accessLevel !== 'SINGLE' || accessibleLocations.length > 1;
  const canViewAllLocations = accessLevel === 'ALL';

  // Check if a location is accessible
  const isLocationAccessible = useCallback(
    (locationId: string): boolean => {
      if (accessLevel === 'ALL') return true;
      return accessibleLocations.some((loc) => loc.id === locationId);
    },
    [accessLevel, accessibleLocations]
  );

  // Handle location change with validation
  const handleSetLocationId = useCallback(
    (locationId: LocationFilterValue) => {
      // Admin can select "ALL"
      if (locationId === LOCATION_CONFIG.ALL_LOCATIONS_ID && canViewAllLocations) {
        setCurrentLocationId(locationId);
        return;
      }

      // Validate access to specific location
      if (locationId !== LOCATION_CONFIG.ALL_LOCATIONS_ID && isLocationAccessible(locationId)) {
        setCurrentLocationId(locationId);
      }
    },
    [canViewAllLocations, isLocationAccessible]
  );

  // Switch to all locations (Admin only)
  const switchToAllLocations = useCallback(() => {
    if (canViewAllLocations) {
      setCurrentLocationId(LOCATION_CONFIG.ALL_LOCATIONS_ID);
    }
  }, [canViewAllLocations]);

  // Filter items by current location
  const getFilteredItems = useCallback(
    <T extends { locationId?: string }>(items: T[]): T[] => {
      if (isAllLocations) return items;
      return items.filter((item) => item.locationId === currentLocationId);
    },
    [currentLocationId, isAllLocations]
  );

  // Context value
  const value = useMemo(
    (): LocationContextValue => ({
      currentLocation,
      currentLocationId,
      isAllLocations,
      accessibleLocations,
      accessLevel,
      canSwitchLocation,
      canViewAllLocations,
      setCurrentLocationId: handleSetLocationId,
      switchToAllLocations,
      getFilteredItems,
      isLocationAccessible,
      allLocations: MOCK_LOCATIONS,
      activeLocations: getActiveLocations(),
      getLocation: getLocationById,
    }),
    [
      currentLocation,
      currentLocationId,
      isAllLocations,
      accessibleLocations,
      accessLevel,
      canSwitchLocation,
      canViewAllLocations,
      handleSetLocationId,
      switchToAllLocations,
      getFilteredItems,
      isLocationAccessible,
    ]
  );

  return <LocationContext.Provider value={value}>{children}</LocationContext.Provider>;
};

// ─── Hook ───────────────────────────────────────────────────

export const useLocation = (): LocationContextValue => {
  const context = useContext(LocationContext);
  if (!context) {
    throw new Error('useLocation must be used within LocationProvider');
  }
  return context;
};

// ─── HOC for Location-Aware Components ──────────────────────

interface WithLocationProps {
  locationId?: string;
}

export function withLocationFilter<T extends WithLocationProps>(
  WrappedComponent: React.ComponentType<T>
): React.FC<Omit<T, 'locationId'>> {
  return function LocationFilteredComponent(props) {
    const { currentLocationId, isAllLocations } = useLocation();
    const locationId = isAllLocations ? undefined : currentLocationId;
    return <WrappedComponent {...(props as T)} locationId={locationId as string | undefined} />;
  };
}

export default LocationContext;
