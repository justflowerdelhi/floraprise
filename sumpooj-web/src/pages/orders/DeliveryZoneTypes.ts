/**
 * DeliveryZoneTypes.ts — Delivery Zone Model for Route Optimization
 * 
 * Supports:
 * - ZIP-based zone matching (US, India)
 * - Area/neighborhood matching (UAE, etc.)
 * - City-level matching
 * - Variable delivery fees
 * - Service area validation
 * - Multi-location awareness
 */

// ─── Zone Match Type ────────────────────────────────────────

export type ZoneMatchType = 'ZIP' | 'AREA' | 'CITY';

// ─── Delivery Zone Model ────────────────────────────────────

export interface DeliveryZone {
  id: string;
  name: string;
  locationId?: string;              // Multi-location: which shop location this zone belongs to

  // Flexible matching
  matchType: ZoneMatchType;
  matchValues: string[];            // ZIP codes, area names, or city names depending on matchType

  /** @deprecated Use matchValues instead. Kept for backward compatibility. */
  zipCodes: string[];

  deliveryFee: number;
  estimatedMinutes: number;         // Travel time from shop
  isServiceable: boolean;
  priority: number;                 // Lower = higher priority for overlapping zones
  color?: string;                   // For map visualization
}

// ─── Structured Delivery Address ────────────────────────────

export interface DeliveryAddress {
  // User-facing single input
  fullAddress: string;
  
  // Auto-extracted components
  street: string;
  city: string;
  state: string;
  zipCode: string;
  country: string;
  
  // Geocoding
  latitude: number;
  longitude: number;
  
  // Zone matching result
  deliveryZone?: DeliveryZone;
  
  // Google Places metadata (optional)
  placeId?: string;
  formattedAddress?: string;
}

// ─── Fulfillment Type ────────────────────────────────────────

export type FulfillmentType = 'PICKUP' | 'DELIVERY';

// ─── Mock Delivery Zones ─────────────────────────────────────

export const MOCK_DELIVERY_ZONES: DeliveryZone[] = [
  {
    id: 'zone_1',
    name: 'Zone 1 - Downtown',
    matchType: 'ZIP',
    matchValues: ['411001', '411002', '411003', '400001', '400002'],
    zipCodes: ['411001', '411002', '411003', '400001', '400002'],
    deliveryFee: 100,
    estimatedMinutes: 15,
    isServiceable: true,
    priority: 1,
    color: '#4caf50',
  },
  {
    id: 'zone_2',
    name: 'Zone 2 - Suburbs',
    matchType: 'ZIP',
    matchValues: ['411004', '411005', '411045', '400003', '400004'],
    zipCodes: ['411004', '411005', '411045', '400003', '400004'],
    deliveryFee: 150,
    estimatedMinutes: 30,
    isServiceable: true,
    priority: 2,
    color: '#2196f3',
  },
  {
    id: 'zone_3',
    name: 'Zone 3 - Extended',
    matchType: 'ZIP',
    matchValues: ['411006', '411007', '411008', '400005', '400006'],
    zipCodes: ['411006', '411007', '411008', '400005', '400006'],
    deliveryFee: 200,
    estimatedMinutes: 45,
    isServiceable: true,
    priority: 3,
    color: '#ff9800',
  },
  {
    id: 'zone_4',
    name: 'Zone 4 - Premium',
    matchType: 'ZIP',
    matchValues: ['500033', '560025', '600040', '110054'],
    zipCodes: ['500033', '560025', '600040', '110054'],
    deliveryFee: 300,
    estimatedMinutes: 60,
    isServiceable: true,
    priority: 4,
    color: '#9c27b0',
  },
];
