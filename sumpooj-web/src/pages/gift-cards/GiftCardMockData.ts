/**
 * Gift Card Mock Data
 * Test data for Gift Card module
 * Florist POS + ERP SaaS Platform
 */

import type { SavedGiftCard } from './GiftCardTypes';

const today = new Date();
const isoDate = (d: Date) => d.toISOString().slice(0, 10);
const daysFrom = (n: number) => {
  const d = new Date(today);
  d.setDate(d.getDate() + n);
  return d.toISOString();
};
const daysAgo = (n: number) => daysFrom(-n);

// ─── Mock Gift Cards ────────────────────────────────────────

export interface MockGiftCard {
  id: string;
  code: string;
  initialBalance: number;
  currentBalance: number;
  status: 'ACTIVE' | 'REDEEMED' | 'EXPIRED' | 'CANCELLED';
  recipientName?: string;
  recipientEmail?: string;
  recipientPhone?: string;
  senderName?: string;
  personalMessage?: string;
  occasion?: string;
  designTheme?: string;
  createdAt: string;
  expiresAt?: string;
  lastUsedAt?: string;
  orderId?: string;
  redeemedAmount: number;
  transactionHistory: GiftCardTransaction[];
}

export interface GiftCardTransaction {
  id: string;
  type: 'ISSUED' | 'REDEEMED' | 'REFUND' | 'TOPUP';
  amount: number;
  balanceAfter: number;
  orderId?: string;
  orderNumber?: string;
  note?: string;
  createdAt: string;
  performedBy: string;
}

