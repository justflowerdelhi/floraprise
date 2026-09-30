import React, { useState, useEffect } from 'react';
import { realDeviceService } from '../../services/api/realDeviceService';
import { AppRelease } from '../../types/device';
import { StatusBadge } from '../../components/common/StatusBadge';
import { Smartphone, Download, CheckCircle2, AlertCircle, ArrowUpCircle } from 'lucide-react';

export const AppVersionsPage: React.FC = () => {
  const [releases, setReleases] = useState<AppRelease[]>([]);

  useEffect(() => {
    realDeviceService.getAppReleases().then(setReleases);
  }, []);

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-xl font-black text-slate-900 flex items-center gap-2">
          <Smartphone className="w-5 h-5 text-emerald-600" />
          <span>Application Releases & Version Matrix</span>
        </h2>
        <p className="text-xs text-slate-500 mt-0.5">
          Active production builds, minimum supported versions, and mandatory upgrade rules for all clients.
        </p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {releases.map(rel => (
          <div
            key={rel.id}
            className="bg-white rounded-3xl p-6 border border-slate-200/80 shadow-xs hover:shadow-md transition-all space-y-4"
          >
            <div className="flex items-start justify-between">
              <div>
                <span className="text-[11px] font-bold uppercase tracking-wider text-slate-400">{rel.appType}</span>
                <div className="flex items-center gap-2.5 mt-0.5">
                  <h3 className="text-lg font-black text-slate-900">{rel.version}</h3>
                  <span className="text-xs font-mono text-slate-500 bg-slate-100 px-2 py-0.5 rounded">
                    Build #{rel.buildNumber}
                  </span>
                  <StatusBadge status={rel.healthStatus} size="sm" />
                </div>
              </div>

              {rel.isMandatory && (
                <span className="px-2.5 py-1 bg-amber-50 text-amber-800 border border-amber-200 rounded-full text-[10px] font-bold">
                  Mandatory Upgrade
                </span>
              )}
            </div>

            <div className="grid grid-cols-3 gap-2 p-3 bg-slate-50 rounded-2xl text-xs text-slate-600">
              <div>
                <span className="text-slate-400 block text-[10px]">Released</span>
                <strong className="text-slate-800">{rel.releaseDate}</strong>
              </div>
              <div>
                <span className="text-slate-400 block text-[10px]">Min. Supported</span>
                <strong className="text-slate-800">{rel.minSupportedVersion}</strong>
              </div>
              <div>
                <span className="text-slate-400 block text-[10px]">Active Installs</span>
                <strong className="text-emerald-700 font-bold">{rel.activeInstallsCount}</strong>
              </div>
            </div>

            {/* Release notes */}
            <div className="space-y-1.5 pt-1">
              <div className="text-[11px] font-bold text-slate-500 uppercase tracking-wider">Release Highlights</div>
              <ul className="space-y-1 text-xs text-slate-700">
                {rel.releaseNotes.map((note, idx) => (
                  <li key={idx} className="flex items-start gap-2">
                    <CheckCircle2 className="w-3.5 h-3.5 text-emerald-600 shrink-0 mt-0.5" />
                    <span>{note}</span>
                  </li>
                ))}
              </ul>
            </div>

            {rel.downloadUrl && (
              <div className="pt-3 border-t border-slate-100 flex items-center justify-between">
                <span className="text-[11px] text-slate-400 font-mono truncate max-w-xs">{rel.downloadUrl}</span>
                <a
                  href={rel.downloadUrl}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="inline-flex items-center gap-1.5 px-3 py-1.5 text-xs font-bold rounded-xl bg-slate-900 hover:bg-slate-800 text-white shadow-xs transition-colors"
                >
                  <Download className="w-3.5 h-3.5" />
                  <span>Download Build</span>
                </a>
              </div>
            )}
          </div>
        ))}
      </div>
    </div>
  );
};
