/**
 * SkeletonLoader.tsx — Lightweight skeleton placeholders for dashboard loading state.
 */

function Pulse({ className = '' }: { className?: string }) {
  return (
    <div className={`animate-pulse bg-slate-200 rounded-xl ${className}`} />
  );
}

export function CardSkeleton() {
  return (
    <div className="bg-white rounded-xl shadow-sm border border-slate-100 p-5 space-y-3">
      <div className="flex items-center gap-3">
        <Pulse className="w-10 h-10 rounded-xl shrink-0" />
        <Pulse className="h-3 w-20" />
      </div>
      <Pulse className="h-7 w-24" />
    </div>
  );
}

export function TaskSkeleton() {
  return (
    <div className="bg-white rounded-xl border border-slate-100 p-4 flex items-center gap-3">
      <Pulse className="w-5 h-5 rounded-full shrink-0" />
      <div className="flex-1 space-y-2">
        <Pulse className="h-4 w-48" />
        <Pulse className="h-3 w-32" />
      </div>
      <Pulse className="h-6 w-16 rounded-full" />
    </div>
  );
}

export function ChartSkeleton() {
  return (
    <div className="bg-white rounded-xl shadow-sm border border-slate-100 p-5">
      <Pulse className="h-4 w-32 mb-4" />
      <Pulse className="h-40 w-full" />
    </div>
  );
}

interface DashboardSkeletonProps {
  cards?: number;
  tasks?: number;
  showChart?: boolean;
}

export default function DashboardSkeleton({
  cards = 6,
  tasks = 4,
  showChart = false,
}: DashboardSkeletonProps) {
  return (
    <div>
      {/* Heading skeleton */}
      <div className="space-y-2 mb-8">
        <Pulse className="h-7 w-48" />
        <Pulse className="h-4 w-64" />
      </div>

      {/* Cards grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-6 mb-8">
        {Array.from({ length: cards }).map((_, i) => (
          <CardSkeleton key={i} />
        ))}
      </div>

      {showChart && <div className="mb-8"><ChartSkeleton /></div>}

      {/* Tasks */}
      {tasks > 0 && (
        <div>
          <Pulse className="h-5 w-40 mb-4" />
          <div className="space-y-2">
            {Array.from({ length: tasks }).map((_, i) => (
              <TaskSkeleton key={i} />
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
