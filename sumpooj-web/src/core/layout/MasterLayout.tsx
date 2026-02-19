/**
 * MasterLayout.tsx — Production SaaS App Shell
 *
 * Features:
 * - Header with search, role picker, notifications
 * - Collapsible sidebar navigation
 * - Mobile-responsive drawer
 * - Quick action button overlay
 * - Confirmation provider integration
 */
import React, { useState, Component, type ErrorInfo, type ReactNode as EBReactNode } from 'react';
import {
  Box, AppBar, Toolbar, Typography, IconButton, Avatar, Badge,
  Drawer, useTheme, useMediaQuery, Tooltip, Menu, MenuItem,
  Divider, alpha, ListItemIcon, ListItemText,
} from '@mui/material';

// ─── Error Boundary ─────────────────────────────────────────
class RouteErrorBoundary extends Component<
  { children: EBReactNode },
  { hasError: boolean; error: Error | null }
> {
  constructor(props: { children: EBReactNode }) {
    super(props);
    this.state = { hasError: false, error: null };
  }
  static getDerivedStateFromError(error: Error) {
    return { hasError: true, error };
  }
  componentDidCatch(error: Error, info: ErrorInfo) {
    console.error('[RouteErrorBoundary]', error, info.componentStack);
  }
  render() {
    if (this.state.hasError) {
      return (
        <Box sx={{ p: 4, color: '#ff5252' }}>
          <Typography variant="h5" sx={{ fontWeight: 700 }}>Something went wrong</Typography>
          <Typography variant="body1" sx={{ mt: 1, fontFamily: 'monospace', whiteSpace: 'pre-wrap' }}>
            {this.state.error?.message}
          </Typography>
          <Typography variant="body2" sx={{ mt: 2, color: 'text.secondary' }}>
            Check the browser console (F12) for details.
          </Typography>
        </Box>
      );
    }
    return this.props.children;
  }
}
import {
  Menu as MenuIcon,
  Notifications,
  Help,
  Settings,
  Logout,
  Person,
  DarkMode,
  LightMode,
  LocalFlorist,
} from '@mui/icons-material';
import { Outlet, useNavigate } from 'react-router-dom';
import { useAuth } from '../../auth/AuthContext';
import { Sidebar } from './Sidebar';
import { GlobalSearchDialog } from './GlobalSearch';
import { QuickActionButton } from './QuickActionButton';
import { RolePicker, useRBAC } from '../rbac/RBACContext';
import { ConfirmationProvider } from '../ux/ConfirmationModal';
import { ROLE_CONFIG } from '../rbac/RBACTypes';
import { LocationProvider } from '../location/LocationContext';
import { LocationSwitcher } from '../location/LocationSwitcher';
import {
  TenantProvider,
  TrialBanner,
  PastDueBanner,
  UpgradePromptModal,
} from '../tenant';
import { SensitiveActionProvider } from '../audit';

// ─── Header Props ───────────────────────────────────────────

interface HeaderProps {
  onMenuClick: () => void;
  showMenuButton?: boolean;
}

