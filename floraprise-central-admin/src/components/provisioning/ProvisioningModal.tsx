import React, { useState } from 'react';
import { Subscriber } from '../../types/subscriber';
import { Modal } from '../common/Modal';
import { ProvisioningCheckCard } from './ProvisioningCheckCard';
import { StatusBadge } from '../common/StatusBadge';
import { realSubscriberService } from '../../services/api/realSubscriberService';
import { useNotification } from '../../context/NotificationContext';
import { ShieldCheck, Wrench, CheckCircle } from 'lucide-react';

interface ProvisioningModalProps {
  isOpen: boolean;
  onClose: () => void;
  subscriber: Subscriber;
  onUpdated?: () => void;
}

export const ProvisioningModal: React.FC<ProvisioningModalProps> = ({
  isOpen,
  onClose,
  subscriber,
  onUpdated
}) => {
  const { showToast } = useNotification();
  const [currentSubscriber, setCurrentSubscriber] = useState<Subscriber>(subscriber);
  const [isProcessing, setIsProcessing] = useState(false);

  // Sync state when subscriber prop changes
  React.useEffect(() => {
    setCurrentSubscriber(subscriber);
  }, [subscriber]);

  const passedCount = currentSubscriber.provisioningChecks.filter(c => c.passed).length;
  const totalCount = currentSubscriber.provisioningChecks.length;
  const allPassed = passedCount === totalCount;

  const handleFixLocation = async () => {
    setIsProcessing(true);
    try {
      const updated = await realSubscriberService.autoRemediateLocation(currentSubscriber.id);
      if (updated) {
        setCurrentSubscriber(updated);
        showToast('success', 'Location Provisioned', 'Created "Main Store" (MAIN-01) default location.');
        if (onUpdated) onUpdated();
      }
    } finally {
      setIsProcessing(false);
    }
  };

  const handleFixAll = async () => {
    setIsProcessing(true);
    try {
      const updated = await realSubscriberService.autoRemediateAll(currentSubscriber.id);
      if (updated) {
        setCurrentSubscriber(updated);
        showToast('success', 'Full Remediation Complete', 'All 10 provisioning checks are now green.');
        if (onUpdated) onUpdated();
      }
    } finally {
      setIsProcessing(false);
    }
  };

  const handleActivate = async () => {
    setIsProcessing(true);
    try {
      const res = await realSubscriberService.activateSubscriber(currentSubscriber.id);
      if (res.success && res.subscriber) {
        setCurrentSubscriber(res.subscriber);
        showToast('success', 'Subscriber Activated', `${currentSubscriber.businessName} is now active.`);
        if (onUpdated) onUpdated();
        onClose();
      } else {
        showToast('error', 'Activation Failed', res.message);
      }
    } finally {
      setIsProcessing(false);
    }
  };

  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title="Subscriber Provisioning Verification"
      subtitle={`${currentSubscriber.businessName} (${currentSubscriber.id})`}
      maxWidth="2xl"
      actions={
        <div className="flex items-center justify-between w-full">
          <div className="flex items-center gap-2 text-xs">
            <span className="font-semibold text-slate-700">Readiness Score:</span>
            <span className={`font-bold ${allPassed ? 'text-emerald-600' : 'text-amber-600'}`}>
              {passedCount} / {totalCount} Passed
            </span>
          </div>

          <div className="flex items-center gap-2">
            {!allPassed && (
              <button
                onClick={handleFixAll}
                disabled={isProcessing}
                className="inline-flex items-center gap-1.5 px-3 py-2 text-xs font-semibold text-slate-700 hover:bg-slate-200/60 rounded-xl transition-colors cursor-pointer border border-slate-300"
              >
                <Wrench className="w-3.5 h-3.5 text-slate-600" />
                <span>Auto-Fix All Deficiencies</span>
              </button>
            )}

            <button
              onClick={handleActivate}
              disabled={!allPassed || isProcessing || currentSubscriber.status === 'Active'}
              className="inline-flex items-center gap-1.5 px-4 py-2 text-xs font-semibold bg-emerald-600 text-white hover:bg-emerald-700 disabled:bg-slate-300 disabled:cursor-not-allowed rounded-xl shadow-xs transition-colors cursor-pointer"
            >
              <CheckCircle className="w-4 h-4" />
              <span>{currentSubscriber.status === 'Active' ? 'Already Active' : 'Activate Subscriber'}</span>
            </button>
          </div>
        </div>
      }
    >
      {/* Overview Card */}
      <div className="p-4 rounded-xl bg-slate-900 text-white flex items-center justify-between gap-4">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-xl bg-emerald-500/20 text-emerald-400 border border-emerald-500/30 flex items-center justify-center shrink-0">
            <ShieldCheck className="w-5 h-5" />
          </div>
          <div>
            <div className="text-xs text-slate-400 font-medium">Tenant Operational Status</div>
            <div className="text-sm font-bold text-white flex items-center gap-2 mt-0.5">
              <span>{currentSubscriber.businessName}</span>
              <StatusBadge status={currentSubscriber.status} size="sm" />
            </div>
          </div>
        </div>

        <div className="text-right">
          <div className="text-[11px] text-slate-400">Plan: {currentSubscriber.planName}</div>
          <div className="text-xs font-semibold text-emerald-400 mt-0.5">
            {allPassed ? '✓ 100% Verified for Activation' : '⚠️ Action Required'}
          </div>
        </div>
      </div>

      {/* Warning Alert if location missing */}
      {currentSubscriber.locations.length === 0 && (
        <div className="p-3.5 rounded-xl bg-rose-50 border border-rose-200 text-rose-900 text-xs flex items-start gap-3">
          <div className="shrink-0 mt-0.5">⚠️</div>
          <div>
            <span className="font-bold">CRITICAL PROVISIONING DEFICIENCY:</span> This subscriber has NO location record in the database. Without a Default Location ("Main Store"), Bouquet Production, POS, and Day Close will fail with <code>"No active Cloud location is available"</code>.
          </div>
        </div>
      )}

      {/* Check list */}
      <div className="space-y-2.5 pt-1">
        {currentSubscriber.provisioningChecks.map(check => (
          <ProvisioningCheckCard
            key={check.key}
            check={check}
            isRemediating={isProcessing}
            onRemediate={() => {
              if (check.key === 'location') {
                handleFixLocation();
              } else {
                handleFixAll();
              }
            }}
          />
        ))}
      </div>
    </Modal>
  );
};
