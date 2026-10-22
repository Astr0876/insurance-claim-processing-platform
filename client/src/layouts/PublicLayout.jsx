import React from 'react';
import { Outlet, Link, useLocation } from 'react-router-dom';
import { Shield, ChevronRight, ArrowRight, Lock, CheckCircle2 } from 'lucide-react';
import { useAuth } from '../context/AuthContext';
import DemoCredentialsBar from '../components/common/DemoCredentialsBar';

const PublicLayout = () => {
  const location = useLocation();
  const { isAuthenticated, user, getDashboardRoute } = useAuth();

  const navLinks = [
    { name: 'Home', path: '/' },
    { name: 'Features', path: '/features' },
    { name: 'How It Works', path: '/how-it-works' },
    { name: 'About', path: '/about' },
  ];

  return (
    <div className="min-h-screen flex flex-col bg-slate-50 text-slate-900">
      {/* Top Demo Bar */}
      <div className="bg-slate-950 px-4 py-1.5 border-b border-slate-800">
        <div className="max-w-7xl mx-auto">
          <DemoCredentialsBar />
        </div>
      </div>

      {/* Main Navbar */}
      <header className="sticky top-0 z-40 bg-white/90 backdrop-blur-md border-b border-slate-200/80 transition-all">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-16 flex items-center justify-between">
          {/* Logo */}
          <Link to="/" className="flex items-center gap-2.5 group">
            <div className="w-10 h-10 rounded-xl bg-gradient-to-tr from-indigo-700 to-indigo-500 flex items-center justify-center text-white shadow-md shadow-indigo-200 group-hover:scale-105 transition-transform">
              <Shield className="w-5 h-5 fill-white/20" />
            </div>
            <div>
              <span className="text-lg font-extrabold tracking-tight text-slate-900 flex items-center gap-1">
                Secure<span className="text-indigo-600">Claim</span>
              </span>
              <span className="block text-[10px] tracking-wider uppercase font-semibold text-slate-400 -mt-1">
                Fraud Detection & Claim Engine
              </span>
            </div>
          </Link>

          {/* Navigation links */}
          <nav className="hidden md:flex items-center gap-8 text-sm font-medium">
            {navLinks.map((link) => {
              const isActive = location.pathname === link.path;
              return (
                <Link
                  key={link.path}
                  to={link.path}
                  className={`transition-colors py-1 ${
                    isActive
                      ? 'text-indigo-600 font-semibold border-b-2 border-indigo-600'
                      : 'text-slate-600 hover:text-indigo-600'
                  }`}
                >
                  {link.name}
                </Link>
              );
            })}
          </nav>

          {/* Auth Actions */}
          <div className="flex items-center gap-3">
            {isAuthenticated ? (
              <Link
                to={getDashboardRoute()}
                className="inline-flex items-center gap-2 px-4 py-2 text-sm font-semibold text-white bg-indigo-600 hover:bg-indigo-700 rounded-lg shadow-sm transition active:scale-95"
              >
                <span>Dashboard ({user?.role})</span>
                <ArrowRight className="w-4 h-4" />
              </Link>
            ) : (
              <>
                <Link
                  to="/login"
                  className="px-4 py-2 text-sm font-semibold text-slate-700 hover:text-indigo-600 hover:bg-slate-100 rounded-lg transition"
                >
                  Sign In
                </Link>
                <Link
                  to="/register"
                  className="inline-flex items-center gap-1.5 px-4 py-2 text-sm font-semibold text-white bg-indigo-600 hover:bg-indigo-700 rounded-lg shadow-sm transition active:scale-95"
                >
                  <span>Submit Claim</span>
                  <ChevronRight className="w-4 h-4" />
                </Link>
              </>
            )}
          </div>
        </div>
      </header>

      {/* Main Page Body */}
      <main className="flex-grow">
        <Outlet />
      </main>

      {/* Footer */}
      <footer className="bg-slate-950 text-slate-400 border-t border-slate-900 mt-20">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
          <div className="grid grid-cols-1 md:grid-cols-4 gap-8 mb-10">
            <div className="md:col-span-1">
              <div className="flex items-center gap-2 mb-3">
                <div className="w-8 h-8 rounded-lg bg-indigo-600 flex items-center justify-center text-white">
                  <Shield className="w-4 h-4" />
                </div>
                <span className="text-base font-bold text-white tracking-tight">
                  Secure<span className="text-indigo-400">Claim</span>
                </span>
              </div>
              <p className="text-xs text-slate-400 leading-relaxed mb-4">
                Automated insurance claim intake, multi-tier document verification, explainable AI fraud risk scoring, and role-based adjudication.
              </p>
              <div className="inline-flex items-center gap-1.5 text-xs text-emerald-400 font-mono bg-emerald-950/60 px-2.5 py-1 rounded-full border border-emerald-800/40">
                <span className="w-1.5 h-1.5 rounded-full bg-emerald-400 animate-pulse" />
                All Systems Operational
              </div>
            </div>

            <div>
              <h4 className="text-xs font-semibold text-white tracking-wider uppercase mb-3">
                Platform Workflows
              </h4>
              <ul className="space-y-2 text-xs">
                <li><Link to="/register" className="hover:text-white transition">Online Claim Submission</Link></li>
                <li><Link to="/how-it-works" className="hover:text-white transition">Document Integrity Verification</Link></li>
                <li><Link to="/how-it-works" className="hover:text-white transition">Explainable AI Risk Engine</Link></li>
                <li><Link to="/how-it-works" className="hover:text-white transition">Special Investigation Unit (SIU)</Link></li>
              </ul>
            </div>

            <div>
              <h4 className="text-xs font-semibold text-white tracking-wider uppercase mb-3">
                Stakeholders & Roles
              </h4>
              <ul className="space-y-2 text-xs">
                <li><Link to="/login" className="hover:text-white transition">Customer (Policyholder)</Link></li>
                <li><Link to="/login" className="hover:text-white transition">Insurance Claims Processor</Link></li>
                <li><Link to="/login" className="hover:text-white transition">Fraud Investigation Officer</Link></li>
                <li><Link to="/login" className="hover:text-white transition">Operations Manager & Admin</Link></li>
              </ul>
            </div>

            <div>
              <h4 className="text-xs font-semibold text-white tracking-wider uppercase mb-3">
                Software Engineering Project
              </h4>
              <p className="text-xs text-slate-400 leading-relaxed">
                Developed as a full-stack platform following SRS, Feasibility Study, and Elicitation specifications.
              </p>
              <div className="mt-3 text-xs text-slate-300">
                <span className="font-semibold text-white">Authors:</span> Yash Patel & Rudra Patel<br />
                <span className="text-slate-400 font-mono text-[11px]">Roll: 2024300162, 2024300163</span>
              </div>
            </div>
          </div>

          <div className="pt-8 border-t border-slate-900 flex flex-col sm:flex-row items-center justify-between text-xs text-slate-500 gap-4">
            <p>© 2026 SecureClaim Platform. Academic Software Engineering Case Study.</p>
            <div className="flex items-center gap-6">
              <span className="flex items-center gap-1 text-slate-400">
                <Lock className="w-3.5 h-3.5 text-indigo-400" /> End-to-End Encrypted & Audited
              </span>
            </div>
          </div>
        </div>
      </footer>
    </div>
  );
};

export default PublicLayout;
