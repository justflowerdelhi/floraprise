/**
 * Inventory Adjustment / Wastage Entry — Types, Constants & Mock Data
 * Florist POS + ERP SaaS Platform
 */

import {
  createAdjustment,
  getBatchesByProduct,
  getRecentAdjustments,
  getInventoryProducts,
} from '../../../api/inventory.api';
import { safeArray } from '../../../utils/safeArray';

// ─── Enums / Constants ───────────────────────────────────────

export const ADJUSTMENT_TYPES = [
  { value: 'spoiled', label: 'Spoiled' },
  { value: 'damaged', label: 'Damaged' },
  { value: 'count_correction', label: 'Count Correction' },
  { value: 'used_for_event', label: 'Used for Event' },
  { value: 'sample', label: 'Sample' },
  { value: 'internal_use', label: 'Internal Use' },
  { value: 'refund_restock', label: 'Refund Restock' },
] as const;

export type AdjustmentType =
  | 'spoiled'
  | 'damaged'
  | 'count_correction'
  | 'used_for_event'
  | 'sample'
  | 'internal_use'
  | 'refund_restock';

// ─── Product / Batch ─────────────────────────────────────────

export interface AdjustmentProduct {
  id: string;
  name: string;
  sku: string;
  isPerishable: boolean;
  currentStock: number;
  costPerUnit: number;
  sellingPricePerUnit: number;
  category: string;
}

export interface ProductBatch {
  id: string;
  productId: string;
  batchCode: string;
  quantityRemaining: number;
  expiryDate: string | null;
  storageLocation: string;
  purchaseDate: string;
}

// ─── Adjustment Record ───────────────────────────────────────

export interface AdjustmentFormValues {
  productId: string;
  batchId: string;
  adjustmentType: AdjustmentType | '';
  quantity: number;
  reason: string;
  adjustedBy: string;
  adjustmentDate: string;
}

export interface AdjustmentRecord extends AdjustmentFormValues {
  id: string;
  productName: string;
  batchNumber: string;
  costPerUnit: number;
  totalValue: number;
  createdAt: string;
}

// ─── Summary Stats ───────────────────────────────────────────

export interface WastageSummary {
  todayTotalValue: number;
  todayCount: number;
  monthTotalValue: number;
  monthCount: number;
  topWastedProduct: string;
  topWastedValue: number;
  totalShrinkagePercent: number;
}

// ─── Defaults ────────────────────────────────────────────────

export const defaultFormValues: AdjustmentFormValues = {
  productId: '',
  batchId: '',
  adjustmentType: '',
  quantity: 0,
  reason: '',
  adjustedBy: '',
  adjustmentDate: new Date().toISOString().slice(0, 10),
};

// ─── Mock Products ───────────────────────────────────────────

export const MOCK_PRODUCTS: AdjustmentProduct[] = [
  {
    id: 'prod_001',
    name: 'Red Roses (Premium)',
    sku: 'FLW-RR-001',
    isPerishable: true,
    currentStock: 145,
    costPerUnit: 2.80,
    sellingPricePerUnit: 5.50,
    category: 'Fresh Flowers',
  },
  {
    id: 'prod_002',
    name: 'White Lilies',
    sku: 'FLW-WL-002',
    isPerishable: true,
    currentStock: 110,
    costPerUnit: 3.50,
    sellingPricePerUnit: 7.00,
    category: 'Fresh Flowers',
  },
  {
    id: 'prod_003',
    name: 'Sunflowers',
    sku: 'FLW-SF-003',
    isPerishable: true,
    currentStock: 25,
    costPerUnit: 1.90,
    sellingPricePerUnit: 4.50,
    category: 'Fresh Flowers',
  },
  {
    id: 'prod_004',
    name: 'Baby\'s Breath',
    sku: 'FLW-BB-004',
    isPerishable: true,
    currentStock: 290,
    costPerUnit: 0.60,
    sellingPricePerUnit: 1.80,
    category: 'Fresh Flowers',
  },
  {
    id: 'prod_005',
    name: 'Pink Carnations',
    sku: 'FLW-PC-005',
    isPerishable: true,
    currentStock: 60,
    costPerUnit: 1.20,
    sellingPricePerUnit: 3.00,
    category: 'Fresh Flowers',
  },
  {
    id: 'prod_006',
    name: 'Orchids (Phalaenopsis)',
    sku: 'FLW-OR-006',
    isPerishable: true,
    currentStock: 12,
    costPerUnit: 8.50,
    sellingPricePerUnit: 18.00,
    category: 'Fresh Flowers',
  },
  {
    id: 'prod_007',
    name: 'Eucalyptus Bunches',
    sku: 'GRN-EU-007',
    isPerishable: true,
    currentStock: 85,
    costPerUnit: 2.10,
    sellingPricePerUnit: 5.00,
    category: 'Greens & Foliage',
  },
  {
    id: 'prod_008',
    name: 'Floral Foam Blocks',
    sku: 'SUP-FF-008',
    isPerishable: false,
    currentStock: 320,
    costPerUnit: 0.45,
    sellingPricePerUnit: 1.20,
    category: 'Supplies',
  },
  {
    id: 'prod_009',
    name: 'Glass Cylinder Vases',
    sku: 'VAS-GC-009',
    isPerishable: false,
    currentStock: 45,
    costPerUnit: 4.50,
    sellingPricePerUnit: 12.00,
    category: 'Vases & Containers',
  },
  {
    id: 'prod_010',
    name: 'Peonies',
    sku: 'FLW-PN-010',
    isPerishable: true,
    currentStock: 42,
    costPerUnit: 5.50,
    sellingPricePerUnit: 12.00,
    category: 'Fresh Flowers',
  },
  {
    id: 'prod_011',
    name: 'Hydrangeas (Blue)',
    sku: 'FLW-HY-011',
    isPerishable: true,
    currentStock: 58,
    costPerUnit: 4.20,
    sellingPricePerUnit: 9.00,
    category: 'Fresh Flowers',
  },
  {
    id: 'prod_012',
    name: 'Dried Lavender Bunches',
    sku: 'DRI-LV-012',
    isPerishable: false,
    currentStock: 55,
    costPerUnit: 3.20,
    sellingPricePerUnit: 8.00,
    category: 'Dried Flowers',
  },
];

