/**
 * DiscountApprovalModal.tsx — Manager Approval Modal for Discount Overrides
 *
 * Features:
 * - Compact design for quick approval
 * - Manager PIN verification
 * - Shows discount details being approved
 * - Logs approval to audit trail
 */
import React, { useState, useEffect, useRef, createContext, useContext, useCallback, type ReactNode } from 'react';
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
  CircularProgress,
  Chip,
  useTheme,
} from '@mui/material';
import {
  Security as SecurityIcon,
  LocalOffer as DiscountIcon,
  CheckCircle as ApproveIcon,
  Cancel as DenyIcon,
} from '@mui/icons-material';
import type { UserRole } from '../rbac/RBACTypes';
import type { DiscountValidationResult } from '../rbac/DiscountPermissions';
import { canApproveDiscounts, logDiscountApplication, DISCOUNT_PERMISSIONS } from '../rbac/DiscountPermissions';
import { fmtCurrency } from '../../pages/cart/CartUtils';

// ─── Mock Manager Credentials (would be API in production) ──

interface ManagerCredential {
  id: string;
  name: string;
  role: UserRole;
  pin: string;
}

const MOCK_MANAGERS: ManagerCredential[] = [
  { id: 'mgr-1', name: 'Sarah Manager', role: 'MANAGER', pin: '1234' },
  { id: 'mgr-2', name: 'John Admin', role: 'ADMIN', pin: '0000' },
  { id: 'mgr-3', name: 'Lisa Manager', role: 'MANAGER', pin: '5678' },
];

// ─── Context Types ──────────────────────────────────────────

export interface DiscountApprovalRequest {
  discountType: 'ORDER' | 'LINE';
  discountMethod: 'PERCENT' | 'FLAT';
  discountValue: number;
  effectivePercent: number;
  subtotalOrLineGross: number;
  discountAmount: number;
  validation: DiscountValidationResult;
  productName?: string;
  lineItemId?: string;
  orderId?: string;
  requestingUserId: string;
  requestingUserName: string;
  requestingUserRole: UserRole;
}

interface DiscountApprovalResult {
  approved: boolean;
  approvedBy?: string;
  approverName?: string;
  approverRole?: UserRole;
  reason?: string;
}

interface DiscountApprovalContextValue {
  requestApproval: (request: DiscountApprovalRequest) => Promise<DiscountApprovalResult>;
}

const DiscountApprovalContext = createContext<DiscountApprovalContextValue | null>(null);

// ─── Provider Component ─────────────────────────────────────

interface DiscountApprovalProviderProps {
  children: ReactNode;
}

interface PendingApproval {
  request: DiscountApprovalRequest;
  resolve: (result: DiscountApprovalResult) => void;
}

