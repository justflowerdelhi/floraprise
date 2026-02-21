/**
 * SkeletonLoader.tsx — Premium skeleton placeholders for dashboard loading state.
 */

function Pulse({ className = '' }: { className?: string }) {
  return (
    <div className={`animate-pulse bg-gray-200 rounded ${className}`} />
  );
}

export function CardSkeleton() {
  return (
    <div className="bg-white rounded-xl shadow-sm p-5 animate-pulse">
      <div className="h-4 w-24 bg-gray-200 rounded mb-4"></div>
      <div className="h-8 w-16 bg-gray-300 rounded"></div>
    </div>
  );
}

export function TaskSkeleton() {
  return (
    <div className="bg-white rounded-xl shadow-sm p-4 flex items-center gap-3 animate-pulse">
      <div className="w-5 h-5 bg-gray-200 rounded-full shrink-0"></div>
      <div className="flex-1 space-y-2">
        <div className="h-4 w-48 bg-gray-200 rounded"></div>
        <div className="h-3 w-32 bg-gray-200 rounded"></div>
      </div>
      <div className="h-6 w-16 bg-gray-200 rounded-full"></div>
    </div>
  );
}

export function ChartSkeleton() {
  return (
    <div className="bg-white rounded-xl shadow-sm p-5 animate-pulse">
      <div className="h-4 w-32 bg-gray-200 rounded mb-4"></div>
      <div className="h-40 w-full bg-gray-200 rounded"></div>
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
      <div className="space-y-2 mb-10 animate-pulse">
        <div className="flex items-center gap-3">
          <div className="h-7 w-48 bg-gray-200 rounded"></div>
          <div className="h-6 w-16 bg-gray-200 rounded-full"></div>
        </div>
        <div className="h-4 w-64 bg-gray-200 rounded"></div>
      </div>

      {/* Cards grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-6 mb-10">
        {Array.from({ length: cards }).map((_, i) => (
          <CardSkeleton key={i} />
        ))}      </div>

      {/* Subtle divider */}
      <div className="border-t border-gray-100 my-8" />

      {showChart && <div className="mb-10"><ChartSkeleton /></div>}

      {/* Tasks */}
      {tasks > 0 && (
        <div>
          <div className="h-5 w-40 bg-gray-200 rounded mb-4 animate-pulse"></div>
          <div className="space-y-3">
            {Array.from({ length: tasks }).map((_, i) => (
              <TaskSkeleton key={i} />
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
