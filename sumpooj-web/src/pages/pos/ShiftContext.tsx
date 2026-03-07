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
import { useLocation as useLocationCtx } from '../../core/location/LocationContext';

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
  /** The locationId this provider is bound to */
  locationId: string;
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
}

export const ShiftProvider: React.FC<ShiftProviderProps> = ({ children }) => {
  // Read selected location from global LocationContext
  const { currentLocation, currentLocationId, isAllLocations, accessibleLocations, setCurrentLocationId } = useLocationCtx();

  // Auto-select first accessible location when POS opens with "ALL" or no location
  useEffect(() => {
    if ((isAllLocations || !currentLocation) && accessibleLocations.length > 0) {
      setCurrentLocationId(accessibleLocations[0].id);
    }
  }, [isAllLocations, currentLocation, accessibleLocations, setCurrentLocationId]);

  // Derive the effective locationId (empty when "ALL" or no specific location)
  const selectedLocationId = (!isAllLocations && currentLocation?.id) ? currentLocation.id : '';

  const [activeShift, setActiveShift] = useState<ShiftDto | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [isCloseDrawerOpen, setCloseDrawerOpen] = useState(false);

  // ─── Fetch active shift ─────────────────────────────────
  const refreshShift = useCallback(async () => {
    if (!selectedLocationId) {
      console.error('[ShiftProvider] No locationId — cannot fetch active shift. currentLocationId:', currentLocationId);
      setActiveShift(null);
      setError('Select a location to continue.');
      setLoading(false);
      return;
    }
    try {
      setLoading(true);
      setError(null);
      const shift = await getActiveShift(selectedLocationId);
      setActiveShift(shift);
    } catch (err: unknown) {
      console.error('[ShiftProvider] Failed to fetch active shift for location', selectedLocationId, err);
      setActiveShift(null);
      const msg = err instanceof Error ? err.message : 'Failed to check shift status';
      setError(msg);
    } finally {
      setLoading(false);
    }
  }, [selectedLocationId, currentLocationId]);

  // Re-fetch whenever selectedLocationId changes
  useEffect(() => {
    if (selectedLocationId) {
      refreshShift();
    } else {
      // No specific location — reset shift state
      setActiveShift(null);
      setError('Select a location to continue.');
      setLoading(false);
    }
  }, [selectedLocationId, refreshShift]);

  // Auto-refresh shift summary every 60 seconds while a shift is open
  useEffect(() => {
    if (!activeShift || !selectedLocationId) return;
    const interval = setInterval(() => {
      refreshShift();
    }, 60_000);
    return () => clearInterval(interval);
  }, [activeShift?.id, selectedLocationId, refreshShift]);

  // ─── Open shift ─────────────────────────────────────────
  const openShift = useCallback(
    async (openingCash: number) => {
      try {
        setError(null);
        await apiOpenShift({ locationId: selectedLocationId, openingCash });
        await refreshShift();
      } catch (err: unknown) {
        const msg =
          err instanceof Error ? err.message : 'Failed to open shift';
        setError(msg);
        throw err;
      }
    },
    [selectedLocationId, refreshShift],
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
    locationId: selectedLocationId,
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
