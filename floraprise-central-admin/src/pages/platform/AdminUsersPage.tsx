import React, { useState } from 'react';
import { AdminUser } from '../../types/platform';
import { DataTable, Column } from '../../components/common/DataTable';
import { StatusBadge } from '../../components/common/StatusBadge';
import { Users, Shield, Plus, KeyRound } from 'lucide-react';

const INITIAL_ADMINS: AdminUser[] = [
  {
    id: 'usr-01',
    name: 'Vipul Malhotra',
    email: 'vipul@floraprise.com',
    role: 'SuperAdmin',
    status: 'Active',
    lastLoginAt: '10 mins ago',
    twoFactorEnabled: true
  },
  {
    id: 'usr-02',
    name: 'Pooja Agarwal',
    email: 'pooja.support@floraprise.com',
    role: 'SupportOperator',
    status: 'Active',
    lastLoginAt: '1 hour ago',
    twoFactorEnabled: true
  },
  {
    id: 'usr-03',
    name: 'Amit Patel',
    email: 'billing@floraprise.com',
    role: 'BillingAdmin',
    status: 'Active',
    lastLoginAt: 'Yesterday',
    twoFactorEnabled: false
  }
];

export const AdminUsersPage: React.FC = () => {
  const [admins] = useState<AdminUser[]>(INITIAL_ADMINS);

  const columns: Column<AdminUser>[] = [
    {
      key: 'name',
      header: 'Operator Name',
      sortable: true,
      render: (u) => (
        <div>
          <div className="font-bold text-slate-900">{u.name}</div>
          <div className="text-[11px] text-slate-500">{u.email}</div>
        </div>
      )
    },
    {
      key: 'role',
      header: 'Role & Permissions',
      sortable: true,
      render: (u) => (
        <span className={`text-xs font-bold px-2.5 py-1 rounded-full ${
          u.role === 'SuperAdmin' ? 'bg-emerald-100 text-emerald-800' : 'bg-slate-100 text-slate-700'
        }`}>
          {u.role}
        </span>
      )
    },
    {
      key: 'twoFactorEnabled',
      header: 'Hardware 2FA',
      render: (u) => (
        <span className={`text-xs font-semibold ${u.twoFactorEnabled ? 'text-emerald-700' : 'text-amber-700'}`}>
          {u.twoFactorEnabled ? '✓ Enabled' : '⚠️ Pending Setup'}
        </span>
      )
    },
    {
      key: 'lastLoginAt',
      header: 'Last Sign In',
      render: (u) => <span className="text-slate-600">{u.lastLoginAt}</span>
    },
    {
      key: 'status',
      header: 'Status',
      sortable: true,
      render: (u) => <StatusBadge status={u.status} size="sm" />
    }
  ];

  return (
    <div className="space-y-4">
      <div>
        <h2 className="text-xl font-black text-slate-900 flex items-center gap-2">
          <Users className="w-5 h-5 text-emerald-600" />
          <span>Central Admin Operators & RBAC</span>
        </h2>
        <p className="text-xs text-slate-500 mt-0.5">
          Authorized platform administrators, support engineers, and billing managers.
        </p>
      </div>

      <DataTable
        columns={columns}
        data={admins}
        searchPlaceholder="Search admin operators..."
        searchableKeys={['name', 'email', 'role']}
      />
    </div>
  );
};
