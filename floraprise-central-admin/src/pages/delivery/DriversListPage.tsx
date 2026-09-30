import React, { useState, useEffect } from 'react';
import { realDeliveryService } from '../../services/api/realDeliveryService';
import { DeliveryDriver } from '../../types/delivery';
import { DataTable, Column } from '../../components/common/DataTable';
import { StatusBadge } from '../../components/common/StatusBadge';
import { Truck, Phone, Battery, ExternalLink } from 'lucide-react';

export const DriversListPage: React.FC = () => {
  const [drivers, setDrivers] = useState<DeliveryDriver[]>([]);

  useEffect(() => {
    realDeliveryService.getDrivers().then(setDrivers);
  }, []);

  const columns: Column<DeliveryDriver>[] = [
    {
      key: 'name',
      header: 'Driver Name',
      sortable: true,
      render: (d) => (
        <div>
          <div className="font-bold text-slate-900">{d.name}</div>
          <div className="text-[11px] text-slate-500">{d.phone}</div>
        </div>
      )
    },
    {
      key: 'assignedCompanyName',
      header: 'Assigned Subscriber',
      sortable: true,
      render: (d) => <span className="font-semibold text-slate-800">{d.assignedCompanyName}</span>
    },
    {
      key: 'vehicleNumber',
      header: 'Vehicle & Mode',
      render: (d) => (
        <div>
          <div className="font-semibold text-slate-900">{d.vehicleNumber}</div>
          <div className="text-[11px] text-slate-500">{d.vehicleType}</div>
        </div>
      )
    },
    {
      key: 'activeOrdersCount',
      header: 'Active / Completed Today',
      render: (d) => (
        <div>
          <span className="font-bold text-emerald-700">{d.activeOrdersCount} in transit</span>
          <span className="text-slate-400"> / {d.completedTodayCount} delivered</span>
        </div>
      )
    },
    {
      key: 'batteryPercent',
      header: 'Device Status',
      render: (d) => (
        <div className="text-[11px] text-slate-600 space-y-0.5">
          <div className="flex items-center gap-1.5">
            <Battery className="w-3.5 h-3.5 text-slate-400" />
            <span>{d.batteryPercent}% Battery</span>
          </div>
          <div className="text-slate-400">Ping: {d.lastPingAt}</div>
        </div>
      )
    },
    {
      key: 'status',
      header: 'Duty Status',
      sortable: true,
      render: (d) => <StatusBadge status={d.status} size="sm" />
    }
  ];

  return (
    <div className="space-y-4">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h2 className="text-xl font-black text-slate-900 flex items-center gap-2">
            <Truck className="w-5 h-5 text-emerald-600" />
            <span>Delivery Driver Fleet Registry</span>
          </h2>
          <p className="text-xs text-slate-500 mt-0.5">
            Driver profiles, fleet assignments, real-time battery status, and delivery throughput.
          </p>
        </div>

        <a
          href="https://erp.floraprise.com/delivery-routes"
          target="_blank"
          rel="noopener noreferrer"
          className="inline-flex items-center gap-1.5 px-3.5 py-2 text-xs font-bold rounded-xl bg-slate-900 hover:bg-slate-800 text-white shadow-xs"
        >
          <span>Open Delivery Control Center</span>
          <ExternalLink className="w-3.5 h-3.5" />
        </a>
      </div>

      {drivers.length > 0 ? (
        <DataTable
          columns={columns}
          data={drivers}
          searchPlaceholder="Search drivers by name, vehicle number, subscriber..."
          searchableKeys={['name', 'phone', 'vehicleNumber', 'assignedCompanyName']}
        />
      ) : (
        <div className="p-10 bg-white rounded-2xl border border-slate-200 text-center space-y-3">
          <div className="w-12 h-12 rounded-2xl bg-slate-50 text-slate-400 border border-slate-200 mx-auto flex items-center justify-center">
            <Truck className="w-6 h-6" />
          </div>
          <div>
            <h3 className="text-sm font-bold text-slate-900">Drivers are Managed Within Tenant Workspaces</h3>
            <p className="text-xs text-slate-500 max-w-md mx-auto mt-1">
              Store drivers, mobile device bindings, and active shifts are administered per subscriber business inside the ERP Delivery Control Center.
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
