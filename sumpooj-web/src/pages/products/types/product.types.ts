/**
 * Product Types & Interfaces
 * Florist POS + ERP SaaS Platform
 */

// ============================================
// ENUMS & CONSTANTS
// ============================================

export const PRODUCT_TYPES = [
  { value: 'fresh_flower', label: 'Fresh Flower' },
  { value: 'dried_flower', label: 'Dried/Preserved Flower' },
  { value: 'plant', label: 'Plant' },
  { value: 'arrangement', label: 'Arrangement' },
  { value: 'bouquet', label: 'Bouquet' },
  { value: 'gift_item', label: 'Gift Item' },
  { value: 'container', label: 'Container/Vase' },
  { value: 'ribbon', label: 'Ribbon/Accessories' },
  { value: 'supply', label: 'Floral Supply' },
  { value: 'service', label: 'Service' },
] as const;

export const UNITS_OF_MEASURE = [
  { value: 'each', label: 'Each' },
  { value: 'stem', label: 'Stem' },
  { value: 'bunch', label: 'Bunch' },
  { value: 'box', label: 'Box' },
  { value: 'case', label: 'Case' },
  { value: 'dozen', label: 'Dozen' },
  { value: 'foot', label: 'Foot' },
  { value: 'yard', label: 'Yard' },
  { value: 'roll', label: 'Roll' },
  { value: 'pack', label: 'Pack' },
] as const;

export const TAX_CATEGORIES = [
  { value: 'standard', label: 'Standard Rate' },
  { value: 'reduced', label: 'Reduced Rate' },
  { value: 'exempt', label: 'Tax Exempt' },
  { value: 'zero', label: 'Zero Rated' },
] as const;

export const INCOME_ACCOUNTS = [
  { value: '4000', label: '4000 - Product Sales' },
  { value: '4010', label: '4010 - Fresh Flower Sales' },
  { value: '4020', label: '4020 - Plant Sales' },
  { value: '4030', label: '4030 - Gift Sales' },
  { value: '4040', label: '4040 - Service Revenue' },
  { value: '4050', label: '4050 - Event Revenue' },
] as const;

export const EXPENSE_ACCOUNTS = [
  { value: '5000', label: '5000 - Cost of Goods Sold' },
  { value: '5010', label: '5010 - Fresh Flower Purchases' },
  { value: '5020', label: '5020 - Plant Purchases' },
  { value: '5030', label: '5030 - Supply Purchases' },
  { value: '5040', label: '5040 - Delivery Costs' },
] as const;

export const SEASONALITY_OPTIONS = [
  { value: 'year_round', label: 'Year Round' },
  { value: 'spring', label: 'Spring' },
  { value: 'summer', label: 'Summer' },
  { value: 'fall', label: 'Fall' },
  { value: 'winter', label: 'Winter' },
  { value: 'valentines', label: "Valentine's Day" },
  { value: 'mothers_day', label: "Mother's Day" },
  { value: 'christmas', label: 'Christmas' },
  { value: 'wedding_season', label: 'Wedding Season' },
] as const;

export const FLOWER_GRADES = [
  { value: 'premium', label: 'Premium' },
  { value: 'select', label: 'Select' },
  { value: 'standard', label: 'Standard' },
  { value: 'economy', label: 'Economy' },
] as const;

export const COUNTRIES = [
  { value: 'USA', label: 'United States' },
  { value: 'COL', label: 'Colombia' },
  { value: 'ECU', label: 'Ecuador' },
  { value: 'NLD', label: 'Netherlands' },
  { value: 'KEN', label: 'Kenya' },
  { value: 'ETH', label: 'Ethiopia' },
  { value: 'CAN', label: 'Canada' },
  { value: 'MEX', label: 'Mexico' },
  { value: 'PER', label: 'Peru' },
  { value: 'TWN', label: 'Taiwan' },
] as const;

export type ProductType = typeof PRODUCT_TYPES[number]['value'];
export type UnitOfMeasure = typeof UNITS_OF_MEASURE[number]['value'];
export type TaxCategory = typeof TAX_CATEGORIES[number]['value'];
export type IncomeAccount = typeof INCOME_ACCOUNTS[number]['value'];
export type ExpenseAccount = typeof EXPENSE_ACCOUNTS[number]['value'];
export type Seasonality = typeof SEASONALITY_OPTIONS[number]['value'];
export type FlowerGrade = typeof FLOWER_GRADES[number]['value'];
export type CountryCode = typeof COUNTRIES[number]['value'];

// ============================================
// DYNAMIC CATEGORY (from API)
// ============================================

export interface CategoryOption {
  id: string;
  name: string;
  isPerishable: boolean;
  trackBatchByDefault: boolean;
  isActive: boolean;
}

// ============================================
// SUPPLIER INTERFACE
// ============================================

export interface Supplier {
  id: string;
  name: string;
  code: string;
  email?: string;
  phone?: string;
  leadTime?: number;
}

// ============================================
// PRODUCT INTENT TYPE
// ============================================

export type ProductIntent = 'fresh_flower' | 'bouquet' | 'gift_item' | 'raw_material';

// ============================================
// PRODUCT FORM DATA INTERFACE
// ============================================

