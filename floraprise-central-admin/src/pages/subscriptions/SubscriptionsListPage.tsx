import React, { useState, useEffect } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import { realSubscriptionService } from '../../services/api/realSubscriptionService';
import { SubscriptionRecord } from '../../types/subscription';
import { DataTable, Column } from '../../components/common/DataTable';
import { StatusBadge } from '../../components/common/StatusBadge';
import { CreditCard, Filter } from 'lucide-react';

interface SubscriptionsListPageProps {
  initialFilter?: 'Active' | 'Trial' | 'Grace' | 'Expired';
}

export const SubscriptionsListPage: React.FC<SubscriptionsListPageProps> = ({ initialFilter }) => {
  const navigate = useNavigate();
  const location = useLocation();
  const [subscriptions, setSubscriptions] = useState<SubscriptionRecord[]>([]);

  // Infer filter from path if not provided
  let effectiveFilter = initialFilter;
  if (!effectiveFilter) {
    if (location.pathname.includes('/active')) effectiveFilter = 'Active';
    else if (location.pathname.includes('/trial')) effectiveFilter = 'Trial';
    else if (location.pathname.includes('/grace')) effectiveFilter = 'Grace';
    else if (location.pathname.includes('/expired')) effectiveFilter = 'Expired';
  }

  const [selectedFilter, setSelectedFilter] = useState<string>(effectiveFilter || 'all');

  useEffect(() => {
    realSubscriptionService.getSubscriptions().then(setSubscriptions).catch(() => setSubscriptions([]));
  }, []);

  useEffect(() => {
    if (effectiveFilter) {
      setSelectedFilter(effectiveFilter);
    }
  }, [effectiveFilter]);

  const filtered = subscriptions.filter(s => {
    if (selectedFilter === 'all') return true;
    return s.status.toLowerCase() === selectedFilter.toLowerCase();
  });

  const columns: Column<SubscriptionRecord>[] = [
    {
      key: 'businessName',
      header: 'Subscriber Business',
      sortable: true,
      render: (s) => (
        <div 
          onClick={() => navigate(`/subscribers/${s.subscriberId}`)}
          className="font-bold text-slate-900 hover:text-emerald-700 cursor-pointer"
        >
          {s.businessName}
        </div>
      )
    },
    {
      key: 'planName',
      header: 'Subscribed Plan',
      sortable: true,
      render: (s) => (
        <div>
          <div className="font-semibold text-slate-800">{s.planName}</div>
          <div className="text-[11px] text-slate-400 font-mono">{s.planCode}</div>
        </div>
      )
    },
    {
      key: 'amountInr',
      header: 'Amount',
      sortable: true,
      render: (s) => (
        <span className="font-bold text-slate-900">
          {s.amountInr === 0 ? 'Free Trial' : `₹${s.amountInr.toLocaleString('en-IN')}`}
        </span>
      )
    },
    {
      key: 'startDate',
      header: 'Start Date',
      sortable: true,
      render: (s) => <span className="text-slate-600">{s.startDate}</span>
    },
    {
      key: 'expiryDate',
      header: 'Expiry Date',
      sortable: true,
      render: (s) => (
        <div>
          <span className="text-slate-900 font-medium">{s.expiryDate}</span>
          {s.gracePeriodEndsAt && (
            <div className="text-[10px] text-amber-700 font-bold">Grace Ends: {s.gracePeriodEndsAt}</div>
          )}
        </div>
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
        <button
          onClick={() => navigate(`/subscribers/${s.subscriberId}`)}
          className="px-2.5 py-1 text-xs font-semibold text-slate-700 hover:text-emerald-700 hover:bg-emerald-50 rounded-lg cursor-pointer"
        >
          Manage →
        </button>
      )
    }
  ];

  return (
    <div className="space-y-4">
      <div>
        <h2 className="text-xl font-black text-slate-900 flex items-center gap-2">
          <CreditCard className="w-5 h-5 text-emerald-600" />
          <span>Subscription Directory</span>
        </h2>
        <p className="text-xs text-slate-500 mt-0.5">
          Real-time tracking of active, trial, grace period, and expired subscriptions.
        </p>
      </div>

      <DataTable
        columns={columns}
        data={filtered}
        searchPlaceholder="Search subscriptions by subscriber name..."
        searchableKeys={['businessName', 'planName', 'planCode']}
        filters={
          <select
            value={selectedFilter}
            onChange={e => setSelectedFilter(e.target.value)}
            className="px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs text-slate-800 focus:bg-white focus:outline-none focus:ring-2 focus:ring-emerald-500/20"
          >
            <option value="all">All ({subscriptions.length})</option>
            <option value="Active">Active ({subscriptions.filter(s => s.status === 'Active').length})</option>
            <option value="Trial">Trial ({subscriptions.filter(s => s.status === 'Trial').length})</option>
            <option value="Grace">Grace Period ({subscriptions.filter(s => s.status === 'Grace').length})</option>
            <option value="Expired">Expired ({subscriptions.filter(s => s.status === 'Expired').length})</option>
          </select>
        }
      />
    </div>
  );
};
