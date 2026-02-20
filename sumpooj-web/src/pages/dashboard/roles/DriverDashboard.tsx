/**
 * DriverDashboard.tsx — Delivery Focus for Drivers.
 *
 * Summary bar + delivery card list with status toggle.
 * Mobile-friendly, clean layout.
 */
import { useState, useCallback } from 'react';
import SectionHeading from '../components/SectionHeading';
import type { DriverDashboardData, DeliveryItem } from '../api/dashboardApi';

// ─── Status helpers ─────────────────────────────────────────

type DeliveryStatus = DeliveryItem['status'];

const STATUS_CONFIG: Record<DeliveryStatus, { label: string; bg: string; text: string; ring: string }> = {
  pending: { label: 'Pending', bg: 'bg-amber-50', text: 'text-amber-700', ring: 'ring-amber-200' },
  delivered: { label: 'Delivered', bg: 'bg-emerald-50', text: 'text-emerald-700', ring: 'ring-emerald-200' },
  failed: { label: 'Failed', bg: 'bg-rose-50', text: 'text-rose-700', ring: 'ring-rose-200' },
};

const NEXT_STATUS: Record<DeliveryStatus, DeliveryStatus> = {
  pending: 'delivered',
  delivered: 'failed',
  failed: 'pending',
};

// ─── Delivery Card ──────────────────────────────────────────

const icSm = 'w-4 h-4';

interface DeliveryCardProps {
  item: DeliveryItem;
  index: number;
  onStatusToggle: (id: string) => void;
}

function DeliveryCard({ item, index, onStatusToggle }: DeliveryCardProps) {
  const s = STATUS_CONFIG[item.status];
  const done = item.status === 'delivered';

  return (
    <div
      className={`
        bg-white rounded-xl border border-slate-100 shadow-sm
        transition-all duration-200 hover:shadow-md hover:-translate-y-1
        ${done ? 'opacity-60' : ''}
      `}
    >
      {/* Header */}
      <div className="flex items-center justify-between px-4 pt-4 pb-2">
        <div className="flex items-center gap-2.5">
          <span className="w-7 h-7 rounded-lg bg-slate-100 text-slate-600 text-xs font-bold flex items-center justify-center shrink-0">
            {index + 1}
          </span>
          <div>
            <p className="text-sm font-semibold text-slate-800">{item.orderNumber}</p>
            <p className="text-xs text-slate-400">{item.timeSlot}</p>
          </div>
        </div>
        <button
          onClick={() => onStatusToggle(item.id)}
          className={`text-xs font-semibold px-3 py-1 rounded-full ring-1 transition-colors ${s.bg} ${s.text} ${s.ring}`}
        >
          {s.label}
        </button>
      </div>

      {/* Body */}
      <div className="px-4 pb-4 space-y-1.5">
        <div className="flex items-center gap-2">
          <svg className={`${icSm} text-slate-400 shrink-0`} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
            <path strokeLinecap="round" strokeLinejoin="round" d="M15.75 6a3.75 3.75 0 11-7.5 0 3.75 3.75 0 017.5 0zM4.501 20.118a7.5 7.5 0 0114.998 0A17.933 17.933 0 0112 21.75c-2.676 0-5.216-.584-7.499-1.632z" />
          </svg>
          <span className="text-sm text-slate-700 font-medium">{item.customerName}</span>
        </div>

        <a href={`tel:${item.phone}`} className="flex items-center gap-2 group">
          <svg className={`${icSm} text-emerald-500 shrink-0`} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
            <path strokeLinecap="round" strokeLinejoin="round" d="M2.25 6.75c0 8.284 6.716 15 15 15h2.25a2.25 2.25 0 002.25-2.25v-1.372c0-.516-.351-.966-.852-1.091l-4.423-1.106c-.44-.11-.902.055-1.173.417l-.97 1.293c-.282.376-.769.542-1.21.38a12.035 12.035 0 01-7.143-7.143c-.162-.441.004-.928.38-1.21l1.293-.97c.363-.271.527-.734.417-1.173L6.963 3.102a1.125 1.125 0 00-1.091-.852H4.5A2.25 2.25 0 002.25 4.5v2.25z" />
          </svg>
          <span className="text-sm text-emerald-600 font-medium group-hover:underline">{item.phone}</span>
        </a>

        <div className="flex items-start gap-2">
          <svg className={`${icSm} text-slate-400 shrink-0 mt-0.5`} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
            <path strokeLinecap="round" strokeLinejoin="round" d="M15 10.5a3 3 0 11-6 0 3 3 0 016 0z" />
            <path strokeLinecap="round" strokeLinejoin="round" d="M19.5 10.5c0 7.142-7.5 11.25-7.5 11.25S4.5 17.642 4.5 10.5a7.5 7.5 0 1115 0z" />
          </svg>
          <span className="text-sm text-slate-600">{item.address}</span>
        </div>

        <div className="flex items-start gap-2">
          <svg className={`${icSm} text-slate-400 shrink-0 mt-0.5`} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
            <path strokeLinecap="round" strokeLinejoin="round" d="M20.25 7.5l-.625 10.632a2.25 2.25 0 01-2.247 2.118H6.622a2.25 2.25 0 01-2.247-2.118L3.75 7.5M10 11.25h4M3.375 7.5h17.25c.621 0 1.125-.504 1.125-1.125v-1.5c0-.621-.504-1.125-1.125-1.125H3.375c-.621 0-1.125.504-1.125 1.125v1.5c0 .621.504 1.125 1.125 1.125z" />
          </svg>
          <span className="text-xs text-slate-500">{item.items}</span>
        </div>

        {item.notes && (
          <div className="bg-rose-50 rounded-lg px-3 py-1.5 mt-1">
            <p className="text-xs text-rose-600 font-medium">{item.notes}</p>
          </div>
        )}
      </div>
    </div>
  );
}

