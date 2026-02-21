/**
 * CRM Mock Data
 * Test data for CRM, Customer 360, Loyalty & Smart Reminders
 * Florist POS + ERP SaaS Platform
 */

import type {
  Customer,
  CustomerOrderSummary,
  CustomerEventSummary,
  CustomerActivity,
  LoyaltyTransaction,
  SmartReminder,
  Customer360View,
} from './CRMTypes';
import { MOCK_CUSTOMERS } from './CRMTypes';

const today = new Date();
const isoDate = (d: Date) => d.toISOString().slice(0, 10);
const daysFrom = (n: number) => {
  const d = new Date(today);
  d.setDate(d.getDate() + n);
  return isoDate(d);
};
const daysAgo = (n: number) => daysFrom(-n);

// ─── Mock Customer Orders ───────────────────────────────────

export const MOCK_CUSTOMER_ORDERS: Record<string, CustomerOrderSummary[]> = {
  'cust-001': [
    { orderId: 'ord_201', orderNumber: 'ORD-2026-0201', orderDate: daysAgo(5), orderSource: 'WALK_IN', fulfillmentStatus: 'DELIVERED', paymentStatus: 'PAID', total: 4500, profit: 1125, items: 3 },
    { orderId: 'ord_185', orderNumber: 'ORD-2026-0185', orderDate: daysAgo(15), orderSource: 'PHONE', fulfillmentStatus: 'DELIVERED', paymentStatus: 'PAID', total: 8200, profit: 2050, items: 5 },
    { orderId: 'ord_142', orderNumber: 'ORD-2026-0142', orderDate: daysAgo(35), orderSource: 'ONLINE', fulfillmentStatus: 'DELIVERED', paymentStatus: 'PAID', total: 3800, profit: 950, items: 2 },
    { orderId: 'ord_098', orderNumber: 'ORD-2026-0098', orderDate: daysAgo(60), orderSource: 'WALK_IN', fulfillmentStatus: 'DELIVERED', paymentStatus: 'PAID', total: 12500, profit: 3125, items: 8 },
    { orderId: 'ord_045', orderNumber: 'ORD-2026-0045', orderDate: daysAgo(90), orderSource: 'PHONE', fulfillmentStatus: 'DELIVERED', paymentStatus: 'PAID', total: 6500, profit: 1625, items: 4 },
  ],
  'cust-002': [
    { orderId: 'ord_198', orderNumber: 'ORD-2026-0198', orderDate: daysAgo(10), orderSource: 'PHONE', fulfillmentStatus: 'DELIVERED', paymentStatus: 'PAID', total: 3500, profit: 875, items: 2 },
    { orderId: 'ord_165', orderNumber: 'ORD-2026-0165', orderDate: daysAgo(25), orderSource: 'PHONE', fulfillmentStatus: 'DELIVERED', paymentStatus: 'PAID', total: 5200, profit: 1300, items: 3 },
    { orderId: 'ord_120', orderNumber: 'ORD-2026-0120', orderDate: daysAgo(45), orderSource: 'WALK_IN', fulfillmentStatus: 'DELIVERED', paymentStatus: 'PAID', total: 4800, profit: 1200, items: 3 },
  ],
  'cust-003': [
    { orderId: 'ord_195', orderNumber: 'ORD-2026-0195', orderDate: daysAgo(12), orderSource: 'ONLINE', fulfillmentStatus: 'DELIVERED', paymentStatus: 'PAID', total: 2800, profit: 700, items: 2 },
    { orderId: 'ord_180', orderNumber: 'ORD-2026-0180', orderDate: daysAgo(20), orderSource: 'WALK_IN', fulfillmentStatus: 'DELIVERED', paymentStatus: 'PAID', total: 3200, profit: 800, items: 2 },
  ],
  'cust-004': [
    { orderId: 'ord_089', orderNumber: 'ORD-2026-0089', orderDate: daysAgo(120), orderSource: 'PHONE', fulfillmentStatus: 'DELIVERED', paymentStatus: 'PAID', total: 5500, profit: 1375, items: 3 },
    { orderId: 'ord_055', orderNumber: 'ORD-2026-0055', orderDate: daysAgo(150), orderSource: 'WALK_IN', fulfillmentStatus: 'DELIVERED', paymentStatus: 'PAID', total: 4200, profit: 1050, items: 2 },
  ],
};