// ─── Mock Batches ────────────────────────────────────────────

const today = new Date();
const d = (offset: number): string => {
  const dt = new Date(today);
  dt.setDate(dt.getDate() + offset);
  return dt.toISOString().slice(0, 10);
};
const past = (offset: number): string => d(-offset);

export const MOCK_BATCHES: ProductBatch[] = [
  // Red Roses
  { id: 'bat_001', productId: 'prod_001', batchCode: 'BT-2026-0201', quantityRemaining: 85, expiryDate: d(5), storageLocation: 'Walk-in Cooler A', purchaseDate: past(5) },
  { id: 'bat_002', productId: 'prod_001', batchCode: 'BT-2026-0215', quantityRemaining: 60, expiryDate: d(9), storageLocation: 'Walk-in Cooler A', purchaseDate: past(1) },
  // White Lilies
  { id: 'bat_003', productId: 'prod_002', batchCode: 'BT-2026-0202', quantityRemaining: 110, expiryDate: d(8), storageLocation: 'Walk-in Cooler A', purchaseDate: past(3) },
  // Sunflowers
  { id: 'bat_004', productId: 'prod_003', batchCode: 'BT-2026-0203', quantityRemaining: 25, expiryDate: d(1), storageLocation: 'Display Cooler', purchaseDate: past(6) },
  // Baby's Breath
  { id: 'bat_005', productId: 'prod_004', batchCode: 'BT-2026-0204', quantityRemaining: 290, expiryDate: d(12), storageLocation: 'Walk-in Cooler B', purchaseDate: past(2) },
  // Pink Carnations
  { id: 'bat_006', productId: 'prod_005', batchCode: 'BT-2026-0205', quantityRemaining: 60, expiryDate: d(4), storageLocation: 'Walk-in Cooler A', purchaseDate: past(7) },
  // Orchids
  { id: 'bat_007', productId: 'prod_006', batchCode: 'BT-2026-0206', quantityRemaining: 12, expiryDate: d(0), storageLocation: 'Display Cooler', purchaseDate: past(10) },
  // Eucalyptus
  { id: 'bat_008', productId: 'prod_007', batchCode: 'BT-2026-0207', quantityRemaining: 85, expiryDate: d(10), storageLocation: 'Walk-in Cooler B', purchaseDate: past(4) },
  // Peonies
  { id: 'bat_009', productId: 'prod_010', batchCode: 'BT-2026-0215', quantityRemaining: 42, expiryDate: d(2), storageLocation: 'Walk-in Cooler A', purchaseDate: past(4) },
  // Hydrangeas
  { id: 'bat_010', productId: 'prod_011', batchCode: 'BT-2026-0214', quantityRemaining: 58, expiryDate: d(6), storageLocation: 'Walk-in Cooler B', purchaseDate: past(3) },
];

// ─── Mock Recent Adjustments (for summary) ───────────────────

