import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { realSubscriberService } from '../../services/api/realSubscriberService';
import { realDeviceService } from '../../services/api/realDeviceService';
import { Subscriber } from '../../types/subscriber';
import { Tabs, TabItem } from '../../components/common/Tabs';
import { StatusBadge } from '../../components/common/StatusBadge';
import { ConfirmDialog } from '../../components/common/ConfirmDialog';
import { ProvisioningCheckCard } from '../../components/provisioning/ProvisioningCheckCard';
import { ProvisioningModal } from '../../components/provisioning/ProvisioningModal';
import { useNotification } from '../../context/NotificationContext';
import { 
  Building2, 
  User, 
  Phone, 
  Mail, 
  MapPin, 
  CreditCard, 
  Smartphone, 
  Store, 
  Layers, 
  Truck, 
  LifeBuoy, 
  History,
  ShieldCheck,
  Wrench,
  AlertTriangle,
  CheckCircle,
  LogOut,
  ExternalLink,
  Plus,
  RefreshCw,
  ArrowLeft,
  Key,
  Clock,
  Ban,
  Play,
  RotateCcw
} from 'lucide-react';

export const Subscriber360Page: React.FC = () => {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const { showToast } = useNotification();
  const [subscriber, setSubscriber] = useState<Subscriber | null>(null);
  const [activeTab, setActiveTab] = useState<string>('overview');
  const [isProvisioningModalOpen, setIsProvisioningModalOpen] = useState(false);
  const [isProcessing, setIsProcessing] = useState(false);
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);

  const [confirmModal, setConfirmModal] = useState<{
    isOpen: boolean;
    title: string;
    message: string;
    confirmLabel: string;
    variant: 'danger' | 'warning' | 'primary';
    onConfirm: () => void;
  }>({
    isOpen: false,
    title: '',
    message: '',
    confirmLabel: 'Confirm',
    variant: 'primary',
    onConfirm: () => {}
  });

  const loadData = async () => {
    if (!id) return;
    setIsLoading(true);
    setError(null);
    try {
      const sub = await realSubscriberService.getSubscriberById(id);
      if (sub) {
        setSubscriber(sub);
      } else {
        setError(`Subscriber with ID ${id} not found in database.`);
      }
    } catch (err: any) {
      setError(err?.message || `Failed to load subscriber details (ID: ${id}).`);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    loadData();
  }, [id]);

  if (isLoading) {
    return (
      <div className="p-12 text-center text-slate-400 bg-white rounded-2xl border border-slate-200 space-y-3">
        <div className="animate-spin w-8 h-8 border-3 border-emerald-600 border-t-transparent rounded-full mx-auto" />
        <div className="text-xs font-semibold text-slate-600">Loading Subscriber 360 Workspace from Sumpooj.API...</div>
      </div>
    );
  }

  if (error || !subscriber) {
    return (
      <div className="space-y-4">
        <button
          onClick={() => navigate('/subscribers')}
          className="inline-flex items-center gap-1.5 text-xs text-slate-600 hover:text-slate-900 font-semibold cursor-pointer"
        >
          <ArrowLeft className="w-4 h-4" />
          <span>Back to Subscribers Directory</span>
        </button>

        <div className="p-6 rounded-2xl bg-rose-50 border border-rose-200 text-rose-900 space-y-3">
          <div className="flex items-start gap-3">
            <AlertTriangle className="w-6 h-6 text-rose-600 shrink-0 mt-0.5" />
            <div className="space-y-1">
              <div className="font-bold text-base text-rose-950">Subscriber Record Unavailable</div>
              <div className="text-xs text-rose-700">{error || `No subscriber record matching ID: ${id}`}</div>
            </div>
          </div>
          <div className="flex items-center gap-3 pt-2">
            <button
              onClick={loadData}
              className="inline-flex items-center gap-1.5 px-3.5 py-2 bg-rose-600 hover:bg-rose-700 text-white font-bold text-xs rounded-xl shadow-xs cursor-pointer"
            >
              <RefreshCw className="w-3.5 h-3.5" />
              <span>Retry</span>
            </button>
            <button
              onClick={() => navigate('/subscribers')}
              className="px-3.5 py-2 bg-white hover:bg-slate-50 text-slate-700 border border-slate-200 font-semibold text-xs rounded-xl shadow-xs cursor-pointer"
            >
              Return to Subscriber List
            </button>
          </div>
        </div>
      </div>
    );
  }

  const handleFixLocation = async () => {
    setIsProcessing(true);
    try {
      const updated = await realSubscriberService.autoRemediateLocation(subscriber.id);
      if (updated) {
        setSubscriber(updated);
        showToast('success', 'Location Provisioned', 'Created "Main Store" default location in database.');
      }
    } finally {
      setIsProcessing(false);
    }
  };

  const handleForceLogout = async (deviceId: string) => {
    const res = await realDeviceService.forceLogoutDevice(deviceId, subscriber.id);
    if (res.success) {
      showToast('success', 'Device Terminated', res.message);
      loadData();
    }
  };

  const tabs: TabItem[] = [
    { id: 'overview', label: 'Overview', icon: <Building2 className="w-4 h-4" /> },
    { id: 'subscription', label: 'Subscription', icon: <CreditCard className="w-4 h-4" /> },
    { id: 'locations', label: 'Locations', count: subscriber.locations.length, icon: <Store className="w-4 h-4" /> },
    { id: 'licenses', label: 'Licenses', count: subscriber.licenses?.length ?? 0, icon: <Key className="w-4 h-4" /> },
    { id: 'devices', label: 'Devices', count: subscriber.devices.length, icon: <Smartphone className="w-4 h-4" /> },
    { id: 'applications', label: 'Operational Modes', count: subscriber.operationalModes.length, icon: <Layers className="w-4 h-4" /> },
    { id: 'delivery', label: 'Delivery', icon: <Truck className="w-4 h-4" /> },
    { id: 'diagnostics', label: 'Provisioning Health', icon: <ShieldCheck className="w-4 h-4" /> },
    { id: 'activity', label: 'Audit Activity', count: subscriber.activityTimeline?.length ?? 0, icon: <History className="w-4 h-4" /> }
  ];

  return (
    <div className="space-y-6">
      {/* 360 Profile Hero Card */}
      <div className="bg-white p-6 rounded-3xl border border-slate-200/80 shadow-xs space-y-4">
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div className="flex items-start gap-4">
            <div className="w-14 h-14 rounded-2xl bg-emerald-100 border border-emerald-200 text-emerald-800 font-extrabold text-xl flex items-center justify-center shrink-0">
              {subscriber.businessName.charAt(0)}
            </div>
            <div>
              <div className="flex items-center gap-2.5 flex-wrap">
                <h1 className="text-2xl font-black text-slate-900">{subscriber.businessName}</h1>
                <StatusBadge status={subscriber.status} size="md" />
                <span className="text-xs px-2.5 py-0.5 rounded-full bg-slate-100 text-slate-700 font-medium">
                  {subscriber.planName}
                </span>
              </div>
              <div className="text-xs text-slate-500 mt-1 flex flex-wrap items-center gap-x-4 gap-y-1">
                <span className="font-mono text-slate-400">CompanyId: {subscriber.id}</span>
                <span>Owner: <strong className="text-slate-700">{subscriber.ownerName}</strong></span>
                <span>Mobile: <strong className="text-slate-700">{subscriber.mobile}</strong></span>
                <span>City: <strong className="text-slate-700">{subscriber.city}, {subscriber.state}</strong></span>
              </div>
            </div>
          </div>

          <div className="flex flex-wrap items-center gap-2 shrink-0">
            <button
              onClick={() => setIsProvisioningModalOpen(true)}
              className="inline-flex items-center gap-1.5 px-3.5 py-2 text-xs font-bold rounded-xl border border-slate-300 bg-white hover:bg-slate-50 text-slate-700 shadow-xs cursor-pointer transition-colors"
            >
              <ShieldCheck className="w-4 h-4 text-emerald-600" />
              <span>Audit Provisioning</span>
            </button>

            <a
              href={`https://erp.floraprise.com/admin/mobile/customers/${subscriber.id}/usr-01`}
              target="_blank"
              rel="noopener noreferrer"
              className="inline-flex items-center gap-1.5 px-3.5 py-2 text-xs font-bold rounded-xl bg-slate-900 hover:bg-slate-800 text-white shadow-xs cursor-pointer transition-colors"
            >
              <span>Launch in ERP</span>
              <ExternalLink className="w-3.5 h-3.5" />
            </a>
          </div>
        </div>

        {/* Warning if location is missing */}
        {subscriber.locations.length === 0 && (
          <div className="p-3.5 bg-rose-50 border border-rose-200 rounded-2xl text-xs text-rose-900 flex items-center justify-between gap-4">
            <div className="flex items-center gap-2.5">
              <AlertTriangle className="w-5 h-5 text-rose-600 shrink-0" />
              <div>
                <strong>Missing Default Location:</strong> This tenant has no location record. Cloud Production and Day Close will throw <code>"No active Cloud location is available"</code>.
              </div>
            </div>
            <button
              onClick={handleFixLocation}
              disabled={isProcessing}
              className="inline-flex items-center gap-1 px-3 py-1.5 rounded-xl bg-rose-600 hover:bg-rose-700 text-white font-bold text-xs shrink-0 cursor-pointer"
            >
              <Wrench className="w-3.5 h-3.5" />
              <span>{isProcessing ? 'Fixing...' : 'Auto-Create Location'}</span>
            </button>
          </div>
        )}
      </div>

      {/* 360 Tabs Navigation */}
      <div className="bg-white rounded-3xl border border-slate-200/80 shadow-xs overflow-hidden">
        <Tabs tabs={tabs} activeTab={activeTab} onChange={setActiveTab} className="px-6 pt-2" />

        <div className="p-6">
          {/* TAB 1: OVERVIEW */}
          {activeTab === 'overview' && (
            <div className="space-y-6">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                {/* Business Details */}
                <div className="space-y-3">
                  <h3 className="text-xs font-bold uppercase tracking-wider text-slate-400">Business & Contact Info</h3>
                  <div className="p-4 bg-slate-50 rounded-2xl border border-slate-100 space-y-2.5 text-xs">
                    <div className="flex justify-between py-1 border-b border-slate-200/60">
                      <span className="text-slate-500">Legal Name:</span>
                      <span className="font-bold text-slate-900">{subscriber.businessName}</span>
                    </div>
                    <div className="flex justify-between py-1 border-b border-slate-200/60">
                      <span className="text-slate-500">Owner Name:</span>
                      <span className="font-semibold text-slate-900">{subscriber.ownerName}</span>
                    </div>
                    <div className="flex justify-between py-1 border-b border-slate-200/60">
                      <span className="text-slate-500">Primary Mobile:</span>
                      <span className="font-semibold text-slate-900">{subscriber.mobile}</span>
                    </div>
                    <div className="flex justify-between py-1 border-b border-slate-200/60">
                      <span className="text-slate-500">Email:</span>
                      <span className="text-slate-800">{subscriber.email || 'None'}</span>
                    </div>
                    <div className="flex justify-between py-1 border-b border-slate-200/60">
                      <span className="text-slate-500">Address:</span>
                      <span className="text-slate-800 text-right max-w-xs">{subscriber.address}, {subscriber.city}, {subscriber.state} - {subscriber.pinCode}</span>
                    </div>
                    <div className="flex justify-between py-1">
                      <span className="text-slate-500">GSTIN / Tax ID:</span>
                      <span className="font-mono text-slate-800">{subscriber.gstin || 'Unregistered'}</span>
                    </div>
                  </div>
                </div>

                {/* Provisioning Health Card */}
                <div className="space-y-3">
                  <div className="flex items-center justify-between">
                    <h3 className="text-xs font-bold uppercase tracking-wider text-slate-400">Provisioning Verification</h3>
                    <span className="text-xs font-bold text-emerald-700">
                      {subscriber.provisioningChecks.filter(c => c.passed).length} / 10 Ready
                    </span>
                  </div>

                  <div className="p-4 bg-slate-50 rounded-2xl border border-slate-100 space-y-2 text-xs">
                    {subscriber.provisioningChecks.slice(0, 5).map(c => (
                      <div key={c.key} className="flex items-center justify-between py-1">
                        <span className="text-slate-600">{c.title}</span>
                        <StatusBadge status={c.status} size="sm" />
                      </div>
                    ))}
                    <button
                      onClick={() => setIsProvisioningModalOpen(true)}
                      className="w-full mt-2 py-2 text-center text-xs font-bold text-emerald-700 hover:bg-emerald-50 rounded-xl transition-colors cursor-pointer border border-emerald-200"
                    >
                      View All 10 Checks & Auto-Remediation →
                    </button>
                  </div>
                </div>
              </div>
            </div>
          )}

          {/* TAB 2: SUBSCRIPTION */}
          {activeTab === 'subscription' && (
            <div className="space-y-6">
              <div className="p-6 bg-slate-50 rounded-2xl border border-slate-200 space-y-4">
                <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
                  <div>
                    <span className="text-xs text-slate-500 font-medium">Subscription Tier & Plan</span>
                    <h4 className="text-lg font-extrabold text-slate-900">{subscriber.planName}</h4>
                  </div>
                  <div className="flex items-center gap-2">
                    <StatusBadge status={subscriber.subscriptionStatus} size="lg" />
                  </div>
                </div>

                <div className="grid grid-cols-2 md:grid-cols-4 gap-3 pt-2 text-xs">
                  <div className="p-3.5 bg-white rounded-xl border border-slate-200 shadow-2xs">
                    <span className="text-slate-400 block text-[10px] uppercase font-bold tracking-wider">Start Date</span>
                    <strong className="text-slate-800 text-sm">{subscriber.subscriptionStartedAt ? subscriber.subscriptionStartedAt.substring(0, 10) : 'N/A'}</strong>
                  </div>
                  <div className="p-3.5 bg-white rounded-xl border border-slate-200 shadow-2xs">
                    <span className="text-slate-400 block text-[10px] uppercase font-bold tracking-wider">Expiry Date</span>
                    <strong className="text-slate-800 text-sm">{subscriber.subscriptionExpiresAt ? subscriber.subscriptionExpiresAt.substring(0, 10) : 'N/A'}</strong>
                  </div>
                  <div className="p-3.5 bg-white rounded-xl border border-slate-200 shadow-2xs">
                    <span className="text-slate-400 block text-[10px] uppercase font-bold tracking-wider">Max Device Cap</span>
                    <strong className="text-slate-800 text-sm">{subscriber.activeDevicesCount} / {subscriber.maxDevices} Devices</strong>
                  </div>
                  <div className="p-3.5 bg-white rounded-xl border border-slate-200 shadow-2xs">
                    <span className="text-slate-400 block text-[10px] uppercase font-bold tracking-wider">Staff Limit</span>
                    <strong className="text-slate-800 text-sm">{subscriber.maxStaff} Staff Accounts</strong>
                  </div>
                </div>

                {/* Administrative Write Actions for Subscription */}
                <div className="pt-4 border-t border-slate-200/80 flex flex-wrap items-center gap-2.5">
                  <button
                    onClick={() => {
                      setConfirmModal({
                        isOpen: true,
                        title: 'Extend Subscription Term',
                        message: `Are you sure you want to add 30 days to the license validity for "${subscriber.businessName}"? Expiry date will be shifted forward by 30 days.`,
                        confirmLabel: 'Extend +30 Days',
                        variant: 'primary',
                        onConfirm: async () => {
                          const userId = subscriber.mobileUserId || subscriber.users[0]?.id;
                          if (!userId) {
                            showToast('error', 'Action Failed', 'Mobile user ID not found for this subscriber.');
                            return;
                          }
                          const res = await realSubscriberService.extendSubscriptionTerm(subscriber.id, userId, 30);
                          if (res.success) {
                            showToast('success', 'Term Extended', res.message);
                            loadData();
                          } else {
                            showToast('error', 'Extension Failed', res.message);
                          }
                        }
                      });
                    }}
                    className="inline-flex items-center gap-1.5 px-3.5 py-2 text-xs font-bold rounded-xl border border-emerald-300 bg-emerald-50 text-emerald-800 hover:bg-emerald-100 shadow-xs cursor-pointer transition-colors"
                  >
                    <Clock className="w-3.5 h-3.5" />
                    <span>Extend Term (+30 Days)</span>
                  </button>

                  <button
                    onClick={() => {
                      const planCycle = (subscriber.planId?.toUpperCase().includes('QUARTER') ? 'quarterly'
                        : subscriber.planId?.toUpperCase().includes('HALF') ? 'half_yearly'
                        : subscriber.planId?.toUpperCase().includes('MONTH') ? 'monthly'
                        : 'annual');

                      setConfirmModal({
                        isOpen: true,
                        title: 'Renew Subscription',
                        message: `Renew subscription for "${subscriber.businessName}" under plan ${subscriber.planName} (${planCycle.toUpperCase()} cycle)? This will extend the validity term and activate full cloud privileges based on backend plan rules.`,
                        confirmLabel: 'Renew Subscription',
                        variant: 'primary',
                        onConfirm: async () => {
                          const userId = subscriber.mobileUserId || subscriber.users[0]?.id;
                          if (!userId) {
                            showToast('error', 'Action Failed', 'Mobile user ID not found for this subscriber.');
                            return;
                          }
                          const res = await realSubscriberService.renewSubscription(subscriber.id, userId, planCycle, true);
                          if (res.success) {
                            showToast('success', 'Subscription Renewed', res.message);
                            loadData();
                          } else {
                            showToast('error', 'Renewal Failed', res.message);
                          }
                        }
                      });
                    }}
                    className="inline-flex items-center gap-1.5 px-3.5 py-2 text-xs font-bold rounded-xl border border-slate-300 bg-white hover:bg-slate-50 text-slate-800 shadow-xs cursor-pointer transition-colors"
                  >
                    <RefreshCw className="w-3.5 h-3.5 text-slate-600" />
                    <span>Renew Subscription</span>
                  </button>

                  {subscriber.subscriptionStatus === 'Active' || subscriber.subscriptionStatus === 'Trial' ? (
                    <button
                      onClick={() => {
                        setConfirmModal({
                          isOpen: true,
                          title: 'Suspend Subscriber Account',
                          message: `Are you sure you want to SUSPEND "${subscriber.businessName}"? Connected mobile devices and web clients will be blocked from API operations.`,
                          confirmLabel: 'Suspend Account',
                          variant: 'danger',
                          onConfirm: async () => {
                            const userId = subscriber.mobileUserId || subscriber.users[0]?.id;
                            if (!userId) {
                              showToast('error', 'Action Failed', 'Mobile user ID not found for this subscriber.');
                              return;
                            }
                            const res = await realSubscriberService.suspendSubscription(subscriber.id, userId);
                            if (res.success) {
                              showToast('success', 'Account Suspended', res.message);
                              loadData();
                            } else {
                              showToast('error', 'Suspension Failed', res.message);
                            }
                          }
                        });
                      }}
                      className="inline-flex items-center gap-1.5 px-3.5 py-2 text-xs font-bold rounded-xl border border-rose-200 bg-rose-50 hover:bg-rose-100 text-rose-800 shadow-xs cursor-pointer transition-colors"
                    >
                      <Ban className="w-3.5 h-3.5" />
                      <span>Suspend Subscriber</span>
                    </button>
                  ) : (
                    <button
                      onClick={() => {
                        setConfirmModal({
                          isOpen: true,
                          title: 'Reactivate Subscriber Account',
                          message: `Reactivate subscriber "${subscriber.businessName}" and restore operational cloud permissions?`,
                          confirmLabel: 'Reactivate Account',
                          variant: 'primary',
                          onConfirm: async () => {
                            const res = await realSubscriberService.activateSubscriber(subscriber.id);
                            if (res.success) {
                              showToast('success', 'Account Reactivated', res.message);
                              loadData();
                            } else {
                              showToast('error', 'Activation Failed', res.message);
                            }
                          }
                        });
                      }}
                      className="inline-flex items-center gap-1.5 px-3.5 py-2 text-xs font-bold rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white shadow-xs cursor-pointer transition-colors"
                    >
                      <CheckCircle className="w-3.5 h-3.5" />
                      <span>Reactivate / Resume</span>
                    </button>
                  )}
                </div>
              </div>
            </div>
          )}

          {/* TAB 3: LOCATIONS */}
          {activeTab === 'locations' && (
            <div className="space-y-4">
              <div className="flex justify-between items-center">
                <span className="text-xs text-slate-500">Configured Store & Warehouse Locations</span>
                <span className="text-xs font-bold text-slate-700">{subscriber.locations.length} Locations</span>
              </div>

              {subscriber.locations.length > 0 ? (
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  {subscriber.locations.map(loc => (
                    <div key={loc.id} className="p-4 bg-slate-50 rounded-2xl border border-slate-200 space-y-2 text-xs">
                      <div className="flex items-center justify-between">
                        <div className="flex items-center gap-2">
                          <Store className="w-4 h-4 text-emerald-600" />
                          <div className="font-bold text-slate-900">{loc.name}</div>
                          {loc.isDefault && (
                            <span className="text-[10px] bg-emerald-100 text-emerald-800 px-2 py-0.5 rounded-full font-bold">
                              Default
                            </span>
                          )}
                        </div>
                        <StatusBadge status={loc.isActive ? 'Active' : 'Inactive'} size="sm" />
                      </div>
                      <div className="text-[11px] text-slate-500 space-y-0.5">
                        <div>Code: <strong className="font-mono">{loc.code}</strong> • Type: <strong>{loc.type}</strong></div>
                        <div>Address: {loc.address || 'Same as primary shop address'}</div>
                        <div className="text-[10px] text-slate-400 font-mono">LocationId: {loc.id}</div>
                      </div>
                    </div>
                  ))}
                </div>
              ) : (
                <div className="p-8 text-center text-rose-700 bg-rose-50 rounded-2xl border border-rose-200 space-y-2">
                  <AlertTriangle className="w-8 h-8 mx-auto text-rose-600" />
                  <div className="font-bold text-sm">Zero Active Locations Found</div>
                  <p className="text-xs max-w-md mx-auto text-rose-800">
                    This company has zero rows in <code>public."Locations"</code>. Bouquet Production and Day Close will fail until a default location is provisioned.
                  </p>
                  <button
                    onClick={handleFixLocation}
                    className="inline-flex items-center gap-1.5 px-4 py-2 bg-emerald-600 hover:bg-emerald-700 text-white rounded-xl text-xs font-bold cursor-pointer mt-2"
                  >
                    <Plus className="w-4 h-4" />
                    <span>Auto-Provision "Main Store" Location</span>
                  </button>
                </div>
              )}
            </div>
          )}

          {/* TAB 4: LICENSES */}
          {activeTab === 'licenses' && (
            <div className="space-y-4">
              <div className="flex justify-between items-center">
                <span className="text-xs text-slate-500">Issued Tenant Device & Operational Licenses</span>
                <span className="text-xs font-bold text-slate-700">{subscriber.licenses?.length ?? 0} Total Licenses</span>
              </div>

              {subscriber.licenses && subscriber.licenses.length > 0 ? (
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  {subscriber.licenses.map(lic => {
                    const linkedDevice = subscriber.devices.find(d => 
                      d.licenseKey?.toUpperCase() === lic.licenseNumber.toUpperCase() ||
                      d.id === lic.id
                    );
                    const isSuspended = lic.status?.toUpperCase().includes('SUSPEND');
                    const isExpired = lic.status?.toUpperCase().includes('EXPIRE') || lic.remainingDays <= 0;

                    return (
                      <div key={lic.id} className="p-4 bg-slate-50 rounded-2xl border border-slate-200 space-y-3 text-xs">
                        <div className="flex items-center justify-between">
                          <div className="flex items-center gap-2">
                            <Key className="w-4 h-4 text-emerald-600" />
                            <code className="font-bold text-slate-900">{lic.licenseNumber}</code>
                          </div>
                          <StatusBadge status={lic.status} size="sm" />
                        </div>

                        <div className="text-[11px] text-slate-500 space-y-1 pt-1">
                          <div>Plan: <strong className="text-slate-800">{lic.plan}</strong></div>
                          <div>Issued: <strong>{lic.issuedAt ? new Date(lic.issuedAt).toLocaleDateString() : 'N/A'}</strong></div>
                          <div>
                            Expires: <strong>{lic.expiresAt ? new Date(lic.expiresAt).toLocaleDateString() : 'Active Perpetual / Annual'}</strong> ({lic.remainingDays} days remaining)
                          </div>
                          <div className="text-[10px] text-slate-400 font-mono">LicenseId: {lic.id}</div>
                          
                          {/* Device Relationship Badge */}
                          <div className="pt-1.5 flex items-center gap-1.5 flex-wrap">
                            <span className="text-[10px] text-slate-400">Device Binding:</span>
                            {linkedDevice ? (
                              <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-md text-[10px] font-bold bg-emerald-100 text-emerald-800">
                                <Smartphone className="w-3 h-3" />
                                <span>{linkedDevice.deviceName} ({linkedDevice.platform})</span>
                              </span>
                            ) : (
                              <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-md text-[10px] font-medium bg-slate-200 text-slate-600">
                                Unassigned / Available for Pairing
                              </span>
                            )}
                            {(isSuspended || isExpired) && (
                              <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-md text-[10px] font-bold bg-amber-100 text-amber-800">
                                NEEDS ATTENTION
                              </span>
                            )}
                          </div>
                        </div>

                        {/* License Action Toolbar */}
                        <div className="pt-2 border-t border-slate-200/80 flex items-center justify-end gap-2">
                          <button
                            onClick={() => {
                              setConfirmModal({
                                isOpen: true,
                                title: 'Extend License Validity',
                                message: `Extend validity of license "${lic.licenseNumber}" by 30 days?`,
                                confirmLabel: 'Extend +30 Days',
                                variant: 'primary',
                                onConfirm: async () => {
                                  const res = await realDeviceService.extendLicense(lic.id, subscriber.id, 30);
                                  if (res.success) {
                                    showToast('success', 'License Extended', res.message);
                                    loadData();
                                  } else {
                                    showToast('error', 'Extension Failed', res.message);
                                  }
                                }
                              });
                            }}
                            className="inline-flex items-center gap-1 px-2.5 py-1 text-[11px] font-bold text-emerald-700 hover:bg-emerald-100 rounded-lg cursor-pointer transition-colors"
                          >
                            <Clock className="w-3 h-3" />
                            <span>Extend (+30d)</span>
                          </button>

                          {isSuspended ? (
                            <button
                              onClick={() => {
                                setConfirmModal({
                                  isOpen: true,
                                  title: 'Resume License',
                                  message: `Reactivate and resume license "${lic.licenseNumber}"?`,
                                  confirmLabel: 'Resume License',
                                  variant: 'primary',
                                  onConfirm: async () => {
                                    const res = await realDeviceService.resumeLicense(lic.id, subscriber.id);
                                    if (res.success) {
                                      showToast('success', 'License Resumed', res.message);
                                      loadData();
                                    } else {
                                      showToast('error', 'Action Failed', res.message);
                                    }
                                  }
                                });
                              }}
                              className="inline-flex items-center gap-1 px-2.5 py-1 text-[11px] font-bold text-emerald-700 hover:bg-emerald-100 rounded-lg cursor-pointer transition-colors"
                            >
                              <Play className="w-3 h-3" />
                              <span>Resume</span>
                            </button>
                          ) : (
                            <button
                              onClick={() => {
                                setConfirmModal({
                                  isOpen: true,
                                  title: 'Suspend License',
                                  message: `Suspend license "${lic.licenseNumber}"? Paired devices will be prevented from authorizing cloud sessions.`,
                                  confirmLabel: 'Suspend License',
                                  variant: 'warning',
                                  onConfirm: async () => {
                                    const res = await realDeviceService.suspendLicense(lic.id, subscriber.id);
                                    if (res.success) {
                                      showToast('success', 'License Suspended', res.message);
                                      loadData();
                                    } else {
                                      showToast('error', 'Action Failed', res.message);
                                    }
                                  }
                                });
                              }}
                              className="inline-flex items-center gap-1 px-2.5 py-1 text-[11px] font-bold text-amber-700 hover:bg-amber-100 rounded-lg cursor-pointer transition-colors"
                            >
                              <Ban className="w-3 h-3" />
                              <span>Suspend</span>
                            </button>
                          )}
                        </div>
                      </div>
                    );
                  })}
                </div>
              ) : (
                <div className="p-8 text-center text-slate-400 bg-slate-50 rounded-2xl border border-slate-200 space-y-1">
                  <Key className="w-6 h-6 mx-auto text-slate-400 mb-1" />
                  <div className="font-semibold text-xs text-slate-600">No standalone licenses issued yet.</div>
                  <div className="text-[11px] text-slate-400">Device licenses are bound automatically when devices pair with this tenant.</div>
                </div>
              )}
            </div>
          )}

          {/* TAB 5: DEVICES */}
          {activeTab === 'devices' && (
            <div className="space-y-4">
              <div className="flex justify-between items-center">
                <span className="text-xs text-slate-500">Registered Operational Devices & Terminals</span>
                <span className="text-xs font-bold text-slate-700">{subscriber.devices.length} / {subscriber.maxDevices} Devices</span>
              </div>

              {subscriber.devices.length > 0 ? (
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  {subscriber.devices.map(dev => {
                    const hasLicense = Boolean(dev.licenseKey && dev.licenseKey !== 'N/A' && dev.licenseKey !== '');
                    const isDeactivated = dev.status === 'Deactivated';

                    return (
                      <div key={dev.id} className="p-4 bg-slate-50 rounded-2xl border border-slate-200 space-y-2.5 text-xs">
                        <div className="flex items-start justify-between">
                          <div>
                            <div className="font-bold text-slate-900">{dev.deviceName}</div>
                            <div className="text-[11px] text-slate-500">{dev.deviceModel} ({dev.platform})</div>
                          </div>
                          <StatusBadge status={dev.status} size="sm" />
                        </div>

                        <div className="text-[11px] text-slate-500 space-y-0.5 pt-1">
                          <div>Operational Mode: <strong>{dev.operationalMode}</strong></div>
                          <div>App Release: <strong>{dev.appVersion}</strong></div>
                          <div>Last Telemetry Ping: <strong>{dev.lastSeenAt}</strong> ({dev.ipAddress})</div>
                          <div className="flex items-center gap-1.5 flex-wrap pt-0.5">
                            <span>License Binding:</span>
                            {hasLicense ? (
                              <code className="text-emerald-700 font-bold bg-emerald-50 px-1.5 py-0.5 rounded border border-emerald-200">{dev.licenseKey}</code>
                            ) : (
                              <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-md text-[10px] font-bold bg-amber-100 text-amber-800">
                                NEEDS ATTENTION: Unbound
                              </span>
                            )}
                          </div>
                        </div>

                        {/* Device Action Toolbar */}
                        <div className="pt-2 border-t border-slate-200/80 flex items-center justify-end gap-1.5 flex-wrap">
                          <button
                            onClick={() => {
                              setConfirmModal({
                                isOpen: true,
                                title: 'Disconnect Device Session',
                                message: `Force logout active session for device "${dev.deviceName}"? The device operator will be prompted to re-authenticate.`,
                                confirmLabel: 'Disconnect Session',
                                variant: 'warning',
                                onConfirm: async () => {
                                  const res = await realDeviceService.forceLogoutDevice(dev.id, subscriber.id);
                                  if (res.success) {
                                    showToast('success', 'Session Terminated', res.message);
                                    loadData();
                                  } else {
                                    showToast('error', 'Logout Failed', res.message);
                                  }
                                }
                              });
                            }}
                            disabled={isDeactivated}
                            className="inline-flex items-center gap-1 px-2.5 py-1 text-[11px] font-bold text-slate-700 hover:bg-slate-200/70 rounded-lg disabled:opacity-40 cursor-pointer transition-colors"
                          >
                            <LogOut className="w-3.5 h-3.5 text-slate-600" />
                            <span>Force Logout</span>
                          </button>

                          <button
                            onClick={() => {
                              setConfirmModal({
                                isOpen: true,
                                title: 'Disable Device Access',
                                message: `Disable device "${dev.deviceName}"? It will not be permitted to connect or synchronize until administratively re-enabled.`,
                                confirmLabel: 'Disable Device',
                                variant: 'danger',
                                onConfirm: async () => {
                                  const res = await realDeviceService.disableDevice(dev.id, subscriber.id);
                                  if (res.success) {
                                    showToast('success', 'Device Disabled', res.message);
                                    loadData();
                                  } else {
                                    showToast('error', 'Action Failed', res.message);
                                  }
                                }
                              });
                            }}
                            disabled={isDeactivated}
                            className="inline-flex items-center gap-1 px-2.5 py-1 text-[11px] font-bold text-rose-700 hover:bg-rose-100 rounded-lg disabled:opacity-40 cursor-pointer transition-colors"
                          >
                            <Ban className="w-3.5 h-3.5" />
                            <span>Disable</span>
                          </button>

                          <button
                            onClick={() => {
                              setConfirmModal({
                                isOpen: true,
                                title: 'Reset Device Binding',
                                message: `Reset device "${dev.deviceName}"? This will unbind its license key and reset device pairing tokens.`,
                                confirmLabel: 'Reset Device',
                                variant: 'danger',
                                onConfirm: async () => {
                                  const res = await realDeviceService.resetDevice(dev.id, subscriber.id);
                                  if (res.success) {
                                    showToast('success', 'Device Reset', res.message);
                                    loadData();
                                  } else {
                                    showToast('error', 'Action Failed', res.message);
                                  }
                                }
                              });
                            }}
                            className="inline-flex items-center gap-1 px-2.5 py-1 text-[11px] font-bold text-amber-700 hover:bg-amber-100 rounded-lg cursor-pointer transition-colors"
                          >
                            <RotateCcw className="w-3.5 h-3.5" />
                            <span>Reset Pairing</span>
                          </button>
                        </div>
                      </div>
                    );
                  })}
                </div>
              ) : (
                <div className="p-8 text-center text-slate-400 bg-slate-50 rounded-2xl border border-slate-200">
                  No registered active devices found for this tenant.
                </div>
              )}
            </div>
          )}

          {/* TAB 6: APPLICATIONS / OPERATIONAL MODES */}
          {activeTab === 'applications' && (
            <div className="space-y-4">
              <h4 className="text-xs font-bold uppercase tracking-wider text-slate-400">Entitled Operational Clients</h4>
              <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
                {subscriber.operationalModes.map(mode => (
                  <div key={mode} className="p-4 bg-slate-50 rounded-2xl border border-slate-200 text-xs space-y-1">
                    <div className="font-bold text-slate-900">{mode}</div>
                    <div className="text-[11px] text-slate-500">
                      {mode.includes('Android') && 'Native Flutter Android POS & Scanner client'}
                      {mode.includes('Web') && 'Browser-based Flutter Web Desktop client'}
                      {mode.includes('Solo') && 'Standalone SQLite offline desktop client'}
                    </div>
                    <div className="pt-2 text-[10px] text-emerald-700 font-bold">✓ Entitled & License Valid</div>
                  </div>
                ))}
              </div>

              <div className="pt-4 space-y-2">
                <h4 className="text-xs font-bold uppercase tracking-wider text-slate-400">Enabled Cloud Capabilities</h4>
                <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-2 text-xs">
                  {subscriber.enabledCloudServices.map(svc => (
                    <div key={svc} className="p-3 bg-white rounded-xl border border-slate-200 flex items-center gap-2">
                      <CheckCircle className="w-4 h-4 text-emerald-600 shrink-0" />
                      <span className="text-slate-800 font-medium">{svc}</span>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          )}

          {/* TAB 7: DELIVERY */}
          {activeTab === 'delivery' && (
            <div className="space-y-4">
              <div className="p-6 bg-slate-50 rounded-2xl border border-slate-200 space-y-3">
                <div className="flex items-start gap-3">
                  <Truck className="w-6 h-6 text-slate-400 shrink-0 mt-0.5" />
                  <div className="space-y-1">
                    <div className="font-bold text-sm text-slate-800">Delivery Fleet & Driver Telemetry</div>
                    <div className="text-xs text-slate-500">
                      Real-time driver location tracking, dispatch control, and proof-of-delivery sync.
                    </div>
                  </div>
                </div>

                <div className="p-4 bg-white rounded-xl border border-slate-200 text-xs text-slate-600 space-y-2">
                  <div className="flex items-center justify-between">
                    <span className="text-slate-500">Integration Status:</span>
                    <span className="px-2 py-0.5 rounded-full text-[10px] font-bold bg-amber-100 text-amber-800">
                      Not connected yet
                    </span>
                  </div>
                  <div className="flex justify-between py-1 border-t border-slate-100">
                    <span className="text-slate-500">Assigned Delivery Fleet:</span>
                    <span className="font-semibold text-slate-700">None assigned</span>
                  </div>
                  <div className="flex justify-between py-1 border-t border-slate-100">
                    <span className="text-slate-500">Active Drivers:</span>
                    <span className="text-slate-700">0 drivers registered</span>
                  </div>
                </div>

                <div className="pt-2 flex items-center justify-end gap-2 flex-wrap">
                  <button
                    onClick={() => navigate('/delivery/live')}
                    className="inline-flex items-center gap-1.5 px-3.5 py-2 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-700 font-bold text-xs cursor-pointer transition-colors"
                  >
                    <span>Delivery Architecture</span>
                  </button>
                  <a
                    href="https://erp.floraprise.com/delivery-routes"
                    target="_blank"
                    rel="noopener noreferrer"
                    className="inline-flex items-center gap-1.5 px-3.5 py-2 rounded-xl bg-slate-900 hover:bg-slate-800 text-white font-bold text-xs cursor-pointer transition-colors"
                  >
                    <span>Open ERP Delivery Control Center</span>
                    <ExternalLink className="w-3.5 h-3.5" />
                  </a>
                </div>
              </div>
            </div>
          )}

          {/* TAB 8: DIAGNOSTICS / PROVISIONING HEALTH */}
          {activeTab === 'diagnostics' && (
            <div className="space-y-3">
              <div className="flex items-center justify-between">
                <h4 className="text-xs font-bold uppercase tracking-wider text-slate-400">10-Point Provisioning Audit</h4>
                <button
                  onClick={() => setIsProvisioningModalOpen(true)}
                  className="text-xs font-bold text-emerald-700 hover:underline cursor-pointer"
                >
                  Interactive Auditor Mode
                </button>
              </div>

              <div className="space-y-2.5">
                {subscriber.provisioningChecks.map(chk => (
                  <ProvisioningCheckCard
                    key={chk.key}
                    check={chk}
                    onRemediate={chk.key === 'location' ? handleFixLocation : undefined}
                  />
                ))}
              </div>
            </div>
          )}

          {/* TAB 9: ACTIVITY / AUDIT */}
          {activeTab === 'activity' && (
            <div className="space-y-4 text-xs">
              <div className="flex justify-between items-center">
                <h4 className="text-xs font-bold uppercase tracking-wider text-slate-400">Live Tenant Activity & Audit Trail</h4>
                <span className="text-xs text-slate-500">{subscriber.activityTimeline?.length ?? 0} Recorded Events</span>
              </div>

              {subscriber.activityTimeline && subscriber.activityTimeline.length > 0 ? (
                <div className="space-y-2.5">
                  {subscriber.activityTimeline.map((item, idx) => (
                    <div key={idx} className="p-3.5 bg-slate-50 rounded-2xl border border-slate-200 flex items-start justify-between gap-4">
                      <div className="space-y-1">
                        <div className="flex items-center gap-2">
                          <span className="px-2 py-0.5 rounded-md text-[10px] font-bold uppercase tracking-wider bg-slate-200 text-slate-700">
                            {item.category}
                          </span>
                          <span className="font-bold text-slate-900">{item.title}</span>
                        </div>
                        <div className="text-[11px] text-slate-600">{item.description}</div>
                      </div>
                      <span className="text-[10px] text-slate-400 shrink-0 font-mono">
                        {item.timestamp ? new Date(item.timestamp).toLocaleString('en-IN', { timeZone: 'Asia/Kolkata' }) : ''}
                      </span>
                    </div>
                  ))}
                </div>
              ) : (
                <div className="p-8 text-center text-slate-400 bg-slate-50 rounded-2xl border border-slate-200">
                  No recent audit activity recorded for this tenant.
                </div>
              )}
            </div>
          )}
        </div>
      </div>

      {/* Provisioning Verification Modal */}
      <ProvisioningModal
        isOpen={isProvisioningModalOpen}
        onClose={() => setIsProvisioningModalOpen(false)}
        subscriber={subscriber}
        onUpdated={loadData}
      />

      {/* Lifecycle Action Confirmation Modal */}
      <ConfirmDialog
        isOpen={confirmModal.isOpen}
        onClose={() => setConfirmModal(prev => ({ ...prev, isOpen: false }))}
        onConfirm={confirmModal.onConfirm}
        title={confirmModal.title}
        message={confirmModal.message}
        confirmLabel={confirmModal.confirmLabel}
        variant={confirmModal.variant}
      />
    </div>
  );
};
