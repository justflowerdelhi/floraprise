/**
 * Purchase Mock Data
 * Test data for Purchase/GRN module
 * Florist POS + ERP SaaS Platform
 */

import type { Supplier, Product, PurchaseItem, OrderSummary } from './types/purchase.types';

const today = new Date();
const isoDate = (d: Date) => d.toISOString().slice(0, 10);
const daysFrom = (n: number) => {
  const d = new Date(today);
  d.setDate(d.getDate() + n);
  return isoDate(d);
};
const daysAgo = (n: number) => daysFrom(-n);

// ─── Mock Suppliers ─────────────────────────────────────────

export const MOCK_SUPPLIERS: Supplier[] = [
  {
    id: 'sup_001',
    name: 'Holland Direct',
    contactPerson: 'Jan van der Berg',
    email: 'orders@hollanddirect.com',
    phone: '+31 20 555 0123',
    address: 'Aalsmeer Flower Auction, Netherlands',
    defaultPaymentTerms: 'net_30',
    leadTimeDays: 2,
  },
  {
    id: 'sup_002',
    name: 'FlowerFresh Imports',
    contactPerson: 'Maria Rodriguez',
    email: 'sales@flowerfreshimports.com',
    phone: '+1 305 555 0456',
    address: 'Miami, FL, USA',
    defaultPaymentTerms: 'net_15',
    leadTimeDays: 3,
  },
  {
    id: 'sup_003',
    name: 'Local Growers Co-op',
    contactPerson: 'Rajesh Kumar',
    email: 'coop@localgrowers.in',
    phone: '+91 80 555 0789',
    address: 'Hosur Road, Bangalore',
    defaultPaymentTerms: 'cod',
    leadTimeDays: 1,
  },
  {
    id: 'sup_004',
    name: 'GreenLeaf Distributors',
    contactPerson: 'Sunita Patel',
    email: 'orders@greenleaf.in',
    phone: '+91 22 555 0147',
    address: 'APMC Market, Mumbai',
    defaultPaymentTerms: 'net_7',
    leadTimeDays: 2,
  },
  {
    id: 'sup_005',
    name: 'Pacific Blooms',
    contactPerson: 'David Chen',
    email: 'info@pacificblooms.com',
    phone: '+65 6555 0258',
    address: 'Singapore',
    defaultPaymentTerms: 'net_30',
    leadTimeDays: 4,
  },
  {
    id: 'sup_006',
    name: 'Petal Perfect Supplies',
    contactPerson: 'Anita Mehta',
    email: 'supply@petalperfect.in',
    phone: '+91 11 555 0369',
    address: 'Chandni Chowk, Delhi',
    defaultPaymentTerms: 'net_15',
    leadTimeDays: 5,
  },
];

// ─── Mock Products for Purchase ─────────────────────────────

