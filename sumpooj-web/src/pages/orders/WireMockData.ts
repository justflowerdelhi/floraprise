import type { VendorFlorist, WireSettlement } from './OrderTypes';

export const MOCK_VENDOR_FLORISTS: VendorFlorist[] = [
  {
    id: 'vendor_001',
    name: 'Rosewood Florals',
    city: 'Pune',
    state: 'MH',
    phone: '020-4000-1111',
    email: 'orders@rosewoodflorals.com',
    defaultCommissionRate: 18,
    isActive: true,
  },
  {
    id: 'vendor_002',
    name: 'Urban Petals',
    city: 'Mumbai',
    state: 'MH',
    phone: '022-4555-2222',
    email: 'hello@urbanpetals.in',
    defaultCommissionRate: 20,
    isActive: true,
  },
  {
    id: 'vendor_003',
    name: 'Greenline Blooms',
    city: 'Bengaluru',
    state: 'KA',
    phone: '080-4777-3333',
    email: 'sales@greenlineblooms.com',
    defaultCommissionRate: 15,
    isActive: false,
  },
];

export const MOCK_WIRE_SETTLEMENTS: WireSettlement[] = [
  {
    orderNumber: 'ORD-2026-0101',
    vendorName: 'Rosewood Florals',
    amount: 1850,
    status: 'PENDING',
  },
  {
    orderNumber: 'ORD-2026-0102',
    vendorName: 'Urban Petals',
    amount: 2400,
    status: 'SENT',
  },
  {
    orderNumber: 'ORD-2026-0103',
    vendorName: 'Rosewood Florals',
    amount: 1320,
    status: 'CLEARED',
  },
];