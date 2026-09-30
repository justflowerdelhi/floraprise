import React, { useState, useEffect } from 'react';
import { realDeliveryService, DeliverySubsystemStatus } from '../../services/api/realDeliveryService';
import { Truck, MapPin, Navigation, ExternalLink, ShieldCheck, Radio, Smartphone, Layers, CheckCircle2, AlertCircle } from 'lucide-react';

export const LiveTrackingPage: React.FC = () => {
  const [status, setStatus] = useState<DeliverySubsystemStatus | null>(null);

  useEffect(() => {
    realDeliveryService.getSummary().then(setStatus);
  }, []);

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h2 className="text-xl font-black text-slate-900 flex items-center gap-2">
            <Truck className="w-5 h-5 text-emerald-600" />
            <span>Delivery Fleet & Route Operations</span>
          </h2>
          <p className="text-xs text-slate-500 mt-0.5">
            Overview of Floraprise last-mile delivery architecture, driver dispatching, and live tracking hubs.
          </p>
        </div>

        <a
          href="https://erp.floraprise.com/delivery-routes"
          target="_blank"
          rel="noopener noreferrer"
          className="inline-flex items-center gap-1.5 px-4 py-2 text-xs font-bold rounded-xl bg-slate-900 hover:bg-slate-800 text-white shadow-xs transition-colors cursor-pointer"
        >
          <span>Open Delivery Control Center</span>
          <ExternalLink className="w-3.5 h-3.5" />
        </a>
      </div>

      {/* Tenant-Scoped Architecture Banner */}
      <div className="bg-gradient-to-r from-slate-900 via-slate-800 to-emerald-950 rounded-3xl p-6 text-white shadow-lg relative overflow-hidden">
        <div className="relative z-10 space-y-3 max-w-2xl">
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-emerald-500/20 text-emerald-400 border border-emerald-500/30 text-xs font-semibold">
            <ShieldCheck className="w-3.5 h-3.5" />
            <span>Delivery Subsystem: Tenant-Scoped Operation</span>
          </div>

          <h3 className="text-lg md:text-xl font-bold text-white">
            Live Route Planning & Telemetry is Managed in the ERP Delivery Control Center
          </h3>

          <p className="text-xs text-slate-300 leading-relaxed">
            Floraprise delivery dispatching, multi-stop route optimization, driver assignments, and live GPS streaming are isolated per tenant to preserve strict business privacy and operational security.
          </p>

          <div className="pt-2 flex flex-wrap gap-3">
            <a
              href="https://erp.floraprise.com/delivery-routes"
              target="_blank"
              rel="noopener noreferrer"
              className="inline-flex items-center gap-1.5 px-4 py-2 bg-emerald-600 hover:bg-emerald-500 text-white text-xs font-bold rounded-xl shadow-xs transition-colors"
            >
              <span>Launch Delivery Control Center</span>
              <ExternalLink className="w-3.5 h-3.5" />
            </a>
          </div>
        </div>
      </div>

      {/* 4 Architectural Pillar Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 text-xs">
        <div className="bg-white p-5 rounded-2xl border border-slate-200/80 shadow-xs space-y-2">
          <div className="w-9 h-9 rounded-xl bg-emerald-50 text-emerald-700 flex items-center justify-center font-bold">
            <MapPin className="w-4 h-4" />
          </div>
          <div className="font-bold text-slate-900">1. Route Optimization</div>
          <div className="text-slate-500 text-[11px] leading-relaxed">
            Multi-order batching with Google Maps Platform route calculation, distance matrix estimation, and geofenced store radius.
          </div>
        </div>

        <div className="bg-white p-5 rounded-2xl border border-slate-200/80 shadow-xs space-y-2">
          <div className="w-9 h-9 rounded-xl bg-sky-50 text-sky-700 flex items-center justify-center font-bold">
            <Smartphone className="w-4 h-4" />
          </div>
          <div className="font-bold text-slate-900">2. Driver Mobile App</div>
          <div className="text-slate-500 text-[11px] leading-relaxed">
            Native Android and Web Driver App for pickup verification, turn-by-turn navigation, customer calls, and proof-of-delivery photos.
          </div>
        </div>

        <div className="bg-white p-5 rounded-2xl border border-slate-200/80 shadow-xs space-y-2">
          <div className="w-9 h-9 rounded-xl bg-amber-50 text-amber-700 flex items-center justify-center font-bold">
            <Radio className="w-4 h-4" />
          </div>
          <div className="font-bold text-slate-900">3. SignalR Real-Time Hub</div>
          <div className="text-slate-500 text-[11px] leading-relaxed">
            Sub-second live coordinate broadcasts from driver devices to the tenant dispatch map console during active trips.
          </div>
        </div>

        <div className="bg-white p-5 rounded-2xl border border-slate-200/80 shadow-xs space-y-2">
          <div className="w-9 h-9 rounded-xl bg-purple-50 text-purple-700 flex items-center justify-center font-bold">
            <Navigation className="w-4 h-4" />
          </div>
          <div className="font-bold text-slate-900">4. Customer Tracking Portal</div>
          <div className="text-slate-500 text-[11px] leading-relaxed">
            SMS and WhatsApp branded tracking links enabling flower recipients to monitor arriving drivers in real time.
          </div>
        </div>
      </div>

      {/* Integration Notice & Status */}
      <div className="p-5 bg-white rounded-2xl border border-slate-200/80 shadow-xs flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div className="flex items-start gap-3">
          <div className="p-2 rounded-xl bg-emerald-50 text-emerald-700 shrink-0">
            <CheckCircle2 className="w-5 h-5" />
          </div>
          <div className="space-y-0.5">
            <div className="text-sm font-bold text-slate-900">Delivery Subsystem Status</div>
            <div className="text-xs text-slate-500">
              API routes: <code>/api/delivery/control-center</code> and <code>/api/delivery/routes</code> are operational and authenticated via <code>PolicyNames.CompanyOnly</code>.
            </div>
          </div>
        </div>

        <a
          href="https://erp.floraprise.com/delivery-routes"
          target="_blank"
          rel="noopener noreferrer"
          className="inline-flex items-center gap-1.5 px-4 py-2 text-xs font-bold text-emerald-700 hover:text-emerald-800 bg-emerald-50 hover:bg-emerald-100 rounded-xl border border-emerald-200 transition-colors shrink-0"
        >
          <span>Open Control Center</span>
          <ExternalLink className="w-3.5 h-3.5" />
        </a>
      </div>
    </div>
  );
};
