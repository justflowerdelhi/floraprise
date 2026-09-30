import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { Search, Building2, Smartphone, ExternalLink, Wrench, X } from 'lucide-react';
import { realSubscriberService } from '../../services/api/realSubscriberService';
import { realExistingToolsService } from '../../services/api/realExistingToolsService';
import { Subscriber } from '../../types/subscriber';
import { ExistingAdminTool } from '../../types/existingTools';
import { StatusBadge } from '../common/StatusBadge';

interface GlobalSearchModalProps {
  isOpen: boolean;
  onClose: () => void;
}

export const GlobalSearchModal: React.FC<GlobalSearchModalProps> = ({ isOpen, onClose }) => {
  const navigate = useNavigate();
  const [query, setQuery] = useState('');
  const [subscribers, setSubscribers] = useState<Subscriber[]>([]);
  const [tools, setTools] = useState<ExistingAdminTool[]>([]);

  useEffect(() => {
    if (isOpen) {
      realSubscriberService.getSubscribers().then(setSubscribers).catch(() => []);
      realExistingToolsService.getTools().then(setTools);
      setQuery('');
    }
  }, [isOpen]);

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape' && isOpen) onClose();
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [isOpen, onClose]);

  if (!isOpen) return null;

  const q = query.trim().toLowerCase();
  const filteredSubscribers = subscribers.filter(s => 
    !q || 
    s.businessName.toLowerCase().includes(q) || 
    s.ownerName.toLowerCase().includes(q) ||
    s.mobile.includes(q) ||
    s.city.toLowerCase().includes(q)
  ).slice(0, 5);

  const filteredTools = tools.filter(t =>
    !q ||
    t.name.toLowerCase().includes(q) ||
    t.description.toLowerCase().includes(q) ||
    t.category.toLowerCase().includes(q)
  ).slice(0, 4);

  return (
    <div className="fixed inset-0 z-50 overflow-y-auto flex items-start justify-center p-4 pt-20 bg-slate-900/60 backdrop-blur-xs animate-in fade-in duration-150">
      <div 
        className="bg-white rounded-2xl shadow-2xl border border-slate-200 w-full max-w-2xl overflow-hidden flex flex-col animate-in zoom-in-95 duration-150"
        onClick={e => e.stopPropagation()}
      >
        {/* Search Input Bar */}
        <div className="p-4 border-b border-slate-100 flex items-center gap-3">
          <Search className="w-5 h-5 text-emerald-600 shrink-0" />
          <input
            autoFocus
            type="text"
            value={query}
            onChange={e => setQuery(e.target.value)}
            placeholder="Search subscribers by name, phone, city, or existing admin tools... (Press ESC to exit)"
            className="flex-1 text-sm bg-transparent border-none text-slate-900 placeholder:text-slate-400 focus:outline-none"
          />
          <button 
            onClick={onClose}
            className="p-1 text-slate-400 hover:text-slate-600 rounded-lg hover:bg-slate-100"
          >
            <X className="w-4 h-4" />
          </button>
        </div>

        {/* Results */}
        <div className="p-4 overflow-y-auto max-h-[60vh] space-y-4 text-xs">
          {/* Subscribers section */}
          <div>
            <div className="text-[11px] font-bold uppercase tracking-wider text-slate-400 px-2 mb-2 flex items-center gap-1.5">
              <Building2 className="w-3.5 h-3.5" />
              <span>Subscribers & Tenants</span>
            </div>
            {filteredSubscribers.length > 0 ? (
              <div className="space-y-1">
                {filteredSubscribers.map(sub => (
                  <div
                    key={sub.id}
                    onClick={() => {
                      navigate(`/subscribers/${sub.id}`);
                      onClose();
                    }}
                    className="p-2.5 rounded-xl hover:bg-emerald-50/60 flex items-center justify-between cursor-pointer group transition-colors"
                  >
                    <div className="flex items-center gap-3">
                      <div className="w-8 h-8 rounded-lg bg-slate-100 group-hover:bg-emerald-100 text-slate-700 group-hover:text-emerald-800 flex items-center justify-center font-bold text-xs">
                        {sub.businessName.charAt(0)}
                      </div>
                      <div>
                        <div className="font-bold text-slate-900 group-hover:text-emerald-900">{sub.businessName}</div>
                        <div className="text-[11px] text-slate-500">{sub.ownerName} • {sub.mobile} • {sub.city}</div>
                      </div>
                    </div>
                    <div className="flex items-center gap-2">
                      <StatusBadge status={sub.status} size="sm" />
                      <span className="text-[10px] text-slate-400 font-mono">{sub.id.substring(0, 8)}...</span>
                    </div>
                  </div>
                ))}
              </div>
            ) : (
              <div className="text-slate-400 px-2 py-1 text-xs">No matching subscribers found</div>
            )}
          </div>

          {/* Existing Admin Tools */}
          <div>
            <div className="text-[11px] font-bold uppercase tracking-wider text-slate-400 px-2 mb-2 flex items-center gap-1.5">
              <ExternalLink className="w-3.5 h-3.5" />
              <span>Existing Admin Tools</span>
            </div>
            <div className="space-y-1">
              {filteredTools.map(tool => (
                <a
                  key={tool.id}
                  href={tool.url}
                  target="_blank"
                  rel="noopener noreferrer"
                  onClick={onClose}
                  className="p-2.5 rounded-xl hover:bg-slate-50 flex items-center justify-between cursor-pointer group transition-colors text-slate-900 block"
                >
                  <div className="flex items-center gap-3">
                    <div className="w-8 h-8 rounded-lg bg-emerald-50 text-emerald-700 flex items-center justify-center font-bold text-xs">
                      <Wrench className="w-4 h-4" />
                    </div>
                    <div>
                      <div className="font-semibold text-slate-900 group-hover:text-emerald-700">{tool.name}</div>
                      <div className="text-[11px] text-slate-500">{tool.description}</div>
                    </div>
                  </div>
                  <div className="flex items-center gap-1.5 text-[11px] text-emerald-700 font-medium">
                    <span>Open</span>
                    <ExternalLink className="w-3 h-3" />
                  </div>
                </a>
              ))}
            </div>
          </div>
        </div>

        {/* Footer */}
        <div className="p-3 bg-slate-50 border-t border-slate-100 flex items-center justify-between text-[11px] text-slate-500 px-4">
          <span>Tip: Press <code>ESC</code> to close</span>
          <span>Floraprise Central Admin Global Index</span>
        </div>
      </div>
    </div>
  );
};
