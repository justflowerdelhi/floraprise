/**
 * ProposalMockData.ts — Mock Data for Proposal Builder
 */
import type { Proposal, ProposalVersion } from './ProposalTypes';

// ─── Product Catalog for Proposals ──────────────────────────

export interface ProductOption {
  id: string;
  name: string;
  sku: string;
  category: string;
  sellingPrice: number;
  costPrice: number;
  available: boolean;
}

export const PRODUCT_OPTIONS: ProductOption[] = [
  // Fresh Flowers
  { id: 'p01', name: 'Red Roses (Premium)', sku: 'RSP-001', category: 'Fresh Flowers', sellingPrice: 280, costPrice: 120, available: true },
  { id: 'p02', name: 'White Lilies', sku: 'WHL-002', category: 'Fresh Flowers', sellingPrice: 350, costPrice: 160, available: true },
  { id: 'p03', name: 'Sunflowers', sku: 'SNF-003', category: 'Fresh Flowers', sellingPrice: 190, costPrice: 80, available: true },
  { id: 'p08', name: "Baby's Breath", sku: 'BBR-006', category: 'Fresh Flowers', sellingPrice: 60, costPrice: 22, available: true },
  { id: 'p09', name: 'Carnations (Mixed)', sku: 'CRN-007', category: 'Fresh Flowers', sellingPrice: 85, costPrice: 35, available: true },
  { id: 'p10', name: 'Gerbera Daisies', sku: 'GRB-008', category: 'Fresh Flowers', sellingPrice: 150, costPrice: 65, available: true },
  { id: 'p11', name: 'Marigolds', sku: 'MRG-009', category: 'Fresh Flowers', sellingPrice: 45, costPrice: 18, available: true },
  { id: 'p12', name: 'Jasmine Strings', sku: 'JSM-010', category: 'Fresh Flowers', sellingPrice: 120, costPrice: 50, available: true },

  // Bouquets
  { id: 'p04', name: 'Classic Rose Bouquet', sku: 'CRB-010', category: 'Bouquets', sellingPrice: 850, costPrice: 380, available: true },
  { id: 'p13', name: 'Bridal Bouquet (Premium)', sku: 'BRB-015', category: 'Bouquets', sellingPrice: 3500, costPrice: 1400, available: true },
  { id: 'p14', name: 'Bridesmaid Bouquet', sku: 'BMB-016', category: 'Bouquets', sellingPrice: 1800, costPrice: 720, available: true },
  { id: 'p15', name: 'Boutonniere', sku: 'BTN-017', category: 'Bouquets', sellingPrice: 350, costPrice: 120, available: true },
  { id: 'p16', name: 'Corsage', sku: 'CRS-018', category: 'Bouquets', sellingPrice: 450, costPrice: 160, available: true },

  // Arrangements
  { id: 'p05', name: 'Spring Garden Arrangement', sku: 'SGA-011', category: 'Arrangements', sellingPrice: 1200, costPrice: 520, available: true },
  { id: 'p17', name: 'Table Centerpiece', sku: 'TCP-020', category: 'Arrangements', sellingPrice: 2500, costPrice: 980, available: true },
  { id: 'p18', name: 'Stage Arrangement (Large)', sku: 'SAL-021', category: 'Arrangements', sellingPrice: 8500, costPrice: 3400, available: true },
  { id: 'p19', name: 'Altar/Mandap Arrangement', sku: 'AMA-022', category: 'Arrangements', sellingPrice: 15000, costPrice: 6000, available: true },
  { id: 'p20', name: 'Entrance Arch', sku: 'ENA-023', category: 'Arrangements', sellingPrice: 25000, costPrice: 10000, available: true },
  { id: 'p21', name: 'Photo Booth Backdrop', sku: 'PBB-024', category: 'Arrangements', sellingPrice: 18000, costPrice: 7200, available: true },

  // Greens & Foliage
  { id: 'p07', name: 'Eucalyptus Bunch', sku: 'EUC-005', category: 'Greens & Foliage', sellingPrice: 210, costPrice: 90, available: true },
  { id: 'p22', name: 'Fern Bunch', sku: 'FRN-025', category: 'Greens & Foliage', sellingPrice: 180, costPrice: 70, available: true },
  { id: 'p23', name: 'Palm Leaves', sku: 'PLM-026', category: 'Greens & Foliage', sellingPrice: 250, costPrice: 100, available: true },

  // Plants
  { id: 'p06', name: 'Orchid Phalaenopsis', sku: 'ORC-004', category: 'Plants', sellingPrice: 550, costPrice: 280, available: true },
  { id: 'p24', name: 'Money Plant (Large)', sku: 'MNP-027', category: 'Plants', sellingPrice: 400, costPrice: 150, available: true },
];

