/**
 * OrderMockData.ts — Mock products, batches, orders, external orders, deliveries
 */
import type {
  Product,
  InventoryBatch,
  Order,
  ExternalOrder,
  DeliveryEntry,
  ProductCategory,
} from './OrderTypes';

// ─── Helpers ────────────────────────────────────────────────

const today = new Date();
const isoDate  = (d: Date) => d.toISOString().slice(0, 10);
const daysFrom = (n: number) => { const d = new Date(today); d.setDate(d.getDate() + n); return isoDate(d); };
const daysAgo  = (n: number) => daysFrom(-n);

let _batchSeq = 0;
const mkBatch = (
  productId: string,
  qty: number,
  cost: number,
  receivedDaysAgo: number,
  expiryDaysFromNow: number,
  supplier: string,
): InventoryBatch => ({
  batchId: `B${String(++_batchSeq).padStart(4, '0')}`,
  productId,
  quantity: qty,
  costPerUnit: cost,
  receivedDate: daysAgo(receivedDaysAgo),
  expiryDate: daysFrom(expiryDaysFromNow),
  supplier,
});

// ─── Products + Batches ─────────────────────────────────────

const P = (
  id: string, name: string, sku: string, barcode: string,
  cat: ProductCategory, sell: number, cost: number, tax: number,
  stock: number, perishable: boolean, batches: InventoryBatch[],
): Product => ({
  id, name, sku, barcode, category: cat,
  sellingPrice: sell, costPrice: cost, taxRate: tax,
  availableStock: stock, isPerishable: perishable, batches,
});

export const MOCK_PRODUCTS: Product[] = [
  P('p01','Red Roses (Premium)','RSP-001','8901234001','Fresh Flowers',    280, 120, 0.05, 180, true, [
    mkBatch('p01', 80, 115, 3, 4, 'Holland Direct'),
    mkBatch('p01', 60, 120, 1, 6, 'Holland Direct'),
    mkBatch('p01', 40, 125, 0, 8, 'Local Growers Co-op'),
  ]),
  P('p02','White Lilies','WHL-002','8901234002','Fresh Flowers',          350, 160, 0.05, 95, true, [
    mkBatch('p02', 50, 155, 4, 3, 'FlowerFresh Imports'),
    mkBatch('p02', 45, 165, 1, 7, 'Holland Direct'),
  ]),
  P('p03','Sunflowers','SNF-003','8901234003','Fresh Flowers',            190, 80, 0.05, 60, true, [
    mkBatch('p03', 35, 78, 2, 5, 'Local Growers Co-op'),
    mkBatch('p03', 25, 82, 0, 9, 'Local Growers Co-op'),
  ]),
  P('p04','Classic Rose Bouquet','CRB-010','8901234010','Bouquets',        850, 380, 0.12, 25, true, [
    mkBatch('p04', 15, 370, 2, 5, 'In-House'),
    mkBatch('p04', 10, 390, 0, 8, 'In-House'),
  ]),
  P('p05','Spring Garden Arrangement','SGA-011','8901234011','Arrangements',1200, 520, 0.12, 12, true, [
    mkBatch('p05', 8, 510, 1, 4, 'In-House'),
    mkBatch('p05', 4, 530, 0, 7, 'In-House'),
  ]),
  P('p06','Orchid Phalaenopsis','ORC-004','8901234004','Plants',           550, 280, 0.05, 30, false, [
    mkBatch('p06', 20, 270, 5, 30, 'FlowerFresh Imports'),
    mkBatch('p06', 10, 290, 1, 45, 'FlowerFresh Imports'),
  ]),
  P('p07','Eucalyptus Bunch','EUC-005','8901234005','Greens & Foliage',    210, 90, 0.05, 110, true, [
    mkBatch('p07', 60, 85, 3, 4, 'GreenLeaf Distributors'),
    mkBatch('p07', 50, 95, 1, 8, 'GreenLeaf Distributors'),
  ]),
  P('p08',"Baby's Breath","BBR-006",'8901234006','Fresh Flowers',           60, 22, 0.05, 420, true, [
    mkBatch('p08', 200, 20, 2, 5, 'Holland Direct'),
    mkBatch('p08', 220, 24, 0, 9, 'Local Growers Co-op'),
  ]),
  P('p09','Glass Cylinder Vase','GCV-020','8901234020','Add-Ons',          450, 180, 0.18, 45, false, [
    mkBatch('p09', 45, 180, 20, 999, 'Petal Perfect'),
  ]),
  P('p10','Satin Ribbon Roll','SRR-021','8901234021','Supplies',            110, 45, 0.18, 80, false, [
    mkBatch('p10', 80, 45, 15, 999, 'Petal Perfect'),
  ]),
  P('p11','Gift Wrapping Paper','GWP-022','8901234022','Gift Items',         30, 10, 0.18, 350, false, [
    mkBatch('p11', 350, 10, 25, 999, 'Petal Perfect'),
  ]),
  P('p12','Teddy Bear (Medium)','TBM-030','8901234030','Add-Ons',          480, 200, 0.18, 18, false, [
    mkBatch('p12', 18, 200, 30, 999, 'Petal Perfect'),
  ]),
  P('p13','Chocolate Box (Premium)','CBP-031','8901234031','Add-Ons',       650, 320, 0.12, 22, false, [
    mkBatch('p13', 22, 320, 10, 60, 'Petal Perfect'),
  ]),
  P('p14','Pink Carnations','PCN-007','8901234007','Fresh Flowers',         120, 48, 0.05, 140, true, [
    mkBatch('p14', 80, 45, 3, 4, 'Pacific Blooms'),
    mkBatch('p14', 60, 50, 0, 7, 'Pacific Blooms'),
  ]),
  P('p15','Sympathy Spray','SYS-012','8901234012','Arrangements',         2200, 950, 0.12, 6, true, [
    mkBatch('p15', 6, 950, 1, 5, 'In-House'),
  ]),
  P('p16','Preserved Rose Box','PRB-032','8901234032','Gift Items',       1200, 480, 0.18, 14, false, [
    mkBatch('p16', 14, 480, 15, 180, 'Petal Perfect'),
  ]),
];

