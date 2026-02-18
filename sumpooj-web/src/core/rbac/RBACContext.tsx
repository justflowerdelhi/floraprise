/**
 * RBACContext.tsx — Role-Based Access Control Provider
 *
 * Provides:
 * - Current user state with role
 * - Permission checking hooks
 * - Mock role simulation for development
 * - Route protection utilities
 */
import React, { createContext, useContext, useState, useCallback, useMemo, type ReactNode } from 'react';
import type { User, UserRole, Permission, MenuItem, MenuSection } from './RBACTypes';
import {
  ROLE_PERMISSIONS,
  MENU_SECTIONS,
  DEFAULT_LANDING,
  hasPermission,
  hasAllPermissions,
  canAccessRoute,
} from './RBACTypes';

// ─── Context Types ──────────────────────────────────────────

interface RBACContextValue {
  // User state
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

  // Actions
  login: (user: User) => void;
  logout: () => void;
  switchRole: (role: UserRole) => void; // Dev/demo only
}

// ─── Mock Users for Development ─────────────────────────────

const MOCK_USERS: Record<UserRole, User> = {
  ADMIN: {
    id: 'user-admin',
    name: 'Raj Kumar',
    email: 'raj@florist.com',
    role: 'ADMIN',
    avatar: undefined,
    primaryLocationId: 'loc-001',
    assignedLocationIds: ['loc-001', 'loc-002', 'loc-003', 'loc-004'], // All locations
  },
  MANAGER: {
    id: 'user-manager',
    name: 'Priya Sharma',
    email: 'priya@florist.com',
    role: 'MANAGER',
    avatar: undefined,
    primaryLocationId: 'loc-001',
    assignedLocationIds: ['loc-001', 'loc-002'], // Bandra & Andheri
  },
  CASHIER: {
    id: 'user-cashier',
    name: 'Amit Singh',
    email: 'amit@florist.com',
    role: 'CASHIER',
    avatar: undefined,
    primaryLocationId: 'loc-001',
    assignedLocationIds: ['loc-001'], // Bandra only
  },
  DESIGNER: {
    id: 'user-designer',
    name: 'Meera Patel',
    email: 'meera@florist.com',
    role: 'DESIGNER',
    avatar: undefined,
    primaryLocationId: 'loc-001',
    assignedLocationIds: ['loc-001'], // Bandra only
  },
  DRIVER: {
    id: 'user-driver',
    name: 'Ravi Kumar',
    email: 'ravi@florist.com',
    role: 'DRIVER',
    avatar: undefined,
    primaryLocationId: 'loc-001',
    assignedLocationIds: ['loc-001', 'loc-002'], // Bandra & Andheri routes
  },
};

// ─── Context Creation ───────────────────────────────────────

const RBACContext = createContext<RBACContextValue | null>(null);

// ─── Provider Component ─────────────────────────────────────

interface RBACProviderProps {
  children: ReactNode;
  initialRole?: UserRole;
}

export const RBACProvider: React.FC<RBACProviderProps> = ({
  children,
  initialRole = 'ADMIN',
}) => {
  // Start with mock user in development
  const [user, setUser] = useState<User | null>(() => MOCK_USERS[initialRole]);

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

  // Login action
  const login = useCallback((newUser: User) => {
    setUser(newUser);
    // In real app: store token, sync with backend
  }, []);

  // Logout action
  const logout = useCallback(() => {
    setUser(null);
    // In real app: clear token, redirect
  }, []);

  // Switch role (development/demo only)
  const switchRole = useCallback((newRole: UserRole) => {
    setUser(MOCK_USERS[newRole]);
  }, []);

  const value: RBACContextValue = {
    user,
    isAuthenticated: user !== null,
    role,
    permissions,
    can,
    canAny,
    canAll,
    canAccessPath,
    getFilteredMenu,
    getDefaultLanding,
    login,
    logout,
    switchRole,
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

// ─── Role Picker Component (Dev/Demo only) ──────────────────

import {
  Box, Typography, Avatar, Menu, MenuItem as MuiMenuItem, ListItemIcon,
  ListItemText, Chip, useTheme, alpha, IconButton, Divider,
} from '@mui/material';
import {
  Person as PersonIcon,
  ExpandMore as ExpandIcon,
  AdminPanelSettings as AdminIcon,
  SupervisorAccount as ManagerIcon,
  PointOfSale as CashierIcon,
  LocalFlorist as DesignerIcon,
  LocalShipping as DriverIcon,
} from '@mui/icons-material';
import { ROLE_CONFIG } from './RBACTypes';

const ROLE_ICONS: Record<UserRole, React.ReactNode> = {
  ADMIN: <AdminIcon />,
  MANAGER: <ManagerIcon />,
  CASHIER: <CashierIcon />,
  DESIGNER: <DesignerIcon />,
  DRIVER: <DriverIcon />,
};

export const RolePicker: React.FC = () => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';
  const { user, role, switchRole } = useRBAC();
  const [anchorEl, setAnchorEl] = useState<null | HTMLElement>(null);
  const open = Boolean(anchorEl);

  const handleClick = (event: React.MouseEvent<HTMLElement>) => {
    setAnchorEl(event.currentTarget);
  };

  const handleClose = () => {
    setAnchorEl(null);
  };

  const handleSelectRole = (newRole: UserRole) => {
    switchRole(newRole);
    handleClose();
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
          gap: 1.5,
          px: 1.5,
          py: 1,
          borderRadius: 2,
          cursor: 'pointer',
          transition: 'all 0.2s',
          '&:hover': {
            bgcolor: dk ? 'rgba(255,255,255,0.05)' : 'rgba(0,0,0,0.04)',
          },
        }}
      >
        <Avatar
          sx={{
            width: 36,
            height: 36,
            bgcolor: alpha(config.color, 0.15),
            color: config.color,
            fontSize: '0.9rem',
            fontWeight: 700,
          }}
        >
          {user?.name?.charAt(0) ?? 'U'}
        </Avatar>
        <Box sx={{ display: { xs: 'none', md: 'block' }, minWidth: 100 }}>
          <Typography variant="subtitle2" sx={{ fontWeight: 600, lineHeight: 1.2 }}>
            {user?.name}
          </Typography>
          <Chip
            size="small"
            label={config.label}
            sx={{
              height: 18,
              fontSize: '0.65rem',
              fontWeight: 600,
              bgcolor: alpha(config.color, 0.15),
              color: config.color,
              mt: 0.25,
            }}
          />
        </Box>
        <ExpandIcon
          sx={{
            fontSize: 20,
            color: dk ? 'rgba(255,255,255,0.5)' : 'text.secondary',
            transition: 'transform 0.2s',
            transform: open ? 'rotate(180deg)' : 'rotate(0deg)',
          }}
        />
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
          <Typography variant="caption" sx={{ fontWeight: 600, textTransform: 'uppercase', color: dk ? 'rgba(255,255,255,0.5)' : 'text.secondary' }}>
            Switch Role (Demo)
          </Typography>
        </Box>
        <Divider sx={{ borderColor: dk ? 'rgba(255,255,255,0.08)' : 'divider' }} />

        {(Object.keys(ROLE_CONFIG) as UserRole[]).map((r) => {
          const rc = ROLE_CONFIG[r];
          const isActive = r === role;
          return (
            <MuiMenuItem
              key={r}
              onClick={() => handleSelectRole(r)}
              selected={isActive}
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
