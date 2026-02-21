import api from './axios';

// ═══════════════════════════════════════════════════════════════════
// PAYMENT GATEWAY TYPES
// ═══════════════════════════════════════════════════════════════════

export type PaymentGatewayType = 
  // India
  | 'Razorpay'
  | 'PayU'
  | 'Cashfree'
  // USA
  | 'Stripe'
  | 'Square'
  | 'PayPal'
  // GCC
  | 'PayTabs'
  | 'HyperPay'
  | 'TapPayments'
  | 'CheckoutCom';

export type GatewayEnvironment = 'Sandbox' | 'Production';

export type PaymentTransactionStatus = 
  | 'Pending'
  | 'Processing'
  | 'Authorized'
  | 'Captured'
  | 'Completed'
  | 'Failed'
  | 'Cancelled'
  | 'Refunded'
  | 'PartiallyRefunded'
  | 'Disputed';

export type PaymentMethodType = 
  | 'Card'
  | 'UPI'
  | 'NetBanking'
  | 'Wallet'
  | 'BankTransfer'
  | 'Cash'
  | 'Check'
  | 'GiftCard'
  | 'StoreCredit'
  | 'PayLater';

// ═══════════════════════════════════════════════════════════════════
// DTOs
// ═══════════════════════════════════════════════════════════════════

export interface PaymentGatewayInfo {
  type: PaymentGatewayType;
  name: string;
  region: string;
  supportedCurrencies: string[];
  supportedPaymentMethods: string[];
  requiresMerchantId: boolean;
  setupDocUrl: string;
}

export interface PaymentGatewayConfig {
  id: string;
  gatewayType: PaymentGatewayType;
  gatewayTypeName: string;
  name: string;
  publicKey: string;
  merchantId: string | null;
  environment: GatewayEnvironment;
  environmentName: string;
  currency: string;
  supportedCurrencies: string | null;
  isActive: boolean;
  isDefault: boolean;
  webhookUrl: string | null;
  lastTestedAt: string | null;
  lastTestSuccessful: boolean | null;
  region: string;
  createdAt: string;
}

export interface PaymentGatewayConfigCreate {
  gatewayType: PaymentGatewayType;
  name: string;
  publicKey: string;
  secretKey: string;
  webhookSecret?: string;
  merchantId?: string;
  environment: GatewayEnvironment;
  currency: string;
  supportedCurrencies?: string;
  isDefault?: boolean;
  additionalConfig?: string;
}

export interface PaymentGatewayConfigUpdate {
  name?: string;
  publicKey?: string;
  secretKey?: string;
  webhookSecret?: string;
  merchantId?: string;
  environment?: GatewayEnvironment;
  currency?: string;
  supportedCurrencies?: string;
  isActive?: boolean;
  isDefault?: boolean;
  additionalConfig?: string;
}

export interface PaymentGatewayTestResult {
  success: boolean;
  message: string;
  testedAt: string;
}

export interface PaymentTransaction {
  id: string;
  transactionRef: string;
  gatewayPaymentId: string | null;
  gatewayOrderId: string | null;
  amount: number;
  currency: string;
  status: PaymentTransactionStatus;
  statusName: string;
  paymentMethod: PaymentMethodType | null;
  paymentMethodName: string | null;
  cardLast4: string | null;
  cardBrand: string | null;
  bankName: string | null;
  upiId: string | null;
  walletName: string | null;
  customerEmail: string | null;
  customerPhone: string | null;
  failureReason: string | null;
  refundedAmount: number;
  gatewayFee: number | null;
  netAmount: number | null;
  createdAt: string;
  completedAt: string | null;
  orderId: string | null;
  gatewayType: PaymentGatewayType;
  gatewayTypeName: string;
}

export interface CreatePaymentRequest {
  amount: number;
  currency: string;
  orderId?: string;
  customerEmail?: string;
  customerPhone?: string;
  description?: string;
  returnUrl?: string;
  cancelUrl?: string;
  metadata?: Record<string, string>;
}

export interface CreatePaymentResult {
  transactionId: string;
  transactionRef: string;
  gatewayOrderId: string | null;
  paymentUrl: string | null;
  clientSecret: string | null;
  qrCode: string | null;
  additionalData: Record<string, unknown> | null;
}

export interface VerifyPaymentRequest {
  transactionRef: string;
  gatewayPaymentId?: string;
  gatewaySignature?: string;
  additionalData?: Record<string, string>;
}

export interface VerifyPaymentResult {
  success: boolean;
  status: PaymentTransactionStatus;
  message: string | null;
  transaction: PaymentTransaction | null;
}

export interface RefundRequest {
  transactionId: string;
  amount?: number;
  reason?: string;
}

export interface RefundResult {
  success: boolean;
  refundId: string | null;
  refundedAmount: number;
  message: string | null;
}

// ═══════════════════════════════════════════════════════════════════
// PAYMENT GATEWAY CONFIG API
// ═══════════════════════════════════════════════════════════════════

