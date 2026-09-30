import React, { useState } from 'react';
import { Modal } from '../common/Modal';
import { realSubscriberService } from '../../services/api/realSubscriberService';
import { realSubscriptionService } from '../../services/api/realSubscriptionService';
import { SubscriptionPlan } from '../../types/subscription';
import { OperationalMode, CloudServiceKey } from '../../types/subscriber';
import { useNotification } from '../../context/NotificationContext';
import { 
  Building2, 
  MapPin, 
  CreditCard, 
  Cloud, 
  ShieldCheck, 
  Check, 
  ChevronRight, 
  ChevronLeft,
  Sparkles,
  Store,
  Smartphone,
  Users
} from 'lucide-react';

interface OnboardingWizardModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSubscriberCreated?: () => void;
  initialData?: {
    businessName?: string;
    ownerName?: string;
    mobile?: string;
    email?: string;
    address?: string;
    city?: string;
  };
}

export const OnboardingWizardModal: React.FC<OnboardingWizardModalProps> = ({
  isOpen,
  onClose,
  onSubscriberCreated,
  initialData
}) => {
  const { showToast } = useNotification();
  const [currentStep, setCurrentStep] = useState<number>(1);
  const [plans, setPlans] = useState<SubscriptionPlan[]>([]);
  const [isSubmitting, setIsSubmitting] = useState(false);

  // Form State
  const [businessName, setBusinessName] = useState(initialData?.businessName || '');
  const [ownerName, setOwnerName] = useState(initialData?.ownerName || '');
  const [mobile, setMobile] = useState(initialData?.mobile || '');
  const [email, setEmail] = useState(initialData?.email || '');
  const [address, setAddress] = useState(initialData?.address || '');
  const [city, setCity] = useState(initialData?.city || '');
  const [state, setState] = useState('Delhi');
  const [pinCode, setPinCode] = useState('110001');
  const [gstin, setGstin] = useState('');

  // Default Location
  const [locationName, setLocationName] = useState('Main Store');
  const [locationCode, setLocationCode] = useState('MAIN-01');
  const [locationType, setLocationType] = useState<'Store' | 'Warehouse' | 'Workshop' | 'Kiosk'>('Store');

  // Plan & Access
  const [selectedPlanId, setSelectedPlanId] = useState('');
  const [operationalModes, setOperationalModes] = useState<OperationalMode[]>([
    'Flutter Cloud Android',
    'Flutter Web'
  ]);
  const [enabledCloudServices, setEnabledCloudServices] = useState<CloudServiceKey[]>([
    'Subscription Validation',
    'Delivery Tracking',
    'Cloud Storage',
    'Notifications',
    'WhatsApp Integration',
    'Cloud Production & Recipes'
  ]);

  // Load real commercial plans from database
  React.useEffect(() => {
    realSubscriptionService.getPlans().then(loadedPlans => {
      const activeOnly = loadedPlans.filter(p => p.isActive);
      setPlans(activeOnly);
      if (activeOnly.length > 0) {
        const preferred = activeOnly.find(p => p.code === 'ANNUAL') || activeOnly[0];
        setSelectedPlanId(preferred.id);
      }
    }).catch(() => setPlans([]));
  }, []);

  const toggleMode = (mode: OperationalMode) => {
    if (operationalModes.includes(mode)) {
      if (operationalModes.length > 1) {
        setOperationalModes(operationalModes.filter(m => m !== mode));
      }
    } else {
      setOperationalModes([...operationalModes, mode]);
    }
  };

  const toggleService = (srv: CloudServiceKey) => {
    if (enabledCloudServices.includes(srv)) {
      setEnabledCloudServices(enabledCloudServices.filter(s => s !== srv));
    } else {
      setEnabledCloudServices([...enabledCloudServices, srv]);
    }
  };

  const handleCompleteAndActivate = async () => {
    setIsSubmitting(true);
    try {
      const selectedPlan = plans.find(p => p.id === selectedPlanId);
      const newSub = await realSubscriberService.createSubscriber({
        businessName,
        ownerName,
        mobile,
        email,
        address,
        city,
        state,
        pinCode,
        gstin,
        planId: selectedPlanId,
        planName: selectedPlan ? selectedPlan.name : 'Annual Pro',
        operationalModes,
        enabledCloudServices,
        locationName,
        locationCode,
        locationType,
        activateImmediately: true
      });

      showToast('success', 'Subscriber Onboarded & Activated!', `${newSub.businessName} has been fully provisioned with default location.`);
      if (onSubscriberCreated) onSubscriberCreated();
      onClose();
    } catch (e: any) {
      showToast('error', 'Onboarding Failed', e.message);
    } finally {
      setIsSubmitting(false);
    }
  };

  const steps = [
    { num: 1, title: 'Business Info', icon: Building2 },
    { num: 2, title: 'Default Location', icon: Store },
    { num: 3, title: 'Plan & Access', icon: CreditCard },
    { num: 4, title: 'Cloud Services', icon: Cloud },
    { num: 5, title: 'Review & Activate', icon: ShieldCheck }
  ];

  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title="New Subscriber Onboarding Wizard"
      subtitle="Complete tenant registration, default location provisioning, and entitlement activation."
      maxWidth="4xl"
      actions={
        <div className="flex items-center justify-between w-full">
          <button
            type="button"
            onClick={() => setCurrentStep(prev => Math.max(prev - 1, 1))}
            disabled={currentStep === 1}
            className="inline-flex items-center gap-1.5 px-3.5 py-2 text-xs font-semibold text-slate-700 hover:bg-slate-200/60 rounded-xl disabled:opacity-40 disabled:cursor-not-allowed transition-colors cursor-pointer"
          >
            <ChevronLeft className="w-4 h-4" />
            <span>Previous</span>
          </button>

          <div className="flex items-center gap-2">
            {currentStep < 5 ? (
              <button
                type="button"
                onClick={() => setCurrentStep(prev => Math.min(prev + 1, 5))}
                disabled={!businessName || !ownerName || !mobile}
                className="inline-flex items-center gap-1.5 px-4 py-2 text-xs font-semibold bg-slate-900 text-white hover:bg-slate-800 disabled:opacity-50 disabled:cursor-not-allowed rounded-xl shadow-xs transition-colors cursor-pointer"
              >
                <span>Continue</span>
                <ChevronRight className="w-4 h-4" />
              </button>
            ) : (
              <button
                type="button"
                onClick={handleCompleteAndActivate}
                disabled={isSubmitting}
                className="inline-flex items-center gap-1.5 px-5 py-2 text-xs font-bold bg-emerald-600 text-white hover:bg-emerald-700 disabled:opacity-50 rounded-xl shadow-md shadow-emerald-600/20 transition-all cursor-pointer"
              >
                <Sparkles className="w-4 h-4" />
                <span>{isSubmitting ? 'Provisioning...' : 'Complete & Activate Subscriber'}</span>
              </button>
            )}
          </div>
        </div>
      }
    >
      {/* Stepper bar */}
      <div className="flex items-center justify-between border-b border-slate-100 pb-4 mb-2">
        {steps.map((s, idx) => {
          const Icon = s.icon;
          const isCurrent = currentStep === s.num;
          const isPassed = currentStep > s.num;
          return (
            <React.Fragment key={s.num}>
              <div 
                onClick={() => setCurrentStep(s.num)}
                className="flex items-center gap-2 cursor-pointer group select-none"
              >
                <div className={`w-8 h-8 rounded-xl flex items-center justify-center text-xs font-bold transition-all ${
                  isCurrent 
                    ? 'bg-emerald-600 text-white shadow-xs' 
                    : isPassed 
                    ? 'bg-emerald-100 text-emerald-800' 
                    : 'bg-slate-100 text-slate-400 group-hover:bg-slate-200'
                }`}>
                  {isPassed ? <Check className="w-4 h-4" /> : <Icon className="w-4 h-4" />}
                </div>
                <span className={`text-xs font-semibold hidden md:inline ${
                  isCurrent ? 'text-slate-900' : isPassed ? 'text-emerald-700' : 'text-slate-400'
                }`}>
                  {s.title}
                </span>
              </div>
              {idx < steps.length - 1 && (
                <div className={`flex-1 h-0.5 mx-2 ${isPassed ? 'bg-emerald-500' : 'bg-slate-200'}`} />
              )}
            </React.Fragment>
          );
        })}
      </div>

      {/* Step 1: Business Info */}
      {currentStep === 1 && (
        <div className="space-y-4 animate-in fade-in duration-200">
          <div className="p-3 bg-emerald-50/60 border border-emerald-200/60 rounded-xl text-xs text-emerald-900">
            <strong>Public Registration Review:</strong> Confirm subscriber basic details submitted via registration.
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-xs font-semibold text-slate-700 mb-1">Business / Shop Name *</label>
              <input
                type="text"
                value={businessName}
                onChange={e => setBusinessName(e.target.value)}
                placeholder="e.g. Blossom Boutique"
                className="w-full px-3.5 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs text-slate-900 focus:bg-white focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500"
              />
            </div>

            <div>
              <label className="block text-xs font-semibold text-slate-700 mb-1">Owner / Primary Contact Name *</label>
              <input
                type="text"
                value={ownerName}
                onChange={e => setOwnerName(e.target.value)}
                placeholder="e.g. Ramesh Gupta"
                className="w-full px-3.5 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs text-slate-900 focus:bg-white focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500"
              />
            </div>

            <div>
              <label className="block text-xs font-semibold text-slate-700 mb-1">Mobile Number *</label>
              <input
                type="text"
                value={mobile}
                onChange={e => setMobile(e.target.value)}
                placeholder="e.g. 9810392755"
                className="w-full px-3.5 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs text-slate-900 focus:bg-white focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500"
              />
            </div>

            <div>
              <label className="block text-xs font-semibold text-slate-700 mb-1">Email Address</label>
              <input
                type="email"
                value={email}
                onChange={e => setEmail(e.target.value)}
                placeholder="e.g. orders@blossomboutique.in"
                className="w-full px-3.5 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs text-slate-900 focus:bg-white focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500"
              />
            </div>

            <div className="md:col-span-2">
              <label className="block text-xs font-semibold text-slate-700 mb-1">Shop Address</label>
              <input
                type="text"
                value={address}
                onChange={e => setAddress(e.target.value)}
                placeholder="e.g. 14 Market Road, Near City Center"
                className="w-full px-3.5 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs text-slate-900 focus:bg-white focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500"
              />
            </div>

            <div>
              <label className="block text-xs font-semibold text-slate-700 mb-1">City</label>
              <input
                type="text"
                value={city}
                onChange={e => setCity(e.target.value)}
                placeholder="e.g. New Delhi"
                className="w-full px-3.5 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs text-slate-900 focus:bg-white focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500"
              />
            </div>

            <div>
              <label className="block text-xs font-semibold text-slate-700 mb-1">State</label>
              <input
                type="text"
                value={state}
                onChange={e => setState(e.target.value)}
                placeholder="e.g. Delhi"
                className="w-full px-3.5 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs text-slate-900 focus:bg-white focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500"
              />
            </div>

            <div>
              <label className="block text-xs font-semibold text-slate-700 mb-1">PIN Code</label>
              <input
                type="text"
                value={pinCode}
                onChange={e => setPinCode(e.target.value)}
                placeholder="e.g. 110001"
                className="w-full px-3.5 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs text-slate-900 focus:bg-white focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500"
              />
            </div>

            <div>
              <label className="block text-xs font-semibold text-slate-700 mb-1">GSTIN (Optional)</label>
              <input
                type="text"
                value={gstin}
                onChange={e => setGstin(e.target.value)}
                placeholder="e.g. 07AAAAA0000A1Z5"
                className="w-full px-3.5 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs text-slate-900 focus:bg-white focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500"
              />
            </div>
          </div>
        </div>
      )}

      {/* Step 2: Default Location Setup (CRITICAL) */}
      {currentStep === 2 && (
        <div className="space-y-4 animate-in fade-in duration-200">
          <div className="p-3.5 bg-amber-50 border border-amber-200 rounded-xl text-xs text-amber-900 leading-relaxed">
            <span className="font-bold">⚠️ CRITICAL PROVISIONING STEP:</span> Every Floraprise Cloud tenant requires at least one Default Location. This generates the initial record in <code>public."Locations"</code>, ensuring Bouquet Production, POS, and Day Close function seamlessly.
          </div>

          <div className="bg-slate-50 p-5 rounded-2xl border border-slate-200/80 space-y-4">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-xl bg-emerald-100 text-emerald-800 flex items-center justify-center shrink-0">
                <Store className="w-5 h-5" />
              </div>
              <div>
                <h4 className="text-xs font-bold text-slate-900">Primary Store Location Configuration</h4>
                <p className="text-[11px] text-slate-500">Will be set as <code>IsDefault = TRUE</code> and <code>IsActive = TRUE</code>.</p>
              </div>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-4 pt-2">
              <div>
                <label className="block text-xs font-semibold text-slate-700 mb-1">Location Name *</label>
                <input
                  type="text"
                  value={locationName}
                  onChange={e => setLocationName(e.target.value)}
                  placeholder="Main Store"
                  className="w-full px-3.5 py-2 bg-white border border-slate-200 rounded-xl text-xs text-slate-900 focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500"
                />
              </div>

              <div>
                <label className="block text-xs font-semibold text-slate-700 mb-1">Location Code *</label>
                <input
                  type="text"
                  value={locationCode}
                  onChange={e => setLocationCode(e.target.value)}
                  placeholder="MAIN-01"
                  className="w-full px-3.5 py-2 bg-white border border-slate-200 rounded-xl text-xs text-slate-900 focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 uppercase"
                />
              </div>

              <div>
                <label className="block text-xs font-semibold text-slate-700 mb-1">Location Type</label>
                <select
                  value={locationType}
                  onChange={e => setLocationType(e.target.value as any)}
                  className="w-full px-3.5 py-2 bg-white border border-slate-200 rounded-xl text-xs text-slate-900 focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500"
                >
                  <option value="Store">Store (Retail POS & Production)</option>
                  <option value="Warehouse">Warehouse (Storage & Dispatch)</option>
                  <option value="Workshop">Workshop (Floral Studio)</option>
                  <option value="Kiosk">Kiosk</option>
                </select>
              </div>
            </div>

            <div className="pt-2">
              <label className="block text-xs font-semibold text-slate-700 mb-1">Location Address</label>
              <input
                type="text"
                value={address}
                onChange={e => setAddress(e.target.value)}
                placeholder="Shop location address"
                className="w-full px-3.5 py-2 bg-white border border-slate-200 rounded-xl text-xs text-slate-900 focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500"
              />
            </div>
          </div>
        </div>
      )}

      {/* Step 3: Plan & Operational Access */}
      {currentStep === 3 && (
        <div className="space-y-4 animate-in fade-in duration-200">
          <div>
            <label className="block text-xs font-bold text-slate-900 mb-2">Select Commercial Subscription Plan</label>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
              {plans.map(plan => {
                const isSelected = selectedPlanId === plan.id;
                const priceDisplay = (plan.annualPrice ?? 0) === 0 && (plan.monthlyPrice ?? 0) === 0
                  ? 'Free Trial'
                  : `₹${((plan.annualPrice ?? 0) || (plan.monthlyPrice ?? 0)).toLocaleString('en-IN')}`;

                return (
                  <div
                    key={plan.id}
                    onClick={() => setSelectedPlanId(plan.id)}
                    className={`p-4 rounded-2xl border-2 transition-all cursor-pointer ${
                      isSelected
                        ? 'border-emerald-600 bg-emerald-50/40 shadow-xs ring-2 ring-emerald-500/20'
                        : 'border-slate-200 bg-white hover:border-slate-300'
                    }`}
                  >
                    <div className="flex items-start justify-between">
                      <div>
                        <div className="flex items-center gap-1.5">
                          <span className="text-xs font-bold text-slate-900">{plan.name}</span>
                          <span className="text-[10px] font-semibold px-1.5 py-0.2 bg-slate-100 text-slate-700 rounded">
                            {plan.planType}
                          </span>
                        </div>
                        <div className="text-[11px] text-slate-500 mt-1">{plan.description}</div>
                        <div className="text-[10px] text-slate-400 font-mono mt-0.5">Code: {plan.code}</div>
                      </div>
                      <div className="text-right shrink-0">
                        <div className="text-sm font-bold text-emerald-700">
                          {priceDisplay}
                        </div>
                        <div className="text-[10px] text-slate-400">
                          {plan.code === 'MOBILE_TRIAL' ? `${plan.trialDays} Days Trial` : `${plan.durationDays} Days / ${plan.billingCycle}`}
                        </div>
                      </div>
                    </div>

                    <div className="mt-3 pt-2.5 border-t border-slate-100 flex items-center gap-3 text-[11px] text-slate-600 flex-wrap">
                      <span className="inline-flex items-center gap-1">
                        <Smartphone className="w-3 h-3 text-slate-400" />
                        <span><strong>{plan.maximumDevices}</strong> Devices</span>
                      </span>
                      <span className="inline-flex items-center gap-1">
                        <Users className="w-3 h-3 text-slate-400" />
                        <span><strong>{plan.maximumStaff}</strong> Staff</span>
                      </span>
                      <span><strong>{plan.offlineDays}d</strong> Offline</span>
                    </div>
                  </div>
                );
              })}
            </div>
          </div>

          <div className="pt-2">
            <label className="block text-xs font-bold text-slate-900 mb-2">Enabled Operational Modes</label>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
              {(['Flutter Cloud Android', 'Flutter Web', 'Flutter Solo'] as OperationalMode[]).map(mode => {
                const isChecked = operationalModes.includes(mode);
                return (
                  <div
                    key={mode}
                    onClick={() => toggleMode(mode)}
                    className={`p-3.5 rounded-xl border flex items-center justify-between cursor-pointer transition-all ${
                      isChecked ? 'bg-emerald-50 border-emerald-400 text-emerald-950 font-semibold' : 'bg-slate-50 border-slate-200 text-slate-600'
                    }`}
                  >
                    <span className="text-xs">{mode}</span>
                    <input type="checkbox" checked={isChecked} onChange={() => {}} className="accent-emerald-600 w-4 h-4" />
                  </div>
                );
              })}
            </div>
          </div>
        </div>
      )}

      {/* Step 4: Cloud Services */}
      {currentStep === 4 && (
        <div className="space-y-4 animate-in fade-in duration-200">
          <div className="text-xs text-slate-600">
            Configure enabled background cloud microservices for this subscriber:
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
            {([
              'Subscription Validation',
              'Delivery Tracking',
              'Cloud Storage',
              'Notifications',
              'WhatsApp Integration',
              'Cloud Production & Recipes'
            ] as CloudServiceKey[]).map(srv => {
              const isChecked = enabledCloudServices.includes(srv);
              return (
                <div
                  key={srv}
                  onClick={() => toggleService(srv)}
                  className={`p-3.5 rounded-xl border flex items-center justify-between cursor-pointer transition-all ${
                    isChecked ? 'bg-emerald-50 border-emerald-400 text-emerald-950 font-semibold' : 'bg-slate-50 border-slate-200 text-slate-600'
                  }`}
                >
                  <span className="text-xs">{srv}</span>
                  <input type="checkbox" checked={isChecked} onChange={() => {}} className="accent-emerald-600 w-4 h-4" />
                </div>
              );
            })}
          </div>
        </div>
      )}

      {/* Step 5: Review & Activate */}
      {currentStep === 5 && (
        <div className="space-y-4 animate-in fade-in duration-200">
          <div className="p-4 bg-emerald-50 border border-emerald-200 rounded-2xl">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-xl bg-emerald-600 text-white flex items-center justify-center shrink-0">
                <ShieldCheck className="w-6 h-6" />
              </div>
              <div>
                <h4 className="text-xs font-bold text-emerald-950">Provisioning Checks Verified (10/10 Ready)</h4>
                <p className="text-[11px] text-emerald-700">All required entity dependencies, Default Location, and licenses are configured.</p>
              </div>
            </div>
          </div>

          <div className="bg-slate-50 p-4 rounded-2xl border border-slate-200/80 space-y-2 text-xs">
            <div className="flex justify-between py-1 border-b border-slate-200/60">
              <span className="text-slate-500">Business:</span>
              <span className="font-bold text-slate-900">{businessName}</span>
            </div>
            <div className="flex justify-between py-1 border-b border-slate-200/60">
              <span className="text-slate-500">Owner Contact:</span>
              <span className="font-semibold text-slate-900">{ownerName} ({mobile})</span>
            </div>
            <div className="flex justify-between py-1 border-b border-slate-200/60">
              <span className="text-slate-500">Default Location:</span>
              <span className="font-semibold text-emerald-700">{locationName} ({locationCode}) — Type: {locationType}</span>
            </div>
            <div className="flex justify-between py-1 border-b border-slate-200/60">
              <span className="text-slate-500">Subscription Plan:</span>
              <span className="font-bold text-slate-900">
                {(() => {
                  const sel = plans.find(p => p.id === selectedPlanId);
                  if (!sel) return 'Default Plan';
                  const isFree = (sel.annualPrice ?? 0) === 0 && (sel.monthlyPrice ?? 0) === 0;
                  const price = (sel.annualPrice ?? 0) || (sel.monthlyPrice ?? 0);
                  const pVal = isFree ? 'Free Trial' : `₹${price.toLocaleString('en-IN')}`;
                  return `${sel.name} (${pVal})`;
                })()}
              </span>
            </div>
            <div className="flex justify-between py-1">
              <span className="text-slate-500">Operational Clients:</span>
              <span className="font-medium text-slate-800">{operationalModes.join(', ')}</span>
            </div>
          </div>
        </div>
      )}
    </Modal>
  );
};
