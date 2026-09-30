import React, { useState } from 'react';
import { PlatformSettings } from '../../types/platform';
import { useNotification } from '../../context/NotificationContext';
import { Settings, Shield, Bell, Save, Check } from 'lucide-react';

export const SettingsPage: React.FC = () => {
  const { showToast } = useNotification();
  const [settings, setSettings] = useState<PlatformSettings>({
    platformName: 'Floraprise Central Admin',
    environment: 'Production',
    supportContactEmail: 'support@floraprise.com',
    supportPhone: '+91 9810392755',
    annualPlanPriceInr: 14999,
    trialDurationDays: 14,
    gracePeriodDays: 7,
    maintenanceMode: false,
    allowPublicSelfRegistration: true,
    requireDefaultLocationCheck: true,
    automaticSoloMigrationVerify: true,
    webhookUrl: 'https://api.floraprise.com/webhooks/platform-events'
  });

  const [isSaved, setIsSaved] = useState(false);

  const handleSave = (e: React.FormEvent) => {
    e.preventDefault();
    setIsSaved(true);
    showToast('success', 'Settings Saved', 'Global Central Admin configuration updated.');
    setTimeout(() => setIsSaved(false), 2000);
  };

  return (
    <div className="space-y-6 max-w-4xl">
      <div>
        <h2 className="text-xl font-black text-slate-900 flex items-center gap-2">
          <Settings className="w-5 h-5 text-emerald-600" />
          <span>Platform Settings & Guardrails</span>
        </h2>
        <p className="text-xs text-slate-500 mt-0.5">
          Global operational defaults, provisioning safety guardrails, and billing thresholds.
        </p>
      </div>

      <form onSubmit={handleSave} className="space-y-6">
        {/* Provisioning Safety Guardrails */}
        <div className="bg-white p-6 rounded-3xl border border-slate-200 shadow-xs space-y-4">
          <h3 className="text-sm font-bold text-slate-900 flex items-center gap-2">
            <Shield className="w-4 h-4 text-emerald-600" />
            <span>Multi-Tenant Provisioning Guardrails</span>
          </h3>

          <div className="space-y-3 text-xs">
            <label className="flex items-start gap-3 p-3 rounded-2xl bg-emerald-50/50 border border-emerald-200 cursor-pointer">
              <input
                type="checkbox"
                checked={settings.requireDefaultLocationCheck}
                onChange={e => setSettings({ ...settings, requireDefaultLocationCheck: e.target.checked })}
                className="mt-0.5 rounded accent-emerald-600 w-4 h-4"
              />
              <div>
                <span className="font-bold text-emerald-950 block">Enforce Mandatory Default Store Location (Main Store / MAIN-01)</span>
                <span className="text-emerald-800 text-[11px]">
                  Blocks subscriber activation if zero location records exist in PostgreSQL, completely preventing the "No active Cloud location is available" production bug.
                </span>
              </div>
            </label>

            <label className="flex items-start gap-3 p-3 rounded-2xl bg-slate-50 border border-slate-200 cursor-pointer">
              <input
                type="checkbox"
                checked={settings.allowPublicSelfRegistration}
                onChange={e => setSettings({ ...settings, allowPublicSelfRegistration: e.target.checked })}
                className="mt-0.5 rounded accent-emerald-600 w-4 h-4"
              />
              <div>
                <span className="font-bold text-slate-900 block">Allow Self-Registration with Pending Admin Review</span>
                <span className="text-slate-500 text-[11px]">
                  Newly registered accounts are placed in the "Pending Onboarding" queue rather than immediately active.
                </span>
              </div>
            </label>
          </div>
        </div>

        {/* Pricing & Grace Period Defaults */}
        <div className="bg-white p-6 rounded-3xl border border-slate-200 shadow-xs space-y-4">
          <h3 className="text-sm font-bold text-slate-900">Commercial & Billing Defaults</h3>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-4 text-xs">
            <div>
              <label className="block font-semibold text-slate-700 mb-1">Standard Annual Pro Price (₹)</label>
              <input
                type="number"
                value={settings.annualPlanPriceInr}
                onChange={e => setSettings({ ...settings, annualPlanPriceInr: Number(e.target.value) })}
                className="w-full px-3.5 py-2 bg-slate-50 border border-slate-200 rounded-xl font-bold text-slate-900"
              />
            </div>

            <div>
              <label className="block font-semibold text-slate-700 mb-1">Trial Evaluation Period (Days)</label>
              <input
                type="number"
                value={settings.trialDurationDays}
                onChange={e => setSettings({ ...settings, trialDurationDays: Number(e.target.value) })}
                className="w-full px-3.5 py-2 bg-slate-50 border border-slate-200 rounded-xl text-slate-900"
              />
            </div>

            <div>
              <label className="block font-semibold text-slate-700 mb-1">Grace Period Before Lockout (Days)</label>
              <input
                type="number"
                value={settings.gracePeriodDays}
                onChange={e => setSettings({ ...settings, gracePeriodDays: Number(e.target.value) })}
                className="w-full px-3.5 py-2 bg-slate-50 border border-slate-200 rounded-xl text-slate-900"
              />
            </div>
          </div>
        </div>

        {/* Save button */}
        <div className="flex justify-end">
          <button
            type="submit"
            className="inline-flex items-center gap-2 px-6 py-2.5 bg-emerald-600 hover:bg-emerald-700 text-white text-xs font-bold rounded-xl shadow-xs shadow-emerald-600/20 transition-all cursor-pointer"
          >
            {isSaved ? <Check className="w-4 h-4" /> : <Save className="w-4 h-4" />}
            <span>{isSaved ? 'Settings Saved' : 'Save Platform Guardrails'}</span>
          </button>
        </div>
      </form>
    </div>
  );
};