// ─── Main Component ─────────────────────────────────────────

interface DriverDashboardProps {
  data: DriverDashboardData;
}

export default function DriverDashboard({ data }: DriverDashboardProps) {
  const [deliveries, setDeliveries] = useState<DeliveryItem[]>(data.deliveries);

  const toggleStatus = useCallback((id: string) => {
    setDeliveries((prev) =>
      prev.map((d) =>
        d.id === id ? { ...d, status: NEXT_STATUS[d.status] } : d,
      ),
    );
  }, []);

  const pending = deliveries.filter((d) => d.status === 'pending').length;
  const delivered = deliveries.filter((d) => d.status === 'delivered').length;
  const failed = deliveries.filter((d) => d.status === 'failed').length;

  return (
    <div>
      {/* Summary cards — standard card treatment in 4-col grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-6 mb-10">
        <div className="bg-white rounded-xl shadow-sm border border-slate-100 p-5 flex flex-col justify-between transition-all duration-200 hover:shadow-md hover:-translate-y-1">
          <div className="flex items-center gap-3 mb-3">
            <div className="w-10 h-10 rounded-xl bg-slate-100 text-slate-600 flex items-center justify-center shrink-0">
              <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
                <path strokeLinecap="round" strokeLinejoin="round" d="M8.25 18.75a1.5 1.5 0 01-3 0m3 0a1.5 1.5 0 00-3 0m3 0h6m-9 0H3.375a1.125 1.125 0 01-1.125-1.125V14.25m17.25 4.5a1.5 1.5 0 01-3 0m3 0a1.5 1.5 0 00-3 0m3 0h1.125c.621 0 1.129-.504 1.09-1.124a17.902 17.902 0 00-3.213-9.193 2.056 2.056 0 00-1.58-.86H14.25m-6.75 0V7.5A2.25 2.25 0 019.75 5.25h1.5" />
              </svg>
            </div>
            <p className="text-sm text-gray-500 font-medium">Total</p>
          </div>
          <p className="text-2xl font-semibold text-gray-900">{deliveries.length}</p>
        </div>
        <div className="bg-white rounded-xl shadow-sm border border-slate-100 p-5 flex flex-col justify-between transition-all duration-200 hover:shadow-md hover:-translate-y-1">
          <div className="flex items-center gap-3 mb-3">
            <div className="w-10 h-10 rounded-xl bg-amber-50 text-amber-600 flex items-center justify-center shrink-0">
              <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
                <path strokeLinecap="round" strokeLinejoin="round" d="M12 6v6h4.5m4.5 0a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
            </div>
            <p className="text-sm text-gray-500 font-medium">Pending</p>
          </div>
          <p className="text-2xl font-semibold text-amber-700">{pending}</p>
        </div>
        <div className="bg-white rounded-xl shadow-sm border border-slate-100 p-5 flex flex-col justify-between transition-all duration-200 hover:shadow-md hover:-translate-y-1">
          <div className="flex items-center gap-3 mb-3">
            <div className="w-10 h-10 rounded-xl bg-emerald-50 text-emerald-600 flex items-center justify-center shrink-0">
              <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
                <path strokeLinecap="round" strokeLinejoin="round" d="M9 12.75L11.25 15 15 9.75M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
            </div>
            <p className="text-sm text-gray-500 font-medium">Delivered</p>
          </div>
          <p className="text-2xl font-semibold text-emerald-700">{delivered}</p>
        </div>
        <div className="bg-white rounded-xl shadow-sm border border-slate-100 p-5 flex flex-col justify-between transition-all duration-200 hover:shadow-md hover:-translate-y-1">
          <div className="flex items-center gap-3 mb-3">
            <div className="w-10 h-10 rounded-xl bg-rose-50 text-rose-500 flex items-center justify-center shrink-0">
              <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
                <path strokeLinecap="round" strokeLinejoin="round" d="M12 9v3.75m-9.303 3.376c-.866 1.5.217 3.374 1.948 3.374h14.71c1.73 0 2.813-1.874 1.948-3.374L13.949 3.378c-.866-1.5-3.032-1.5-3.898 0L2.697 16.126zM12 15.75h.007v.008H12v-.008z" />
              </svg>
            </div>
            <p className="text-sm text-gray-500 font-medium">Failed</p>
          </div>
          <p className="text-2xl font-semibold text-rose-700">{failed}</p>
        </div>
      </div>

      {/* Subtle divider */}
      <div className="border-t border-gray-100 my-8" />

      {/* Delivery list */}
      <div className="mb-4">
        <SectionHeading title="Today's Deliveries" count={deliveries.length} />
      </div>
      {deliveries.length > 0 ? (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          {deliveries.map((d, i) => (
            <DeliveryCard key={d.id} item={d} index={i} onStatusToggle={toggleStatus} />
          ))}
        </div>
      ) : (
        <div className="text-center py-12 text-gray-400">
          <p className="text-sm">No deliveries scheduled today</p>
        </div>
      )}
    </div>
  );
}
