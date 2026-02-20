/**
 * TaxEngine.ts — Multi-Tax-System Engine
 *
 * Supports:
 * - SALES_TAX (US): Single-rate per jurisdiction
 * - GST (India): CGST + SGST (intra-state) or IGST (inter-state)
 * - VAT (UAE / Europe): Single-rate inclusive/exclusive
 *
 * Tax profiles are configurable per tenant. Orders store their
 * taxProfileId so historical orders remain correct even if rates change.
 */

import type { TaxSystemType } from '../tenant/TenantTypes';

// ─── Tax Profile Model ──────────────────────────────────────

export interface TaxProfile {
  id: string;
  name: string;                       // e.g. "Standard GST", "NYC Sales Tax"
  taxSystem: TaxSystemType;
  rate: number;                       // e.g. 0.18 = 18%
  isInclusive: boolean;              // true = price includes tax (common in VAT)
  isDefault: boolean;

  // GST-specific split
  gstSplit?: {
    cgst: number;                    // e.g. 0.09 = 9%
    sgst: number;                    // e.g. 0.09 = 9%
    igst: number;                    // e.g. 0.18 = 18% (inter-state)
  };

  // Jurisdiction info
  jurisdiction?: string;             // e.g. "Maharashtra", "New York", "Dubai"
  registrationLabel?: string;        // e.g. "GSTIN", "Tax ID", "TRN"
}

// ─── Tax Calculation Result ─────────────────────────────────

export interface TaxBreakdown {
  taxProfileId: string;
  taxProfileName: string;
  taxSystem: TaxSystemType;
  baseAmount: number;                // Pre-tax amount
  taxAmount: number;                 // Total tax
  totalAmount: number;               // base + tax (or original amount if inclusive)

  // Detailed line items for invoice display
  lineItems: TaxLineItem[];
}

export interface TaxLineItem {
  label: string;                     // e.g. "CGST @9%", "Sales Tax @8.875%", "VAT @5%"
  rate: number;
  amount: number;
}

// ─── Tax Calculator ─────────────────────────────────────────

/**
 * Calculate tax breakdown for a given amount and tax profile.
 * @param amount  The line total (exclusive or inclusive depending on profile)
 * @param profile The tax profile to apply
 * @param isInterState  (GST only) true for IGST, false for CGST+SGST
 */
export function calculateTax(
  amount: number,
  profile: TaxProfile,
  isInterState: boolean = false,
): TaxBreakdown {
  const round2 = (n: number) => Math.round(n * 100) / 100;

  let baseAmount: number;
  let taxAmount: number;
  let lineItems: TaxLineItem[];

  if (profile.isInclusive) {
    // Price includes tax — extract tax from amount
    baseAmount = round2(amount / (1 + profile.rate));
    taxAmount = round2(amount - baseAmount);
  } else {
    // Price excludes tax — add tax on top
    baseAmount = amount;
    taxAmount = round2(amount * profile.rate);
  }

  // Build line items based on tax system
  switch (profile.taxSystem) {
    case 'GST': {
      if (profile.gstSplit) {
        if (isInterState) {
          lineItems = [
            {
              label: `IGST @${(profile.gstSplit.igst * 100).toFixed(0)}%`,
              rate: profile.gstSplit.igst,
              amount: taxAmount,
            },
          ];
        } else {
          const halfTax = round2(taxAmount / 2);
          lineItems = [
            {
              label: `CGST @${(profile.gstSplit.cgst * 100).toFixed(0)}%`,
              rate: profile.gstSplit.cgst,
              amount: halfTax,
            },
            {
              label: `SGST @${(profile.gstSplit.sgst * 100).toFixed(0)}%`,
              rate: profile.gstSplit.sgst,
              amount: round2(taxAmount - halfTax), // avoid rounding drift
            },
          ];
        }
      } else {
        lineItems = [
          {
            label: `GST @${(profile.rate * 100).toFixed(0)}%`,
            rate: profile.rate,
            amount: taxAmount,
          },
        ];
      }
      break;
    }

    case 'VAT':
      lineItems = [
        {
          label: `VAT @${(profile.rate * 100).toFixed(0)}%`,
          rate: profile.rate,
          amount: taxAmount,
        },
      ];
      break;

    case 'SALES_TAX':
    default:
      lineItems = [
        {
          label: `Sales Tax @${(profile.rate * 100).toFixed(3)}%`,
          rate: profile.rate,
          amount: taxAmount,
        },
      ];
      break;
  }

  return {
    taxProfileId: profile.id,
    taxProfileName: profile.name,
    taxSystem: profile.taxSystem,
    baseAmount,
    taxAmount,
    totalAmount: round2(baseAmount + taxAmount),
    lineItems,
  };
}

