/**
 * ProductionMockData.ts — Mock Data for Production Planning
 *
 * Phase 4: Production Planning & Inventory Reservation
 */
import type {
  EventProductionData,
  EventProductionItem,
  ChecklistItem,
  InventoryAvailability,
} from './ProductionTypes';

// ─── Production Items for evt-001 (Sharma-Patel Wedding) ────

const PRODUCTION_ITEMS_EVT001: EventProductionItem[] = [
  {
    id: 'pitem-001',
    eventId: 'evt-001',
    proposalItemId: 'item-001',
    name: 'Bridal Bouquet (Premium)',
    quantity: 1,
    linkedProductId: 'p13',
    linkedProductSku: 'BRB-015',
    productionStatus: 'READY',
    reservedQuantity: 1,
  },
  {
    id: 'pitem-002',
    eventId: 'evt-001',
    proposalItemId: 'item-002',
    name: 'Bridesmaid Bouquet',
    quantity: 6,
    linkedProductId: 'p14',
    linkedProductSku: 'BMB-016',
    productionStatus: 'IN_PROGRESS',
    reservedQuantity: 6,
  },
  {
    id: 'pitem-003',
    eventId: 'evt-001',
    proposalItemId: 'item-003',
    name: 'Boutonniere',
    quantity: 10,
    linkedProductId: 'p15',
    linkedProductSku: 'BTN-017',
    productionStatus: 'IN_PROGRESS',
    reservedQuantity: 10,
  },
  {
    id: 'pitem-004',
    eventId: 'evt-001',
    proposalItemId: 'item-004',
    name: 'Altar/Mandap Arrangement',
    quantity: 1,
    linkedProductId: 'p19',
    linkedProductSku: 'AMA-022',
    productionStatus: 'NOT_STARTED',
    reservedQuantity: 1,
    notes: 'Large arrangement - needs extra preparation time',
  },
  {
    id: 'pitem-005',
    eventId: 'evt-001',
    proposalItemId: 'item-005',
    name: 'Table Centerpiece',
    quantity: 25,
    linkedProductId: 'p17',
    linkedProductSku: 'TCP-020',
    productionStatus: 'NOT_STARTED',
    reservedQuantity: 20,
  },
  {
    id: 'pitem-006',
    eventId: 'evt-001',
    proposalItemId: 'item-006',
    name: 'Entrance Arch',
    quantity: 2,
    linkedProductId: 'p20',
    linkedProductSku: 'ENA-023',
    productionStatus: 'NOT_STARTED',
    reservedQuantity: 2,
  },
  {
    id: 'pitem-007',
    eventId: 'evt-001',
    proposalItemId: 'item-007',
    name: 'Delivery & Setup',
    quantity: 1,
    productionStatus: 'NOT_STARTED',
    reservedQuantity: 0,
    notes: 'Service - no inventory needed',
  },
  {
    id: 'pitem-008',
    eventId: 'evt-001',
    proposalItemId: 'item-008',
    name: 'Site Visit',
    quantity: 2,
    productionStatus: 'READY',
    reservedQuantity: 0,
    notes: 'Completed on Feb 10',
  },
];

// ─── Production Items for evt-002 (TechCorp Gala) ───────────

const PRODUCTION_ITEMS_EVT002: EventProductionItem[] = [
  {
    id: 'pitem-009',
    eventId: 'evt-002',
    proposalItemId: 'item-009',
    name: 'Table Centerpiece',
    quantity: 20,
    linkedProductId: 'p17',
    linkedProductSku: 'TCP-020',
    productionStatus: 'IN_PROGRESS',
    reservedQuantity: 20,
  },
  {
    id: 'pitem-010',
    eventId: 'evt-002',
    proposalItemId: 'item-010',
    name: 'Stage Arrangement (Large)',
    quantity: 2,
    linkedProductId: 'p18',
    linkedProductSku: 'SAL-021',
    productionStatus: 'IN_PROGRESS',
    reservedQuantity: 2,
  },
  {
    id: 'pitem-011',
    eventId: 'evt-002',
    proposalItemId: 'item-011',
    name: 'White Orchids Display',
    quantity: 10,
    linkedProductId: 'p06',
    linkedProductSku: 'ORC-004',
    productionStatus: 'READY',
    reservedQuantity: 10,
  },
];

// ─── Checklist Items ────────────────────────────────────────

