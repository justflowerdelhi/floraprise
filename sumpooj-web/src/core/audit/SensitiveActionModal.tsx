// =============================================================================
// SENSITIVE ACTION MODAL - Confirmation Dialog for Critical Operations
// =============================================================================

import React, { useState, createContext, useContext, useCallback, type ReactNode } from 'react';
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  Box,
  Typography,
  TextField,
  Alert,
  alpha,
  CircularProgress,
} from '@mui/material';
import {
  Warning,
  Error,
  Info,
  MoneyOff,
  Inventory,
  Edit,
  DeleteForever,
  ArrowDownward,
  Block,
  CreditCardOff,
  Lock,
  LockOpen,
  PersonRemove,
} from '@mui/icons-material';
import type {
  SensitiveActionType,
  SensitiveActionConfig,
} from './AuditTypes';
import { SENSITIVE_ACTION_CONFIGS } from './AuditTypes';

// -----------------------------------------------------------------------------
// Icon Map
// -----------------------------------------------------------------------------

const ACTION_ICONS: Record<string, React.ReactNode> = {
  MoneyOff: <MoneyOff sx={{ fontSize: 28 }} />,
  Inventory: <Inventory sx={{ fontSize: 28 }} />,
  Edit: <Edit sx={{ fontSize: 28 }} />,
  DeleteForever: <DeleteForever sx={{ fontSize: 28 }} />,
  ArrowDownward: <ArrowDownward sx={{ fontSize: 28 }} />,
  Block: <Block sx={{ fontSize: 28 }} />,
  CreditCardOff: <CreditCardOff sx={{ fontSize: 28 }} />,
  Lock: <Lock sx={{ fontSize: 28 }} />,
  LockOpen: <LockOpen sx={{ fontSize: 28 }} />,
  PersonRemove: <PersonRemove sx={{ fontSize: 28 }} />,
};

// -----------------------------------------------------------------------------
// Context Types
// -----------------------------------------------------------------------------

interface SensitiveActionContextValue {
  requestConfirmation: (
    actionType: SensitiveActionType,
    options?: {
      customTitle?: string;
      customDescription?: string;
      metadata?: Record<string, unknown>;
    }
  ) => Promise<{ confirmed: boolean; reason?: string }>;
}

const SensitiveActionContext = createContext<SensitiveActionContextValue | undefined>(undefined);

// -----------------------------------------------------------------------------
// Provider Component
// -----------------------------------------------------------------------------

interface SensitiveActionProviderProps {
  children: ReactNode;
}

interface PendingAction {
  config: SensitiveActionConfig;
  customTitle?: string;
  customDescription?: string;
  metadata?: Record<string, unknown>;
  resolve: (result: { confirmed: boolean; reason?: string }) => void;
}