// ─── Mock Customer Events ───────────────────────────────────

export const MOCK_CUSTOMER_EVENTS: Record<string, CustomerEventSummary[]> = {
  'cust-001': [
    { eventId: 'evt_025', eventName: 'Sharma-Patel Wedding', eventType: 'Wedding', eventDate: daysFrom(45), status: 'CONFIRMED', estimatedValue: 85000, totalPaid: 42500 },
    { eventId: 'evt_018', eventName: 'Corporate Diwali Event', eventType: 'Corporate', eventDate: daysAgo(90), status: 'COMPLETED', estimatedValue: 25000, totalPaid: 25000 },
  ],
  'cust-002': [
    { eventId: 'evt_022', eventName: 'Annual Office Decoration', eventType: 'Corporate', eventDate: daysFrom(30), status: 'PROPOSAL_SENT', estimatedValue: 35000, totalPaid: 0 },
  ],
};

// ─── Mock Customer Activities ───────────────────────────────

export const MOCK_CUSTOMER_ACTIVITIES: Record<string, CustomerActivity[]> = {
  'cust-001': [
    { id: 'act_001', customerId: 'cust-001', type: 'ORDER_COMPLETED', description: 'Order #ORD-2026-0201 delivered', createdAt: daysAgo(5) + 'T14:30:00Z' },
    { id: 'act_002', customerId: 'cust-001', type: 'POINTS_EARNED', description: 'Earned 45 points from order', metadata: { points: 45, orderId: 'ord_201' }, createdAt: daysAgo(5) + 'T14:31:00Z' },
    { id: 'act_003', customerId: 'cust-001', type: 'EVENT_BOOKED', description: 'Wedding event booked - Sharma-Patel', metadata: { eventId: 'evt_025' }, createdAt: daysAgo(10) + 'T11:00:00Z' },
    { id: 'act_004', customerId: 'cust-001', type: 'PAYMENT_RECEIVED', description: 'Advance payment ₹42,500 received', metadata: { amount: 42500, eventId: 'evt_025' }, createdAt: daysAgo(10) + 'T11:30:00Z' },
    { id: 'act_005', customerId: 'cust-001', type: 'ORDER_PLACED', description: 'Order #ORD-2026-0185 placed', createdAt: daysAgo(15) + 'T16:00:00Z' },
    { id: 'act_006', customerId: 'cust-001', type: 'TIER_UPGRADED', description: 'Upgraded to Platinum tier', metadata: { fromTier: 'GOLD', toTier: 'PLATINUM' }, createdAt: daysAgo(30) + 'T10:00:00Z' },
  ],
  'cust-002': [
    { id: 'act_010', customerId: 'cust-002', type: 'ORDER_COMPLETED', description: 'Order #ORD-2026-0198 delivered', createdAt: daysAgo(10) + 'T15:00:00Z' },
    { id: 'act_011', customerId: 'cust-002', type: 'POINTS_EARNED', description: 'Earned 35 points from order', metadata: { points: 35, orderId: 'ord_198' }, createdAt: daysAgo(10) + 'T15:01:00Z' },
    { id: 'act_012', customerId: 'cust-002', type: 'NOTE_ADDED', description: 'Prefers same-day delivery when possible', createdAt: daysAgo(20) + 'T09:00:00Z' },
  ],
  'cust-003': [
    { id: 'act_020', customerId: 'cust-003', type: 'ORDER_PLACED', description: 'Order #ORD-2026-0195 placed', createdAt: daysAgo(12) + 'T10:30:00Z' },
    { id: 'act_021', customerId: 'cust-003', type: 'ORDER_COMPLETED', description: 'Order #ORD-2026-0195 delivered', createdAt: daysAgo(11) + 'T14:00:00Z' },
  ],
  'cust-004': [
    { id: 'act_030', customerId: 'cust-004', type: 'TAG_ADDED', description: 'Tagged as At Risk - no recent orders', createdAt: daysAgo(60) + 'T08:00:00Z' },
  ],
};

// ─── Mock Loyalty Transactions ──────────────────────────────

