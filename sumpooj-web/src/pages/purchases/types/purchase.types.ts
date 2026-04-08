/**
 * Purchase Entry Form — TypeScript Interfaces
 * Goods Receipt Note (GRN) for Florist POS + ERP
 */

// ============================================
// ENUMS / CONSTANTS
// ============================================

export const PAYMENT_TERMS = [
  { value: 'net_7', label: 'Net 7' },
  { value: 'net_15', label: 'Net 15' },
  { value: 'net_30', label: 'Net 30' },
  { value: 'net_45', label: 'Net 45' },
  { value: 'net_60', label: 'Net 60' },
  { value: 'cod', label: 'Cash on Delivery' },
  { value: 'prepaid', label: 'Prepaid' },
] as const;

export const UNITS = [
  { value: 'stem', label: 'Stem' },
  { value: 'bunch', label: 'Bunch' },
  { value: 'box', label: 'Box' },
  { value: 'kg', label: 'Kg' },
  { value: 'lbs', label: 'Lbs' },
  { value: 'piece', label: 'Piece' },
  { value: 'pack', label: 'Pack' },
  { value: 'dozen', label: 'Dozen' },
] as const;

export const STORAGE_LOCATIONS = [
  { value: 'cold_room_a', label: 'Cold Room A (2–4°C)' },
  { value: 'cold_room_b', label: 'Cold Room B (4–8°C)' },
  { value: 'display_cooler', label: 'Display Cooler' },
  { value: 'dry_storage', label: 'Dry Storage' },
  { value: 'warehouse', label: 'Warehouse' },
] as const;

export const TAX_RATES = [
  { value: 0, label: 'No Tax (0%)' },
  { value: 5, label: 'GST 5%' },
  { value: 12, label: 'GST 12%' },
  { value: 18, label: 'GST 18%' },
] as const;

// ============================================
// SUPPLIER
// ============================================

export interface Supplier {
  id: string;
  name: string;
  contactPerson?: string;
  email?: string;
  phone?: string;
  address?: string;
  defaultPaymentTerms?: string;
  leadTimeDays?: number;
}

// ============================================
// PRODUCT (for lookup)
// ============================================

export interface Product {
  id: string;
  name: string;
  sku: string;
  isPerishable: boolean;
  defaultShelfLifeDays?: number;
  defaultUnit: string;
  lastCost?: number;
  sellingPrice?: number;
  category?: string;
}

// ============================================
// PURCHASE ITEM (row)
// ============================================

export interface PurchaseItem {
  id: string;
  productId: string;
  productName: string;
  sku: string;
  isPerishable: boolean;
  unit: string;
  quantity: number;
  expectedCostPerUnit: number;
  total: number;
  // Product attributes for planning
  shelfLifeDays: number;
  // Margin tracking
  sellingPrice: number;
  marginPercent: number;
  marginAmount: number;
}

// ============================================
// PURCHASE HEADER
// ============================================

export interface PurchaseHeader {
  supplierId: string;
  expectedDeliveryDate: string;
  paymentTerms: string;
  location: string;
  shippingCost: number;
  notes: string;
  invoiceImage: File | null;
  taxRate: number;
}

// ============================================
// FULL FORM DATA
// ============================================

export interface PurchaseFormData {
  header: PurchaseHeader;
  items: PurchaseItem[];
}

// ============================================
// SUMMARY
// ============================================

export interface OrderSummary {
  itemCount: number;
  subtotal: number;
  taxRate: number;
  taxAmount: number;
  shippingCost: number;
  grandTotal: number;
  averageMargin: number;
  lowMarginItems: number;
  perishableItems: number;
  earliestExpiry: string | null;
}

// ============================================
// DEFAULTS / HELPERS
// ============================================

export const createEmptyItem = (): PurchaseItem => ({
  id: crypto.randomUUID(),
  productId: '',
  productName: '',
  sku: '',
  isPerishable: false,
  unit: 'stem',
  quantity: 0,
  expectedCostPerUnit: 0,
  total: 0,
  shelfLifeDays: 0,
  sellingPrice: 0,
  marginPercent: 0,
  marginAmount: 0,
});

export const defaultPurchaseHeader: PurchaseHeader = {
  supplierId: '',
  expectedDeliveryDate: '',
  paymentTerms: 'net_30',
  location: '',
  shippingCost: 0,
  notes: '',
  invoiceImage: null,
  taxRate: 0,
};

// ============================================
// LOCATIONS (multi-location ready)
// ============================================

export const LOCATIONS = [
  { value: 'main_store', label: 'Main Store' },
  { value: 'warehouse', label: 'Warehouse' },
  { value: 'branch_1', label: 'Branch — Downtown' },
  { value: 'branch_2', label: 'Branch — Mall Location' },
] as const;
