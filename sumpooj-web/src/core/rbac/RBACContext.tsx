/**
 * RBACContext.tsx — Role-Based Access Control Provider
 *
 * Provides:
 * - Current user state derived from AuthContext (backend-authoritative)
 * - Permission checking hooks
 * - Route protection utilities
 * - Dev-only RolePicker (gated behind import.meta.env.DEV)
 */
import React, { createContext, useContext, useCallback, useMemo, type ReactNode } from 'react';
import type { User, UserRole, Permission, MenuItem, MenuSection } from './RBACTypes';
import {
  ROLE_PERMISSIONS,
  MENU_SECTIONS,
  DEFAULT_LANDING,
  hasPermission,
  hasAllPermissions,
  canAccessRoute,
} from './RBACTypes';
import { useAuth } from '../../auth/AuthContext';

// ─── Context Types ──────────────────────────────────────────

interface RBACContextValue {
  // User state (read-only, from AuthContext)
  user: User | null;
  isAuthenticated: boolean;
  role: UserRole | null;
  permissions: Permission[];

  // Permission checks
  can: (permission: Permission) => boolean;
  canAny: (permissions: Permission[]) => boolean;
  canAll: (permissions: Permission[]) => boolean;
  canAccessPath: (path: string) => boolean;

  // Navigation
  getFilteredMenu: () => MenuSection[];
  getDefaultLanding: () => string;
}

// ─── Context Creation ───────────────────────────────────────

const RBACContext = createContext<RBACContextValue | null>(null);

// ─── Provider Component ─────────────────────────────────────

interface RBACProviderProps {
  children: ReactNode;
}

export const RBACProvider: React.FC<RBACProviderProps> = ({ children }) => {
  // User comes from AuthContext — single source of truth
  const auth = useAuth();
  const user = auth.user;

  // Derived state
  const role = user?.role ?? null;
  const permissions = useMemo(() => {
    if (!role) return [];
    return ROLE_PERMISSIONS[role] ?? [];
  }, [role]);

  // Permission checks
  const can = useCallback(
    (permission: Permission): boolean => {
      return permissions.includes(permission);
    },
    [permissions]
  );

  const canAny = useCallback(
    (perms: Permission[]): boolean => {
      return hasPermission(permissions, perms);
    },
    [permissions]
  );

  const canAll = useCallback(
    (perms: Permission[]): boolean => {
      return hasAllPermissions(permissions, perms);
    },
    [permissions]
  );

  const canAccessPath = useCallback(
    (path: string): boolean => {
      if (!role) return false;
      return canAccessRoute(role, path);
    },
    [role]
  );

  // Get menu items filtered by permissions
  const getFilteredMenu = useCallback((): MenuSection[] => {
    return MENU_SECTIONS.map((section) => ({
      ...section,
      items: section.items.filter((item) => hasPermission(permissions, item.permissions)),
    })).filter((section) => section.items.length > 0);
  }, [permissions]);

  // Get default landing page for current role
  const getDefaultLanding = useCallback((): string => {
    if (!role) return '/auth/login';
    return DEFAULT_LANDING[role] ?? '/';
  }, [role]);

  const value: RBACContextValue = {
    user,
    isAuthenticated: auth.isAuthenticated,
    role,
    permissions,
    can,
    canAny,
    canAll,
    canAccessPath,
    getFilteredMenu,
    getDefaultLanding,
  };

  return <RBACContext.Provider value={value}>{children}</RBACContext.Provider>;
};

// ─── Hook for consuming context ─────────────────────────────

export const useRBAC = (): RBACContextValue => {
  const context = useContext(RBACContext);
  if (!context) {
    throw new Error('useRBAC must be used within RBACProvider');
  }
  return context;
};

// ─── Permission Gate Component ──────────────────────────────

interface PermissionGateProps {
  children: ReactNode;
  permission?: Permission;
  permissions?: Permission[];
  requireAll?: boolean;
  fallback?: ReactNode;
}

export const PermissionGate: React.FC<PermissionGateProps> = ({
  children,
  permission,
  permissions = [],
  requireAll = false,
  fallback = null,
}) => {
  const { can, canAny, canAll } = useRBAC();

  // Single permission check
  if (permission) {
    return can(permission) ? <>{children}</> : <>{fallback}</>;
  }

  // Multiple permissions
  if (permissions.length > 0) {
    const hasAccess = requireAll ? canAll(permissions) : canAny(permissions);
    return hasAccess ? <>{children}</> : <>{fallback}</>;
  }

  // No permissions specified, allow access
  return <>{children}</>;
};

// ─── Role Picker Component (Dev-only — for local testing) ───

