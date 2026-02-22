/**
 * HomeDashboard.tsx — FloraEdge Control Center
 *
 * Main landing page after login.
 * Top KPI strip + responsive grid of feature tiles.
 * Loads user dashboard preferences from API and allows customization.
 */
import React, { useState, useEffect, useCallback, useMemo } from 'react';
import { useNavigate } from 'react-router-dom';
import { IconButton, Tooltip, CircularProgress, Snackbar, Alert } from '@mui/material';
import {
  PointOfSale as POSIcon,
  ShoppingCart as OrdersIcon,
  Inventory2 as InventoryIcon,
  People as CRMIcon,
  LocalFlorist as ProductionIcon,
  Event as EventsIcon,
  Payment as PaymentsIcon,
  BarChart as ReportsIcon,
  Settings as SettingsIcon,
  TrendingUp,
  PendingActions,
  WarningAmber,
  AccessTime,
  Celebration,
  Tune as CustomizeIcon,
} from '@mui/icons-material';
import CustomizeDashboardDrawer, { type ModuleItem } from './CustomizeDashboardDrawer';
import {
  getDashboardPreference,
  saveDashboardPreference,
} from '../../api/dashboard-preference.api';

// ─── KPI Data ───────────────────────────────────────────────

interface KpiItem {
  label: string;
  value: string;
  subtext?: string;
  icon: React.ReactNode;
  color: string;          // tailwind text color for the icon bg
  bgColor: string;        // tailwind bg for the icon circle
}

const KPI_ITEMS: KpiItem[] = [
  {
    label: 'Today Sales',
    value: '$0.00',
    subtext: '0 transactions',
    icon: <TrendingUp className="w-5 h-5" />,
    color: 'text-green-600',
    bgColor: 'bg-green-50',
  },
  {
    label: 'Pending Orders',
    value: '0',
    subtext: 'Needs attention',
    icon: <PendingActions className="w-5 h-5" />,
    color: 'text-orange-600',
    bgColor: 'bg-orange-50',
  },
  {
    label: 'Low Stock Items',
    value: '0',
    subtext: 'Below threshold',
    icon: <WarningAmber className="w-5 h-5" />,
    color: 'text-red-600',
    bgColor: 'bg-red-50',
  },
  {
    label: 'Active Shift',
    value: 'No Shift',
    subtext: 'Tap POS to open',
    icon: <AccessTime className="w-5 h-5" />,
    color: 'text-purple-600',
    bgColor: 'bg-purple-50',
  },
  {
    label: 'Upcoming Events',
    value: '0',
    subtext: 'Next 7 days',
    icon: <Celebration className="w-5 h-5" />,
    color: 'text-blue-600',
    bgColor: 'bg-blue-50',
  },
];

// ─── Feature Tiles ──────────────────────────────────────────

interface FeatureTile {
  key: string;
  title: string;
  icon: React.ReactNode;
  route: string;
  color: string;
  badge?: string | null;
  description: string;
}

const FEATURE_TILES: FeatureTile[] = [
  { key: 'POS', title: 'POS', description: 'Point of Sale', icon: <POSIcon sx={{ fontSize: 36 }} />, route: '/pos', color: 'from-purple-600 to-purple-700', badge: null },
  { key: 'Orders', title: 'Orders', description: 'Manage orders', icon: <OrdersIcon sx={{ fontSize: 36 }} />, route: '/order-list', color: 'from-indigo-500 to-indigo-600', badge: null },
  { key: 'Inventory', title: 'Inventory', description: 'Stock & batches', icon: <InventoryIcon sx={{ fontSize: 36 }} />, route: '/inventory', color: 'from-emerald-500 to-emerald-600', badge: null },
  { key: 'CRM', title: 'CRM', description: 'Customer intelligence', icon: <CRMIcon sx={{ fontSize: 36 }} />, route: '/crm/customers', color: 'from-sky-500 to-sky-600', badge: null },
  { key: 'Production', title: 'Production', description: 'Floral recipes & build', icon: <ProductionIcon sx={{ fontSize: 36 }} />, route: '/production/recipes', color: 'from-pink-500 to-pink-600', badge: null },
  { key: 'Events', title: 'Events', description: 'Weddings & events', icon: <EventsIcon sx={{ fontSize: 36 }} />, route: '/events', color: 'from-amber-500 to-amber-600', badge: null },
  { key: 'Payments', title: 'Payments', description: 'Day close & shifts', icon: <PaymentsIcon sx={{ fontSize: 36 }} />, route: '/day-close', color: 'from-teal-500 to-teal-600', badge: null },
  { key: 'Reports', title: 'Reports', description: 'Profit & analytics', icon: <ReportsIcon sx={{ fontSize: 36 }} />, route: '/profit-intelligence', color: 'from-cyan-600 to-cyan-700', badge: null },
  { key: 'Settings', title: 'Settings', description: 'Store configuration', icon: <SettingsIcon sx={{ fontSize: 36 }} />, route: '/settings/tenant', color: 'from-gray-500 to-gray-600', badge: null },
];

