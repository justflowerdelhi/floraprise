import React from 'react';
import { Link, useLocation } from 'react-router-dom';
import { ChevronRight, Home } from 'lucide-react';

export const Breadcrumbs: React.FC = () => {
  const location = useLocation();
  const pathnames = location.pathname.split('/').filter(x => x);

  const routeNameMap: Record<string, string> = {
    dashboard: 'Dashboard',
    subscribers: 'Subscribers',
    pending: 'Pending Onboarding',
    provisioning: 'Provisioning Health',
    subscriptions: 'Subscriptions',
    plans: 'Plans',
    active: 'Active',
    trial: 'Trial',
    grace: 'Grace Period',
    expired: 'Expired',
    devices: 'Devices & Apps',
    android: 'Android Fleet',
    solo: 'Solo Offline',
    web: 'Web Terminals',
    versions: 'App Versions',
    delivery: 'Delivery Control',
    live: 'Live Tracking',
    drivers: 'Drivers',
    sessions: 'Delivery Sessions',
    support: 'Support & Diagnostics',
    diagnostics: 'Diagnostics',
    migration: 'Solo Migration',
    issues: 'Issues',
    reports: 'Reports',
    'existing-tools': 'Existing Admin Tools',
    platform: 'Platform',
    users: 'Admin Operators',
    settings: 'Settings'
  };

  return (
    <nav className="flex items-center gap-1.5 text-xs text-slate-500 py-2.5 px-4 md:px-6">
      <Link to="/dashboard" className="flex items-center gap-1 hover:text-slate-900 transition-colors">
        <Home className="w-3.5 h-3.5" />
        <span className="sr-only">Home</span>
      </Link>

      {pathnames.map((value, index) => {
        const to = `/${pathnames.slice(0, index + 1).join('/')}`;
        const isLast = index === pathnames.length - 1;
        const displayName = routeNameMap[value] || (value.length > 15 ? `${value.substring(0, 8)}...` : value);

        return (
          <React.Fragment key={to}>
            <ChevronRight className="w-3.5 h-3.5 text-slate-400" />
            {isLast ? (
              <span className="font-semibold text-slate-900">{displayName}</span>
            ) : (
              <Link to={to} className="hover:text-slate-900 transition-colors">
                {displayName}
              </Link>
            )}
          </React.Fragment>
        );
      })}
    </nav>
  );
};
