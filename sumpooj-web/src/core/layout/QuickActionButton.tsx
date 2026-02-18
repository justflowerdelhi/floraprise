/**
 * QuickActionButton.tsx — Floating Action Button with Quick Actions
 *
 * Features:
 * - Floating button for primary action
 * - Expandable menu for quick actions
 * - Role-based action filtering
 */
import React, { useState } from 'react';
import {
  Box, Fab, Tooltip, Zoom, SpeedDial, SpeedDialAction, SpeedDialIcon,
  useTheme, alpha,
} from '@mui/material';
import {
  Add as AddIcon,
  Close as CloseIcon,
  PointOfSale as POSIcon,
  Phone as PhoneIcon,
  AddShoppingCart as PurchaseIcon,
  LocalFlorist as ProductIcon,
  Person as CustomerIcon,
} from '@mui/icons-material';
import { useNavigate } from 'react-router-dom';
import { useRBAC } from '../rbac/RBACContext';
import { QUICK_ACTIONS } from '../rbac/RBACTypes';
import type { Permission } from '../rbac/RBACTypes';

// ─── Types ──────────────────────────────────────────────────

interface ActionItem {
  id: string;
  label: string;
  icon: React.ReactNode;
  path: string;
  permissions: Permission[];
  color?: string;
}

// ─── Extended Actions ───────────────────────────────────────

const ALL_QUICK_ACTIONS: ActionItem[] = [
  {
    id: 'new-sale',
    label: 'New Sale',
    icon: <POSIcon />,
    path: '/pos',
    permissions: ['pos:access'],
    color: '#4caf50',
  },
  {
    id: 'phone-order',
    label: 'Phone Order',
    icon: <PhoneIcon />,
    path: '/phone-order',
    permissions: ['orders:create'],
    color: '#2196f3',
  },
  {
    id: 'new-purchase',
    label: 'Add Stock',
    icon: <PurchaseIcon />,
    path: '/purchases/new',
    permissions: ['inventory:purchase'],
    color: '#ff9800',
  },
  {
    id: 'new-product',
    label: 'Add Product',
    icon: <ProductIcon />,
    path: '/products/new',
    permissions: ['products:create'],
    color: '#9c27b0',
  },
  {
    id: 'new-customer',
    label: 'Add Customer',
    icon: <CustomerIcon />,
    path: '/customers?action=new',
    permissions: ['customers:create'],
    color: '#00bcd4',
  },
];

// ─── Simple FAB (Single Action) ─────────────────────────────

interface SimpleFabProps {
  label: string;
  icon?: React.ReactNode;
  onClick?: () => void;
  path?: string;
  color?: string;
  position?: 'bottom-right' | 'bottom-left' | 'bottom-center';
}

export const SimpleFab: React.FC<SimpleFabProps> = ({
  label,
  icon = <AddIcon />,
  onClick,
  path,
  color = '#fdd835',
  position = 'bottom-right',
}) => {
  const navigate = useNavigate();

  const handleClick = () => {
    if (onClick) {
      onClick();
    } else if (path) {
      navigate(path);
    }
  };

  const positionStyles = {
    'bottom-right': { bottom: 24, right: 24 },
    'bottom-left': { bottom: 24, left: 24 },
    'bottom-center': { bottom: 24, left: '50%', transform: 'translateX(-50%)' },
  };

  return (
    <Tooltip title={label} placement="left">
      <Fab
        onClick={handleClick}
        sx={{
          position: 'fixed',
          ...positionStyles[position],
          bgcolor: color,
          color: '#000',
          fontWeight: 700,
          boxShadow: `0 6px 20px ${alpha(color, 0.5)}`,
          '&:hover': {
            bgcolor: alpha(color, 0.9),
            boxShadow: `0 8px 25px ${alpha(color, 0.6)}`,
            transform: position === 'bottom-center' ? 'translateX(-50%) scale(1.05)' : 'scale(1.05)',
          },
          transition: 'all 0.2s',
          zIndex: 1200,
        }}
      >
        {icon}
      </Fab>
    </Tooltip>
  );
};

// ─── Speed Dial (Multiple Actions) ──────────────────────────

interface QuickActionButtonProps {
  /** Filter to specific actions */
  actions?: string[];
  /** Position on screen */
  position?: 'bottom-right' | 'bottom-left';
  /** Primary action (clicked without expansion) */
  primaryAction?: string;
}

