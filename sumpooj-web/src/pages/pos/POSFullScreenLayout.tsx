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
import React, { useEffect, useCallback } from 'react';
import { Outlet, useNavigate } from 'react-router-dom';
import { Dialog, DialogTitle, DialogContent, DialogActions, Button } from '@mui/material';
import { Warning as WarningIcon } from '@mui/icons-material';
import { POSProvider, usePOSNavigationBlocker, usePOS } from './POSContext';
import { LocationProvider, useLocation } from '../../core/location/LocationContext';

// ─── Navigation Blocker Dialog ──────────────────────────────

const NavigationBlockerDialog: React.FC = () => {
  const blocker = usePOSNavigationBlocker();
  const { resetCart } = usePOS();

  const handleStay = useCallback(() => {
    if (blocker.state === 'blocked') {
      blocker.reset();
    }
  }, [blocker]);

  const handleLeave = useCallback(() => {
    if (blocker.state === 'blocked') {
      resetCart();
      blocker.proceed();
    }
  }, [blocker, resetCart]);

  if (blocker.state !== 'blocked') return null;

  return (
    <Dialog
      open
      onClose={handleStay}
      maxWidth="xs"
      fullWidth
      PaperProps={{
        sx: { borderRadius: 2 },
      }}
    >
      <DialogTitle sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
        <WarningIcon color="warning" />
        Unsaved Cart
      </DialogTitle>
      <DialogContent>
        <p className="text-sm text-gray-600">
          You have items in your cart. Leaving this page will clear your cart and any unsaved changes.
        </p>
      </DialogContent>
      <DialogActions sx={{ px: 3, pb: 2 }}>
        <Button onClick={handleStay} variant="outlined">
          Stay on POS
        </Button>
        <Button onClick={handleLeave} variant="contained" color="error">
          Leave & Clear Cart
        </Button>
      </DialogActions>
    </Dialog>
  );
};

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
  console.log('[DEBUG] POSFullScreenInner rendering');
  return (
    <div className="h-screen w-screen overflow-hidden bg-gray-50">
      {/* Navigation blocker dialog */}
      <NavigationBlockerDialog />
      
      {/* Browser navigation warning */}
      <BrowserNavigationWarning />
      
      {/* Keyboard handler */}
      <POSKeyboardHandler />
      
      {/* Exit button */}
      <ExitPOSButton />
      
      {/* POS Content */}
      <main className="h-full w-full">
        <Outlet />
      </main>
    </div>
  );
};

// ─── Main Layout (provides context) ─────────────────────────

const POSFullScreenLayoutInner: React.FC = () => {
  console.log('[DEBUG] POSFullScreenLayoutInner rendering');
  const location = useLocation();
  console.log('[DEBUG] useLocation result:', location);

  return (
    <POSProvider
      locationId={location.currentLocation?.id || 'loc_default'}
      locationName={location.currentLocation?.name || 'Main Store'}
    >
      <POSFullScreenInner />
    </POSProvider>
  );
};

const POSFullScreenLayout: React.FC = () => {
  console.log('[DEBUG] POSFullScreenLayout rendering');
  
  // Step 3: Test POSFullScreenLayoutInner (uses useLocation + POSProvider)
  return (
    <LocationProvider>
      <POSFullScreenLayoutInner />
    </LocationProvider>
  );
  
  // return (
  //   <LocationProvider>
  //     <POSFullScreenLayoutInner />
  //   </LocationProvider>
  // );
};

export default POSFullScreenLayout;
