import React, { useState } from 'react';
import { NavLink, useLocation } from 'react-router-dom';
import {
  LayoutDashboard,
  Users,
  CreditCard,
  Smartphone,
  Truck,
  LifeBuoy,
  BarChart3,
  ExternalLink,
  Settings,
  ChevronDown,
  ChevronRight,
  LucideIcon
} from 'lucide-react';

interface SidebarProps {
  collapsed: boolean;
  onToggleCollapse: () => void;
  mobileOpen: boolean;
  onCloseMobile: () => void;
}

interface NavChildItem {
  label: string;
  path: string;
  highlight?: boolean;
}

interface NavItem {
  id: string;
  label: string;
  icon: LucideIcon;
  path?: string;
  badge?: string;
  children?: NavChildItem[];
}

export const Sidebar: React.FC<SidebarProps> = ({
  collapsed,
  mobileOpen,
  onCloseMobile
}) => {
  const location = useLocation();

  // Accordion state for expandable sections
  const [openSections, setOpenSections] = useState<Record<string, boolean>>({
    subscribers: true,
    subscriptions: false,
    devices: false,
    delivery: false,
    support: false,
    platform: false
  });

  const toggleSection = (section: string) => {
    setOpenSections(prev => ({ ...prev, [section]: !prev[section] }));
  };

  const navItems: NavItem[] = [
    {
      id: 'dashboard',
      label: 'Dashboard',
      icon: LayoutDashboard,
      path: '/dashboard'
    },
    {
      id: 'subscribers',
      label: 'Subscribers',
      icon: Users,
      badge: '8',
      children: [
        { label: 'All Subscribers', path: '/subscribers' },
        { label: 'Pending Onboarding', path: '/subscribers/pending', highlight: true },
        { label: 'Provisioning Health', path: '/subscribers/provisioning' }
      ]
    },
    {
      id: 'subscriptions',
      label: 'Subscriptions',
      icon: CreditCard,
      children: [
        { label: 'Plan Catalog', path: '/subscriptions/plans' },
        { label: 'Active (4)', path: '/subscriptions/active' },
        { label: 'Trial (1)', path: '/subscriptions/trial' },
        { label: 'Grace Period (1)', path: '/subscriptions/grace' },
        { label: 'Expired (1)', path: '/subscriptions/expired' }
      ]
    },
    {
      id: 'devices',
      label: 'Devices & Apps',
      icon: Smartphone,
      children: [
        { label: 'All Devices (6)', path: '/devices' },
        { label: 'Android Fleet', path: '/devices/android' },
        { label: 'Solo Offline', path: '/devices/solo' },
        { label: 'Web Terminals', path: '/devices/web' },
        { label: 'App Versions & Releases', path: '/devices/versions' }
      ]
    },
    {
      id: 'delivery',
      label: 'Delivery Control',
      icon: Truck,
      children: [
        { label: 'Live Tracking Map', path: '/delivery/live' },
        { label: 'Driver Registry', path: '/delivery/drivers' },
        { label: 'Delivery Sessions', path: '/delivery/sessions' }
      ]
    },
    {
      id: 'support',
      label: 'Support & Diagnostics',
      icon: LifeBuoy,
      children: [
        { label: 'System Diagnostics', path: '/support/diagnostics' },
        { label: 'Solo → Cloud Migration', path: '/support/migration' },
        { label: 'Issues & Tickets', path: '/support/issues' }
      ]
    },
    {
      id: 'reports',
      label: 'Reports & Analytics',
      icon: BarChart3,
      path: '/reports'
    },
    {
      id: 'existing-tools',
      label: 'Existing Admin Tools',
      icon: ExternalLink,
      path: '/existing-tools',
      badge: 'Launchpad'
    },
    {
      id: 'platform',
      label: 'Platform & Settings',
      icon: Settings,
      children: [
        { label: 'Pricing Plans', path: '/platform/plans' },
        { label: 'Admin Operators', path: '/platform/users' },
        { label: 'System Settings', path: '/platform/settings' }
      ]
    }
  ];

  return (
    <>
      {/* Mobile backdrop */}
      {mobileOpen && (
        <div 
          onClick={onCloseMobile}
          className="fixed inset-0 z-40 bg-slate-900/60 backdrop-blur-xs lg:hidden"
        />
      )}

      {/* Sidebar container */}
      <aside className={`fixed lg:static top-0 bottom-0 left-0 z-40 bg-slate-900 text-slate-300 flex flex-col border-r border-slate-800 transition-all duration-300 select-none ${
        collapsed ? 'w-20' : 'w-64'
      } ${mobileOpen ? 'translate-x-0' : '-translate-x-full lg:translate-x-0'}`}>
        {/* Brand Header */}
        <div className="h-16 flex items-center justify-between px-4 border-b border-slate-800 shrink-0">
          <div className="flex items-center gap-3 overflow-hidden">
            <div className="w-9 h-9 rounded-xl bg-gradient-to-br from-emerald-500 to-teal-700 flex items-center justify-center text-white font-black text-sm shadow-md shadow-emerald-950 shrink-0">
              FP
            </div>
            {!collapsed && (
              <div className="truncate">
                <div className="font-extrabold text-sm text-white tracking-tight flex items-center gap-1.5">
                  <span>FLORAPRISE</span>
                  <span className="text-[10px] bg-emerald-500/20 text-emerald-400 border border-emerald-500/30 px-1.5 py-0.2 rounded font-bold">ADMIN</span>
                </div>
                <div className="text-[10px] text-slate-400 font-medium tracking-wide uppercase">Central Control</div>
              </div>
            )}
          </div>
        </div>

        {/* Navigation scroll area */}
        <div className="flex-1 overflow-y-auto py-4 px-3 space-y-1.5">
          {navItems.map(item => {
            const Icon = item.icon;
            const hasChildren = !!item.children;
            const isOpen = openSections[item.id];
            const isChildActive = hasChildren && item.children?.some(c => location.pathname === c.path);

            if (hasChildren) {
              return (
                <div key={item.id} className="space-y-1">
                  <button
                    onClick={() => toggleSection(item.id)}
                    className={`w-full flex items-center justify-between p-2.5 rounded-xl text-xs font-semibold transition-all cursor-pointer ${
                      isChildActive
                        ? 'bg-slate-800/90 text-white'
                        : 'text-slate-400 hover:text-white hover:bg-slate-800/60'
                    }`}
                  >
                    <div className="flex items-center gap-3">
                      <Icon className={`w-4 h-4 shrink-0 ${isChildActive ? 'text-emerald-400' : 'text-slate-400'}`} />
                      {!collapsed && <span>{item.label}</span>}
                    </div>
                    {!collapsed && (
                      <div className="flex items-center gap-1.5">
                        {item.badge && (
                          <span className="text-[10px] px-1.5 py-0.5 rounded-full bg-emerald-500/20 text-emerald-400 font-bold">
                            {item.badge}
                          </span>
                        )}
                        {isOpen ? <ChevronDown className="w-3.5 h-3.5 text-slate-500" /> : <ChevronRight className="w-3.5 h-3.5 text-slate-500" />}
                      </div>
                    )}
                  </button>

                  {!collapsed && isOpen && item.children && (
                    <div className="pl-9 pr-1 space-y-1 pt-0.5 animate-in slide-in-from-top-2 duration-150">
                      {item.children.map(child => {
                        const isCurrent = location.pathname === child.path;
                        return (
                          <NavLink
                            key={child.path}
                            to={child.path}
                            onClick={onCloseMobile}
                            className={`block py-1.5 px-2.5 rounded-lg text-xs font-medium transition-colors ${
                              isCurrent
                                ? 'bg-emerald-600 text-white font-semibold shadow-xs'
                                : 'text-slate-400 hover:text-slate-200 hover:bg-slate-800/50'
                            }`}
                          >
                            <div className="flex items-center justify-between">
                              <span>{child.label}</span>
                              {child.highlight && !isCurrent && (
                                <span className="w-1.5 h-1.5 rounded-full bg-amber-400 animate-pulse" />
                              )}
                            </div>
                          </NavLink>
                        );
                      })}
                    </div>
                  )}
                </div>
              );
            }

            const isCurrent = location.pathname === item.path;
            return (
              <NavLink
                key={item.id}
                to={item.path!}
                onClick={onCloseMobile}
                className={`flex items-center justify-between p-2.5 rounded-xl text-xs font-semibold transition-all ${
                  isCurrent
                    ? 'bg-emerald-600 text-white shadow-xs'
                    : 'text-slate-400 hover:text-white hover:bg-slate-800/60'
                }`}
              >
                <div className="flex items-center gap-3">
                  <Icon className={`w-4 h-4 shrink-0 ${isCurrent ? 'text-white' : 'text-slate-400'}`} />
                  {!collapsed && <span>{item.label}</span>}
                </div>
                {!collapsed && item.badge && (
                  <span className={`text-[10px] px-1.5 py-0.5 rounded-full font-bold ${
                    isCurrent ? 'bg-white/20 text-white' : 'bg-emerald-500/20 text-emerald-400'
                  }`}>
                    {item.badge}
                  </span>
                )}
              </NavLink>
            );
          })}
        </div>

        {/* System status pill footer */}
        {!collapsed && (
          <div className="p-3 border-t border-slate-800 shrink-0">
            <div className="p-2.5 rounded-xl bg-slate-800/60 border border-slate-700/60 flex items-center justify-between text-xs">
              <div className="flex items-center gap-2">
                <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse" />
                <span className="text-[11px] text-slate-300 font-medium">Cluster Healthy</span>
              </div>
              <span className="text-[10px] text-slate-500 font-mono">v2.4.1</span>
            </div>
          </div>
        )}
      </aside>
    </>
  );
};