// ─── Default Tax Profiles ───────────────────────────────────

export const DEFAULT_TAX_PROFILES: TaxProfile[] = [
  {
    id: 'tp_us_ny',
    name: 'NYC Sales Tax',
    taxSystem: 'SALES_TAX',
    rate: 0.08875,
    isInclusive: false,
    isDefault: false,
    jurisdiction: 'New York City',
    registrationLabel: 'Tax ID',
  },
  {
    id: 'tp_us_ca',
    name: 'CA Sales Tax',
    taxSystem: 'SALES_TAX',
    rate: 0.0725,
    isInclusive: false,
    isDefault: false,
    jurisdiction: 'California',
    registrationLabel: 'Tax ID',
  },
  {
    id: 'tp_in_gst_18',
    name: 'GST 18%',
    taxSystem: 'GST',
    rate: 0.18,
    isInclusive: false,
    isDefault: true,
    gstSplit: { cgst: 0.09, sgst: 0.09, igst: 0.18 },
    jurisdiction: 'India',
    registrationLabel: 'GSTIN',
  },
  {
    id: 'tp_in_gst_12',
    name: 'GST 12%',
    taxSystem: 'GST',
    rate: 0.12,
    isInclusive: false,
    isDefault: false,
    gstSplit: { cgst: 0.06, sgst: 0.06, igst: 0.12 },
    jurisdiction: 'India',
    registrationLabel: 'GSTIN',
  },
  {
    id: 'tp_in_gst_5',
    name: 'GST 5%',
    taxSystem: 'GST',
    rate: 0.05,
    isInclusive: false,
    isDefault: false,
    gstSplit: { cgst: 0.025, sgst: 0.025, igst: 0.05 },
    jurisdiction: 'India',
    registrationLabel: 'GSTIN',
  },
  {
    id: 'tp_ae_vat',
    name: 'UAE VAT 5%',
    taxSystem: 'VAT',
    rate: 0.05,
    isInclusive: true,
    isDefault: false,
    jurisdiction: 'UAE',
    registrationLabel: 'TRN',
  },
];

/**
 * Get the default tax profile for a given tax system.
 */
export function getDefaultTaxProfile(taxSystem: TaxSystemType): TaxProfile {
  return (
    DEFAULT_TAX_PROFILES.find((p) => p.taxSystem === taxSystem && p.isDefault) ??
    DEFAULT_TAX_PROFILES.find((p) => p.taxSystem === taxSystem) ??
    DEFAULT_TAX_PROFILES[0]
  );
}

/**
 * Get all tax profiles for a given tax system.
 */
export function getTaxProfilesBySystem(taxSystem: TaxSystemType): TaxProfile[] {
  return DEFAULT_TAX_PROFILES.filter((p) => p.taxSystem === taxSystem);
}

/**
 * Find a tax profile by ID.
 */
export function getTaxProfileById(id: string): TaxProfile | undefined {
  return DEFAULT_TAX_PROFILES.find((p) => p.id === id);
}

/**
 * Get the tax registration label for a tax system.
 * e.g. GST → "GSTIN", SALES_TAX → "Tax ID", VAT → "TRN"
 */
export function getTaxRegistrationLabel(taxSystem: TaxSystemType): string {
  switch (taxSystem) {
    case 'GST':
      return 'GSTIN';
    case 'VAT':
      return 'TRN';
    case 'SALES_TAX':
    default:
      return 'Tax ID';
  }
}
