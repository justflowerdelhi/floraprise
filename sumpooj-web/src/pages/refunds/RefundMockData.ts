/**
 * Refunds Mock Data
 * Test data for Refund processing module
 * Florist POS + ERP SaaS Platform
 */

import type { RefundStatus, RefundMethod, RefundItem, RefundEntry } from './RefundTypes';

const today = new Date();
const isoDateTime = (d: Date) => d.toISOString();
const daysAgo = (n: number, hours = 12) => {
  const d = new Date(today);
  d.setDate(d.getDate() - n);
  d.setHours(hours, 0, 0, 0);
  return isoDateTime(d);
};

// ─── Mock Refund Items ──────────────────────────────────────

const createRefundItems = (items: Array<{
  lineItemId: string;
  productId: string;
  productName: string;
  sku: string;
  maxRefundableQty: number;
  quantity: number;
  unitPrice: number;
  isRestockable: boolean;
  restock: boolean;
}>): RefundItem[] => items.map(item => ({
  lineItemId: item.lineItemId,
  productId: item.productId,
  productName: item.productName,
  sku: item.sku,
  maxRefundableQty: item.maxRefundableQty,
  quantity: item.quantity,
  unitPrice: item.unitPrice,
  refundAmount: item.quantity * item.unitPrice,
  isRestockable: item.isRestockable,
  restock: item.restock,
}));

// ─── Mock Refund Entries ────────────────────────────────────

export const MOCK_REFUND_ENTRIES: RefundEntry[] = [
  {
    refundId: 'ref_2026_0301_0001',
    refundedAmount: 1200,
    items: createRefundItems([
      { lineItemId: 'li_001', productId: 'prod_001', productName: 'Red Rose Bouquet', sku: 'FL-ROSE-RED-12', maxRefundableQty: 1, quantity: 1, unitPrice: 1200, isRestockable: false, restock: false },
    ]),
    method: 'ORIGINAL',
    reason: 'Flowers arrived wilted due to delayed delivery',
    createdAt: daysAgo(2, 14),
    processedBy: 'user_001',
    processedByName: 'Amit Kumar',
    status: 'PROCESSED',
  },
  {
    refundId: 'ref_2026_0296_0002',
    refundedAmount: 1750,
    items: createRefundItems([
      { lineItemId: 'li_010', productId: 'prod_005', productName: 'Decorative Vase - Blue', sku: 'ACC-VASE-BLU-M', maxRefundableQty: 1, quantity: 1, unitPrice: 850, isRestockable: true, restock: true },
      { lineItemId: 'li_011', productId: 'prod_006', productName: 'Dried Flower Set', sku: 'FL-DRY-SET-01', maxRefundableQty: 3, quantity: 2, unitPrice: 450, isRestockable: true, restock: true },
    ]),
    method: 'STORE_CREDIT',
    reason: 'Customer changed mind, items returned in original condition',
    createdAt: daysAgo(5, 16),
    processedBy: 'user_002',
    processedByName: 'Sneha Patel',
    status: 'PROCESSED',
  },
  {
    refundId: 'ref_2026_0302_0003',
    refundedAmount: 1300,
    items: createRefundItems([
      { lineItemId: 'li_020', productId: 'prod_010', productName: 'Mixed Tulips - Yellow', sku: 'FL-TULIP-YEL-10', maxRefundableQty: 5, quantity: 2, unitPrice: 650, isRestockable: false, restock: false },
    ]),
    method: 'ORIGINAL',
    reason: 'Customer ordered Pink Tulips but received Yellow - wrong item sent',
    createdAt: daysAgo(1, 11),
    processedBy: 'user_003',
    processedByName: 'Ravi Sharma',
    status: 'PENDING',
  },
  {
    refundId: 'ref_2026_0293_0004',
    refundedAmount: 2500,
    items: createRefundItems([
      { lineItemId: 'li_030', productId: 'prod_012', productName: 'Orchid Plant - White', sku: 'PL-ORCH-WHT-01', maxRefundableQty: 1, quantity: 1, unitPrice: 2500, isRestockable: false, restock: false },
    ]),
    method: 'ORIGINAL',
    reason: 'Plant had root rot upon delivery - quality issue',
    createdAt: daysAgo(8, 13),
    processedBy: 'user_001',
    processedByName: 'Amit Kumar',
    status: 'PROCESSED',
  },
  {
    refundId: 'ref_2026_0289_0005',
    refundedAmount: 540,
    items: createRefundItems([
      { lineItemId: 'li_040', productId: 'prod_015', productName: 'Lily Stems - White', sku: 'FL-LILY-WHT-05', maxRefundableQty: 5, quantity: 3, unitPrice: 180, isRestockable: false, restock: false },
    ]),
    method: 'ORIGINAL',
    reason: '3 lily stems were missing from the order - partial delivery',
    createdAt: daysAgo(12, 17),
    processedBy: 'user_002',
    processedByName: 'Sneha Patel',
    status: 'PROCESSED',
  },
  {
    refundId: 'ref_2026_0286_0006',
    refundedAmount: 4500,
    items: createRefundItems([
      { lineItemId: 'li_050', productId: 'prod_020', productName: 'Wedding Centerpiece - Premium', sku: 'ARR-WED-PREM-01', maxRefundableQty: 1, quantity: 1, unitPrice: 4500, isRestockable: false, restock: false },
    ]),
    method: 'ORIGINAL',
    reason: 'Customer requested return - 10 days after delivery, outside return window',
    createdAt: daysAgo(15, 10),
    processedBy: 'user_003',
    processedByName: 'Ravi Sharma',
    status: 'FAILED',
  },
  {
    refundId: 'ref_2026_0303_0007',
    refundedAmount: 1800,
    items: createRefundItems([
      { lineItemId: 'li_060', productId: 'prod_025', productName: 'Glass Terrarium - Large', sku: 'ACC-TERR-LRG-01', maxRefundableQty: 1, quantity: 1, unitPrice: 1800, isRestockable: false, restock: false },
    ]),
    method: 'ORIGINAL',
    reason: 'Terrarium arrived with crack in glass - damaged in transit',
    createdAt: daysAgo(0, 9),
    processedBy: 'user_001',
    processedByName: 'Amit Kumar',
    status: 'PENDING',
  },
];