const Header: React.FC<HeaderProps> = ({ onMenuClick, showMenuButton = true }) => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';
  const { user } = useRBAC();
  const auth = useAuth();
  const navigate = useNavigate();
  const [userMenuAnchor, setUserMenuAnchor] = useState<null | HTMLElement>(null);

  // Fallback for when user is null
  if (!user) return null;

  const roleConfig = ROLE_CONFIG[user.role];

  return (
    <AppBar
      position="fixed"
      elevation={0}
      sx={{
        bgcolor: dk ? '#0a0a0a' : '#fff',
        borderBottom: `1px solid ${dk ? 'rgba(255,255,255,0.06)' : '#e0e0e0'}`,
        color: dk ? '#fff' : 'text.primary',
        zIndex: theme.zIndex.drawer + 1,
      }}
    >
      <Toolbar sx={{ gap: 1, minHeight: { xs: 56, sm: 64 } }}>
        {/* Menu Button (mobile) */}
        {showMenuButton && (
          <IconButton
            onClick={onMenuClick}
            edge="start"
            sx={{
              mr: 1,
              display: { md: 'none' },
            }}
          >
            <MenuIcon />
          </IconButton>
        )}

        {/* Mobile Logo */}
        <Box 
          sx={{ display: { xs: 'flex', md: 'none' }, alignItems: 'center', cursor: 'pointer' }}
          onClick={() => window.location.href = '/dashboard'}
        >
          <img 
            src="/assets/logo/floraedge-icon.svg"
            alt="FloraEdge"
            style={{ height: '28px', width: '28px' }}
          />
        </Box>

        {/* Global Search (in header) */}
        <Box sx={{ flexGrow: 1, display: 'flex', justifyContent: { xs: 'flex-end', md: 'flex-start' } }}>
          <GlobalSearchDialog />
        </Box>

        {/* Location Switcher */}
        <Box sx={{ display: { xs: 'none', sm: 'block' }, mr: 1 }}>
          <LocationSwitcher />
        </Box>

        {/* Role Picker (Demo/Dev) */}
        <Box sx={{ display: { xs: 'none', sm: 'block' } }}>
          <RolePicker />
        </Box>

        {/* Notifications */}
        <Tooltip title="Alerts & Notifications">
          <IconButton>
            <Badge badgeContent={3} color="error">
              <Notifications />
            </Badge>
          </IconButton>
        </Tooltip>

        {/* Help */}
        <Tooltip title="Help & Support">
          <IconButton sx={{ display: { xs: 'none', sm: 'flex' } }}>
            <Help />
          </IconButton>
        </Tooltip>

        {/* User Avatar Menu */}
        <Tooltip title={`${user.name} (${roleConfig.label})`}>
          <IconButton
            onClick={(e) => setUserMenuAnchor(e.currentTarget)}
            sx={{ p: 0.5 }}
          >
            <Avatar
              sx={{
                width: 36,
                height: 36,
                bgcolor: roleConfig.color,
                fontSize: '0.875rem',
                fontWeight: 700,
              }}
            >
              {user.name.split(' ').map((n) => n[0]).join('')}
            </Avatar>
          </IconButton>
        </Tooltip>

        {/* User Dropdown Menu */}
        <Menu
          anchorEl={userMenuAnchor}
          open={Boolean(userMenuAnchor)}
          onClose={() => setUserMenuAnchor(null)}
          transformOrigin={{ horizontal: 'right', vertical: 'top' }}
          anchorOrigin={{ horizontal: 'right', vertical: 'bottom' }}
          PaperProps={{
            sx: {
              mt: 1,
              minWidth: 200,
              bgcolor: dk ? '#1a1a2e' : '#fff',
              border: `1px solid ${dk ? 'rgba(255,255,255,0.08)' : '#e0e0e0'}`,
            },
          }}
        >
          {/* User Info */}
          <Box sx={{ px: 2, py: 1.5 }}>
            <Typography variant="subtitle2" sx={{ fontWeight: 700 }}>
              {user.name}
            </Typography>
            <Typography variant="caption" sx={{ color: roleConfig.color }}>
              {roleConfig.label}
            </Typography>
          </Box>
          <Divider />

          <MenuItem onClick={() => setUserMenuAnchor(null)}>
            <ListItemIcon><Person fontSize="small" /></ListItemIcon>
            <ListItemText>Profile</ListItemText>
          </MenuItem>

          <MenuItem onClick={() => setUserMenuAnchor(null)}>
            <ListItemIcon><Settings fontSize="small" /></ListItemIcon>
            <ListItemText>Settings</ListItemText>
          </MenuItem>

          <MenuItem onClick={() => setUserMenuAnchor(null)}>
            <ListItemIcon>{dk ? <LightMode fontSize="small" /> : <DarkMode fontSize="small" />}</ListItemIcon>
            <ListItemText>{dk ? 'Light Mode' : 'Dark Mode'}</ListItemText>
          </MenuItem>

          <Divider />

          <MenuItem
            onClick={() => {
              setUserMenuAnchor(null);
              auth.logout();
              navigate('/auth/login');
            }}
            sx={{ color: 'error.main' }}
          >
            <ListItemIcon><Logout fontSize="small" sx={{ color: 'error.main' }} /></ListItemIcon>
            <ListItemText>Sign Out</ListItemText>
          </MenuItem>
        </Menu>
      </Toolbar>
    </AppBar>
  );
};

// ─── Main Layout Component ──────────────────────────────────

