/**
 * Sidebar.tsx — Collapsible Navigation Sidebar
 *
 * Features:
 * - Expandable/collapsible sections
 * - Role-based menu filtering
 * - Active state highlighting
 * - Large readable icons and text
 * - Mobile drawer mode
 */
import React, { useState } from 'react';
import {
  Box, Typography, List, ListItem, ListItemButton, ListItemIcon,
  ListItemText, Collapse, Divider, Tooltip, Badge, useTheme, alpha,
} from '@mui/material';
import {
  ExpandMore as ExpandIcon,
  ExpandLess as CollapseIcon,
  PointOfSale,
  Phone,
  CloudDownload,
  Receipt,
  LocalShipping,
  Inventory2,
  AddShoppingCart,
  Tune,
  Warning,
  Dashboard,
  TrendingUp,
  Assessment,
  History,
  NotificationsActive,
  LocalFlorist,
  People,
  Celebration,
  CreditCard,
  Lock,
  Loyalty,
  RequestQuote,
  Assignment,
  ChevronLeft as CollapseMenuIcon,
  ChevronRight as ExpandMenuIcon,
  MenuBook,
  Blender,
  AutoAwesome,
  DeleteSweep,
  CardGiftcard,
  Bolt,
  BusinessCenter,
  AccountBalance,
  Category,
  Settings,
  Store,
  AltRoute,
  Schedule as ScheduleIcon,
  AddCircleOutline,
} from '@mui/icons-material';
import { useNavigate, useLocation } from 'react-router-dom';
import { useRBAC } from '../rbac/RBACContext';
import type { MenuSection, MenuItem as MenuItemType } from '../rbac/RBACTypes';
import { useTenant } from '../tenant/TenantContext';

// ─── Icon Mapping ───────────────────────────────────────────

const ICON_MAP: Record<string, React.ReactNode> = {
  PointOfSale: <PointOfSale />,
  Phone: <Phone />,
  CloudDownload: <CloudDownload />,
  Receipt: <Receipt />,
  LocalShipping: <LocalShipping />,
  Inventory2: <Inventory2 />,
  AddShoppingCart: <AddShoppingCart />,
  Tune: <Tune />,
  Warning: <Warning />,
  Dashboard: <Dashboard />,
  TrendingUp: <TrendingUp />,
  Assessment: <Assessment />,
  History: <History />,
  NotificationsActive: <NotificationsActive />,
  LocalFlorist: <LocalFlorist />,
  People: <People />,
  Celebration: <Celebration />,
  CreditCard: <CreditCard />,
  Lock: <Lock />,
  Loyalty: <Loyalty />,
  RequestQuote: <RequestQuote />,
  Assignment: <Assignment />,
  MenuBook: <MenuBook />,
  Blender: <Blender />,
  AutoAwesome: <AutoAwesome />,
  DeleteSweep: <DeleteSweep />,
  CardGiftcard: <CardGiftcard />,
  Category: <Category />,
  Settings: <Settings />,
  Store: <Store />,
  AltRoute: <AltRoute />,
  ScheduleIcon: <ScheduleIcon />,
  AddCircleOutline: <AddCircleOutline />,
};

// ─── Section Colors ─────────────────────────────────────────

const SECTION_COLORS: Record<string, string> = {
  operations: '#2E7D32',
  'events-group': '#C62828',
  'staff-group': '#EF6C00',
  products: '#FB8C00',
  business: '#1565C0',
  'accounting-group': '#1976d2',
  'reports-group': '#6A1B9A',
  'settings-group': '#B26A00',
  sales: '#2E7D32',      // Flora Green
  orders: '#2196f3',
  inventory: '#ff9800',
  catalog: '#00bcd4',
  production: '#00897b', // Teal
  'gift-cards': '#9c27b0', // Purple accent
  accounting: '#1976d2', // Blue for accounting
  events: '#e91e63',
  staff: '#ff5722',
  crm: '#5B2E91',        // FloraPrice Purple
  reports: '#5B2E91',    // FloraPrice Purple
  settings: '#B26A00',   // High-contrast amber
  platform: '#1B5E20',   // Dark Green for Platform Admin
};

