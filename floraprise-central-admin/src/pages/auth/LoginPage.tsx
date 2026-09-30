import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';
import { ArrowRight, Lock, Mail, AlertCircle } from 'lucide-react';

export const LoginPage: React.FC = () => {
  const navigate = useNavigate();
  const { login, loginWithCredentials, isAuthenticating } = useAuth();
  const [email, setEmail] = useState('admin@floraprise.com');
  const [password, setPassword] = useState('Flora@Admin2026!');
  const [rememberMe, setRememberMe] = useState(true);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setErrorMessage(null);

    const result = await loginWithCredentials(email, password);
    if (result.success) {
      navigate('/dashboard');
    } else {
      setErrorMessage(result.error || 'Authentication failed. Please verify Sumpooj.API is running.');
    }
  };

  const handleQuickLogin = async (roleEmail: string, defaultPass: string) => {
    setErrorMessage(null);
    setEmail(roleEmail);
    setPassword(defaultPass);
    const result = await loginWithCredentials(roleEmail, defaultPass);
    if (result.success) {
      navigate('/dashboard');
    } else {
      setErrorMessage(result.error || 'Quick login failed. Verify Sumpooj.API credentials.');
    }
  };

  return (
    <div className="min-h-screen bg-slate-900 flex items-center justify-center p-4 relative overflow-hidden">
      {/* Background glow effects */}
      <div className="absolute top-1/4 left-1/4 w-96 h-96 bg-emerald-500/10 rounded-full blur-3xl pointer-events-none" />
      <div className="absolute bottom-1/4 right-1/4 w-96 h-96 bg-teal-500/10 rounded-full blur-3xl pointer-events-none" />

      <div className="w-full max-w-md bg-slate-800/90 border border-slate-700/80 rounded-3xl p-8 shadow-2xl backdrop-blur-md relative z-10">
        {/* Brand Header */}
        <div className="text-center mb-8">
          <div className="w-14 h-14 rounded-2xl bg-gradient-to-br from-emerald-500 to-teal-700 flex items-center justify-center text-white font-black text-xl shadow-lg shadow-emerald-950 mx-auto mb-4">
            FP
          </div>
          <h1 className="text-2xl font-black text-white tracking-tight">FLORAPRISE</h1>
          <p className="text-xs font-semibold text-emerald-400 uppercase tracking-wider mt-1">Central Admin Control Center</p>
          <p className="text-xs text-slate-400 mt-2">Manage subscribers, multi-tenant provisioning, licenses, and delivery tracking.</p>
        </div>

        {errorMessage && (
          <div className="mb-4 p-3 rounded-xl bg-rose-500/10 border border-rose-500/30 flex items-start gap-2.5 text-xs text-rose-300">
            <AlertCircle className="w-4 h-4 text-rose-400 shrink-0 mt-0.5" />
            <span>{errorMessage}</span>
          </div>
        )}

        {/* Login Form */}
        <form onSubmit={handleSubmit} className="space-y-4 text-xs">
          <div>
            <label className="block text-slate-300 font-semibold mb-1.5">Admin Email</label>
            <div className="relative">
              <Mail className="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
              <input
                type="email"
                value={email}
                onChange={e => setEmail(e.target.value)}
                required
                className="w-full pl-10 pr-4 py-2.5 bg-slate-900/80 border border-slate-700 rounded-xl text-white placeholder:text-slate-500 focus:outline-none focus:ring-2 focus:ring-emerald-500/40 focus:border-emerald-500 text-xs"
              />
            </div>
          </div>

          <div>
            <div className="flex items-center justify-between mb-1.5">
              <label className="text-slate-300 font-semibold">Master Password</label>
              <span className="text-[11px] text-emerald-400 hover:underline cursor-pointer">Hardware 2FA Active</span>
            </div>
            <div className="relative">
              <Lock className="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
              <input
                type="password"
                value={password}
                onChange={e => setPassword(e.target.value)}
                required
                className="w-full pl-10 pr-4 py-2.5 bg-slate-900/80 border border-slate-700 rounded-xl text-white placeholder:text-slate-500 focus:outline-none focus:ring-2 focus:ring-emerald-500/40 focus:border-emerald-500 text-xs"
              />
            </div>
          </div>

          <div className="flex items-center justify-between pt-1 text-slate-400">
            <label className="flex items-center gap-2 cursor-pointer select-none">
              <input
                type="checkbox"
                checked={rememberMe}
                onChange={e => setRememberMe(e.target.checked)}
                className="rounded accent-emerald-500"
              />
              <span>Remember this workstation</span>
            </label>
            <span className="text-[11px] font-mono text-slate-500">TLS 1.3 / Encrypted</span>
          </div>

          <button
            type="submit"
            disabled={isAuthenticating}
            className="w-full mt-4 py-3 bg-emerald-600 hover:bg-emerald-500 disabled:opacity-50 text-white font-bold rounded-xl shadow-lg shadow-emerald-950/50 flex items-center justify-center gap-2 transition-all cursor-pointer"
          >
            <span>{isAuthenticating ? 'Connecting to Sumpooj.API...' : 'Sign In to Central Admin'}</span>
            <ArrowRight className="w-4 h-4" />
          </button>
        </form>

        {/* Quick Demo Login Profiles */}
        <div className="mt-8 pt-6 border-t border-slate-700/60">
          <div className="text-[11px] font-semibold text-slate-400 uppercase tracking-wider text-center mb-3">
            Quick Operator Profiles (Development)
          </div>
          <div className="grid grid-cols-2 gap-2 text-xs">
            <button
              onClick={() => handleQuickLogin('admin@floraprise.com', 'Flora@Admin2026!')}
              className="p-2.5 bg-slate-900/60 hover:bg-slate-700/60 border border-slate-700 rounded-xl text-left text-slate-300 hover:text-white transition-colors cursor-pointer"
            >
              <div className="font-bold text-white">Central Admin</div>
              <div className="text-[10px] text-emerald-400">admin@floraprise.com</div>
            </button>
            <button
              onClick={() => handleQuickLogin('sumit.singh@sumpooj.com', 'Admin@123')}
              className="p-2.5 bg-slate-900/60 hover:bg-slate-700/60 border border-slate-700 rounded-xl text-left text-slate-300 hover:text-white transition-colors cursor-pointer"
            >
              <div className="font-bold text-white">Super Admin</div>
              <div className="text-[10px] text-sky-400">sumit.singh@sumpooj.com</div>
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};
