/**
 * Payment Mock Data
 * Test data for Payment processing module
 * Florist POS + ERP SaaS Platform
 */

import type { Payment, PaymentMethod, PaymentStatus } from './PaymentTypes';

const today = new Date();
const isoDate = (d: Date) => d.toISOString();
const daysAgo = (n: number, hours = 12) => {
  const d = new Date(today);
  d.setDate(d.getDate() - n);
  d.setHours(hours, 0, 0, 0);
  return isoDate(d);
};

// ─── Mock Payments ──────────────────────────────────────────

export const MOCK_PAYMENTS: Payment[] = [
  // Today's payments
  {
    id: 'pay_001',
    orderId: 'ord_201',
    locationId: 'loc_main',
    method: 'CARD',
    amount: 4500,
    status: 'APPROVED',
    transactionId: 'TXN-2026030901',
    authorizationCode: 'AUTH-5421',
    cardBrand: 'Visa',
    last4: '4532',
    terminalResponse: {
      terminalId: 'TERM-001',
      responseCode: '00',
      message: 'Transaction approved',
      timestamp: daysAgo(0, 14),
      receiptData: 'Visa ****4532\nApproved',
    },
    createdAt: daysAgo(0, 14),
  },
  {
    id: 'pay_002',
    orderId: 'ord_200',
    locationId: 'loc_main',
    method: 'CASH',
    amount: 2800,
    status: 'APPROVED',
    createdAt: daysAgo(0, 11),
  },
  {
    id: 'pay_003',
    orderId: 'ord_199',
    locationId: 'loc_main',
    method: 'UPI',
    amount: 3500,
    status: 'APPROVED',
    transactionId: 'UPI-2026030903',
    createdAt: daysAgo(0, 10),
  },
  {
    id: 'pay_004',
    orderId: 'ord_198',
    locationId: 'loc_branch1',
    method: 'GIFT_CARD',
    amount: 1500,
    status: 'APPROVED',
    transactionId: 'GC-FLORA-2026-001',
    createdAt: daysAgo(0, 9),
  },
  // Yesterday's payments
  {
    id: 'pay_005',
    orderId: 'ord_195',
    locationId: 'loc_main',
    method: 'CARD',
    amount: 6200,
    status: 'APPROVED',
    transactionId: 'TXN-2026030805',
    authorizationCode: 'AUTH-7832',
    cardBrand: 'Mastercard',
    last4: '8821',
    terminalResponse: {
      terminalId: 'TERM-001',
      responseCode: '00',
      message: 'Transaction approved',
      timestamp: daysAgo(1, 16),
    },
    createdAt: daysAgo(1, 16),
  },
  {
    id: 'pay_006',
    orderId: 'ord_194',
    locationId: 'loc_main',
    method: 'CASH',
    amount: 1800,
    status: 'APPROVED',
    createdAt: daysAgo(1, 14),
  },
  {
    id: 'pay_007',
    orderId: 'ord_193',
    locationId: 'loc_branch1',
    method: 'UPI',
    amount: 4200,
    status: 'APPROVED',
    transactionId: 'UPI-2026030807',
    createdAt: daysAgo(1, 12),
  },
  {
    id: 'pay_008',
    orderId: 'ord_192',
    locationId: 'loc_main',
    method: 'CARD',
    amount: 8500,
    status: 'APPROVED',
    transactionId: 'TXN-2026030808',
    authorizationCode: 'AUTH-9012',
    cardBrand: 'Visa',
    last4: '1234',
    createdAt: daysAgo(1, 10),
  },
  // 2 days ago
  {
    id: 'pay_009',
    orderId: 'ord_189',
    locationId: 'loc_main',
    method: 'BANK_TRANSFER',
    amount: 25000,
    status: 'APPROVED',
    transactionId: 'NEFT-2026030709',
    createdAt: daysAgo(2, 11),
  },
  {
    id: 'pay_010',
    orderId: 'ord_188',
    locationId: 'loc_main',
    method: 'CARD',
    amount: 3200,
    status: 'DECLINED',
    transactionId: 'TXN-2026030710',
    terminalResponse: {
      terminalId: 'TERM-001',
      responseCode: '51',
      message: 'Insufficient funds',
      timestamp: daysAgo(2, 15),
    },
    createdAt: daysAgo(2, 15),
  },
  {
    id: 'pay_011',
    orderId: 'ord_188',
    locationId: 'loc_main',
    method: 'CASH',
    amount: 3200,
    status: 'APPROVED',
    createdAt: daysAgo(2, 15),
  },
  // 3 days ago
  {
    id: 'pay_012',
    orderId: 'ord_185',
    locationId: 'loc_main',
    method: 'CARD',
    amount: 8200,
    status: 'APPROVED',
    transactionId: 'TXN-2026030612',
    authorizationCode: 'AUTH-3456',
    cardBrand: 'RuPay',
    last4: '5678',
    createdAt: daysAgo(3, 14),
  },
  {
    id: 'pay_013',
    orderId: 'ord_184',
    locationId: 'loc_branch1',
    method: 'EXTERNAL_TERMINAL',
    amount: 5500,
    status: 'APPROVED',
    transactionId: 'EXT-2026030613',
    createdAt: daysAgo(3, 12),
  },
  {
    id: 'pay_014',
    orderId: 'ord_183',
    locationId: 'loc_main',
    method: 'UPI',
    amount: 2200,
    status: 'APPROVED',
    transactionId: 'UPI-2026030614',
    createdAt: daysAgo(3, 10),
  },
  // Week ago - mix
  {
    id: 'pay_015',
    orderId: 'ord_175',
    locationId: 'loc_main',
    method: 'CARD',
    amount: 12500,
    status: 'APPROVED',
    transactionId: 'TXN-2026022815',
    authorizationCode: 'AUTH-6789',
    cardBrand: 'Visa',
    last4: '9012',
    createdAt: daysAgo(7, 16),
  },
  {
    id: 'pay_016',
    orderId: 'ord_174',
    locationId: 'loc_main',
    method: 'GIFT_CARD',
    amount: 2000,
    status: 'APPROVED',
    transactionId: 'GC-FLORA-2025-089',
    createdAt: daysAgo(7, 14),
  },
  {
    id: 'pay_017',
    orderId: 'ord_173',
    locationId: 'loc_branch1',
    method: 'CASH',
    amount: 4800,
    status: 'APPROVED',
    createdAt: daysAgo(7, 11),
  },
  // Voided / Refunded examples
  {
    id: 'pay_018',
    orderId: 'ord_168',
    locationId: 'loc_main',
    method: 'CARD',
    amount: 3800,
    status: 'VOIDED',
    transactionId: 'TXN-2026022518',
    authorizationCode: 'AUTH-1111',
    cardBrand: 'Mastercard',
    last4: '3333',
    createdAt: daysAgo(10, 15),
  },
  {
    id: 'pay_019',
    orderId: 'ord_155',
    locationId: 'loc_main',
    method: 'UPI',
    amount: 2500,
    status: 'REFUNDED',
    transactionId: 'UPI-2026022019',
    createdAt: daysAgo(15, 12),
  },
  // Pending payment
  {
    id: 'pay_020',
    orderId: 'ord_202',
    locationId: 'loc_main',
    method: 'BANK_TRANSFER',
    amount: 45000,
    status: 'PENDING',
    createdAt: daysAgo(0, 9),
  },
];

