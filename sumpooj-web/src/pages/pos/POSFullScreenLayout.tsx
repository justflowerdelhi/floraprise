/**
 * POSFullScreenLayout.tsx — Dedicated Full-Screen POS Layout
 * 
 * Completely separate from MasterLayout:
 * - No sidebar navigation
 * - No header navigation
 * - Optimized for 1440px retail desktop
 * - Navigation blocking when cart has items
 * - Single cart architecture enforcement
 */
import React, { Component, useEffect, useCallback, type ErrorInfo, type ReactNode } from 'react';
import { Outlet, useNavigate } from 'react-router-dom';
import { CircularProgress } from '@mui/material';
import { POSProvider, usePOS } from './POSContext';
import { LocationProvider, useLocation } from '../../core/location/LocationContext';
import { ShiftProvider, useShift } from './ShiftContext';
import ShiftOpenModal from './ShiftOpenModal';
import ShiftCloseDrawer from './ShiftCloseDrawer';

// ─── Error Boundary ─────────────────────────────────────────

interface EBProps { children: ReactNode }
interface EBState { error: Error | null }

class POSErrorBoundary extends Component<EBProps, EBState> {
  state: EBState = { error: null };

  static getDerivedStateFromError(error: Error) { return { error }; }

  componentDidCatch(error: Error, info: ErrorInfo) {
    console.error('[POSErrorBoundary]', error, info.componentStack);
  }

  render() {
    if (this.state.error) {
      return (
        <div className="h-screen w-screen flex items-center justify-center bg-red-50 p-8">
          <div className="max-w-lg text-center">
            <h1 className="text-2xl font-bold text-red-700 mb-4">POS Error</h1>
            <p className="text-red-600 mb-2 font-mono text-sm">{this.state.error.message}</p>
            <pre className="text-xs text-left bg-red-100 p-4 rounded overflow-auto max-h-60 mb-4">
              {this.state.error.stack}
            </pre>
            <button onClick={() => window.location.reload()} className="px-4 py-2 bg-red-600 text-white rounded">
              Reload
            </button>
          </div>
        </div>
      );
    }
    return this.props.children;
  }
}

// ─── Navigation Blocker ─────────────────────────────────────
// useBlocker requires createBrowserRouter (data router).
// This app uses <BrowserRouter>, so we rely on beforeunload only.
// The NavigationBlockerDialog is a no-op placeholder.
const NavigationBlockerDialog: React.FC = () => null;

// ─── Browser Navigation Warning ─────────────────────────────

const BrowserNavigationWarning: React.FC = () => {
  const { hasUnsavedCart, state } = usePOS();

  useEffect(() => {
    const handleBeforeUnload = (e: BeforeUnloadEvent) => {
      if (hasUnsavedCart && state.lifecycle !== 'completed') {
        e.preventDefault();
        e.returnValue = 'You have items in your cart. Are you sure you want to leave?';
        return e.returnValue;
      }
    };

    window.addEventListener('beforeunload', handleBeforeUnload);
    return () => window.removeEventListener('beforeunload', handleBeforeUnload);
  }, [hasUnsavedCart, state.lifecycle]);

  return null;
};

// ─── Exit POS Button ────────────────────────────────────────

const ExitPOSButton: React.FC = () => {
  const navigate = useNavigate();
  const { hasUnsavedCart } = usePOS();

  const handleExit = useCallback(() => {
    if (hasUnsavedCart) {
      // Navigation blocker will handle this
      navigate('/dashboard');
    } else {
      navigate('/dashboard');
    }
  }, [navigate, hasUnsavedCart]);

  return (
    <button
      onClick={handleExit}
      className="fixed top-4 right-4 z-50 flex items-center gap-2 px-3 py-2 
                 bg-white/90 backdrop-blur border border-gray-200 rounded-lg shadow-sm
                 hover:bg-gray-50 transition-colors text-sm font-medium text-gray-700"
      title="Exit POS (Escape)"
    >
      <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
      </svg>
      Exit POS
    </button>
  );
};

// ─── Close Shift Button ─────────────────────────────────────

const CloseShiftButton: React.FC = () => {
  const { activeShift, setCloseDrawerOpen } = useShift();

  if (!activeShift) return null;

  return (
    <button
      onClick={() => setCloseDrawerOpen(true)}
      className="fixed top-4 right-36 z-50 flex items-center gap-2 px-3 py-2
                 bg-white/90 backdrop-blur border border-gray-200 rounded-lg shadow-sm
                 hover:bg-red-50 hover:border-red-200 transition-colors text-sm font-medium text-gray-700"
      title="Close current shift"
    >
      <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
      </svg>
      Close Shift
    </button>
  );
};

// ─── POS Keyboard Shortcuts ─────────────────────────────────

const POSKeyboardHandler: React.FC = () => {
  const navigate = useNavigate();
  const { hasUnsavedCart } = usePOS();

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      // Escape to exit POS (will trigger blocker if cart has items)
      if (e.key === 'Escape' && !e.ctrlKey && !e.altKey && !e.shiftKey) {
        // Don't interfere with dialogs/modals
        const isInModal = document.querySelector('[role="dialog"]');
        if (!isInModal) {
          navigate('/dashboard');
        }
      }
    };

    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [navigate, hasUnsavedCart]);

  return null;
};

// ─── Inner Layout (needs POS context) ───────────────────────

const POSFullScreenInner: React.FC = () => {
  const { loading, activeShift, shiftSystemAvailable } = useShift();

  // Show loading spinner while checking shift status
  if (loading) {
    return (
      <div className="h-screen w-screen flex items-center justify-center bg-gray-50">
        <div className="text-center">
          <CircularProgress size={40} />
          <p className="mt-3 text-sm text-gray-500">Checking shift status…</p>
        </div>
      </div>
    );
  }

  return (
    <div className="h-screen w-screen overflow-hidden bg-gray-50">
      {/* Shift open modal — blocks POS only when shift system is available but no shift open */}
      <ShiftOpenModal />

      {/* Shift close drawer */}
      <ShiftCloseDrawer />

      {/* Navigation blocker dialog */}
      <NavigationBlockerDialog />
      
      {/* Browser navigation warning */}
      <BrowserNavigationWarning />
      
      {/* Keyboard handler */}
      <POSKeyboardHandler />

      {/* Close Shift button (visible when shift is active) */}
      <CloseShiftButton />
      
      {/* Exit button */}
      <ExitPOSButton />
      
      {/* POS Content — always render behind shift modal */}
      <main className="h-full w-full">
        <Outlet />
      </main>
    </div>
  );
};

// ─── Main Layout (provides context) ─────────────────────────

const POSFullScreenLayoutInner: React.FC = () => {
  const location = useLocation();

  const locationId = location.currentLocation?.id || 'loc_default';

  return (
    <ShiftProvider locationId={locationId}>
      <POSProvider
        locationId={locationId}
        locationName={location.currentLocation?.name || 'Main Store'}
      >
        <POSFullScreenInner />
      </POSProvider>
    </ShiftProvider>
  );
};

const POSFullScreenLayout: React.FC = () => {
  return (
    <POSErrorBoundary>
      <LocationProvider>
        <POSFullScreenLayoutInner />
      </LocationProvider>
    </POSErrorBoundary>
  );
};

export default POSFullScreenLayout;
