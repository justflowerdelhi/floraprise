import React, { useState, useEffect } from 'react';
import { useNavigate, useOutletContext } from 'react-router-dom';
import { 
  Users, 
  Smartphone, 
  Truck, 
  AlertTriangle, 
  CheckCircle2, 
  Clock, 
  CreditCard, 
  Plus, 
  Search, 
  Wrench, 
  ExternalLink,
  ArrowRight,
  ShieldCheck,
  Building2,
  ChevronRight,
  Activity,
  Layers,
  Sparkles,
  RefreshCw
} from 'lucide-react';
import { realDashboardService, DashboardMetrics } from '../../services/api/realDashboardService';
import { realSubscriberService } from '../../services/api/realSubscriberService';
import { Subscriber } from '../../types/subscriber';
import { MetricCard } from '../../components/common/MetricCard';
import { StatusBadge } from '../../components/common/StatusBadge';
import { ProvisioningModal } from '../../components/provisioning/ProvisioningModal';

export const DashboardPage: React.FC = () => {
  const navigate = useNavigate();
  const outletContext = useOutletContext<{ onOpenOnboarding?: () => void }>();
  const [metrics, setMetrics] = useState<DashboardMetrics | null>(null);
  const [recentSubscribers, setRecentSubscribers] = useState<Subscriber[]>([]);
  const [selectedSubscriberForCheck, setSelectedSubscriberForCheck] = useState<Subscriber | null>(null);
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [isLive, setIsLive] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);

  const loadData = async () => {
    setIsLoading(true);
    setError(null);
    try {
      const res = await realDashboardService.getMetrics();
      setMetrics(res.metrics);
      setIsLive(res.isLive);
      if (res.error) setError(res.error);

      const subs = await realSubscriberService.getSubscribers().catch(() => []);
      setRecentSubscribers(subs.slice(0, 5));
    } catch (err: any) {
      setError(err?.message || 'Failed to load dashboard metrics.');
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    loadData();
  }, []);

  if (isLoading && !metrics) {
    return (
      <div className="p-12 text-center text-slate-400 bg-white rounded-2xl border border-slate-200 space-y-3">
        <div className="animate-spin w-8 h-8 border-3 border-emerald-600 border-t-transparent rounded-full mx-auto" />
        <div className="text-xs font-semibold text-slate-600">Connecting to Sumpooj.API Live Telemetry...</div>
      </div>
    );
  }

  if (!metrics) {
    return (
      <div className="p-8 text-center text-slate-400">
        <div className="animate-spin w-6 h-6 border-2 border-emerald-600 border-t-transparent rounded-full mx-auto mb-2" />
        <span>Loading Central Admin Dashboard...</span>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Welcome Banner */}
      <div className="bg-gradient-to-r from-slate-900 via-slate-800 to-emerald-950 rounded-3xl p-6 md:p-8 text-white shadow-lg relative overflow-hidden">
        <div className="absolute right-0 top-0 bottom-0 w-1/3 bg-[radial-gradient(ellipse_at_top_right,_var(--tw-gradient-stops))] from-emerald-500/10 via-transparent to-transparent pointer-events-none" />

        <div className="relative z-10 flex flex-col md:flex-row md:items-center justify-between gap-6">
          <div className="space-y-2 max-w-2xl">
            <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-emerald-500/20 text-emerald-400 border border-emerald-500/30 text-xs font-semibold">
              <Sparkles className="w-3.5 h-3.5" />
              <span>Platform Health: 100% Operational</span>
            </div>
            <h1 className="text-2xl md:text-3xl font-black tracking-tight text-white">
              Floraprise Central Control
            </h1>
            <p className="text-xs md:text-sm text-slate-300 leading-relaxed">
              Unified administration platform for multi-tenant subscription provisioning, client applications (Solo, Cloud Android, Web), and real-time delivery telemetry.
            </p>
          </div>

          <div className="flex flex-wrap items-center gap-3 shrink-0">
            <button
              onClick={() => outletContext?.onOpenOnboarding ? outletContext.onOpenOnboarding() : navigate('/subscribers/pending')}
              className="inline-flex items-center gap-2 px-4 py-2.5 bg-emerald-600 hover:bg-emerald-500 text-white text-xs font-bold rounded-xl shadow-lg shadow-emerald-950/40 transition-all cursor-pointer"
            >
              <Plus className="w-4 h-4" />
              <span>Onboard Subscriber</span>
            </button>
            <button
              onClick={() => navigate('/subscribers/provisioning')}
              className="inline-flex items-center gap-2 px-4 py-2.5 bg-slate-800 hover:bg-slate-700 text-slate-200 text-xs font-bold rounded-xl border border-slate-700 transition-colors cursor-pointer"
            >
              <ShieldCheck className="w-4 h-4 text-emerald-400" />
              <span>Provisioning Matrix</span>
            </button>
          </div>
        </div>
      </div>

      {/* Backend Alert Banner if Offline or Error */}
      {error && (
        <div className="p-4 rounded-2xl bg-amber-50 border border-amber-200 text-amber-900 flex items-start justify-between gap-3">
          <div className="flex items-start gap-2.5">
            <AlertTriangle className="w-5 h-5 text-amber-600 shrink-0 mt-0.5" />
            <div>
              <div className="font-bold text-xs text-amber-950">Backend Telemetry Notice</div>
              <div className="text-xs text-amber-700 mt-0.5">{error}</div>
            </div>
          </div>
          <button
            onClick={loadData}
            className="inline-flex items-center gap-1.5 px-3 py-1.5 bg-amber-600 hover:bg-amber-700 text-white font-bold text-xs rounded-xl shadow-xs shrink-0 cursor-pointer"
          >
            <RefreshCw className="w-3.5 h-3.5" />
            <span>Refresh</span>
          </button>
        </div>
      )}

      {/* 4 Core Summary Metrics */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <MetricCard
          title="Total Subscribers"
          value={metrics.totalSubscribers}
          subtitle="All registered businesses"
          icon={Building2}
          variant="slate"
          onClick={() => navigate('/subscribers')}
        />
        <MetricCard
          title="Active Subscribers"
          value={metrics.activeSubscribers}
          subtitle="Fully provisioned & billing"
          trend={{ value: '100%', isPositive: true, label: 'healthy' }}
          icon={CheckCircle2}
          variant="emerald"
          onClick={() => navigate('/subscribers')}
        />
        <MetricCard
          title="Active Devices"
          value={metrics.activeDevicesCount}
          subtitle="Online POS & Web sessions"
          icon={Smartphone}
          variant="sky"
          onClick={() => navigate('/devices')}
        />
        <MetricCard
          title="Delivery Subsystem"
          value={metrics.activeDeliveriesCount > 0 ? `${metrics.activeDeliveriesCount} Active` : 'Tenant-Scoped'}
          subtitle="Managed in ERP Control Center"
          icon={Truck}
          variant="amber"
          onClick={() => navigate('/delivery/live')}
        />
      </div>

      {/* Grid: Onboarding & Subscription Summaries */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Onboarding & Provisioning Attention Card */}
        <div className="bg-white p-5 rounded-2xl border border-slate-200/80 shadow-xs space-y-4">
          <div className="flex items-center justify-between">
            <h3 className="text-sm font-bold text-slate-900 flex items-center gap-2">
              <ShieldCheck className="w-4 h-4 text-emerald-600" />
              <span>Onboarding & Health</span>
            </h3>
            <button
              onClick={() => navigate('/subscribers/pending')}
              className="text-xs text-emerald-700 hover:underline font-semibold"
            >
              View Queue
            </button>
          </div>

          <div className="grid grid-cols-3 gap-2">
            <div 
              onClick={() => navigate('/subscribers/pending')}
              className="p-3 rounded-xl bg-amber-50/80 border border-amber-200/70 text-center cursor-pointer hover:bg-amber-100/60 transition-colors"
            >
              <div className="text-xl font-black text-amber-700">{metrics.pendingOnboardingCount}</div>
              <div className="text-[10px] font-semibold text-amber-900 mt-0.5">Pending Review</div>
            </div>

            <div 
              onClick={() => navigate('/subscribers/provisioning')}
              className="p-3 rounded-xl bg-rose-50/80 border border-rose-200/70 text-center cursor-pointer hover:bg-rose-100/60 transition-colors"
            >
              <div className="text-xl font-black text-rose-700">{metrics.needsAttentionCount}</div>
              <div className="text-[10px] font-semibold text-rose-900 mt-0.5">Needs Attention</div>
            </div>

            <div 
              onClick={() => navigate('/support/issues')}
              className="p-3 rounded-xl bg-slate-50 border border-slate-200 text-center cursor-pointer hover:bg-slate-100 transition-colors"
            >
              <div className="text-xl font-black text-slate-700">{metrics.criticalIssuesCount}</div>
              <div className="text-[10px] font-semibold text-slate-600 mt-0.5">Open Issues</div>
            </div>
          </div>

          <div className="p-3 rounded-xl bg-slate-50 border border-slate-100 text-xs text-slate-600 leading-relaxed">
            <span className="font-semibold text-slate-900">Provisioning Rule:</span> Tenants cannot be activated until all 10 checks (including Default Location <code>"Main Store"</code>) are green.
          </div>
        </div>

        {/* Subscription Summary */}
        <div className="bg-white p-5 rounded-2xl border border-slate-200/80 shadow-xs space-y-4">
          <div className="flex items-center justify-between">
            <h3 className="text-sm font-bold text-slate-900 flex items-center gap-2">
              <CreditCard className="w-4 h-4 text-emerald-600" />
              <span>Subscription Status</span>
            </h3>
            <button
              onClick={() => navigate('/subscriptions/plans')}
              className="text-xs text-emerald-700 hover:underline font-semibold"
            >
              Plan Catalog
            </button>
          </div>

          <div className="grid grid-cols-2 gap-3 text-xs">
            <div 
              onClick={() => navigate('/subscriptions/active')}
              className="p-3 rounded-xl bg-emerald-50/60 border border-emerald-200/60 flex items-center justify-between cursor-pointer hover:bg-emerald-100/60"
            >
              <div>
                <div className="font-bold text-emerald-950">Active Paid</div>
                <div className="text-[11px] text-emerald-700">Commercial Tiers</div>
              </div>
              <span className="text-lg font-black text-emerald-700">{metrics.subscriptionSummary.active}</span>
            </div>

            <div 
              onClick={() => navigate('/subscriptions/trial')}
              className="p-3 rounded-xl bg-sky-50/60 border border-sky-200/60 flex items-center justify-between cursor-pointer hover:bg-sky-100/60"
            >
              <div>
                <div className="font-bold text-sky-950">Active Trials</div>
                <div className="text-[11px] text-sky-700">Evaluation Mode</div>
              </div>
              <span className="text-lg font-black text-sky-700">{metrics.subscriptionSummary.trial}</span>
            </div>

            <div 
              onClick={() => navigate('/subscriptions/grace')}
              className="p-3 rounded-xl bg-amber-50/60 border border-amber-200/60 flex items-center justify-between cursor-pointer hover:bg-amber-100/60"
            >
              <div>
                <div className="font-bold text-amber-950">Grace Period</div>
                <div className="text-[11px] text-amber-700">Tolerance Window</div>
              </div>
              <span className="text-lg font-black text-amber-700">{metrics.subscriptionSummary.grace}</span>
            </div>

            <div 
              onClick={() => navigate('/subscriptions/expired')}
              className="p-3 rounded-xl bg-rose-50/60 border border-rose-200/60 flex items-center justify-between cursor-pointer hover:bg-rose-100/60"
            >
              <div>
                <div className="font-bold text-rose-950">Expired</div>
                <div className="text-[11px] text-rose-700">Needs Renewal</div>
              </div>
              <span className="text-lg font-black text-rose-700">{metrics.subscriptionSummary.expired}</span>
            </div>
          </div>
        </div>

        {/* Application Ecosystem Health */}
        <div className="bg-white p-5 rounded-2xl border border-slate-200/80 shadow-xs space-y-4">
          <div className="flex items-center justify-between">
            <h3 className="text-sm font-bold text-slate-900 flex items-center gap-2">
              <Activity className="w-4 h-4 text-emerald-600" />
              <span>Client & API Health</span>
            </h3>
            <button
              onClick={() => navigate('/devices/versions')}
              className="text-xs text-emerald-700 hover:underline font-semibold"
            >
              Versions
            </button>
          </div>

          <div className="space-y-2 text-xs">
            <div className="flex items-center justify-between p-2 rounded-xl bg-slate-50 border border-slate-100">
              <div className="flex items-center gap-2">
                <span className="w-2 h-2 rounded-full bg-emerald-500" />
                <span className="font-semibold text-slate-800">Android APK</span>
              </div>
              <span className="text-slate-500">{metrics.applicationHealth.android.version} ({metrics.applicationHealth.android.activeCount} installs)</span>
            </div>

            <div className="flex items-center justify-between p-2 rounded-xl bg-slate-50 border border-slate-100">
              <div className="flex items-center gap-2">
                <span className="w-2 h-2 rounded-full bg-emerald-500" />
                <span className="font-semibold text-slate-800">Flutter Web</span>
              </div>
              <span className="text-slate-500">{metrics.applicationHealth.flutterWeb.version} ({metrics.applicationHealth.flutterWeb.activeCount} web users)</span>
            </div>

            <div className="flex items-center justify-between p-2 rounded-xl bg-slate-50 border border-slate-100">
              <div className="flex items-center gap-2">
                <span className="w-2 h-2 rounded-full bg-emerald-500" />
                <span className="font-semibold text-slate-800">Cloud API Gateway</span>
              </div>
              <span className="text-slate-500">{metrics.applicationHealth.api.latencyMs}ms ({metrics.applicationHealth.api.uptimePercent}%)</span>
            </div>

            <div className="flex items-center justify-between p-2 rounded-xl bg-slate-50 border border-slate-100">
              <div className="flex items-center gap-2">
                <span className="w-2 h-2 rounded-full bg-emerald-500" />
                <span className="font-semibold text-slate-800">Delivery Subsystem</span>
              </div>
              <span className="text-slate-500">Tenant-Scoped (ERP Control Center)</span>
            </div>
          </div>
        </div>
      </div>

      {/* Quick Launch & Existing Tools Grid */}
      <div className="bg-white p-5 rounded-2xl border border-slate-200/80 shadow-xs space-y-4">
        <div className="flex items-center justify-between">
          <div>
            <h3 className="text-sm font-bold text-slate-900">Quick Administrative Access</h3>
            <p className="text-xs text-slate-500 mt-0.5">Direct launchers for operational actions and existing ERP / Mobile tools.</p>
          </div>
          <button
            onClick={() => navigate('/existing-tools')}
            className="text-xs text-emerald-700 font-bold hover:underline flex items-center gap-1"
          >
            <span>All Existing Tools</span>
            <ArrowRight className="w-3.5 h-3.5" />
          </button>
        </div>

        <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-5 gap-3 text-xs">
          <button
            onClick={() => outletContext?.onOpenOnboarding ? outletContext.onOpenOnboarding() : navigate('/subscribers/pending')}
            className="p-3 rounded-xl bg-emerald-50/70 border border-emerald-200/80 hover:bg-emerald-100/70 text-emerald-900 font-semibold text-left transition-colors cursor-pointer"
          >
            <Plus className="w-4 h-4 text-emerald-600 mb-1.5" />
            <div>Add Subscriber</div>
            <div className="text-[10px] text-emerald-700 font-normal">Onboarding wizard</div>
          </button>

          <button
            onClick={() => navigate('/subscribers/pending')}
            className="p-3 rounded-xl bg-amber-50/70 border border-amber-200/80 hover:bg-amber-100/70 text-amber-900 font-semibold text-left transition-colors cursor-pointer"
          >
            <Clock className="w-4 h-4 text-amber-600 mb-1.5" />
            <div>Pending Queue</div>
            <div className="text-[10px] text-amber-700 font-normal">Review registrations</div>
          </button>

          <button
            onClick={() => navigate('/support/diagnostics')}
            className="p-3 rounded-xl bg-sky-50/70 border border-sky-200/80 hover:bg-sky-100/70 text-sky-900 font-semibold text-left transition-colors cursor-pointer"
          >
            <Wrench className="w-4 h-4 text-sky-600 mb-1.5" />
            <div>Run Diagnostics</div>
            <div className="text-[10px] text-sky-700 font-normal">Tenant health test</div>
          </button>

          <a
            href="https://erp.floraprise.com/admin/demo-requests"
            target="_blank"
            rel="noopener noreferrer"
            className="p-3 rounded-xl bg-slate-50 border border-slate-200 hover:bg-slate-100 text-slate-800 font-semibold text-left transition-colors block"
          >
            <ExternalLink className="w-4 h-4 text-slate-500 mb-1.5" />
            <div>Demo Requests</div>
            <div className="text-[10px] text-slate-500 font-normal">ERP Backoffice</div>
          </a>

          <a
            href="https://mobile.floraprise.com/"
            target="_blank"
            rel="noopener noreferrer"
            className="p-3 rounded-xl bg-slate-50 border border-slate-200 hover:bg-slate-100 text-slate-800 font-semibold text-left transition-colors block"
          >
            <Smartphone className="w-4 h-4 text-slate-500 mb-1.5" />
            <div>Mobile Admin</div>
            <div className="text-[10px] text-slate-500 font-normal">mobile.floraprise.com</div>
          </a>
        </div>
      </div>

      {/* Recent Subscribers Table */}
      <div className="bg-white rounded-2xl border border-slate-200/80 shadow-xs overflow-hidden">
        <div className="p-5 border-b border-slate-100 flex items-center justify-between">
          <div>
            <h3 className="text-sm font-bold text-slate-900">Recent Floraprise Subscribers</h3>
            <p className="text-xs text-slate-500 mt-0.5">Active, trial, and pending subscribers across Solo, Android, and Web clients.</p>
          </div>
          <button
            onClick={() => navigate('/subscribers')}
            className="text-xs text-emerald-700 font-bold hover:underline flex items-center gap-1"
          >
            <span>View All ({metrics.totalSubscribers})</span>
            <ChevronRight className="w-3.5 h-3.5" />
          </button>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs text-slate-600">
            <thead className="bg-slate-50/80 text-slate-500 uppercase font-semibold text-[11px] tracking-wider border-b border-slate-200/80">
              <tr>
                <th className="py-3.5 px-4">Business / Tenant</th>
                <th className="py-3.5 px-4">Owner & Mobile</th>
                <th className="py-3.5 px-4">Plan & Expiry</th>
                <th className="py-3.5 px-4">Operational Clients</th>
                <th className="py-3.5 px-4">Provisioning</th>
                <th className="py-3.5 px-4">Status</th>
                <th className="py-3.5 px-4 text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {recentSubscribers.map(sub => (
                <tr key={sub.id} className="hover:bg-slate-50/80 transition-colors">
                  <td className="py-3.5 px-4">
                    <div 
                      onClick={() => navigate(`/subscribers/${sub.id}`)}
                      className="font-bold text-slate-900 hover:text-emerald-700 cursor-pointer"
                    >
                      {sub.businessName}
                    </div>
                    <div className="text-[11px] text-slate-400 font-mono">{sub.id.substring(0, 8)}...</div>
                  </td>
                  <td className="py-3.5 px-4">
                    <div className="font-semibold text-slate-800">{sub.ownerName}</div>
                    <div className="text-[11px] text-slate-500">{sub.mobile}</div>
                  </td>
                  <td className="py-3.5 px-4">
                    <div className="font-semibold text-slate-800">{sub.planName}</div>
                    <div className="text-[11px] text-slate-500">Exp: {sub.subscriptionExpiresAt.substring(0, 10)}</div>
                  </td>
                  <td className="py-3.5 px-4">
                    <div className="flex flex-wrap gap-1">
                      {sub.operationalModes.map(mode => (
                        <span key={mode} className="text-[10px] px-2 py-0.5 rounded bg-slate-100 text-slate-700 font-medium">
                          {mode.replace('Flutter ', '')}
                        </span>
                      ))}
                    </div>
                  </td>
                  <td className="py-3.5 px-4">
                    <button
                      onClick={() => setSelectedSubscriberForCheck(sub)}
                      className={`inline-flex items-center gap-1 text-[11px] font-bold px-2 py-0.5 rounded cursor-pointer ${
                        sub.overallProvisioningState === 'READY'
                          ? 'bg-emerald-100 text-emerald-800 hover:bg-emerald-200'
                          : sub.overallProvisioningState === 'NEEDS ATTENTION'
                          ? 'bg-amber-100 text-amber-800 hover:bg-amber-200'
                          : 'bg-rose-100 text-rose-800 hover:bg-rose-200'
                      }`}
                    >
                      <span>{sub.overallProvisioningState}</span>
                    </button>
                  </td>
                  <td className="py-3.5 px-4">
                    <StatusBadge status={sub.status} size="sm" />
                  </td>
                  <td className="py-3.5 px-4 text-right">
                    <button
                      onClick={() => navigate(`/subscribers/${sub.id}`)}
                      className="px-2.5 py-1 text-xs font-semibold text-slate-700 hover:text-emerald-700 hover:bg-emerald-50 rounded-lg transition-colors cursor-pointer"
                    >
                      360 View →
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {/* Provisioning Modal */}
      {selectedSubscriberForCheck && (
        <ProvisioningModal
          isOpen={true}
          onClose={() => setSelectedSubscriberForCheck(null)}
          subscriber={selectedSubscriberForCheck}
          onUpdated={loadData}
        />
      )}
    </div>
  );
};