// ─── Payment Summary by Method ──────────────────────────────

export interface PaymentMethodSummary {
  method: PaymentMethod;
  count: number;
  totalAmount: number;
  percentage: number;
}

export const calculatePaymentMethodSummary = (payments: Payment[]): PaymentMethodSummary[] => {
  const approved = payments.filter(p => p.status === 'APPROVED');
  const total = approved.reduce((sum, p) => sum + p.amount, 0);
  
  const byMethod = approved.reduce((acc, p) => {
    if (!acc[p.method]) {
      acc[p.method] = { count: 0, amount: 0 };
    }
    acc[p.method].count++;
    acc[p.method].amount += p.amount;
    return acc;
  }, {} as Record<PaymentMethod, { count: number; amount: number }>);

  return Object.entries(byMethod).map(([method, data]) => ({
    method: method as PaymentMethod,
    count: data.count,
    totalAmount: data.amount,
    percentage: total > 0 ? (data.amount / total) * 100 : 0,
  })).sort((a, b) => b.totalAmount - a.totalAmount);
};

// ─── Daily Payment Summary ──────────────────────────────────

export interface DailyPaymentSummary {
  date: string;
  totalTransactions: number;
  totalAmount: number;
  byMethod: Record<PaymentMethod, number>;
  approvedCount: number;
  declinedCount: number;
}