export const MOCK_PURCHASE_PRODUCTS: Product[] = [
  { id: 'prod_001', name: 'Red Roses (Premium)', sku: 'FLW-RR-001', isPerishable: true, defaultShelfLifeDays: 7, defaultUnit: 'stem', lastCost: 2.80, sellingPrice: 5.50, category: 'Fresh Flowers' },
  { id: 'prod_002', name: 'White Lilies', sku: 'FLW-WL-002', isPerishable: true, defaultShelfLifeDays: 10, defaultUnit: 'stem', lastCost: 3.50, sellingPrice: 7.00, category: 'Fresh Flowers' },
  { id: 'prod_003', name: 'Sunflowers', sku: 'FLW-SF-003', isPerishable: true, defaultShelfLifeDays: 7, defaultUnit: 'stem', lastCost: 1.90, sellingPrice: 4.50, category: 'Fresh Flowers' },
  { id: 'prod_004', name: "Baby's Breath", sku: 'FLW-BB-004', isPerishable: true, defaultShelfLifeDays: 10, defaultUnit: 'bunch', lastCost: 0.60, sellingPrice: 1.80, category: 'Fresh Flowers' },
  { id: 'prod_005', name: 'Pink Carnations', sku: 'FLW-PC-005', isPerishable: true, defaultShelfLifeDays: 14, defaultUnit: 'stem', lastCost: 1.20, sellingPrice: 3.00, category: 'Fresh Flowers' },
  { id: 'prod_006', name: 'Orchids (Phalaenopsis)', sku: 'FLW-OR-006', isPerishable: true, defaultShelfLifeDays: 21, defaultUnit: 'stem', lastCost: 8.50, sellingPrice: 18.00, category: 'Fresh Flowers' },
  { id: 'prod_007', name: 'Eucalyptus Bunches', sku: 'GRN-EU-007', isPerishable: true, defaultShelfLifeDays: 14, defaultUnit: 'bunch', lastCost: 2.10, sellingPrice: 5.00, category: 'Greens & Foliage' },
  { id: 'prod_008', name: 'Tulips (Mixed)', sku: 'FLW-TL-008', isPerishable: true, defaultShelfLifeDays: 7, defaultUnit: 'stem', lastCost: 2.40, sellingPrice: 5.50, category: 'Fresh Flowers' },
  { id: 'prod_009', name: 'Floral Foam Blocks', sku: 'SUP-FF-009', isPerishable: false, defaultUnit: 'piece', lastCost: 0.45, sellingPrice: 1.20, category: 'Supplies' },
  { id: 'prod_010', name: 'Glass Cylinder Vases', sku: 'VAS-GC-010', isPerishable: false, defaultUnit: 'piece', lastCost: 4.50, sellingPrice: 12.00, category: 'Vases & Containers' },
  { id: 'prod_011', name: 'Satin Ribbon Roll', sku: 'SUP-SR-011', isPerishable: false, defaultUnit: 'roll', lastCost: 1.10, sellingPrice: 3.00, category: 'Supplies' },
  { id: 'prod_012', name: 'Peonies', sku: 'FLW-PN-012', isPerishable: true, defaultShelfLifeDays: 7, defaultUnit: 'stem', lastCost: 5.50, sellingPrice: 12.00, category: 'Fresh Flowers' },
  { id: 'prod_013', name: 'Hydrangeas (Blue)', sku: 'FLW-HY-013', isPerishable: true, defaultShelfLifeDays: 7, defaultUnit: 'stem', lastCost: 4.20, sellingPrice: 9.00, category: 'Fresh Flowers' },
  { id: 'prod_014', name: 'Ruscus (Italian)', sku: 'GRN-RS-014', isPerishable: true, defaultShelfLifeDays: 21, defaultUnit: 'bunch', lastCost: 1.40, sellingPrice: 3.50, category: 'Greens & Foliage' },
  { id: 'prod_015', name: 'Spray Roses (Peach)', sku: 'FLW-SR-015', isPerishable: true, defaultShelfLifeDays: 7, defaultUnit: 'stem', lastCost: 2.20, sellingPrice: 5.00, category: 'Fresh Flowers' },
];

// ─── Mock Purchase Orders ───────────────────────────────────

export type PurchaseStatus = 'DRAFT' | 'SUBMITTED' | 'APPROVED' | 'RECEIVED' | 'PARTIALLY_RECEIVED' | 'CANCELLED';

export interface PurchaseOrder {
  id: string;
  poNumber: string;
  supplierId: string;
  supplierName: string;
  invoiceNumber?: string;
  purchaseDate: string;
  expectedDeliveryDate: string;
  actualDeliveryDate?: string;
  paymentTerms: string;
  location: string;
  status: PurchaseStatus;
  items: PurchaseItem[];
  subtotal: number;
  taxRate: number;
  taxAmount: number;
  shippingCost: number;
  grandTotal: number;
  notes?: string;
  createdBy: string;
  createdAt: string;
  updatedAt: string;
}

let itemSeq = 0;
const mkItem = (
  productId: string,
  productName: string,
  sku: string,
  isPerishable: boolean,
  qty: number,
  cost: number,
  sellPrice: number,
  shelfDays: number,
  purchaseDate: string,
  storage: string,
): PurchaseItem => {
  const total = qty * cost;
  const margin = sellPrice > 0 ? ((sellPrice - cost) / sellPrice) * 100 : 0;
  const expiryDate = isPerishable ? daysFrom(shelfDays) : '';
  return {
    id: `item_${String(++itemSeq).padStart(4, '0')}`,
    productId,
    productName,
    sku,
    isPerishable,
    unit: 'stem',
    quantity: qty,
    costPerUnit: cost,
    total,
    batchNumber: isPerishable ? `BT-2026-${String(itemSeq).padStart(4, '0')}` : '',
    purchaseDate,
    shelfLifeDays: shelfDays,
    expiryDate,
    storageLocation: storage,
    sellingPrice: sellPrice,
    marginPercent: Math.round(margin * 10) / 10,
    marginAmount: Math.round((sellPrice - cost) * qty * 100) / 100,
  };
};

