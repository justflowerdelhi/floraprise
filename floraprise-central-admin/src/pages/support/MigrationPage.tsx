import React, { useState, useEffect } from 'react';
import { realDiagnosticsService } from '../../services/api/realDiagnosticsService';
import { MigrationJob } from '../../types/diagnostics';
import { StatusBadge } from '../../components/common/StatusBadge';
import { useNotification } from '../../context/NotificationContext';
import { ArrowRightLeft, CheckCircle2, Play, Database, Sparkles, RefreshCw } from 'lucide-react';

export const MigrationPage: React.FC = () => {
  const { showToast } = useNotification();
  const [jobs, setJobs] = useState<MigrationJob[]>([]);
  const [isStarting, setIsStarting] = useState(false);

  const loadData = () => {
    realDiagnosticsService.getMigrationJobs().then(setJobs);
  };

  useEffect(() => {
    loadData();
  }, []);

  const handleStartMigration = async (jobId: string, companyId: string) => {
    setIsStarting(true);
    const res = await realDiagnosticsService.startMigration(companyId);
    setIsStarting(false);
    if (res.success) {
      showToast('success', 'Migration Pipeline Initiated', res.message);
      loadData();
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h2 className="text-xl font-black text-slate-900 flex items-center gap-2">
            <ArrowRightLeft className="w-5 h-5 text-emerald-600" />
            <span>Solo (SQLite) → Cloud Migration Hub</span>
          </h2>
          <p className="text-xs text-slate-500 mt-0.5">
            Migrate standalone offline SQLite florists into multi-device Cloud Android & Web subscriptions safely without data loss.
          </p>
        </div>
      </div>

      <div className="p-4 bg-emerald-50 border border-emerald-200 rounded-2xl text-xs text-emerald-900 space-y-1">
        <div className="font-bold flex items-center gap-1.5">
          <Sparkles className="w-4 h-4 text-emerald-600" />
          <span>Automated Migration Integrity Guarantee:</span>
        </div>
        <p className="text-[11px] text-emerald-800 leading-relaxed">
          The migration pipeline parses encrypted offline SQLite backups, maps customers, order history, inventory ledgers, and floral design recipes, and creates Cloud tenant entities with a guaranteed Default Store location.
        </p>
      </div>

      <div className="space-y-4">
        {jobs.length > 0 ? (
          jobs.map(job => (
            <div
              key={job.id}
              className="bg-white p-6 rounded-3xl border border-slate-200/80 shadow-xs space-y-4"
            >
              <div className="flex flex-col md:flex-row md:items-center justify-between gap-3">
                <div>
                  <div className="flex items-center gap-2.5">
                    <h3 className="text-base font-extrabold text-slate-900">{job.companyName}</h3>
                    <StatusBadge status={job.status} size="sm" />
                  </div>
                  <div className="text-xs text-slate-500 mt-0.5">
                    Owner Phone: <strong>{job.ownerPhone}</strong> • Target: <strong>{job.targetMode}</strong>
                  </div>
                </div>

                {job.status === 'Preparing' && (
                  <button
                    onClick={() => handleStartMigration(job.id, job.companyId)}
                    disabled={isStarting}
                    className="inline-flex items-center gap-1.5 px-4 py-2 bg-emerald-600 hover:bg-emerald-700 text-white rounded-xl text-xs font-bold shadow-xs cursor-pointer"
                  >
                    <Play className="w-4 h-4" />
                    <span>{isStarting ? 'Initiating...' : 'Execute Cloud Import Pipeline'}</span>
                  </button>
                )}
              </div>

              {/* Progress bar */}
              <div className="space-y-1.5">
                <div className="flex justify-between text-xs text-slate-600">
                  <span className="font-medium text-slate-800">Current Step: {job.currentStep}</span>
                  <span className="font-bold text-emerald-700">
                    {job.processedRecordsCount} / {job.totalRecordsCount} Records (
                    {Math.round((job.processedRecordsCount / Math.max(1, job.totalRecordsCount)) * 100)}%)
                  </span>
                </div>
                <div className="w-full h-2.5 bg-slate-100 rounded-full overflow-hidden">
                  <div
                    className="h-full bg-emerald-600 rounded-full transition-all duration-500"
                    style={{ width: `${(job.processedRecordsCount / Math.max(1, job.totalRecordsCount)) * 100}%` }}
                  />
                </div>
              </div>

              <div className="pt-2 border-t border-slate-100 flex flex-wrap items-center justify-between text-[11px] text-slate-400">
                <span>Initiated by: {job.initiatedBy}</span>
                {job.completedAt && <span>Completed: {job.completedAt}</span>}
              </div>
            </div>
          ))
        ) : (
          <div className="p-10 bg-white rounded-2xl border border-slate-200 text-center space-y-2">
            <Database className="w-8 h-8 text-slate-400 mx-auto" />
            <div className="text-sm font-bold text-slate-800">No Pending Solo SQLite Migrations</div>
            <p className="text-xs text-slate-500 max-w-md mx-auto">
              All registered subscribers are operating on native Cloud Android, Flutter Web, or enterprise multi-device tiers.
            </p>
          </div>
        )}
      </div>
    </div>
  );
};