const GROUP_MAP = {
  operations: ['sales', 'orders'],
  events: ['events'],
  staff: ['staff'],
  products: ['inventory', 'catalog', 'production'],
  business: ['crm', 'ai', 'gift-cards', 'platform'],
  accounting: ['accounting'],
  reports: ['reports'],
  settings: ['settings'],
} as const;

const GROUP_ICONS: Record<'operations' | 'events' | 'staff' | 'products' | 'business' | 'accounting' | 'reports' | 'settings', React.ReactNode> = {
  operations: <Bolt sx={{ fontSize: 18 }} />,
  events: <Celebration sx={{ fontSize: 18 }} />,
  staff: <People sx={{ fontSize: 18 }} />,
  products: <Inventory2 sx={{ fontSize: 18 }} />,
  business: <BusinessCenter sx={{ fontSize: 18 }} />,
  accounting: <AccountBalance sx={{ fontSize: 18 }} />,
  reports: <Assessment sx={{ fontSize: 18 }} />,
  settings: <Settings sx={{ fontSize: 18 }} />,
};

interface GroupedMenuSection extends MenuSection {
  icon?: React.ReactNode;
}

const buildGroupedSections = (menuSections: MenuSection[]): GroupedMenuSection[] => {
  const byId = new Map(menuSections.map((s) => [s.id, s]));

  const orders = byId.get('orders');
  const accounting = byId.get('accounting');

  const wireItemIds = new Set(['wire-vendors', 'wire-settlements']);
  const businessOrderItemIds = new Set(['corporate-orders', 'corporate-auto-orders']);
  const productionReportItemIds = new Set(['production-intelligence', 'production-wastage']);
  const inventoryReportItemIds = new Set(['inventory-ledger', 'daily-inventory-report']);
  const wireItems = orders?.items.filter((i) => wireItemIds.has(i.id)) ?? [];
  const businessOrderItems = orders?.items.filter((i) => businessOrderItemIds.has(i.id)) ?? [];

  // Remove wire items from Orders so they only appear under Business/Accounting context.
  const operationsSections = GROUP_MAP.operations
    .map((id) => {
      const section = byId.get(id);
      if (!section) return undefined;
      if (id !== 'orders') return section;
      return {
        ...section,
        items: section.items.filter((i) => !wireItemIds.has(i.id) && !businessOrderItemIds.has(i.id)),
      };
    })
    .filter((s): s is MenuSection => Boolean(s));

  const eventSections = GROUP_MAP.events
    .map((id) => byId.get(id))
    .filter((s): s is MenuSection => Boolean(s));

  const staffSections = GROUP_MAP.staff
    .map((id) => byId.get(id))
    .filter((s): s is MenuSection => Boolean(s));

  const productsSections = GROUP_MAP.products
    .map((id) => {
      const section = byId.get(id);
      if (!section) return undefined;
      if (id === 'production') {
        return {
          ...section,
          items: section.items.filter((i) => !productionReportItemIds.has(i.id)),
        };
      }
      if (id === 'inventory') {
        return {
          ...section,
          items: section.items.filter((i) => !inventoryReportItemIds.has(i.id)),
        };
      }
      return {
        ...section,
        items: section.items,
      };
    })
    .filter((s): s is MenuSection => Boolean(s));

  const businessSections = GROUP_MAP.business
    .map((id) => {
      const section = byId.get(id);
      if (!section) return undefined;
      if (id === 'crm') {
        return {
          ...section,
          items: [...section.items, ...businessOrderItems],
        };
      }
      return section;
    })
    .filter((s): s is MenuSection => Boolean(s));

  const accountingSections = GROUP_MAP.accounting
    .map((id) => {
      const section = byId.get(id);
      if (!section) return undefined;
      if (id !== 'accounting' || !accounting) return section;
      return {
        ...section,
        items: [...accounting.items, ...wireItems],
      };
    })
    .filter((s): s is MenuSection => Boolean(s));

  const reportsSections = GROUP_MAP.reports
    .map((id) => byId.get(id))
    .filter((s): s is MenuSection => Boolean(s));

  const productionReportItems = byId.get('production')?.items.filter((i) => productionReportItemIds.has(i.id)) ?? [];
  const inventoryReportItems = byId.get('inventory')?.items.filter((i) => inventoryReportItemIds.has(i.id)) ?? [];

  const settingsSections = GROUP_MAP.settings
    .map((id) => byId.get(id))
    .filter((s): s is MenuSection => Boolean(s));

  return [
    {
      id: 'operations',
      title: 'OPERATIONS',
      icon: GROUP_ICONS.operations,
      items: operationsSections.flatMap((s) => s.items),
    },
    {
      id: 'products',
      title: 'PRODUCTS & STOCK',
      icon: GROUP_ICONS.products,
      items: productsSections.flatMap((s) => s.items),
    },
    {
      id: 'events-group',
      title: 'EVENTS',
      icon: GROUP_ICONS.events,
      items: eventSections.flatMap((s) => s.items),
    },
    {
      id: 'staff-group',
      title: 'STAFF',
      icon: GROUP_ICONS.staff,
      items: staffSections.flatMap((s) => s.items),
    },
    {
      id: 'business',
      title: 'BUSINESS',
      icon: GROUP_ICONS.business,
      items: businessSections.flatMap((s) => s.items),
    },
    {
      id: 'accounting-group',
      title: 'ACCOUNTING',
      icon: GROUP_ICONS.accounting,
      items: accountingSections.flatMap((s) => s.items),
    },
    {
      id: 'reports-group',
      title: 'REPORTS',
      icon: GROUP_ICONS.reports,
      items: [...reportsSections.flatMap((s) => s.items), ...productionReportItems, ...inventoryReportItems],
    },
    {
      id: 'settings-group',
      title: 'SETTINGS',
      icon: GROUP_ICONS.settings,
      items: settingsSections.flatMap((s) => s.items),
    },
  ].filter((section) => section.items.length > 0);
};

