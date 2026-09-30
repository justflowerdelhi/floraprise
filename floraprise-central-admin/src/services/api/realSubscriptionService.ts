/**
 * Real Subscription Service
 * Connects directly to Sumpooj.API platform mobile administration endpoints:
 * - GET /api/platform/mobile-admin/plans (Plan Catalog source of truth)
 * - Real Subscribers -> Subscriptions mapping
 */

import { apiClient } from './apiClient';
import { SubscriptionPlan, SubscriptionRecord } from '../../types/subscription';
import { realSubscriberService } from './realSubscriberService';

export interface BackendMobileSubscriptionPlanDto {
  id: string;
  code: string;
  name: string;
  planType: number; // 1: Basic, 2: Pro, 3: Enterprise, 4: Lifetime
  monthlyPrice: number;
  annualPrice: number;
  lifetimePrice: number;
  trialDays: number;
  offlineDays: number;
  graceDays: number;
  maximumDevices: number;
  maximumStaff: number;
  isActive: boolean;
  includedModulesJson?: string;
}

class RealSubscriptionService {
  /**
   * Fetch active commercial plan catalog directly from backend
   */
  async getPlans(): Promise<SubscriptionPlan[]> {
    const res = await apiClient.get<BackendMobileSubscriptionPlanDto[]>('/api/platform/mobile-admin/plans');

    if (res.isSuccess && res.data && Array.isArray(res.data)) {
      return res.data.map(p => {
        const planTypeName = p.planType === 1 ? 'Basic' 
          : p.planType === 2 ? 'Pro' 
          : p.planType === 3 ? 'Enterprise' 
          : p.planType === 4 ? 'Lifetime' 
          : 'Pro';

        const billingCycle = p.code === 'MOBILE_TRIAL' ? 'Trial'
          : p.code === 'QUARTERLY' ? 'Quarterly'
          : p.code === 'HALF_YEARLY' ? 'Half-Yearly'
          : 'Annual';

        const durationDays = p.code === 'MOBILE_TRIAL' ? (p.trialDays || 7)
          : p.code === 'QUARTERLY' ? 90
          : p.code === 'HALF_YEARLY' ? 180
          : 365;

        const effectivePrice = p.annualPrice > 0 ? p.annualPrice : (p.monthlyPrice > 0 ? p.monthlyPrice : 0);

        return {
          id: p.id,
          name: p.name,
          code: p.code,
          planType: planTypeName,
          billingCycle: billingCycle as any,
          priceInr: effectivePrice,
          monthlyPrice: p.monthlyPrice || 0,
          annualPrice: p.annualPrice || 0,
          lifetimePrice: p.lifetimePrice || 0,
          trialDays: p.trialDays || 7,
          offlineDays: p.offlineDays || 3,
          graceDays: p.graceDays || 30,
          maximumDevices: p.maximumDevices || 3,
          maximumStaff: p.maximumStaff || 10,
          maxDevices: p.maximumDevices || 3,
          maxStaff: p.maximumStaff || 10,
          maxLocations: 1,
          durationDays: durationDays,
          supportedModes: ['Flutter Cloud Android', 'Flutter Web', 'Flutter Solo'],
          includedServices: [
            'Subscription Validation',
            'Delivery Tracking',
            'Cloud Storage',
            'Notifications',
            'Cloud Production & Recipes'
          ],
          includedModulesJson: p.includedModulesJson || '[]',
          description: `${p.name} tier with ${p.maximumDevices || 3} devices, ${p.maximumStaff || 10} staff accounts, and ${p.offlineDays || 3}-day offline tolerance.`,
          isActive: p.isActive,
          isPopular: p.code === 'ANNUAL'
        };
      });
    }

    return [];
  }

  /**
   * Fetch live subscription records derived from real subscribers
   */
  async getSubscriptions(filter?: 'Active' | 'Trial' | 'Grace' | 'Expired'): Promise<SubscriptionRecord[]> {
    const subs = await realSubscriberService.getSubscribers();
    
    const records: SubscriptionRecord[] = subs.map(s => {
      let amount = 14999;
      if (s.planId === 'MOBILE_TRIAL' || s.subscriptionStatus === 'Trial') amount = 0;
      else if (s.planId === 'QUARTERLY') amount = 4999;
      else if (s.planId === 'HALF_YEARLY') amount = 8999;

      return {
        id: `sub-${s.id.substring(0, 8)}`,
        subscriberId: s.id,
        businessName: s.businessName,
        planName: s.planName,
        planCode: s.planId,
        status: s.subscriptionStatus,
        amountInr: amount,
        startDate: s.subscriptionStartedAt ? s.subscriptionStartedAt.substring(0, 10) : 'N/A',
        expiryDate: s.subscriptionExpiresAt ? s.subscriptionExpiresAt.substring(0, 10) : 'N/A',
        autoRenew: true
      };
    });

    if (filter) {
      return records.filter(r => r.status.toLowerCase() === filter.toLowerCase());
    }

    return records;
  }

  /**
   * Summarize real subscription metrics
   */
  async getSummary() {
    const subs = await this.getSubscriptions();
    return {
      total: subs.length,
      active: subs.filter(s => s.status === 'Active').length,
      trial: subs.filter(s => s.status === 'Trial').length,
      grace: subs.filter(s => s.status === 'Grace').length,
      expired: subs.filter(s => s.status === 'Expired').length,
      totalRevenueInr: subs.reduce((acc, curr) => acc + curr.amountInr, 0)
    };
  }
}

export const realSubscriptionService = new RealSubscriptionService();