// ─── Mock Orders ────────────────────────────────────────────

export const MOCK_ORDERS: Order[] = [
  {
    id: 'ord_001', orderNumber: 'ORD-2026-0001', orderSource: 'WALK_IN',
    isPriceEditable: true, customerName: 'Meera Joshi', customerPhone: '9876543210',
    fulfillmentStatus: 'COMPLETED', paymentStatus: 'PAID',
    items: [], totals: { subtotal: 1130, taxTotal: 56.5, discountTotal: 0, grandTotal: 1186.5, totalCost: 500, marginPercent: 57.9, marginWarning: false, itemCount: 4, lineCount: 2 },
    createdAt: daysAgo(5), updatedAt: daysAgo(5),
  },
  {
    id: 'ord_002', orderNumber: 'ORD-2026-0002', orderSource: 'PHONE',
    isPriceEditable: true, customerName: 'Raj Kapoor', customerPhone: '9988776655',
    recipientName: 'Priya Kapoor', recipientPhone: '9988776600',
    deliveryDate: daysFrom(1), deliveryAddress: '45 MG Road, Pune 411001',
    cardMessage: 'Happy Anniversary!', occasion: 'Anniversary',
    fulfillmentStatus: 'IN_DESIGN', paymentStatus: 'UNPAID',
    items: [], totals: { subtotal: 2050, taxTotal: 246, discountTotal: 100, grandTotal: 2196, totalCost: 900, marginPercent: 59, marginWarning: false, itemCount: 3, lineCount: 2 },
    createdAt: daysAgo(1), updatedAt: daysAgo(1),
  },
  {
    id: 'ord_003', orderNumber: 'ORD-2026-0003', orderSource: 'FTD',
    externalOrderId: 'FTD-98765', externalPlatform: 'FTD',
    isExternallyPaid: true, isPriceEditable: false,
    senderName: 'David Johnson', recipientName: 'Jennifer Smith', recipientPhone: '555-0123',
    customerName: 'Jennifer Smith', deliveryDate: daysFrom(2),
    deliveryAddress: '12 Palm Drive, Mumbai 400001',
    cardMessage: 'Get well soon!', occasion: 'Get Well',
    externalCommission: 945, externalFees: 0, netPayout: 2555,
    fulfillmentStatus: 'CONFIRMED', paymentStatus: 'PAID',
    items: [], totals: { subtotal: 3500, taxTotal: 0, discountTotal: 0, grandTotal: 3500, totalCost: 1500, marginPercent: 57.1, marginWarning: false, itemCount: 5, lineCount: 3 },
    createdAt: daysAgo(0), updatedAt: daysAgo(0),
  },
  {
    id: 'ord_004', orderNumber: 'ORD-2026-0004', orderSource: 'WEBSITE',
    isPriceEditable: true, customerName: 'Sneha Patil', customerPhone: '8877665544',
    recipientName: 'Deepa Patil',
    deliveryDate: daysFrom(3), deliveryAddress: '78 Shivaji Nagar, Pune 411005',
    fulfillmentStatus: 'READY', paymentStatus: 'PAID',
    items: [], totals: { subtotal: 850, taxTotal: 102, discountTotal: 50, grandTotal: 902, totalCost: 380, marginPercent: 57.9, marginWarning: false, itemCount: 1, lineCount: 1 },
    createdAt: daysAgo(2), updatedAt: daysAgo(0),
  },
  {
    id: 'ord_005', orderNumber: 'ORD-2026-0005', orderSource: 'WALK_IN',
    isPriceEditable: true, customerName: 'Amit Deshmukh',
    fulfillmentStatus: 'DRAFT', paymentStatus: 'UNPAID',
    items: [], totals: { subtotal: 560, taxTotal: 28, discountTotal: 0, grandTotal: 588, totalCost: 220, marginPercent: 62.6, marginWarning: false, itemCount: 3, lineCount: 2 },
    createdAt: daysAgo(0), updatedAt: daysAgo(0),
  },
  {
    id: 'ord_006', orderNumber: 'ORD-2026-0006', orderSource: 'BLOOMNATION',
    externalOrderId: 'BN-20260215-001', externalPlatform: 'BLOOMNATION',
    isExternallyPaid: true, isPriceEditable: false,
    senderName: 'Michael Carter', recipientName: 'Lakshmi Nair', recipientPhone: '9900112233',
    customerName: 'Michael Carter',
    deliveryDate: daysFrom(1), deliveryAddress: '33 Koregaon Park, Pune 411001',
    cardMessage: 'Wishing you all the best!', occasion: 'Congratulations',
    externalCommission: 250, externalFees: 0, netPayout: 2250,
    fulfillmentStatus: 'IN_DESIGN', paymentStatus: 'PAID',
    items: [], totals: { subtotal: 2500, taxTotal: 0, discountTotal: 0, grandTotal: 2500, totalCost: 980, marginPercent: 60.8, marginWarning: false, itemCount: 3, lineCount: 2 },
    createdAt: daysAgo(0), updatedAt: daysAgo(0),
  },
  {
    id: 'ord_007', orderNumber: 'ORD-2026-0007', orderSource: 'PHONE',
    isPriceEditable: true, customerName: 'Arjun Mehta', customerPhone: '7766554433',
    recipientName: 'Sanya Mehta',
    deliveryDate: daysFrom(0), deliveryAddress: '88 Baner Road, Pune 411045',
    cardMessage: 'Happy Birthday sweetheart!', occasion: 'Birthday',
    fulfillmentStatus: 'READY', paymentStatus: 'PARTIAL',
    items: [], totals: { subtotal: 1800, taxTotal: 216, discountTotal: 0, grandTotal: 2016, totalCost: 720, marginPercent: 60, marginWarning: false, itemCount: 2, lineCount: 2 },
    createdAt: daysAgo(1), updatedAt: daysAgo(0),
  },
];