export const MOCK_DAILY_PAYMENT_SUMMARIES: DailyPaymentSummary[] = [
  {
    date: daysAgo(0).slice(0, 10),
    totalTransactions: 12,
    totalAmount: 45200,
    byMethod: { CASH: 8500, CARD: 22000, UPI: 8200, GIFT_CARD: 3500, BANK_TRANSFER: 3000, EXTERNAL_TERMINAL: 0 },
    approvedCount: 11,
    declinedCount: 1,
  },
  {
    date: daysAgo(1).slice(0, 10),
    totalTransactions: 15,
    totalAmount: 52800,
    byMethod: { CASH: 12500, CARD: 24800, UPI: 9500, GIFT_CARD: 2000, BANK_TRANSFER: 4000, EXTERNAL_TERMINAL: 0 },
    approvedCount: 15,
    declinedCount: 0,
  },
  {
    date: daysAgo(2).slice(0, 10),
    totalTransactions: 10,
    totalAmount: 38500,
    byMethod: { CASH: 9200, CARD: 18500, UPI: 5800, GIFT_CARD: 0, BANK_TRANSFER: 5000, EXTERNAL_TERMINAL: 0 },
    approvedCount: 9,
    declinedCount: 1,
  },
  {
    date: daysAgo(3).slice(0, 10),
    totalTransactions: 18,
    totalAmount: 62400,
    byMethod: { CASH: 15800, CARD: 28500, UPI: 12100, GIFT_CARD: 1500, BANK_TRANSFER: 0, EXTERNAL_TERMINAL: 4500 },
    approvedCount: 18,
    declinedCount: 0,
  },
  {
    date: daysAgo(4).slice(0, 10),
    totalTransactions: 14,
    totalAmount: 48200,
    byMethod: { CASH: 11200, CARD: 22500, UPI: 8500, GIFT_CARD: 2500, BANK_TRANSFER: 3500, EXTERNAL_TERMINAL: 0 },
    approvedCount: 13,
    declinedCount: 1,
  },
  {
    date: daysAgo(5).slice(0, 10),
    totalTransactions: 16,
    totalAmount: 55800,
    byMethod: { CASH: 14500, CARD: 26800, UPI: 9500, GIFT_CARD: 1800, BANK_TRANSFER: 3200, EXTERNAL_TERMINAL: 0 },
    approvedCount: 16,
    declinedCount: 0,
  },
  {
    date: daysAgo(6).slice(0, 10),
    totalTransactions: 20,
    totalAmount: 68500,
    byMethod: { CASH: 18200, CARD: 32500, UPI: 11800, GIFT_CARD: 2500, BANK_TRANSFER: 0, EXTERNAL_TERMINAL: 3500 },
    approvedCount: 19,
    declinedCount: 1,
  },
];

// ─── Payment Statistics ─────────────────────────────────────