export const MOCK_LOYALTY_TRANSACTIONS: Record<string, LoyaltyTransaction[]> = {
  'cust-001': [
    { id: 'lt_001', customerId: 'cust-001', type: 'EARN', points: 45, balance: 2450, description: 'Order #ORD-2026-0201', orderId: 'ord_201', createdAt: daysAgo(5) + 'T14:31:00Z' },
    { id: 'lt_002', customerId: 'cust-001', type: 'EARN', points: 82, balance: 2405, description: 'Order #ORD-2026-0185', orderId: 'ord_185', createdAt: daysAgo(15) + 'T16:05:00Z' },
    { id: 'lt_003', customerId: 'cust-001', type: 'REDEEM', points: -200, balance: 2323, description: 'Redeemed for ₹200 discount', orderId: 'ord_142', createdAt: daysAgo(35) + 'T12:00:00Z' },
    { id: 'lt_004', customerId: 'cust-001', type: 'BONUS', points: 100, balance: 2523, description: 'Tier upgrade bonus - Platinum', createdAt: daysAgo(30) + 'T10:00:00Z' },
    { id: 'lt_005', customerId: 'cust-001', type: 'EARN', points: 125, balance: 2423, description: 'Order #ORD-2026-0098', orderId: 'ord_098', createdAt: daysAgo(60) + 'T14:00:00Z' },
  ],
  'cust-002': [
    { id: 'lt_010', customerId: 'cust-002', type: 'EARN', points: 35, balance: 680, description: 'Order #ORD-2026-0198', orderId: 'ord_198', createdAt: daysAgo(10) + 'T15:01:00Z' },
    { id: 'lt_011', customerId: 'cust-002', type: 'EARN', points: 52, balance: 645, description: 'Order #ORD-2026-0165', orderId: 'ord_165', createdAt: daysAgo(25) + 'T11:30:00Z' },
    { id: 'lt_012', customerId: 'cust-002', type: 'REDEEM', points: -100, balance: 593, description: 'Redeemed for ₹100 discount', orderId: 'ord_120', createdAt: daysAgo(45) + 'T10:00:00Z' },
  ],
  'cust-003': [
    { id: 'lt_020', customerId: 'cust-003', type: 'EARN', points: 28, balance: 85, description: 'Order #ORD-2026-0195', orderId: 'ord_195', createdAt: daysAgo(12) + 'T10:35:00Z' },
    { id: 'lt_021', customerId: 'cust-003', type: 'EARN', points: 32, balance: 57, description: 'Order #ORD-2026-0180', orderId: 'ord_180', createdAt: daysAgo(20) + 'T14:00:00Z' },
    { id: 'lt_022', customerId: 'cust-003', type: 'BONUS', points: 25, balance: 25, description: 'Welcome bonus', createdAt: daysAgo(95) + 'T10:00:00Z' },
  ],
};

// ─── Mock Smart Reminders ───────────────────────────────────

