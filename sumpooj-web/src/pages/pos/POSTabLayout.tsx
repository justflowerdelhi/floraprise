/**
 * POSTabLayout.tsx — Tab bar + content container for the POS workflow.
 *
 * Steps:
 *  1. Order Type   (always accessible)
 *  2. Products     (requires intent selected)
 *  3. Details      (requires at least one item)
 *  4. Payment      (requires details valid)
 *
 * Touch-friendly, large tabs with step numbers & icons.
 */
import React from 'react';
import {
  Store as TakeNowIcon,
  Inventory2 as ProductsIcon,
  Description as DetailsIcon,
  Payment as PaymentIcon,
  Check as CheckIcon,
} from '@mui/icons-material';

// ─── Tab Definitions ────────────────────────────────────────

export type POSTab = 0 | 1 | 2 | 3;

interface TabDef {
  index: POSTab;
  label: string;
  icon: React.ReactNode;
}

const TABS: TabDef[] = [
  { index: 0, label: 'Order Type', icon: <TakeNowIcon fontSize="small" /> },
  { index: 1, label: 'Products', icon: <ProductsIcon fontSize="small" /> },
  { index: 2, label: 'Details', icon: <DetailsIcon fontSize="small" /> },
  { index: 3, label: 'Payment', icon: <PaymentIcon fontSize="small" /> },
];

// ─── Props ──────────────────────────────────────────────────

interface POSTabLayoutProps {
  activeTab: POSTab;
  onTabChange: (tab: POSTab) => void;
  /** Per-tab reachability (tabs that can be navigated to) */
  tabEnabled: Record<POSTab, boolean>;
  /** Per-tab completion (show green check) */
  tabCompleted: Record<POSTab, boolean>;
  children: React.ReactNode;
}

// ─── Component ──────────────────────────────────────────────

const POSTabLayout: React.FC<POSTabLayoutProps> = ({
  activeTab,
  onTabChange,
  tabEnabled,
  tabCompleted,
  children,
}) => {
  return (
    <div className="h-full flex flex-col overflow-hidden">
      {/* ─── Tab Bar ─────────────────────────────────────── */}
      <nav className="shrink-0 flex border-b border-gray-200 bg-white">
        {TABS.map((tab) => {
          const active = activeTab === tab.index;
          const enabled = tabEnabled[tab.index];
          const completed = tabCompleted[tab.index];

          return (
            <button
              key={tab.index}
              onClick={() => enabled && onTabChange(tab.index)}
              disabled={!enabled}
              className={`
                relative flex-1 flex items-center justify-center gap-2
                px-4 py-3.5 text-sm font-semibold transition-colors select-none
                ${active
                  ? 'text-purple-700 bg-purple-50/60'
                  : enabled
                    ? 'text-gray-600 hover:text-gray-900 hover:bg-gray-50 cursor-pointer'
                    : 'text-gray-300 cursor-not-allowed'
                }
              `}
            >
              {/* Step number */}
              <span
                className={`
                  w-6 h-6 rounded-full flex items-center justify-center text-xs font-bold shrink-0
                  ${completed
                    ? 'bg-green-500 text-white'
                    : active
                      ? 'bg-purple-600 text-white'
                      : enabled
                        ? 'bg-gray-200 text-gray-600'
                        : 'bg-gray-100 text-gray-300'
                  }
                `}
              >
                {completed ? <CheckIcon sx={{ fontSize: 14 }} /> : tab.index + 1}
              </span>

              {/* Icon + label */}
              <span className="hidden sm:flex items-center gap-1.5">
                {tab.icon}
                {tab.label}
              </span>
              <span className="sm:hidden">{tab.label}</span>

              {/* Active indicator */}
              {active && (
                <span className="absolute bottom-0 left-0 right-0 h-[3px] bg-purple-600 rounded-t" />
              )}
            </button>
          );
        })}
      </nav>

      {/* ─── Tab Content ─────────────────────────────────── */}
      <div className="flex-1 overflow-hidden">
        {children}
      </div>
    </div>
  );
};

export default POSTabLayout;
