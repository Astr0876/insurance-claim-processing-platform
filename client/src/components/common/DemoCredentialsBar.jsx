import React from 'react';
import { useAuth, DEMO_ACCOUNTS } from '../../context/AuthContext';
import { useNavigate } from 'react-router-dom';
import { Zap, UserCheck } from 'lucide-react';

const DemoCredentialsBar = ({ className = '', onAccountSelected }) => {
  const { quickDemoLogin, getDashboardRoute } = useAuth();
  const navigate = useNavigate();

  const handleQuickLogin = async (acc) => {
    if (onAccountSelected) {
      onAccountSelected(acc.email, 'Password123!');
      return;
    }

    try {
      const user = await quickDemoLogin(acc.email);
      navigate(getDashboardRoute(user.role));
    } catch (err) {
      console.error('Demo login error:', err);
    }
  };

  return (
    <div className={`bg-gradient-to-r from-slate-900 to-indigo-950 text-white p-3 rounded-xl border border-indigo-900/40 shadow-sm ${className}`}>
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2.5">
        <div className="flex items-center gap-2">
          <div className="p-1.5 rounded-lg bg-indigo-500/20 text-indigo-300">
            <Zap className="w-4 h-4 text-amber-400 fill-amber-400" />
          </div>
          <div>
            <span className="text-xs font-bold tracking-wider uppercase text-indigo-300">
              Demo Mode Quick Switch
            </span>
            <p className="text-[11px] text-slate-300 hidden md:block">
              Click any role to test immediate end-to-end access (Password: <code className="text-amber-300 font-mono">Password123!</code>)
            </p>
          </div>
        </div>

        <div className="flex flex-wrap items-center gap-1.5">
          {DEMO_ACCOUNTS.map((acc) => (
            <button
              key={acc.role}
              type="button"
              onClick={() => handleQuickLogin(acc)}
              className="px-2.5 py-1 text-xs font-semibold rounded-lg bg-white/10 hover:bg-white/20 active:scale-95 text-slate-100 hover:text-white transition-all border border-white/10 flex items-center gap-1.5"
            >
              <UserCheck className="w-3 h-3 text-indigo-400" />
              <span>{acc.label}</span>
            </button>
          ))}
        </div>
      </div>
    </div>
  );
};

export default DemoCredentialsBar;
