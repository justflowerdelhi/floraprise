import React, { useState, useEffect } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import { realDeviceService } from '../../services/api/realDeviceService';
import { SubscriberDevice } from '../../types/subscriber';
import { DataTable, Column } from '../../components/common/DataTable';
import { StatusBadge } from '../../components/common/StatusBadge';
import { useNotification } from '../../context/NotificationContext';
import { Smartphone, LogOut, ShieldAlert } from 'lucide-react';

export const DevicesListPage: React.FC = () => {
  const location = useLocation();
  const navigate = useNavigate();
  const { showToast } = useNotification();
  const [devices, setDevices] = useState<SubscriberDevice[]>([]);

  let initialPlatformFilter = 'all';
  if (location.pathname.includes('/android')) initialPlatformFilter = 'Android';
  else if (location.pathname.includes('/solo')) initialPlatformFilter = 'Solo';
  else if (location.pathname.includes('/web')) initialPlatformFilter = 'Web';

  const [selectedPlatform, setSelectedPlatform] = useState<string>(initialPlatformFilter);

  const loadData = () => {
    realDeviceService.getAllDevices().then(setDevices).catch(() => setDevices([]));
  };

  useEffect(() => {
    loadData();
  }, []);

  const handleForceLogout = async (deviceId: string) => {
    const res = await realDeviceService.forceLogoutDevice(deviceId);
    if (res.success) {
      showToast('success', 'Device Session Terminated', res.message);
      loadData();
    }
  };

  const filtered = devices.filter(d => {
    if (selectedPlatform === 'all') return true;
    if (selectedPlatform === 'Android') return d.platform === 'Android' && d.operationalMode === 'Flutter Cloud Android';
    if (selectedPlatform === 'Solo') return d.operationalMode === 'Flutter Solo';
    if (selectedPlatform === 'Web') return d.platform === 'Web' || d.operationalMode === 'Flutter Web';
    return true;
  });

  const columns: Column<SubscriberDevice>[] = [
    {
      key: 'deviceName',
      header: 'Device & Hardware',
      sortable: true,
      render: (d) => (
        <div>
          <div className="font-bold text-slate-900">{d.deviceName}</div>
          <div className="text-[11px] text-slate-500">{d.deviceModel} • {d.platform}</div>
        </div>
      )
    },
    {
      key: 'operationalMode',
      header: 'Operational Mode',
      sortable: true,
      render: (d) => (
        <span className="text-xs font-semibold text-slate-800">
          {d.operationalMode}
        </span>
      )
    },
    {
      key: 'appVersion',
      header: 'App Version',
      sortable: true,
      render: (d) => (
        <span className="font-mono text-xs text-slate-700 bg-slate-100 px-2 py-0.5 rounded">
          {d.appVersion}
        </span>
      )
    },
    {
      key: 'licenseKey',
      header: 'License Key',
      render: (d) => (
        <span className="font-mono text-[11px] font-bold text-emerald-800 bg-emerald-50 px-2 py-0.5 rounded border border-emerald-200">
          {d.licenseKey}
        </span>
      )
    },
    {
      key: 'lastSeenAt',
      header: 'Telemetry & IP',
      render: (d) => (
        <div>
          <div className="text-xs text-slate-800">{d.lastSeenAt}</div>
          <div className="text-[10px] font-mono text-slate-400">{d.ipAddress}</div>
        </div>
      )
    },
    {
      key: 'status',
      header: 'Status',
      sortable: true,
      render: (d) => <StatusBadge status={d.status} size="sm" />
    },
    {
      key: 'actions',
      header: 'Actions',
      align: 'right',
      render: (d) => (
        <button
          onClick={() => handleForceLogout(d.id)}
          disabled={d.status === 'Deactivated'}
          title="Force Revoke / Disconnect"
          className="p-1.5 rounded-lg text-rose-600 hover:bg-rose-50 disabled:opacity-40 cursor-pointer"
        >
          <LogOut className="w-4 h-4" />
        </button>
      )
    }
  ];

  return (
    <div className="space-y-4">
      <div>
        <h2 className="text-xl font-black text-slate-900 flex items-center gap-2">
          <Smartphone className="w-5 h-5 text-emerald-600" />
          <span>Device Registry & Active Sessions</span>
        </h2>
        <p className="text-xs text-slate-500 mt-0.5">
          Connected POS tablets, Web browser sessions, and offline Solo SQLite installations.
        </p>
      </div>

      <DataTable
        columns={columns}
        data={filtered}
        searchPlaceholder="Search devices by name, model, license..."
        searchableKeys={['deviceName', 'deviceModel', 'licenseKey', 'ipAddress']}
        filters={
          <select
            value={selectedPlatform}
            onChange={e => setSelectedPlatform(e.target.value)}
            className="px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs text-slate-800 focus:bg-white focus:outline-none focus:ring-2 focus:ring-emerald-500/20"
          >
            <option value="all">All Devices ({devices.length})</option>
            <option value="Android">Flutter Cloud Android</option>
            <option value="Solo">Flutter Solo Offline</option>
            <option value="Web">Flutter Web</option>
          </select>
        }
      />
    </div>
  );
};
