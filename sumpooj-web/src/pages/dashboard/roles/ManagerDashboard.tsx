/**
 * ManagerDashboard.tsx — Operations Control for Store Managers.
 *
 * 6 metric cards + quick actions + operation alerts.
 */
import StatCard from '../components/StatCard';
import QuickActionButton from '../components/QuickActionButton';
import SectionHeading from '../components/SectionHeading';
import type { ManagerDashboardData, OperationAlert } from '../api/dashboardApi';

// ─── Icons (w-5 h-5 standardised) ──────────────────────────
const ic = 'w-5 h-5';
const icSm = 'w-4 h-4';

const Icons = {
  orders: (
    <svg className={ic} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
      <path strokeLinecap="round" strokeLinejoin="round" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
    </svg>
  ),
  delivery: (
    <svg className={ic} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
      <path strokeLinecap="round" strokeLinejoin="round" d="M8.25 18.75a1.5 1.5 0 01-3 0m3 0a1.5 1.5 0 00-3 0m3 0h6m-9 0H3.375a1.125 1.125 0 01-1.125-1.125V14.25m17.25 4.5a1.5 1.5 0 01-3 0m3 0a1.5 1.5 0 00-3 0m3 0h1.125c.621 0 1.129-.504 1.09-1.124a17.902 17.902 0 00-3.213-9.193 2.056 2.056 0 00-1.58-.86H14.25m-6.75 0V7.5A2.25 2.25 0 019.75 5.25h1.5" />
    </svg>
  ),
  production: (
    <svg className={ic} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
      <path strokeLinecap="round" strokeLinejoin="round" d="M9.75 3.104v5.714a2.25 2.25 0 01-.659 1.591L5 14.5M9.75 3.104c-.251.023-.501.05-.75.082m.75-.082a24.301 24.301 0 014.5 0m0 0v5.714c0 .597.237 1.17.659 1.591L19.8 15.3M14.25 3.104c.251.023.501.05.75.082M19.8 15.3l-1.57.393A9.065 9.065 0 0112 15a9.065 9.065 0 00-6.23.693L5 14.5m14.8.8l1.402 1.402c1.232 1.232.65 3.318-1.067 3.611A48.309 48.309 0 0112 21c-2.773 0-5.491-.235-8.135-.687-1.718-.293-2.3-2.379-1.067-3.61L5 14.5" />
    </svg>
  ),
  lowStock: (
    <svg className={ic} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
      <path strokeLinecap="round" strokeLinejoin="round" d="M12 9v3.75m-9.303 3.376c-.866 1.5.217 3.374 1.948 3.374h14.71c1.73 0 2.813-1.874 1.948-3.374L13.949 3.378c-.866-1.5-3.032-1.5-3.898 0L2.697 16.126zM12 15.75h.007v.008H12v-.008z" />
    </svg>
  ),
  expiry: (
    <svg className={ic} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
      <path strokeLinecap="round" strokeLinejoin="round" d="M12 6v6h4.5m4.5 0a9 9 0 11-18 0 9 9 0 0118 0z" />
    </svg>
  ),
  staff: (
    <svg className={ic} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
      <path strokeLinecap="round" strokeLinejoin="round" d="M15 19.128a9.38 9.38 0 002.625.372 9.337 9.337 0 004.121-.952 4.125 4.125 0 00-7.533-2.493M15 19.128v-.003c0-1.113-.285-2.16-.786-3.07M15 19.128v.106A12.318 12.318 0 018.624 21c-2.331 0-4.512-.645-6.374-1.766l-.001-.109a6.375 6.375 0 0111.964-3.07M12 6.375a3.375 3.375 0 11-6.75 0 3.375 3.375 0 016.75 0zm8.25 2.25a2.625 2.625 0 11-5.25 0 2.625 2.625 0 015.25 0z" />
    </svg>
  ),
  qaProd: (
    <svg className={icSm} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
      <path strokeLinecap="round" strokeLinejoin="round" d="M12 4.5v15m7.5-7.5h-15" />
    </svg>
  ),
  qaTruck: (
    <svg className={icSm} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
      <path strokeLinecap="round" strokeLinejoin="round" d="M8.25 18.75a1.5 1.5 0 01-3 0m3 0a1.5 1.5 0 00-3 0m3 0h6m-9 0H3.375a1.125 1.125 0 01-1.125-1.125V14.25m17.25 4.5a1.5 1.5 0 01-3 0m3 0a1.5 1.5 0 00-3 0m3 0h1.125c.621 0 1.129-.504 1.09-1.124a17.902 17.902 0 00-3.213-9.193 2.056 2.056 0 00-1.58-.86H14.25m-6.75 0V7.5A2.25 2.25 0 019.75 5.25h1.5" />
    </svg>
  ),
  qaAdjust: (
    <svg className={icSm} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
      <path strokeLinecap="round" strokeLinejoin="round" d="M10.5 6h9.75M10.5 6a1.5 1.5 0 11-3 0m3 0a1.5 1.5 0 10-3 0M3.75 6H7.5m3 12h9.75m-9.75 0a1.5 1.5 0 01-3 0m3 0a1.5 1.5 0 00-3 0m-3.75 0H7.5m9-6h3.75m-3.75 0a1.5 1.5 0 01-3 0m3 0a1.5 1.5 0 00-3 0m-9.75 0h9.75" />
    </svg>
  ),
};

