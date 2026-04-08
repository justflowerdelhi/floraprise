/**
 * useToast.tsx — Global Toast / Snackbar Notification System
 *
 * Provides a context-based toast that any component can trigger.
 * Wraps MUI Snackbar + Alert for success / error / warning / info messages.
 */
import { createContext, useContext, useState, useCallback, useMemo, useEffect } from 'react';
import type { ReactNode } from 'react';
import { Snackbar, Alert } from '@mui/material';
import type { AlertColor } from '@mui/material';

// ─── Types ──────────────────────────────────────────────────

interface ToastMessage {
  id: number;
  message: string;
  severity: AlertColor;
  duration?: number;
}

export type GlobalToastPayload = {
  message: string;
  severity: AlertColor;
  duration?: number;
};

export const GLOBAL_TOAST_EVENT = 'app:toast';

interface ToastContextValue {
  success: (message: string, duration?: number) => void;
  error: (message: string, duration?: number) => void;
  warning: (message: string, duration?: number) => void;
  info: (message: string, duration?: number) => void;
}

// ─── Context ────────────────────────────────────────────────

const ToastContext = createContext<ToastContextValue | null>(null);

let toastId = 0;

// ─── Provider ───────────────────────────────────────────────

export const ToastProvider = ({ children }: { children: ReactNode }) => {
  const [toasts, setToasts] = useState<ToastMessage[]>([]);

  const addToast = useCallback((message: string, severity: AlertColor, duration = 4000) => {
    const id = ++toastId;
    setToasts((prev) => [...prev, { id, message, severity, duration }]);
  }, []);

  const removeToast = useCallback((id: number) => {
    setToasts((prev) => prev.filter((t) => t.id !== id));
  }, []);

  useEffect(() => {
    const handleGlobalToast = (event: Event) => {
      const customEvent = event as CustomEvent<GlobalToastPayload>;
      const payload = customEvent.detail;
      if (!payload?.message || !payload?.severity) return;
      addToast(payload.message, payload.severity, payload.duration);
    };

    window.addEventListener(GLOBAL_TOAST_EVENT, handleGlobalToast as EventListener);
    return () => {
      window.removeEventListener(GLOBAL_TOAST_EVENT, handleGlobalToast as EventListener);
    };
  }, [addToast]);

  const value = useMemo<ToastContextValue>(
    () => ({
      success: (msg, dur) => addToast(msg, 'success', dur),
      error: (msg, dur) => addToast(msg, 'error', dur ?? 6000),
      warning: (msg, dur) => addToast(msg, 'warning', dur),
      info: (msg, dur) => addToast(msg, 'info', dur),
    }),
    [addToast],
  );

  return (
    <ToastContext.Provider value={value}>
      {children}
      {toasts.map((toast) => (
        <Snackbar
          key={toast.id}
          open
          autoHideDuration={toast.duration}
          onClose={() => removeToast(toast.id)}
          anchorOrigin={{ vertical: 'top', horizontal: 'right' }}
          sx={{ mt: toasts.indexOf(toast) * 7 }}
        >
          <Alert
            onClose={() => removeToast(toast.id)}
            severity={toast.severity}
            variant="filled"
            sx={{ width: '100%', minWidth: 300 }}
          >
            {toast.message}
          </Alert>
        </Snackbar>
      ))}
    </ToastContext.Provider>
  );
};

// ─── Hook ───────────────────────────────────────────────────

export const useToast = (): ToastContextValue => {
  const ctx = useContext(ToastContext);
  if (!ctx) throw new Error('useToast must be used within ToastProvider');
  return ctx;
};