export const MOCK_GIFT_CARDS: MockGiftCard[] = [
  {
    id: 'gc_001',
    code: 'GIFT-2026-A1B2C3',
    initialBalance: 5000,
    currentBalance: 3250,
    status: 'ACTIVE',
    recipientName: 'Priya Sharma',
    recipientEmail: 'priya@email.com',
    recipientPhone: '+91 98765 43210',
    senderName: 'Rahul Verma',
    personalMessage: 'Happy Birthday! Hope you have a wonderful day filled with flowers!',
    occasion: 'birthday',
    designTheme: 'rose-light',
    createdAt: daysAgo(30),
    expiresAt: daysFrom(335),
    lastUsedAt: daysAgo(5),
    redeemedAmount: 1750,
    transactionHistory: [
      { id: 'tx_001', type: 'ISSUED', amount: 5000, balanceAfter: 5000, note: 'Gift card issued', createdAt: daysAgo(30), performedBy: 'System' },
      { id: 'tx_002', type: 'REDEEMED', amount: -1200, balanceAfter: 3800, orderId: 'ord_101', orderNumber: 'ORD-2026-0101', createdAt: daysAgo(15), performedBy: 'Anita Sharma' },
      { id: 'tx_003', type: 'REDEEMED', amount: -550, balanceAfter: 3250, orderId: 'ord_115', orderNumber: 'ORD-2026-0115', createdAt: daysAgo(5), performedBy: 'Priya Patel' },
    ],
  },
  {
    id: 'gc_002',
    code: 'GIFT-2026-D4E5F6',
    initialBalance: 10000,
    currentBalance: 10000,
    status: 'ACTIVE',
    recipientName: 'Anita Desai',
    senderName: 'Corporate Gifting - TechCorp',
    personalMessage: 'Thank you for your partnership!',
    occasion: 'thank_you',
    designTheme: 'gold-elegant',
    createdAt: daysAgo(7),
    expiresAt: daysFrom(358),
    redeemedAmount: 0,
    transactionHistory: [
      { id: 'tx_004', type: 'ISSUED', amount: 10000, balanceAfter: 10000, note: 'Corporate gift card', createdAt: daysAgo(7), performedBy: 'Ravi Kumar' },
    ],
  },
  {
    id: 'gc_003',
    code: 'GIFT-2026-G7H8I9',
    initialBalance: 2500,
    currentBalance: 0,
    status: 'REDEEMED',
    recipientName: 'Vikram Singh',
    recipientPhone: '+91 87654 32109',
    senderName: 'Family',
    personalMessage: 'Wishing you a speedy recovery!',
    occasion: 'get_well',
    designTheme: 'watercolor-soft',
    createdAt: daysAgo(45),
    expiresAt: daysFrom(320),
    lastUsedAt: daysAgo(10),
    redeemedAmount: 2500,
    transactionHistory: [
      { id: 'tx_005', type: 'ISSUED', amount: 2500, balanceAfter: 2500, note: 'Gift card issued', createdAt: daysAgo(45), performedBy: 'System' },
      { id: 'tx_006', type: 'REDEEMED', amount: -1500, balanceAfter: 1000, orderId: 'ord_089', orderNumber: 'ORD-2026-0089', createdAt: daysAgo(30), performedBy: 'Neha Gupta' },
      { id: 'tx_007', type: 'REDEEMED', amount: -1000, balanceAfter: 0, orderId: 'ord_098', orderNumber: 'ORD-2026-0098', createdAt: daysAgo(10), performedBy: 'Sameer Das' },
    ],
  },
  {
    id: 'gc_004',
    code: 'GIFT-2025-J0K1L2',
    initialBalance: 3000,
    currentBalance: 1800,
    status: 'EXPIRED',
    recipientName: 'Meera Patel',
    recipientEmail: 'meera.p@email.com',
    senderName: 'Best Wishes',
    occasion: 'anniversary',
    designTheme: 'peach-blush',
    createdAt: daysAgo(400),
    expiresAt: daysAgo(35),
    lastUsedAt: daysAgo(100),
    redeemedAmount: 1200,
    transactionHistory: [
      { id: 'tx_008', type: 'ISSUED', amount: 3000, balanceAfter: 3000, note: 'Anniversary gift', createdAt: daysAgo(400), performedBy: 'System' },
      { id: 'tx_009', type: 'REDEEMED', amount: -1200, balanceAfter: 1800, orderId: 'ord_045', orderNumber: 'ORD-2025-0045', createdAt: daysAgo(100), performedBy: 'Anita Sharma' },
    ],
  },
  {
    id: 'gc_005',
    code: 'GIFT-2026-M3N4O5',
    initialBalance: 7500,
    currentBalance: 5000,
    status: 'ACTIVE',
    recipientName: 'Neha Kapoor',
    recipientEmail: 'neha.kapoor@company.com',
    recipientPhone: '+91 76543 21098',
    senderName: 'Wedding Wishes - The Sharma Family',
    personalMessage: 'Congratulations on your wedding! May your life bloom with happiness.',
    occasion: 'wedding',
    designTheme: 'lavender-soft',
    createdAt: daysAgo(20),
    expiresAt: daysFrom(345),
    lastUsedAt: daysAgo(3),
    redeemedAmount: 2500,
    transactionHistory: [
      { id: 'tx_010', type: 'ISSUED', amount: 7500, balanceAfter: 7500, note: 'Wedding gift card', createdAt: daysAgo(20), performedBy: 'Ravi Kumar' },
      { id: 'tx_011', type: 'REDEEMED', amount: -2500, balanceAfter: 5000, orderId: 'ord_122', orderNumber: 'ORD-2026-0122', createdAt: daysAgo(3), performedBy: 'Priya Patel' },
    ],
  },
  {
    id: 'gc_006',
    code: 'GIFT-2026-P6Q7R8',
    initialBalance: 1500,
    currentBalance: 1500,
    status: 'CANCELLED',
    recipientName: 'Test Customer',
    senderName: 'Admin',
    occasion: 'custom',
    createdAt: daysAgo(15),
    redeemedAmount: 0,
    transactionHistory: [
      { id: 'tx_012', type: 'ISSUED', amount: 1500, balanceAfter: 1500, note: 'Test card - cancelled', createdAt: daysAgo(15), performedBy: 'Admin' },
    ],
  },
  {
    id: 'gc_007',
    code: 'GIFT-2026-S9T0U1',
    initialBalance: 2000,
    currentBalance: 2500,
    status: 'ACTIVE',
    recipientName: 'Arun Mehta',
    recipientPhone: '+91 65432 10987',
    senderName: 'Store Promotion',
    personalMessage: 'Thank you for being our valued customer!',
    occasion: 'thank_you',
    designTheme: 'modern-minimal',
    createdAt: daysAgo(10),
    expiresAt: daysFrom(355),
    redeemedAmount: 0,
    transactionHistory: [
      { id: 'tx_013', type: 'ISSUED', amount: 2000, balanceAfter: 2000, note: 'Loyalty reward card', createdAt: daysAgo(10), performedBy: 'System' },
      { id: 'tx_014', type: 'TOPUP', amount: 500, balanceAfter: 2500, note: 'Bonus points converted', createdAt: daysAgo(5), performedBy: 'Anita Sharma' },
    ],
  },
  {
    id: 'gc_008',
    code: 'GIFT-2026-V2W3X4',
    initialBalance: 4000,
    currentBalance: 4000,
    status: 'ACTIVE',
    recipientName: 'New Baby Celebration',
    recipientEmail: 'parents@email.com',
    senderName: 'Office Colleagues',
    personalMessage: 'Congratulations on the new addition to your family!',
    occasion: 'new_baby',
    designTheme: 'corner-floral',
    createdAt: daysAgo(2),
    expiresAt: daysFrom(363),
    redeemedAmount: 0,
    transactionHistory: [
      { id: 'tx_015', type: 'ISSUED', amount: 4000, balanceAfter: 4000, note: 'New baby celebration gift', createdAt: daysAgo(2), performedBy: 'Neha Gupta' },
    ],
  },
];