export const MOCK_RECENT_ADJUSTMENTS: AdjustmentRecord[] = [
  {
    id: 'adj_001',
    productId: 'prod_001',
    productName: 'Red Roses (Premium)',
    batchId: 'bat_001',
    batchNumber: 'BT-2026-0201',
    adjustmentType: 'spoiled',
    quantity: 15,
    reason: 'Wilted — end of shelf life',
    adjustedBy: 'Priya Sharma',
    adjustmentDate: new Date().toISOString().slice(0, 10),
    costPerUnit: 2.80,
    totalValue: 42.00,
    createdAt: new Date().toISOString(),
  },
  {
    id: 'adj_002',
    productId: 'prod_003',
    productName: 'Sunflowers',
    batchId: 'bat_004',
    batchNumber: 'BT-2026-0203',
    adjustmentType: 'damaged',
    quantity: 8,
    reason: 'Stems broken during transport',
    adjustedBy: 'Amit Patel',
    adjustmentDate: new Date().toISOString().slice(0, 10),
    costPerUnit: 1.90,
    totalValue: 15.20,
    createdAt: new Date().toISOString(),
  },
  {
    id: 'adj_003',
    productId: 'prod_006',
    productName: 'Orchids (Phalaenopsis)',
    batchId: 'bat_007',
    batchNumber: 'BT-2026-0206',
    adjustmentType: 'sample',
    quantity: 2,
    reason: 'Client sampling for wedding order',
    adjustedBy: 'Priya Sharma',
    adjustmentDate: new Date().toISOString().slice(0, 10),
    costPerUnit: 8.50,
    totalValue: 17.00,
    createdAt: new Date().toISOString(),
  },
  {
    id: 'adj_004',
    productId: 'prod_005',
    productName: 'Pink Carnations',
    batchId: 'bat_006',
    batchNumber: 'BT-2026-0205',
    adjustmentType: 'spoiled',
    quantity: 20,
    reason: 'Fungal growth detected',
    adjustedBy: 'Amit Patel',
    adjustmentDate: past(2),
    costPerUnit: 1.20,
    totalValue: 24.00,
    createdAt: new Date(Date.now() - 2 * 86400000).toISOString(),
  },
  {
    id: 'adj_005',
    productId: 'prod_001',
    productName: 'Red Roses (Premium)',
    batchId: 'bat_001',
    batchNumber: 'BT-2026-0201',
    adjustmentType: 'spoiled',
    quantity: 25,
    reason: 'Wilted batch — cold chain issue',
    adjustedBy: 'Priya Sharma',
    adjustmentDate: past(5),
    costPerUnit: 2.80,
    totalValue: 70.00,
    createdAt: new Date(Date.now() - 5 * 86400000).toISOString(),
  },
  {
    id: 'adj_006',
    productId: 'prod_010',
    productName: 'Peonies',
    batchId: 'bat_009',
    batchNumber: 'BT-2026-0215',
    adjustmentType: 'used_for_event',
    quantity: 10,
    reason: 'Wedding demo arrangement',
    adjustedBy: 'Priya Sharma',
    adjustmentDate: past(3),
    costPerUnit: 5.50,
    totalValue: 55.00,
    createdAt: new Date(Date.now() - 3 * 86400000).toISOString(),
  },
  {
    id: 'adj_007',
    productId: 'prod_002',
    productName: 'White Lilies',
    batchId: 'bat_003',
    batchNumber: 'BT-2026-0202',
    adjustmentType: 'damaged',
    quantity: 5,
    reason: 'Dropped during arrangement',
    adjustedBy: 'Amit Patel',
    adjustmentDate: past(7),
    costPerUnit: 3.50,
    totalValue: 17.50,
    createdAt: new Date(Date.now() - 7 * 86400000).toISOString(),
  },
  {
    id: 'adj_008',
    productId: 'prod_009',
    productName: 'Glass Cylinder Vases',
    batchId: '',
    batchNumber: '',
    adjustmentType: 'damaged',
    quantity: 3,
    reason: 'Cracked in shipping — supplier claim filed',
    adjustedBy: 'Amit Patel',
    adjustmentDate: past(10),
    costPerUnit: 4.50,
    totalValue: 13.50,
    createdAt: new Date(Date.now() - 10 * 86400000).toISOString(),
  },
];

// ─── Staff ───────────────────────────────────────────────────

export const STAFF_MEMBERS = [
  'Priya Sharma',
  'Amit Patel',
  'Neha Gupta',
  'Ravi Kumar',
] as const;

// ─── API Payload Contracts ───────────────────────────────────

export interface SubmitAdjustmentPayload {
  productId: string;
  batchId: string;
  adjustmentType: string;
  quantity: number;
  reason: string;
  adjustedBy: string;
  adjustmentDate: string;
  costPerUnit: number;
  totalValue: number;
}

type ApiAdjustment = {
  id?: string;
  productId?: string;
  productName?: string;
  batchId?: string | null;
  batchNumber?: string | null;
  adjustmentType?: string;
  quantity?: number;
  reason?: string;
  adjustedByName?: string | null;
  adjustmentDate?: string;
  costPerUnit?: number;
  totalValue?: number;
  createdAtUtc?: string;
};

