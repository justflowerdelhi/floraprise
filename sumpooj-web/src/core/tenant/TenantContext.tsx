// =============================================================================
// TENANT CONTEXT - SaaS Tenant State Management (Backend-Authoritative)
// =============================================================================

import React, { createContext, useContext, useState, useCallback, useMemo, useEffect, type ReactNode } from 'react';
import type {
  Tenant,
  TenantPlan,
  SubscriptionStatus,
  PlanConfig,
} from './TenantTypes';
import {
  MOCK_TENANT,
  getPlanConfig,
  getTrialDaysRemaining,
  isSubscriptionActive,
} from './TenantTypes';
import type { FeatureFlag } from './FeatureFlags';
import {
  hasFeature,
  getAvailableFeatures,
  getUnavailableFeatures,
  getRequiredPlanForFeature,
  getUpgradePathForFeature,
} from './FeatureFlags';
import { setCurrentCurrency } from '../i18n/currency';
import { useAuth } from '../../auth/AuthContext';

// -----------------------------------------------------------------------------
// Context Types
// -----------------------------------------------------------------------------

interface TenantContextValue {
  // Tenant data (read-only from backend via AuthContext)
  tenant: Tenant;
  plan: TenantPlan;
  planConfig: PlanConfig;
  subscriptionStatus: SubscriptionStatus;
  
  // Trial info
  isTrialActive: boolean;
  trialDaysRemaining: number;
  
  // Subscription status
  isActive: boolean;
  isPastDue: boolean;
  isCancelled: boolean;
  
  // Feature access
  hasFeature: (feature: FeatureFlag) => boolean;
  availableFeatures: FeatureFlag[];
  unavailableFeatures: FeatureFlag[];
  getUpgradePlan: (feature: FeatureFlag) => TenantPlan | null;
  getFeatureRequiredPlan: (feature: FeatureFlag) => TenantPlan;

  // Subscription actions (API-backed stubs — TODO: wire to real endpoints)
  upgradePlan: (newPlan: TenantPlan) => void;
  cancelSubscription: () => void;
  resumeSubscription: () => void;
  
  // UI helpers
  showUpgradeModal: boolean;
  setShowUpgradeModal: (show: boolean) => void;
  upgradeFeature: FeatureFlag | null;
  promptUpgrade: (feature: FeatureFlag) => void;
}

// -----------------------------------------------------------------------------
// Context Creation
// -----------------------------------------------------------------------------

const TenantContext = createContext<TenantContextValue | undefined>(undefined);

// -----------------------------------------------------------------------------
// Provider Component
// -----------------------------------------------------------------------------

interface TenantProviderProps {
  children: ReactNode;
}

