/**
 * DeliveryZoneUtils.ts — Zone Matching & Validation Logic
 * 
 * Auto-detects delivery zones from ZIP codes
 * Applies delivery fees
 * Validates service areas
 */

import type { DeliveryZone, DeliveryAddress } from './DeliveryZoneTypes';
import { MOCK_DELIVERY_ZONES } from './DeliveryZoneTypes';

// ─── Zone Matching ─────────────────────────────────────────

/**
 * Find delivery zone by ZIP code
 * Returns the highest priority zone if multiple zones service the same ZIP
 */
export const findDeliveryZone = (zipCode: string): DeliveryZone | null => {
  if (!zipCode) return null;
  
  const normalizedZip = zipCode.trim();
  
  const matchingZones = MOCK_DELIVERY_ZONES.filter((zone) =>
    zone.zipCodes.includes(normalizedZip) && zone.isServiceable
  );
  
  if (matchingZones.length === 0) return null;
  
  // Return highest priority zone (lowest priority number)
  return matchingZones.sort((a, b) => a.priority - b.priority)[0];
};

/**
 * Check if a ZIP code is serviceable
 */
export const isZipServiceable = (zipCode: string): boolean => {
  return findDeliveryZone(zipCode) !== null;
};

/**
 * Get delivery fee for a ZIP code
 */
export const getDeliveryFee = (zipCode: string): number => {
  const zone = findDeliveryZone(zipCode);
  return zone?.deliveryFee ?? 0;
};

// ─── Address Parsing ────────────────────────────────────────

/**
 * Extract ZIP code from Google Places result
 */
export const extractZipFromPlaceResult = (
  place: any  // google.maps.places.PlaceResult when API loaded
): string => {
  const postalCodeComponent = place.address_components?.find((component: any) =>
    component.types.includes('postal_code')
  );
  
  return postalCodeComponent?.long_name ?? '';
};

/**
 * Extract structured address from Google Places result
 */
export const parseGooglePlaceResult = (
  place: any  // google.maps.places.PlaceResult when API loaded
): Partial<DeliveryAddress> => {
  const components = place.address_components || [];
  
  const getComponent = (type: string): string => {
    const component = components.find((c: any) => c.types.includes(type));
    return component?.long_name ?? '';
  };
  
  const street = [
    getComponent('street_number'),
    getComponent('route'),
  ]
    .filter(Boolean)
    .join(' ');
  
  const city = getComponent('locality') || getComponent('administrative_area_level_2');
  const state = getComponent('administrative_area_level_1');
  const zipCode = getComponent('postal_code');
  const country = getComponent('country');
  
  const latitude = place.geometry?.location?.lat() ?? 0;
  const longitude = place.geometry?.location?.lng() ?? 0;
  
  const deliveryZone = findDeliveryZone(zipCode);
  
  return {
    fullAddress: place.formatted_address || '',
    street,
    city,
    state,
    zipCode,
    country,
    latitude,
    longitude,
    deliveryZone: deliveryZone || undefined,
    placeId: place.place_id,
    formattedAddress: place.formatted_address,
  };
};

/**
 * Extract basic ZIP from any address string (fallback for manual entry)
 */
export const extractZipFromString = (address: string): string => {
  // Match Indian ZIP (6 digits) or US ZIP (5 digits or 5+4)
  const match = address.match(/\b(\d{5,6}(?:-\d{4})?)\b/);
  return match ? match[1] : '';
};

/**
 * Format delivery zone message for UI
 */
export const formatZoneMessage = (zone: DeliveryZone): string => {
  return `${zone.name} – ₹${zone.deliveryFee} (${zone.estimatedMinutes} mins)`;
};

/**
 * Validate delivery address completeness
 */
export const validateDeliveryAddress = (address: Partial<DeliveryAddress>): string[] => {
  const errors: string[] = [];
  
  if (!address.fullAddress) errors.push('Address is required');
  if (!address.zipCode) errors.push('ZIP code is required');
  if (!address.city) errors.push('City is required');
  
  if (address.zipCode && !isZipServiceable(address.zipCode)) {
    errors.push('This area is not serviceable');
  }
  
  return errors;
};
