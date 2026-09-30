import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { realExistingToolsService } from '../../services/api/realExistingToolsService';
import { ExistingAdminTool, ExistingToolCategory, ExistingToolStatus } from '../../types/existingTools';
import { 
  ExternalLink, 
  LayoutDashboard, 
  UserCheck, 
  Smartphone, 
  Building2, 
  Users, 
  KeyRound, 
  ShieldAlert, 
  MapPin, 
  Trash2,
  Sliders,
  BarChart3,
  Activity,
  CreditCard,
  ShieldCheck,
  Lock,
  CheckCircle2,
  Layers,
  ArrowUpRight
} from 'lucide-react';

export const ExistingToolsPage: React.FC = () => {
  const [tools, setTools] = useState<ExistingAdminTool[]>([]);
  const [selectedCategory, setSelectedCategory] = useState<string>('all');
  const [searchQuery, setSearchQuery] = useState<string>('');

  useEffect(() => {
    realExistingToolsService.getTools().then(setTools);
  }, []);

  const categories: ('all' | ExistingToolCategory)[] = [
    'all',
    'PLATFORM',
    'CUSTOMER / SALES',
    'SUBSCRIPTIONS',
    'OPERATIONS'
  ];

  const filtered = tools.filter(t => {
    const matchesCategory = selectedCategory === 'all' || t.category === selectedCategory;
    const matchesSearch = !searchQuery || 
      t.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      t.description.toLowerCase().includes(searchQuery.toLowerCase()) ||
      t.url.toLowerCase().includes(searchQuery.toLowerCase()) ||
      t.authRequirement.toLowerCase().includes(searchQuery.toLowerCase());
    return matchesCategory && matchesSearch;
  });

  const getIcon = (iconName: string) => {
    switch (iconName) {
      case 'LayoutDashboard': return <LayoutDashboard className="w-5 h-5" />;
      case 'UserCheck': return <UserCheck className="w-5 h-5" />;
      case 'Smartphone': return <Smartphone className="w-5 h-5" />;
      case 'Building2': return <Building2 className="w-5 h-5" />;
      case 'Users': return <Users className="w-5 h-5" />;
      case 'KeyRound': return <KeyRound className="w-5 h-5" />;
      case 'ShieldAlert': return <ShieldAlert className="w-5 h-5" />;
      case 'MapPin': return <MapPin className="w-5 h-5" />;
      case 'Trash2': return <Trash2 className="w-5 h-5" />;
      case 'Sliders': return <Sliders className="w-5 h-5" />;
      case 'BarChart3': return <BarChart3 className="w-5 h-5" />;
      case 'Activity': return <Activity className="w-5 h-5" />;
      case 'CreditCard': return <CreditCard className="w-5 h-5" />;
      default: return <ExternalLink className="w-5 h-5" />;
    }
  };

  const getStatusBadge = (status: ExistingToolStatus) => {
    switch (status) {
      case 'Available':
        return (
          <span className="inline-flex items-center gap-1 text-[10px] font-bold px-2 py-0.5 rounded-full bg-emerald-100 text-emerald-800 border border-emerald-200">
            <CheckCircle2 className="w-3 h-3 text-emerald-600" />
            <span>Available</span>
          </span>
        );
      case 'Requires Separate Login':
        return (
          <span className="inline-flex items-center gap-1 text-[10px] font-bold px-2 py-0.5 rounded-full bg-amber-100 text-amber-800 border border-amber-200">
            <Lock className="w-3 h-3 text-amber-600" />
            <span>Requires Separate Login</span>
          </span>
        );
      case 'Tenant-Scoped':
        return (
          <span className="inline-flex items-center gap-1 text-[10px] font-bold px-2 py-0.5 rounded-full bg-sky-100 text-sky-800 border border-sky-200">
            <MapPin className="w-3 h-3 text-sky-600" />
            <span>Tenant-Scoped</span>
          </span>
        );
      case 'Not Connected':
      default:
        return (
          <span className="inline-flex items-center gap-1 text-[10px] font-bold px-2 py-0.5 rounded-full bg-slate-100 text-slate-700 border border-slate-200">
            <span>Not Connected</span>
          </span>
        );
    }
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h2 className="text-xl font-black text-slate-900 flex items-center gap-2">
            <ExternalLink className="w-5 h-5 text-emerald-600" />
            <span>Floraprise Existing Admin Tools Launchpad</span>
          </h2>
          <p className="text-xs text-slate-500 mt-0.5">
            Authoritative directory connecting Central Admin to verified ERP backoffice portals, mobile administration registries, and tenant dispatch centers.
          </p>
        </div>
      </div>

      {/* Category Filter Pills & Search */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
        <div className="flex items-center gap-2 overflow-x-auto pb-1">
          {categories.map(cat => (
            <button
              key={cat}
              onClick={() => setSelectedCategory(cat)}
              className={`px-3.5 py-1.5 rounded-full text-xs font-semibold whitespace-nowrap transition-all cursor-pointer ${
                selectedCategory === cat
                  ? 'bg-emerald-600 text-white shadow-xs'
                  : 'bg-white border border-slate-200 text-slate-600 hover:bg-slate-50'
              }`}
            >
              {cat === 'all' ? 'All Admin Tools' : cat}
            </button>
          ))}
        </div>

        <input
          type="text"
          placeholder="Filter tools by name, role, URL..."
          value={searchQuery}
          onChange={e => setSearchQuery(e.target.value)}
          className="px-3 py-1.5 bg-white border border-slate-200 rounded-xl text-xs text-slate-800 placeholder:text-slate-400 focus:outline-none focus:border-emerald-500 w-full sm:w-64"
        />
      </div>

      {/* Tools Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {filtered.map(tool => {
          const isInternal = tool.target === '_self' || tool.url.startsWith('/');
          const CardWrapper = isInternal ? Link : 'a';
          const cardProps = isInternal 
            ? { to: tool.url } 
            : { href: tool.url, target: tool.target, rel: 'noopener noreferrer' };

          return (
            <CardWrapper
              key={tool.id}
              {...(cardProps as any)}
              className="bg-white p-5 rounded-3xl border border-slate-200 shadow-xs hover:shadow-md hover:border-emerald-300 transition-all flex flex-col justify-between group"
            >
              <div className="space-y-3">
                <div className="flex items-start justify-between">
                  <div className="w-11 h-11 rounded-2xl bg-emerald-50 text-emerald-700 border border-emerald-100 flex items-center justify-center group-hover:scale-105 transition-transform">
                    {getIcon(tool.iconName)}
                  </div>
                  <div className="flex flex-col items-end gap-1">
                    {getStatusBadge(tool.status)}
                    {tool.badge && (
                      <span className="text-[10px] font-bold px-2 py-0.5 rounded-full bg-slate-100 text-slate-700">
                        {tool.badge}
                      </span>
                    )}
                  </div>
                </div>

                <div>
                  <h3 className="text-sm font-bold text-slate-900 group-hover:text-emerald-700 transition-colors flex items-center gap-1.5">
                    <span>{tool.name}</span>
                    <ArrowUpRight className="w-3.5 h-3.5 text-slate-400 group-hover:text-emerald-600 opacity-0 group-hover:opacity-100 transition-opacity" />
                  </h3>
                  
                  <div className="flex items-center gap-2 mt-1">
                    <span className="text-[10px] font-bold uppercase tracking-wider px-2 py-0.5 rounded bg-slate-100 text-slate-600">
                      {tool.category}
                    </span>
                  </div>

                  <p className="text-xs text-slate-500 mt-2 line-clamp-2 leading-relaxed">
                    {tool.description}
                  </p>
                </div>

                <div className="pt-2 border-t border-slate-100/80 text-[11px] text-slate-500">
                  <span className="font-semibold text-slate-700">Auth Requirement: </span>
                  <span className="font-mono text-slate-600">{tool.authRequirement}</span>
                </div>
              </div>

              <div className="pt-3 mt-3 border-t border-slate-100 flex items-center justify-between text-xs font-semibold text-emerald-700">
                <span className="font-mono text-[11px] text-slate-400 truncate max-w-[200px]">{tool.url}</span>
                <span className="group-hover:translate-x-1 transition-transform flex items-center gap-0.5">
                  <span>{isInternal ? 'Open' : 'Launch'}</span>
                  <span>↗</span>
                </span>
              </div>
            </CardWrapper>
          );
        })}
      </div>
    </div>
  );
};