// ─── Mock Proposals ─────────────────────────────────────────

export const MOCK_PROPOSALS: Proposal[] = [
  {
    id: 'prop-001',
    eventId: 'evt-001',
    eventName: 'Sharma-Patel Wedding',
    versionName: 'Final Quote v3',
    versionNumber: 3,
    status: 'APPROVED',
    items: [
      {
        id: 'item-001',
        type: 'PRODUCT',
        name: 'Bridal Bouquet (Premium)',
        linkedProductId: 'p13',
        linkedProductSku: 'BRB-015',
        quantity: 1,
        unitPrice: 3500,
        unitCost: 1400,
        totalPrice: 3500,
        totalCost: 1400,
        marginPercentage: 60,
      },
      {
        id: 'item-002',
        type: 'PRODUCT',
        name: 'Bridesmaid Bouquet',
        linkedProductId: 'p14',
        linkedProductSku: 'BMB-016',
        quantity: 6,
        unitPrice: 1800,
        unitCost: 720,
        totalPrice: 10800,
        totalCost: 4320,
        marginPercentage: 60,
      },
      {
        id: 'item-003',
        type: 'PRODUCT',
        name: 'Boutonniere',
        linkedProductId: 'p15',
        linkedProductSku: 'BTN-017',
        quantity: 10,
        unitPrice: 350,
        unitCost: 120,
        totalPrice: 3500,
        totalCost: 1200,
        marginPercentage: 65.71,
      },
      {
        id: 'item-004',
        type: 'PRODUCT',
        name: 'Altar/Mandap Arrangement',
        linkedProductId: 'p19',
        linkedProductSku: 'AMA-022',
        quantity: 1,
        unitPrice: 45000,
        unitCost: 18000,
        totalPrice: 45000,
        totalCost: 18000,
        marginPercentage: 60,
      },
      {
        id: 'item-005',
        type: 'PRODUCT',
        name: 'Table Centerpiece',
        linkedProductId: 'p17',
        linkedProductSku: 'TCP-020',
        quantity: 25,
        unitPrice: 2500,
        unitCost: 980,
        totalPrice: 62500,
        totalCost: 24500,
        marginPercentage: 60.8,
      },
      {
        id: 'item-006',
        type: 'PRODUCT',
        name: 'Entrance Arch',
        linkedProductId: 'p20',
        linkedProductSku: 'ENA-023',
        quantity: 2,
        unitPrice: 25000,
        unitCost: 10000,
        totalPrice: 50000,
        totalCost: 20000,
        marginPercentage: 60,
      },
      {
        id: 'item-007',
        type: 'SERVICE',
        name: 'Delivery & Setup',
        quantity: 1,
        unitPrice: 8000,
        unitCost: 3500,
        totalPrice: 8000,
        totalCost: 3500,
        marginPercentage: 56.25,
      },
      {
        id: 'item-008',
        type: 'SERVICE',
        name: 'Site Visit',
        quantity: 2,
        unitPrice: 2500,
        unitCost: 1000,
        totalPrice: 5000,
        totalCost: 2000,
        marginPercentage: 60,
      },
    ],
    subtotal: 188300,
    discountType: 'PERCENTAGE',
    discountValue: 5,
    discount: 9415,
    taxRate: 18,
    tax: 32199.3,
    grandTotal: 211084.3,
    totalCost: 74920,
    grossProfit: 136164.3,
    marginPercentage: 64.51,
    notes: 'VIP client - please ensure premium quality flowers. Setup starts 6 AM on event day.',
    validUntil: '2026-02-28',
    createdAt: '2026-01-15T10:00:00Z',
    updatedAt: '2026-01-25T14:30:00Z',
    sentAt: '2026-01-25T15:00:00Z',
    approvedAt: '2026-01-28T11:00:00Z',
  },
  {
    id: 'prop-002',
    eventId: 'evt-002',
    eventName: 'TechCorp Annual Gala',
    versionName: 'v2 - Updated',
    versionNumber: 2,
    status: 'SENT',
    items: [
      {
        id: 'item-009',
        type: 'PRODUCT',
        name: 'Table Centerpiece',
        linkedProductId: 'p17',
        linkedProductSku: 'TCP-020',
        quantity: 20,
        unitPrice: 2200,
        unitCost: 980,
        totalPrice: 44000,
        totalCost: 19600,
        marginPercentage: 55.45,
      },
      {
        id: 'item-010',
        type: 'PRODUCT',
        name: 'Stage Arrangement (Large)',
        linkedProductId: 'p18',
        linkedProductSku: 'SAL-021',
        quantity: 2,
        unitPrice: 8500,
        unitCost: 3400,
        totalPrice: 17000,
        totalCost: 6800,
        marginPercentage: 60,
      },
      {
        id: 'item-011',
        type: 'PRODUCT',
        name: 'Orchid Phalaenopsis',
        linkedProductId: 'p06',
        linkedProductSku: 'ORC-004',
        quantity: 15,
        unitPrice: 550,
        unitCost: 280,
        totalPrice: 8250,
        totalCost: 4200,
        marginPercentage: 49.09,
      },
      {
        id: 'item-012',
        type: 'SERVICE',
        name: 'Delivery & Setup',
        quantity: 1,
        unitPrice: 5000,
        unitCost: 2000,
        totalPrice: 5000,
        totalCost: 2000,
        marginPercentage: 60,
      },
    ],
    subtotal: 74250,
    discountType: 'FIXED',
    discountValue: 5000,
    discount: 5000,
    taxRate: 18,
    tax: 12465,
    grandTotal: 81715,
    totalCost: 32600,
    grossProfit: 49115,
    marginPercentage: 60.11,
    notes: 'Corporate event - minimalist elegant look. All white/green color scheme.',
    validUntil: '2026-02-20',
    createdAt: '2026-02-01T09:00:00Z',
    updatedAt: '2026-02-05T11:00:00Z',
    sentAt: '2026-02-05T11:30:00Z',
  },
  {
    id: 'prop-003',
    eventId: 'evt-003',
    eventName: 'Gupta Birthday Celebration',
    versionName: 'Initial Quote',
    versionNumber: 1,
    status: 'DRAFT',
    items: [
      {
        id: 'item-013',
        type: 'PRODUCT',
        name: 'Spring Garden Arrangement',
        linkedProductId: 'p05',
        linkedProductSku: 'SGA-011',
        quantity: 3,
        unitPrice: 1200,
        unitCost: 520,
        totalPrice: 3600,
        totalCost: 1560,
        marginPercentage: 56.67,
      },
      {
        id: 'item-014',
        type: 'PRODUCT',
        name: 'Table Centerpiece',
        linkedProductId: 'p17',
        linkedProductSku: 'TCP-020',
        quantity: 5,
        unitPrice: 2000,
        unitCost: 980,
        totalPrice: 10000,
        totalCost: 4900,
        marginPercentage: 51,
      },
      {
        id: 'item-015',
        type: 'SERVICE',
        name: 'Delivery & Setup',
        quantity: 1,
        unitPrice: 2000,
        unitCost: 800,
        totalPrice: 2000,
        totalCost: 800,
        marginPercentage: 60,
      },
    ],
    subtotal: 15600,
    discountType: 'PERCENTAGE',
    discountValue: 0,
    discount: 0,
    taxRate: 18,
    tax: 2808,
    grandTotal: 18408,
    totalCost: 7260,
    grossProfit: 11148,
    marginPercentage: 60.56,
    notes: '',
    validUntil: '',
    createdAt: '2026-02-10T14:00:00Z',
    updatedAt: '2026-02-10T14:00:00Z',
  },
  {
    id: 'prop-004',
    eventId: 'evt-005',
    eventName: 'Kapoor-Singh Wedding',
    versionName: 'Draft Quote',
    versionNumber: 1,
    status: 'DRAFT',
    items: [
      {
        id: 'item-016',
        type: 'PACKAGE',
        name: 'Premium Wedding Package',
        description: 'Full floral experience',
        quantity: 1,
        unitPrice: 85000,
        unitCost: 42000,
        totalPrice: 85000,
        totalCost: 42000,
        marginPercentage: 50.59,
      },
      {
        id: 'item-017',
        type: 'PRODUCT',
        name: 'Entrance Arch',
        linkedProductId: 'p20',
        linkedProductSku: 'ENA-023',
        quantity: 1,
        unitPrice: 25000,
        unitCost: 10000,
        totalPrice: 25000,
        totalCost: 10000,
        marginPercentage: 60,
      },
    ],
    subtotal: 110000,
    discountType: 'PERCENTAGE',
    discountValue: 0,
    discount: 0,
    taxRate: 18,
    tax: 19800,
    grandTotal: 129800,
    totalCost: 52000,
    grossProfit: 77800,
    marginPercentage: 59.94,
    notes: 'Awaiting client venue confirmation before finalizing.',
    validUntil: '',
    createdAt: '2026-02-18T10:00:00Z',
    updatedAt: '2026-02-18T10:00:00Z',
  },
];

