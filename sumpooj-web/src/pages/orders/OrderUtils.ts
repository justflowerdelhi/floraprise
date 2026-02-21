/**
 * OrderUtils.ts — Order creation helpers & commission calculations
 *
 * - Build Order from cart + customer data
 * - Commission-aware profit for external platforms
 * - Accept external order → unified Order model
 */
import type {
  Order, OrderSource, CartItem, CartSummary, ExternalOrder,

} from './OrderTypes';
import { formatCurrency } from '../../core/i18n';

let _orderSeq = 100;

/** Generate next order number: ORD-YYYY-NNNN */
export const nextOrderNumber = (): string => {
  _orderSeq += 1;
  const year = new Date().getFullYear();
  return `ORD-${year}-${String(_orderSeq).padStart(4, '0')}`;
};

/** Generate a unique order ID */
export const nextOrderId = (): string => `ord_${Date.now()}_${Math.random().toString(36).slice(2, 6)}`;

// ─── Commission Calculation ─────────────────────────────────

export interface CommissionBreakdown {
  grossRevenue: number;
  platformCommission: number;
  platformFees: number;
  netPayout: number;
  netMarginPercent: number;
  fifoCost: number;
  actualProfit: number;
  actualProfitPercent: number;
}

/**
 * Calculate commission-aware profit for external platform orders.
 *
 * netPayout = grossRevenue - commission - fees
 * actualProfit = netPayout - fifoCost
 */
export const calcCommissionBreakdown = (
  grossRevenue: number,
  commission: number,
  fees: number,
  fifoCost: number,
): CommissionBreakdown => {
  const netPayout = grossRevenue - commission - fees;
  const actualProfit = netPayout - fifoCost;
  const netMarginPercent = grossRevenue > 0
    ? Math.round((netPayout / grossRevenue) * 1000) / 10
    : 0;
  const actualProfitPercent = netPayout > 0
    ? Math.round((actualProfit / netPayout) * 1000) / 10
    : 0;

  return {
    grossRevenue,
    platformCommission: commission,
    platformFees: fees,
    netPayout,
    netMarginPercent,
    fifoCost,
    actualProfit,
    actualProfitPercent,
  };
};

// ─── Platform commission rates ──────────────────────────────

export const PLATFORM_COMMISSION_RATES: Record<'FTD' | 'BLOOMNATION', { commissionRate: number; flatFee: number }> = {
  FTD:         { commissionRate: 0.27, flatFee: 0 },    // 27% commission
  BLOOMNATION: { commissionRate: 0.10, flatFee: 0 },    // 10% commission
};

/**
 * Auto-calculate commission from gross amount based on platform defaults.
 */
export const calcPlatformCommission = (
  platform: 'FTD' | 'BLOOMNATION',
  grossAmount: number,
): { commission: number; fees: number } => {
  const rate = PLATFORM_COMMISSION_RATES[platform];
  return {
    commission: Math.round(grossAmount * rate.commissionRate * 100) / 100,
    fees: rate.flatFee,
  };
};

// ─── Build Order from cart ──────────────────────────────────

export interface CreateOrderParams {
  orderSource: OrderSource;
  items: CartItem[];
  totals: CartSummary;
  orderType?: Order['orderType'];
  customerName?: string;
  customerPhone?: string;
  senderName?: string;
  recipientName?: string;
  recipientPhone?: string;
  deliveryDate?: string;
  deliveryAddress?: string;
  deliveryInstructions?: string;
  cardMessage?: string;
  occasion?: string;
  notes?: string;
  // Wire management fields
  vendorFloristId?: string;
  vendorFloristName?: string;
  vendorAmount?: number;
  wireFee?: number;
  sourceNetwork?: string;
  commissionPercent?: number;
  netReceived?: number;
  settlementStatus?: Order['settlementStatus'];
  // External platform fields
  externalOrderId?: string;
  externalPlatform?: string;
  externalCommission?: number;
  externalFees?: number;
  netPayout?: number;
}

export const createOrder = (params: CreateOrderParams): Order => {
  const isExternal = params.orderSource === 'BLOOMNATION' || params.orderSource === 'FTD';
  const now = new Date().toISOString();

  return {
    id: nextOrderId(),
    orderNumber: nextOrderNumber(),
    orderSource: params.orderSource,
    orderType: params.orderType ?? 'LOCAL',

    externalOrderId: params.externalOrderId,
    externalPlatform: params.externalPlatform,
    isExternallyPaid: isExternal,
    isPriceEditable: !isExternal,

    senderName: params.senderName,
    customerName: params.customerName,
    customerPhone: params.customerPhone,

    recipientName: params.recipientName,
    recipientPhone: params.recipientPhone,

    deliveryDate: params.deliveryDate,
    deliveryAddress: params.deliveryAddress,
    deliveryInstructions: params.deliveryInstructions,
    cardMessage: params.cardMessage,
    occasion: params.occasion,

    externalCommission: params.externalCommission,
    externalFees: params.externalFees,
    netPayout: params.netPayout,

    vendorFloristId: params.vendorFloristId,
    vendorFloristName: params.vendorFloristName,
    vendorAmount: params.vendorAmount,
    wireFee: params.wireFee,
    sourceNetwork: params.sourceNetwork,
    commissionPercent: params.commissionPercent,
    netReceived: params.netReceived,
    settlementStatus: params.settlementStatus,

    fulfillmentStatus: 'DRAFT',
    paymentStatus: isExternal ? 'PAID' : 'UNPAID',

    items: params.items,
    totals: params.totals,
    notes: params.notes,

    createdAt: now,
    updatedAt: now,
  };
};

// ─── Accept external order → unified Order ──────────────────

export const acceptExternalOrder = (ext: ExternalOrder): Order => {
  const platform = ext.platform;
  const now = new Date().toISOString();

  return {
    id: nextOrderId(),
    orderNumber: nextOrderNumber(),
    orderSource: platform,
    orderType: 'LOCAL',

    externalOrderId: ext.externalOrderId,
    externalPlatform: platform,
    isExternallyPaid: true,
    isPriceEditable: false,

    senderName: ext.senderName,
    recipientName: ext.recipientName,
    recipientPhone: ext.recipientPhone,

    deliveryDate: ext.deliveryDate,
    deliveryAddress: ext.deliveryAddress,
    deliveryInstructions: ext.deliveryInstructions,
    cardMessage: ext.cardMessage,

    externalCommission: ext.commission,
    externalFees: ext.fees,
    netPayout: ext.netPayout,

    fulfillmentStatus: 'CONFIRMED',
    paymentStatus: 'PAID',

    items: [],  // Will be populated by the florist when designing
    totals: {
      subtotal: ext.grossAmount,
      taxTotal: 0,
      discountTotal: 0,
      orderDiscountAmount: 0,
      grandTotal: ext.grossAmount,
      totalCost: 0,
      marginPercent: 0,
      marginWarning: false,
      itemCount: ext.items.reduce((s, i) => s + i.quantity, 0),
      lineCount: ext.items.length,
      taxBreakdown: [],
    },

    createdAt: now,
    updatedAt: now,
  };
};

// ─── Check if source is external platform ───────────────────

export const isExternalSource = (source: OrderSource): boolean =>
  source === 'BLOOMNATION' || source === 'FTD';

// ─── Formatters ─────────────────────────────────────────────

export const fmtOrderCurrency = (v: number): string => formatCurrency(v);