export const MOCK_PURCHASE_ORDERS: PurchaseOrder[] = [
  {
    id: 'po_001',
    poNumber: 'PO-2026-0001',
    supplierId: 'sup_001',
    supplierName: 'Holland Direct',
    invoiceNumber: 'HD-INV-98765',
    purchaseDate: daysAgo(2),
    expectedDeliveryDate: daysAgo(0),
    actualDeliveryDate: daysAgo(0),
    paymentTerms: 'net_30',
    location: 'Main Store',
    status: 'RECEIVED',
    items: [
      mkItem('prod_001', 'Red Roses (Premium)', 'FLW-RR-001', true, 200, 2.80, 5.50, 7, daysAgo(0), 'cold_room_a'),
      mkItem('prod_004', "Baby's Breath", 'FLW-BB-004', true, 300, 0.60, 1.80, 10, daysAgo(0), 'cold_room_b'),
      mkItem('prod_008', 'Tulips (Mixed)', 'FLW-TL-008', true, 100, 2.40, 5.50, 7, daysAgo(0), 'cold_room_a'),
    ],
    subtotal: 1000,
    taxRate: 5,
    taxAmount: 50,
    shippingCost: 150,
    grandTotal: 1200,
    notes: 'Weekly flower shipment from Holland',
    createdBy: 'Anita Sharma',
    createdAt: daysAgo(5),
    updatedAt: daysAgo(0),
  },
  {
    id: 'po_002',
    poNumber: 'PO-2026-0002',
    supplierId: 'sup_002',
    supplierName: 'FlowerFresh Imports',
    invoiceNumber: 'FFI-45678',
    purchaseDate: daysAgo(3),
    expectedDeliveryDate: daysAgo(0),
    paymentTerms: 'net_15',
    location: 'Main Store',
    status: 'APPROVED',
    items: [
      mkItem('prod_002', 'White Lilies', 'FLW-WL-002', true, 120, 3.50, 7.00, 10, daysAgo(0), 'cold_room_a'),
      mkItem('prod_006', 'Orchids (Phalaenopsis)', 'FLW-OR-006', true, 40, 8.50, 18.00, 21, daysAgo(0), 'display_cooler'),
    ],
    subtotal: 760,
    taxRate: 5,
    taxAmount: 38,
    shippingCost: 200,
    grandTotal: 998,
    createdBy: 'Ravi Kumar',
    createdAt: daysAgo(5),
    updatedAt: daysAgo(3),
  },
  {
    id: 'po_003',
    poNumber: 'PO-2026-0003',
    supplierId: 'sup_003',
    supplierName: 'Local Growers Co-op',
    purchaseDate: daysAgo(1),
    expectedDeliveryDate: daysFrom(0),
    paymentTerms: 'cod',
    location: 'Main Store',
    status: 'SUBMITTED',
    items: [
      mkItem('prod_003', 'Sunflowers', 'FLW-SF-003', true, 80, 1.90, 4.50, 7, daysFrom(0), 'display_cooler'),
      mkItem('prod_005', 'Pink Carnations', 'FLW-PC-005', true, 150, 1.20, 3.00, 14, daysFrom(0), 'cold_room_a'),
    ],
    subtotal: 332,
    taxRate: 0,
    taxAmount: 0,
    shippingCost: 50,
    grandTotal: 382,
    notes: 'Local delivery - COD payment',
    createdBy: 'Priya Patel',
    createdAt: daysAgo(1),
    updatedAt: daysAgo(1),
  },
  {
    id: 'po_004',
    poNumber: 'PO-2026-0004',
    supplierId: 'sup_004',
    supplierName: 'GreenLeaf Distributors',
    purchaseDate: daysAgo(0),
    expectedDeliveryDate: daysFrom(2),
    paymentTerms: 'net_7',
    location: 'Main Store',
    status: 'DRAFT',
    items: [
      mkItem('prod_007', 'Eucalyptus Bunches', 'GRN-EU-007', true, 100, 2.10, 5.00, 14, daysFrom(2), 'cold_room_b'),
      mkItem('prod_014', 'Ruscus (Italian)', 'GRN-RS-014', true, 80, 1.40, 3.50, 21, daysFrom(2), 'cold_room_b'),
    ],
    subtotal: 322,
    taxRate: 5,
    taxAmount: 16.10,
    shippingCost: 75,
    grandTotal: 413.10,
    createdBy: 'Sameer Das',
    createdAt: daysAgo(0),
    updatedAt: daysAgo(0),
  },
  {
    id: 'po_005',
    poNumber: 'PO-2026-0005',
    supplierId: 'sup_006',
    supplierName: 'Petal Perfect Supplies',
    invoiceNumber: 'PPS-2026-1234',
    purchaseDate: daysAgo(10),
    expectedDeliveryDate: daysAgo(5),
    actualDeliveryDate: daysAgo(5),
    paymentTerms: 'net_15',
    location: 'Main Store',
    status: 'RECEIVED',
    items: [
      mkItem('prod_009', 'Floral Foam Blocks', 'SUP-FF-009', false, 500, 0.45, 1.20, 0, daysAgo(5), 'dry_storage'),
      mkItem('prod_010', 'Glass Cylinder Vases', 'VAS-GC-010', false, 50, 4.50, 12.00, 0, daysAgo(5), 'dry_storage'),
      mkItem('prod_011', 'Satin Ribbon Roll', 'SUP-SR-011', false, 30, 1.10, 3.00, 0, daysAgo(5), 'dry_storage'),
    ],
    subtotal: 483,
    taxRate: 18,
    taxAmount: 86.94,
    shippingCost: 100,
    grandTotal: 669.94,
    notes: 'Monthly supplies order',
    createdBy: 'Neha Gupta',
    createdAt: daysAgo(12),
    updatedAt: daysAgo(5),
  },
  {
    id: 'po_006',
    poNumber: 'PO-2026-0006',
    supplierId: 'sup_005',
    supplierName: 'Pacific Blooms',
    purchaseDate: daysAgo(7),
    expectedDeliveryDate: daysAgo(3),
    actualDeliveryDate: daysAgo(2),
    paymentTerms: 'net_30',
    location: 'Main Store',
    status: 'PARTIALLY_RECEIVED',
    items: [
      mkItem('prod_012', 'Peonies', 'FLW-PN-012', true, 60, 5.50, 12.00, 7, daysAgo(2), 'cold_room_a'),
      mkItem('prod_013', 'Hydrangeas (Blue)', 'FLW-HY-013', true, 50, 4.20, 9.00, 7, daysAgo(2), 'cold_room_b'),
      mkItem('prod_015', 'Spray Roses (Peach)', 'FLW-SR-015', true, 120, 2.20, 5.00, 7, daysAgo(2), 'cold_room_a'),
    ],
    subtotal: 804,
    taxRate: 5,
    taxAmount: 40.20,
    shippingCost: 250,
    grandTotal: 1094.20,
    notes: 'Partial delivery - Spray roses delayed',
    createdBy: 'Vikram Singh',
    createdAt: daysAgo(10),
    updatedAt: daysAgo(2),
  },
];

