// =============================================================================
// CRM TYPES - Customer Retention & Intelligence Module
// Florist ERP SaaS — CRM & Customer 360 View
// =============================================================================

// -----------------------------------------------------------------------------
// Loyalty Tiers
// -----------------------------------------------------------------------------

export type LoyaltyTier = 'SILVER' | 'GOLD' | 'PLATINUM';

export const LOYALTY_TIERS: LoyaltyTier[] = ['SILVER', 'GOLD', 'PLATINUM'];

export interface LoyaltyTierConfig {
  tier: LoyaltyTier;
  label: string;
  color: string;
  backgroundColor: string;
  minPoints: number;
  pointsMultiplier: number; // bonus multiplier on earnings
  description: string;
  benefits: string[];
}

export const LOYALTY_TIER_CONFIGS: Record<LoyaltyTier, LoyaltyTierConfig> = {
  SILVER: {
    tier: 'SILVER',
    label: 'Silver',
    color: '#9e9e9e',
    backgroundColor: 'rgba(158, 158, 158, 0.15)',
    minPoints: 0,
    pointsMultiplier: 1.0,
    description: 'Welcome to our loyalty program',
    benefits: [
      'Earn 1 point per {symbol}100 spent',
      'Birthday discount (5%)',
      'Early access to sales',
    ],
  },
  GOLD: {
    tier: 'GOLD',
    label: 'Gold',
    color: '#ffc107',
    backgroundColor: 'rgba(255, 193, 7, 0.15)',
    minPoints: 500,
    pointsMultiplier: 1.5,
    description: 'Valued customer status',
    benefits: [
      'Earn 1.5x points per {symbol}100 spent',
      'Birthday discount (10%)',
      'Free delivery on orders over {symbol}2000',
      'Priority customer support',
    ],
  },
  PLATINUM: {
    tier: 'PLATINUM',
    label: 'Platinum',
    color: '#00bcd4',
    backgroundColor: 'rgba(0, 188, 212, 0.15)',
    minPoints: 2000,
    pointsMultiplier: 2.0,
    description: 'VIP customer status',
    benefits: [
      'Earn 2x points per {symbol}100 spent',
      'Birthday discount (15%)',
      'Free delivery on all orders',
      'Exclusive VIP events access',
      'Dedicated account manager',
      'Anniversary gift',
    ],
  },
};

// -----------------------------------------------------------------------------
// Customer Tags
// -----------------------------------------------------------------------------

export type CustomerTagType =
  | 'VIP'
  | 'CORPORATE'
  | 'WEDDING_CLIENT'
  | 'REPEAT_CUSTOMER'
  | 'NEW_CUSTOMER'
  | 'AT_RISK'
  | 'LOST'
  | 'WHOLESALE'
  | 'REFERRAL'
  | 'INFLUENCER';

export interface CustomerTag {
  type: CustomerTagType;
  label: string;
  color: string;
  description: string;
  autoAssign?: {
    condition: string;
    field: string;
    operator: 'gt' | 'lt' | 'eq' | 'between' | 'days_since';
    value: number | [number, number];
  };
}

export const CUSTOMER_TAGS: Record<CustomerTagType, CustomerTag> = {
  VIP: {
    type: 'VIP',
    label: 'VIP',
    color: '#9c27b0',
    description: 'High-value customer',
    autoAssign: { condition: 'lifetimeValue', field: 'lifetimeValue', operator: 'gt', value: 50000 },
  },
  CORPORATE: {
    type: 'CORPORATE',
    label: 'Corporate',
    color: '#2196f3',
    description: 'Business/corporate account',
  },
  WEDDING_CLIENT: {
    type: 'WEDDING_CLIENT',
    label: 'Wedding Client',
    color: '#e91e63',
    description: 'Has wedding events',
  },
  REPEAT_CUSTOMER: {
    type: 'REPEAT_CUSTOMER',
    label: 'Repeat',
    color: '#4caf50',
    description: 'Ordered multiple times',
    autoAssign: { condition: 'totalOrders', field: 'totalOrders', operator: 'gt', value: 3 },
  },
  NEW_CUSTOMER: {
    type: 'NEW_CUSTOMER',
    label: 'New',
    color: '#00bcd4',
    description: 'Recently joined',
    autoAssign: { condition: 'firstOrderDays', field: 'createdAt', operator: 'lt', value: 30 },
  },
  AT_RISK: {
    type: 'AT_RISK',
    label: 'At Risk',
    color: '#ff9800',
    description: 'No purchase in 60-90 days',
    autoAssign: { condition: 'lastOrderDays', field: 'lastOrderDate', operator: 'between', value: [60, 90] },
  },
  LOST: {
    type: 'LOST',
    label: 'Lost',
    color: '#f44336',
    description: 'No purchase in 90+ days',
    autoAssign: { condition: 'lastOrderDays', field: 'lastOrderDate', operator: 'gt', value: 90 },
  },
  WHOLESALE: {
    type: 'WHOLESALE',
    label: 'Wholesale',
    color: '#795548',
    description: 'Wholesale buyer',
  },
  REFERRAL: {
    type: 'REFERRAL',
    label: 'Referral',
    color: '#009688',
    description: 'Referred by another customer',
  },
  INFLUENCER: {
    type: 'INFLUENCER',
    label: 'Influencer',
    color: '#ff5722',
    description: 'Social media influencer',
  },
};

