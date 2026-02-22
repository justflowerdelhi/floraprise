// =============================================================================
// FINANCIAL LOCK - UI Components for Lock Status & Controls
// =============================================================================

import React from 'react';
import {
  Box,
  Typography,
  Alert,
  Button,
  Tooltip,
  Chip,
  alpha,
} from '@mui/material';
import {
  Lock,
  LockOpen,
  Warning,
  Edit,
  InfoOutlined,
} from '@mui/icons-material';
import type { LockStatus, LockReason } from './AuditTypes';
import { LOCK_MESSAGES } from './AuditTypes';
import { useSensitiveAction } from './SensitiveActionModal';

// -----------------------------------------------------------------------------
// Lock Status Banner
// -----------------------------------------------------------------------------

interface LockStatusBannerProps {
  lockStatus: LockStatus;
  entityName?: string;
  onRequestOverride?: () => void;
  showOverrideButton?: boolean;
}

export function LockStatusBanner({
  lockStatus,
  entityName = 'This item',
  onRequestOverride,
  showOverrideButton = true,
}: LockStatusBannerProps) {
  if (!lockStatus.isLocked) return null;
  
  return (
    <Alert
      severity="warning"
      icon={<Lock />}
      sx={{
        mb: 2,
        bgcolor: alpha('#ff9800', 0.1),
        border: 1,
        borderColor: alpha('#ff9800', 0.3),
        '& .MuiAlert-icon': { color: '#ff9800' },
      }}
      action={
        showOverrideButton && lockStatus.canOverride && onRequestOverride ? (
          <Button
            size="small"
            color="warning"
            onClick={onRequestOverride}
            startIcon={<LockOpen />}
          >
            Request Override
          </Button>
        ) : undefined
      }
    >
      <Typography variant="body2" fontWeight={600} mb={0.5}>
        {entityName} is Locked
      </Typography>
      <Typography variant="body2" color="text.secondary">
        {lockStatus.message}
        {!lockStatus.canOverride && ' This cannot be changed.'}
      </Typography>
    </Alert>
  );
}

// -----------------------------------------------------------------------------
// Lock Status Chip
// -----------------------------------------------------------------------------

interface LockStatusChipProps {
  lockStatus: LockStatus;
  size?: 'small' | 'medium';
}

export function LockStatusChip({ lockStatus, size = 'small' }: LockStatusChipProps) {
  if (!lockStatus.isLocked) return null;
  
  return (
    <Tooltip title={lockStatus.message || 'This item is locked'}>
      <Chip
        icon={<Lock />}
        label="Locked"
        size={size}
        sx={{
          bgcolor: alpha('#ff9800', 0.15),
          color: '#ff9800',
          '& .MuiChip-icon': { color: '#ff9800' },
        }}
      />
    </Tooltip>
  );
}

// -----------------------------------------------------------------------------
// Locked Field Wrapper
// -----------------------------------------------------------------------------

interface LockedFieldWrapperProps {
  lockStatus: LockStatus;
  children: React.ReactNode;
  fieldLabel?: string;
}

export function LockedFieldWrapper({
  lockStatus,
  children,
  fieldLabel,
}: LockedFieldWrapperProps) {
  if (!lockStatus.isLocked) {
    return children;
  }
  
  return (
    <Box sx={{ position: 'relative' }}>
      <Box
        sx={{
          opacity: 0.6,
          pointerEvents: 'none',
          filter: 'grayscale(30%)',
        }}
      >
        {children}
      </Box>
      <Tooltip title={lockStatus.message || `${fieldLabel || 'Field'} is locked`}>
        <Box
          sx={{
            position: 'absolute',
            top: 8,
            right: 8,
            width: 24,
            height: 24,
            borderRadius: '50%',
            bgcolor: alpha('#ff9800', 0.15),
            color: '#ff9800',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
          }}
        >
          <Lock sx={{ fontSize: 14 }} />
        </Box>
      </Tooltip>
    </Box>
  );
}

// -----------------------------------------------------------------------------
// Edit Lock Guard
// -----------------------------------------------------------------------------

interface EditLockGuardProps {
  lockStatus: LockStatus;
  entityType: 'order' | 'proposal' | 'event' | 'payment';
  entityId: string;
  onOverrideGranted?: () => void;
  children: React.ReactNode;
}

export function EditLockGuard({
  lockStatus,
  entityType,
  entityId,
  onOverrideGranted,
  children,
}: EditLockGuardProps) {
  const { requestConfirmation } = useSensitiveAction();
  
  const handleOverrideRequest = async () => {
    let actionType: 'PROPOSAL_OVERRIDE' | 'ORDER_VOID' = 'PROPOSAL_OVERRIDE';
    
    if (entityType === 'order') {
      actionType = 'ORDER_VOID';
    }
    
    const result = await requestConfirmation(actionType, {
      metadata: {
        entity_type: entityType,
        entity_id: entityId,
        lock_reason: lockStatus.reason,
      },
    });
    
    if (result.confirmed && onOverrideGranted) {
      onOverrideGranted();
    }
  };
  
  if (!lockStatus.isLocked) {
    return children;
  }
  
  return (
    <Box>
      <LockStatusBanner
        lockStatus={lockStatus}
        entityName={`This ${entityType}`}
        onRequestOverride={lockStatus.canOverride ? handleOverrideRequest : undefined}
        showOverrideButton={lockStatus.canOverride}
      />
      <Box
        sx={{
          opacity: 0.7,
          pointerEvents: 'none',
        }}
      >
        {children}
      </Box>
    </Box>
  );
}

