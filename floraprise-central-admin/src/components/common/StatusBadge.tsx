import React from 'react';

interface StatusBadgeProps {
  status: string;
  size?: 'sm' | 'md' | 'lg';
  dot?: boolean;
}

export const StatusBadge: React.FC<StatusBadgeProps> = ({ 
  status, 
  size = 'md', 
  dot = true 
}) => {
  const norm = status.toLowerCase();

  let bgClass = 'bg-slate-100 text-slate-700 border-slate-200';
  let dotClass = 'bg-slate-400';

  if (norm === 'active' || norm === 'ready' || norm === 'healthy' || norm === 'online' || norm === 'stable' || norm === 'completed' || norm === 'delivered' || norm === 'operational') {
    bgClass = 'bg-emerald-50 text-emerald-700 border-emerald-200/80';
    dotClass = 'bg-emerald-500';
  } else if (norm === 'trial') {
    bgClass = 'bg-sky-50 text-sky-700 border-sky-200/80';
    dotClass = 'bg-sky-500';
  } else if (norm === 'needs attention' || norm === 'grace' || norm === 'pending' || norm === 'pending onboarding' || norm === 'in transit' || norm === 'in progress' || norm === 'investigating' || norm === 'degraded') {
    bgClass = 'bg-amber-50 text-amber-700 border-amber-200/80';
    dotClass = 'bg-amber-500';
  } else if (norm === 'not ready' || norm === 'critical' || norm === 'expired' || norm === 'suspended' || norm === 'failed' || norm === 'deactivated' || norm === 'offline') {
    bgClass = 'bg-rose-50 text-rose-700 border-rose-200/80';
    dotClass = 'bg-rose-500';
  } else if (norm === 'not connected' || norm === 'unverified' || norm === 'not yet connected') {
    bgClass = 'bg-slate-100 text-slate-600 border-slate-300';
    dotClass = 'bg-slate-400';
  }

  const sizeClasses = {
    sm: 'text-[11px] px-2 py-0.5 font-medium',
    md: 'text-xs px-2.5 py-1 font-semibold',
    lg: 'text-sm px-3 py-1.5 font-semibold'
  };

  return (
    <span className={`inline-flex items-center gap-1.5 rounded-full border ${sizeClasses[size]} ${bgClass} transition-colors`}>
      {dot && (
        <span className={`w-1.5 h-1.5 rounded-full shrink-0 ${dotClass} ${norm === 'active' || norm === 'in transit' ? 'animate-pulse' : ''}`} />
      )}
      {status}
    </span>
  );
};