/** Lookup map: key → tile definition */
const TILE_MAP = new Map(FEATURE_TILES.map((t) => [t.key, t]));

/** Default module keys (all visible, default order) */
const DEFAULT_KEYS = FEATURE_TILES.map((t) => t.key);

// ─── Component ──────────────────────────────────────────────

const HomeDashboard: React.FC = () => {
  const navigate = useNavigate();

  // ── Single source of truth: ordered module list with visibility ──
  const [modules, setModules] = useState<ModuleItem[]>(
    DEFAULT_KEYS.map((k) => ({ key: k, visible: true })),
  );
  const [prefLoading, setPrefLoading] = useState(true);
  const [drawerOpen, setDrawerOpen] = useState(false);
  const [saving, setSaving] = useState(false);
  const [errorMsg, setErrorMsg] = useState('');

  // Load preferences on mount
  useEffect(() => {
    let cancelled = false;
    (async () => {
      try {
        const pref = await getDashboardPreference();
        if (cancelled) return;
        if (!pref.isDefault && pref.moduleOrder.length > 0) {
          const visSet = new Set(pref.visibleModules);
          // Merge: keep any new modules the server doesn't know about
          const serverOrder = pref.moduleOrder.filter((k) => TILE_MAP.has(k));
          const missing = DEFAULT_KEYS.filter((k) => !serverOrder.includes(k));
          const allKeys = [...serverOrder, ...missing];
          setModules(allKeys.map((k) => ({ key: k, visible: visSet.has(k) })));
        }
      } catch {
        // Use defaults silently
      } finally {
        if (!cancelled) setPrefLoading(false);
      }
    })();
    return () => { cancelled = true; };
  }, []);

  // Derive visible tiles for rendering
  const displayTiles = useMemo(() => {
    return modules
      .filter((m) => m.visible)
      .map((m) => TILE_MAP.get(m.key)!)
      .filter(Boolean);
  }, [modules]);

  // Save handler — updates local state immediately on success
  const handleSave = useCallback(async (updated: ModuleItem[]) => {
    setSaving(true);
    try {
      const vis = updated.filter((m) => m.visible).map((m) => m.key);
      const ord = updated.map((m) => m.key);
      await saveDashboardPreference({ visibleModules: vis, moduleOrder: ord });
      // Apply to local state immediately — no reload needed
      setModules(updated);
      setDrawerOpen(false);
    } catch (err) {
      console.error('Failed to save dashboard preference:', err);
      setErrorMsg('Failed to save preferences. Please try again.');
    } finally {
      setSaving(false);
    }
  }, []);

  return (
    <div className="min-h-full bg-gray-50 p-4 sm:p-6 lg:p-8">
      {/* ── Header ─────────────────────────────────── */}
      <div className="flex items-start justify-between mb-6">
        <div>
          <h1 className="text-2xl sm:text-3xl font-bold text-gray-900">
            Control Center
          </h1>
          <p className="text-sm text-gray-500 mt-1">
            FloraEdge — your business at a glance
          </p>
        </div>
        <Tooltip title="Customize Dashboard">
          <IconButton
            onClick={() => setDrawerOpen(true)}
            sx={{
              bgcolor: 'white',
              border: '1px solid',
              borderColor: 'divider',
              '&:hover': { bgcolor: 'action.hover' },
            }}
          >
            <CustomizeIcon />
          </IconButton>
        </Tooltip>
      </div>

      {/* ── KPI Strip ──────────────────────────────── */}
      <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-5 gap-3 sm:gap-4 mb-8">
        {KPI_ITEMS.map((kpi) => (
          <div
            key={kpi.label}
            className="bg-white rounded-xl border border-gray-200 p-4 flex items-start gap-3
                       shadow-sm hover:shadow-md transition-shadow"
          >
            {/* Icon circle */}
            <div
              className={`shrink-0 w-10 h-10 rounded-lg flex items-center justify-center ${kpi.bgColor} ${kpi.color}`}
            >
              {kpi.icon}
            </div>

            {/* Text */}
            <div className="min-w-0">
              <p className="text-xs text-gray-500 uppercase tracking-wide leading-tight truncate">
                {kpi.label}
              </p>
              <p className="text-lg font-bold text-gray-900 leading-tight mt-0.5">
                {kpi.value}
              </p>
              {kpi.subtext && (
                <p className="text-[11px] text-gray-400 leading-tight mt-0.5 truncate">
                  {kpi.subtext}
                </p>
              )}
            </div>
          </div>
        ))}
      </div>

      {/* ── Feature Tiles ──────────────────────────── */}
      {prefLoading ? (
        <div className="flex items-center justify-center py-16">
          <CircularProgress size={32} />
        </div>
      ) : (
      <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5 gap-4 sm:gap-5">
        {displayTiles.map((tile) => (
          <button
            key={tile.key}
            onClick={() => navigate(tile.route)}
            className="group relative bg-white rounded-2xl border border-gray-200 p-5 sm:p-6
                       flex flex-col items-center text-center
                       shadow-sm hover:shadow-lg active:scale-[0.97]
                       transition-all duration-200 ease-out
                       min-h-[140px] sm:min-h-[160px]
                       touch-manipulation cursor-pointer
                       focus:outline-none focus:ring-2 focus:ring-purple-400 focus:ring-offset-2"
          >
            {/* Badge */}
            {tile.badge && (
              <span
                className="absolute top-2.5 right-2.5 bg-red-500 text-white text-[10px] font-bold
                           leading-none px-1.5 py-0.5 rounded-full min-w-[18px] text-center"
              >
                {tile.badge}
              </span>
            )}

            {/* Icon Container */}
            <div
              className={`w-14 h-14 sm:w-16 sm:h-16 rounded-2xl bg-gradient-to-br ${tile.color}
                          flex items-center justify-center text-white mb-3 sm:mb-4
                          group-hover:scale-110 transition-transform duration-200`}
            >
              {tile.icon}
            </div>

            {/* Title */}
            <span className="text-sm sm:text-base font-semibold text-gray-900 leading-tight">
              {tile.title}
            </span>

            {/* Description */}
            <span className="text-[11px] sm:text-xs text-gray-400 mt-1 leading-tight">
              {tile.description}
            </span>
          </button>
        ))}
      </div>
      )}

      {/* ── Customize Drawer ───────────────────────── */}
      <CustomizeDashboardDrawer
        open={drawerOpen}
        onClose={() => setDrawerOpen(false)}
        modules={modules}
        saving={saving}
        onSave={handleSave}
      />

      {/* ── Error Snackbar ─────────────────────────── */}
      <Snackbar
        open={!!errorMsg}
        autoHideDuration={4000}
        onClose={() => setErrorMsg('')}
        anchorOrigin={{ vertical: 'bottom', horizontal: 'center' }}
      >
        <Alert severity="error" onClose={() => setErrorMsg('')} sx={{ minWidth: 280 }}>
          {errorMsg}
        </Alert>
      </Snackbar>
    </div>
  );
};

export default HomeDashboard;
