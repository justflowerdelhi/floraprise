/**
 * Purchase Entry Form — Zod Validation Schema
 */

import { z } from 'zod';

// ============================================
// PURCHASE ITEM SCHEMA
// ============================================

export const purchaseItemSchema = z.object({
  id: z.string(),
  productId: z.string().min(1, 'Product is required'),
  productName: z.string(),
  sku: z.string(),
  isPerishable: z.boolean(),
  unit: z.string().min(1, 'Unit is required'),
  quantity: z
    .number({ message: 'Quantity is required' })
    .positive('Quantity must be greater than 0'),
  costPerUnit: z
    .number({ message: 'Cost is required' })
    .positive('Cost must be greater than 0'),
  total: z.number(),
  // Perishable fields (conditionally required via superRefine)
  batchNumber: z.string(),
  purchaseDate: z.string(),
  shelfLifeDays: z.number(),
  expiryDate: z.string(),
  storageLocation: z.string(),
  // Margin
  sellingPrice: z.number(),
  marginPercent: z.number(),
  marginAmount: z.number(),
}).superRefine((item, ctx) => {
  if (item.isPerishable) {
    if (!item.batchNumber || item.batchNumber.trim() === '') {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message: 'Batch number is required for perishable items',
        path: ['batchNumber'],
      });
    }
    if (!item.expiryDate) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message: 'Expiry date is required for perishable items',
        path: ['expiryDate'],
      });
    }
    if (!item.storageLocation) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message: 'Storage location is required for perishable items',
        path: ['storageLocation'],
      });
    }
  }
});

// ============================================
// PURCHASE HEADER SCHEMA
// ============================================

export const purchaseHeaderSchema = z.object({
  supplierId: z.string().min(1, 'Supplier is required'),
  invoiceNumber: z
    .string()
    .min(1, 'Invoice number is required')
    .max(50, 'Invoice number must be less than 50 characters'),
  purchaseDate: z.string().min(1, 'Purchase date is required'),
  expectedDeliveryDate: z.string().min(1, 'Expected delivery date is required'),
  paymentTerms: z.string().min(1, 'Payment terms are required'),
  location: z.string().min(1, 'Location is required'),
  shippingCost: z.number().min(0, 'Shipping cost cannot be negative'),
  notes: z.string().max(500, 'Notes must be less than 500 characters'),
  invoiceImage: z.any().nullable(),
  taxRate: z.number().min(0),
});

// ============================================
// FULL FORM SCHEMA
// ============================================

export const purchaseFormSchema = z.object({
  header: purchaseHeaderSchema,
  items: z
    .array(purchaseItemSchema)
    .min(1, 'At least one product item is required'),
});

export type PurchaseFormSchemaType = z.infer<typeof purchaseFormSchema>;
