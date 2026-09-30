import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { realSubscriberService } from '../../services/api/realSubscriberService';
import { Subscriber } from '../../types/subscriber';
import { StatusBadge } from '../../components/common/StatusBadge';
import { ProvisioningModal } from '../../components/provisioning/ProvisioningModal';
import { ShieldCheck, CheckCircle2, AlertTriangle, XCircle, Wrench, RefreshCw, Store } from 'lucide-react';
import { useNotification } from '../../context/NotificationContext';

export const ProvisioningHealthPage: React.FC = () => {
  const navigate = useNavigate();
  const { showToast } = useNotification();
  const [subscribers, setSubscribers] = useState<Subscriber[]>([]);
  const [selectedSubscriber, setSelectedSubscriber] = useState<Subscriber | null>(null);
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);

  const loadData = async () => {
    setIsLoading(true);
    setError(null);
    try {
      const data = await realSubscriberService.getProvisioningHealth();
      setSubscribers(data);
    } catch (err: any) {
      setError(err?.message || 'Unable to fetch provisioning matrix from backend.');
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    loadData();
  }, []);

  const handleFixLocationQuick = async (sub: Subscriber) => {
    const updated = await realSubscriberService.autoRemediateLocation(sub.id);
    if (updated) {
      showToast('success', 'Default Location Created', `Provisioned "Main Store" (MAIN-01) for ${sub.businessName}.`);
      loadData();
    }
  };

  const checkKeys = [
    { key: 'company', label: 'Company' },
    { key: 'owner', label: 'Owner' },
    { key: 'profile', label: 'Profile' },
    { key: 'location', label: 'Location' },
    { key: 'subscription', label: 'Subscription' },
    { key: 'license', label: 'License' },
    { key: 'cloud_profile', label: 'Cloud Context' },
    { key: 'device_entitlement', label: 'Device Entitlements' },
    { key: 'delivery_config', label: 'Delivery' },
    { key: 'required_settings', label: 'Settings' }
  ];

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h2 className="text-xl font-black text-slate-900 flex items-center gap-2">
            <ShieldCheck className="w-6 h-6 text-emerald-600" />
            <span>Subscriber Provisioning Health Matrix</span>
          </h2>
          <p className="text-xs text-slate-500 mt-0.5">
            Systematic 10-point audit matrix preventing broken tenants, orphan companies, and missing locations.
          </p>
        </div>

        <button
          onClick={loadData}
          disabled={isLoading}
          className="inline-flex items-center gap-1.5 px-3 py-2 text-xs font-semibold rounded-xl border border-slate-200 bg-white hover:bg-slate-50 text-slate-700 shadow-xs cursor-pointer disabled:opacity-50"
        >
          <RefreshCw className={`w-4 h-4 text-slate-400 ${isLoading ? 'animate-spin text-emerald-600' : ''}`} />
          <span>Re-evaluate All</span>
        </button>
      </div>

      {/* Error Banner */}
      {error && (
        <div className="p-4 rounded-2xl bg-rose-50 border border-rose-200 text-rose-900 flex items-start justify-between gap-3">
          <div className="flex items-start gap-2.5">
            <AlertTriangle className="w-5 h-5 text-rose-600 shrink-0 mt-0.5" />
            <div>
              <div className="font-bold text-sm text-rose-950">Unable to load provisioning matrix</div>
              <div className="text-xs text-rose-700 mt-0.5">{error}</div>
            </div>
          </div>
          <button
            onClick={loadData}
            className="px-3 py-1.5 bg-rose-600 hover:bg-rose-700 text-white font-bold text-xs rounded-xl shadow-xs shrink-0 cursor-pointer"
          >
            Retry
          </button>
        </div>
      )}

      {/* Overview Table / Loading */}
      {isLoading ? (
        <div className="p-12 text-center text-slate-400 bg-white rounded-2xl border border-slate-200 space-y-3">
          <div className="animate-spin w-8 h-8 border-3 border-emerald-600 border-t-transparent rounded-full mx-auto" />
          <div className="text-xs font-semibold text-slate-600">Evaluating 10-point provisioning matrix from Sumpooj.API...</div>
        </div>
      ) : (
      <div className="bg-white rounded-2xl border border-slate-200 shadow-xs overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs text-slate-600">
            <thead className="bg-slate-50/80 text-slate-500 uppercase font-semibold text-[11px] tracking-wider border-b border-slate-200">
              <tr>
                <th className="py-3.5 px-4">Subscriber</th>
                <th className="py-3.5 px-4 text-center">Status</th>
                {checkKeys.map(c => (
                  <th key={c.key} className="py-3.5 px-2 text-center text-[10px]">
                    {c.label}
                  </th>
                ))}
                <th className="py-3.5 px-4 text-center">Overall</th>
                <th className="py-3.5 px-4 text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {subscribers.map(sub => {
                const checksMap = new Map(sub.provisioningChecks.map(c => [c.key, c]));
                const isLocationMissing = sub.locations.length === 0;

                return (
                  <tr key={sub.id} className="hover:bg-slate-50/80 transition-colors">
                    <td className="py-3.5 px-4">
                      <div 
                        onClick={() => navigate(`/subscribers/${sub.id}`)}
                        className="font-bold text-slate-900 hover:text-emerald-700 cursor-pointer"
                      >
                        {sub.businessName}
                      </div>
                      <div className="text-[11px] text-slate-400">{sub.city} • {sub.mobile}</div>
                    </td>

                    <td className="py-3.5 px-4 text-center">
                      <StatusBadge status={sub.status} size="sm" />
                    </td>

                    {/* 10 Individual Check Pills */}
                    {checkKeys.map(c => {
                      const check = checksMap.get(c.key);
                      const isReady = check?.status === 'READY';
                      const isNeedsAttention = check?.status === 'NEEDS ATTENTION';
                      
                      return (
                        <td key={c.key} className="py-3.5 px-2 text-center">
                          {isReady ? (
                            <span className="inline-flex items-center justify-center w-5 h-5 rounded-full bg-emerald-100 text-emerald-700 font-bold text-[10px]" title={`${c.label}: PASSED`}>
                              ✓
                            </span>
                          ) : isNeedsAttention ? (
                            <span className="inline-flex items-center justify-center w-5 h-5 rounded-full bg-amber-100 text-amber-700 font-bold text-[10px]" title={`${c.label}: ${check?.problem || 'Warning'}`}>
                              !
                            </span>
                          ) : (
                            <span className="inline-flex items-center justify-center w-5 h-5 rounded-full bg-rose-100 text-rose-700 font-bold text-[10px]" title={`${c.label}: ${check?.problem || 'Failed'}`}>
                              ✕
                            </span>
                          )}
                        </td>
                      );
                    })}

                    <td className="py-3.5 px-4 text-center">
                      <span className={`inline-block px-2.5 py-1 rounded-full text-[10px] font-bold ${
                        sub.overallProvisioningState === 'READY'
                          ? 'bg-emerald-100 text-emerald-800'
                          : sub.overallProvisioningState === 'NEEDS ATTENTION'
                          ? 'bg-amber-100 text-amber-800'
                          : 'bg-rose-100 text-rose-800'
                      }`}>
                        {sub.overallProvisioningState}
                      </span>
                    </td>

                    <td className="py-3.5 px-4 text-right">
                      <div className="flex items-center justify-end gap-1.5">
                        {isLocationMissing && (
                          <button
                            onClick={() => handleFixLocationQuick(sub)}
                            className="inline-flex items-center gap-1 px-2 py-1 rounded-lg text-[11px] font-bold bg-amber-600 hover:bg-amber-700 text-white cursor-pointer shadow-xs"
                            title="Auto-create Main Store location"
                          >
                            <Store className="w-3.5 h-3.5" />
                            <span>Fix Loc</span>
                          </button>
                        )}
                        <button
                          onClick={() => setSelectedSubscriber(sub)}
                          className="px-2.5 py-1 rounded-lg text-xs font-semibold bg-slate-100 hover:bg-slate-200 text-slate-700 cursor-pointer"
                        >
                          Audit →
                        </button>
                      </div>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </div>
      )}

      {/* Provisioning Modal */}
      {selectedSubscriber && (
        <ProvisioningModal
          isOpen={true}
          onClose={() => setSelectedSubscriber(null)}
          subscriber={selectedSubscriber}
          onUpdated={loadData}
        />
      )}
    </div>
  );
};
