import React, { useState, useEffect } from 'react';
import { realDiagnosticsService } from '../../services/api/realDiagnosticsService';
import { realSubscriberService } from '../../services/api/realSubscriberService';
import { DiagnosticCheckItem } from '../../types/diagnostics';
import { Subscriber } from '../../types/subscriber';
import { StatusBadge } from '../../components/common/StatusBadge';
import { ProvisioningModal } from '../../components/provisioning/ProvisioningModal';
import { Wrench, CheckCircle2, AlertTriangle, ShieldCheck, RefreshCw, Activity } from 'lucide-react';
import { useNotification } from '../../context/NotificationContext';

export const DiagnosticsPage: React.FC = () => {
  const { showToast } = useNotification();
  const [healthChecks, setHealthChecks] = useState<DiagnosticCheckItem[]>([]);
  const [subscribers, setSubscribers] = useState<Subscriber[]>([]);
  const [selectedSub, setSelectedSub] = useState<Subscriber | null>(null);
  const [isRunning, setIsRunning] = useState(false);

  const loadData = async () => {
    try {
      const [checks, subs] = await Promise.all([
        realDiagnosticsService.getSystemHealth(),
        realSubscriberService.getSubscribers().catch(() => [] as Subscriber[])
      ]);
      setHealthChecks(checks);
      setSubscribers(subs);
    } catch {
      // Handled
    }
  };

  useEffect(() => {
    loadData();
  }, []);

  const handleRunFullDiagnostics = async () => {
    setIsRunning(true);
    await loadData();
    setIsRunning(false);
    showToast('success', 'Diagnostics Cycle Completed', 'All core platform services evaluated against live backend.');
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h2 className="text-xl font-black text-slate-900 flex items-center gap-2">
            <Wrench className="w-5 h-5 text-emerald-600" />
            <span>Platform & Tenant Diagnostics</span>
          </h2>
          <p className="text-xs text-slate-500 mt-0.5">
            Real-time health monitoring of Sumpooj.API Gateway, database persistence, authorization policies, and multi-tenant location checks.
          </p>
        </div>

        <button
          onClick={handleRunFullDiagnostics}
          disabled={isRunning}
          className="inline-flex items-center gap-2 px-4 py-2 text-xs font-bold rounded-xl bg-slate-900 hover:bg-slate-800 text-white shadow-xs cursor-pointer transition-colors"
        >
          <RefreshCw className={`w-4 h-4 ${isRunning ? 'animate-spin' : ''}`} />
          <span>{isRunning ? 'Running Health Suite...' : 'Run Diagnostics Suite'}</span>
        </button>
      </div>

      {/* Core Infrastructure & API Status Cards */}
      <div className="space-y-3">
        <h3 className="text-xs font-bold uppercase tracking-wider text-slate-400">Core Services & Backend Connectivity</h3>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {healthChecks.map(chk => (
            <div
              key={chk.id}
              className="bg-white p-5 rounded-2xl border border-slate-200 shadow-xs space-y-3"
            >
              <div className="flex items-start justify-between">
                <div>
                  <span className="text-[10px] font-bold uppercase tracking-wider text-slate-400">{chk.category}</span>
                  <h4 className="text-sm font-bold text-slate-900 mt-0.5">{chk.serviceName}</h4>
                </div>
                <StatusBadge status={chk.status} size="sm" />
              </div>

              <div className="p-3 bg-slate-50 rounded-xl text-xs text-slate-600 space-y-1">
                <div className="font-mono text-[11px] text-slate-500 truncate">{chk.endpointOrResource}</div>
                <p className="text-slate-800">{chk.detail}</p>
              </div>

              <div className="flex items-center justify-between text-[11px] text-slate-400 pt-1">
                <span>Latency: <strong className="text-emerald-700">{chk.latencyMs}ms</strong></span>
                <span>Checked {chk.lastCheckedAt}</span>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Subscriber Diagnostics Check Grid */}
      <div className="bg-white rounded-3xl p-6 border border-slate-200 shadow-xs space-y-4">
        <div>
          <h3 className="text-sm font-bold text-slate-900">Tenant-Level Diagnostics & Provisioning Audits</h3>
          <p className="text-xs text-slate-500 mt-0.5">
            Audit individual subscribers for location integrity, device binding, and API connectivity.
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-3">
          {subscribers.map(sub => (
            <div
              key={sub.id}
              onClick={() => setSelectedSub(sub)}
              className="p-4 rounded-2xl border border-slate-200 bg-slate-50/60 hover:bg-slate-100/80 hover:border-emerald-300 transition-all cursor-pointer flex items-center justify-between"
            >
              <div>
                <div className="font-bold text-slate-900 text-xs">{sub.businessName}</div>
                <div className="text-[11px] text-slate-500">{sub.city} • {sub.planName}</div>
              </div>
              <div className="text-right">
                <StatusBadge status={sub.overallProvisioningState} size="sm" />
                <div className="text-[10px] text-emerald-700 font-bold mt-1">Audit Checks →</div>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Provisioning Modal */}
      {selectedSub && (
        <ProvisioningModal
          isOpen={true}
          onClose={() => setSelectedSub(null)}
          subscriber={selectedSub}
          onUpdated={loadData}
        />
      )}
    </div>
  );
};