// -----------------------------------------------------------------------------
// Customer Model (Enhanced)
// -----------------------------------------------------------------------------

export interface Customer {
  id: string;
  tenantId: string;
  locationId?: string; // Primary location

  // Basic Info
  name: string;
  phone: string;
  email?: string;
  preferredAddress?: string;
  notes?: string;

  // Dates
  birthday?: string; // ISO date "YYYY-MM-DD"
  anniversary?: string; // ISO date "YYYY-MM-DD"
  createdAt: string; // ISO timestamp

  // Tags & Segmentation
  tags: CustomerTagType[];

  // Metrics
  lifetimeValue: number; // Total revenue
  totalOrders: number;
  averageOrderValue: number;
  lastOrderDate?: string; // ISO date
  firstOrderDate?: string; // ISO date

  // Loyalty
  loyaltyPoints: number;
  loyaltyTier: LoyaltyTier;
  loyaltyPointsEarned: number; // All time earned
  loyaltyPointsRedeemed: number; // All time redeemed

  // Profit Contribution
  totalProfit: number; // Lifetime profit
  profitMargin: number; // Average % margin

  // Marketing
  marketingConsent: boolean;
  preferredContactMethod?: 'PHONE' | 'EMAIL' | 'WHATSAPP' | 'SMS';

  // Referral
  referredBy?: string; // Customer ID
  referralCount: number; // How many referred
}

// -----------------------------------------------------------------------------
// Customer Order Summary (for 360 view)
// -----------------------------------------------------------------------------

export interface CustomerOrderSummary {
  orderId: string;
  orderNumber: string;
  orderDate: string;
  orderSource: string;
  fulfillmentStatus: string;
  paymentStatus: string;
  total: number;
  profit: number;
  items: number;
}

// -----------------------------------------------------------------------------
// Customer Event Summary (for 360 view)
// -----------------------------------------------------------------------------

export interface CustomerEventSummary {
  eventId: string;
  eventName: string;
  eventType: string;
  eventDate: string;
  status: string;
  estimatedValue: number;
  totalPaid: number;
}

// -----------------------------------------------------------------------------
// Customer 360 View Data
// -----------------------------------------------------------------------------

export interface Customer360View {
  customer: Customer;
  orders: CustomerOrderSummary[];
  events: CustomerEventSummary[];
  recentActivity: CustomerActivity[];
  loyaltyTransactions: LoyaltyTransaction[];
  engagementScore: number; // 0-100
  churnRisk: 'LOW' | 'MEDIUM' | 'HIGH';
}

// -----------------------------------------------------------------------------
// Customer Activity
// -----------------------------------------------------------------------------

export type CustomerActivityType =
  | 'ORDER_PLACED'
  | 'ORDER_COMPLETED'
  | 'EVENT_BOOKED'
  | 'EVENT_COMPLETED'
  | 'PAYMENT_RECEIVED'
  | 'POINTS_EARNED'
  | 'POINTS_REDEEMED'
  | 'TIER_UPGRADED'
  | 'TAG_ADDED'
  | 'NOTE_ADDED';

export interface CustomerActivity {
  id: string;
  customerId: string;
  type: CustomerActivityType;
  description: string;
  metadata?: Record<string, unknown>;
  createdAt: string;
}