// ─── Alert row ──────────────────────────────────────────────

const SEVERITY: Record<string, { dot: string; bg: string; text: string }> = {
  critical: { dot: 'bg-rose-500', bg: 'bg-rose-50', text: 'text-rose-700' },
  warning: { dot: 'bg-amber-400', bg: 'bg-amber-50', text: 'text-amber-700' },
  info: { dot: 'bg-blue-400', bg: 'bg-blue-50', text: 'text-blue-700' },
};

function AlertRow({ alert }: { alert: OperationAlert }) {
  const s = SEVERITY[alert.severity];
  return (
    <a
      href={alert.href ?? '#'}
      className={`flex items-center gap-3 px-4 py-3 rounded-xl ${s.bg} transition-colors hover:opacity-90`}
    >
      <span className={`w-2 h-2 rounded-full shrink-0 ${s.dot}`} />
      <p className={`text-sm font-medium ${s.text} flex-1`}>{alert.message}</p>
      <svg className={`w-4 h-4 ${s.text} opacity-40`} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
        <path strokeLinecap="round" strokeLinejoin="round" d="M8.25 4.5l7.5 7.5-7.5 7.5" />
      </svg>
    </a>
  );
}

// ─── Component ──────────────────────────────────────────────

interface ManagerDashboardProps {
  data: ManagerDashboardData;
}

export default function ManagerDashboard({ data }: ManagerDashboardProps) {
  return (
    <div>
      {/* Metric cards — 4-col grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-6 mb-8">
        <StatCard label="Orders to Fulfill" value={data.ordersToFulfill} icon={Icons.orders} iconBg="bg-blue-50" iconColor="text-blue-600" href="/order-list" />
        <StatCard label="Deliveries Today" value={data.deliveriesScheduled} icon={Icons.delivery} iconBg="bg-emerald-50" iconColor="text-emerald-600" href="/delivery-scheduler" />
        <StatCard label="Production Pending" value={data.productionPending} icon={Icons.production} iconBg="bg-violet-50" iconColor="text-violet-600" href="/production/produce" />
        <StatCard label="Low Stock Alerts" value={data.lowStockAlerts} icon={Icons.lowStock} iconBg="bg-rose-50" iconColor="text-rose-500" href="/inventory" />
        <StatCard label="Expiring Batches" value={data.expiringBatches} icon={Icons.expiry} iconBg="bg-amber-50" iconColor="text-amber-600" href="/expiry-alerts" />
        <StatCard label="Staff Tasks" value={data.staffTasksPending} icon={Icons.staff} iconBg="bg-slate-100" iconColor="text-slate-600" href="/staff" subtitle="Pending" />
      </div>

      {/* Quick actions */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-8">
        <QuickActionButton label="Create Production" icon={Icons.qaProd} href="/production/produce" variant="primary" />
        <QuickActionButton label="View Deliveries" icon={Icons.qaTruck} href="/delivery-scheduler" />
        <QuickActionButton label="Inventory Adjustment" icon={Icons.qaAdjust} href="/adjustments/new" />
      </div>

      {/* Operation alerts */}
      {data.topAlerts.length > 0 && (
        <div>
          <div className="mb-4">
            <SectionHeading title="Alerts" count={data.topAlerts.length} />
          </div>
          <div className="space-y-2">
            {data.topAlerts.map((a) => (
              <AlertRow key={a.id} alert={a} />
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