export function TenantProvider({ children }: TenantProviderProps) {
  // Tenant now comes from AuthContext (backend-authoritative).
  // Falls back to MOCK_TENANT only when auth hasn't resolved yet (boot guard should prevent this).
  const auth = useAuth();
  const tenant: Tenant = auth.tenant ?? MOCK_TENANT;

  // UI state
  const [showUpgradeModal, setShowUpgradeModal] = useState(false);
  const [upgradeFeature, setUpgradeFeature] = useState<FeatureFlag | null>(null);
  
  // Derived values
  const plan = tenant.plan;
  const planConfig = useMemo(() => getPlanConfig(plan), [plan]);
  const subscriptionStatus = tenant.subscriptionStatus;
  
  const isTrialActive = subscriptionStatus === 'TRIAL';
  const trialDaysRemaining = useMemo(
    () => getTrialDaysRemaining(tenant.trialEndsAt),
    [tenant.trialEndsAt]
  );
  
  const isActive = isSubscriptionActive(subscriptionStatus);
  const isPastDue = subscriptionStatus === 'PAST_DUE';
  const isCancelled = subscriptionStatus === 'CANCELLED';

  // Sync module-level currency formatter whenever tenant changes
  useEffect(() => {
    if (tenant.currency) {
      setCurrentCurrency(tenant.currency);
    }
  }, [tenant.currency]);
  
  // Feature access
  const checkFeature = useCallback(
    (feature: FeatureFlag) => hasFeature(plan, feature),
    [plan]
  );
  
  const availableFeatures = useMemo(() => getAvailableFeatures(plan), [plan]);
  const unavailableFeatures = useMemo(() => getUnavailableFeatures(plan), [plan]);
  
  const getUpgradePlan = useCallback(
    (feature: FeatureFlag) => getUpgradePathForFeature(plan, feature),
    [plan]
  );
  
  const getFeatureRequiredPlan = useCallback(
    (feature: FeatureFlag) => getRequiredPlanForFeature(feature),
    []
  );
  
  const promptUpgrade = useCallback((feature: FeatureFlag) => {
    setUpgradeFeature(feature);
    setShowUpgradeModal(true);
  }, []);

  // Subscription mutation stubs — these will call real API endpoints.
  // For now they are no-ops; the backend must be the authority.
  const upgradePlan = useCallback((_newPlan: TenantPlan) => {
    // TODO: POST /api/subscription/upgrade { plan: newPlan }
    // After success, re-fetch /auth/me to get updated tenant
    console.warn('[TenantContext] upgradePlan called — wire to API');
    setShowUpgradeModal(false);
    setUpgradeFeature(null);
  }, []);

  const cancelSubscription = useCallback(() => {
    // TODO: POST /api/subscription/cancel
    console.warn('[TenantContext] cancelSubscription called — wire to API');
  }, []);

  const resumeSubscription = useCallback(() => {
    // TODO: POST /api/subscription/resume
    console.warn('[TenantContext] resumeSubscription called — wire to API');
  }, []);
  
  // Context value
  const value = useMemo<TenantContextValue>(
    () => ({
      tenant,
      plan,
      planConfig,
      subscriptionStatus,
      isTrialActive,
      trialDaysRemaining,
      isActive,
      isPastDue,
      isCancelled,
      hasFeature: checkFeature,
      availableFeatures,
      unavailableFeatures,
      getUpgradePlan,
      getFeatureRequiredPlan,
      upgradePlan,
      cancelSubscription,
      resumeSubscription,
      showUpgradeModal,
      setShowUpgradeModal,
      upgradeFeature,
      promptUpgrade,
    }),
    [
      tenant,
      plan,
      planConfig,
      subscriptionStatus,
      isTrialActive,
      trialDaysRemaining,
      isActive,
      isPastDue,
      isCancelled,
      checkFeature,
      availableFeatures,
      unavailableFeatures,
      getUpgradePlan,
      getFeatureRequiredPlan,
      upgradePlan,
      cancelSubscription,
      resumeSubscription,
      showUpgradeModal,
      upgradeFeature,
      promptUpgrade,
    ]
  );
  
  return (
    <TenantContext.Provider value={value}>
      {children}
    </TenantContext.Provider>
  );
}

// -----------------------------------------------------------------------------
// Hook
// -----------------------------------------------------------------------------

export function useTenant(): TenantContextValue {
  const context = useContext(TenantContext);
  if (!context) {
    throw new Error('useTenant must be used within a TenantProvider');
  }
  return context;
}

// -----------------------------------------------------------------------------
// Feature Gate Component
// -----------------------------------------------------------------------------

interface FeatureGateProps {
  feature: FeatureFlag;
  children: ReactNode;
  fallback?: ReactNode;
}

export function FeatureGate({ feature, children, fallback = null }: FeatureGateProps) {
  const { hasFeature } = useTenant();
  
  if (hasFeature(feature)) {
    return <>{children}</>;
  }
  
  return <>{fallback}</>;
}

// -----------------------------------------------------------------------------
// HOC for Feature Gating
// -----------------------------------------------------------------------------

export function withFeatureGate<P extends object>(
  WrappedComponent: React.ComponentType<P>,
  feature: FeatureFlag
) {
  return function FeatureGatedComponent(props: P) {
    const { hasFeature, promptUpgrade } = useTenant();
    
    if (!hasFeature(feature)) {
      // Trigger upgrade prompt
      React.useEffect(() => {
        promptUpgrade(feature);
      }, []);
      return null;
    }
    
    return <WrappedComponent {...props} />;
  };
}