// ─── Mock External Orders (FTD + BloomNation Inbox) ─────────

export const MOCK_EXTERNAL_ORDERS: ExternalOrder[] = [
  {
    id: 'ext_001', externalOrderId: 'FTD-10234', platform: 'FTD',
    senderName: 'Robert Williams',
    recipientName: 'Sarah Johnson', recipientPhone: '555-0101',
    deliveryDate: daysFrom(1), deliveryAddress: '123 Oak Street, Mumbai 400001',
    deliveryInstructions: 'Leave at front desk if not home',
    cardMessage: 'Happy Birthday! With love from your family.',
    grossAmount: 4500, commission: 1215, fees: 0, netPayout: 3285,
    status: 'PENDING', receivedAt: daysAgo(0), isExternallyPaid: true,
    items: [
      { productName: 'Premium Rose Arrangement', quantity: 1, unitPrice: 3200 },
      { productName: 'Chocolate Box', quantity: 1, unitPrice: 650 },
      { productName: 'Teddy Bear', quantity: 1, unitPrice: 650 },
    ],
  },
  {
    id: 'ext_002', externalOrderId: 'FTD-10235', platform: 'FTD',
    senderName: 'Laura Martinez',
    recipientName: 'Priya Menon', recipientPhone: '555-0202',
    deliveryDate: daysFrom(2), deliveryAddress: '456 MG Road, Pune 411001',
    cardMessage: 'Congratulations on your promotion!',
    grossAmount: 2800, commission: 756, fees: 0, netPayout: 2044,
    status: 'PENDING', receivedAt: daysAgo(0), isExternallyPaid: true,
    items: [
      { productName: 'Spring Garden Arrangement', quantity: 1, unitPrice: 1800 },
      { productName: 'Preserved Rose Box', quantity: 1, unitPrice: 1000 },
    ],
  },
  {
    id: 'ext_003', externalOrderId: 'FTD-10220', platform: 'FTD',
    senderName: 'James Thompson',
    recipientName: 'Vikram Shah', recipientPhone: '555-0303',
    deliveryDate: daysFrom(0), deliveryAddress: '789 Brigade Road, Bangalore 560001',
    cardMessage: 'Deepest sympathies.',
    grossAmount: 5500, commission: 1485, fees: 0, netPayout: 4015,
    status: 'ACCEPTED', receivedAt: daysAgo(2), isExternallyPaid: true,
    items: [
      { productName: 'Sympathy Spray', quantity: 1, unitPrice: 3500 },
      { productName: 'White Lilies Arrangement', quantity: 2, unitPrice: 1000 },
    ],
  },
  {
    id: 'ext_004', externalOrderId: 'FTD-10210', platform: 'FTD',
    senderName: 'Emily Davis',
    recipientName: 'Aisha Khan', recipientPhone: '555-0404',
    deliveryDate: daysAgo(1), deliveryAddress: '321 FC Road, Pune 411004',
    cardMessage: 'Thank you for everything!',
    grossAmount: 1800, commission: 486, fees: 0, netPayout: 1314,
    status: 'ACCEPTED', receivedAt: daysAgo(3), isExternallyPaid: true,
    items: [
      { productName: 'Classic Rose Bouquet', quantity: 1, unitPrice: 1200 },
      { productName: 'Gift Wrapping', quantity: 1, unitPrice: 600 },
    ],
  },
  {
    id: 'ext_005', externalOrderId: 'FTD-10198', platform: 'FTD',
    senderName: 'Mark Anderson',
    recipientName: 'David Chen', recipientPhone: '555-0505',
    deliveryDate: daysAgo(2), deliveryAddress: '55 Park Street, Kolkata 700016',
    cardMessage: 'Happy Anniversary!',
    grossAmount: 3200, commission: 864, fees: 0, netPayout: 2336,
    status: 'REJECTED', receivedAt: daysAgo(4), isExternallyPaid: true,
    items: [
      { productName: 'Orchid Collection', quantity: 2, unitPrice: 1600 },
    ],
  },
  // ─── BloomNation Orders ───────
  {
    id: 'ext_006', externalOrderId: 'BN-20260215-042', platform: 'BLOOMNATION',
    senderName: 'Jessica Brown',
    recipientName: 'Anita Sharma', recipientPhone: '9876501234',
    deliveryDate: daysFrom(1), deliveryAddress: '10 Hinjawadi Phase 1, Pune 411057',
    deliveryInstructions: 'Ring the bell twice, apartment 4B',
    cardMessage: 'You make the world brighter!',
    grossAmount: 3200, commission: 320, fees: 0, netPayout: 2880,
    status: 'PENDING', receivedAt: daysAgo(0), isExternallyPaid: true,
    items: [
      { productName: 'Spring Garden Arrangement', quantity: 1, unitPrice: 1800 },
      { productName: 'Orchid Phalaenopsis', quantity: 1, unitPrice: 550 },
      { productName: 'Glass Cylinder Vase', quantity: 1, unitPrice: 450 },
      { productName: 'Gift Wrapping', quantity: 4, unitPrice: 100 },
    ],
  },
  {
    id: 'ext_007', externalOrderId: 'BN-20260214-038', platform: 'BLOOMNATION',
    senderName: 'Thomas Wilson',
    recipientName: 'Pooja Desai', recipientPhone: '9988001122',
    deliveryDate: daysFrom(0), deliveryAddress: '77 Deccan Gymkhana, Pune 411004',
    cardMessage: 'Happy Valentine\'s Day, my love!',
    grossAmount: 5800, commission: 580, fees: 0, netPayout: 5220,
    status: 'ACCEPTED', receivedAt: daysAgo(1), isExternallyPaid: true,
    items: [
      { productName: 'Premium Red Roses (50 stems)', quantity: 1, unitPrice: 4200 },
      { productName: 'Preserved Rose Box', quantity: 1, unitPrice: 1200 },
      { productName: 'Satin Ribbon Upgrade', quantity: 1, unitPrice: 400 },
    ],
  },
  {
    id: 'ext_008', externalOrderId: 'BN-20260213-021', platform: 'BLOOMNATION',
    senderName: 'Karen Lee',
    recipientName: 'Rohan Kulkarni', recipientPhone: '8877009988',
    deliveryDate: daysAgo(1), deliveryAddress: '5 Kothrud, Pune 411038',
    cardMessage: 'Wishing you a speedy recovery.',
    grossAmount: 1600, commission: 160, fees: 0, netPayout: 1440,
    status: 'ACCEPTED', receivedAt: daysAgo(3), isExternallyPaid: true,
    items: [
      { productName: 'White Lilies Bouquet', quantity: 1, unitPrice: 1000 },
      { productName: 'Eucalyptus Bunch', quantity: 2, unitPrice: 300 },
    ],
  },
];