// -----------------------------------------------------------------------------
// Loyalty Transactions
// -----------------------------------------------------------------------------

export type LoyaltyTransactionType = 'EARN' | 'REDEEM' | 'EXPIRE' | 'ADJUST' | 'BONUS';

export interface LoyaltyTransaction {
  id: string;
  customerId: string;
  type: LoyaltyTransactionType;
  points: number; // positive for earn, negative for redeem
  balance: number; // balance after transaction
  description: string;
  orderId?: string;
  createdAt: string;
}

// -----------------------------------------------------------------------------
// Smart Reminders
// -----------------------------------------------------------------------------

export type ReminderType =
  | 'BIRTHDAY'
  | 'ANNIVERSARY'
  | 'NO_PURCHASE'
  | 'VIP_FOLLOWUP'
  | 'AT_RISK'
  | 'RE_ENGAGEMENT'
  | 'EVENT_FOLLOWUP';

export type ReminderPriority = 'LOW' | 'MEDIUM' | 'HIGH' | 'URGENT';

export interface SmartReminder {
  id: string;
  type: ReminderType;
  priority: ReminderPriority;
  customerId: string;
  customerName: string;
  customerPhone: string;
  title: string;
  description: string;
  dueDate: string; // ISO date
  metadata?: Record<string, unknown>;
  dismissed: boolean;
  actionTaken?: string;
  createdAt: string;
}

export interface ReminderConfig {
  type: ReminderType;
  label: string;
  icon: string;
  color: string;
  defaultPriority: ReminderPriority;
  description: string;
}

export const REMINDER_CONFIGS: Record<ReminderType, ReminderConfig> = {
  BIRTHDAY: {
    type: 'BIRTHDAY',
    label: 'Birthday',
    icon: 'Cake',
    color: '#e91e63',
    defaultPriority: 'HIGH',
    description: 'Customer birthday coming up',
  },
  ANNIVERSARY: {
    type: 'ANNIVERSARY',
    label: 'Anniversary',
    icon: 'Favorite',
    color: '#f44336',
    defaultPriority: 'HIGH',
    description: 'Customer anniversary coming up',
  },
  NO_PURCHASE: {
    type: 'NO_PURCHASE',
    label: 'No Recent Purchase',
    icon: 'ShoppingCartOff',
    color: '#ff9800',
    defaultPriority: 'MEDIUM',
    description: 'Customer hasn\'t ordered in 90+ days',
  },
  VIP_FOLLOWUP: {
    type: 'VIP_FOLLOWUP',
    label: 'VIP Follow-up',
    icon: 'Star',
    color: '#9c27b0',
    defaultPriority: 'HIGH',
    description: 'VIP customer requires attention',
  },
  AT_RISK: {
    type: 'AT_RISK',
    label: 'At Risk',
    icon: 'Warning',
    color: '#ff5722',
    defaultPriority: 'HIGH',
    description: 'Customer at risk of churning',
  },
  RE_ENGAGEMENT: {
    type: 'RE_ENGAGEMENT',
    label: 'Re-engagement',
    icon: 'Replay',
    color: '#2196f3',
    defaultPriority: 'MEDIUM',
    description: 'Opportunity to re-engage customer',
  },
  EVENT_FOLLOWUP: {
    type: 'EVENT_FOLLOWUP',
    label: 'Event Follow-up',
    icon: 'EventNote',
    color: '#4caf50',
    defaultPriority: 'MEDIUM',
    description: 'Follow up after event completion',
  },
};

// -----------------------------------------------------------------------------
// Loyalty Points Configuration
// -----------------------------------------------------------------------------

export interface LoyaltyConfig {
  pointsPerCurrency: number; // Points earned per ₹100
  currencyPerPoint: number; // ₹ value of 1 point when redeeming
  minRedeemPoints: number; // Minimum points to redeem
  pointsExpireDays: number; // Days until points expire (0 = never)
  welcomeBonus: number; // Points for new customers
  referralBonus: number; // Points for successful referral
  birthdayBonus: number; // Bonus points on birthday
}

export const DEFAULT_LOYALTY_CONFIG: LoyaltyConfig = {
  pointsPerCurrency: 1, // 1 point per ₹100
  currencyPerPoint: 1, // 1 point = ₹1
  minRedeemPoints: 100,
  pointsExpireDays: 365,
  welcomeBonus: 50,
  referralBonus: 100,
  birthdayBonus: 50,
};

