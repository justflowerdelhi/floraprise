import React, { useState, useEffect } from 'react';
import { realSubscriptionService } from '../../services/api/realSubscriptionService';
import { SubscriptionPlan } from '../../types/subscription';
import { StatusBadge } from '../../components/common/StatusBadge';
import { Modal } from '../../components/common/Modal';
import { 
  CreditCard, 
  Check, 
  Sparkles, 
  ShieldCheck, 
  Smartphone, 
  Users, 
  Clock, 
  WifiOff, 
  ShieldAlert,
  Info,
  Layers,
  RefreshCw,
  ExternalLink
} from 'lucide-react';

export const PlansPage: React.FC = () => {
  const [plans, setPlans] = useState<SubscriptionPlan[]>([]);
  const [selectedPlan, setSelectedPlan] = useState<SubscriptionPlan | null>(null);
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);

  const loadPlans = async () => {
    setIsLoading(true);
    setError(null);
    try {
      const data = await realSubscriptionService.getPlans();
      setPlans(data);
    } catch (err: any) {
      setError(err?.message || 'Failed to load subscription plan catalog.');
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    loadPlans();
  }, []);

  if (isLoading && plans.length === 0) {
    return (
      <div className="p-12 text-center text-slate-400 bg-white rounded-2xl border border-slate-200 space-y-3">
        <div className="animate-spin w-8 h-8 border-3 border-emerald-600 border-t-transparent rounded-full mx-auto" />
        <div className="text-xs font-semibold text-slate-600">Loading Commercial Plan Catalog from Sumpooj.API...</div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h2 className="text-xl font-black text-slate-900 flex items-center gap-2">
            <CreditCard className="w-5 h-5 text-emerald-600" />
            <span>Commercial Plan Catalog & Entitlements</span>
          </h2>
          <p className="text-xs text-slate-500 mt-0.5">
            Database-backed subscription source of truth: pricing tiers, offline allowances, device limits, and microservice rules.
          </p>
        </div>
        <button
          onClick={loadPlans}
          className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-xl border border-slate-300 bg-white hover:bg-slate-50 text-slate-700 text-xs font-bold shadow-xs cursor-pointer"
        >
          <RefreshCw className="w-3.5 h-3.5" />
          <span>Refresh Catalog</span>
        </button>
      </div>

      {error && (
        <div className="p-4 rounded-2xl bg-rose-50 border border-rose-200 text-xs text-rose-900 flex items-center justify-between">
          <div>{error}</div>
          <button onClick={loadPlans} className="font-bold underline cursor-pointer">Retry</button>
        </div>
      )}

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {plans.map(plan => (
          <div
            key={plan.id}
            className={`bg-white rounded-3xl p-6 border flex flex-col justify-between transition-all ${
              plan.isPopular 
                ? 'border-emerald-500 shadow-lg shadow-emerald-500/10 ring-2 ring-emerald-500/20' 
                : 'border-slate-200 shadow-xs hover:shadow-md'
            }`}
          >
            <div className="space-y-4">
              <div className="flex items-center justify-between">
                <span className="font-mono text-[10px] font-bold text-slate-400 bg-slate-100 px-2 py-0.5 rounded-md">
                  {plan.code}
                </span>
                <StatusBadge status={plan.isActive ? 'Active' : 'Inactive'} size="sm" />
              </div>

              <div>
                <div className="flex items-center gap-1.5">
                  <h3 className="text-base font-extrabold text-slate-900">{plan.name}</h3>
                  <span className="text-[10px] font-bold px-2 py-0.5 rounded-full bg-slate-100 text-slate-700">
                    {plan.planType}
                  </span>
                </div>
                <p className="text-xs text-slate-500 mt-1 min-h-[36px]">{plan.description}</p>
              </div>

              {/* Price display */}
              <div className="pt-2 border-t border-slate-100">
                <div className="text-2xl font-black text-slate-900">
                  {(plan.annualPrice ?? 0) === 0 && (plan.monthlyPrice ?? 0) === 0 
                    ? 'Free' 
                    : `₹${((plan.annualPrice ?? 0) || (plan.monthlyPrice ?? 0)).toLocaleString('en-IN')}`}
                </div>
                <span className="text-xs text-slate-400 font-medium">
                  {plan.code === 'MOBILE_TRIAL' ? `for ${plan.trialDays ?? 7} Days` : `/ ${plan.billingCycle} billing`}
                </span>
              </div>

              {/* Limits & Rules */}
              <div className="p-3.5 bg-slate-50 rounded-2xl border border-slate-100 text-xs space-y-2">
                <div className="flex justify-between items-center">
                  <span className="text-slate-500 flex items-center gap-1">
                    <Smartphone className="w-3.5 h-3.5 text-slate-400" />
                    <span>Max Devices:</span>
                  </span>
                  <strong className="text-slate-900">{plan.maximumDevices} Devices</strong>
                </div>
                <div className="flex justify-between items-center">
                  <span className="text-slate-500 flex items-center gap-1">
                    <Users className="w-3.5 h-3.5 text-slate-400" />
                    <span>Staff Limit:</span>
                  </span>
                  <strong className="text-slate-900">{plan.maximumStaff} Staff</strong>
                </div>
                <div className="flex justify-between items-center">
                  <span className="text-slate-500 flex items-center gap-1">
                    <WifiOff className="w-3.5 h-3.5 text-slate-400" />
                    <span>Offline Days:</span>
                  </span>
                  <strong className="text-slate-900">{plan.offlineDays} Days</strong>
                </div>
                <div className="flex justify-between items-center">
                  <span className="text-slate-500 flex items-center gap-1">
                    <ShieldAlert className="w-3.5 h-3.5 text-slate-400" />
                    <span>Grace Period:</span>
                  </span>
                  <strong className="text-slate-900">{plan.graceDays} Days</strong>
                </div>
              </div>

              {/* Included Services */}
              <div className="space-y-1.5 pt-1">
                <div className="text-[10px] font-bold uppercase tracking-wider text-slate-400">Included Services</div>
                {plan.includedServices.slice(0, 3).map(srv => (
                  <div key={srv} className="flex items-center gap-1.5 text-[11px] text-slate-700">
                    <Check className="w-3 h-3 text-emerald-600 shrink-0" />
                    <span>{srv}</span>
                  </div>
                ))}
              </div>
            </div>

            <div className="pt-4 mt-4 border-t border-slate-100">
              <button
                onClick={() => setSelectedPlan(plan)}
                className={`w-full py-2.5 rounded-xl text-xs font-bold transition-colors cursor-pointer ${
                  plan.isPopular 
                    ? 'bg-emerald-600 hover:bg-emerald-700 text-white shadow-xs' 
                    : 'bg-slate-100 hover:bg-slate-200 text-slate-800'
                }`}
              >
                View Plan Details
              </button>
            </div>
          </div>
        ))}
      </div>

      {/* Plan Details Modal */}
      {selectedPlan && (
        <Modal
          isOpen={Boolean(selectedPlan)}
          onClose={() => setSelectedPlan(null)}
          title={`Plan Specification: ${selectedPlan.name}`}
          maxWidth="md"
          actions={
            <button
              onClick={() => setSelectedPlan(null)}
              className="px-4 py-2 text-xs font-bold bg-slate-900 hover:bg-slate-800 text-white rounded-xl cursor-pointer"
            >
              Close
            </button>
          }
        >
          <div className="space-y-5 text-xs">
            {/* Header info */}
            <div className="p-4 bg-slate-50 rounded-2xl border border-slate-200 space-y-2">
              <div className="flex items-center justify-between">
                <div>
                  <h4 className="text-base font-extrabold text-slate-900">{selectedPlan.name}</h4>
                  <div className="text-slate-500 text-[11px] font-mono">Code: {selectedPlan.code} • Plan ID: {selectedPlan.id}</div>
                </div>
                <StatusBadge status={selectedPlan.isActive ? 'Active' : 'Inactive'} size="md" />
              </div>
              <p className="text-slate-600 text-xs pt-1">{selectedPlan.description}</p>
            </div>

            {/* Pricing Details */}
            <div className="space-y-2">
              <h5 className="font-bold uppercase tracking-wider text-slate-400 text-[10px]">Commercial Pricing Matrix</h5>
              <div className="grid grid-cols-3 gap-3">
                <div className="p-3 bg-white rounded-xl border border-slate-200">
                  <span className="text-[10px] text-slate-400 block">Monthly Price</span>
                  <strong className="text-slate-900 text-sm">
                    {(selectedPlan.monthlyPrice ?? 0) > 0 ? `₹${(selectedPlan.monthlyPrice ?? 0).toLocaleString('en-IN')}` : 'N/A'}
                  </strong>
                </div>
                <div className="p-3 bg-white rounded-xl border border-slate-200">
                  <span className="text-[10px] text-slate-400 block">Annual Price</span>
                  <strong className="text-slate-900 text-sm">
                    {(selectedPlan.annualPrice ?? 0) > 0 ? `₹${(selectedPlan.annualPrice ?? 0).toLocaleString('en-IN')}` : 'N/A'}
                  </strong>
                </div>
                <div className="p-3 bg-white rounded-xl border border-slate-200">
                  <span className="text-[10px] text-slate-400 block">Lifetime Price</span>
                  <strong className="text-slate-900 text-sm">
                    {(selectedPlan.lifetimePrice ?? 0) > 0 ? `₹${(selectedPlan.lifetimePrice ?? 0).toLocaleString('en-IN')}` : 'N/A'}
                  </strong>
                </div>
              </div>
            </div>

            {/* Quotas and Operational Tolerance */}
            <div className="space-y-2">
              <h5 className="font-bold uppercase tracking-wider text-slate-400 text-[10px]">Quotas & Tolerance Rules</h5>
              <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
                <div className="p-3 bg-white rounded-xl border border-slate-200">
                  <span className="text-[10px] text-slate-400 block">Max Devices</span>
                  <strong className="text-slate-900">{selectedPlan.maximumDevices} POS/Web</strong>
                </div>
                <div className="p-3 bg-white rounded-xl border border-slate-200">
                  <span className="text-[10px] text-slate-400 block">Max Staff</span>
                  <strong className="text-slate-900">{selectedPlan.maximumStaff} Accounts</strong>
                </div>
                <div className="p-3 bg-white rounded-xl border border-slate-200">
                  <span className="text-[10px] text-slate-400 block">Offline Days</span>
                  <strong className="text-slate-900">{selectedPlan.offlineDays} Days Grace</strong>
                </div>
                <div className="p-3 bg-white rounded-xl border border-slate-200">
                  <span className="text-[10px] text-slate-400 block">Renewal Grace</span>
                  <strong className="text-slate-900">{selectedPlan.graceDays} Days</strong>
                </div>
              </div>
            </div>

            {/* Included Microservices */}
            <div className="space-y-2">
              <h5 className="font-bold uppercase tracking-wider text-slate-400 text-[10px]">Cloud Microservices & Entitlements</h5>
              <div className="p-3.5 bg-slate-50 rounded-2xl border border-slate-200 space-y-1.5">
                {selectedPlan.includedServices.map(srv => (
                  <div key={srv} className="flex items-center gap-2 text-slate-700">
                    <Check className="w-4 h-4 text-emerald-600 shrink-0" />
                    <span className="font-medium">{srv}</span>
                  </div>
                ))}
              </div>
            </div>

            {/* Safety Notice */}
            <div className="p-3.5 bg-amber-50 border border-amber-200 rounded-xl text-amber-900 text-[11px] flex items-start gap-2">
              <Info className="w-4 h-4 text-amber-600 shrink-0 mt-0.5" />
              <div>
                <strong>Immutable Source of Truth:</strong> Commercial plan specifications are governed by Sumpooj.API database seed and server configurations. Active plans are automatically assigned during subscriber onboarding and renewal cycles.
              </div>
            </div>
          </div>
        </Modal>
      )}
    </div>
  );
};