/** Get all available payment gateway types */
export const getAvailableGateways = async (): Promise<PaymentGatewayInfo[]> => {
  const res = await api.get('/payment-gateways/available');
  return res.data;
};

/** Get all configured payment gateways for the company */
export const getPaymentGatewayConfigs = async (): Promise<PaymentGatewayConfig[]> => {
  const res = await api.get('/payment-gateways');
  return res.data;
};

/** Get a specific payment gateway configuration */
export const getPaymentGatewayConfig = async (id: string): Promise<PaymentGatewayConfig> => {
  const res = await api.get(`/payment-gateways/${id}`);
  return res.data;
};

/** Get the default payment gateway */
export const getDefaultPaymentGateway = async (): Promise<PaymentGatewayConfig | null> => {
  try {
    const res = await api.get('/payment-gateways/default');
    return res.data;
  } catch {
    return null;
  }
};

/** Create a new payment gateway configuration */
export const createPaymentGatewayConfig = async (
  data: PaymentGatewayConfigCreate
): Promise<PaymentGatewayConfig> => {
  const res = await api.post('/payment-gateways', data);
  return res.data;
};

/** Update a payment gateway configuration */
export const updatePaymentGatewayConfig = async (
  id: string,
  data: PaymentGatewayConfigUpdate
): Promise<PaymentGatewayConfig> => {
  const res = await api.put(`/payment-gateways/${id}`, data);
  return res.data;
};

/** Delete a payment gateway configuration */
export const deletePaymentGatewayConfig = async (id: string): Promise<void> => {
  await api.delete(`/payment-gateways/${id}`);
};

/** Test payment gateway connection */
export const testPaymentGatewayConnection = async (
  id: string
): Promise<PaymentGatewayTestResult> => {
  const res = await api.post(`/payment-gateways/${id}/test`);
  return res.data;
};

// ═══════════════════════════════════════════════════════════════════
// PAYMENTS API
// ═══════════════════════════════════════════════════════════════════

/** Create a new payment */
export const createPayment = async (
  data: CreatePaymentRequest,
  gatewayConfigId?: string
): Promise<CreatePaymentResult> => {
  const params = gatewayConfigId ? { gatewayConfigId } : {};
  const res = await api.post('/payments', data, { params });
  return res.data;
};

/** Verify payment completion */
export const verifyPayment = async (data: VerifyPaymentRequest): Promise<VerifyPaymentResult> => {
  const res = await api.post('/payments/verify', data);
  return res.data;
};

/** Process a refund */
export const refundPayment = async (data: RefundRequest): Promise<RefundResult> => {
  const res = await api.post('/payments/refund', data);
  return res.data;
};

/** Get a transaction by ID */
export const getPaymentTransaction = async (id: string): Promise<PaymentTransaction> => {
  const res = await api.get(`/payments/transactions/${id}`);
  return res.data;
};

/** Get transactions for an order */
export const getPaymentTransactionsByOrder = async (
  orderId: string
): Promise<PaymentTransaction[]> => {
  const res = await api.get(`/payments/orders/${orderId}/transactions`);
  return res.data;
};

/** Search transactions */
export const searchPaymentTransactions = async (params: {
  status?: PaymentTransactionStatus;
  fromDate?: string;
  toDate?: string;
  page?: number;
  pageSize?: number;
}): Promise<{
  items: PaymentTransaction[];
  totalCount: number;
  page: number;
  pageSize: number;
  totalPages: number;
}> => {
  const res = await api.get('/payments/transactions', { params });
  return res.data;
};

// ═══════════════════════════════════════════════════════════════════
// HELPER FUNCTIONS
// ═══════════════════════════════════════════════════════════════════

/** Get gateway info by region */
export const getGatewaysByRegion = (
  gateways: PaymentGatewayInfo[],
  region: 'IN' | 'US' | 'GCC'
): PaymentGatewayInfo[] => {
  return gateways.filter((g) => g.region === region);
};

/** Format currency amount for gateway (convert to smallest unit) */
export const formatAmountForGateway = (amount: number, currency: string): number => {
  // Most gateways expect amounts in smallest currency unit (cents, paise, etc.)
  const noDecimalCurrencies = ['JPY', 'KRW', 'VND'];
  if (noDecimalCurrencies.includes(currency.toUpperCase())) {
    return Math.round(amount);
  }
  return Math.round(amount * 100);
};

/** Get status color for UI */
export const getStatusColor = (
  status: PaymentTransactionStatus
): 'success' | 'error' | 'warning' | 'info' | 'default' => {
  switch (status) {
    case 'Completed':
      return 'success';
    case 'Failed':
    case 'Cancelled':
    case 'Disputed':
      return 'error';
    case 'Pending':
    case 'Processing':
      return 'warning';
    case 'Authorized':
    case 'Captured':
      return 'info';
    case 'Refunded':
    case 'PartiallyRefunded':
      return 'default';
    default:
      return 'default';
  }
};