export interface ProductFormData {
  // Product Intent (top-level selector)
  productIntent: ProductIntent;

  // Basic Info (Required)
  productName: string;
  productType: ProductType;
  categoryId: string;
  sku: string;
  unitOfMeasure: UnitOfMeasure;
  retailPrice: number;
  costPrice: number;
  trackInventory: boolean;
  status: 'active' | 'inactive';

  // Basic Info (Optional)
  barcodeInputMethod?: 'scan' | 'auto_generate' | 'none';
  barcode?: string;
  internalBarcode?: string;
  brand?: string;
  description?: string;

  // Inventory Section
  openingStock?: number;
  reorderLevel?: number;
  trackBatch: boolean;

  // Perishable Section
  isPerishable: boolean;
  shelfLifeDays?: number;
  expiryAlertDays?: number;
  temperatureNotes?: string;

  // Pricing Section
  taxCategory: TaxCategory;
  wholesalePrice?: number;
  weddingEventPrice?: number;

  // Flower-Specific (Optional)
  color?: string;
  variety?: string;
  grade?: FlowerGrade;
  countryOfOrigin?: CountryCode;
  seasonality?: Seasonality[];

  // Supplier Info (Optional)
  supplierId?: string;
  leadTimeDays?: number;

  // Accounting (Required)
  incomeAccount: IncomeAccount;
  expenseAccount: ExpenseAccount;

  // Settings (Optional)
  allowAsRawMaterial: boolean;
  availableOnline: boolean;
  commissionEligible: boolean;

  // Images (UI Only)
  images?: File[];
  imageUrls?: string[];

  // Tags
  tags?: string[];

  // Multi-unit flower configuration
  isMultiUnit?: boolean; // If true, product supports multi-unit consumption
  baseUnit?: 'STEM'; // Always STEM for flowers, default STEM
  consumptionUnit?: 'STEM' | 'BUD' | 'BLOOM'; // Allowed values
  avgUnitsPerStem?: number; // Default 1, >1 if isMultiUnit
  allowPartialConsumption?: boolean; // If true, partial consumption allowed
}

// ============================================
// API PAYLOAD STRUCTURE
// ============================================

export interface ProductApiPayload {
  // Core identification
  productName: string;
  sku: string;
  // Multi-unit flower configuration
  isMultiUnit?: boolean;
  baseUnit?: 'STEM';
  consumptionUnit?: 'STEM' | 'BUD' | 'BLOOM';
  avgUnitsPerStem?: number;
  allowPartialConsumption?: boolean;
  barcodeInputMethod?: 'scan' | 'auto_generate' | 'none';
  barcode?: string;
  internalBarcode?: string;
  
  // Classification
  productType: ProductType;
  categoryId?: string;
  brand?: string;
  description?: string;
  tags?: string[];
  
  // Units & Pricing
  unitOfMeasure: UnitOfMeasure;
  retailPrice: number;
  costPrice: number;
  wholesalePrice?: number;
  weddingEventPrice?: number;
  
  // Taxation
  taxCategory: TaxCategory;
  
  // Inventory
  trackInventory: boolean;
  trackBatch: boolean;
  openingStock?: number;
  reorderLevel?: number;
  
  // Perishable details (IsPerishable is derived from category)
  shelfLifeDays?: number;
  expiryAlertDays?: number;
  temperatureNotes?: string;
  
  // Flower Attributes
  flowerAttributes?: {
    color?: string;
    variety?: string;
    grade?: FlowerGrade;
    countryOfOrigin?: CountryCode;
    seasonality?: Seasonality[];
  };
  
  // Supplier
  supplier?: {
    supplierId?: string;
    leadTimeDays?: number;
  };
  
  // Accounting
  accounting: {
    incomeAccount: IncomeAccount;
    expenseAccount: ExpenseAccount;
  };
  
  // Settings
  settings: {
    status: 'active' | 'inactive';
    allowAsRawMaterial: boolean;
    availableOnline: boolean;
    commissionEligible: boolean;
  };
  
  // Images (would be uploaded separately)
  imageIds?: string[];
}

// ============================================
// FORM SECTION PROPS
// ============================================

export interface FormSectionProps {
  control: any;
  errors: any;
  watch: any;
  setValue: any;
  darkMode?: boolean;
}

// ============================================
// DEFAULT VALUES
// ============================================

export const defaultProductFormValues: ProductFormData = {
  productIntent: 'fresh_flower',
  productName: '',
  productType: 'fresh_flower',
  categoryId: '',
  sku: '',
  unitOfMeasure: 'stem',
  retailPrice: 0,
  costPrice: 0,
  trackInventory: true,
  trackBatch: false,
  status: 'active',
  isPerishable: false,
  taxCategory: 'standard',
  incomeAccount: '4000',
  expenseAccount: '5000',
  allowAsRawMaterial: false,
  availableOnline: false,
  commissionEligible: false,
  tags: [],
  // Multi-unit flower configuration defaults
  isMultiUnit: false,
  baseUnit: 'STEM',
  consumptionUnit: 'STEM',
  avgUnitsPerStem: 1,
  allowPartialConsumption: false,
};