// ─── Purchase Summary Stats ─────────────────────────────────

export interface PurchaseSummary {
  totalOrders: number;
  draftOrders: number;
  pendingDelivery: number;
  receivedThisMonth: number;
  totalValueThisMonth: number;
  outstandingPayables: number;
  avgLeadTime: number;
}

export const MOCK_PURCHASE_SUMMARY: PurchaseSummary = {
  totalOrders: MOCK_PURCHASE_ORDERS.length,
  draftOrders: MOCK_PURCHASE_ORDERS.filter(po => po.status === 'DRAFT').length,
  pendingDelivery: MOCK_PURCHASE_ORDERS.filter(po => ['SUBMITTED', 'APPROVED'].includes(po.status)).length,
  receivedThisMonth: MOCK_PURCHASE_ORDERS.filter(po => po.status === 'RECEIVED').length,
  totalValueThisMonth: MOCK_PURCHASE_ORDERS.filter(po => po.status === 'RECEIVED').reduce((sum, po) => sum + po.grandTotal, 0),
  outstandingPayables: MOCK_PURCHASE_ORDERS.filter(po => po.status === 'RECEIVED' && po.paymentTerms !== 'cod').reduce((sum, po) => sum + po.grandTotal, 0),
  avgLeadTime: 2.5,
};

// ─── Mock API Functions ─────────────────────────────────────

export const fetchSuppliers = (): Promise<Supplier[]> =>
  new Promise(resolve => setTimeout(() => resolve([...MOCK_SUPPLIERS]), 400));

export const fetchPurchaseProducts = (): Promise<Product[]> =>
  new Promise(resolve => setTimeout(() => resolve([...MOCK_PURCHASE_PRODUCTS]), 400));

export const fetchPurchaseOrders = (): Promise<PurchaseOrder[]> =>
  new Promise(resolve => setTimeout(() => resolve([...MOCK_PURCHASE_ORDERS]), 500));

export const fetchPurchaseOrderById = (id: string): Promise<PurchaseOrder | null> =>
  new Promise(resolve => setTimeout(() => {
    const po = MOCK_PURCHASE_ORDERS.find(p => p.id === id);
    resolve(po || null);
  }, 300));

export const fetchPurchaseSummary = (): Promise<PurchaseSummary> =>
  new Promise(resolve => setTimeout(() => resolve(MOCK_PURCHASE_SUMMARY), 300));