// -----------------------------------------------------------------------------
// Customer Search / Filter
// -----------------------------------------------------------------------------

export interface CustomerSearchFilters {
  query?: string;
  tags?: CustomerTagType[];
  loyaltyTiers?: LoyaltyTier[];
  minLifetimeValue?: number;
  maxLifetimeValue?: number;
  hasUpcomingBirthday?: boolean;
  hasUpcomingAnniversary?: boolean;
  daysSinceLastOrder?: number;
  marketingConsent?: boolean;
}

// -----------------------------------------------------------------------------
// Helper Functions
// -----------------------------------------------------------------------------

export function getTierFromPoints(points: number): LoyaltyTier {
  if (points >= LOYALTY_TIER_CONFIGS.PLATINUM.minPoints) return 'PLATINUM';
  if (points >= LOYALTY_TIER_CONFIGS.GOLD.minPoints) return 'GOLD';
  return 'SILVER';
}

export function getPointsToNextTier(currentPoints: number, currentTier: LoyaltyTier): number | null {
  if (currentTier === 'PLATINUM') return null;
  const nextTier = currentTier === 'SILVER' ? 'GOLD' : 'PLATINUM';
  return LOYALTY_TIER_CONFIGS[nextTier].minPoints - currentPoints;
}

export function calculatePointsEarned(amount: number, tier: LoyaltyTier): number {
  const multiplier = LOYALTY_TIER_CONFIGS[tier].pointsMultiplier;
  const basePoints = Math.floor(amount / 100) * DEFAULT_LOYALTY_CONFIG.pointsPerCurrency;
  return Math.floor(basePoints * multiplier);
}

export { formatCurrency } from '../../core/i18n';

export function daysSince(dateString?: string): number | null {
  if (!dateString) return null;
  const date = new Date(dateString);
  const now = new Date();
  const diffTime = now.getTime() - date.getTime();
  return Math.floor(diffTime / (1000 * 60 * 60 * 24));
}

export function daysUntil(dateString?: string): number | null {
  if (!dateString) return null;
  const date = new Date(dateString);
  const now = new Date();
  const diffTime = date.getTime() - now.getTime();
  return Math.ceil(diffTime / (1000 * 60 * 60 * 24));
}

export function getUpcomingDate(monthDay: string): Date {
  // monthDay format: "MM-DD"
  const [month, day] = monthDay.split('-').map(Number);
  const now = new Date();
  const thisYear = new Date(now.getFullYear(), month - 1, day);
  const nextYear = new Date(now.getFullYear() + 1, month - 1, day);
  return thisYear >= now ? thisYear : nextYear;
}

export function isWithinDays(dateString: string | undefined, days: number): boolean {
  if (!dateString) return false;
  const daysAway = daysUntil(dateString);
  return daysAway !== null && daysAway >= 0 && daysAway <= days;
}

// -----------------------------------------------------------------------------
// Mock Data
// -----------------------------------------------------------------------------