// ─── Version History ────────────────────────────────────────

export const MOCK_VERSION_HISTORY: Record<string, ProposalVersion[]> = {
  'prop-001': [
    {
      id: 'prop-001-v1',
      versionNumber: 1,
      versionName: 'Initial Quote',
      status: 'DRAFT',
      grandTotal: 165000,
      marginPercentage: 58.2,
      createdAt: '2026-01-15T10:00:00Z',
      changedBy: 'Meera Patel',
    },
    {
      id: 'prop-001-v2',
      versionNumber: 2,
      versionName: 'Revised - More Centerpieces',
      status: 'SENT',
      grandTotal: 195000,
      marginPercentage: 62.1,
      createdAt: '2026-01-20T14:00:00Z',
      changedBy: 'Meera Patel',
    },
    {
      id: 'prop-001-v3',
      versionNumber: 3,
      versionName: 'Final Quote v3',
      status: 'APPROVED',
      grandTotal: 211084.3,
      marginPercentage: 64.51,
      createdAt: '2026-01-25T14:30:00Z',
      changedBy: 'Raj Kumar',
    },
  ],
  'prop-002': [
    {
      id: 'prop-002-v1',
      versionNumber: 1,
      versionName: 'Initial Quote',
      status: 'REJECTED',
      grandTotal: 95000,
      marginPercentage: 55.5,
      createdAt: '2026-01-28T09:00:00Z',
      changedBy: 'Ananya Sharma',
    },
    {
      id: 'prop-002-v2',
      versionNumber: 2,
      versionName: 'v2 - Updated',
      status: 'SENT',
      grandTotal: 81715,
      marginPercentage: 60.11,
      createdAt: '2026-02-05T11:00:00Z',
      changedBy: 'Ananya Sharma',
    },
  ],
};

// ─── Stats Helpers ──────────────────────────────────────────

export const getProposalStats = (proposals: Proposal[]) => {
  const drafts = proposals.filter((p) => p.status === 'DRAFT').length;
  const sent = proposals.filter((p) => p.status === 'SENT').length;
  const approved = proposals.filter((p) => p.status === 'APPROVED').length;
  const rejected = proposals.filter((p) => p.status === 'REJECTED').length;

  const approvedTotal = proposals
    .filter((p) => p.status === 'APPROVED')
    .reduce((sum, p) => sum + p.grandTotal, 0);

  const avgMargin =
    proposals.length > 0
      ? proposals.reduce((sum, p) => sum + p.marginPercentage, 0) / proposals.length
      : 0;

  return {
    total: proposals.length,
    drafts,
    sent,
    approved,
    rejected,
    approvedTotal,
    avgMargin,
  };
};
