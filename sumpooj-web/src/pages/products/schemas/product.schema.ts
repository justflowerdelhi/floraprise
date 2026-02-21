/**
 * Product Form Validation Schema
 * Zod schema with comprehensive validation rules
 */

import { z } from 'zod';

export const productFormSchema = z.object({
  // ========================================
  // BASIC INFO (Required)
  // ========================================
  productName: z
    .string()
    .min(1, 'Product name is required')
    .min(2, 'Product name must be at least 2 characters')
    .max(100, 'Product name must be less than 100 characters'),

  productType: z.enum([
    'fresh_flower',
    'dried_flower',
    'plant',
    'arrangement',
    'bouquet',
    'gift_item',
    'container',
    'ribbon',
    'supply',
    'service',
  ]).default('fresh_flower'),

  categoryId: z
    .string()
    .min(1, 'Category is required'),

  sku: z
    .string()
    .min(1, 'SKU is required')
    .min(3, 'SKU must be at least 3 characters')
    .max(30, 'SKU must be less than 30 characters')
    .regex(/^[A-Za-z0-9-_]+$/, 'SKU can only contain letters, numbers, hyphens, and underscores'),

  unitOfMeasure: z.enum([
    'each',
    'stem',
    'bunch',
    'box',
    'case',
    'dozen',
    'foot',
    'yard',
    'roll',
    'pack',
  ]),

  retailPrice: z
    .number()
    .min(0, 'Retail price cannot be negative'),

  costPrice: z
    .number()
    .min(0, 'Cost price cannot be negative'),

  trackInventory: z.boolean().default(true),
  trackBatch: z.boolean().default(false),

  status: z.enum(['active', 'inactive']),

  // ========================================
  // BASIC INFO (Optional)
  // ========================================
  barcodeInputMethod: z
    .enum(['scan', 'auto_generate', 'none'])
    .default('none'),

  barcode: z
    .string()
    .max(50, 'Barcode must be less than 50 characters')
    .optional()
    .or(z.literal('')),

  internalBarcode: z
    .string()
    .max(50, 'Internal barcode must be less than 50 characters')
    .optional()
    .or(z.literal('')),

  brand: z
    .string()
    .max(50, 'Brand must be less than 50 characters')
    .optional()
    .or(z.literal('')),

  description: z
    .string()
    .max(1000, 'Description must be less than 1000 characters')
    .optional()
    .or(z.literal('')),

  // ========================================
  // INVENTORY SECTION
  // ========================================
  openingStock: z
    .number()
    .int('Opening stock must be a whole number')
    .min(0, 'Opening stock cannot be negative')
    .optional(),

  reorderLevel: z
    .number()
    .int('Reorder level must be a whole number')
    .min(0, 'Reorder level cannot be negative')
    .optional(),

  // ========================================
  // PERISHABLE SECTION
  // ========================================
  isPerishable: z.boolean().default(false),

  shelfLifeDays: z
    .number()
    .int('Shelf life must be a whole number')
    .min(1, 'Shelf life must be at least 1 day')
    .max(365, 'Shelf life cannot exceed 365 days')
    .optional(),

  expiryAlertDays: z
    .number()
    .int('Expiry alert days must be a whole number')
    .min(1, 'Expiry alert must be at least 1 day')
    .optional(),

  temperatureNotes: z
    .string()
    .max(200, 'Temperature notes must be less than 200 characters')
    .optional()
    .or(z.literal('')),

  // ========================================
  // PRICING SECTION
  // ========================================
  taxCategory: z.enum(['standard', 'reduced', 'exempt', 'zero']),

  wholesalePrice: z
    .number()
    .min(0, 'Wholesale price cannot be negative')
    .optional(),

  weddingEventPrice: z
    .number()
    .min(0, 'Wedding/Event price cannot be negative')
    .optional(),

  // ========================================
  // FLOWER ATTRIBUTES (Optional)
  // ========================================
  color: z
    .string()
    .max(50, 'Color must be less than 50 characters')
    .optional()
    .or(z.literal('')),

  variety: z
    .string()
    .max(50, 'Variety must be less than 50 characters')
    .optional()
    .or(z.literal('')),

  grade: z
    .enum(['premium', 'select', 'standard', 'economy'])
    .optional(),

  countryOfOrigin: z
    .enum(['USA', 'COL', 'ECU', 'NLD', 'KEN', 'ETH', 'CAN', 'MEX', 'PER', 'TWN'])
    .optional(),

  seasonality: z
    .array(z.enum([
      'year_round',
      'spring',
      'summer',
      'fall',
      'winter',
      'valentines',
      'mothers_day',
      'christmas',
      'wedding_season',
    ]))
    .optional(),

  // ========================================
  // SUPPLIER INFO (Optional)
  // ========================================
  supplierId: z.string().optional().or(z.literal('')),

  leadTimeDays: z
    .number()
    .int('Lead time must be a whole number')
    .min(0, 'Lead time cannot be negative')
    .max(365, 'Lead time cannot exceed 365 days')
    .optional(),

  // ========================================
  // ACCOUNTING (Required)
  // ========================================
  incomeAccount: z.enum(['4000', '4010', '4020', '4030', '4040', '4050']),

  expenseAccount: z.enum(['5000', '5010', '5020', '5030', '5040']),

  // ========================================
  // SETTINGS (Optional with defaults)
  // ========================================
  allowAsRawMaterial: z.boolean().default(false),
  availableOnline: z.boolean().default(false),
  commissionEligible: z.boolean().default(false),

  // ========================================
  // IMAGES & TAGS
  // ========================================
  images: z.array(z.any()).optional(),
  imageUrls: z.array(z.string()).optional(),
  tags: z.array(z.string()).optional(),
})
// ========================================
// CROSS-FIELD VALIDATIONS
// ========================================
.refine(
  (data) => data.retailPrice >= data.costPrice,
  {
    message: 'Retail price must be greater than or equal to cost price',
    path: ['retailPrice'],
  }
)
.refine(
  (data) => {
    // Shelf life required for perishable products
    if (data.isPerishable) {
      return data.shelfLifeDays !== undefined && data.shelfLifeDays > 0;
    }
    return true;
  },
  {
    message: 'Shelf life is required for perishable products',
    path: ['shelfLifeDays'],
  }
)
.refine(
  (data) => {
    // Opening stock required if track inventory is enabled
    if (data.trackInventory) {
      return data.openingStock !== undefined;
    }
    return true;
  },
  {
    message: 'Opening stock is required when tracking inventory',
    path: ['openingStock'],
  }
)
.refine(
  (data) => {
    // Reorder level required if track inventory is enabled
    if (data.trackInventory) {
      return data.reorderLevel !== undefined;
    }
    return true;
  },
  {
    message: 'Reorder level is required when tracking inventory',
    path: ['reorderLevel'],
  }
);

export type ProductFormSchema = z.infer<typeof productFormSchema>;

// ========================================
// VALIDATION HELPERS
// ========================================

export const isLowShelfLife = (days: number | undefined): boolean => {
  return days !== undefined && days < 5;
};

export const calculateMarginPercent = (
  retailPrice: number,
  costPrice: number
): number => {
  if (retailPrice <= 0) return 0;
  return Math.round(((retailPrice - costPrice) / retailPrice) * 100 * 10) / 10;
};

export const calculateEstimatedExpiryDate = (
  shelfLifeDays: number | undefined
): Date | null => {
  if (!shelfLifeDays) return null;
  const today = new Date();
  today.setDate(today.getDate() + shelfLifeDays);
  return today;
};

export const formatExpiryDate = (date: Date | null): string => {
  if (!date) return '';
  return date.toLocaleDateString('en-US', {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
  });
};
