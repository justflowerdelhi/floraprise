// =============================================================================
// OPERATIONAL VIEW CONTEXT — Retail View vs ERP Professional State
// =============================================================================

import React, {
  createContext,
  useContext,
  useState,
  useCallback,
  useMemo,
  type ReactNode,
} from 'react';
import type { OperationalView } from './TenantTypes';
import {
  OPERATIONAL_VIEWS,
  OPERATIONAL_VIEW_STORAGE_KEY,
  isProfessionalViewEligible,
  resolveOperationalView,
} from './TenantTypes';
import { useTenant } from './TenantContext';

// -----------------------------------------------------------------------------
// Storage Helpers (SSR-Safe)
// -----------------------------------------------------------------------------

export function getStoredOperationalView(): OperationalView | null {
  if (typeof window === 'undefined') return null;
  try {
    const raw = window.localStorage.getItem(OPERATIONAL_VIEW_STORAGE_KEY);
    if (raw === OPERATIONAL_VIEWS.RETAIL || raw === OPERATIONAL_VIEWS.PROFESSIONAL) {
      return raw;
    }
    return null;
  } catch {
    return null;
  }
}

export function setStoredOperationalView(view: OperationalView): void {
  if (typeof window === 'undefined') return;
  try {
    window.localStorage.setItem(OPERATIONAL_VIEW_STORAGE_KEY, view);
  } catch {
    // Silently ignore storage errors (e.g. private browsing storage quota)
  }
}

// -----------------------------------------------------------------------------
// Context Value Interface
// -----------------------------------------------------------------------------

export interface OperationalViewContextValue {
  view: OperationalView;
  isRetail: boolean;
  isProfessional: boolean;
  canUseProfessionalView: boolean;
  setView: (view: OperationalView) => void;
}

const OperationalViewContext = createContext<OperationalViewContextValue | undefined>(undefined);

// -----------------------------------------------------------------------------
// Provider Component
// -----------------------------------------------------------------------------

interface OperationalViewProviderProps {
  children: ReactNode;
}

export function OperationalViewProvider({ children }: OperationalViewProviderProps) {
  const { tenant } = useTenant();
  const plan = tenant?.plan ?? 'STARTER';
  const canUseProfessionalView = isProfessionalViewEligible(plan);

  // Read initial stored preference (SSR-safe)
  const [storedPreference, setStoredPreferenceState] = useState<OperationalView | null>(() => {
    return getStoredOperationalView();
  });

  // Calculate effective view based on plan eligibility and stored preference
  const effectiveView = useMemo(() => {
    return resolveOperationalView(plan, storedPreference);
  }, [plan, storedPreference]);

  // View setter with entitlement validation
  const setView = useCallback(
    (nextView: OperationalView) => {
      // Starter plan cannot switch to Professional View
      if (!canUseProfessionalView && nextView === OPERATIONAL_VIEWS.PROFESSIONAL) {
        console.warn('[OperationalView] Starter plan is restricted to Retail View.');
        return;
      }

      setStoredOperationalView(nextView);
      setStoredPreferenceState(nextView);
    },
    [canUseProfessionalView]
  );

  const value = useMemo<OperationalViewContextValue>(
    () => ({
      view: effectiveView,
      isRetail: effectiveView === OPERATIONAL_VIEWS.RETAIL,
      isProfessional: effectiveView === OPERATIONAL_VIEWS.PROFESSIONAL,
      canUseProfessionalView,
      setView,
    }),
    [effectiveView, canUseProfessionalView, setView]
  );

  return (
    <OperationalViewContext.Provider value={value}>
      {children}
    </OperationalViewContext.Provider>
  );
}

// -----------------------------------------------------------------------------
// Hook
// -----------------------------------------------------------------------------

export function useOperationalView(): OperationalViewContextValue {
  const context = useContext(OperationalViewContext);
  if (!context) {
    throw new Error('useOperationalView must be used within an OperationalViewProvider');
  }
  return context;
}
