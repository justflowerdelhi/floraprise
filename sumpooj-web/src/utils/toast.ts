import { GLOBAL_TOAST_EVENT } from '../hooks/useToast';

type ToastSeverity = 'success' | 'error' | 'warning' | 'info';

const emitToast = (severity: ToastSeverity, message: string, duration?: number) => {
  if (!message) return;

  window.dispatchEvent(
    new CustomEvent(GLOBAL_TOAST_EVENT, {
      detail: {
        severity,
        message,
        duration,
      },
    }),
  );
};

export const showSuccess = (msg: string, duration?: number) => {
  emitToast('success', msg, duration);
};

export const showError = (msg: string, duration?: number) => {
  emitToast('error', msg, duration ?? 6000);
};

export const showInfo = (msg: string, duration?: number) => {
  emitToast('info', msg, duration);
};

export const showWarning = (msg: string, duration?: number) => {
  emitToast('warning', msg, duration);
};
