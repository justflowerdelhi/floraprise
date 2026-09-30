import React, { useState, useEffect } from 'react';
import { realDeliveryService } from '../../services/api/realDeliveryService';
import { DeliverySession } from '../../types/delivery';
import { DataTable, Column } from '../../components/common/DataTable';
import { StatusBadge } from '../../components/common/StatusBadge';
import { Package, MapPin, Clock, ExternalLink } from 'lucide-react';

export const DeliverySessionsPage: React.FC = () => {
  const [sessions, setSessions] = useState<DeliverySession[]>([]);

  useEffect(() => {
    realDeliveryService.getSessions().then(setSessions);
  }, []);

  const columns: Column<DeliverySession>[] = [
    {
      key: 'orderNumber',
      header: 'Order # & Recipient',
      sortable: true,
      render: (s) => (
        <div>
          <div className="font-mono font-bold text-slate-900">{s.orderNumber}</div>
          <div className="text-[11px] text-slate-500">{s.recipientName} ({s.recipientPhone})</div>
        </div>
      )
    },
    {
      key: 'companyName',
      header: 'Subscriber Business',
      sortable: true,
      render: (s) => <span className="font-semibold text-slate-800">{s.companyName}</span>
    },
    {
      key: 'driverName',
      header: 'Assigned Driver',
      sortable: true,
      render: (s) => <span className="text-slate-800">{s.driverName}</span>
    },
    {
      key: 'deliveryAddress',
      header: 'Destination Address',
      render: (s) => <span className="text-xs text-slate-600 truncate max-w-xs block">{s.deliveryAddress}</span>
    },
    {
      key: 'startedAt',
      header: 'Timeline & ETA',
      render: (s) => (
        <div className="text-[11px] text-slate-600">
          <div>Started: {s.startedAt}</div>
          <div>ETA: <strong className="text-emerald-700">{s.completedAt ? `Delivered at ${s.completedAt}` : s.estimatedDeliveryAt}</strong></div>
        </div>
      )
    },
    {
      key: 'status',
      header: 'Session Status',
      sortable: true,
      render: (s) => <StatusBadge status={s.status} size="sm" />
    }
  ];

  return (
    <div className="space-y-4">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h2 className="text-xl font-black text-slate-900 flex items-center gap-2">
            <Package className="w-5 h-5 text-emerald-600" />
            <span>Delivery Order Sessions</span>
          </h2>
          <p className="text-xs text-slate-500 mt-0.5">
            Drop-off dispatch logs, ETAs, and customer delivery confirmations.
          </p>
        </div>

        <a
          href="https://erp.floraprise.com/delivery-routes"
          target="_blank"
          rel="noopener noreferrer"
          className="inline-flex items-center gap-1.5 px-3.5 py-2 text-xs font-bold rounded-xl bg-slate-900 hover:bg-slate-800 text-white shadow-xs"
        >
          <span>Open Delivery Routes Console</span>
          <ExternalLink className="w-3.5 h-3.5" />
        </a>
      </div>

      {sessions.length > 0 ? (
        <DataTable
          columns={columns}
          data={sessions}
          searchPlaceholder="Search delivery sessions by order #, recipient, driver..."
          searchableKeys={['orderNumber', 'recipientName', 'driverName', 'companyName']}
        />
      ) : (
        <div className="p-10 bg-white rounded-2xl border border-slate-200 text-center space-y-3">
          <div className="w-12 h-12 rounded-2xl bg-slate-50 text-slate-400 border border-slate-200 mx-auto flex items-center justify-center">
            <Package className="w-6 h-6" />
          </div>
          <div>
            <h3 className="text-sm font-bold text-slate-900">Delivery Sessions are Tenant-Scoped</h3>
            <p className="text-xs text-slate-500 max-w-md mx-auto mt-1">
              Active delivery orders, route assignments, and driver transit sessions are managed within each tenant company's Delivery Control Center.
            </p>
          </div>
          <div className="pt-2">
            <a
              href="https://erp.floraprise.com/delivery-routes"
              target="_blank"
              rel="noopener noreferrer"
              className="inline-flex items-center gap-1.5 px-4 py-2 bg-emerald-600 hover:bg-emerald-500 text-white font-bold text-xs rounded-xl shadow-xs"
            >
              <span>Open ERP Delivery Control Center</span>
              <ExternalLink className="w-3.5 h-3.5" />
            </a>
          </div>
        </div>
      )}
    </div>
  );
};