export function SensitiveActionProvider({ children }: SensitiveActionProviderProps) {
  const [pendingAction, setPendingAction] = useState<PendingAction | null>(null);
  const [reason, setReason] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  
  const requestConfirmation = useCallback(
    (
      actionType: SensitiveActionType,
      options?: {
        customTitle?: string;
        customDescription?: string;
        metadata?: Record<string, unknown>;
      }
    ): Promise<{ confirmed: boolean; reason?: string }> => {
      return new Promise((resolve) => {
        const config = SENSITIVE_ACTION_CONFIGS[actionType];
        setPendingAction({
          config,
          customTitle: options?.customTitle,
          customDescription: options?.customDescription,
          metadata: options?.metadata,
          resolve,
        });
        setReason('');
        setPassword('');
        setError(null);
      });
    },
    []
  );
  
  const handleConfirm = async () => {
    if (!pendingAction) return;
    
    const { config, resolve } = pendingAction;
    
    // Validation
    if (config.requireReason && !reason.trim()) {
      setError('Please provide a reason for this action');
      return;
    }
    
    if (config.requirePassword && !password.trim()) {
      setError('Please enter your password to confirm');
      return;
    }
    
    // Mock password validation for demo
    if (config.requirePassword && password !== 'admin123') {
      setError('Invalid password');
      return;
    }
    
    setLoading(true);
    
    // Simulate API call
    await new Promise((r) => setTimeout(r, 500));
    
    setLoading(false);
    setPendingAction(null);
    resolve({ confirmed: true, reason: reason.trim() || undefined });
  };
  
  const handleCancel = () => {
    if (pendingAction) {
      pendingAction.resolve({ confirmed: false });
      setPendingAction(null);
    }
  };
  
  const getWarningColor = (level: 'info' | 'warning' | 'danger'): string => {
    switch (level) {
      case 'danger':
        return '#f44336';
      case 'warning':
        return '#ff9800';
      default:
        return '#2196f3';
    }
  };
  
  const getWarningIcon = (level: 'info' | 'warning' | 'danger'): React.ReactNode => {
    switch (level) {
      case 'danger':
        return <Error />;
      case 'warning':
        return <Warning />;
      default:
        return <Info />;
    }
  };
  
  return (
    <SensitiveActionContext.Provider value={{ requestConfirmation }}>
      {children}
      
      {/* Confirmation Dialog */}
      <Dialog
        open={!!pendingAction}
        onClose={handleCancel}
        maxWidth="sm"
        fullWidth
        PaperProps={{
          sx: {
            bgcolor: '#1a1a2e',
            backgroundImage: 'none',
          },
        }}
      >
        {pendingAction && (
          <>
            <DialogTitle
              sx={{
                display: 'flex',
                alignItems: 'center',
                gap: 2,
                borderBottom: 1,
                borderColor: 'divider',
              }}
            >
              <Box
                sx={{
                  width: 56,
                  height: 56,
                  borderRadius: 2,
                  bgcolor: alpha(getWarningColor(pendingAction.config.warningLevel), 0.15),
                  color: getWarningColor(pendingAction.config.warningLevel),
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                }}
              >
                {ACTION_ICONS[pendingAction.config.icon] || getWarningIcon(pendingAction.config.warningLevel)}
              </Box>
              <Box>
                <Typography variant="h6" fontWeight={600}>
                  {pendingAction.customTitle || pendingAction.config.title}
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  This action requires confirmation
                </Typography>
              </Box>
            </DialogTitle>
            
            <DialogContent sx={{ pt: 3 }}>
              {/* Warning Alert */}
              <Alert
                severity={pendingAction.config.warningLevel === 'danger' ? 'error' : pendingAction.config.warningLevel}
                sx={{
                  mb: 3,
                  bgcolor: alpha(getWarningColor(pendingAction.config.warningLevel), 0.1),
                  color: 'text.primary',
                  '& .MuiAlert-icon': {
                    color: getWarningColor(pendingAction.config.warningLevel),
                  },
                }}
              >
                {pendingAction.customDescription || pendingAction.config.description}
              </Alert>
              
              {/* Metadata Display */}
              {pendingAction.metadata && Object.keys(pendingAction.metadata).length > 0 && (
                <Box
                  sx={{
                    p: 2,
                    bgcolor: '#0f0f0f',
                    borderRadius: 2,
                    mb: 3,
                  }}
                >
                  <Typography variant="caption" color="text.secondary" display="block" mb={1}>
                    Action Details:
                  </Typography>
                  {Object.entries(pendingAction.metadata).map(([key, value]) => (
                    <Box key={key} sx={{ display: 'flex', justifyContent: 'space-between', mb: 0.5 }}>
                      <Typography variant="body2" color="text.secondary">
                        {key.replace(/_/g, ' ').replace(/\b\w/g, (l) => l.toUpperCase())}:
                      </Typography>
                      <Typography variant="body2" fontWeight={600}>
                        {String(value)}
                      </Typography>
                    </Box>
                  ))}
                </Box>
              )}
              
              {/* Reason Input */}
              {pendingAction.config.requireReason && (
                <TextField
                  fullWidth
                  label="Reason for this action"
                  placeholder="Please explain why you are performing this action..."
                  value={reason}
                  onChange={(e) => {
                    setReason(e.target.value);
                    setError(null);
                  }}
                  multiline
                  rows={2}
                  required
                  sx={{ mb: pendingAction.config.requirePassword ? 2 : 0 }}
                />
              )}
              
              {/* Password Input */}
              {pendingAction.config.requirePassword && (
                <TextField
                  fullWidth
                  type="password"
                  label="Enter your password to confirm"
                  placeholder="Password"
                  value={password}
                  onChange={(e) => {
                    setPassword(e.target.value);
                    setError(null);
                  }}
                  required
                />
              )}
              
              {/* Error Display */}
              {error && (
                <Alert severity="error" sx={{ mt: 2 }}>
                  {error}
                </Alert>
              )}
            </DialogContent>
            
            <DialogActions sx={{ p: 2, gap: 1, borderTop: 1, borderColor: 'divider' }}>
              <Button
                onClick={handleCancel}
                color="inherit"
                disabled={loading}
              >
                {pendingAction.config.cancelText}
              </Button>
              <Button
                variant="contained"
                onClick={handleConfirm}
                disabled={loading}
                sx={{
                  bgcolor: getWarningColor(pendingAction.config.warningLevel),
                  '&:hover': {
                    bgcolor: alpha(getWarningColor(pendingAction.config.warningLevel), 0.8),
                  },
                }}
              >
                {loading ? (
                  <CircularProgress size={20} color="inherit" />
                ) : (
                  pendingAction.config.confirmText
                )}
              </Button>
            </DialogActions>
          </>
        )}
      </Dialog>
    </SensitiveActionContext.Provider>
  );
}

