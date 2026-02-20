/**
 * TaskItem.tsx — Single toggleable task row for Designer dashboard.
 */
import type { ProductionTask } from '../api/dashboardApi';

const PRIORITY_DOT: Record<string, string> = {
  high: 'bg-rose-500',
  medium: 'bg-amber-400',
  low: 'bg-slate-300',
};

const STATUS_BADGE: Record<string, { bg: string; text: string; label: string }> = {
  pending: { bg: 'bg-amber-50', text: 'text-amber-700', label: 'Pending' },
  in_progress: { bg: 'bg-blue-50', text: 'text-blue-700', label: 'In Progress' },
  completed: { bg: 'bg-emerald-50', text: 'text-emerald-700', label: 'Done' },
};

interface TaskItemProps {
  task: ProductionTask;
  onToggle: (id: string) => void;
}

export default function TaskItem({ task, onToggle }: TaskItemProps) {
  const badge = STATUS_BADGE[task.status];
  const done = task.status === 'completed';

  return (
    <div
      className={`
        flex items-center gap-3 bg-white rounded-xl border border-slate-100
        px-4 py-3 transition-all duration-200 hover:shadow-sm
        ${done ? 'opacity-60' : ''}
      `}
    >
      {/* Priority dot */}
      <span className={`w-2.5 h-2.5 rounded-full shrink-0 ${PRIORITY_DOT[task.priority]}`} />

      {/* Checkbox */}
      <button
        onClick={() => onToggle(task.id)}
        className={`
          w-5 h-5 rounded-md border-2 shrink-0 flex items-center justify-center transition-colors
          ${done
            ? 'bg-emerald-500 border-emerald-500 text-white'
            : 'border-slate-300 hover:border-emerald-400'
          }
        `}
      >
        {done && (
          <svg className="w-3 h-3" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={3}>
            <path strokeLinecap="round" strokeLinejoin="round" d="M5 13l4 4L19 7" />
          </svg>
        )}
      </button>

      {/* Content */}
      <div className="flex-1 min-w-0">
        <p className={`text-sm font-medium ${done ? 'line-through text-slate-400' : 'text-slate-800'}`}>
          {task.title}
        </p>
        {task.notes && (
          <p className="text-xs text-slate-400 truncate mt-0.5">{task.notes}</p>
        )}
      </div>

      {/* Time slot */}
      {task.dueTime && (
        <span className="text-xs text-slate-500 font-medium shrink-0">{task.dueTime}</span>
      )}

      {/* Status badge */}
      <span className={`text-[11px] font-semibold px-2 py-0.5 rounded-full shrink-0 ${badge.bg} ${badge.text}`}>
        {badge.label}
      </span>
    </div>
  );
}