// ─── Mock Deliveries ────────────────────────────────────────

export const MOCK_DELIVERIES: DeliveryEntry[] = [
  { orderId: 'ord_002', orderNumber: 'ORD-2026-0002', recipientName: 'Raj Kapoor',      deliveryDate: daysFrom(1), timeSlot: '9:00 AM - 11:00 AM',  address: '45 MG Road, Pune 411001',             assignedDriver: 'Ravi Kumar',   fulfillmentStatus: 'IN_DESIGN',        orderSource: 'PHONE' },
  { orderId: 'ord_003', orderNumber: 'ORD-2026-0003', recipientName: 'Jennifer Smith',   deliveryDate: daysFrom(2), timeSlot: '11:00 AM - 1:00 PM',  address: '12 Palm Drive, Mumbai 400001',         assignedDriver: 'Sameer Das',   fulfillmentStatus: 'CONFIRMED',        orderSource: 'FTD' },
  { orderId: 'ord_004', orderNumber: 'ORD-2026-0004', recipientName: 'Sneha Patil',      deliveryDate: daysFrom(3), timeSlot: '1:00 PM - 3:00 PM',   address: '78 Shivaji Nagar, Pune 411005',        assignedDriver: 'Vikram Singh', fulfillmentStatus: 'READY',            orderSource: 'WEBSITE' },
  { orderId: 'del_001', orderNumber: 'ORD-2026-0006', recipientName: 'Lakshmi Nair',     deliveryDate: daysFrom(0), timeSlot: '9:00 AM - 11:00 AM',  address: '33 Koregaon Park, Pune 411001',        assignedDriver: 'Ravi Kumar',   fulfillmentStatus: 'OUT_FOR_DELIVERY', orderSource: 'WALK_IN' },
  { orderId: 'del_002', orderNumber: 'ORD-2026-0007', recipientName: 'Arjun Mehta',      deliveryDate: daysFrom(0), timeSlot: '3:00 PM - 5:00 PM',   address: '88 Baner Road, Pune 411045',           assignedDriver: 'Amit Thakur',  fulfillmentStatus: 'READY',            orderSource: 'PHONE' },
  { orderId: 'del_003', orderNumber: 'ORD-2026-0008', recipientName: 'Kavita Reddy',     deliveryDate: daysFrom(1), timeSlot: '5:00 PM - 7:00 PM',   address: '22 Jubilee Hills, Hyderabad 500033',   assignedDriver: 'Sameer Das',   fulfillmentStatus: 'CONFIRMED',        orderSource: 'WEBSITE' },
  { orderId: 'del_004', orderNumber: 'ORD-2026-0009', recipientName: 'Sarah Johnson',    deliveryDate: daysFrom(1), timeSlot: '11:00 AM - 1:00 PM',  address: '123 Oak Street, Mumbai 400001',        assignedDriver: 'Ravi Kumar',   fulfillmentStatus: 'CONFIRMED',        orderSource: 'FTD' },
  { orderId: 'del_005', orderNumber: 'ORD-2026-0010', recipientName: 'Suresh Iyer',      deliveryDate: daysFrom(2), timeSlot: '9:00 AM - 11:00 AM',  address: '67 Anna Nagar, Chennai 600040',        assignedDriver: 'Vikram Singh', fulfillmentStatus: 'IN_DESIGN',        orderSource: 'PHONE' },
  { orderId: 'del_006', orderNumber: 'ORD-2026-0011', recipientName: 'Neha Gupta',       deliveryDate: daysFrom(0), timeSlot: '1:00 PM - 3:00 PM',   address: '15 Civil Lines, Delhi 110054',         assignedDriver: 'Amit Thakur',  fulfillmentStatus: 'COMPLETED',        orderSource: 'WALK_IN' },
  { orderId: 'del_007', orderNumber: 'ORD-2026-0012', recipientName: 'Mohammed Ali',     deliveryDate: daysFrom(3), timeSlot: '3:00 PM - 5:00 PM',   address: '44 Residency Road, Bangalore 560025',  assignedDriver: 'Sameer Das',   fulfillmentStatus: 'DRAFT',            orderSource: 'WEBSITE' },
];

// ─── Product Categories for filter ──────────────────────────

export const PRODUCT_CATEGORIES: ProductCategory[] = [
  'Fresh Flowers',
  'Arrangements',
  'Bouquets',
  'Plants',
  'Greens & Foliage',
  'Supplies',
  'Add-Ons',
  'Gift Items',
];