// -----------------------------------------------------------------------------
// Hook
// -----------------------------------------------------------------------------

export function useSensitiveAction(): SensitiveActionContextValue {
  const context = useContext(SensitiveActionContext);
  if (!context) {
    throw new Error('useSensitiveAction must be used within a SensitiveActionProvider');
  }
  return context;
}

// -----------------------------------------------------------------------------
// Standalone Confirmation Button
// -----------------------------------------------------------------------------

interface SensitiveActionButtonProps {
  actionType: SensitiveActionType;
  onConfirm: (reason?: string) => void;
  onCancel?: () => void;
  children: React.ReactNode;
  customTitle?: string;
  customDescription?: string;
  metadata?: Record<string, unknown>;
  disabled?: boolean;
  variant?: 'text' | 'outlined' | 'contained';
  color?: 'inherit' | 'primary' | 'secondary' | 'success' | 'error' | 'info' | 'warning';
  size?: 'small' | 'medium' | 'large';
  startIcon?: React.ReactNode;
  fullWidth?: boolean;
  sx?: object;
}

export function SensitiveActionButton({
  actionType,
  onConfirm,
  onCancel,
  children,
  customTitle,
  customDescription,
  metadata,
  disabled = false,
  variant = 'contained',
  color = 'primary',
  size = 'medium',
  startIcon,
  fullWidth = false,
  sx = {},
}: SensitiveActionButtonProps) {
  const { requestConfirmation } = useSensitiveAction();
  
  const handleClick = async () => {
    const result = await requestConfirmation(actionType, {
      customTitle,
      customDescription,
      metadata,
    });
    
    if (result.confirmed) {
      onConfirm(result.reason);
    } else {
      onCancel?.();
    }
  };
  
  return (
    <Button
      variant={variant}
      color={color}
      size={size}
      startIcon={startIcon}
      fullWidth={fullWidth}
      disabled={disabled}
      onClick={handleClick}
      sx={sx}
    >
      {children}
    </Button>
  );
}

// -----------------------------------------------------------------------------
// Quick Confirmation Helper Functions
// -----------------------------------------------------------------------------

export function createSensitiveActionHandler(
  requestConfirmation: SensitiveActionContextValue['requestConfirmation'],
  actionType: SensitiveActionType,
  onConfirm: (reason?: string) => void,
  options?: {
    customTitle?: string;
    customDescription?: string;
    metadata?: Record<string, unknown>;
  }
) {
  return async () => {
    const result = await requestConfirmation(actionType, options);
    if (result.confirmed) {
      onConfirm(result.reason);
    }
  };
}