// ─── Sidebar Props ──────────────────────────────────────────

interface SidebarProps {
  collapsed?: boolean;
  onToggleCollapse?: () => void;
  /** Mobile mode (full-width drawer) */
  mobile?: boolean;
  onNavigate?: () => void;
}

// ─── Menu Item Component ────────────────────────────────────

interface MenuItemProps {
  item: MenuItemType;
  collapsed: boolean;
  sectionColor: string;
  onNavigate?: () => void;
}

const MenuItem: React.FC<MenuItemProps> = ({ item, collapsed, sectionColor, onNavigate }) => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';
  const navigate = useNavigate();
  const location = useLocation();

    const isActive = item.path
      ? location.pathname === item.path || location.pathname.startsWith(item.path + "/")
      : false;
  const icon = ICON_MAP[item.icon] ?? <Dashboard />;

  const handleClick = () => {
    if (!item.path) return;

    if (location.pathname !== item.path) {
      navigate(item.path);
    }

    onNavigate?.();
  };

  const button = (
    <ListItemButton
      onClick={handleClick}
      selected={isActive}
      sx={{
        borderRadius: 2,
        mb: 0.5,
        mx: collapsed ? 0.5 : 1,
        px: collapsed ? 1.5 : 2,
        py: 1.25,
        minHeight: 48,
        justifyContent: collapsed ? 'center' : 'flex-start',
        transition: 'all 0.2s',
        '&.Mui-selected': {
          bgcolor: alpha(sectionColor, dk ? 0.2 : 0.12),
          '&:hover': {
            bgcolor: alpha(sectionColor, dk ? 0.25 : 0.16),
          },
          '& .MuiListItemIcon-root': {
            color: sectionColor,
          },
          '& .MuiListItemText-primary': {
            color: sectionColor,
            fontWeight: 700,
          },
        },
        '&:hover': {
          bgcolor: dk ? 'rgba(255,255,255,0.05)' : 'rgba(0,0,0,0.04)',
        },
      }}
    >
      <ListItemIcon
        sx={{
          minWidth: collapsed ? 0 : 40,
          justifyContent: 'center',
          color: isActive ? sectionColor : dk ? 'rgba(255,255,255,0.7)' : 'text.secondary',
          '& svg': { fontSize: 22 },
        }}
      >
        {item.badge ? (
          <Badge
            badgeContent={item.badge}
            color="error"
            sx={{
              '& .MuiBadge-badge': {
                fontSize: '0.65rem',
                height: 16,
                minWidth: 16,
              },
            }}
          >
            {icon}
          </Badge>
        ) : (
          icon
        )}
      </ListItemIcon>
      {!collapsed && (
        <ListItemText
          primary={item.label}
          primaryTypographyProps={{
            fontWeight: isActive ? 700 : 500,
            fontSize: '0.9375rem',
          }}
        />
      )}
    </ListItemButton>
  );

  if (collapsed) {
    return (
      <Tooltip title={item.label} placement="right" arrow>
        {button}
      </Tooltip>
    );
  }

  return button;
};