export const MOCK_SMART_REMINDERS: SmartReminder[] = [
  // Birthday Reminders
  {
    id: 'rem_001',
    type: 'BIRTHDAY',
    priority: 'HIGH',
    customerId: 'cust-001',
    customerName: 'Priya Sharma',
    customerPhone: '+91 98765 43210',
    title: 'Birthday in 3 days',
    description: 'VIP customer Priya Sharma\'s birthday is on March 15. Consider sending a birthday arrangement or special offer.',
    dueDate: daysFrom(3),
    metadata: { birthday: '1990-03-15', tier: 'PLATINUM', lifetimeValue: 125000 },
    dismissed: false,
    createdAt: daysAgo(0) + 'T08:00:00Z',
  },
  {
    id: 'rem_002',
    type: 'BIRTHDAY',
    priority: 'MEDIUM',
    customerId: 'cust-003',
    customerName: 'Anita Desai',
    customerPhone: '+91 76543 21098',
    title: 'Birthday in 7 days',
    description: 'Customer Anita Desai\'s birthday is coming up. Great opportunity to engage a new customer.',
    dueDate: daysFrom(7),
    metadata: { birthday: '1992-02-28', tier: 'SILVER' },
    dismissed: false,
    createdAt: daysAgo(0) + 'T08:00:00Z',
  },
  // Anniversary Reminders
  {
    id: 'rem_003',
    type: 'ANNIVERSARY',
    priority: 'HIGH',
    customerId: 'cust-001',
    customerName: 'Priya Sharma',
    customerPhone: '+91 98765 43210',
    title: 'Anniversary coming up',
    description: 'Priya Sharma\'s wedding anniversary is in November. She has ordered anniversary flowers before.',
    dueDate: daysFrom(270),
    metadata: { anniversary: '2018-11-20' },
    dismissed: false,
    createdAt: daysAgo(0) + 'T08:00:00Z',
  },
  // At Risk Customers
  {
    id: 'rem_004',
    type: 'AT_RISK',
    priority: 'HIGH',
    customerId: 'cust-004',
    customerName: 'Vikram Singh',
    customerPhone: '+91 65432 10987',
    title: 'Customer at risk - 120+ days inactive',
    description: 'Vikram Singh hasn\'t ordered in 120 days. Previously a repeat customer with 8 orders. Consider reaching out with a special offer.',
    dueDate: daysAgo(0),
    metadata: { lastOrderDate: daysAgo(120), totalOrders: 8, lifetimeValue: 32000 },
    dismissed: false,
    createdAt: daysAgo(0) + 'T08:00:00Z',
  },
  // VIP Follow-up
  {
    id: 'rem_005',
    type: 'VIP_FOLLOWUP',
    priority: 'HIGH',
    customerId: 'cust-001',
    customerName: 'Priya Sharma',
    customerPhone: '+91 98765 43210',
    title: 'VIP wedding event follow-up',
    description: 'Priya has a wedding event booked in 45 days. Schedule a follow-up call to confirm details and upsell additional services.',
    dueDate: daysFrom(5),
    metadata: { eventId: 'evt_025', eventDate: daysFrom(45), estimatedValue: 85000 },
    dismissed: false,
    createdAt: daysAgo(2) + 'T10:00:00Z',
  },
  // Re-engagement
  {
    id: 'rem_006',
    type: 'RE_ENGAGEMENT',
    priority: 'MEDIUM',
    customerId: 'cust-005',
    customerName: 'Meera Kapoor',
    customerPhone: '+91 54321 09876',
    title: 'Re-engagement opportunity',
    description: 'Meera ordered flowers for Mother\'s Day last year. Mother\'s Day is approaching - good time to reach out.',
    dueDate: daysFrom(60),
    metadata: { lastOccasion: 'Mothers Day', lastOrderDate: daysAgo(300) },
    dismissed: false,
    createdAt: daysAgo(0) + 'T08:00:00Z',
  },
  // Event Follow-up
  {
    id: 'rem_007',
    type: 'EVENT_FOLLOWUP',
    priority: 'MEDIUM',
    customerId: 'cust-002',
    customerName: 'Rahul Verma',
    customerPhone: '+91 87654 32109',
    title: 'Corporate event follow-up',
    description: 'Rahul\'s company has a proposal pending. Follow up on the Annual Office Decoration proposal.',
    dueDate: daysAgo(0),
    metadata: { eventId: 'evt_022', proposalDate: daysAgo(5), estimatedValue: 35000 },
    dismissed: false,
    createdAt: daysAgo(3) + 'T09:00:00Z',
  },
  // No Purchase Warning
  {
    id: 'rem_008',
    type: 'NO_PURCHASE',
    priority: 'MEDIUM',
    customerId: 'cust-006',
    customerName: 'Suresh Menon',
    customerPhone: '+91 43210 98765',
    title: 'No purchase in 90+ days',
    description: 'Regular customer Suresh Menon hasn\'t ordered in 95 days. Previously ordered monthly for office reception.',
    dueDate: daysAgo(0),
    metadata: { lastOrderDate: daysAgo(95), avgOrderFrequency: 30, totalOrders: 12 },
    dismissed: false,
    createdAt: daysAgo(5) + 'T08:00:00Z',
  },
];

// ─── Build Customer 360 View ────────────────────────────────

export const buildCustomer360View = (customerId: string): Customer360View | null => {
  const customer = MOCK_CUSTOMERS.find(c => c.id === customerId);
  if (!customer) return null;

  return {
    customer,
    orders: MOCK_CUSTOMER_ORDERS[customerId] || [],
    events: MOCK_CUSTOMER_EVENTS[customerId] || [],
    recentActivity: MOCK_CUSTOMER_ACTIVITIES[customerId] || [],
    loyaltyTransactions: MOCK_LOYALTY_TRANSACTIONS[customerId] || [],
    engagementScore: calculateEngagementScore(customer),
    churnRisk: calculateChurnRisk(customer),
  };
};

