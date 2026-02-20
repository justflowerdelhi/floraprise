/**
 * ErrorState.tsx — Friendly error & 403 display.
 */

interface ErrorStateProps {
  status?: number;
  message?: string;
  onRetry?: () => void;
}

export default function ErrorState({
  status,
  message,
  onRetry,
}: ErrorStateProps) {
  const is403 = status === 403;

  return (
    <div className="flex flex-col items-center justify-center py-20 text-center">
      <div className="w-16 h-16 rounded-full bg-rose-50 flex items-center justify-center mb-4">
        <svg className="w-8 h-8 text-rose-500" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
          {is403 ? (
            <path strokeLinecap="round" strokeLinejoin="round" d="M18.364 18.364A9 9 0 005.636 5.636m12.728 12.728L5.636 5.636" />
          ) : (
            <path strokeLinecap="round" strokeLinejoin="round" d="M12 9v3.75m9-.75a9 9 0 11-18 0 9 9 0 0118 0zm-9 3.75h.008v.008H12v-.008z" />
          )}
        </svg>
      </div>
      <h3 className="text-lg font-semibold text-slate-800 mb-1">
        {is403 ? 'Access Denied' : 'Something went wrong'}
      </h3>
      <p className="text-sm text-slate-500 max-w-xs mb-4">
        {is403
          ? "You don't have permission to view this dashboard. Contact your administrator."
          : message || 'Failed to load dashboard data. Please try again.'}
      </p>
      {onRetry && !is403 && (
        <button
          onClick={onRetry}
          className="px-4 py-2 rounded-lg bg-slate-800 text-white text-sm font-medium hover:bg-slate-700 transition-colors"
        >
          Retry
        </button>
      )}
    </div>
  );
}
