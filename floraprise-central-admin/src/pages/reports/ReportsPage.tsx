import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { 
  BarChart3, 
  TrendingUp, 
  Users, 
  Smartphone, 
  CreditCard, 
  DollarSign, 
  ExternalLink,
  ShieldCheck,
  Building2,
  RefreshCw,
  ArrowRight
} from 'lucide-react';
import { realReportsService, PlatformReportSummary } from '../../services/api/realReportsService';
import { MetricCard } from '../../components/common/MetricCard';

export const ReportsPage: React.FC = () => {
  const navigate = useNavigate();
  const [summary, setSummary] = useState<PlatformReportSummary | null>(null);
  const [isLoading, setIsLoading] = useState<boolean>(true);

  const loadData = async () => {
    setIsLoading(true);
    try {
      const data = await realReportsService.getSummary();
      setSummary(data);
    } catch {
      setSummary(null);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    loadData();
  }, []);

  if (isLoading && !summary) {
    return (
      <div className="p-12 text-center text-slate-400 bg-white rounded-2xl border border-slate-200 space-y-3">
        <div className="animate-spin w-8 h-8 border-3 border-emerald-600 border-t-transparent rounded-full mx-auto" />
        <div className="text-xs font-semibold text-slate-600">Calculating Live Platform Reports...</div>
      </div>
    );
  }

  if (!summary) {
    return (
      <div className="p-10 bg-white rounded-2xl border border-slate-200 text-center space-y-3">
        <BarChart3 className="w-8 h-8 mx-auto text-slate-400" />
        <div className="text-sm font-bold text-slate-800">Unable to load telemetry reports</div>
        <button
          onClick={loadData}
          className="inline-flex items-center gap-1.5 px-4 py-2 bg-emerald-600 hover:bg-emerald-700 text-white rounded-xl text-xs font-bold cursor-pointer"
        >
          <RefreshCw className="w-3.5 h-3.5" />
          <span>Retry</span>
        </button>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h2 className="text-xl font-black text-slate-900 flex items-center gap-2">
            <BarChart3 className="w-5 h-5 text-emerald-600" />
            <span>Platform Growth & Telemetry Reports</span>
          </h2>
          <p className="text-xs text-slate-500 mt-0.5">
            Real subscriber telemetry, MRR/ARR run-rate, license saturation, and operational client distributions derived from verified database records.
          </p>
        </div>

        <div className="flex items-center gap-2">
          <button
            onClick={loadData}
            className="p-2 text-slate-500 hover:text-slate-800 bg-white border border-slate-200 rounded-xl hover:bg-slate-50 transition-colors cursor-pointer"
            title="Refresh Reports"
          >
            <RefreshCw className="w-4 h-4" />
          </button>
          <a
            href="https://erp.floraprise.com/admin/analytics"
            target="_blank"
            rel="noopener noreferrer"
            className="inline-flex items-center gap-1.5 px-3.5 py-2 text-xs font-bold rounded-xl bg-slate-900 hover:bg-slate-800 text-white shadow-xs"
          >
            <span>Open ERP Platform Analytics</span>
            <ExternalLink className="w-3.5 h-3.5" />
          </a>
        </div>
      </div>

      {/* 4 Core Metric Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <MetricCard
          title="Monthly Run-Rate (MRR)"
          value={`₹${summary.mrr.toLocaleString('en-IN')}`}
          subtitle="Sum of active recurring SaaS fees"
          icon={DollarSign}
          variant="emerald"
          onClick={() => navigate('/subscriptions/active')}
        />
        <MetricCard
          title="Annual Run-Rate (ARR)"
          value={`₹${summary.arr.toLocaleString('en-IN')}`}
          subtitle="Annualized SaaS run-rate"
          icon={TrendingUp}
          variant="sky"
          onClick={() => navigate('/subscriptions/plans')}
        />
        <MetricCard
          title="License Saturation"
          value={`${summary.licenseUtilizationRate}%`}
          subtitle={`${summary.totalDevices} devices / ${summary.totalLicenses} licenses`}
          icon={Smartphone}
          variant="amber"
          onClick={() => navigate('/devices')}
        />
        <MetricCard
          title="Subscribers Breakdown"
          value={`${summary.activePaidSubscribers} Active`}
          subtitle={`${summary.trialSubscribers} Trial / ${summary.totalSubscribers} Total`}
          icon={Users}
          variant="slate"
          onClick={() => navigate('/subscribers')}
        />
      </div>

      {/* Breakdown Grids */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {/* Operational Mode Breakdown */}
        <div className="bg-white p-6 rounded-3xl border border-slate-200/80 shadow-xs space-y-4">
          <div className="flex items-center justify-between">
            <h3 className="text-sm font-bold text-slate-900">Subscriber Operational Client Distribution</h3>
            <span className="text-xs text-slate-400">{summary.totalSubscribers} Total Subscribers</span>
          </div>
          
          <div className="space-y-4 text-xs">
            {summary.operationalModeDistribution.map(mode => (
              <div key={mode.modeName}>
                <div className="flex justify-between font-semibold text-slate-700 mb-1.5">
                  <span>{mode.modeName}</span>
                  <span>{mode.percentage}% ({mode.subscriberCount} Subscribers)</span>
                </div>
                <div className="w-full h-2.5 bg-slate-100 rounded-full overflow-hidden">
                  <div className={`h-full ${mode.color} rounded-full transition-all`} style={{ width: `${Math.max(4, mode.percentage)}%` }} />
                </div>
              </div>
            ))}
          </div>

          <div className="pt-2 border-t border-slate-100 text-[11px] text-slate-500">
            Client telemetry is automatically reported by active Android POS terminals, web client sessions, and desktop standalone instances.
          </div>
        </div>

        {/* Subscription Plan Share */}
        <div className="bg-white p-6 rounded-3xl border border-slate-200/80 shadow-xs space-y-4">
          <div className="flex items-center justify-between">
            <h3 className="text-sm font-bold text-slate-900">Commercial Plan Tier Distribution</h3>
            <button
              onClick={() => navigate('/subscriptions/plans')}
              className="text-xs text-emerald-700 hover:underline font-bold flex items-center gap-1"
            >
              <span>Plan Catalog</span>
              <ArrowRight className="w-3 h-3" />
            </button>
          </div>
          
          <div className="space-y-2.5 text-xs">
            {summary.planTierDistribution.map(tier => (
              <div 
                key={tier.planCode} 
                onClick={() => navigate('/subscriptions/plans')}
                className="p-3 bg-slate-50 hover:bg-slate-100 rounded-2xl border border-slate-200 flex items-center justify-between transition-colors cursor-pointer"
              >
                <div>
                  <div className="text-slate-900 font-bold">{tier.planName}</div>
                  <div className="text-[11px] text-slate-500">
                    {tier.isCustomOrTrial ? 'Evaluation Tier' : `Monthly contribution: ₹${tier.monthlyRevenue.toLocaleString('en-IN')}`}
                  </div>
                </div>
                <div className="text-right">
                  <span className="text-base font-black text-emerald-800">{tier.subscriberCount}</span>
                  <div className="text-[10px] text-slate-400">Subscribers</div>
                </div>
              </div>
            ))}
          </div>

          <div className="pt-2 border-t border-slate-100 text-[11px] text-slate-500 flex items-center justify-between">
            <span>Aggregated from active subscriptions</span>
            <span className="font-semibold text-emerald-700">{summary.activePaidSubscribers} Active Subscriptions</span>
          </div>
        </div>
      </div>
    </div>
  );
};
