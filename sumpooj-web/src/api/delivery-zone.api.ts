import api from './axios';

// ─── Types ──────────────────────────────────────────────────

export interface DeliveryZone {
  id: string;
  name: string;
  code: string;
  matchType: 'ZIP' | 'AREA' | 'CITY';
  matchValues: string[];
  zipCodes: string[]; // @deprecated - use matchValues
  cities: string[];
  locationId?: string;
  freeDeliveryThreshold?: number;
  deliveryFee: number;
  sameDayFee: number;
  expressFee: number;
  estimatedMinutes: number;
  distanceKm?: number;
  priority: number;
  isServiceable: boolean;
  isActive: boolean;
  notes?: string;
  color?: string;
  createdAtUtc: string;
}

export interface CreateDeliveryZoneRequest {
  name: string;
  code: string;
  matchType: 'ZIP' | 'AREA' | 'CITY';
  matchValues: string[];
  locationId?: string;
  freeDeliveryThreshold?: number;
  deliveryFee: number;
  sameDayFee?: number;
  expressFee?: number;
  estimatedMinutes: number;
  distanceKm?: number;
  priority: number;
  isServiceable?: boolean;
  notes?: string;
  color?: string;
}

export interface CalculateDeliveryFeeRequest {
  zipCode?: string;
  city?: string;
  area?: string;
  isSameDay?: boolean;
  isExpress?: boolean;
  orderAmount: number;
  locationId?: string;
}

export interface DeliveryFeeResult {
  zoneId?: string;
  zoneName?: string;
  baseFee: number;
  sameDayFee: number;
  expressFee: number;
  totalFee: number;
  isFreeDelivery: boolean;
  isServiceable: boolean;
  estimatedMinutes: number;
  message?: string;
}

// ─── API Functions ──────────────────────────────────────────

/** GET /delivery-zones - Get all delivery zones */
export const getDeliveryZones = async (activeOnly = true): Promise<DeliveryZone[]> => {
  const res = await api.get('/delivery-zones', { params: { activeOnly } });
  return res.data;
};

/** GET /delivery-zones/:id - Get delivery zone by ID */
export const getDeliveryZoneById = async (id: string): Promise<DeliveryZone> => {
  const res = await api.get(`/delivery-zones/${id}`);
  return res.data;
};

/** POST /delivery-zones - Create new delivery zone */
export const createDeliveryZone = async (data: CreateDeliveryZoneRequest): Promise<DeliveryZone> => {
  const res = await api.post('/delivery-zones', data);
  return res.data;
};

/** PUT /delivery-zones/:id - Update delivery zone */
export const updateDeliveryZone = async (id: string, data: CreateDeliveryZoneRequest): Promise<DeliveryZone> => {
  const res = await api.put(`/delivery-zones/${id}`, data);
  return res.data;
};

/** DELETE /delivery-zones/:id - Delete delivery zone */
export const deleteDeliveryZone = async (id: string): Promise<void> => {
  await api.delete(`/delivery-zones/${id}`);
};

/** POST /delivery-zones/:id/activate - Activate delivery zone */
export const activateDeliveryZone = async (id: string): Promise<void> => {
  await api.post(`/delivery-zones/${id}/activate`);
};

/** POST /delivery-zones/:id/deactivate - Deactivate delivery zone */
export const deactivateDeliveryZone = async (id: string): Promise<void> => {
  await api.post(`/delivery-zones/${id}/deactivate`);
};

/** POST /delivery-zones/calculate-fee - Calculate delivery fee for a location */
export const calculateDeliveryFee = async (data: CalculateDeliveryFeeRequest): Promise<DeliveryFeeResult> => {
  const res = await api.post('/delivery-zones/calculate-fee', data);
  return res.data;
};