import {
  Box, Typography, Avatar, Menu, MenuItem as MuiMenuItem, ListItemIcon,
  ListItemText, Chip, useTheme, alpha, Divider,
} from '@mui/material';
import {
  ExpandMore as ExpandIcon,
  AdminPanelSettings as AdminIcon,
  SupervisorAccount as ManagerIcon,
  PointOfSale as CashierIcon,
  LocalFlorist as DesignerIcon,
  LocalShipping as DriverIcon,
} from '@mui/icons-material';
import { ROLE_CONFIG } from './RBACTypes';
import { useState } from 'react';

const ROLE_ICONS: Record<UserRole, React.ReactNode> = {
  ADMIN: <AdminIcon />,
  MANAGER: <ManagerIcon />,
  CASHIER: <CashierIcon />,
  DESIGNER: <DesignerIcon />,
  DRIVER: <DriverIcon />,
};

/**
 * Dev-only role picker.
 * In production builds this renders nothing.
 * It does NOT grant real permissions — it only changes the
 * RBAC-level mock for UI preview purposes during development.
 */
export const RolePicker: React.FC = () => {
  // Only render in development builds
  if (!import.meta.env.DEV) return null;

  return <RolePickerInner />;
};

const RolePickerInner: React.FC = () => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';
  const { user, role } = useRBAC();
  const [anchorEl, setAnchorEl] = useState<null | HTMLElement>(null);
  const open = Boolean(anchorEl);

  const handleClick = (event: React.MouseEvent<HTMLElement>) => {
    setAnchorEl(event.currentTarget);
  };

  const handleClose = () => {
    setAnchorEl(null);
  };

  if (!role) return null;

  const config = ROLE_CONFIG[role];

  return (
    <>
      <Box
        onClick={handleClick}
        sx={{
          display: 'flex',
          alignItems: 'center',
          gap: 1,
          px: 1,
          py: 0.5,
          borderRadius: 2,
          cursor: 'pointer',
          border: '1px dashed',
          borderColor: 'warning.main',
          opacity: 0.7,
          transition: 'all 0.2s',
          '&:hover': {
            opacity: 1,
            bgcolor: dk ? 'rgba(255,255,255,0.05)' : 'rgba(0,0,0,0.04)',
          },
        }}
      >
        <Avatar
          sx={{
            width: 28,
            height: 28,
            bgcolor: alpha(config.color, 0.15),
            color: config.color,
            fontSize: '0.75rem',
            fontWeight: 700,
          }}
        >
          {user?.name?.charAt(0) ?? 'U'}
        </Avatar>
        <Typography variant="caption" sx={{ fontWeight: 600, color: 'warning.main' }}>
          DEV: {config.label}
        </Typography>
        <ExpandIcon sx={{ fontSize: 16, color: 'warning.main' }} />
      </Box>

      <Menu
        anchorEl={anchorEl}
        open={open}
        onClose={handleClose}
        anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }}
        transformOrigin={{ vertical: 'top', horizontal: 'right' }}
        slotProps={{
          paper: {
            sx: {
              mt: 1,
              minWidth: 220,
              bgcolor: dk ? '#1a1a2e' : '#fff',
              border: dk ? '1px solid rgba(255,255,255,0.1)' : 'none',
              boxShadow: dk ? '0 8px 32px rgba(0,0,0,0.4)' : '0 4px 16px rgba(0,0,0,0.15)',
            },
          },
        }}
      >
        <Box sx={{ px: 2, py: 1 }}>
          <Typography variant="caption" sx={{ fontWeight: 600, textTransform: 'uppercase', color: 'warning.main' }}>
            Dev Role Picker (read-only preview)
          </Typography>
        </Box>
        <Divider sx={{ borderColor: dk ? 'rgba(255,255,255,0.08)' : 'divider' }} />

        {(Object.keys(ROLE_CONFIG) as UserRole[]).map((r) => {
          const rc = ROLE_CONFIG[r];
          const isActive = r === role;
          return (
            <MuiMenuItem
              key={r}
              selected={isActive}
              disabled
              sx={{
                py: 1.5,
                '&.Mui-selected': {
                  bgcolor: alpha(rc.color, dk ? 0.15 : 0.08),
                },
              }}
            >
              <ListItemIcon sx={{ color: rc.color, minWidth: 36 }}>
                {ROLE_ICONS[r]}
              </ListItemIcon>
              <ListItemText
                primary={rc.label}
                secondary={rc.description}
                primaryTypographyProps={{ fontWeight: 600, fontSize: '0.875rem' }}
                secondaryTypographyProps={{ fontSize: '0.7rem' }}
              />
              {isActive && (
                <Chip
                  size="small"
                  label="Active"
                  sx={{
                    height: 20,
                    fontSize: '0.65rem',
                    bgcolor: alpha(rc.color, 0.2),
                    color: rc.color,
                  }}
                />
              )}
            </MuiMenuItem>
          );
        })}
      </Menu>
    </>
  );
};

export default RBACContext;