const CHECKLIST_EVT001: ChecklistItem[] = [
  { id: 'chk-001', label: 'Order Flowers', completed: true, completedAt: '2026-02-20T10:00:00Z', completedBy: 'Meera Patel', order: 1 },
  { id: 'chk-002', label: 'Confirm Venue Details', completed: true, completedAt: '2026-02-22T14:00:00Z', completedBy: 'Meera Patel', order: 2 },
  { id: 'chk-003', label: 'Prepare Items', completed: false, order: 3 },
  { id: 'chk-004', label: 'Load Van', completed: false, order: 4 },
  { id: 'chk-005', label: 'Install Complete', completed: false, order: 5 },
];

const CHECKLIST_EVT002: ChecklistItem[] = [
  { id: 'chk-006', label: 'Order Flowers', completed: true, completedAt: '2026-02-15T09:00:00Z', completedBy: 'Ananya Sharma', order: 1 },
  { id: 'chk-007', label: 'Confirm Venue Details', completed: true, completedAt: '2026-02-16T11:00:00Z', completedBy: 'Ananya Sharma', order: 2 },
  { id: 'chk-008', label: 'Prepare Items', completed: true, completedAt: '2026-02-18T15:00:00Z', completedBy: 'Ananya Sharma', order: 3 },
  { id: 'chk-009', label: 'Load Van', completed: false, order: 4 },
  { id: 'chk-010', label: 'Install Complete', completed: false, order: 5 },
];

// ─── Mock Production Data ───────────────────────────────────

export const MOCK_PRODUCTION_DATA: EventProductionData[] = [
  {
    eventId: 'evt-001',
    proposalId: 'prop-001',
    assignedDesignerId: 'd1',
    productionStartDate: '2026-03-01',
    deliveryDate: '2026-03-15',
    installDate: '2026-03-15',
    items: PRODUCTION_ITEMS_EVT001,
    checklist: CHECKLIST_EVT001,
    notes: 'Premium wedding - extra attention to detail required',
    createdAt: '2026-02-01T10:00:00Z',
    updatedAt: '2026-02-18T14:00:00Z',
  },
  {
    eventId: 'evt-002',
    proposalId: 'prop-002',
    assignedDesignerId: 'd2',
    productionStartDate: '2026-02-20',
    deliveryDate: '2026-02-28',
    installDate: '2026-02-28',
    items: PRODUCTION_ITEMS_EVT002,
    checklist: CHECKLIST_EVT002,
    notes: 'Corporate event - professional look required',
    createdAt: '2026-02-10T08:00:00Z',
    updatedAt: '2026-02-18T10:00:00Z',
  },
];

// ─── Mock Inventory Availability ────────────────────────────

