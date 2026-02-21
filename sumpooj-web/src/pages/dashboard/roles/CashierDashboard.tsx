/**
 * CashierDashboard.tsx — Speed & Simplicity for Cashiers.
 *
 * Compact "Start POS" card + 4 stat cards.
 * Clean, distraction-free.
 */
import { useNavigate } from 'react-router-dom';
import StatCard from '../components/StatCard';
import type { CashierDashboardData } from '../api/dashboardApi';
import { formatCurrency } from '../../../core/i18n';

const ic = 'w-5 h-5';

const Icons = {
  pickup: (
    <svg className={ic} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
      <path strokeLinecap="round" strokeLinejoin="round" d="M15.75 10.5V6a3.75 3.75 0 10-7.5 0v4.5m11.356-1.993l1.263 12c.07.665-.45 1.243-1.119 1.243H4.25a1.125 1.125 0 01-1.12-1.243l1.264-12A1.125 1.125 0 015.513 7.5h12.974c.576 0 1.059.435 1.119 1.007zM8.625 10.5a.375.375 0 11-.75 0 .375.375 0 01.75 0zm7.5 0a.375.375 0 11-.75 0 .375.375 0 01.75 0z" />
    </svg>
  ),
  unpaid: (
    <svg className={ic} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
      <path strokeLinecap="round" strokeLinejoin="round" d="M2.25 18.75a60.07 60.07 0 0115.797 2.101c.727.198 1.453-.342 1.453-1.096V18.75M3.75 4.5v.75A.75.75 0 013 6h-.75m0 0v-.375c0-.621.504-1.125 1.125-1.125H20.25M2.25 6v9m18-10.5v.75c0 .414.336.75.75.75h.75m-1.5-1.5h.375c.621 0 1.125.504 1.125 1.125v9.75c0 .621-.504 1.125-1.125 1.125h-.375m1.5-1.5H21a.75.75 0 00-.75.75v.75m0 0H3.75m0 0h-.375a1.125 1.125 0 01-1.125-1.125V15m1.5 1.5v-.75A.75.75 0 003 15h-.75M15 10.5a3 3 0 11-6 0 3 3 0 016 0zm3 0h.008v.008H18V10.5zm-12 0h.008v.008H6V10.5z" />
    </svg>
  ),
  receipt: (
    <svg className={ic} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
      <path strokeLinecap="round" strokeLinejoin="round" d="M9 14.25l6-6m4.5-3.493V21.75l-3.75-1.5-3.75 1.5-3.75-1.5-3.75 1.5V4.757c0-1.108.806-2.057 1.907-2.185a48.507 48.507 0 0111.186 0c1.1.128 1.907 1.077 1.907 2.185z" />
    </svg>
  ),
  total: (
    <svg className={ic} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
      <path strokeLinecap="round" strokeLinejoin="round" d="M12 6v12m-3-2.818.879.659c1.171.879 3.07.879 4.242 0 1.172-.879 1.172-2.303 0-3.182C13.536 12.219 12.768 12 12 12c-.725 0-1.45-.22-2.003-.659-1.106-.879-1.106-2.303 0-3.182s2.9-.879 4.006 0l.415.33M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
    </svg>
  ),
};

interface CashierDashboardProps {
  data: CashierDashboardData;
}

export default function CashierDashboard({ data }: CashierDashboardProps) {
  const navigate = useNavigate();

  return (
    <div>
      {/* Start POS — compact, inline hero */}
      <div
        onClick={() => navigate('/pos')}
        className="
          bg-white rounded-xl shadow-sm border border-slate-100
          p-5 flex items-center gap-4 mb-10
          cursor-pointer hover:shadow-md hover:-translate-y-1
          transition-all duration-200 active:scale-[0.99]
        "
      >
        <div className="w-10 h-10 rounded-xl bg-emerald-50 text-emerald-600 flex items-center justify-center shrink-0">
          <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
            <path strokeLinecap="round" strokeLinejoin="round" d="M2.25 3h1.386c.51 0 .955.343 1.087.835l.383 1.437M7.5 14.25a3 3 0 00-3 3h15.75m-12.75-3h11.218c1.121-2.3 2.1-4.684 2.924-7.138a60.114 60.114 0 00-16.536-1.84M7.5 14.25L5.106 5.272M6 20.25a.75.75 0 11-1.5 0 .75.75 0 011.5 0zm12.75 0a.75.75 0 11-1.5 0 .75.75 0 011.5 0z" />
          </svg>
        </div>
        <div>
          <p className="text-sm font-bold text-slate-800">Start POS</p>
          <p className="text-xs text-slate-500">Open Walk-In Sales Terminal</p>
        </div>
        <svg className="w-5 h-5 text-slate-300 ml-auto" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
          <path strokeLinecap="round" strokeLinejoin="round" d="M8.25 4.5l7.5 7.5-7.5 7.5" />
        </svg>
      </div>

      {/* Metric cards — 4-col grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-6">
        <StatCard label="Pending Pickups" value={data.pendingPickups} icon={Icons.pickup} iconBg="bg-amber-50" iconColor="text-amber-600" href="/order-list" />
        <StatCard label="Unpaid Orders" value={data.unpaidOrders} icon={Icons.unpaid} iconBg="bg-rose-50" iconColor="text-rose-500" href="/order-list" />
        <StatCard label="Sales Today" value={data.todaySalesCount} icon={Icons.receipt} iconBg="bg-blue-50" iconColor="text-blue-600" subtitle="transactions" />
        <StatCard label="Today's Total" value={formatCurrency(data.todaySalesTotal)} icon={Icons.total} iconBg="bg-emerald-50" iconColor="text-emerald-600" />
      </div>
    </div>
  );
}
