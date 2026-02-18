/**
 * Location Module - Multi-Location Architecture
 *
 * Exports all location-related types, context, and components.
 */

// Types
export type {
  Location,
  LocationAccessLevel,
  LocationFilterValue,
  LocationFilter,
} from './LocationTypes';

export {
  MOCK_LOCATIONS,
  getActiveLocations,
  getLocationById,
  getLocationsByIds,
  getLocationShortName,
  filterByLocation,
  LOCATION_CONFIG,
} from './LocationTypes';

// Context
export { LocationProvider, useLocation, withLocationFilter } from './LocationContext';

// Components
export { LocationSwitcher, LocationBadge } from './LocationSwitcher';
