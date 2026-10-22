import React, { useState } from 'react';
import { Link } from 'react-router-dom';
import {
  Shield,
  ArrowRight,
  CheckCircle2,
  AlertTriangle,
  FileCheck,
  TrendingUp,
  Lock,
  Zap,
  Activity,
  FileText,
  UserCheck,
  Search,
  Sparkles
} from 'lucide-react';
import { useAuth } from '../../context/AuthContext';

const HomePage = () => {
  const { isAuthenticated, getDashboardRoute } = useAuth();

  // Interactive Live Fraud Simulator on Hero
  const [simAmount, setSimAmount] = useState(28500);
  const [simCoverage, setSimCoverage] = useState(30000);
  const [simLag, setSimLag] = useState(1);
  const [simHasDocs, setSimHasDocs] = useState(false);

  // Compute live client-side preview of risk engine
  const ratio = simAmount / (simCoverage || 1);
  let simScore = 10;
  if (ratio >= 0.85) simScore += 35;
  else if (ratio >= 0.5) simScore += 18;
  if (simLag <= 30) simScore += 25; // Policy velocity
  if (!simHasDocs) simScore += 20;

  const simLevel = simScore >= 65 ? 'HIGH' : (simScore >= 35 ? 'MEDIUM' : 'LOW');

  return (
    <div className="relative overflow-hidden">
      {/* Background radial glowing effects */}
      <div className="absolute top-0 left-1/2 -translate-x-1/2 w-[1000px] h-[500px] bg-gradient-to-b from-indigo-100/60 via-indigo-50/20 to-transparent blur-3xl pointer-events-none -z-10" />

      {/* Hero Section */}
      <section className="pt-16 pb-20 px-4 sm:px-6 lg:px-8 max-w-7xl mx-auto">
        <div className="text-center max-w-3xl mx-auto mb-12">
          <div className="inline-flex items-center gap-2 px-3 py-1.5 rounded-full bg-indigo-50 border border-indigo-200/80 text-indigo-700 text-xs font-semibold mb-6 shadow-sm">
            <Sparkles className="w-3.5 h-3.5 text-indigo-600" />
            <span>AI-Assisted Fraud Risk Detection Engine v1.2</span>
          </div>

          <h1 className="text-4xl sm:text-5xl lg:text-6xl font-extrabold text-slate-950 tracking-tight leading-[1.12]">
            Smarter Claims. Faster Decisions.{' '}
            <span className="text-transparent bg-clip-text bg-gradient-to-r from-indigo-600 via-indigo-700 to-blue-600">
              Safer Insurance.
            </span>
          </h1>

          <p className="mt-6 text-base sm:text-lg text-slate-600 leading-relaxed font-normal">
            An intelligent full-stack platform for secure claim submission, automated document verification, explainable AI fraud detection, and transparent end-to-end claim adjudication.
          </p>

          <div className="mt-8 flex flex-col sm:flex-row items-center justify-center gap-3.5">
            {isAuthenticated ? (
              <Link
                to={getDashboardRoute()}
                className="w-full sm:w-auto px-7 py-3.5 rounded-xl font-bold text-sm text-white bg-indigo-600 hover:bg-indigo-700 shadow-lg shadow-indigo-200 transition-all active:scale-95 flex items-center justify-center gap-2"
              >
                <span>Go to My Dashboard</span>
                <ArrowRight className="w-4 h-4" />
              </Link>
            ) : (
              <>
                <Link
                  to="/register"
                  className="w-full sm:w-auto px-7 py-3.5 rounded-xl font-bold text-sm text-white bg-indigo-600 hover:bg-indigo-700 shadow-lg shadow-indigo-200 transition-all active:scale-95 flex items-center justify-center gap-2"
                >
                  <span>Submit a Claim</span>
                  <ArrowRight className="w-4 h-4" />
                </Link>
                <Link
                  to="/login"
                  className="w-full sm:w-auto px-7 py-3.5 rounded-xl font-bold text-sm text-slate-700 bg-white hover:bg-slate-50 border border-slate-200/90 shadow-sm transition active:scale-95 flex items-center justify-center gap-2"
                >
                  <span>Explore Demo Platform</span>
                </Link>
              </>
            )}
          </div>
        </div>

        {/* Live Interactive Fraud Engine Demo Widget */}
        <div className="max-w-4xl mx-auto mt-6 bg-slate-900 rounded-2xl shadow-2xl border border-slate-800 text-white p-6 sm:p-8 relative overflow-hidden">
          <div className="absolute top-0 right-0 w-80 h-80 bg-indigo-500/10 rounded-full blur-2xl pointer-events-none" />

          <div className="flex flex-col md:flex-row items-start md:items-center justify-between gap-4 pb-6 border-b border-slate-800">
            <div>
              <div className="flex items-center gap-2 text-indigo-400 font-mono text-xs uppercase tracking-wider font-semibold">
                <Activity className="w-4 h-4" />
                Live Heuristic Risk Engine Simulator
              </div>
              <h3 className="text-lg font-bold text-white mt-1">
                Real-Time Underwriting & Fraud Risk Gauge
              </h3>
            </div>
            <div className="flex items-center gap-2">
              <span className={`px-3 py-1 rounded-full text-xs font-bold border ${
                simLevel === 'HIGH'
                  ? 'bg-rose-500/20 text-rose-400 border-rose-500/40'
                  : simLevel === 'MEDIUM'
                  ? 'bg-amber-500/20 text-amber-400 border-amber-500/40'
                  : 'bg-emerald-500/20 text-emerald-400 border-emerald-500/40'
              }`}>
                {simLevel} RISK ({simScore}%)
              </span>
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-8 pt-6">
            {/* Controls */}
            <div className="space-y-4">
              <div>
                <div className="flex justify-between text-xs text-slate-300 font-medium mb-1.5">
                  <span>Claim Amount vs Coverage</span>
                  <span className="font-mono text-indigo-300">${simAmount.toLocaleString()} / ${simCoverage.toLocaleString()}</span>
                </div>
                <input
                  type="range"
                  min="2000"
                  max="50000"
                  step="1000"
                  value={simAmount}
                  onChange={(e) => setSimAmount(Number(e.target.value))}
                  className="w-full h-1.5 bg-slate-700 rounded-lg appearance-none cursor-pointer accent-indigo-500"
                />
              </div>

              <div>
                <div className="flex justify-between text-xs text-slate-300 font-medium mb-1.5">
                  <span>Days Since Policy Inception</span>
                  <span className="font-mono text-indigo-300">{simLag} days</span>
                </div>
                <input
                  type="range"
                  min="1"
                  max="180"
                  value={simLag}
                  onChange={(e) => setSimLag(Number(e.target.value))}
                  className="w-full h-1.5 bg-slate-700 rounded-lg appearance-none cursor-pointer accent-indigo-500"
                />
              </div>

              <div className="flex items-center gap-3 pt-2">
                <input
                  type="checkbox"
                  id="hasDocsCheck"
                  checked={simHasDocs}
                  onChange={(e) => setSimHasDocs(e.target.checked)}
                  className="w-4 h-4 rounded text-indigo-600 bg-slate-800 border-slate-700 focus:ring-indigo-500 cursor-pointer"
                />
                <label htmlFor="hasDocsCheck" className="text-xs text-slate-300 cursor-pointer">
                  Supporting invoices / police report attached
                </label>
              </div>
            </div>

            {/* Results Output */}
            <div className="bg-slate-950/70 rounded-xl p-5 border border-slate-800 flex flex-col justify-between">
              <div>
                <span className="text-[11px] font-mono uppercase text-slate-400 block mb-2">
                  Engine Assessment Breakdown:
                </span>
                <ul className="space-y-1.5 text-xs text-slate-300">
                  {ratio >= 0.85 && (
                    <li className="flex items-center gap-2 text-rose-400">
                      <AlertTriangle className="w-3.5 h-3.5 shrink-0" />
                      Coverage exhaustion risk ({Math.round(ratio * 100)}% of limit)
                    </li>
                  )}
                  {simLag <= 30 && (
                    <li className="flex items-center gap-2 text-rose-400">
                      <AlertTriangle className="w-3.5 h-3.5 shrink-0" />
                      Velocity anomaly: Filed within {simLag} days of inception
                    </li>
                  )}
                  {!simHasDocs && (
                    <li className="flex items-center gap-2 text-amber-400">
                      <AlertTriangle className="w-3.5 h-3.5 shrink-0" />
                      Zero supporting documentation attached
                    </li>
                  )}
                  {ratio < 0.85 && simLag > 30 && simHasDocs && (
                    <li className="flex items-center gap-2 text-emerald-400">
                      <CheckCircle2 className="w-3.5 h-3.5 shrink-0" />
                      All initial underwriting heuristics cleared
                    </li>
                  )}
                </ul>
              </div>

              <div className="mt-4 pt-4 border-t border-slate-800 flex items-center justify-between">
                <span className="text-xs text-slate-400">Action:</span>
                <span className={`text-xs font-bold font-mono ${
                  simLevel === 'HIGH' ? 'text-rose-400' : simLevel === 'MEDIUM' ? 'text-amber-400' : 'text-emerald-400'
                }`}>
                  {simLevel === 'HIGH' ? 'ROUTE TO SIU INVESTIGATOR' : (simLevel === 'MEDIUM' ? 'FLAG FOR SUPERVISOR REVIEW' : 'STANDARD STAFF APPROVAL')}
                </span>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Metrics Banner */}
      <section className="bg-slate-900 py-10 border-y border-slate-800 text-white">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="grid grid-cols-2 md:grid-cols-4 gap-6 text-center">
            <div>
              <div className="text-2xl sm:text-3xl font-extrabold text-white tracking-tight">$105,200+</div>
              <div className="text-xs text-slate-400 mt-1">Claims Adjudicated</div>
            </div>
            <div>
              <div className="text-2xl sm:text-3xl font-extrabold text-indigo-400 tracking-tight">100% Deterministic</div>
              <div className="text-xs text-slate-400 mt-1">Explainable AI Scoring</div>
            </div>
            <div>
              <div className="text-2xl sm:text-3xl font-extrabold text-emerald-400 tracking-tight">$15,200</div>
              <div className="text-xs text-slate-400 mt-1">Fraud Losses Prevented</div>
            </div>
            <div>
              <div className="text-2xl sm:text-3xl font-extrabold text-blue-400 tracking-tight">2.8 Days</div>
              <div className="text-xs text-slate-400 mt-1">Average Turnaround</div>
            </div>
          </div>
        </div>
      </section>

      {/* 5-Step Lifecycle Section */}
      <section className="py-20 px-4 sm:px-6 lg:px-8 max-w-7xl mx-auto">
        <div className="text-center max-w-2xl mx-auto mb-16">
          <span className="text-xs font-bold tracking-wider uppercase text-indigo-600 bg-indigo-50 px-3 py-1 rounded-full border border-indigo-200">
            End-to-End Workflow
          </span>
          <h2 className="text-3xl font-extrabold text-slate-950 mt-4 tracking-tight">
            How Claims Move from Intake to Settlement
          </h2>
          <p className="text-sm text-slate-500 mt-2">
            Every step is recorded in an immutable audit log, with role-based validation preventing unauthorized approvals.
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-5 gap-4">
          {[
            {
              step: '01',
              title: 'Claim Submission',
              desc: 'Customer selects active policy, enters incident data, uploads bills & photos. Instant CLM ID generated.',
              icon: FileText
            },
            {
              step: '02',
              title: 'Document Verify',
              desc: 'Claims staff audits invoices, police records, and estimates. Flags items as Verified or Needs Review.',
              icon: FileCheck
            },
            {
              step: '03',
              title: 'Fraud Risk Scan',
              desc: 'Explainable rule engine evaluates coverage exhaustion, filing velocity, frequency, and keyword flags.',
              icon: Shield
            },
            {
              step: '04',
              title: 'SIU Investigation',
              desc: 'High risk claims are routed to Fraud Officers to verify physical evidence and record forensic findings.',
              icon: AlertTriangle
            },
            {
              step: '05',
              title: 'Adjudication',
              desc: 'Authorized staff approves settlement amount or issues denial letter with detailed rationale.',
              icon: CheckCircle2
            }
          ].map((card) => {
            const Icon = card.icon;
            return (
              <div key={card.step} className="bg-white p-6 rounded-2xl border border-slate-200/80 shadow-sm hover:shadow-md transition-all">
                <span className="text-2xl font-black text-indigo-100 font-mono block mb-2">{card.step}</span>
                <div className="w-10 h-10 rounded-xl bg-indigo-50 text-indigo-600 flex items-center justify-center mb-4">
                  <Icon className="w-5 h-5" />
                </div>
                <h3 className="text-sm font-bold text-slate-900 mb-2">{card.title}</h3>
                <p className="text-xs text-slate-500 leading-relaxed">{card.desc}</p>
              </div>
            );
          })}
        </div>
      </section>

      {/* Role-Based Portals */}
      <section className="py-16 bg-slate-100/60 border-t border-slate-200/80">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center max-w-2xl mx-auto mb-12">
            <h2 className="text-2xl sm:text-3xl font-extrabold text-slate-950 tracking-tight">
              Role-Based Enterprise Access
            </h2>
            <p className="text-xs sm:text-sm text-slate-600 mt-2">
              Each stakeholder accesses specialized tooling designed specifically for their operational mandate.
            </p>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-5 gap-4">
            {[
              { role: 'Policyholder', desc: 'Submit claims, track live status timeline, upload receipts.', color: 'border-emerald-200 hover:border-emerald-400' },
              { role: 'Claims Staff', desc: 'Adjudication queue, verify documents, calculate approved payout.', color: 'border-blue-200 hover:border-blue-400' },
              { role: 'Fraud Officer', desc: 'Investigate suspicious claims, inspect indicators, clear or confirm alerts.', color: 'border-purple-200 hover:border-purple-400' },
              { role: 'Manager', desc: 'Executive KPI reporting, approval rate tracking, fraud prevention savings.', color: 'border-amber-200 hover:border-amber-400' },
              { role: 'Administrator', desc: 'User RBAC, system settings, fraud thresholds, immutable audit logs.', color: 'border-rose-200 hover:border-rose-400' }
            ].map((actor) => (
              <div key={actor.role} className={`bg-white p-5 rounded-2xl border shadow-sm transition-all ${actor.color}`}>
                <div className="flex items-center gap-2 mb-2 font-bold text-slate-900 text-sm">
                  <UserCheck className="w-4 h-4 text-indigo-600" />
                  {actor.role}
                </div>
                <p className="text-xs text-slate-500 leading-relaxed mb-4">{actor.desc}</p>
                <Link
                  to="/login"
                  className="text-xs font-semibold text-indigo-600 hover:text-indigo-800 flex items-center gap-1"
                >
                  Sign In <ArrowRight className="w-3.5 h-3.5" />
                </Link>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Call to Action */}
      <section className="py-20 px-4 sm:px-6 lg:px-8 max-w-5xl mx-auto text-center">
        <div className="bg-gradient-to-br from-indigo-900 via-indigo-950 to-slate-950 rounded-3xl p-10 sm:p-14 text-white shadow-2xl relative overflow-hidden">
          <div className="absolute top-0 right-0 w-96 h-96 bg-indigo-500/20 rounded-full blur-3xl pointer-events-none" />
          <h2 className="text-3xl sm:text-4xl font-extrabold tracking-tight">
            Ready to test the live adjudication platform?
          </h2>
          <p className="mt-4 text-sm text-indigo-200 max-w-xl mx-auto leading-relaxed">
            Experience the complete journey: submit a claim as a policyholder, run the fraud analysis, investigate suspicious indicators, and verify documents as staff.
          </p>
          <div className="mt-8 flex flex-wrap items-center justify-center gap-3">
            <Link
              to="/login"
              className="px-6 py-3 rounded-xl font-bold text-sm text-indigo-950 bg-white hover:bg-slate-100 shadow transition active:scale-95"
            >
              Sign In with Demo Accounts
            </Link>
            <Link
              to="/register"
              className="px-6 py-3 rounded-xl font-bold text-sm text-white bg-indigo-600 hover:bg-indigo-700 shadow transition active:scale-95"
            >
              Register New Policyholder
            </Link>
          </div>
        </div>
      </section>
    </div>
  );
};

export default HomePage;
