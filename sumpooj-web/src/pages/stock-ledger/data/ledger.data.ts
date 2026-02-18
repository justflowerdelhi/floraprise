/**
 * Stock Movement Ledger — Types, Constants & Mock Data
 * Florist POS + ERP SaaS Platform
 *
 * Tracks every inventory movement: purchases, sales, adjustments, transfers.
 */

// ─── Types ──────────────────────────────────────────────────

export type ReferenceType = 'Purchase' | 'Sale' | 'Adjustment' | 'Transfer';

export interface StockMovement {
  id: string;
  date: string;                 // ISO date-time
  referenceType: ReferenceType;
  referenceNumber: string;
  productId: string;
  productName: string;
  batchNumber: string;
  location: string;
  quantityIn: number;
  quantityOut: number;
  balanceAfter: number;         // running balance (computed during generation)
  costPerUnit: number;
  costImpact: number;           // + for inflow cost, − for outflow cost
  performedBy: string;
  notes: string;
}

export interface LedgerFilterState {
  search: string;
  productId: string;
  dateFrom: string;
  dateTo: string;
  location: string;
  referenceType: ReferenceType | '';
  sortDir: 'asc' | 'desc';
}

export interface LedgerSummary {
  openingBalance: number;
  totalIn: number;
  totalOut: number;
  closingBalance: number;
  totalCostIn: number;
  totalCostOut: number;
}

// ─── Constants ──────────────────────────────────────────────

export const REFERENCE_TYPES: ReferenceType[] = [
  'Purchase',
  'Sale',
  'Adjustment',
  'Transfer',
];

export const LOCATIONS = [
  'Walk-in Cooler A',
  'Walk-in Cooler B',
  'Display Cooler',
  'Dry Storage',
  'Workshop',
  'Front Display',
] as const;

export const STAFF_MEMBERS = [
  'Anita Sharma',
  'Ravi Kumar',
  'Priya Patel',
  'Sameer Das',
  'Neha Gupta',
  'Vikram Singh',
] as const;

export const PRODUCTS = [
  { id: 'prod_001', name: 'Red Roses (Premium)' },
  { id: 'prod_002', name: 'White Lilies' },
  { id: 'prod_003', name: 'Sunflowers' },
  { id: 'prod_004', name: "Baby's Breath" },
  { id: 'prod_005', name: 'Pink Carnations' },
  { id: 'prod_006', name: 'Orchids (Phalaenopsis)' },
  { id: 'prod_007', name: 'Eucalyptus Bunches' },
  { id: 'prod_008', name: 'Tulips (Mixed)' },
  { id: 'prod_009', name: 'Floral Foam Blocks' },
  { id: 'prod_010', name: 'Glass Cylinder Vases' },
  { id: 'prod_011', name: 'Hydrangeas (Blue)' },
  { id: 'prod_012', name: 'Peonies' },
  { id: 'prod_013', name: 'Spray Roses (Peach)' },
] as const;

export const DEFAULT_LEDGER_FILTERS: LedgerFilterState = {
  search: '',
  productId: '',
  dateFrom: '',
  dateTo: '',
  location: '',
  referenceType: '',
  sortDir: 'desc',
};

// ─── Mock Data Generator ────────────────────────────────────

const today = new Date();
const dt = (daysAgo: number, hour = 9, min = 0): string => {
  const d = new Date(today);
  d.setDate(d.getDate() - daysAgo);
  d.setHours(hour, min, 0, 0);
  return d.toISOString();
};

const refNum = (prefix: string, n: number) =>
  `${prefix}-${today.getFullYear()}-${String(n).padStart(4, '0')}`;

/**
 * Generate a realistic set of stock movements across 30 days.
 * The running‐balance is computed per product, chronological order.
 */