export const MOCK_CUSTOMERS: Customer[] = [
  {
    id: 'cust-001',
    tenantId: 'tenant-001',
    name: 'Priya Sharma',
    phone: '+91 98765 43210',
    email: 'priya.sharma@email.com',
    preferredAddress: '123 MG Road, Bangalore 560001',
    birthday: '1990-03-15',
    anniversary: '2018-11-20',
    createdAt: '2023-01-15T10:00:00Z',
    tags: ['VIP', 'WEDDING_CLIENT', 'REPEAT_CUSTOMER'],
    lifetimeValue: 125000,
    totalOrders: 28,
    averageOrderValue: 4464,
    lastOrderDate: '2026-02-10',
    firstOrderDate: '2023-01-20',
    loyaltyPoints: 2450,
    loyaltyTier: 'PLATINUM',
    loyaltyPointsEarned: 3200,
    loyaltyPointsRedeemed: 750,
    totalProfit: 31250,
    profitMargin: 25,
    marketingConsent: true,
    preferredContactMethod: 'WHATSAPP',
    referralCount: 3,
    notes: 'Prefers roses. Usually orders for corporate events.',
  },
  {
    id: 'cust-002',
    tenantId: 'tenant-001',
    name: 'Rahul Verma',
    phone: '+91 87654 32109',
    email: 'rahul.v@company.com',
    birthday: '1985-07-22',
    createdAt: '2024-06-10T14:30:00Z',
    tags: ['CORPORATE', 'REPEAT_CUSTOMER'],
    lifetimeValue: 45000,
    totalOrders: 12,
    averageOrderValue: 3750,
    lastOrderDate: '2026-02-05',
    firstOrderDate: '2024-06-15',
    loyaltyPoints: 680,
    loyaltyTier: 'GOLD',
    loyaltyPointsEarned: 980,
    loyaltyPointsRedeemed: 300,
    totalProfit: 11250,
    profitMargin: 25,
    marketingConsent: true,
    preferredContactMethod: 'EMAIL',
    referralCount: 1,
  },
  {
    id: 'cust-003',
    tenantId: 'tenant-001',
    name: 'Anita Desai',
    phone: '+91 76543 21098',
    birthday: '1992-02-28',
    anniversary: '2020-05-10',
    createdAt: '2025-08-20T09:00:00Z',
    tags: ['NEW_CUSTOMER'],
    lifetimeValue: 8500,
    totalOrders: 3,
    averageOrderValue: 2833,
    lastOrderDate: '2025-11-15',
    firstOrderDate: '2025-08-25',
    loyaltyPoints: 85,
    loyaltyTier: 'SILVER',
    loyaltyPointsEarned: 85,
    loyaltyPointsRedeemed: 0,
    totalProfit: 2125,
    profitMargin: 25,
    marketingConsent: true,
    referralCount: 0,
  },
  {
    id: 'cust-004',
    tenantId: 'tenant-001',
    name: 'Vikram Singh',
    phone: '+91 65432 10987',
    email: 'vikram.singh@gmail.com',
    birthday: '1988-09-05',
    createdAt: '2023-11-01T11:00:00Z',
    tags: ['AT_RISK', 'REPEAT_CUSTOMER'],
    lifetimeValue: 32000,
    totalOrders: 8,
    averageOrderValue: 4000,
    lastOrderDate: '2025-10-20',
    firstOrderDate: '2023-11-10',
    loyaltyPoints: 520,
    loyaltyTier: 'GOLD',
    loyaltyPointsEarned: 720,
    loyaltyPointsRedeemed: 200,
    totalProfit: 8000,
    profitMargin: 25,
    marketingConsent: false,
    referralCount: 0,
    notes: 'Prefers lilies. Last order was for mother\'s birthday.',
  },
  {
    id: 'cust-005',
    tenantId: 'tenant-001',
    name: 'Meera Patel',
    phone: '+91 54321 09876',
    email: 'meera.patel@email.com',
    birthday: '1995-02-25',
    anniversary: '2022-12-15',
    createdAt: '2024-02-14T16:00:00Z',
    tags: ['WEDDING_CLIENT', 'VIP'],
    lifetimeValue: 180000,
    totalOrders: 15,
    averageOrderValue: 12000,
    lastOrderDate: '2026-02-14',
    firstOrderDate: '2024-02-20',
    loyaltyPoints: 3200,
    loyaltyTier: 'PLATINUM',
    loyaltyPointsEarned: 4500,
    loyaltyPointsRedeemed: 1300,
    totalProfit: 45000,
    profitMargin: 25,
    marketingConsent: true,
    preferredContactMethod: 'PHONE',
    referralCount: 5,
    notes: 'Wedding planner. Refers many clients.',
  },
];

export const MOCK_CUSTOMER_ORDERS: CustomerOrderSummary[] = [
  {
    orderId: 'ord-001',
    orderNumber: 'ORD-2026-0215',
    orderDate: '2026-02-14',
    orderSource: 'PHONE',
    fulfillmentStatus: 'COMPLETED',
    paymentStatus: 'PAID',
    total: 5500,
    profit: 1375,
    items: 3,
  },
  {
    orderId: 'ord-002',
    orderNumber: 'ORD-2026-0180',
    orderDate: '2026-02-10',
    orderSource: 'WALK_IN',
    fulfillmentStatus: 'COMPLETED',
    paymentStatus: 'PAID',
    total: 3200,
    profit: 800,
    items: 2,
  },
  {
    orderId: 'ord-003',
    orderNumber: 'ORD-2026-0120',
    orderDate: '2026-01-25',
    orderSource: 'WEBSITE',
    fulfillmentStatus: 'COMPLETED',
    paymentStatus: 'PAID',
    total: 4800,
    profit: 1200,
    items: 4,
  },
];

