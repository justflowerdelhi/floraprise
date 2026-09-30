import React, { useState, useEffect } from 'react';
import { realDiagnosticsService } from '../../services/api/realDiagnosticsService';
import { SupportIssue } from '../../types/diagnostics';
import { DataTable, Column } from '../../components/common/DataTable';
import { StatusBadge } from '../../components/common/StatusBadge';
import { LifeBuoy, AlertTriangle } from 'lucide-react';

export const IssuesPage: React.FC = () => {
  const [issues, setIssues] = useState<SupportIssue[]>([]);

  useEffect(() => {
    realDiagnosticsService.getSupportIssues().then(setIssues);
  }, []);

  const columns: Column<SupportIssue>[] = [
    {
      key: 'ticketNumber',
      header: 'Ticket # & Title',
      sortable: true,
      render: (i) => (
        <div>
          <div className="font-mono font-bold text-slate-900">{i.ticketNumber}</div>
          <div className="text-xs font-semibold text-slate-800 mt-0.5">{i.title}</div>
          <div className="text-[11px] text-slate-500 line-clamp-1">{i.description}</div>
        </div>
      )
    },
    {
      key: 'companyName',
      header: 'Subscriber Business',
      sortable: true,
      render: (i) => <span className="font-semibold text-slate-800">{i.companyName}</span>
    },
    {
      key: 'category',
      header: 'Category',
      sortable: true,
      render: (i) => <span className="text-xs text-slate-700 bg-slate-100 px-2 py-0.5 rounded">{i.category}</span>
    },
    {
      key: 'severity',
      header: 'Severity',
      sortable: true,
      render: (i) => (
        <span className={`text-[10px] font-bold uppercase px-2 py-0.5 rounded-full ${
          i.severity === 'Critical' ? 'bg-rose-100 text-rose-800' :
          i.severity === 'High' ? 'bg-amber-100 text-amber-800' : 'bg-slate-100 text-slate-700'
        }`}>
          {i.severity}
        </span>
      )
    },
    {
      key: 'assignedTo',
      header: 'Assigned Operator',
      render: (i) => <span className="text-xs text-slate-700">{i.assignedTo}</span>
    },
    {
      key: 'status',
      header: 'Status',
      sortable: true,
      render: (i) => <StatusBadge status={i.status} size="sm" />
    }
  ];

  return (
    <div className="space-y-4">
      <div>
        <h2 className="text-xl font-black text-slate-900 flex items-center gap-2">
          <LifeBuoy className="w-5 h-5 text-emerald-600" />
          <span>Tenant Support Tickets & Provisioning Issues</span>
        </h2>
        <p className="text-xs text-slate-500 mt-0.5">
          Active operational incidents, onboarding exceptions, and tenant remediation alerts derived from live subscriber states.
        </p>
      </div>

      <DataTable
        columns={columns}
        data={issues}
        searchPlaceholder="Search tickets by subject, company, category..."
        searchableKeys={['ticketNumber', 'title', 'companyName', 'category', 'description']}
      />
    </div>
  );
};
