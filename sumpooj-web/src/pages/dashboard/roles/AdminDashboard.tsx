/**
 * AdminDashboard.tsx — Business Overview for Administrators.
 *
 * 8 metric cards (4-col grid) + weekly sales trend chart.
 * All cards are clickable → navigate to respective modules.
 */
import StatCard from '../components/StatCard';
import MiniChart from '../components/MiniChart';
import type { AdminDashboardData } from '../api/dashboardApi';
import { formatCurrency } from '../../../core/i18n';

// ─── Currency formatter ───────────────────────────────────────
const fmt = (n: number) => formatCurrency(n);

// ─── Icons (w-5 h-5 standardised) ──────────────────────────
const ic = 'w-5 h-5';

const Icons = {
  sales: (
    <svg className={ic} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
      <path strokeLinecap="round" strokeLinejoin="round" d="M12 6v12m-3-2.818.879.659c1.171.879 3.07.879 4.242 0 1.172-.879 1.172-2.303 0-3.182C13.536 12.219 12.768 12 12 12c-.725 0-1.45-.22-2.003-.659-1.106-.879-1.106-2.303 0-3.182s2.9-.879 4.006 0l.415.33M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
    </svg>
  ),
  revenue: (
    <svg className={ic} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
      <path strokeLinecap="round" strokeLinejoin="round" d="M2.25 18L9 11.25l4.306 4.307a11.95 11.95 0 015.814-5.519l2.74-1.22m0 0l-5.94-2.28m5.94 2.28l-2.28 5.941" />
    </svg>
  ),
  profit: (
    <svg className={ic} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
      <path strokeLinecap="round" strokeLinejoin="round" d="M9 14.25l6-6m4.5-3.493V21.75l-3.75-1.5-3.75 1.5-3.75-1.5-3.75 1.5V4.757c0-1.108.806-2.057 1.907-2.185a48.507 48.507 0 0111.186 0c1.1.128 1.907 1.077 1.907 2.185z" />
    </svg>
  ),
  inventory: (
    <svg className={ic} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
      <path strokeLinecap="round" strokeLinejoin="round" d="M20.25 7.5l-.625 10.632a2.25 2.25 0 01-2.247 2.118H6.622a2.25 2.25 0 01-2.247-2.118L3.75 7.5M10 11.25h4M3.375 7.5h17.25c.621 0 1.125-.504 1.125-1.125v-1.5c0-.621-.504-1.125-1.125-1.125H3.375c-.621 0-1.125.504-1.125 1.125v1.5c0 .621.504 1.125 1.125 1.125z" />
    </svg>
  ),
  wastage: (
    <svg className={ic} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
      <path strokeLinecap="round" strokeLinejoin="round" d="M14.74 9l-.346 9m-4.788 0L9.26 9m9.968-3.21c.342.052.682.107 1.022.166m-1.022-.165L18.16 19.673a2.25 2.25 0 01-2.244 2.077H8.084a2.25 2.25 0 01-2.244-2.077L4.772 5.79m14.456 0a48.108 48.108 0 00-3.478-.397m-12 .562c.34-.059.68-.114 1.022-.165m0 0a48.11 48.11 0 013.478-.397m7.5 0v-.916c0-1.18-.91-2.164-2.09-2.201a51.964 51.964 0 00-3.32 0c-1.18.037-2.09 1.022-2.09 2.201v.916m7.5 0a48.667 48.667 0 00-7.5 0" />
    </svg>
  ),
  network: (
    <svg className={ic} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
      <path strokeLinecap="round" strokeLinejoin="round" d="M12 21a9.004 9.004 0 008.716-6.747M12 21a9.004 9.004 0 01-8.716-6.747M12 21c2.485 0 4.5-4.03 4.5-9S14.485 3 12 3m0 18c-2.485 0-4.5-4.03-4.5-9S9.515 3 12 3m0 0a8.997 8.997 0 017.843 4.582M12 3a8.997 8.997 0 00-7.843 4.582m15.686 0A11.953 11.953 0 0112 10.5c-2.998 0-5.74-1.1-7.843-2.918m15.686 0A8.959 8.959 0 0121 12c0 .778-.099 1.533-.284 2.253m0 0A17.919 17.919 0 0112 16.5c-3.162 0-6.133-.815-8.716-2.247m0 0A9.015 9.015 0 013 12c0-1.605.42-3.113 1.157-4.418" />
    </svg>
  ),
  expiring: (
    <svg className={ic} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
      <path strokeLinecap="round" strokeLinejoin="round" d="M12 6v6h4.5m4.5 0a9 9 0 11-18 0 9 9 0 0118 0z" />
    </svg>
  ),
  wedding: (
    <svg className={ic} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
      <path strokeLinecap="round" strokeLinejoin="round" d="M21 8.25c0-2.485-2.099-4.5-4.688-4.5-1.935 0-3.597 1.126-4.312 2.733-.715-1.607-2.377-2.733-4.313-2.733C5.1 3.75 3 5.765 3 8.25c0 7.22 9 12 9 12s9-4.78 9-12z" />
    </svg>
  ),
};

interface AdminDashboardProps {
  data: AdminDashboardData;
}

export default function AdminDashboard({ data }: AdminDashboardProps) {
  return (
    <div>
      {/* Metric cards — 4-col grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-6 mb-10">
        <StatCard label="Today's Sales" value={fmt(data.todaySales)} icon={Icons.sales} iconBg="bg-emerald-50" iconColor="text-emerald-600" href="/order-list" />
        <StatCard label="Month Revenue" value={fmt(data.monthRevenue)} icon={Icons.revenue} iconBg="bg-blue-50" iconColor="text-blue-600" href="/profit-intelligence" />
        <StatCard label="Gross Profit" value={fmt(data.grossProfitToday)} icon={Icons.profit} iconBg="bg-violet-50" iconColor="text-violet-600" href="/profit-intelligence" subtitle="Today" />
        <StatCard label="Inventory Value" value={fmt(data.inventoryValue)} icon={Icons.inventory} iconBg="bg-sky-50" iconColor="text-sky-600" href="/valuation" />
        <StatCard label="Wastage Today" value={fmt(data.wastageToday)} icon={Icons.wastage} iconBg="bg-rose-50" iconColor="text-rose-500" href="/production/wastage" />
        <StatCard label="Network Orders" value={data.networkOrdersPending} icon={Icons.network} iconBg="bg-amber-50" iconColor="text-amber-600" subtitle="Pending approval" href="/external-orders" />
        <StatCard label="Expiring Bouquets" value={data.expiringBouquets} icon={Icons.expiring} iconBg="bg-orange-50" iconColor="text-orange-500" href="/expiry-alerts" />
        <StatCard label="Upcoming Weddings" value={data.upcomingWeddings} icon={Icons.wedding} iconBg="bg-pink-50" iconColor="text-pink-500" subtitle="Next 7 days" href="/events" />
      </div>

      {/* Subtle divider */}
      <div className="border-t border-gray-100 my-8" />

      {/* Sales trend chart */}
      <MiniChart data={data.salesTrend} />
    </div>
  );
}
