/**
 * QuickActionButton.tsx — Prominent action button for dashboards.
 */
import { useNavigate } from 'react-router-dom';

interface QuickActionButtonProps {
  label: string;
  icon: React.ReactNode;
  href: string;
  variant?: 'primary' | 'secondary';
}

export default function QuickActionButton({
  label,
  icon,
  href,
  variant = 'secondary',
}: QuickActionButtonProps) {
  const navigate = useNavigate();

  const base =
    'inline-flex items-center gap-2 px-4 py-2.5 rounded-xl font-semibold text-sm transition-all duration-200 active:scale-[0.97]';
  const styles =
    variant === 'primary'
      ? 'bg-emerald-600 text-white hover:bg-emerald-700 shadow-sm'
      : 'bg-white text-slate-700 border border-slate-200 hover:bg-slate-50 hover:border-slate-300';

  return (
    <button onClick={() => navigate(href)} className={`${base} ${styles}`}>
      {icon}
      {label}
    </button>
  );
}