type ApiInventoryProduct = {
  id?: string;
  name?: string;
  productType?: string;
  quantityAvailable?: number;
  unitCost?: number;
};

type ApiBatch = {
  id?: string;
  productId?: string;
  batchNumber?: string;
  quantityRemaining?: number;
  expiryDate?: string | null;
  storageLocation?: string | null;
  receivedDate?: string;
};

const mapAdjustmentTypeToUi = (value: string | undefined): AdjustmentType => {
  const normalized = String(value ?? '').toLowerCase();

  switch (normalized) {
    case 'spoiled':
      return 'spoiled';
    case 'damaged':
      return 'damaged';
    case 'usedforevent':
    case 'used_for_event':
      return 'used_for_event';
    case 'usedforsample':
    case 'sample':
    case 'used_for_sample':
      return 'sample';
    case 'correction':
    case 'count_correction':
      return 'count_correction';
    default:
      return 'internal_use';
  }
};

const mapApiAdjustment = (a: ApiAdjustment): AdjustmentRecord => ({
  id: String(a.id ?? ''),
  productId: String(a.productId ?? ''),
  productName: String(a.productName ?? 'Unknown Product'),
  batchId: String(a.batchId ?? ''),
  batchNumber: String(a.batchNumber ?? ''),
  adjustmentType: mapAdjustmentTypeToUi(a.adjustmentType),
  quantity: Number(a.quantity ?? 0),
  reason: String(a.reason ?? ''),
  adjustedBy: String(a.adjustedByName ?? ''),
  adjustmentDate: String(a.adjustmentDate ?? new Date().toISOString()),
  costPerUnit: Number(a.costPerUnit ?? 0),
  totalValue: Number(a.totalValue ?? 0),
  createdAt: String(a.createdAtUtc ?? a.adjustmentDate ?? new Date().toISOString()),
});

const inferPerishable = (productType: string): boolean => {
  const normalized = productType.toLowerCase();
  return (
    normalized.includes('flower') ||
    normalized.includes('fresh') ||
    normalized.includes('floral')
  );
};

export const fetchProducts = async (): Promise<AdjustmentProduct[]> => {
  try {
    const payload = await getInventoryProducts();
    const data = safeArray<ApiInventoryProduct>(payload, 'items');

    if (data.length === 0) {
      return [];
    }

    return data.map((p) => {
      const productType = String(p.productType ?? 'General');
      const unitCost = Number(p.unitCost ?? 0);
      const id = String(p.id ?? '');

      return {
        id,
        name: String(p.name ?? 'Unnamed Product'),
        sku: `SKU-${id.slice(0, 8).toUpperCase()}`,
        isPerishable: inferPerishable(productType),
        currentStock: Number(p.quantityAvailable ?? 0),
        costPerUnit: unitCost,
        sellingPricePerUnit: unitCost,
        category: productType,
      };
    });
  } catch {
    return [];
  }
};

export const fetchBatchesForProduct = async (productId: string): Promise<ProductBatch[]> => {
  if (!productId) return [];

  try {
    const payload = await getBatchesByProduct(productId);
    const data = safeArray<ApiBatch>(payload, 'items');

    if (data.length === 0) {
      return [];
    }

    return data.map((b) => ({
      id: String(b.id ?? ''),
      productId: String(b.productId ?? productId),
      batchCode: String(b.batchNumber ?? ''),
      quantityRemaining: Number(b.quantityRemaining ?? 0),
      expiryDate: b.expiryDate ? String(b.expiryDate).slice(0, 10) : null,
      storageLocation: String(b.storageLocation ?? 'N/A'),
      purchaseDate: String(b.receivedDate ?? new Date().toISOString()).slice(0, 10),
    }));
  } catch {
    return [];
  }
};

export const fetchRecentAdjustments = async (): Promise<AdjustmentRecord[]> => {
  try {
    const payload = await getRecentAdjustments(25);
    const data = safeArray<ApiAdjustment>(payload, 'items');

    if (data.length === 0) {
      return [];
    }

    return data.map(mapApiAdjustment);
  } catch {
    return [];
  }
};

export const submitAdjustment = async (
  payload: SubmitAdjustmentPayload,
): Promise<{ success: boolean; id: string }> => {
  const response = await createAdjustment({
    productId: payload.productId,
    batchId: payload.batchId || null,
    adjustmentType: payload.adjustmentType,
    quantity: payload.quantity,
    costPerUnit: payload.costPerUnit,
    reason: payload.reason,
    adjustmentDate: payload.adjustmentDate,
    notes: payload.adjustedBy ? `Adjusted by: ${payload.adjustedBy}` : null,
  });

  const id = String((response as { id?: string })?.id ?? '');
  return { success: true, id };
};
