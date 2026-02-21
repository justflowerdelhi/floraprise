/**
 * ShiftContext.tsx — POS Shift State Management
 *
 * Wraps the POS to enforce shift-based access:
 * - Loads active shift on mount based on current location
 * - Exposes open / close / refresh helpers
 * - Provides shift data for the shift-close summary
 *
 * Consumed by ShiftOpenModal (blocks POS when no shift)
 * and ShiftCloseDrawer (shows summary + cash count).
 */
import React, {
  createContext,
  useContext,
  useState,
  useCallback,
  useEffect,
  type ReactNode,
} from 'react';
import type { ShiftDto } from '../../api/shift.api';
import {
  getActiveShift,
  openShift as apiOpenShift,
  closeShift as apiCloseShift,
} from '../../api/shift.api';

// ─── Context Types ──────────────────────────────────────────

interface ShiftContextValue {
  /** The currently-open shift, or null if none */
  activeShift: ShiftDto | null;
  /** True while loading the initial shift check */
  loading: boolean;
  /** Error message from the last operation, if any */
  error: string | null;
  /** Whether the shift-close drawer is visible */
  isCloseDrawerOpen: boolean;
  /** True when the shift API is reachable (false = shifts not deployed yet, skip guard) */
  shiftSystemAvailable: boolean;
  /** Open a new shift with the given cash amount */
  openShift: (openingCash: number) => Promise<void>;
  /** Close the active shift */
  closeShift: (closingCashCount: number, notes?: string) => Promise<void>;
  /** Re-fetch the active shift from the server */
  refreshShift: () => Promise<void>;
  /** Toggle the shift-close drawer */
  setCloseDrawerOpen: (open: boolean) => void;
}

const ShiftContext = createContext<ShiftContextValue | null>(null);

// ─── Provider ───────────────────────────────────────────────

interface ShiftProviderProps {
  children: ReactNode;
  locationId: string;
}

export const ShiftProvider: React.FC<ShiftProviderProps> = ({ children, locationId }) => {
  const [activeShift, setActiveShift] = useState<ShiftDto | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [isCloseDrawerOpen, setCloseDrawerOpen] = useState(false);
  const [shiftSystemAvailable, setShiftSystemAvailable] = useState(true);

  // ─── Fetch active shift ─────────────────────────────────
  const refreshShift = useCallback(async () => {
    if (!locationId) return;
    try {
      setLoading(true);
      setError(null);
      const shift = await getActiveShift(locationId);
      setActiveShift(shift);
      setShiftSystemAvailable(true);
    } catch (err: unknown) {
      console.error('Failed to fetch active shift', err);
      // If the endpoint doesn't exist yet (404) or network error, mark shifts as unavailable
      // so the POS is not blocked.
      setShiftSystemAvailable(false);
      setError(null); // Don't show error when system is simply not deployed
    } finally {
      setLoading(false);
    }
  }, [locationId]);

  useEffect(() => {
    refreshShift();
  }, [refreshShift]);

  // ─── Open shift ─────────────────────────────────────────
  const openShift = useCallback(
    async (openingCash: number) => {
      try {
        setError(null);
        await apiOpenShift({ locationId, openingCash });
        await refreshShift();
      } catch (err: unknown) {
        const msg =
          err instanceof Error ? err.message : 'Failed to open shift';
        setError(msg);
        throw err;
      }
    },
    [locationId, refreshShift],
  );

  // ─── Close shift ────────────────────────────────────────
  const closeShift = useCallback(
    async (closingCashCount: number, notes?: string) => {
      if (!activeShift) throw new Error('No active shift to close');
      try {
        setError(null);
        await apiCloseShift(activeShift.id, { closingCashCount, notes });
        setActiveShift(null);
        setCloseDrawerOpen(false);
      } catch (err: unknown) {
        const msg =
          err instanceof Error ? err.message : 'Failed to close shift';
        setError(msg);
        throw err;
      }
    },
    [activeShift],
  );

  // ─── Value ──────────────────────────────────────────────
  const value: ShiftContextValue = {
    activeShift,
    loading,
    error,
    isCloseDrawerOpen,
    shiftSystemAvailable,
    openShift,
    closeShift,
    refreshShift,
    setCloseDrawerOpen,
  };

  return <ShiftContext.Provider value={value}>{children}</ShiftContext.Provider>;
};

// ─── Hook ───────────────────────────────────────────────────

export const useShift = (): ShiftContextValue => {
  const ctx = useContext(ShiftContext);
  if (!ctx) throw new Error('useShift must be used within ShiftProvider');
  return ctx;
};

export default ShiftContext;