// ─── Gift Card Summary Stats ────────────────────────────────

export interface GiftCardSummary {
  totalIssued: number;
  totalActive: number;
  totalRedeemed: number;
  totalExpired: number;
  totalCancelled: number;
  totalValueIssued: number;
  totalValueRedeemed: number;
  totalValueOutstanding: number;
  averageCardValue: number;
  redemptionRate: number;
}

export const calculateGiftCardSummary = (cards: MockGiftCard[]): GiftCardSummary => {
  const summary: GiftCardSummary = {
    totalIssued: cards.length,
    totalActive: cards.filter(c => c.status === 'ACTIVE').length,
    totalRedeemed: cards.filter(c => c.status === 'REDEEMED').length,
    totalExpired: cards.filter(c => c.status === 'EXPIRED').length,
    totalCancelled: cards.filter(c => c.status === 'CANCELLED').length,
    totalValueIssued: cards.reduce((sum, c) => sum + c.initialBalance, 0),
    totalValueRedeemed: cards.reduce((sum, c) => sum + c.redeemedAmount, 0),
    totalValueOutstanding: cards.filter(c => c.status === 'ACTIVE').reduce((sum, c) => sum + c.currentBalance, 0),
    averageCardValue: 0,
    redemptionRate: 0,
  };
  summary.averageCardValue = summary.totalValueIssued / summary.totalIssued;
  summary.redemptionRate = (summary.totalValueRedeemed / summary.totalValueIssued) * 100;
  return summary;
};

export const MOCK_GIFT_CARD_SUMMARY = calculateGiftCardSummary(MOCK_GIFT_CARDS);

// ─── Mock API Functions ─────────────────────────────────────

export const fetchGiftCards = (): Promise<MockGiftCard[]> =>
  new Promise(resolve => setTimeout(() => resolve([...MOCK_GIFT_CARDS]), 500));

export const fetchGiftCardByCode = (code: string): Promise<MockGiftCard | null> =>
  new Promise(resolve => setTimeout(() => {
    const card = MOCK_GIFT_CARDS.find(c => c.code === code);
    resolve(card || null);
  }, 300));

export const fetchGiftCardSummary = (): Promise<GiftCardSummary> =>
  new Promise(resolve => setTimeout(() => resolve(MOCK_GIFT_CARD_SUMMARY), 300));
