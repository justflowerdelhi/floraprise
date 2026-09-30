import React from 'react';
import { ProvisioningCheckResult } from '../../types/subscriber';
import { StatusBadge } from '../common/StatusBadge';
import { CheckCircle2, AlertTriangle, XCircle, Wrench } from 'lucide-react';

interface ProvisioningCheckCardProps {
  check: ProvisioningCheckResult;
  onRemediate?: () => void;
  isRemediating?: boolean;
}

export const ProvisioningCheckCard: React.FC<ProvisioningCheckCardProps> = ({
  check,
  onRemediate,
  isRemediating
}) => {
  const isReady = check.status === 'READY';
  const isNeedsAttention = check.status === 'NEEDS ATTENTION';
  const isNotReady = check.status === 'NOT READY';

  return (
    <div className={`p-4 rounded-xl border transition-all ${
      isReady 
        ? 'bg-emerald-50/30 border-emerald-200/60' 
        : isNeedsAttention 
        ? 'bg-amber-50/40 border-amber-200' 
        : 'bg-rose-50/40 border-rose-200'
    }`}>
      <div className="flex items-start justify-between gap-3">
        <div className="flex items-start gap-3">
          <div className="mt-0.5 shrink-0">
            {isReady && <CheckCircle2 className="w-5 h-5 text-emerald-600" />}
            {isNeedsAttention && <AlertTriangle className="w-5 h-5 text-amber-600" />}
            {isNotReady && <XCircle className="w-5 h-5 text-rose-600" />}
          </div>
          <div>
            <div className="text-xs font-bold text-slate-900">{check.title}</div>
            
            {check.problem && (
              <div className="text-xs font-semibold text-rose-700 mt-1">
                {check.problem}
              </div>
            )}
            
            {check.explanation && (
              <p className="text-[11px] text-slate-600 mt-0.5 leading-relaxed">
                {check.explanation}
              </p>
            )}
          </div>
        </div>

        <div className="shrink-0 flex items-center gap-2">
          <StatusBadge status={check.status} size="sm" />
          
          {check.remediationAvailable && onRemediate && !isReady && (
            <button
              onClick={onRemediate}
              disabled={isRemediating}
              className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-lg text-xs font-semibold bg-emerald-600 text-white hover:bg-emerald-700 disabled:opacity-50 shadow-xs transition-colors cursor-pointer"
            >
              <Wrench className="w-3.5 h-3.5" />
              <span>{isRemediating ? 'Fixing...' : check.suggestedAction || 'Auto-Fix'}</span>
            </button>
          )}
        </div>
      </div>
    </div>
  );
};