export const MOCK_CUSTOMER_EVENTS: CustomerEventSummary[] = [
  {
    eventId: 'evt-001',
    eventName: 'Sharma Wedding Reception',
    eventType: 'WEDDING',
    eventDate: '2025-12-15',
    status: 'COMPLETED',
    estimatedValue: 85000,
    totalPaid: 85000,
  },
  {
    eventId: 'evt-002',
    eventName: 'Corporate Annual Gala',
    eventType: 'CORPORATE',
    eventDate: '2026-03-20',
    status: 'CONFIRMED',
    estimatedValue: 45000,
    totalPaid: 22500,
  },
];

export const MOCK_REMINDERS: SmartReminder[] = [
  {
    id: 'rem-001',
    type: 'BIRTHDAY',
    priority: 'HIGH',
    customerId: 'cust-005',
    customerName: 'Meera Patel',
    customerPhone: '+91 54321 09876',
    title: 'Birthday in 7 days',
    description: 'Meera Patel\'s birthday is on Feb 25. She is a VIP/Platinum customer. Consider sending a personalized offer.',
    dueDate: '2026-02-25',
    dismissed: false,
    createdAt: '2026-02-18T08:00:00Z',
  },
  {
    id: 'rem-002',
    type: 'ANNIVERSARY',
    priority: 'HIGH',
    customerId: 'cust-003',
    customerName: 'Anita Desai',
    customerPhone: '+91 76543 21098',
    title: 'Anniversary upcoming',
    description: 'Wedding anniversary on May 10. Good opportunity for premium bouquet suggestion.',
    dueDate: '2026-05-10',
    dismissed: false,
    createdAt: '2026-02-18T08:00:00Z',
  },
  {
    id: 'rem-003',
    type: 'NO_PURCHASE',
    priority: 'MEDIUM',
    customerId: 'cust-004',
    customerName: 'Vikram Singh',
    customerPhone: '+91 65432 10987',
    title: 'No purchase in 120 days',
    description: 'Last order was on Oct 20, 2025. Customer may be losing interest.',
    dueDate: '2026-02-18',
    dismissed: false,
    createdAt: '2026-02-18T08:00:00Z',
  },
  {
    id: 'rem-004',
    type: 'VIP_FOLLOWUP',
    priority: 'HIGH',
    customerId: 'cust-001',
    customerName: 'Priya Sharma',
    customerPhone: '+91 98765 43210',
    title: 'VIP check-in',
    description: 'Platinum customer with upcoming anniversary in November. Proactive outreach recommended.',
    dueDate: '2026-02-20',
    dismissed: false,
    createdAt: '2026-02-18T08:00:00Z',
  },
  {
    id: 'rem-005',
    type: 'AT_RISK',
    priority: 'HIGH',
    customerId: 'cust-004',
    customerName: 'Vikram Singh',
    customerPhone: '+91 65432 10987',
    title: 'At risk of churning',
    description: 'Gold member with declining order frequency. Consider win-back offer.',
    dueDate: '2026-02-18',
    dismissed: false,
    createdAt: '2026-02-18T08:00:00Z',
  },
];

export const MOCK_LOYALTY_TRANSACTIONS: LoyaltyTransaction[] = [
  {
    id: 'lt-001',
    customerId: 'cust-001',
    type: 'EARN',
    points: 55,
    balance: 2450,
    description: 'Order #ORD-2026-0215',
    orderId: 'ord-001',
    createdAt: '2026-02-14T14:30:00Z',
  },
  {
    id: 'lt-002',
    customerId: 'cust-001',
    type: 'EARN',
    points: 32,
    balance: 2395,
    description: 'Order #ORD-2026-0180',
    orderId: 'ord-002',
    createdAt: '2026-02-10T11:00:00Z',
  },
  {
    id: 'lt-003',
    customerId: 'cust-001',
    type: 'REDEEM',
    points: -200,
    balance: 2363,
    description: 'Redeemed for discount',
    orderId: 'ord-003',
    createdAt: '2026-01-25T16:00:00Z',
  },
  {
    id: 'lt-004',
    customerId: 'cust-001',
    type: 'BONUS',
    points: 50,
    balance: 2563,
    description: 'Birthday bonus',
    createdAt: '2025-03-15T00:00:00Z',
  },
];
