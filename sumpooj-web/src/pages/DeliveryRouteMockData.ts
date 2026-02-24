// Mock Delivery Routes for testing
// Add more as needed for your test cases
export const MOCK_DELIVERY_ROUTES = [
  {
    id: 'route_001',
    name: 'Downtown Express',
    status: 'Assigned',
    deliveryPersonName: 'Amit Sharma',
    deliveries: [
      {
        id: 'del_001',
        stopOrder: 1,
        orderNumber: 'ORD-2026-0002',
        customerName: 'Raj Kapoor',
        timeSlot: '10:00-12:00',
        postalCode: '411001',
      },
      {
        id: 'del_002',
        stopOrder: 2,
        orderNumber: 'ORD-2026-0004',
        customerName: 'Sunita Rao',
        timeSlot: '12:00-14:00',
        postalCode: '411002',
      },
    ],
  },
  {
    id: 'route_002',
    name: 'Suburb Run',
    status: 'Draft',
    deliveries: [
      {
        id: 'del_003',
        stopOrder: 1,
        orderNumber: 'ORD-2026-0005',
        customerName: 'Vikram Singh',
        timeSlot: '14:00-16:00',
        postalCode: '411003',
      },
    ],
  },
];
