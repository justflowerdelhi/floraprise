/**
 * ProposalTypes.ts — Proposal Builder Type Definitions
 *
 * Phase 2: Proposal Builder with Margin Intelligence
 * Defines strict TypeScript interfaces for proposal management.
 */

// ─── Proposal Status ────────────────────────────────────────

export type ProposalStatus = 'DRAFT' | 'SENT' | 'APPROVED' | 'REJECTED';

export const PROPOSAL_STATUSES: ProposalStatus[] = ['DRAFT', 'SENT', 'APPROVED', 'REJECTED'];

// ─── Proposal Item Type ─────────────────────────────────────

export type ProposalItemType = 'PRODUCT' | 'SERVICE' | 'PACKAGE';

export const PROPOSAL_ITEM_TYPES: ProposalItemType[] = ['PRODUCT', 'SERVICE', 'PACKAGE'];

// ─── Proposal Item Interface ────────────────────────────────

export interface ProposalItem {
  id: string;
  type: ProposalItemType;
  name: string;
  description?: string;
  linkedProductId?: string;
  linkedProductSku?: string;
  quantity: number;
  unitPrice: number;
  unitCost: number;
  totalPrice: number; // quantity * unitPrice
  totalCost: number; // quantity * unitCost
  marginPercentage: number; // ((totalPrice - totalCost) / totalPrice) * 100
}

// ─── Proposal Interface ─────────────────────────────────────

export interface Proposal {
  id: string;
  eventId: string;
  eventName?: string; // Denormalized for display
  versionName: string;
  versionNumber: number;
  status: ProposalStatus;
  items: ProposalItem[];
  subtotal: number;
  discountType: 'PERCENTAGE' | 'FIXED';
  discountValue: number;
  discount: number; // Calculated discount amount
  taxRate: number;
  tax: number; // Calculated tax amount
  grandTotal: number;
  totalCost: number;
  grossProfit: number;
  marginPercentage: number;
  notes?: string;
  validUntil?: string;
  createdAt: string;
  updatedAt: string;
  sentAt?: string;
  approvedAt?: string;
}

// ─── Proposal Form Data ─────────────────────────────────────

export interface ProposalFormData {
  versionName: string;
  discountType: 'PERCENTAGE' | 'FIXED';
  discountValue: string;
  taxRate: string;
  notes: string;
  validUntil: string;
}

// ─── Status Configuration ───────────────────────────────────

export interface ProposalStatusConfig {
  label: string;
  color: string;
  bgColor: string;
  icon: string;
  description: string;
}

export const PROPOSAL_STATUS_CONFIG: Record<ProposalStatus, ProposalStatusConfig> = {
  DRAFT: {
    label: 'Draft',
    color: '#9e9e9e',
    bgColor: 'rgba(158, 158, 158, 0.12)',
    icon: '📝',
    description: 'Work in progress',
  },
  SENT: {
    label: 'Sent',
    color: '#2196f3',
    bgColor: 'rgba(33, 150, 243, 0.12)',
    icon: '📤',
    description: 'Sent to client',
  },
  APPROVED: {
    label: 'Approved',
    color: '#4caf50',
    bgColor: 'rgba(76, 175, 80, 0.12)',
    icon: '✅',
    description: 'Client approved',
  },
  REJECTED: {
    label: 'Rejected',
    color: '#f44336',
    bgColor: 'rgba(244, 67, 54, 0.12)',
    icon: '❌',
    description: 'Client rejected',
  },
};

// ─── Item Type Configuration ────────────────────────────────

export interface ItemTypeConfig {
  label: string;
  color: string;
  icon: string;
  description: string;
}

export const ITEM_TYPE_CONFIG: Record<ProposalItemType, ItemTypeConfig> = {
  PRODUCT: {
    label: 'Product',
    color: '#4caf50',
    icon: '🌸',
    description: 'Flower arrangement or product from inventory',
  },
  SERVICE: {
    label: 'Service',
    color: '#2196f3',
    icon: '🛠️',
    description: 'Labor, setup, delivery, or other service',
  },
  PACKAGE: {
    label: 'Package',
    color: '#9c27b0',
    icon: '📦',
    description: 'Bundled items at a package price',
  },
};

// ─── Margin Thresholds ──────────────────────────────────────

export const MARGIN_THRESHOLDS = {
  HEALTHY: 30, // >= 30% is green
  WARNING: 20, // >= 20% is yellow
  DANGER: 0, // < 20% is red
};

export const getMarginColor = (margin: number): string => {
  if (margin >= MARGIN_THRESHOLDS.HEALTHY) return '#4caf50'; // Green
  if (margin >= MARGIN_THRESHOLDS.WARNING) return '#ff9800'; // Yellow/Orange
  return '#f44336'; // Red
};

export const getMarginStatus = (margin: number): 'healthy' | 'warning' | 'danger' => {
  if (margin >= MARGIN_THRESHOLDS.HEALTHY) return 'healthy';
  if (margin >= MARGIN_THRESHOLDS.WARNING) return 'warning';
  return 'danger';
};

// ─── Utility Functions ──────────────────────────────────────

export const calculateItemMargin = (unitPrice: number, unitCost: number): number => {
  if (unitPrice <= 0) return 0;
  return ((unitPrice - unitCost) / unitPrice) * 100;
};

