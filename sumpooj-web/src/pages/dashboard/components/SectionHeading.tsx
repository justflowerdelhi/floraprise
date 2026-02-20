/**
 * SectionHeading.tsx — Consistent section title with optional count badge.
 */

interface SectionHeadingProps {
  title: string;
  count?: number;
  className?: string;
}

export default function SectionHeading({ title, count, className = '' }: SectionHeadingProps) {
  return (
    <div className={`flex items-center gap-2 ${className}`}>
      <h3 className="text-sm font-semibold text-slate-800 uppercase tracking-wide">{title}</h3>
      {count !== undefined && (
        <span className="text-[11px] font-bold bg-slate-100 text-slate-600 px-2 py-0.5 rounded-full">
          {count}
        </span>
      )}
    </div>
  );
}