// -----------------------------------------------------------------------------
// Delete Lock Guard
// -----------------------------------------------------------------------------

interface DeleteLockGuardProps {
  lockStatus: LockStatus;
  onDelete: () => void;
  entityName?: string;
  children?: React.ReactNode;
  buttonVariant?: 'text' | 'outlined' | 'contained';
  buttonSize?: 'small' | 'medium' | 'large';
}

export function DeleteLockGuard({
  lockStatus,
  onDelete,
  entityName = 'item',
  children,
  buttonVariant = 'outlined',
  buttonSize = 'small',
}: DeleteLockGuardProps) {
  const { requestConfirmation } = useSensitiveAction();
  
  const handleDelete = async () => {
    const result = await requestConfirmation('EVENT_DELETION', {
      customTitle: `Delete ${entityName}`,
      customDescription: lockStatus.isLocked
        ? lockStatus.message
        : `Are you sure you want to delete this ${entityName}? This action cannot be undone.`,
    });
    
    if (result.confirmed) {
      onDelete();
    }
  };
  
  if (lockStatus.isLocked && !lockStatus.canOverride) {
    return (
      <Tooltip title={lockStatus.message}>
        <span>
          <Button
            variant={buttonVariant}
            size={buttonSize}
            color="error"
            disabled
            startIcon={<Lock />}
          >
            {children || `Delete ${entityName}`}
          </Button>
        </span>
      </Tooltip>
    );
  }
  
  return (
    <Button
      variant={buttonVariant}
      size={buttonSize}
      color="error"
      onClick={handleDelete}
    >
      {children || `Delete ${entityName}`}
    </Button>
  );
}

// -----------------------------------------------------------------------------
// Financial Rules Summary
// -----------------------------------------------------------------------------

interface FinancialRulesSummaryProps {
  entityType: 'order' | 'proposal' | 'event';
  rules: {
    rule: string;
    status: 'active' | 'inactive' | 'warning';
    description: string;
  }[];
}

export function FinancialRulesSummary({ entityType, rules }: FinancialRulesSummaryProps) {
  return (
    <Box
      sx={{
        p: 2,
        bgcolor: '#0f0f0f',
        borderRadius: 2,
        border: 1,
        borderColor: alpha('#fff', 0.1),
      }}
    >
      <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 2 }}>
        <InfoOutlined sx={{ fontSize: 18, color: 'text.secondary' }} />
        <Typography variant="subtitle2" color="text.secondary">
          Financial Controls for this {entityType}
        </Typography>
      </Box>
      
      <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1 }}>
        {rules.map((rule, index) => (
          <Box
            key={index}
            sx={{
              display: 'flex',
              alignItems: 'center',
              gap: 1.5,
              p: 1,
              borderRadius: 1,
              bgcolor: alpha(
                rule.status === 'active' ? '#4caf50' :
                rule.status === 'warning' ? '#ff9800' : '#9e9e9e',
                0.1
              ),
            }}
          >
            <Box
              sx={{
                width: 8,
                height: 8,
                borderRadius: '50%',
                bgcolor:
                  rule.status === 'active' ? '#4caf50' :
                  rule.status === 'warning' ? '#ff9800' : '#9e9e9e',
              }}
            />
            <Box sx={{ flex: 1 }}>
              <Typography variant="body2" fontWeight={600}>
                {rule.rule}
              </Typography>
              <Typography variant="caption" color="text.secondary">
                {rule.description}
              </Typography>
            </Box>
          </Box>
        ))}
      </Box>
    </Box>
  );
}

// -----------------------------------------------------------------------------
// Pre-built Rule Checks
// -----------------------------------------------------------------------------

export const ORDER_FINANCIAL_RULES = [
  {
    rule: 'Payment Lock',
    status: 'active' as const,
    description: 'Fully paid orders cannot be edited to prevent reconciliation issues',
  },
  {
    rule: 'Completion Lock',
    status: 'active' as const,
    description: 'Completed/delivered orders are read-only for audit purposes',
  },
  {
    rule: 'Refund Tracking',
    status: 'active' as const,
    description: 'All refunds are logged with reason and require confirmation',
  },
];

export const PROPOSAL_FINANCIAL_RULES = [
  {
    rule: 'Approval Lock',
    status: 'active' as const,
    description: 'Approved proposals require creating a new version to make changes',
  },
  {
    rule: 'Version Control',
    status: 'active' as const,
    description: 'All proposal changes are versioned and tracked',
  },
];

export const EVENT_FINANCIAL_RULES = [
  {
    rule: 'Payment Protection',
    status: 'active' as const,
    description: 'Events with payment history cannot be deleted',
  },
  {
    rule: 'Invoice Lock',
    status: 'active' as const,
    description: 'Events with sent invoices require override to modify',
  },
];
