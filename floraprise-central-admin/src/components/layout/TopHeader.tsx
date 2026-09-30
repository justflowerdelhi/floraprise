import React, { useState } from 'react';
import { useAuth } from '../../context/AuthContext';
import { 
  Menu, 
  Search, 
  Bell, 
  Plus, 
  LogOut, 
  User, 
  ShieldCheck, 
  ExternalLink,
  ChevronDown,
  Sparkles
} from 'lucide-react';

interface TopHeaderProps {
  onToggleMobileSidebar: () => void;
  onOpenGlobalSearch: () => void;
  onOpenOnboarding: () => void;
}

export const TopHeader: React.FC<TopHeaderProps> = ({
  onToggleMobileSidebar,
  onOpenGlobalSearch,
  onOpenOnboarding
}) => {
  const { user, logout } = useAuth();
  const [profileOpen, setProfileOpen] = useState(false);

  return (
    <header className="h-16 bg-white border-b border-slate-200/80 px-4 md:px-6 flex items-center justify-between gap-4 sticky top-0 z-30">
      {/* Left controls */}
      <div className="flex items-center gap-3">
        <button
          onClick={onToggleMobileSidebar}
          className="p-2 rounded-xl text-slate-500 hover:text-slate-900 hover:bg-slate-100 lg:hidden"
        >
          <Menu className="w-5 h-5" />
        </button>

        {/* Global Search trigger */}
        <button
          onClick={onOpenGlobalSearch}
          className="flex items-center gap-2.5 px-3.5 py-1.5 bg-slate-100/80 hover:bg-slate-200/60 border border-slate-200/80 rounded-xl text-xs text-slate-500 hover:text-slate-900 transition-all cursor-pointer w-48 md:w-80"
        >
          <Search className="w-4 h-4 text-slate-400 shrink-0" />
          <span className="truncate">Search subscribers or tools...</span>
          <kbd className="hidden sm:inline-block ml-auto text-[10px] bg-white border border-slate-200 px-1.5 py-0.5 rounded font-mono text-slate-400">
            Ctrl+K
          </kbd>
        </button>
      </div>

      {/* Right controls */}
      <div className="flex items-center gap-3">
        {/* Quick Add Subscriber button */}
        <button
          onClick={onOpenOnboarding}
          className="inline-flex items-center gap-1.5 px-3.5 py-2 rounded-xl text-xs font-bold bg-emerald-600 hover:bg-emerald-700 text-white shadow-xs shadow-emerald-600/20 transition-all cursor-pointer"
        >
          <Plus className="w-4 h-4" />
          <span className="hidden sm:inline">Add Subscriber</span>
        </button>

        {/* Notifications Icon */}
        <button
          onClick={() => alert('All systems operational. Zero unacknowledged alerts.')}
          className="relative p-2 rounded-xl text-slate-500 hover:text-slate-900 hover:bg-slate-100 transition-colors"
          title="System Notifications"
        >
          <Bell className="w-4 h-4" />
          <span className="absolute top-1.5 right-1.5 w-2 h-2 rounded-full bg-emerald-500 ring-2 ring-white" />
        </button>

        {/* User Profile dropdown */}
        <div className="relative">
          <button
            onClick={() => setProfileOpen(!profileOpen)}
            className="flex items-center gap-2.5 p-1.5 rounded-xl hover:bg-slate-100 transition-colors cursor-pointer"
          >
            <div className="w-8 h-8 rounded-full bg-emerald-100 text-emerald-800 font-bold text-xs flex items-center justify-center border border-emerald-200">
              {user?.name.charAt(0) || 'A'}
            </div>
            <div className="hidden md:block text-left">
              <div className="text-xs font-bold text-slate-900 leading-tight">{user?.name || 'Administrator'}</div>
              <div className="text-[10px] text-slate-500">{user?.role || 'SuperAdmin'}</div>
            </div>
            <ChevronDown className="w-3.5 h-3.5 text-slate-400" />
          </button>

          {profileOpen && (
            <div 
              className="absolute right-0 mt-2 w-56 bg-white rounded-2xl shadow-xl border border-slate-200 py-1.5 z-50 text-xs text-slate-700 animate-in fade-in zoom-in-95 duration-100"
              onMouseLeave={() => setProfileOpen(false)}
            >
              <div className="px-4 py-2 border-b border-slate-100">
                <div className="font-bold text-slate-900">{user?.name}</div>
                <div className="text-[11px] text-slate-500 truncate">{user?.email}</div>
              </div>

              <div className="py-1">
                <a
                  href="https://erp.floraprise.com/admin/dashboard"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="flex items-center justify-between px-4 py-2 hover:bg-slate-50 text-slate-700"
                >
                  <span className="flex items-center gap-2">
                    <ExternalLink className="w-3.5 h-3.5 text-slate-400" />
                    <span>Launch ERP Admin</span>
                  </span>
                  <span className="text-[10px] text-slate-400">External</span>
                </a>

                <button
                  onClick={() => {
                    setProfileOpen(false);
                    onOpenOnboarding();
                  }}
                  className="w-full flex items-center gap-2 px-4 py-2 hover:bg-slate-50 text-left text-slate-700 cursor-pointer"
                >
                  <Sparkles className="w-3.5 h-3.5 text-emerald-600" />
                  <span>Onboarding Wizard</span>
                </button>
              </div>

              <div className="border-t border-slate-100 pt-1">
                <button
                  onClick={() => {
                    logout();
                    setProfileOpen(false);
                  }}
                  className="w-full flex items-center gap-2 px-4 py-2 text-rose-600 hover:bg-rose-50 text-left cursor-pointer font-medium"
                >
                  <LogOut className="w-3.5 h-3.5" />
                  <span>Sign Out</span>
                </button>
              </div>
            </div>
          )}
        </div>
      </div>
    </header>
  );
};
