// Fallback type for POSCustomer if CRMTypes.ts is missing
export type CustomerTagType = string;

export interface POSCustomer {
  id: string;
  tenantId: string;
  name: string;
  phone: string;
  email: string;
  preferredAddress: string;
  createdAt: string;
  tags: CustomerTagType[];
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
}