export interface PaymentStats {
  totalTransactions: number;
  totalAmount: number;
  approvedAmount: number;
  declinedAmount: number;
  avgTransactionValue: number;
  cardPaymentPercentage: number;
  cashPaymentPercentage: number;
  digitalPaymentPercentage: number;
}

export const calculatePaymentStats = (payments: Payment[]): PaymentStats => {
  const approved = payments.filter(p => p.status === 'APPROVED');
  const declined = payments.filter(p => p.status === 'DECLINED');
  
  const totalAmount = approved.reduce((sum, p) => sum + p.amount, 0);
  const cardAmount = approved.filter(p => p.method === 'CARD').reduce((sum, p) => sum + p.amount, 0);
  const cashAmount = approved.filter(p => p.method === 'CASH').reduce((sum, p) => sum + p.amount, 0);
  const digitalAmount = approved.filter(p => ['UPI', 'BANK_TRANSFER'].includes(p.method)).reduce((sum, p) => sum + p.amount, 0);

  return {
    totalTransactions: payments.length,
    totalAmount,
    approvedAmount: totalAmount,
    declinedAmount: declined.reduce((sum, p) => sum + p.amount, 0),
    avgTransactionValue: approved.length > 0 ? totalAmount / approved.length : 0,
    cardPaymentPercentage: totalAmount > 0 ? (cardAmount / totalAmount) * 100 : 0,
    cashPaymentPercentage: totalAmount > 0 ? (cashAmount / totalAmount) * 100 : 0,
    digitalPaymentPercentage: totalAmount > 0 ? (digitalAmount / totalAmount) * 100 : 0,
  };
};

export const MOCK_PAYMENT_STATS = calculatePaymentStats(MOCK_PAYMENTS);
export const MOCK_PAYMENT_METHOD_SUMMARY = calculatePaymentMethodSummary(MOCK_PAYMENTS);

// ─── Mock API Functions ─────────────────────────────────────

export const fetchPayments = (filters?: {
  orderId?: string;
  locationId?: string;
  method?: PaymentMethod;
  status?: PaymentStatus;
  dateFrom?: string;
  dateTo?: string;
}): Promise<Payment[]> =>
  new Promise(resolve => setTimeout(() => {
    let results = [...MOCK_PAYMENTS];
    if (filters?.orderId) results = results.filter(p => p.orderId === filters.orderId);
    if (filters?.locationId) results = results.filter(p => p.locationId === filters.locationId);
    if (filters?.method) results = results.filter(p => p.method === filters.method);
    if (filters?.status) results = results.filter(p => p.status === filters.status);
    if (filters?.dateFrom) results = results.filter(p => p.createdAt >= filters.dateFrom!);
    if (filters?.dateTo) results = results.filter(p => p.createdAt <= filters.dateTo!);
    resolve(results);
  }, 500));

export const fetchPaymentById = (paymentId: string): Promise<Payment | null> =>
  new Promise(resolve => setTimeout(() => {
    resolve(MOCK_PAYMENTS.find(p => p.id === paymentId) || null);
  }, 300));

export const fetchPaymentStats = (): Promise<PaymentStats> =>
  new Promise(resolve => setTimeout(() => resolve(MOCK_PAYMENT_STATS), 300));

export const fetchDailyPaymentSummaries = (): Promise<DailyPaymentSummary[]> =>
  new Promise(resolve => setTimeout(() => resolve([...MOCK_DAILY_PAYMENT_SUMMARIES]), 400));

export const fetchPaymentMethodSummary = (): Promise<PaymentMethodSummary[]> =>
  new Promise(resolve => setTimeout(() => resolve([...MOCK_PAYMENT_METHOD_SUMMARY]), 300));

export const voidPayment = (paymentId: string): Promise<boolean> =>
  new Promise(resolve => setTimeout(() => {
    const payment = MOCK_PAYMENTS.find(p => p.id === paymentId);
    if (payment && payment.status === 'APPROVED') {
      payment.status = 'VOIDED';
    }
    resolve(true);
  }, 500));