const generateMovements = (): StockMovement[] => {
  const raw: Omit<StockMovement, 'balanceAfter'>[] = [
    // ─── Day 30 (opening purchases) ──────────────────────
    { id: 'mv_001', date: dt(30, 8, 15), referenceType: 'Purchase', referenceNumber: refNum('PO', 1001), productId: 'prod_001', productName: 'Red Roses (Premium)', batchNumber: 'BT-2026-0201', location: 'Walk-in Cooler A', quantityIn: 200, quantityOut: 0, costPerUnit: 2.80, costImpact: 560, performedBy: 'Anita Sharma', notes: 'Initial stock from Holland Direct' },
    { id: 'mv_002', date: dt(30, 8, 30), referenceType: 'Purchase', referenceNumber: refNum('PO', 1001), productId: 'prod_002', productName: 'White Lilies', batchNumber: 'BT-2026-0202', location: 'Walk-in Cooler A', quantityIn: 120, quantityOut: 0, costPerUnit: 3.50, costImpact: 420, performedBy: 'Anita Sharma', notes: 'FlowerFresh Imports shipment' },
    { id: 'mv_003', date: dt(30, 9, 0),  referenceType: 'Purchase', referenceNumber: refNum('PO', 1002), productId: 'prod_003', productName: 'Sunflowers', batchNumber: 'BT-2026-0203', location: 'Display Cooler', quantityIn: 80, quantityOut: 0, costPerUnit: 1.90, costImpact: 152, performedBy: 'Ravi Kumar', notes: 'Local Growers Co-op delivery' },
    { id: 'mv_004', date: dt(30, 9, 15), referenceType: 'Purchase', referenceNumber: refNum('PO', 1002), productId: 'prod_005', productName: 'Pink Carnations', batchNumber: 'BT-2026-0205', location: 'Walk-in Cooler A', quantityIn: 150, quantityOut: 0, costPerUnit: 1.20, costImpact: 180, performedBy: 'Ravi Kumar', notes: 'Pacific Blooms order' },
    { id: 'mv_005', date: dt(29, 10, 0), referenceType: 'Purchase', referenceNumber: refNum('PO', 1003), productId: 'prod_004', productName: "Baby's Breath", batchNumber: 'BT-2026-0204', location: 'Walk-in Cooler B', quantityIn: 300, quantityOut: 0, costPerUnit: 0.60, costImpact: 180, performedBy: 'Priya Patel', notes: 'Holland Direct — filler stock' },
    { id: 'mv_006', date: dt(29, 10, 30), referenceType: 'Purchase', referenceNumber: refNum('PO', 1003), productId: 'prod_006', productName: 'Orchids (Phalaenopsis)', batchNumber: 'BT-2026-0206', location: 'Display Cooler', quantityIn: 40, quantityOut: 0, costPerUnit: 8.50, costImpact: 340, performedBy: 'Priya Patel', notes: 'Premium orchids — FlowerFresh Imports' },

    // ─── Day 28 (early sales) ────────────────────────────
    { id: 'mv_007', date: dt(28, 11, 0),  referenceType: 'Sale', referenceNumber: refNum('INV', 2001), productId: 'prod_001', productName: 'Red Roses (Premium)', batchNumber: 'BT-2026-0201', location: 'Walk-in Cooler A', quantityIn: 0, quantityOut: 12, costPerUnit: 2.80, costImpact: -33.60, performedBy: 'Sameer Das', notes: 'Wedding bouquet order #W-101' },
    { id: 'mv_008', date: dt(28, 14, 30), referenceType: 'Sale', referenceNumber: refNum('INV', 2002), productId: 'prod_002', productName: 'White Lilies', batchNumber: 'BT-2026-0202', location: 'Walk-in Cooler A', quantityIn: 0, quantityOut: 5, costPerUnit: 3.50, costImpact: -17.50, performedBy: 'Neha Gupta', notes: 'Walk-in customer' },
    { id: 'mv_009', date: dt(28, 15, 0),  referenceType: 'Sale', referenceNumber: refNum('INV', 2002), productId: 'prod_004', productName: "Baby's Breath", batchNumber: 'BT-2026-0204', location: 'Walk-in Cooler B', quantityIn: 0, quantityOut: 20, costPerUnit: 0.60, costImpact: -12.00, performedBy: 'Neha Gupta', notes: 'Filler with lily order' },

    // ─── Day 25 (transfer + more sales) ─────────────────
    { id: 'mv_010', date: dt(25, 8, 0),  referenceType: 'Transfer', referenceNumber: refNum('TF', 3001), productId: 'prod_001', productName: 'Red Roses (Premium)', batchNumber: 'BT-2026-0201', location: 'Walk-in Cooler A → Front Display', quantityIn: 0, quantityOut: 30, costPerUnit: 2.80, costImpact: 0, performedBy: 'Vikram Singh', notes: 'Move to front display for weekday traffic' },
    { id: 'mv_011', date: dt(25, 9, 30), referenceType: 'Sale', referenceNumber: refNum('INV', 2003), productId: 'prod_005', productName: 'Pink Carnations', batchNumber: 'BT-2026-0205', location: 'Walk-in Cooler A', quantityIn: 0, quantityOut: 25, costPerUnit: 1.20, costImpact: -30.00, performedBy: 'Sameer Das', notes: 'Birthday arrangement order' },
    { id: 'mv_012', date: dt(25, 11, 0), referenceType: 'Sale', referenceNumber: refNum('INV', 2004), productId: 'prod_003', productName: 'Sunflowers', batchNumber: 'BT-2026-0203', location: 'Display Cooler', quantityIn: 0, quantityOut: 15, costPerUnit: 1.90, costImpact: -28.50, performedBy: 'Priya Patel', notes: 'Corporate lobby arrangement' },

    // ─── Day 22 (adjustment — damaged stock) ────────────
    { id: 'mv_013', date: dt(22, 9, 0),  referenceType: 'Adjustment', referenceNumber: refNum('ADJ', 4001), productId: 'prod_001', productName: 'Red Roses (Premium)', batchNumber: 'BT-2026-0201', location: 'Walk-in Cooler A', quantityIn: 0, quantityOut: 8, costPerUnit: 2.80, costImpact: -22.40, performedBy: 'Anita Sharma', notes: 'Damaged during storage — cooler temp spike' },
    { id: 'mv_014', date: dt(22, 9, 15), referenceType: 'Adjustment', referenceNumber: refNum('ADJ', 4001), productId: 'prod_006', productName: 'Orchids (Phalaenopsis)', batchNumber: 'BT-2026-0206', location: 'Display Cooler', quantityIn: 0, quantityOut: 3, costPerUnit: 8.50, costImpact: -25.50, performedBy: 'Anita Sharma', notes: 'Wilted — display cooler issue' },

    // ─── Day 20 (restock purchase) ──────────────────────
    { id: 'mv_015', date: dt(20, 8, 0),  referenceType: 'Purchase', referenceNumber: refNum('PO', 1004), productId: 'prod_007', productName: 'Eucalyptus Bunches', batchNumber: 'BT-2026-0207', location: 'Walk-in Cooler B', quantityIn: 100, quantityOut: 0, costPerUnit: 2.10, costImpact: 210, performedBy: 'Ravi Kumar', notes: 'GreenLeaf Distributors — weekly greens' },
    { id: 'mv_016', date: dt(20, 8, 30), referenceType: 'Purchase', referenceNumber: refNum('PO', 1004), productId: 'prod_008', productName: 'Tulips (Mixed)', batchNumber: 'BT-2026-0208', location: 'Walk-in Cooler A', quantityIn: 100, quantityOut: 0, costPerUnit: 2.40, costImpact: 240, performedBy: 'Ravi Kumar', notes: 'Holland Direct — seasonal tulips' },
    { id: 'mv_017', date: dt(20, 9, 0),  referenceType: 'Purchase', referenceNumber: refNum('PO', 1005), productId: 'prod_009', productName: 'Floral Foam Blocks', batchNumber: 'BT-2026-0209', location: 'Dry Storage', quantityIn: 500, quantityOut: 0, costPerUnit: 0.45, costImpact: 225, performedBy: 'Priya Patel', notes: 'Petal Perfect — bulk supplies' },

    // ─── Day 18 (sales wave — Valentine's prep) ─────────
    { id: 'mv_018', date: dt(18, 10, 0), referenceType: 'Sale', referenceNumber: refNum('INV', 2005), productId: 'prod_001', productName: 'Red Roses (Premium)', batchNumber: 'BT-2026-0201', location: 'Walk-in Cooler A', quantityIn: 0, quantityOut: 50, costPerUnit: 2.80, costImpact: -140, performedBy: 'Sameer Das', notes: "Valentine's pre-order batch — Hotel Grand" },
    { id: 'mv_019', date: dt(18, 10, 30), referenceType: 'Sale', referenceNumber: refNum('INV', 2005), productId: 'prod_002', productName: 'White Lilies', batchNumber: 'BT-2026-0202', location: 'Walk-in Cooler A', quantityIn: 0, quantityOut: 20, costPerUnit: 3.50, costImpact: -70, performedBy: 'Sameer Das', notes: "Valentine's pre-order — Hotel Grand" },
    { id: 'mv_020', date: dt(18, 11, 0), referenceType: 'Sale', referenceNumber: refNum('INV', 2006), productId: 'prod_004', productName: "Baby's Breath", batchNumber: 'BT-2026-0204', location: 'Walk-in Cooler B', quantityIn: 0, quantityOut: 40, costPerUnit: 0.60, costImpact: -24, performedBy: 'Neha Gupta', notes: 'Bulk filler order — Events Plus' },
    { id: 'mv_021', date: dt(18, 14, 0), referenceType: 'Sale', referenceNumber: refNum('INV', 2007), productId: 'prod_008', productName: 'Tulips (Mixed)', batchNumber: 'BT-2026-0208', location: 'Walk-in Cooler A', quantityIn: 0, quantityOut: 30, costPerUnit: 2.40, costImpact: -72, performedBy: 'Vikram Singh', notes: "Walk-in customer — Valentine's gift" },

    // ─── Day 15 (transfer + sales) ──────────────────────
    { id: 'mv_022', date: dt(15, 8, 0),  referenceType: 'Transfer', referenceNumber: refNum('TF', 3002), productId: 'prod_003', productName: 'Sunflowers', batchNumber: 'BT-2026-0203', location: 'Display Cooler → Front Display', quantityIn: 0, quantityOut: 10, costPerUnit: 1.90, costImpact: 0, performedBy: 'Vikram Singh', notes: 'Refresh front display' },
    { id: 'mv_023', date: dt(15, 12, 0), referenceType: 'Sale', referenceNumber: refNum('INV', 2008), productId: 'prod_005', productName: 'Pink Carnations', batchNumber: 'BT-2026-0205', location: 'Walk-in Cooler A', quantityIn: 0, quantityOut: 35, costPerUnit: 1.20, costImpact: -42, performedBy: 'Priya Patel', notes: 'Sympathy arrangement — local hospital' },
    { id: 'mv_024', date: dt(15, 15, 0), referenceType: 'Sale', referenceNumber: refNum('INV', 2009), productId: 'prod_007', productName: 'Eucalyptus Bunches', batchNumber: 'BT-2026-0207', location: 'Walk-in Cooler B', quantityIn: 0, quantityOut: 15, costPerUnit: 2.10, costImpact: -31.50, performedBy: 'Neha Gupta', notes: 'Mixed greenery for event' },

    // ─── Day 12 (wastage adjustment) ────────────────────
    { id: 'mv_025', date: dt(12, 9, 0),  referenceType: 'Adjustment', referenceNumber: refNum('ADJ', 4002), productId: 'prod_008', productName: 'Tulips (Mixed)', batchNumber: 'BT-2026-0208', location: 'Walk-in Cooler A', quantityIn: 0, quantityOut: 10, costPerUnit: 2.40, costImpact: -24, performedBy: 'Anita Sharma', notes: 'Spoiled — past peak freshness' },
    { id: 'mv_026', date: dt(12, 9, 30), referenceType: 'Adjustment', referenceNumber: refNum('ADJ', 4002), productId: 'prod_003', productName: 'Sunflowers', batchNumber: 'BT-2026-0203', location: 'Display Cooler', quantityIn: 0, quantityOut: 5, costPerUnit: 1.90, costImpact: -9.50, performedBy: 'Anita Sharma', notes: 'Drooping heads — customer return' },

    // ─── Day 10 (new purchases) ─────────────────────────
    { id: 'mv_027', date: dt(10, 8, 0),  referenceType: 'Purchase', referenceNumber: refNum('PO', 1006), productId: 'prod_011', productName: 'Hydrangeas (Blue)', batchNumber: 'BT-2026-0214', location: 'Walk-in Cooler B', quantityIn: 60, quantityOut: 0, costPerUnit: 4.20, costImpact: 252, performedBy: 'Ravi Kumar', notes: 'Pacific Blooms — spring collection' },
    { id: 'mv_028', date: dt(10, 8, 30), referenceType: 'Purchase', referenceNumber: refNum('PO', 1006), productId: 'prod_012', productName: 'Peonies', batchNumber: 'BT-2026-0215', location: 'Walk-in Cooler A', quantityIn: 50, quantityOut: 0, costPerUnit: 5.50, costImpact: 275, performedBy: 'Ravi Kumar', notes: 'Holland Direct — premium peonies' },
    { id: 'mv_029', date: dt(10, 9, 0),  referenceType: 'Purchase', referenceNumber: refNum('PO', 1007), productId: 'prod_013', productName: 'Spray Roses (Peach)', batchNumber: 'BT-2026-0218', location: 'Walk-in Cooler A', quantityIn: 180, quantityOut: 0, costPerUnit: 2.20, costImpact: 396, performedBy: 'Priya Patel', notes: 'Pacific Blooms — fresh spray roses' },

    // ─── Day 7 (heavy sales) ────────────────────────────
    { id: 'mv_030', date: dt(7, 10, 0),  referenceType: 'Sale', referenceNumber: refNum('INV', 2010), productId: 'prod_001', productName: 'Red Roses (Premium)', batchNumber: 'BT-2026-0201', location: 'Walk-in Cooler A', quantityIn: 0, quantityOut: 25, costPerUnit: 2.80, costImpact: -70, performedBy: 'Sameer Das', notes: 'Anniversary arrangement' },
    { id: 'mv_031', date: dt(7, 11, 30), referenceType: 'Sale', referenceNumber: refNum('INV', 2011), productId: 'prod_002', productName: 'White Lilies', batchNumber: 'BT-2026-0202', location: 'Walk-in Cooler A', quantityIn: 0, quantityOut: 15, costPerUnit: 3.50, costImpact: -52.50, performedBy: 'Neha Gupta', notes: 'Funeral flowers order' },
    { id: 'mv_032', date: dt(7, 12, 0),  referenceType: 'Sale', referenceNumber: refNum('INV', 2012), productId: 'prod_011', productName: 'Hydrangeas (Blue)', batchNumber: 'BT-2026-0214', location: 'Walk-in Cooler B', quantityIn: 0, quantityOut: 8, costPerUnit: 4.20, costImpact: -33.60, performedBy: 'Priya Patel', notes: 'Bridal shower arrangement' },
    { id: 'mv_033', date: dt(7, 14, 0),  referenceType: 'Sale', referenceNumber: refNum('INV', 2013), productId: 'prod_009', productName: 'Floral Foam Blocks', batchNumber: 'BT-2026-0209', location: 'Dry Storage', quantityIn: 0, quantityOut: 80, costPerUnit: 0.45, costImpact: -36, performedBy: 'Vikram Singh', notes: 'Workshop supply draw for the week' },
    { id: 'mv_034', date: dt(7, 15, 0),  referenceType: 'Sale', referenceNumber: refNum('INV', 2014), productId: 'prod_013', productName: 'Spray Roses (Peach)', batchNumber: 'BT-2026-0218', location: 'Walk-in Cooler A', quantityIn: 0, quantityOut: 20, costPerUnit: 2.20, costImpact: -44, performedBy: 'Sameer Das', notes: 'Mixed bouquet order' },

    // ─── Day 5 (transfers + adjustments) ────────────────
    { id: 'mv_035', date: dt(5, 8, 0),   referenceType: 'Transfer', referenceNumber: refNum('TF', 3003), productId: 'prod_005', productName: 'Pink Carnations', batchNumber: 'BT-2026-0205', location: 'Walk-in Cooler A → Display Cooler', quantityIn: 0, quantityOut: 20, costPerUnit: 1.20, costImpact: 0, performedBy: 'Vikram Singh', notes: 'Move remaining stock to display' },
    { id: 'mv_036', date: dt(5, 9, 30),  referenceType: 'Adjustment', referenceNumber: refNum('ADJ', 4003), productId: 'prod_006', productName: 'Orchids (Phalaenopsis)', batchNumber: 'BT-2026-0206', location: 'Display Cooler', quantityIn: 0, quantityOut: 5, costPerUnit: 8.50, costImpact: -42.50, performedBy: 'Anita Sharma', notes: 'End-of-life disposal — blooms faded' },

    // ─── Day 3 (sales + purchase) ───────────────────────
    { id: 'mv_037', date: dt(3, 9, 0),   referenceType: 'Sale', referenceNumber: refNum('INV', 2015), productId: 'prod_012', productName: 'Peonies', batchNumber: 'BT-2026-0215', location: 'Walk-in Cooler A', quantityIn: 0, quantityOut: 8, costPerUnit: 5.50, costImpact: -44, performedBy: 'Neha Gupta', notes: 'Premium arrangement — VIP customer' },
    { id: 'mv_038', date: dt(3, 10, 0),  referenceType: 'Sale', referenceNumber: refNum('INV', 2016), productId: 'prod_004', productName: "Baby's Breath", batchNumber: 'BT-2026-0204', location: 'Walk-in Cooler B', quantityIn: 0, quantityOut: 30, costPerUnit: 0.60, costImpact: -18, performedBy: 'Sameer Das', notes: 'Event decoration — filler bunches' },
    { id: 'mv_039', date: dt(3, 14, 0),  referenceType: 'Purchase', referenceNumber: refNum('PO', 1008), productId: 'prod_010', productName: 'Glass Cylinder Vases', batchNumber: 'BT-2026-0210', location: 'Dry Storage', quantityIn: 60, quantityOut: 0, costPerUnit: 4.50, costImpact: 270, performedBy: 'Priya Patel', notes: 'Petal Perfect — container restock' },

    // ─── Day 1 (yesterday) ──────────────────────────────
    { id: 'mv_040', date: dt(1, 9, 0),   referenceType: 'Sale', referenceNumber: refNum('INV', 2017), productId: 'prod_001', productName: 'Red Roses (Premium)', batchNumber: 'BT-2026-0201', location: 'Walk-in Cooler A', quantityIn: 0, quantityOut: 20, costPerUnit: 2.80, costImpact: -56, performedBy: 'Vikram Singh', notes: 'Daily walk-in sales' },
    { id: 'mv_041', date: dt(1, 10, 30), referenceType: 'Sale', referenceNumber: refNum('INV', 2018), productId: 'prod_013', productName: 'Spray Roses (Peach)', batchNumber: 'BT-2026-0218', location: 'Walk-in Cooler A', quantityIn: 0, quantityOut: 15, costPerUnit: 2.20, costImpact: -33, performedBy: 'Neha Gupta', notes: 'Hand-tied bouquet for pickup' },
    { id: 'mv_042', date: dt(1, 12, 0),  referenceType: 'Sale', referenceNumber: refNum('INV', 2019), productId: 'prod_010', productName: 'Glass Cylinder Vases', batchNumber: 'BT-2026-0210', location: 'Dry Storage', quantityIn: 0, quantityOut: 5, costPerUnit: 4.50, costImpact: -22.50, performedBy: 'Priya Patel', notes: 'Bundled with arrangement' },
    { id: 'mv_043', date: dt(1, 14, 0),  referenceType: 'Adjustment', referenceNumber: refNum('ADJ', 4004), productId: 'prod_008', productName: 'Tulips (Mixed)', batchNumber: 'BT-2026-0208', location: 'Walk-in Cooler A', quantityIn: 0, quantityOut: 20, costPerUnit: 2.40, costImpact: -48, performedBy: 'Anita Sharma', notes: 'Expired batch — full wastage write-off' },
    { id: 'mv_044', date: dt(1, 15, 0),  referenceType: 'Sale', referenceNumber: refNum('INV', 2020), productId: 'prod_009', productName: 'Floral Foam Blocks', batchNumber: 'BT-2026-0209', location: 'Dry Storage', quantityIn: 0, quantityOut: 100, costPerUnit: 0.45, costImpact: -45, performedBy: 'Vikram Singh', notes: 'Bulk order — florist workshop client' },

    // ─── Day 0 (today) ─────────────────────────────────
    { id: 'mv_045', date: dt(0, 8, 0),   referenceType: 'Sale', referenceNumber: refNum('INV', 2021), productId: 'prod_001', productName: 'Red Roses (Premium)', batchNumber: 'BT-2026-0201', location: 'Walk-in Cooler A', quantityIn: 0, quantityOut: 25, costPerUnit: 2.80, costImpact: -70, performedBy: 'Sameer Das', notes: 'Morning rush — mixed rose bouquets' },
    { id: 'mv_046', date: dt(0, 9, 30),  referenceType: 'Sale', referenceNumber: refNum('INV', 2022), productId: 'prod_011', productName: 'Hydrangeas (Blue)', batchNumber: 'BT-2026-0214', location: 'Walk-in Cooler B', quantityIn: 0, quantityOut: 4, costPerUnit: 4.20, costImpact: -16.80, performedBy: 'Neha Gupta', notes: 'Center piece orders' },
    { id: 'mv_047', date: dt(0, 10, 0),  referenceType: 'Transfer', referenceNumber: refNum('TF', 3004), productId: 'prod_012', productName: 'Peonies', batchNumber: 'BT-2026-0215', location: 'Walk-in Cooler A → Front Display', quantityIn: 0, quantityOut: 10, costPerUnit: 5.50, costImpact: 0, performedBy: 'Vikram Singh', notes: 'Feature peonies in window display' },
    { id: 'mv_048', date: dt(0, 11, 0),  referenceType: 'Sale', referenceNumber: refNum('INV', 2023), productId: 'prod_005', productName: 'Pink Carnations', batchNumber: 'BT-2026-0205', location: 'Walk-in Cooler A', quantityIn: 0, quantityOut: 10, costPerUnit: 1.20, costImpact: -12, performedBy: 'Priya Patel', notes: 'Get-well bouquet' },
  ];

  // Compute running balances per product (chronological)
  const sorted = [...raw].sort((a, b) => new Date(a.date).getTime() - new Date(b.date).getTime());
  const balances: Record<string, number> = {};

  return sorted.map((mv): StockMovement => {
    const prev = balances[mv.productId] ?? 0;
    const next = prev + mv.quantityIn - mv.quantityOut;
    balances[mv.productId] = next;
    return { ...mv, balanceAfter: next };
  });
};

export const MOCK_MOVEMENTS: StockMovement[] = generateMovements();

// ─── Mock API ───────────────────────────────────────────────

export const fetchMovements = (): Promise<StockMovement[]> =>
  new Promise((resolve) =>
    setTimeout(() => resolve([...MOCK_MOVEMENTS]), 600),
  );
