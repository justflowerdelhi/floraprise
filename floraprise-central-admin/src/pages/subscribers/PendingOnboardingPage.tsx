import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { realSubscriberService } from '../../services/api/realSubscriberService';
import { Subscriber } from '../../types/subscriber';
import { StatusBadge } from '../../components/common/StatusBadge';
import { ProvisioningModal } from '../../components/provisioning/ProvisioningModal';
import { OnboardingWizardModal } from '../../components/onboarding/OnboardingWizardModal';
import { Clock, ShieldCheck, ArrowRight, Store, AlertTriangle, CheckCircle, Sparkles } from 'lucide-react';

export const PendingOnboardingPage: React.FC = () => {
  const navigate = useNavigate();
  const [pendingSubscribers, setPendingSubscribers] = useState<Subscriber[]>([]);
  const [selectedForCheck, setSelectedForCheck] = useState<Subscriber | null>(null);
  const [wizardData, setWizardData] = useState<any | null>(null);
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);

  const loadData = async () => {
    setIsLoading(true);
    setError(null);
    try {
      const subs = await realSubscriberService.getPendingOnboarding();
      setPendingSubscribers(subs);
    } catch (err: any) {
      setError(err?.message || 'Unable to fetch pending onboarding queue.');
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    loadData();
  }, []);

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-xl font-black text-slate-900 flex items-center gap-2">
          <Clock className="w-5 h-5 text-amber-600" />
          <span>Pending Onboarding Queue</span>
        </h2>
        <p className="text-xs text-slate-500 mt-0.5">
          Self-registered florists awaiting Central Admin provisioning verification, Default Location setup, and activation.
        </p>
      </div>

      {/* Error Banner */}
      {error && (
        <div className="p-4 rounded-2xl bg-rose-50 border border-rose-200 text-rose-900 flex items-start justify-between gap-3">
          <div className="flex items-start gap-2.5">
            <AlertTriangle className="w-5 h-5 text-rose-600 shrink-0 mt-0.5" />
            <div>
              <div className="font-bold text-sm text-rose-950">Unable to load pending queue</div>
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

      {/* Content */}
      {isLoading ? (
        <div className="p-12 text-center text-slate-400 bg-white rounded-2xl border border-slate-200 space-y-3">
          <div className="animate-spin w-8 h-8 border-3 border-emerald-600 border-t-transparent rounded-full mx-auto" />
          <div className="text-xs font-semibold text-slate-600">Loading pending subscribers from Sumpooj.API...</div>
        </div>
      ) : pendingSubscribers.length > 0 ? (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {pendingSubscribers.map(sub => {
            const failingChecks = sub.provisioningChecks.filter(c => !c.passed);
            const isLocationMissing = sub.locations.length === 0;

            return (
              <div
                key={sub.id}
                className="bg-white p-5 rounded-2xl border border-slate-200 shadow-xs hover:shadow-md transition-all space-y-4"
              >
                <div className="flex items-start justify-between gap-3">
                  <div>
                    <div className="font-extrabold text-base text-slate-900">{sub.businessName}</div>
                    <div className="text-xs text-slate-500 mt-0.5">{sub.ownerName} • {sub.mobile}</div>
                    <div className="text-[11px] text-slate-400">{sub.address}, {sub.city}, {sub.state}</div>
                  </div>
                  <StatusBadge status={sub.status} size="sm" />
                </div>

                {/* Provisioning Warning Box */}
                {isLocationMissing && (
                  <div className="p-3 bg-amber-50 border border-amber-200 rounded-xl text-xs text-amber-900 flex items-start gap-2.5">
                    <Store className="w-4 h-4 text-amber-600 shrink-0 mt-0.5" />
                    <div>
                      <span className="font-bold">Missing Default Location:</span> No store configured in database. Must provision <code>"Main Store"</code> prior to activation.
                    </div>
                  </div>
                )}

                {/* Status checklist */}
                <div className="p-3 bg-slate-50 rounded-xl border border-slate-100 text-xs space-y-1.5">
                  <div className="flex justify-between">
                    <span className="text-slate-500">Plan Requested:</span>
                    <span className="font-bold text-slate-900">{sub.planName}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-slate-500">Registered:</span>
                    <span className="text-slate-700">{sub.createdAt.substring(0, 10)} ({sub.lastActivityAt})</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-slate-500">Provisioning Readiness:</span>
                    <span className={`font-bold ${failingChecks.length === 0 ? 'text-emerald-700' : 'text-amber-700'}`}>
                      {10 - failingChecks.length} / 10 Checks Passed
                    </span>
                  </div>
                </div>

                {/* Actions */}
                <div className="pt-1 flex items-center justify-between gap-3 border-t border-slate-100">
                  <button
                    onClick={() => setSelectedForCheck(sub)}
                    className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-xl border border-slate-200 text-xs font-semibold text-slate-700 hover:bg-slate-50 cursor-pointer transition-colors"
                  >
                    <ShieldCheck className="w-4 h-4 text-emerald-600" />
                    <span>Audit Provisioning</span>
                  </button>

                  <button
                    onClick={() => setWizardData(sub)}
                    className="inline-flex items-center gap-1.5 px-4 py-2 rounded-xl bg-slate-900 hover:bg-slate-800 text-white text-xs font-bold cursor-pointer transition-colors"
                  >
                    <span>Complete Onboarding</span>
                    <ArrowRight className="w-4 h-4" />
                  </button>
                </div>
              </div>
            );
          })}
        </div>
      ) : (
        <div className="bg-white p-12 rounded-2xl border border-slate-200 text-center space-y-2">
          <div className="w-12 h-12 rounded-2xl bg-emerald-100 text-emerald-700 flex items-center justify-center mx-auto">
            <CheckCircle className="w-6 h-6" />
          </div>
          <h3 className="text-base font-bold text-slate-900">All Registered Subscribers Onboarded</h3>
          <p className="text-xs text-slate-500 max-w-sm mx-auto">
            There are currently zero pending subscriber registrations in the queue.
          </p>
        </div>
      )}

      {/* Provisioning Modal */}
      {selectedForCheck && (
        <ProvisioningModal
          isOpen={true}
          onClose={() => setSelectedForCheck(null)}
          subscriber={selectedForCheck}
          onUpdated={loadData}
        />
      )}

      {/* Wizard Modal */}
      {wizardData && (
        <OnboardingWizardModal
          isOpen={true}
          onClose={() => setWizardData(null)}
          initialData={wizardData}
          onSubscriberCreated={() => {
            setWizardData(null);
            loadData();
          }}
        />
      )}
    </div>
  );
};