// ─── Order-Refund Mapping (for displaying refunds per order) ───

export interface OrderRefundRecord {
  orderId: string;
  orderNumber: string;
  customerName: string;
  customerPhone: string;
  orderTotal: number;
  totalRefunded: number;
  refunds: RefundEntry[];
}

export const MOCK_ORDER_REFUNDS: OrderRefundRecord[] = [
  {
    orderId: 'ord_189',
    orderNumber: 'ORD-2026-0189',
    customerName: 'Priya Sharma',
    customerPhone: '+91 98765 43210',
    orderTotal: 4500,
    totalRefunded: 1200,
    refunds: [MOCK_REFUND_ENTRIES[0]],
  },
  {
    orderId: 'ord_175',
    orderNumber: 'ORD-2026-0175',
    customerName: 'Rahul Verma',
    customerPhone: '+91 87654 32109',
    orderTotal: 5200,
    totalRefunded: 1750,
    refunds: [MOCK_REFUND_ENTRIES[1]],
  },
  {
    orderId: 'ord_168',
    orderNumber: 'ORD-2026-0168',
    customerName: 'Anita Desai',
    customerPhone: '+91 76543 21098',
    orderTotal: 3200,
    totalRefunded: 0,
    refunds: [MOCK_REFUND_ENTRIES[2]],
  },
  {
    orderId: 'ord_155',
    orderNumber: 'ORD-2026-0155',
    customerName: 'Vikram Singh',
    customerPhone: '+91 65432 10987',
    orderTotal: 6800,
    totalRefunded: 2500,
    refunds: [MOCK_REFUND_ENTRIES[3]],
  },
  {
    orderId: 'ord_142',
    orderNumber: 'ORD-2026-0142',
    customerName: 'Priya Sharma',
    customerPhone: '+91 98765 43210',
    orderTotal: 3800,
    totalRefunded: 540,
    refunds: [MOCK_REFUND_ENTRIES[4]],
  },
  {
    orderId: 'ord_130',
    orderNumber: 'ORD-2026-0130',
    customerName: 'Meera Kapoor',
    customerPhone: '+91 54321 09876',
    orderTotal: 8500,
    totalRefunded: 0,
    refunds: [MOCK_REFUND_ENTRIES[5]],
  },
  {
    orderId: 'ord_195',
    orderNumber: 'ORD-2026-0195',
    customerName: 'Anita Desai',
    customerPhone: '+91 76543 21098',
    orderTotal: 4200,
    totalRefunded: 0,
    refunds: [MOCK_REFUND_ENTRIES[6]],
  },
];