export const calculateItemTotals = (
  quantity: number,
  unitPrice: number,
  unitCost: number
): { totalPrice: number; totalCost: number; marginPercentage: number } => {
  const totalPrice = quantity * unitPrice;
  const totalCost = quantity * unitCost;
  const marginPercentage = totalPrice > 0 ? ((totalPrice - totalCost) / totalPrice) * 100 : 0;
  return { totalPrice, totalCost, marginPercentage };
};

export const calculateProposalTotals = (
  items: ProposalItem[],
  discountType: 'PERCENTAGE' | 'FIXED',
  discountValue: number,
  taxRate: number
): {
  subtotal: number;
  discount: number;
  tax: number;
  grandTotal: number;
  totalCost: number;
  grossProfit: number;
  marginPercentage: number;
} => {
  const subtotal = items.reduce((sum, item) => sum + item.totalPrice, 0);
  const totalCost = items.reduce((sum, item) => sum + item.totalCost, 0);

  // Calculate discount
  const discount = discountType === 'PERCENTAGE' ? (subtotal * discountValue) / 100 : discountValue;

  // Calculate tax on discounted amount
  const taxableAmount = subtotal - discount;
  const tax = (taxableAmount * taxRate) / 100;

  // Calculate grand total
  const grandTotal = taxableAmount + tax;

  // Calculate profit and margin
  const grossProfit = grandTotal - totalCost;
  const marginPercentage = grandTotal > 0 ? (grossProfit / grandTotal) * 100 : 0;

  return {
    subtotal,
    discount,
    tax,
    grandTotal,
    totalCost,
    grossProfit,
    marginPercentage,
  };
};

export const createNewItem = (type: ProposalItemType = 'PRODUCT'): ProposalItem => ({
  id: `item-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`,
  type,
  name: '',
  quantity: 1,
  unitPrice: 0,
  unitCost: 0,
  totalPrice: 0,
  totalCost: 0,
  marginPercentage: 0,
});

export const getInitialProposalFormData = (proposal?: Proposal): ProposalFormData => ({
  versionName: proposal?.versionName ?? 'Version 1',
  discountType: proposal?.discountType ?? 'PERCENTAGE',
  discountValue: proposal?.discountValue?.toString() ?? '0',
  taxRate: proposal?.taxRate?.toString() ?? '18',
  notes: proposal?.notes ?? '',
  validUntil: proposal?.validUntil ?? '',
});

// ─── Version History Entry ──────────────────────────────────

export interface ProposalVersion {
  id: string;
  versionNumber: number;
  versionName: string;
  status: ProposalStatus;
  grandTotal: number;
  marginPercentage: number;
  createdAt: string;
  changedBy?: string;
}

// ─── Service Presets ────────────────────────────────────────

export interface ServicePreset {
  id: string;
  name: string;
  description: string;
  defaultPrice: number;
  defaultCost: number;
}

export const SERVICE_PRESETS: ServicePreset[] = [
  { id: 'svc-delivery', name: 'Delivery & Setup', description: 'On-site delivery and arrangement setup', defaultPrice: 2000, defaultCost: 800 },
  { id: 'svc-consultation', name: 'Design Consultation', description: 'Initial design consultation (1 hour)', defaultPrice: 1500, defaultCost: 500 },
  { id: 'svc-site-visit', name: 'Site Visit', description: 'Venue inspection and measurements', defaultPrice: 2500, defaultCost: 1000 },
  { id: 'svc-setup-large', name: 'Large Setup', description: 'Setup for events > 200 guests', defaultPrice: 8000, defaultCost: 3500 },
  { id: 'svc-breakdown', name: 'Breakdown & Cleanup', description: 'Post-event breakdown and cleanup', defaultPrice: 3000, defaultCost: 1200 },
  { id: 'svc-rental', name: 'Vase/Container Rental', description: 'Rental of premium vases and containers', defaultPrice: 5000, defaultCost: 1000 },
];

// ─── Package Presets ────────────────────────────────────────

export interface PackagePreset {
  id: string;
  name: string;
  description: string;
  defaultPrice: number;
  defaultCost: number;
  includedItems: string[];
}

export const PACKAGE_PRESETS: PackagePreset[] = [
  {
    id: 'pkg-basic-wedding',
    name: 'Basic Wedding Package',
    description: 'Essential floral for intimate weddings',
    defaultPrice: 35000,
    defaultCost: 18000,
    includedItems: ['Bridal Bouquet', '2 Bridesmaids Bouquets', '5 Boutonnieres', 'Altar Arrangement'],
  },
  {
    id: 'pkg-premium-wedding',
    name: 'Premium Wedding Package',
    description: 'Full floral experience for medium weddings',
    defaultPrice: 85000,
    defaultCost: 42000,
    includedItems: ['Bridal Bouquet', '4 Bridesmaids Bouquets', '10 Boutonnieres', 'Mandap Decor', '10 Table Centerpieces', 'Entrance Decor'],
  },
  {
    id: 'pkg-luxury-wedding',
    name: 'Luxury Wedding Package',
    description: 'Premium decor for grand weddings',
    defaultPrice: 180000,
    defaultCost: 85000,
    includedItems: ['Everything in Premium', 'Stage Backdrop', '20 Table Centerpieces', 'Photo Booth Decor', 'Car Decor', 'VIP Lounge Decor'],
  },
  {
    id: 'pkg-corporate-basic',
    name: 'Corporate Basic Package',
    description: 'Professional florals for corporate events',
    defaultPrice: 25000,
    defaultCost: 12000,
    includedItems: ['Reception Arrangement', '5 Table Centerpieces', 'Stage Flowers'],
  },
];