// ─── Section Component ──────────────────────────────────────

interface SectionProps {
  section: GroupedMenuSection;
  collapsed: boolean;
  defaultExpanded?: boolean;
  onNavigate?: () => void;
}

const Section: React.FC<SectionProps> = ({ section, collapsed, defaultExpanded = true, onNavigate }) => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';
  const [expanded, setExpanded] = useState(defaultExpanded);

  const sectionColor = SECTION_COLORS[section.id] ?? '#fdd835';

  if (section.items.length === 0) return null;

  return (
    <Box sx={{ mb: 1 }}>
      {/* Section Header */}
      {!collapsed && (
        <ListItemButton
          onClick={() => setExpanded(!expanded)}
          sx={{
            py: 0.75,
            px: 1.5,
            mx: 1,
            borderRadius: 1.5,
            bgcolor: alpha(sectionColor, dk ? 0.3 : 0.14),
            border: `1px solid ${alpha(sectionColor, dk ? 0.55 : 0.28)}`,
            '&:hover': {
              bgcolor: alpha(sectionColor, dk ? 0.42 : 0.22),
            },
          }}
        >
          <ListItemIcon
            sx={{
              minWidth: 24,
              color: dk ? alpha('#ffffff', 0.9) : alpha(sectionColor, 0.92),
              mr: 1,
            }}
          >
            {section.icon ?? <Dashboard sx={{ fontSize: 18 }} />}
          </ListItemIcon>
          <Typography
            variant="caption"
            sx={{
              fontWeight: 700,
              textTransform: 'uppercase',
              letterSpacing: 1,
              color: dk ? alpha('#ffffff', 0.95) : alpha(sectionColor, 0.95),
              flexGrow: 1,
              fontSize: '0.7rem',
            }}
          >
            {section.title}
          </Typography>
          {expanded ? (
            <CollapseIcon sx={{ fontSize: 18, color: dk ? alpha('#ffffff', 0.9) : alpha(sectionColor, 0.9) }} />
          ) : (
            <ExpandIcon sx={{ fontSize: 18, color: dk ? alpha('#ffffff', 0.9) : alpha(sectionColor, 0.9) }} />
          )}
        </ListItemButton>
      )}

      {/* Section Items */}
        <Collapse in={collapsed ? true : expanded} timeout="auto">
        <List disablePadding>
          {section.items.map((item) => (
            <MenuItem
              key={item.id}
              item={item}
              collapsed={collapsed}
              sectionColor={sectionColor}
              onNavigate={onNavigate}
            />
          ))}
        </List>
      </Collapse>

      {!collapsed && <Divider sx={{ my: 1, mx: 2, borderColor: dk ? 'rgba(255,255,255,0.06)' : 'divider' }} />}
    </Box>
  );
};

// ─── Main Sidebar Component ─────────────────────────────────