export const QuickActionButton: React.FC<QuickActionButtonProps> = ({
  actions,
  position = 'bottom-right',
  primaryAction,
}) => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';
  const navigate = useNavigate();
  const { canAny } = useRBAC();

  const [open, setOpen] = useState(false);

  // Filter actions based on permissions and provided list
  const filteredActions = ALL_QUICK_ACTIONS.filter((action) => {
    // Check permissions
    if (!canAny(action.permissions)) return false;

    // Check if specific actions were requested
    if (actions && !actions.includes(action.id)) return false;

    return true;
  });

  // If no actions available, don't render
  if (filteredActions.length === 0) return null;

  // If only one action, show simple FAB
  if (filteredActions.length === 1) {
    const action = filteredActions[0];
    return (
      <SimpleFab
        label={action.label}
        icon={action.icon}
        path={action.path}
        color={action.color ?? '#fdd835'}
        position={position}
      />
    );
  }

  // Handle primary action click
  const handlePrimaryClick = () => {
    if (primaryAction) {
      const action = filteredActions.find((a) => a.id === primaryAction);
      if (action) {
        navigate(action.path);
        return;
      }
    }
    setOpen(!open);
  };

  const handleActionClick = (path: string) => {
    navigate(path);
    setOpen(false);
  };

  const positionStyles = position === 'bottom-right'
    ? { bottom: 24, right: 24 }
    : { bottom: 24, left: 24 };

  return (
    <SpeedDial
      ariaLabel="Quick Actions"
      sx={{
        position: 'fixed',
        ...positionStyles,
        '& .MuiFab-primary': {
          bgcolor: '#fdd835',
          color: '#000',
          boxShadow: '0 6px 20px rgba(253,216,53,0.4)',
          '&:hover': {
            bgcolor: '#ffeb3b',
          },
        },
        zIndex: 1200,
      }}
      icon={<SpeedDialIcon icon={<AddIcon />} openIcon={<CloseIcon />} />}
      onOpen={() => setOpen(true)}
      onClose={() => setOpen(false)}
      open={open}
      direction="up"
    >
      {filteredActions.map((action) => (
        <SpeedDialAction
          key={action.id}
          icon={action.icon}
          tooltipTitle={action.label}
          tooltipOpen
          onClick={() => handleActionClick(action.path)}
          sx={{
            '& .MuiSpeedDialAction-fab': {
              bgcolor: action.color ?? '#666',
              color: '#fff',
              '&:hover': {
                bgcolor: alpha(action.color ?? '#666', 0.85),
              },
            },
            '& .MuiSpeedDialAction-staticTooltipLabel': {
              bgcolor: dk ? '#2a2a3e' : '#333',
              color: '#fff',
              fontWeight: 600,
              whiteSpace: 'nowrap',
              px: 1.5,
              py: 0.75,
              borderRadius: 1,
            },
          }}
        />
      ))}
    </SpeedDial>
  );
};

// ─── Inline Quick Actions Bar ───────────────────────────────

interface QuickActionsBarProps {
  maxActions?: number;
}

export const QuickActionsBar: React.FC<QuickActionsBarProps> = ({ maxActions = 3 }) => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';
  const navigate = useNavigate();
  const { canAny } = useRBAC();

  const filteredActions = ALL_QUICK_ACTIONS.filter((action) => canAny(action.permissions)).slice(0, maxActions);

  if (filteredActions.length === 0) return null;

  return (
    <Box sx={{ display: 'flex', gap: 1.5 }}>
      {filteredActions.map((action) => (
        <Tooltip key={action.id} title={action.label}>
          <Fab
            size="small"
            onClick={() => navigate(action.path)}
            sx={{
              bgcolor: action.color ?? '#666',
              color: '#fff',
              boxShadow: `0 4px 12px ${alpha(action.color ?? '#666', 0.4)}`,
              '&:hover': {
                bgcolor: alpha(action.color ?? '#666', 0.85),
                transform: 'scale(1.1)',
              },
              transition: 'all 0.2s',
            }}
          >
            {action.icon}
          </Fab>
        </Tooltip>
      ))}
    </Box>
  );
};

export default QuickActionButton;
