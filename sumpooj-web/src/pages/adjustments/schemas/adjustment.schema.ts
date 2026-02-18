/**
 * Inventory Adjustment — Zod Validation Schema (Zod v4)
 */

import { z } from 'zod';

export const adjustmentSchema = z
  .object({
    productId: z.string().min(1, 'Product is required'),
    batchId: z.string(),
    adjustmentType: z.string().min(1, 'Adjustment type is required'),
    quantity: z
      .number({ message: 'Quantity is required' })
      .positive('Quantity must be greater than 0'),
    reason: z.string().max(500, 'Reason must be under 500 characters'),
    adjustedBy: z.string().min(1, 'Adjusted by is required'),
    adjustmentDate: z.string().min(1, 'Date is required'),
  })
  .superRefine((data, ctx) => {
    // Batch required for perishable — validated in the component
    // since we need product context. Schema-level: we validate
    // conditional reason requirement.
    if (
      (data.adjustmentType === 'spoiled' || data.adjustmentType === 'damaged') &&
      (!data.reason || data.reason.trim().length === 0)
    ) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message: 'Reason is required for Spoiled or Damaged adjustments',
        path: ['reason'],
      });
    }
  });

export type AdjustmentSchemaType = z.infer<typeof adjustmentSchema>;
