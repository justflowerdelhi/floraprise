/**
 * ConfirmationModal.tsx — Reusable Confirmation Dialog
 *
 * For risky actions like:
 * - Order cancellation
 * - Refunds
 * - Deletions
 * - Large discounts
 */
import React, { createContext, useContext, useState, useCallback, type ReactNode } from 'react';
import {
  Dialog, DialogTitle, DialogContent, DialogActions, Button, Box,
  Typography, useTheme, alpha, IconButton,
} from '@mui/material';
import {
  Warning as WarningIcon,
  Error as DangerIcon,
  Info as InfoIcon,
  Close as CloseIcon,
  Check as ConfirmIcon,
} from '@mui/icons-material';

// ─── Types ──────────────────────────────────────────────────

export type ConfirmSeverity = 'info' | 'warning' | 'danger';

export interface ConfirmationOptions {
  title: string;
  message: string;
  confirmLabel?: string;
  cancelLabel?: string;
  severity?: ConfirmSeverity;
  onConfirm?: () => void | Promise<void>;
  onCancel?: () => void;
}

interface ConfirmationContextValue {
  confirm: (options: ConfirmationOptions) => Promise<boolean>;
  isOpen: boolean;
}

// ─── Severity Config ────────────────────────────────────────

const SEVERITY_CONFIG: Record<ConfirmSeverity, { icon: React.ReactNode; color: string; bgColor: string }> = {
  info: {
    icon: <InfoIcon sx={{ fontSize: 28 }} />,
    color: '#2196f3',
    bgColor: '#e3f2fd',
  },
  warning: {
    icon: <WarningIcon sx={{ fontSize: 28 }} />,
    color: '#ff9800',
    bgColor: '#fff3e0',
  },
  danger: {
    icon: <DangerIcon sx={{ fontSize: 28 }} />,
    color: '#f44336',
    bgColor: '#ffebee',
  },
};

// ─── Context ────────────────────────────────────────────────

const ConfirmationContext = createContext<ConfirmationContextValue | null>(null);

// ─── Provider Component ─────────────────────────────────────

interface ConfirmationProviderProps {
  children: ReactNode;
}

export const ConfirmationProvider: React.FC<ConfirmationProviderProps> = ({ children }) => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';

  const [isOpen, setIsOpen] = useState(false);
  const [options, setOptions] = useState<ConfirmationOptions | null>(null);
  const [resolvePromise, setResolvePromise] = useState<((value: boolean) => void) | null>(null);
  const [isLoading, setIsLoading] = useState(false);

  const confirm = useCallback((opts: ConfirmationOptions): Promise<boolean> => {
    setOptions(opts);
    setIsOpen(true);

    return new Promise((resolve) => {
      setResolvePromise(() => resolve);
    });
  }, []);

  const handleConfirm = useCallback(async () => {
    if (options?.onConfirm) {
      setIsLoading(true);
      try {
        await options.onConfirm();
      } finally {
        setIsLoading(false);
      }
    }
    setIsOpen(false);
    resolvePromise?.(true);
  }, [options, resolvePromise]);

  const handleCancel = useCallback(() => {
    options?.onCancel?.();
    setIsOpen(false);
    resolvePromise?.(false);
  }, [options, resolvePromise]);

  const severity = options?.severity ?? 'warning';
  const config = SEVERITY_CONFIG[severity];

  return (
    <ConfirmationContext.Provider value={{ confirm, isOpen }}>
      {children}

      <Dialog
        open={isOpen}
        onClose={handleCancel}
        maxWidth="xs"
        fullWidth
        PaperProps={{
          sx: {
            borderRadius: 3,
            bgcolor: dk ? '#1a1a2e' : '#fff',
            border: dk ? '1px solid rgba(255,255,255,0.1)' : 'none',
          },
        }}
      >
        {/* Close Button */}
        <IconButton
          onClick={handleCancel}
          sx={{
            position: 'absolute',
            right: 8,
            top: 8,
            color: dk ? 'rgba(255,255,255,0.5)' : 'text.secondary',
          }}
        >
          <CloseIcon />
        </IconButton>

        {/* Icon Header */}
        <Box
          sx={{
            display: 'flex',
            justifyContent: 'center',
            pt: 3,
            pb: 1,
          }}
        >
          <Box
            sx={{
              width: 64,
              height: 64,
              borderRadius: '50%',
              bgcolor: dk ? alpha(config.color, 0.15) : config.bgColor,
              color: config.color,
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
            }}
          >
            {config.icon}
          </Box>
        </Box>

        {/* Title */}
        <DialogTitle
          sx={{
            textAlign: 'center',
            fontWeight: 700,
            fontSize: '1.25rem',
            pb: 0,
          }}
        >
          {options?.title}
        </DialogTitle>

        {/* Message */}
        <DialogContent>
          <Typography
            variant="body1"
            sx={{
              textAlign: 'center',
              color: dk ? 'rgba(255,255,255,0.7)' : 'text.secondary',
              lineHeight: 1.6,
              px: 2,
            }}
          >
            {options?.message}
          </Typography>
        </DialogContent>

        {/* Actions */}
        <DialogActions
          sx={{
            px: 3,
            pb: 3,
            gap: 1,
            flexDirection: 'column',
          }}
        >
          {/* Primary Action - Confirm */}
          <Button
            fullWidth
            variant="contained"
            onClick={handleConfirm}
            disabled={isLoading}
            startIcon={<ConfirmIcon />}
            sx={{
              py: 1.5,
              fontWeight: 700,
              fontSize: '1rem',
              borderRadius: 2,
              bgcolor: severity === 'danger' ? '#f44336' : severity === 'warning' ? '#ff9800' : '#2196f3',
              '&:hover': {
                bgcolor: severity === 'danger' ? '#d32f2f' : severity === 'warning' ? '#f57c00' : '#1976d2',
              },
            }}
          >
            {isLoading ? 'Please wait...' : (options?.confirmLabel ?? 'Yes, Continue')}
          </Button>

          {/* Secondary Action - Cancel */}
          <Button
            fullWidth
            variant="outlined"
            onClick={handleCancel}
            disabled={isLoading}
            sx={{
              py: 1.5,
              fontWeight: 600,
              fontSize: '1rem',
              borderRadius: 2,
              borderColor: dk ? 'rgba(255,255,255,0.2)' : 'divider',
              color: dk ? 'rgba(255,255,255,0.8)' : 'text.primary',
              '&:hover': {
                borderColor: dk ? 'rgba(255,255,255,0.4)' : 'text.primary',
                bgcolor: dk ? 'rgba(255,255,255,0.05)' : 'rgba(0,0,0,0.04)',
              },
            }}
          >
            {options?.cancelLabel ?? 'Cancel'}
          </Button>
        </DialogActions>
      </Dialog>
    </ConfirmationContext.Provider>
  );
};

