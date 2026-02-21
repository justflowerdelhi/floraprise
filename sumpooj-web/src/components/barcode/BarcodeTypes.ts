/**
 * Barcode Types & Interfaces
 * Complete Barcode & Label System
 * Florist POS + ERP SaaS Platform
 */

// ============================================
// BARCODE TYPE ENUM
// ============================================

export type BarcodeSourceType = 
  | 'EXTERNAL'      // Scanned manufacturer barcode
  | 'INTERNAL'      // Auto-generated internal barcode
  | 'BATCH'         // Auto-generated batch barcode
  | 'FINISHED';     // Auto-generated finished goods barcode

export type BarcodeFormat = 'CODE128' | 'EAN13' | 'UPC' | 'CODE39';

// ============================================
// BARCODE DATA INTERFACES
// ============================================

export interface BarcodeData {
  /** The barcode value/number */
  value: string;
  /** Source type of the barcode */
  type: BarcodeSourceType;
  /** Format of the barcode */
  format: BarcodeFormat;
  /** When the barcode was created */
  createdAt: string;
  /** Whether this is the primary barcode for the item */
  isPrimary: boolean;
}

export interface ProductBarcodes {
  /** External manufacturer barcode (scanned) */
  externalBarcode?: string;
  /** Internal auto-generated barcode */
  internalBarcode?: string;
}

export interface BatchBarcodes {
  /** Batch-specific barcode */
  batchBarcode: string;
  /** Parent product barcodes */
  productBarcodes?: ProductBarcodes;
}

export interface FinishedGoodBarcodes {
  /** Finished product barcode */
  finishedBarcode: string;
  /** Recipe/source batch info */
  sourceBatchBarcode?: string;
}

// ============================================
// LABEL CONFIGURATION
// ============================================

export interface LabelConfig {
  /** Width in mm (default: 50mm for thermal) */
  width: number;
  /** Height in mm (default: 25mm for thermal) */
  height: number;
  /** Show price on label */
  includePrice: boolean;
  /** Show expiry date on label */
  includeExpiry: boolean;
  /** Number of copies to print */
  quantity: number;
  /** Barcode format */
  barcodeFormat: BarcodeFormat;
}

export interface LabelData {
  /** Product/batch/item name */
  name: string;
  /** SKU or batch code */
  sku: string;
  /** Barcode value to render */
  barcode: string;
  /** Price (optional) */
  price?: number;
  /** Expiry date (optional) */
  expiryDate?: string;
  /** Additional info line */
  additionalInfo?: string;
}

// ============================================
// DEFAULT CONFIGURATIONS
// ============================================

export const DEFAULT_LABEL_CONFIG: LabelConfig = {
  width: 50,
  height: 25,
  includePrice: true,
  includeExpiry: false,
  quantity: 1,
  barcodeFormat: 'CODE128',
};

// Thermal printer label sizes (common standards)
export const LABEL_SIZES = [
  { value: '50x25', label: '50mm × 25mm (Standard)', width: 50, height: 25 },
  { value: '40x20', label: '40mm × 20mm (Small)', width: 40, height: 20 },
  { value: '60x30', label: '60mm × 30mm (Large)', width: 60, height: 30 },
  { value: '80x40', label: '80mm × 40mm (XL)', width: 80, height: 40 },
] as const;

// ============================================
// BARCODE PREFIXES
// ============================================

export const BARCODE_PREFIXES = {
  /** Internal product barcode prefix */
  INTERNAL: 'INT',
  /** Batch barcode prefix */
  BATCH: 'BAT',
  /** Finished goods barcode prefix */
  FINISHED: 'FIN',
} as const;

// ============================================
// BARCODE SEARCH RESULT
// ============================================

export interface BarcodeSearchResult {
  /** Whether a match was found */
  found: boolean;
  /** Type of barcode that matched */
  matchType?: BarcodeSourceType;
  /** Product ID if matched */
  productId?: string;
  /** Batch ID if matched */
  batchId?: string;
  /** Product name */
  productName?: string;
  /** SKU */
  sku?: string;
  /** Price */
  price?: number;
  /** Cost price */
  costPrice?: number;
  /** Available quantity */
  quantity?: number;
  /** Is perishable */
  isPerishable?: boolean;
  /** Tax rate */
  taxRate?: number;
  /** Category */
  category?: string;
}

// ============================================
// BARCODE GENERATION REQUEST
// ============================================

export interface GenerateBarcodeRequest {
  /** Type of barcode to generate */
  type: 'INTERNAL' | 'BATCH' | 'FINISHED';
  /** Entity ID (product, batch, or production record) */
  entityId: string;
  /** Entity type for reference */
  entityType: 'product' | 'batch' | 'finished_good';
}

export interface GenerateBarcodeResponse {
  /** Generated barcode value */
  barcode: string;
  /** Type of barcode */
  type: BarcodeSourceType;
  /** Format */
  format: BarcodeFormat;
}

// ============================================
// BARCODE VALIDATION
// ============================================

export interface BarcodeValidationResult {
  /** Is the barcode valid */
  isValid: boolean;
  /** Is the barcode unique (not already used) */
  isUnique: boolean;
  /** Error message if invalid */
  errorMessage?: string;
  /** Suggested format if detected differently */
  detectedFormat?: BarcodeFormat;
}
