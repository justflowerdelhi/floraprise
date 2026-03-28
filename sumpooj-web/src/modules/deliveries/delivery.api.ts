import api from '../../api/axios';

// ── Types ────────────────────────────────────────────────────────────────

export interface DeliveryListItem {
  deliveryId: string;
  orderNumber: string;
  customerName: string;
  phone: string | null;
  deliveryDate: string;
  timeSlot: string;
  address: string;
  postalCode: string | null;
  status: 'Scheduled' | 'OutForDelivery' | 'Delivered' | 'Failed' | 'Cancelled';
  deliveryPersonName: string | null;
}

export interface StaffOption {
  id: string;
  name: string;
}

// ── API Functions ────────────────────────────────────────────────────────

export async function getDeliveries(date?: string): Promise<DeliveryListItem[]> {
  const params = date ? { date } : {};
  const res = await api.get('/deliveries', { params });
  return res.data;
}

export async function markOutForDelivery(deliveryId: string): Promise<void> {
  await api.put(`/deliveries/${deliveryId}/out-for-delivery`);
}

export async function markDelivered(deliveryId: string): Promise<void> {
  await api.put(`/deliveries/${deliveryId}/delivered`);
}

export async function assignDeliveryPerson(deliveryId: string, staffId: string): Promise<void> {
  await api.put(`/deliveries/${deliveryId}/assign`, { staffId });
}

export async function getDeliveryStaff(): Promise<StaffOption[]> {
  const res = await api.get('/Staff/by-role/delivery');
  return res.data;
}