export const MasterLayout: React.FC = () => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';
  const isMobile = useMediaQuery(theme.breakpoints.down('md'));

  const [mobileOpen, setMobileOpen] = useState(false);
  const [sidebarCollapsed, setSidebarCollapsed] = useState(false);

  const sidebarWidth = sidebarCollapsed ? 72 : 260;

  return (
    <TenantProvider>
      <LocationProvider>
        <ConfirmationProvider>
          <SensitiveActionProvider>
            <Box sx={{ display: 'flex', flexDirection: 'column', minHeight: '100vh', bgcolor: dk ? '#0f0f0f' : '#f5f5f5' }}>
              {/* Subscription Banners */}
              <TrialBanner />
              <PastDueBanner />
              
              <Box sx={{ display: 'flex', flex: 1 }}>
                {/* Header */}
                <Header
                  onMenuClick={() => setMobileOpen(true)}
                  showMenuButton={isMobile}
                />

              {/* Desktop Sidebar */}
              {!isMobile && (
                <Box
                  component="nav"
                  sx={{
                    width: sidebarWidth,
                    flexShrink: 0,
                    transition: 'width 0.3s ease',
                  }}
                >
                  <Box sx={{ position: 'fixed', top: 64, height: 'calc(100vh - 64px)' }}>
                    <Sidebar
                      collapsed={sidebarCollapsed}
                      onToggleCollapse={() => setSidebarCollapsed(!sidebarCollapsed)}
                    />
                  </Box>
                </Box>
              )}

              {/* Mobile Drawer */}
              <Drawer
                variant="temporary"
                open={mobileOpen}
                onClose={() => setMobileOpen(false)}
                ModalProps={{ keepMounted: true }}
                sx={{
                  display: { xs: 'block', md: 'none' },
                  '& .MuiDrawer-paper': {
                    width: 280,
                    bgcolor: dk ? '#0f0f0f' : '#fff',
                  },
                }}
              >
                <Box sx={{ height: 64 }} /> {/* Spacer for header */}
                <Sidebar mobile onNavigate={() => setMobileOpen(false)} />
              </Drawer>

              {/* Main Content */}
              <Box
                component="main"
                sx={{
                  flexGrow: 1,
                  pt: { xs: 7, sm: 8 }, // Header offset
                  pb: 10, // FAB offset
                  px: { xs: 2, sm: 3 },
                  minHeight: '100vh',
                  overflow: 'auto',
                }}
              >
                <RouteErrorBoundary>
                  <Outlet />
                </RouteErrorBoundary>
              </Box>

              {/* Quick Action FAB */}
              <QuickActionButton />
            </Box>
            
            {/* Upgrade Prompt Modal */}
            <UpgradePromptModal />
          </Box>
          </SensitiveActionProvider>
        </ConfirmationProvider>
      </LocationProvider>
    </TenantProvider>
  );
};

// ─── Simple Page Wrapper ────────────────────────────────────

interface PageWrapperProps {
  title?: string;
  subtitle?: string;
  children: React.ReactNode;
  actions?: React.ReactNode;
}

export const PageWrapper: React.FC<PageWrapperProps> = ({ title, subtitle, children, actions }) => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';

  return (
    <Box sx={{ maxWidth: 1600, mx: 'auto' }}>
      {/* Page Header */}
      {(title || actions) && (
        <Box
          sx={{
            display: 'flex',
            alignItems: 'flex-start',
            justifyContent: 'space-between',
            flexWrap: 'wrap',
            gap: 2,
            mb: 3,
          }}
        >
          <Box>
            {title && (
              <Typography variant="h5" sx={{ fontWeight: 800 }}>
                {title}
              </Typography>
            )}
            {subtitle && (
              <Typography variant="body2" sx={{ color: dk ? 'rgba(255,255,255,0.5)' : 'text.secondary', mt: 0.5 }}>
                {subtitle}
              </Typography>
            )}
          </Box>
          {actions && <Box sx={{ display: 'flex', gap: 1, flexWrap: 'wrap' }}>{actions}</Box>}
        </Box>
      )}

      {/* Page Content */}
      {children}
    </Box>
  );
};

// ─── Content Card ───────────────────────────────────────────

interface ContentCardProps {
  title?: string;
  children: React.ReactNode;
  actions?: React.ReactNode;
  noPadding?: boolean;
}

export const ContentCard: React.FC<ContentCardProps> = ({ title, children, actions, noPadding }) => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';

  return (
    <Box
      sx={{
        bgcolor: dk ? '#1a1a2e' : '#fff',
        borderRadius: 3,
        border: `1px solid ${dk ? 'rgba(255,255,255,0.06)' : '#e0e0e0'}`,
        overflow: 'hidden',
      }}
    >
      {/* Card Header */}
      {(title || actions) && (
        <Box
          sx={{
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
            px: 3,
            py: 2,
            borderBottom: `1px solid ${dk ? 'rgba(255,255,255,0.06)' : '#e0e0e0'}`,
          }}
        >
          {title && (
            <Typography variant="subtitle1" sx={{ fontWeight: 700 }}>
              {title}
            </Typography>
          )}
          {actions && <Box>{actions}</Box>}
        </Box>
      )}

      {/* Card Content */}
      <Box sx={{ p: noPadding ? 0 : 3 }}>{children}</Box>
    </Box>
  );
};

export default MasterLayout;
