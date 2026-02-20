/**
 * InvoiceConfig.ts — Multi-Tax-System Invoice Template Configuration
 *
 * Provides country-aware labels, columns, and footer text for invoices.
 * Each tax system has different requirements:
 *   - SALES_TAX (US): Single "Sales Tax" line, no tax registration on invoice
 *   - GST (India): CGST + SGST or IGST lines, mandatory GSTIN display
 *   - VAT (UAE): Single "VAT" line, mandatory TRN display
 */

import type { TaxSystemType } from '../tenant/TenantTypes';

// ─── Invoice Configuration Model ────────────────────────────

export interface InvoiceConfig {
  /** Label shown for the tax line (e.g. "Sales Tax", "GST", "VAT") */
  taxLabel: string;

  /** Whether to show the tax registration number on invoice */
  showTaxRegistrationNumber: boolean;

  /** Label for the registration number (e.g. "GSTIN", "TRN", "Tax ID") */
  taxRegistrationLabel: string;

  /** Whether to show split tax lines (CGST+SGST for GST) */
  showTaxSplit: boolean;

  /** Invoice footer note (legal/regulatory text) */
  footerNote: string;

  /** Column headers for the invoice line items table */
  lineItemColumns: string[];

  /** Whether to show HSN/SAC codes (mandatory for GST) */
  showHSNCode: boolean;

  /** Label for the subtotal line */
  subtotalLabel: string;

  /** Label for the total line */
  totalLabel: string;

  /** Label for the discount line */
  discountLabel: string;
}

// ─── Default Invoice Configs per Tax System ─────────────────

export const INVOICE_CONFIGS: Record<TaxSystemType, InvoiceConfig> = {
  SALES_TAX: {
    taxLabel: 'Sales Tax',
    showTaxRegistrationNumber: false,
    taxRegistrationLabel: 'Tax ID',
    showTaxSplit: false,
    footerNote: 'Thank you for your business!',
    lineItemColumns: ['Item', 'Qty', 'Unit Price', 'Discount', 'Tax', 'Total'],
    showHSNCode: false,
    subtotalLabel: 'Subtotal',
    totalLabel: 'Total',
    discountLabel: 'Discount',
  },

  GST: {
    taxLabel: 'GST',
    showTaxRegistrationNumber: true,
    taxRegistrationLabel: 'GSTIN',
    showTaxSplit: true,
    footerNote:
      'This is a computer-generated invoice and does not require a signature. ' +
      'Subject to jurisdiction. E&OE.',
    lineItemColumns: ['Item', 'HSN/SAC', 'Qty', 'Unit Price', 'Discount', 'CGST', 'SGST', 'Total'],
    showHSNCode: true,
    subtotalLabel: 'Subtotal',
    totalLabel: 'Grand Total',
    discountLabel: 'Discount',
  },

  VAT: {
    taxLabel: 'VAT',
    showTaxRegistrationNumber: true,
    taxRegistrationLabel: 'TRN',
    showTaxSplit: false,
    footerNote: 'Prices are inclusive of VAT where applicable.',
    lineItemColumns: ['Item', 'Qty', 'Unit Price', 'Discount', 'VAT', 'Total'],
    showHSNCode: false,
    subtotalLabel: 'Subtotal (excl. VAT)',
    totalLabel: 'Total (incl. VAT)',
    discountLabel: 'Discount',
  },
};

/**
 * Get the invoice config for a tax system.
 */
export function getInvoiceConfig(taxSystem: TaxSystemType): InvoiceConfig {
  return INVOICE_CONFIGS[taxSystem] ?? INVOICE_CONFIGS.SALES_TAX;
}
