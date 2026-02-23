import api from '../../api/axios';

const USE_MOCK_DATA = import.meta.env.DEV;

// ── Types ────────────────────────────────────────────────────────────────

export interface DeliveryListItem {
  deliveryId: string;
  orderNumber: string;
  customerName: string;
  phone: string | null;
  deliveryDate: string;
  timeSlot: string;
  address: string;
  status: 'Scheduled' | 'OutForDelivery' | 'Delivered' | 'Failed' | 'Cancelled';
  deliveryPersonName: string | null;
}

export interface StaffOption {
  id: string;
  name: string;
}

// ── Mock Data ────────────────────────────────────────────────────────────

const MOCK_DELIVERIES: DeliveryListItem[] = [
  { deliveryId: 'd1', orderNumber: 'SO-20260224-001', customerName: 'Sarah Johnson', phone: '9876543210', deliveryDate: new Date().toISOString(), timeSlot: '10:00 AM – 12:00 PM', address: '42 Park Avenue, Downtown', status: 'Scheduled', deliveryPersonName: null },
  { deliveryId: 'd2', orderNumber: 'SO-20260224-002', customerName: 'Michael Chen', phone: '9876543211', deliveryDate: new Date().toISOString(), timeSlot: '12:00 PM – 2:00 PM', address: '15 Oak Street, Midtown', status: 'Scheduled', deliveryPersonName: 'Tom Driver' },
  { deliveryId: 'd3', orderNumber: 'SO-20260224-003', customerName: 'Emily Davis', phone: '9876543212', deliveryDate: new Date().toISOString(), timeSlot: '2:00 PM – 4:00 PM', address: '88 Maple Drive, Uptown', status: 'OutForDelivery', deliveryPersonName: 'Jake Runner' },
  { deliveryId: 'd4', orderNumber: 'SO-20260224-004', customerName: 'Raj Patel', phone: '9876543213', deliveryDate: new Date().toISOString(), timeSlot: '10:00 AM – 12:00 PM', address: '7 River Road, Eastside', status: 'Delivered', deliveryPersonName: 'Tom Driver' },
  { deliveryId: 'd5', orderNumber: 'SO-20260224-005', customerName: 'Lisa Wang', phone: '9876543214', deliveryDate: new Date().toISOString(), timeSlot: '4:00 PM – 6:00 PM', address: '202 Elm Boulevard, Westend', status: 'OutForDelivery', deliveryPersonName: null },
];

const MOCK_STAFF: StaffOption[] = [
  { id: 's1', name: 'Tom Driver' },
  { id: 's2', name: 'Jake Runner' },
  { id: 's3', name: 'Amy Swift' },
];

// ── API Functions ────────────────────────────────────────────────────────

export async function getDeliveries(date?: string): Promise<DeliveryListItem[]> {
  if (USE_MOCK_DATA) {
    await new Promise((r) => setTimeout(r, 400));
    return MOCK_DELIVERIES;
  }
  const params = date ? { date } : {};
  const res = await api.get('/deliveries', { params });
  return res.data;
}

export async function markOutForDelivery(deliveryId: string): Promise<void> {
  if (USE_MOCK_DATA) {
    await new Promise((r) => setTimeout(r, 400));
    return;
  }
  await api.put(`/deliveries/${deliveryId}/out-for-delivery`);
}

export async function markDelivered(deliveryId: string): Promise<void> {
  if (USE_MOCK_DATA) {
    await new Promise((r) => setTimeout(r, 400));
    return;
  }
  await api.put(`/deliveries/${deliveryId}/delivered`);
}

export async function assignDeliveryPerson(deliveryId: string, staffId: string): Promise<void> {
  if (USE_MOCK_DATA) {
    await new Promise((r) => setTimeout(r, 400));
    return;
  }
  await api.put(`/deliveries/${deliveryId}/assign`, { staffId });
}

export async function getDeliveryStaff(): Promise<StaffOption[]> {
  if (USE_MOCK_DATA) {
    await new Promise((r) => setTimeout(r, 300));
    return MOCK_STAFF;
  }
  const res = await api.get('/Staff/by-role/delivery');
  return res.data;
}
