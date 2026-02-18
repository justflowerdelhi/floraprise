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
  ChevronLeft as CollapseMenuIcon,
  ChevronRight as ExpandMenuIcon,
} from '@mui/icons-material';
import { useNavigate, useLocation } from 'react-router-dom';
import { useRBAC } from '../rbac/RBACContext';
import type { MenuSection, MenuItem as MenuItemType } from '../rbac/RBACTypes';

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
};

// ─── Section Colors ─────────────────────────────────────────

const SECTION_COLORS: Record<string, string> = {
  sales: '#2E7D32',      // Flora Green
  orders: '#2196f3',
  events: '#e91e63',
  inventory: '#ff9800',
  reports: '#5B2E91',    // FloraEdge Purple
  catalog: '#00bcd4',
  crm: '#5B2E91',        // FloraEdge Purple
  staff: '#ff5722',
  settings: '#F4C430',   // Accent Yellow
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

  const isActive = item.path ? location.pathname === item.path : false;
  const icon = ICON_MAP[item.icon] ?? <Dashboard />;

  const handleClick = () => {
    if (item.path) {
      navigate(item.path);
      onNavigate?.();
    }
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
  section: MenuSection;
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
            px: 2,
            borderRadius: 0,
            '&:hover': {
              bgcolor: 'transparent',
            },
          }}
        >
          <Typography
            variant="caption"
            sx={{
              fontWeight: 700,
              textTransform: 'uppercase',
              letterSpacing: 1,
              color: dk ? 'rgba(255,255,255,0.4)' : 'text.disabled',
              flexGrow: 1,
              fontSize: '0.7rem',
            }}
          >
            {section.title}
          </Typography>
          {expanded ? (
            <CollapseIcon sx={{ fontSize: 18, color: dk ? 'rgba(255,255,255,0.3)' : 'text.disabled' }} />
          ) : (
            <ExpandIcon sx={{ fontSize: 18, color: dk ? 'rgba(255,255,255,0.3)' : 'text.disabled' }} />
          )}
        </ListItemButton>
      )}

      {/* Section Items */}
      <Collapse in={expanded || collapsed} timeout="auto" unmountOnExit={false}>
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

  const menuSections = getFilteredMenu();

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
        onClick={() => window.location.href = '/dashboard'}
      >
        {!collapsed && (
          <Box sx={{ display: 'flex', alignItems: 'center', height: 32 }}>
            <img 
              src={dk ? '/assets/logo/floraedge-logo-light.svg' : '/assets/logo/floraedge-logo.svg'}
              alt="FloraEdge"
              style={{ height: '32px', display: 'block' }}
            />
          </Box>
        )}

        {collapsed && (
          <img 
            src="/assets/logo/floraedge-icon.svg"
            alt="FloraEdge"
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
        {menuSections.map((section, index) => (
          <Section
            key={section.id}
            section={section}
            collapsed={collapsed}
            defaultExpanded={index < 2} // First two sections expanded by default
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
            v1.0.0 • FloraEdge
          </Typography>
        </Box>
      )}
    </Box>
  );
};

export default Sidebar;
