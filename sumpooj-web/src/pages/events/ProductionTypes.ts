/**
 * ProductionTypes.ts — Production Planning Type Definitions
 *
 * Phase 4: Production Planning & Inventory Reservation
 * Links proposals to operations for wedding/event production.
 */

// ─── Production Status ──────────────────────────────────────

export type ProductionStatus =
  | 'NOT_STARTED'
  | 'IN_PROGRESS'
  | 'READY'
  | 'INSTALLED';

export const PRODUCTION_STATUSES: ProductionStatus[] = [
  'NOT_STARTED',
  'IN_PROGRESS',
  'READY',
  'INSTALLED',
];

// ─── Production Item Interface ──────────────────────────────

export interface EventProductionItem {
  id: string;
  eventId: string;
  proposalItemId: string;
  name: string;
  quantity: number;
  linkedProductId?: string;
  linkedProductSku?: string;
  productionStatus: ProductionStatus;
  reservedQuantity: number;
  notes?: string;
  dueDate?: string;
}

// ─── Checklist Item Interface ───────────────────────────────

export interface ChecklistItem {
  id: string;
  label: string;
  completed: boolean;
  completedAt?: string;
  completedBy?: string;
  order: number;
}

// ─── Event Production Data ──────────────────────────────────

export interface EventProductionData {
  eventId: string;
  proposalId: string;
  assignedDesignerId?: string;
  productionStartDate?: string;
  deliveryDate?: string;
  installDate?: string;
  items: EventProductionItem[];
  checklist: ChecklistItem[];
  notes?: string;
  createdAt: string;
  updatedAt: string;
}

// ─── Inventory Availability ─────────────────────────────────

export interface InventoryAvailability {
  productId: string;
  productName: string;
  sku: string;
  totalQuantity: number;
  reservedForOtherEvents: number;
  availableQuantity: number;
  unit: string;
}

// ─── Reservation Warning ────────────────────────────────────

export interface ReservationWarning {
  itemId: string;
  itemName: string;
  requested: number;
  available: number;
  shortfall: number;
}

// ─── Status Configuration ───────────────────────────────────

export interface ProductionStatusConfig {
  label: string;
  color: string;
  bgColor: string;
  icon: string;
  description: string;
}

export const PRODUCTION_STATUS_CONFIG: Record<ProductionStatus, ProductionStatusConfig> = {
  NOT_STARTED: {
    label: 'Not Started',
    color: '#9e9e9e',
    bgColor: 'rgba(158, 158, 158, 0.12)',
    icon: 'Schedule',
    description: 'Production not yet begun',
  },
  IN_PROGRESS: {
    label: 'In Progress',
    color: '#2196f3',
    bgColor: 'rgba(33, 150, 243, 0.12)',
    icon: 'Engineering',
    description: 'Being worked on',
  },
  READY: {
    label: 'Ready',
    color: '#4caf50',
    bgColor: 'rgba(76, 175, 80, 0.12)',
    icon: 'CheckCircle',
    description: 'Complete and ready for delivery',
  },
  INSTALLED: {
    label: 'Installed',
    color: '#9c27b0',
    bgColor: 'rgba(156, 39, 176, 0.12)',
    icon: 'Verified',
    description: 'Installed at venue',
  },
};

// ─── Default Checklist Template ─────────────────────────────

export const DEFAULT_CHECKLIST_ITEMS: Omit<ChecklistItem, 'id'>[] = [
  { label: 'Order Flowers', completed: false, order: 1 },
  { label: 'Confirm Venue Details', completed: false, order: 2 },
  { label: 'Prepare Items', completed: false, order: 3 },
  { label: 'Load Van', completed: false, order: 4 },
  { label: 'Install Complete', completed: false, order: 5 },
];

// ─── Utility Functions ──────────────────────────────────────

/**
 * Generate unique ID
 */
export const generateId = (): string =>
  `prod-${Date.now()}-${Math.random().toString(36).substring(2, 9)}`;

/**
 * Generate checklist from template
 */
export const generateDefaultChecklist = (): ChecklistItem[] =>
  DEFAULT_CHECKLIST_ITEMS.map((item, index) => ({
    ...item,
    id: `chk-${Date.now()}-${index}`,
  }));

/**
 * Calculate production progress percentage
 */
export const calculateProductionProgress = (items: EventProductionItem[]): number => {
  if (items.length === 0) return 0;
  const completedSteps: number[] = items.map((item) => {
    switch (item.productionStatus) {
      case 'INSTALLED': return 100;
      case 'READY': return 75;
      case 'IN_PROGRESS': return 40;
      default: return 0;
    }
  });
  return Math.round(completedSteps.reduce((a, b) => a + b, 0) / items.length);
};

/**
 * Calculate checklist progress
 */
export const calculateChecklistProgress = (checklist: ChecklistItem[]): number => {
  if (checklist.length === 0) return 0;
  const completed = checklist.filter((item) => item.completed).length;
  return Math.round((completed / checklist.length) * 100);
};

/**
 * Check if reservation exceeds available inventory
 */
export const checkReservationWarnings = (
  items: EventProductionItem[],
  availability: Map<string, InventoryAvailability>
): ReservationWarning[] => {
  const warnings: ReservationWarning[] = [];

  items.forEach((item) => {
    if (item.linkedProductId && item.reservedQuantity > 0) {
      const inv = availability.get(item.linkedProductId);
      if (inv && item.reservedQuantity > inv.availableQuantity) {
        warnings.push({
          itemId: item.id,
          itemName: item.name,
          requested: item.reservedQuantity,
          available: inv.availableQuantity,
          shortfall: item.reservedQuantity - inv.availableQuantity,
        });
      }
    }
  });

  return warnings;
};

/**
 * Get overall production status based on item statuses
 */
export const getOverallProductionStatus = (items: EventProductionItem[]): ProductionStatus => {
  if (items.length === 0) return 'NOT_STARTED';

  const allInstalled = items.every((i) => i.productionStatus === 'INSTALLED');
  if (allInstalled) return 'INSTALLED';

  const allReady = items.every((i) => i.productionStatus === 'READY' || i.productionStatus === 'INSTALLED');
  if (allReady) return 'READY';

  const anyInProgress = items.some((i) => i.productionStatus === 'IN_PROGRESS' || i.productionStatus === 'READY');
  if (anyInProgress) return 'IN_PROGRESS';

  return 'NOT_STARTED';
};

/**
 * Convert proposal items to production items
 */
export const proposalItemsToProductionItems = (
  eventId: string,
  _proposalId: string,
  proposalItems: Array<{
    id: string;
    name: string;
    quantity: number;
    linkedProductId?: string;
    linkedProductSku?: string;
  }>
): EventProductionItem[] => {
  return proposalItems.map((item) => ({
    id: generateId(),
    eventId,
    proposalItemId: item.id,
    name: item.name,
    quantity: item.quantity,
    linkedProductId: item.linkedProductId,
    linkedProductSku: item.linkedProductSku,
    productionStatus: 'NOT_STARTED' as ProductionStatus,
    reservedQuantity: 0,
  }));
};