const calculateEngagementScore = (customer: Customer): number => {
  let score = 0;
  // Recency (last 30 days = 30 pts, 60 days = 20 pts, 90 days = 10 pts)
  const daysSinceOrder = customer.lastOrderDate 
    ? Math.floor((Date.now() - new Date(customer.lastOrderDate).getTime()) / (1000 * 60 * 60 * 24))
    : 999;
  if (daysSinceOrder <= 30) score += 30;
  else if (daysSinceOrder <= 60) score += 20;
  else if (daysSinceOrder <= 90) score += 10;

  // Frequency (orders per month)
  score += Math.min(customer.totalOrders * 2, 30);

  // Monetary (lifetime value tiers)
  if (customer.lifetimeValue >= 100000) score += 25;
  else if (customer.lifetimeValue >= 50000) score += 20;
  else if (customer.lifetimeValue >= 20000) score += 15;
  else if (customer.lifetimeValue >= 10000) score += 10;
  else score += 5;

  // Engagement bonuses
  if (customer.marketingConsent) score += 5;
  if (customer.referralCount > 0) score += 5;
  if (customer.tags.includes('VIP')) score += 5;

  return Math.min(score, 100);
};

const calculateChurnRisk = (customer: Customer): 'LOW' | 'MEDIUM' | 'HIGH' => {
  const daysSinceOrder = customer.lastOrderDate
    ? Math.floor((Date.now() - new Date(customer.lastOrderDate).getTime()) / (1000 * 60 * 60 * 24))
    : 999;
    
  if (daysSinceOrder > 90) return 'HIGH';
  if (daysSinceOrder > 60) return 'MEDIUM';
  return 'LOW';
};

// ─── Reminder Summary Stats ─────────────────────────────────

export interface ReminderSummary {
  total: number;
  urgent: number;
  high: number;
  medium: number;
  low: number;
  birthdayCount: number;
  anniversaryCount: number;
  atRiskCount: number;
  followUpCount: number;
}

export const calculateReminderSummary = (reminders: SmartReminder[]): ReminderSummary => {
  const active = reminders.filter(r => !r.dismissed);
  return {
    total: active.length,
    urgent: active.filter(r => r.priority === 'URGENT').length,
    high: active.filter(r => r.priority === 'HIGH').length,
    medium: active.filter(r => r.priority === 'MEDIUM').length,
    low: active.filter(r => r.priority === 'LOW').length,
    birthdayCount: active.filter(r => r.type === 'BIRTHDAY').length,
    anniversaryCount: active.filter(r => r.type === 'ANNIVERSARY').length,
    atRiskCount: active.filter(r => r.type === 'AT_RISK').length,
    followUpCount: active.filter(r => ['VIP_FOLLOWUP', 'EVENT_FOLLOWUP', 'RE_ENGAGEMENT'].includes(r.type)).length,
  };
};

export const MOCK_REMINDER_SUMMARY = calculateReminderSummary(MOCK_SMART_REMINDERS);

// ─── Mock API Functions ─────────────────────────────────────

export const fetchCustomer360 = (customerId: string): Promise<Customer360View | null> =>
  new Promise(resolve => setTimeout(() => resolve(buildCustomer360View(customerId)), 500));

export const fetchSmartReminders = (): Promise<SmartReminder[]> =>
  new Promise(resolve => setTimeout(() => resolve([...MOCK_SMART_REMINDERS]), 400));

export const fetchReminderSummary = (): Promise<ReminderSummary> =>
  new Promise(resolve => setTimeout(() => resolve(MOCK_REMINDER_SUMMARY), 300));

export const dismissReminderMock = (reminderId: string): Promise<boolean> =>
  new Promise(resolve => setTimeout(() => {
    const reminder = MOCK_SMART_REMINDERS.find(r => r.id === reminderId);
    if (reminder) reminder.dismissed = true;
    resolve(true);
  }, 300));

export const fetchCustomerOrders = (customerId: string): Promise<CustomerOrderSummary[]> =>
  new Promise(resolve => setTimeout(() => resolve(MOCK_CUSTOMER_ORDERS[customerId] || []), 400));

export const fetchCustomerActivities = (customerId: string): Promise<CustomerActivity[]> =>
  new Promise(resolve => setTimeout(() => resolve(MOCK_CUSTOMER_ACTIVITIES[customerId] || []), 400));