export const MOCK_INVENTORY_AVAILABILITY: InventoryAvailability[] = [
  // Fresh Flowers
  { productId: 'p01', productName: 'Red Roses (Premium)', sku: 'RSP-001', totalQuantity: 500, reservedForOtherEvents: 100, availableQuantity: 400, unit: 'stems' },
  { productId: 'p02', productName: 'White Lilies', sku: 'WHL-002', totalQuantity: 200, reservedForOtherEvents: 50, availableQuantity: 150, unit: 'stems' },
  { productId: 'p03', productName: 'Sunflowers', sku: 'SNF-003', totalQuantity: 150, reservedForOtherEvents: 30, availableQuantity: 120, unit: 'stems' },
  { productId: 'p08', productName: "Baby's Breath", sku: 'BBR-006', totalQuantity: 100, reservedForOtherEvents: 20, availableQuantity: 80, unit: 'bunches' },
  { productId: 'p09', productName: 'Carnations (Mixed)', sku: 'CRN-007', totalQuantity: 300, reservedForOtherEvents: 50, availableQuantity: 250, unit: 'stems' },
  { productId: 'p10', productName: 'Gerbera Daisies', sku: 'GRB-008', totalQuantity: 180, reservedForOtherEvents: 40, availableQuantity: 140, unit: 'stems' },
  { productId: 'p11', productName: 'Marigolds', sku: 'MRG-009', totalQuantity: 1000, reservedForOtherEvents: 200, availableQuantity: 800, unit: 'strings' },
  { productId: 'p12', productName: 'Jasmine Strings', sku: 'JSM-010', totalQuantity: 50, reservedForOtherEvents: 10, availableQuantity: 40, unit: 'strings' },

  // Bouquets & Arrangements (Capacity)
  { productId: 'p13', productName: 'Bridal Bouquet (Premium)', sku: 'BRB-015', totalQuantity: 5, reservedForOtherEvents: 2, availableQuantity: 3, unit: 'units' },
  { productId: 'p14', productName: 'Bridesmaid Bouquet', sku: 'BMB-016', totalQuantity: 20, reservedForOtherEvents: 8, availableQuantity: 12, unit: 'units' },
  { productId: 'p15', productName: 'Boutonniere', sku: 'BTN-017', totalQuantity: 50, reservedForOtherEvents: 15, availableQuantity: 35, unit: 'units' },
  { productId: 'p16', productName: 'Corsage', sku: 'CRS-018', totalQuantity: 30, reservedForOtherEvents: 10, availableQuantity: 20, unit: 'units' },
  { productId: 'p17', productName: 'Table Centerpiece', sku: 'TCP-020', totalQuantity: 100, reservedForOtherEvents: 40, availableQuantity: 60, unit: 'units' },
  { productId: 'p18', productName: 'Stage Arrangement (Large)', sku: 'SAL-021', totalQuantity: 10, reservedForOtherEvents: 4, availableQuantity: 6, unit: 'units' },
  { productId: 'p19', productName: 'Altar/Mandap Arrangement', sku: 'AMA-022', totalQuantity: 5, reservedForOtherEvents: 2, availableQuantity: 3, unit: 'units' },
  { productId: 'p20', productName: 'Entrance Arch', sku: 'ENA-023', totalQuantity: 8, reservedForOtherEvents: 3, availableQuantity: 5, unit: 'units' },
  { productId: 'p21', productName: 'Photo Booth Backdrop', sku: 'PBB-024', totalQuantity: 6, reservedForOtherEvents: 2, availableQuantity: 4, unit: 'units' },

  // Greens & Foliage
  { productId: 'p07', productName: 'Eucalyptus Bunch', sku: 'EUC-005', totalQuantity: 80, reservedForOtherEvents: 20, availableQuantity: 60, unit: 'bunches' },
  { productId: 'p22', productName: 'Fern Bunch', sku: 'FRN-025', totalQuantity: 100, reservedForOtherEvents: 30, availableQuantity: 70, unit: 'bunches' },
  { productId: 'p23', productName: 'Palm Leaves', sku: 'PLM-026', totalQuantity: 60, reservedForOtherEvents: 10, availableQuantity: 50, unit: 'bunches' },

  // Plants
  { productId: 'p06', productName: 'Orchid Phalaenopsis', sku: 'ORC-004', totalQuantity: 25, reservedForOtherEvents: 10, availableQuantity: 15, unit: 'plants' },
  { productId: 'p24', productName: 'Money Plant (Large)', sku: 'MNP-027', totalQuantity: 40, reservedForOtherEvents: 5, availableQuantity: 35, unit: 'plants' },
];

// ─── Helper Functions ───────────────────────────────────────

/**
 * Get production data for an event
 */
export const getProductionForEvent = (eventId: string): EventProductionData | null => {
  return MOCK_PRODUCTION_DATA.find((p) => p.eventId === eventId) || null;
};

/**
 * Get inventory availability map
 */
export const getInventoryAvailabilityMap = (): Map<string, InventoryAvailability> => {
  const map = new Map<string, InventoryAvailability>();
  MOCK_INVENTORY_AVAILABILITY.forEach((inv) => {
    map.set(inv.productId, inv);
  });
  return map;
};

/**
 * Get availability for a specific product
 */
export const getProductAvailability = (productId: string): InventoryAvailability | null => {
  return MOCK_INVENTORY_AVAILABILITY.find((inv) => inv.productId === productId) || null;
};

/**
 * Calculate remaining stock after reservation
 */
export const calculateRemainingStock = (
  productId: string,
  reservedQuantity: number
): { available: number; remaining: number } | null => {
  const inv = getProductAvailability(productId);
  if (!inv) return null;
  return {
    available: inv.availableQuantity,
    remaining: Math.max(0, inv.availableQuantity - reservedQuantity),
  };
};

/**
 * Get all events with production data
 */
export const getEventsWithProduction = (): string[] => {
  return MOCK_PRODUCTION_DATA.map((p) => p.eventId);
};

/**
 * Check if event has production initialized
 */
export const hasProductionData = (eventId: string): boolean => {
  return MOCK_PRODUCTION_DATA.some((p) => p.eventId === eventId);
};
