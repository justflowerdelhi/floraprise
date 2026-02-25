// Dedicated types for POSCustomer
export type CustomerTagType = string;
export interface POSCustomer {
  id: string;
  tenantId: string;
  name: string;
  phone: string;
  email: string;
  preferredAddress: string;
  createdAt: string;
  tags: string[];
  lifetimeValue: number;
  totalOrders: number;
  averageOrderValue: number;
  referralCount: number;
  loyaltyPoints: number;
  loyaltyTier: string;
  loyaltyPointsEarned: number;
  loyaltyPointsRedeemed: number;
  totalProfit: number;
  profitMargin: number;
  marketingConsent: boolean;
  lastOrderDate?: string;
  notes?: string;
}
