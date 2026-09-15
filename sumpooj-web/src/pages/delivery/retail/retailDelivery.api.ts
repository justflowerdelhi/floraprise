/**
 * retailDelivery.api.ts — Retail Delivery API Integration
 */

import api from '../../../api/axios';
import type { RetailDeliveryItem, RetailDeliveryDriver } from './retailDelivery.types';

export async function fetchRetailDeliveries(params?: {
  date?: string;
  status?: string;
  search?: string;
}): Promise<RetailDeliveryItem[]> {
  const queryParams: Record<string, string> = {};
  if (params?.date) queryParams.date = params.date;
  if (params?.status) queryParams.status = params.status;
  if (params?.search) queryParams.search = params.search;

  const res = await api.get<RetailDeliveryItem[]>('/deliveries', { params: queryParams });
  return res.data;
}

export async function fetchRetailDeliveryDrivers(): Promise<RetailDeliveryDriver[]> {
  const res = await api.get<RetailDeliveryDriver[]>('/deliveries/drivers');
  return res.data;
}

export async function assignDeliveryDriver(
  deliveryId: string,
  staffId: string
): Promise<{ message: string; driverName?: string }> {
  const res = await api.put<{ message: string; driverName?: string }>(
    `/deliveries/${deliveryId}/assign`,
    { staffId }
  );
  return res.data;
}

export async function markDeliveryOutForDelivery(
  deliveryId: string
): Promise<{ message: string }> {
  const res = await api.put<{ message: string }>(
    `/deliveries/${deliveryId}/out-for-delivery`
  );
  return res.data;
}

export async function markDeliveryDelivered(
  deliveryId: string
): Promise<{ message: string }> {
  const res = await api.put<{ message: string }>(
    `/deliveries/${deliveryId}/delivered`
  );
  return res.data;
}