// ─── Refund Summary Stats ───────────────────────────────────

export interface RefundSummary {
  total: number;
  processed: number;
  pending: number;
  failed: number;
  totalRefunded: number;
  avgRefundAmount: number;
  byMethod: Record<RefundMethod, number>;
}

export const calculateRefundSummary = (refunds: RefundEntry[]): RefundSummary => {
  const processed = refunds.filter(r => r.status === 'PROCESSED');
  const pending = refunds.filter(r => r.status === 'PENDING');
  const failed = refunds.filter(r => r.status === 'FAILED');

  const totalRefunded = processed.reduce((sum, r) => sum + r.refundedAmount, 0);
  const avgRefundAmount = processed.length > 0 ? totalRefunded / processed.length : 0;

  const byMethod = processed.reduce((acc, r) => {
    acc[r.method] = (acc[r.method] || 0) + r.refundedAmount;
    return acc;
  }, { ORIGINAL: 0, STORE_CREDIT: 0 } as Record<RefundMethod, number>);

  return {
    total: refunds.length,
    processed: processed.length,
    pending: pending.length,
    failed: failed.length,
    totalRefunded,
    avgRefundAmount,
    byMethod,
  };
};

export const MOCK_REFUND_SUMMARY = calculateRefundSummary(MOCK_REFUND_ENTRIES);

// ─── Period Statistics ──────────────────────────────────────

export interface RefundPeriodStats {
  period: string;
  count: number;
  totalAmount: number;
  avgProcessingTime: number;
  topReason: string;
}

export const MOCK_REFUND_MONTHLY_STATS: RefundPeriodStats[] = [
  { period: '2026-03', count: 7, totalAmount: 12540, avgProcessingTime: 4.2, topReason: 'Damaged in transit' },
  { period: '2026-02', count: 12, totalAmount: 18750, avgProcessingTime: 3.8, topReason: 'Customer request' },
  { period: '2026-01', count: 9, totalAmount: 14200, avgProcessingTime: 5.1, topReason: 'Quality issue' },
  { period: '2025-12', count: 15, totalAmount: 28500, avgProcessingTime: 6.2, topReason: 'Wrong item sent' },
  { period: '2025-11', count: 8, totalAmount: 11800, avgProcessingTime: 3.5, topReason: 'Damaged in transit' },
  { period: '2025-10', count: 6, totalAmount: 9200, avgProcessingTime: 4.0, topReason: 'Customer request' },
];

// ─── Mock API Functions ─────────────────────────────────────

export const fetchRefundEntries = (filters?: {
  status?: RefundStatus;
  method?: RefundMethod;
  dateFrom?: string;
  dateTo?: string;
}): Promise<RefundEntry[]> =>
  new Promise(resolve => setTimeout(() => {
    let results = [...MOCK_REFUND_ENTRIES];
    if (filters?.status) results = results.filter(r => r.status === filters.status);
    if (filters?.method) results = results.filter(r => r.method === filters.method);
    if (filters?.dateFrom) results = results.filter(r => r.createdAt >= filters.dateFrom!);
    if (filters?.dateTo) results = results.filter(r => r.createdAt <= filters.dateTo!);
    resolve(results);
  }, 500));

export const fetchRefundById = (refundId: string): Promise<RefundEntry | null> =>
  new Promise(resolve => setTimeout(() => {
    resolve(MOCK_REFUND_ENTRIES.find(r => r.refundId === refundId) || null);
  }, 300));

export const fetchOrderRefunds = (orderId: string): Promise<OrderRefundRecord | null> =>
  new Promise(resolve => setTimeout(() => {
    resolve(MOCK_ORDER_REFUNDS.find(r => r.orderId === orderId) || null);
  }, 300));

export const fetchRefundSummary = (): Promise<RefundSummary> =>
  new Promise(resolve => setTimeout(() => resolve(MOCK_REFUND_SUMMARY), 300));

export const fetchRefundStats = (): Promise<RefundPeriodStats[]> =>
  new Promise(resolve => setTimeout(() => resolve([...MOCK_REFUND_MONTHLY_STATS]), 400));