export const Sidebar: React.FC<SidebarProps> = ({
  collapsed = false,
  onToggleCollapse,
  mobile = false,
  onNavigate,
}) => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';
  const { getFilteredMenu } = useRBAC();
  const { hasFeature } = useTenant();
  const navigate = useNavigate();
  const location = useLocation();

  const wireRoutes = new Set(['/wire-vendors', '/wire-settlements']);

  // Route-based filtering for POS/Walk-In
  const isPOS = location.pathname.startsWith('/pos') || location.pathname.startsWith('/walk-in');

  let menuSections = getFilteredMenu()
    .map((section) => ({
      ...section,
      items: section.items.filter((item) => {
        if (item.path && wireRoutes.has(item.path)) {
          return hasFeature('WIRE_MANAGEMENT');
        }
        return true;
      }),
    }))
    .filter((section) => section.items.length > 0);

  const groupedSections = buildGroupedSections(menuSections);

  return (
    <Box
      sx={{
        width: collapsed ? 72 : 260,
        height: '100%',
        display: 'flex',
        flexDirection: 'column',
        bgcolor: dk ? '#0f0f0f' : '#fff',
        borderRight: `1px solid ${dk ? 'rgba(255,255,255,0.06)' : '#e0e0e0'}`,
        transition: 'width 0.3s ease',
          willChange: 'width',
        overflow: 'hidden',
      }}
    >
      {/* Logo / Brand */}
      <Box
        sx={{
          display: 'flex',
          alignItems: 'center',
          justifyContent: collapsed ? 'center' : 'space-between',
          px: collapsed ? 1 : 2,
          py: 2,
          minHeight: 64,
          borderBottom: `1px solid ${dk ? 'rgba(255,255,255,0.06)' : '#e0e0e0'}`,
          cursor: 'pointer',
        }}
        onClick={() => navigate('/dashboard')}
      >
        {!collapsed && (
          <Box sx={{ display: 'flex', alignItems: 'center', height: 32 }}>
            <img 
              src={dk ? '/assets/logo/floraprise-logo-light.svg' : '/assets/logo/floraprise-logo.svg'}
              alt="FloraPrice"
              style={{ height: '32px', display: 'block' }}
            />
          </Box>
        )}

        {collapsed && (
          <img 
            src="/assets/logo/floraprise-icon.svg"
            alt="FloraPrice"
            style={{ height: '32px', width: '32px', display: 'block' }}
          />
        )}

        {/* Collapse Toggle (non-mobile only) */}
        {!mobile && onToggleCollapse && (
          <Tooltip title={collapsed ? 'Expand Menu' : 'Collapse Menu'} placement="right">
            <ListItemButton
              onClick={onToggleCollapse}
              sx={{
                width: 32,
                height: 32,
                minWidth: 32,
                borderRadius: '50%',
                display: 'flex',
                justifyContent: 'center',
                alignItems: 'center',
                bgcolor: dk ? 'rgba(255,255,255,0.05)' : 'rgba(0,0,0,0.04)',
                '&:hover': {
                  bgcolor: dk ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.08)',
                },
              }}
            >
              {collapsed ? (
                <ExpandMenuIcon sx={{ fontSize: 18 }} />
              ) : (
                <CollapseMenuIcon sx={{ fontSize: 18 }} />
              )}
            </ListItemButton>
          </Tooltip>
        )}
      </Box>

      {/* Menu Sections */}
      <Box
        sx={{
          flexGrow: 1,
          overflowY: 'auto',
          overflowX: 'hidden',
          py: 1,
          '&::-webkit-scrollbar': {
            width: 6,
          },
          '&::-webkit-scrollbar-thumb': {
            bgcolor: dk ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.1)',
            borderRadius: 3,
          },
        }}
      >
        {groupedSections.map((section, index) => (
          <Section
            key={section.id}
            section={section}
            collapsed={collapsed}
            defaultExpanded={index === 0} // OPERATIONS expanded by default
            onNavigate={onNavigate}
          />
        ))}
      </Box>

      {/* Footer */}
      {!collapsed && (
        <Box
          sx={{
            p: 2,
            borderTop: `1px solid ${dk ? 'rgba(255,255,255,0.06)' : '#e0e0e0'}`,
          }}
        >
          <Typography
            variant="caption"
            sx={{
              color: dk ? 'rgba(255,255,255,0.3)' : 'text.disabled',
              display: 'block',
              textAlign: 'center',
            }}
          >
            v1.0.0 • FloraPrice
          </Typography>
        </Box>
      )}
    </Box>
  );
};

export default Sidebar;
