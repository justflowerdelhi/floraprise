/**
 * DeliveryZoneTypes.ts — Delivery Zone Model for Route Optimization
 * 
 * Supports:
 * - ZIP-based zone matching
 * - Variable delivery fees
 * - Service area validation
 * - Future routing logic integration
 */

// ─── Delivery Zone Model ────────────────────────────────────

export interface DeliveryZone {
  id: string;
  name: string;
  zipCodes: string[];
  deliveryFee: number;
  estimatedMinutes: number;  // Travel time from shop
  isServiceable: boolean;
  priority: number;           // Lower = higher priority for overlapping zones
  color?: string;             // For map visualization
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
    zipCodes: ['500033', '560025', '600040', '110054'],
    deliveryFee: 300,
    estimatedMinutes: 60,
    isServiceable: true,
    priority: 4,
    color: '#9c27b0',
  },
];
