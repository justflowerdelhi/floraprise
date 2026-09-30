import React, { useState, useEffect } from 'react';
import { useNavigate, useOutletContext } from 'react-router-dom';
import { realSubscriberService } from '../../services/api/realSubscriberService';
import { Subscriber } from '../../types/subscriber';
import { DataTable, Column } from '../../components/common/DataTable';
import { StatusBadge } from '../../components/common/StatusBadge';
import { ProvisioningModal } from '../../components/provisioning/ProvisioningModal';
import { Plus, ShieldCheck, Eye, AlertTriangle, RefreshCw, Building2 } from 'lucide-react';

export const SubscribersListPage: React.FC = () => {
  const navigate = useNavigate();
  const outletContext = useOutletContext<{ onOpenOnboarding?: () => void }>();
  const [subscribers, setSubscribers] = useState<Subscriber[]>([]);
  const [selectedStatus, setSelectedStatus] = useState<string>('all');
  const [selectedForCheck, setSelectedForCheck] = useState<Subscriber | null>(null);
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);

  const loadData = async () => {
    setIsLoading(true);
    setError(null);
    try {
      const data = await realSubscriberService.getSubscribers();
      setSubscribers(data);
    } catch (err: any) {
      setError(err?.message || 'Unable to load subscribers from backend.');
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    loadData();
  }, []);

  const filteredSubscribers = subscribers.filter(s => {
    if (selectedStatus === 'all') return true;
    return s.status.toLowerCase() === selectedStatus.toLowerCase();
  });

  const columns: Column<Subscriber>[] = [
    {
      key: 'businessName',
      header: 'Subscriber Business',
      sortable: true,
      render: (s) => (
        <div>
          <div className="font-bold text-slate-900 hover:text-emerald-700 cursor-pointer" onClick={() => navigate(`/subscribers/${s.id}`)}>
            {s.businessName}
          </div>
          <div className="text-[11px] text-slate-400 font-mono">{s.city}, {s.state} • ID: {s.id.substring(0, 8)}...</div>
        </div>
      )
    },
    {
      key: 'ownerName',
      header: 'Owner / Contact',
      sortable: true,
      render: (s) => (
        <div>
          <div className="font-semibold text-slate-800">{s.ownerName}</div>
          <div className="text-[11px] text-slate-500">{s.mobile} • {s.email}</div>
        </div>
      )
    },
    {
      key: 'planName',
      header: 'Subscription Plan',
      sortable: true,
      render: (s) => (
        <div>
          <div className="font-semibold text-slate-800">{s.planName}</div>
          <div className="text-[11px] text-slate-500">Expires: {s.subscriptionExpiresAt.substring(0, 10)}</div>
        </div>
      )
    },
    {
      key: 'operationalModes',
      header: 'Operational Modes',
      render: (s) => (
        <div className="flex flex-wrap gap-1">
          {s.operationalModes.map(m => (
            <span key={m} className="text-[10px] px-2 py-0.5 rounded bg-slate-100 text-slate-700 font-medium">
              {m.replace('Flutter ', '')}
            </span>
          ))}
        </div>
      )
    },
    {
      key: 'overallProvisioningState',
      header: 'Provisioning',
      sortable: true,
      render: (s) => (
        <button
          onClick={(e) => {
            e.stopPropagation();
            setSelectedForCheck(s);
          }}
          className={`inline-flex items-center gap-1 text-[11px] font-bold px-2 py-0.5 rounded cursor-pointer ${
            s.overallProvisioningState === 'READY'
              ? 'bg-emerald-100 text-emerald-800 hover:bg-emerald-200'
              : s.overallProvisioningState === 'NEEDS ATTENTION'
              ? 'bg-amber-100 text-amber-800 hover:bg-amber-200'
              : 'bg-rose-100 text-rose-800 hover:bg-rose-200'
          }`}
        >
          <span>{s.overallProvisioningState}</span>
        </button>
      )
    },
    {
      key: 'status',
      header: 'Status',
      sortable: true,
      render: (s) => <StatusBadge status={s.status} size="sm" />
    },
    {
      key: 'actions',
      header: 'Actions',
      align: 'right',
      render: (s) => (
        <div className="flex items-center justify-end gap-1.5" onClick={e => e.stopPropagation()}>
          <button
            onClick={() => setSelectedForCheck(s)}
            title="Run 10 Provisioning Checks"
            className="p-1.5 rounded-lg text-slate-500 hover:text-emerald-700 hover:bg-emerald-50 transition-colors"
          >
            <ShieldCheck className="w-4 h-4" />
          </button>
          <button
            onClick={() => navigate(`/subscribers/${s.id}`)}
            title="View 360 Profile"
            className="p-1.5 rounded-lg text-slate-500 hover:text-slate-900 hover:bg-slate-100 transition-colors"
          >
            <Eye className="w-4 h-4" />
          </button>
        </div>
      )
    }
  ];

  return (
    <div className="space-y-4">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h2 className="text-xl font-black text-slate-900">Subscribers & Tenant Management</h2>
          <p className="text-xs text-slate-500 mt-0.5">
            Real subscriber directory from Sumpooj.API across Solo, Cloud Mobile, and Web operational modes.
          </p>
        </div>

        <div className="flex items-center gap-2">
          <button
            onClick={loadData}
            title="Refresh from backend"
            disabled={isLoading}
            className="p-2 text-slate-600 hover:text-slate-900 hover:bg-slate-100 rounded-xl border border-slate-200 bg-white shadow-xs transition-colors cursor-pointer disabled:opacity-50"
          >
            <RefreshCw className={`w-4 h-4 ${isLoading ? 'animate-spin text-emerald-600' : ''}`} />
          </button>

          <button
            onClick={() => outletContext?.onOpenOnboarding ? outletContext.onOpenOnboarding() : navigate('/subscribers/pending')}
            className="inline-flex items-center gap-1.5 px-4 py-2 text-xs font-bold bg-emerald-600 hover:bg-emerald-700 text-white rounded-xl shadow-xs shadow-emerald-600/20 transition-all cursor-pointer"
          >
            <Plus className="w-4 h-4" />
            <span>Onboard New Subscriber</span>
          </button>
        </div>
      </div>

      {/* Error Banner */}
      {error && (
        <div className="p-4 rounded-2xl bg-rose-50 border border-rose-200 text-rose-900 space-y-2">
          <div className="flex items-start justify-between gap-3">
            <div className="flex items-start gap-2.5">
              <AlertTriangle className="w-5 h-5 text-rose-600 shrink-0 mt-0.5" />
              <div>
                <div className="font-bold text-sm text-rose-950">Unable to load subscribers from backend</div>
                <div className="text-xs text-rose-700 mt-0.5">{error}</div>
              </div>
            </div>
            <button
              onClick={loadData}
              className="inline-flex items-center gap-1.5 px-3 py-1.5 bg-rose-600 hover:bg-rose-700 text-white font-bold text-xs rounded-xl shadow-xs shrink-0 cursor-pointer"
            >
              <RefreshCw className="w-3.5 h-3.5" />
              <span>Retry</span>
            </button>
          </div>
        </div>
      )}

      {/* Loading State */}
      {isLoading ? (
        <div className="p-12 text-center text-slate-400 bg-white rounded-2xl border border-slate-200 space-y-3">
          <div className="animate-spin w-8 h-8 border-3 border-emerald-600 border-t-transparent rounded-full mx-auto" />
          <div className="text-xs font-semibold text-slate-600">Fetching live subscribers from Sumpooj.API...</div>
        </div>
      ) : !error && subscribers.length === 0 ? (
        /* Empty State */
        <div className="p-12 text-center bg-white rounded-2xl border border-slate-200 space-y-4">
          <div className="w-12 h-12 rounded-2xl bg-slate-100 flex items-center justify-center text-slate-400 mx-auto">
            <Building2 className="w-6 h-6" />
          </div>
          <div>
            <div className="font-bold text-base text-slate-800">No subscribers found in database</div>
            <p className="text-xs text-slate-500 max-w-sm mx-auto mt-1">
              There are currently no registered mobile subscribers or florist companies in the database.
            </p>
          </div>
          <button
            onClick={() => outletContext?.onOpenOnboarding ? outletContext.onOpenOnboarding() : navigate('/subscribers/pending')}
            className="inline-flex items-center gap-1.5 px-4 py-2 text-xs font-bold bg-emerald-600 hover:bg-emerald-700 text-white rounded-xl shadow-xs cursor-pointer"
          >
            <Plus className="w-4 h-4" />
            <span>Onboard First Subscriber</span>
          </button>
        </div>
      ) : !error ? (
        /* Main DataTable */
        <DataTable
          columns={columns}
          data={filteredSubscribers}
          searchPlaceholder="Search by business name, owner, phone, city, or company ID..."
          searchableKeys={['businessName', 'ownerName', 'mobile', 'email', 'city', 'id']}
          filters={
            <select
              value={selectedStatus}
              onChange={e => setSelectedStatus(e.target.value)}
              className="px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs text-slate-800 focus:bg-white focus:outline-none focus:ring-2 focus:ring-emerald-500/20"
            >
              <option value="all">All Statuses ({subscribers.length})</option>
              <option value="active">Active ({subscribers.filter(s => s.status === 'Active').length})</option>
              <option value="trial">Trial ({subscribers.filter(s => s.status === 'Trial').length})</option>
              <option value="needs attention">Needs Attention ({subscribers.filter(s => s.status === 'Needs Attention').length})</option>
              <option value="pending onboarding">Pending Onboarding ({subscribers.filter(s => s.status === 'Pending Onboarding').length})</option>
              <option value="expired">Expired ({subscribers.filter(s => s.status === 'Expired').length})</option>
            </select>
          }
          onRowClick={(sub) => navigate(`/subscribers/${sub.id}`)}
        />
      ) : null}

      {/* Provisioning Verification Modal */}
      {selectedForCheck && (
        <ProvisioningModal
          isOpen={true}
          onClose={() => setSelectedForCheck(null)}
          subscriber={selectedForCheck}
          onUpdated={loadData}
        />
      )}
    </div>
  );
};
