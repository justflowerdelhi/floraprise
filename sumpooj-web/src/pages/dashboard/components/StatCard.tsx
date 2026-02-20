/**
 * StatCard.tsx — Reusable metric card with consistent layout.
 *
 * Structure: icon container (w-10 h-10) + label + bold value + optional subtitle.
 * Uses shadow-sm, rounded-xl, p-5. Equal height via flex-col.
 */
import { useNavigate } from 'react-router-dom';

interface StatCardProps {
  label: string;
  value: string | number;
  icon: React.ReactNode;
  href?: string;
  iconBg?: string;       // bg color for icon container e.g. "bg-emerald-50"
  iconColor?: string;     // text color for icon e.g. "text-emerald-600"
  subtitle?: string;
}

export default function StatCard({
  label,
  value,
  icon,
  href,
  iconBg = 'bg-slate-50',
  iconColor = 'text-slate-600',
  subtitle,
}: StatCardProps) {
  const navigate = useNavigate();

  return (
    <div
      onClick={href ? () => navigate(href) : undefined}
      className={`
        bg-white rounded-xl shadow-sm border border-slate-100
        p-5 flex flex-col justify-between h-full
        transition-all duration-200
        ${href ? 'cursor-pointer hover:shadow-md hover:-translate-y-0.5 active:scale-[0.98]' : ''}
      `}
    >
      {/* Top row: icon + label */}
      <div className="flex items-center gap-3 mb-3">
        <div className={`w-10 h-10 rounded-xl ${iconBg} ${iconColor} flex items-center justify-center shrink-0`}>
          {icon}
        </div>
        <p className="text-xs font-medium text-slate-500 uppercase tracking-wide leading-tight">
          {label}
        </p>
      </div>

      {/* Metric */}
      <p className="text-2xl font-bold text-slate-800 leading-tight">
        {typeof value === 'number' ? value.toLocaleString('en-IN') : value}
      </p>

      {/* Subtitle */}
      {subtitle && (
        <p className="text-xs text-slate-400 mt-1">{subtitle}</p>
      )}
    </div>
  );
}