export function DiscountApprovalProvider({ children }: DiscountApprovalProviderProps) {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';
  const pinInputRef = useRef<HTMLInputElement>(null);

  const [pending, setPending] = useState<PendingApproval | null>(null);
  const [pin, setPin] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Focus PIN input when modal opens
  useEffect(() => {
    if (pending) {
      setTimeout(() => pinInputRef.current?.focus(), 100);
    }
  }, [pending]);

  const requestApproval = useCallback(
    (request: DiscountApprovalRequest): Promise<DiscountApprovalResult> => {
      return new Promise((resolve) => {
        setPending({ request, resolve });
        setPin('');
        setError(null);
      });
    },
    []
  );

  const handleApprove = async () => {
    if (!pending) return;

    if (!pin.trim()) {
      setError('Please enter manager PIN');
      return;
    }

    setLoading(true);

    // Simulate API call delay
    await new Promise((r) => setTimeout(r, 300));

    // Find manager by PIN
    const manager = MOCK_MANAGERS.find((m) => m.pin === pin);

    if (!manager) {
      setError('Invalid PIN');
      setLoading(false);
      return;
    }

    // Check if the manager has approval permissions
    if (!canApproveDiscounts(manager.role)) {
      setError(`${manager.name} does not have discount approval permission`);
      setLoading(false);
      return;
    }

    // Check if approver can approve this discount level
    const approverPermissions = DISCOUNT_PERMISSIONS[manager.role];
    const maxAllowed = pending.request.discountType === 'ORDER'
      ? approverPermissions.maxOrderPercent
      : approverPermissions.maxLinePercent;

    if (maxAllowed !== null && pending.request.effectivePercent > maxAllowed) {
      setError(`${manager.name} can only approve up to ${maxAllowed}%`);
      setLoading(false);
      return;
    }

    // Success - log the approval
    logDiscountApplication({
      userId: pending.request.requestingUserId,
      userName: pending.request.requestingUserName,
      userRole: pending.request.requestingUserRole,
      discountType: pending.request.discountType,
      discountMethod: pending.request.discountMethod,
      discountValue: pending.request.discountValue,
      effectivePercent: pending.request.effectivePercent,
      orderId: pending.request.orderId,
      lineItemId: pending.request.lineItemId,
      productName: pending.request.productName,
      subtotalBefore: pending.request.subtotalOrLineGross,
      discountAmount: pending.request.discountAmount,
      approvalRequired: true,
      approvedBy: manager.id,
      approverName: manager.name,
      approverRole: manager.role,
    });

    setLoading(false);
    pending.resolve({
      approved: true,
      approvedBy: manager.id,
      approverName: manager.name,
      approverRole: manager.role,
    });
    setPending(null);
  };

  const handleCancel = () => {
    if (!pending) return;
    pending.resolve({ approved: false });
    setPending(null);
  };

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter') handleApprove();
    if (e.key === 'Escape') handleCancel();
  };

  const contextValue: DiscountApprovalContextValue = { requestApproval };

  return (
    <DiscountApprovalContext.Provider value={contextValue}>
      {children}

      {/* Approval Modal */}
      <Dialog
        open={Boolean(pending)}
        onClose={handleCancel}
        maxWidth="xs"
        fullWidth
        PaperProps={{
          sx: {
            borderRadius: 3,
            bgcolor: dk ? '#1a1a2e' : '#fff',
            backgroundImage: 'none',
          },
        }}
        TransitionProps={{
          timeout: { enter: 150, exit: 100 },
        }}
      >
        {pending && (
          <>
            <DialogTitle sx={{ pb: 1 }}>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
                <Box
                  sx={{
                    width: 40,
                    height: 40,
                    borderRadius: '50%',
                    bgcolor: dk ? 'rgba(255,193,7,0.15)' : 'rgba(255,193,7,0.1)',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                  }}
                >
                  <SecurityIcon sx={{ color: theme.palette.warning.main }} />
                </Box>
                <Box>
                  <Typography variant="h6" sx={{ fontWeight: 700, fontSize: '1rem' }}>
                    Manager Approval Required
                  </Typography>
                  <Typography variant="caption" sx={{ color: 'text.secondary' }}>
                    Discount exceeds your permission level
                  </Typography>
                </Box>
              </Box>
            </DialogTitle>

            <DialogContent sx={{ pt: 1 }}>
              {/* Discount Details */}
              <Box
                sx={{
                  p: 2,
                  borderRadius: 2,
                  bgcolor: dk ? 'rgba(255,255,255,0.04)' : 'rgba(0,0,0,0.02)',
                  border: `1px solid ${dk ? 'rgba(255,255,255,0.08)' : '#e0e0e0'}`,
                  mb: 2,
                }}
              >
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 1.5 }}>
                  <DiscountIcon sx={{ fontSize: 18, color: theme.palette.primary.main }} />
                  <Typography variant="subtitle2" sx={{ fontWeight: 700 }}>
                    Discount Request
                  </Typography>
                </Box>

                <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 0.75 }}>
                  <Typography variant="body2" color="text.secondary">Type</Typography>
                  <Chip
                    label={pending.request.discountType === 'ORDER' ? 'Order' : 'Line Item'}
                    size="small"
                    sx={{ fontWeight: 600, fontSize: '0.7rem', height: 22 }}
                  />
                </Box>

                {pending.request.productName && (
                  <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 0.75 }}>
                    <Typography variant="body2" color="text.secondary">Product</Typography>
                    <Typography variant="body2" sx={{ fontWeight: 600 }}>
                      {pending.request.productName}
                    </Typography>
                  </Box>
                )}

                <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 0.75 }}>
                  <Typography variant="body2" color="text.secondary">Discount</Typography>
                  <Typography variant="body2" sx={{ fontWeight: 700, color: theme.palette.success.main }}>
                    {pending.request.discountMethod === 'PERCENT'
                      ? `${pending.request.discountValue}%`
                      : fmtCurrency(pending.request.discountValue)
                    }
                    {pending.request.discountMethod === 'FLAT' && (
                      <Typography component="span" variant="caption" sx={{ ml: 0.5, color: 'text.secondary' }}>
                        ({pending.request.effectivePercent}%)
                      </Typography>
                    )}
                  </Typography>
                </Box>

                <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 0.75 }}>
                  <Typography variant="body2" color="text.secondary">Amount</Typography>
                  <Typography variant="body2" sx={{ fontWeight: 700, color: theme.palette.error.main }}>
                    -{fmtCurrency(pending.request.discountAmount)}
                  </Typography>
                </Box>

                <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                  <Typography variant="body2" color="text.secondary">Your Limit</Typography>
                  <Typography variant="body2" sx={{ fontWeight: 600 }}>
                    {pending.request.validation.maxAllowed}%
                  </Typography>
                </Box>
              </Box>

              {/* Requester Info */}
              <Box sx={{ mb: 2 }}>
                <Typography variant="caption" color="text.secondary">
                  Requested by: <strong>{pending.request.requestingUserName}</strong> ({pending.request.requestingUserRole})
                </Typography>
              </Box>

              {/* PIN Input */}
              <TextField
                inputRef={pinInputRef}
                fullWidth
                type="password"
                label="Manager PIN"
                placeholder="Enter manager PIN"
                value={pin}
                onChange={(e) => setPin(e.target.value)}
                onKeyDown={handleKeyDown}
                disabled={loading}
                autoComplete="off"
                slotProps={{
                  input: {
                    sx: {
                      fontSize: '1.2rem',
                      fontWeight: 600,
                      letterSpacing: '0.2em',
                      textAlign: 'center',
                    },
                  },
                }}
                sx={{
                  '& .MuiOutlinedInput-root': {
                    ...(dk ? { '& fieldset': { borderColor: 'rgba(255,255,255,0.15)' } } : {}),
                  },
                }}
              />

              {/* Error */}
              {error && (
                <Alert severity="error" sx={{ mt: 2, fontSize: '0.85rem' }}>
                  {error}
                </Alert>
              )}

              {/* Demo Hint */}
              <Typography
                variant="caption"
                sx={{ display: 'block', mt: 1.5, color: 'text.disabled', textAlign: 'center' }}
              >
                Demo PINs: Manager (1234, 5678), Admin (0000)
              </Typography>
            </DialogContent>

            <DialogActions sx={{ px: 3, pb: 2.5, pt: 1, gap: 1 }}>
              <Button
                onClick={handleCancel}
                disabled={loading}
                startIcon={<DenyIcon />}
                sx={{
                  fontWeight: 600,
                  ...(dk ? { color: 'rgba(255,255,255,0.7)' } : {}),
                }}
              >
                Cancel
              </Button>
              <Button
                variant="contained"
                onClick={handleApprove}
                disabled={loading || !pin.trim()}
                startIcon={loading ? <CircularProgress size={18} color="inherit" /> : <ApproveIcon />}
                sx={{
                  minWidth: 120,
                  fontWeight: 700,
                  ...(dk
                    ? {
                        bgcolor: '#fdd835',
                        color: '#000',
                        '&:hover': { bgcolor: '#fbc02d' },
                        '&.Mui-disabled': { bgcolor: 'rgba(255,255,255,0.12)', color: 'rgba(255,255,255,0.3)' },
                      }
                    : {}),
                }}
              >
                {loading ? 'Verifying...' : 'Approve'}
              </Button>
            </DialogActions>
          </>
        )}
      </Dialog>
    </DiscountApprovalContext.Provider>
  );
}

// ─── Hook ───────────────────────────────────────────────────

export function useDiscountApproval(): DiscountApprovalContextValue {
  const ctx = useContext(DiscountApprovalContext);
  if (!ctx) {
    throw new Error('useDiscountApproval must be used within DiscountApprovalProvider');
  }
  return ctx;
}

// Already exported inline: DiscountApprovalRequest
// DiscountApprovalResult is internal only