// ─── Hook ───────────────────────────────────────────────────

export const useConfirmation = (): ConfirmationContextValue => {
  const context = useContext(ConfirmationContext);
  if (!context) {
    throw new Error('useConfirmation must be used within ConfirmationProvider');
  }
  return context;
};

// ─── Standalone Component (for non-context usage) ───────────

interface ConfirmationModalProps extends ConfirmationOptions {
  open: boolean;
  onClose: () => void;
}

export const ConfirmationModal: React.FC<ConfirmationModalProps> = ({
  open,
  onClose,
  title,
  message,
  confirmLabel = 'Yes, Continue',
  cancelLabel = 'Cancel',
  severity = 'warning',
  onConfirm,
  onCancel,
}) => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';
  const config = SEVERITY_CONFIG[severity];
  const [isLoading, setIsLoading] = useState(false);

  const handleConfirm = async () => {
    if (onConfirm) {
      setIsLoading(true);
      try {
        await onConfirm();
      } finally {
        setIsLoading(false);
      }
    }
    onClose();
  };

  const handleCancel = () => {
    onCancel?.();
    onClose();
  };

  return (
    <Dialog
      open={open}
      onClose={handleCancel}
      maxWidth="xs"
      fullWidth
      PaperProps={{
        sx: {
          borderRadius: 3,
          bgcolor: dk ? '#1a1a2e' : '#fff',
          border: dk ? '1px solid rgba(255,255,255,0.1)' : 'none',
        },
      }}
    >
      <IconButton
        onClick={handleCancel}
        sx={{
          position: 'absolute',
          right: 8,
          top: 8,
          color: dk ? 'rgba(255,255,255,0.5)' : 'text.secondary',
        }}
      >
        <CloseIcon />
      </IconButton>

      <Box
        sx={{
          display: 'flex',
          justifyContent: 'center',
          pt: 3,
          pb: 1,
        }}
      >
        <Box
          sx={{
            width: 64,
            height: 64,
            borderRadius: '50%',
            bgcolor: dk ? alpha(config.color, 0.15) : config.bgColor,
            color: config.color,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
          }}
        >
          {config.icon}
        </Box>
      </Box>

      <DialogTitle sx={{ textAlign: 'center', fontWeight: 700, fontSize: '1.25rem', pb: 0 }}>
        {title}
      </DialogTitle>

      <DialogContent>
        <Typography
          variant="body1"
          sx={{
            textAlign: 'center',
            color: dk ? 'rgba(255,255,255,0.7)' : 'text.secondary',
            lineHeight: 1.6,
            px: 2,
          }}
        >
          {message}
        </Typography>
      </DialogContent>

      <DialogActions sx={{ px: 3, pb: 3, gap: 1, flexDirection: 'column' }}>
        <Button
          fullWidth
          variant="contained"
          onClick={handleConfirm}
          disabled={isLoading}
          startIcon={<ConfirmIcon />}
          sx={{
            py: 1.5,
            fontWeight: 700,
            fontSize: '1rem',
            borderRadius: 2,
            bgcolor: severity === 'danger' ? '#f44336' : severity === 'warning' ? '#ff9800' : '#2196f3',
            '&:hover': {
              bgcolor: severity === 'danger' ? '#d32f2f' : severity === 'warning' ? '#f57c00' : '#1976d2',
            },
          }}
        >
          {isLoading ? 'Please wait...' : confirmLabel}
        </Button>
        <Button
          fullWidth
          variant="outlined"
          onClick={handleCancel}
          disabled={isLoading}
          sx={{
            py: 1.5,
            fontWeight: 600,
            fontSize: '1rem',
            borderRadius: 2,
            borderColor: dk ? 'rgba(255,255,255,0.2)' : 'divider',
            color: dk ? 'rgba(255,255,255,0.8)' : 'text.primary',
          }}
        >
          {cancelLabel}
        </Button>
      </DialogActions>
    </Dialog>
  );
};

export default ConfirmationModal;
