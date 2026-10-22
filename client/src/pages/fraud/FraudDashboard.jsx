import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { fraudService } from '../../services/api';
import {
  ShieldAlert,
  AlertTriangle,
  Search,
  Filter,
  CheckCircle2,
  XCircle,
  Clock,
  ArrowRight,
  Eye,
  FileText,
  TrendingUp,
  Sliders,
  Sparkles
} from 'lucide-react';
import { StatusBadge, FraudRiskBadge } from '../../components/common/Badge';

const FraudDashboard = () => {
  const [queue, setQueue] = useState([]);
  const [isLoading, setIsLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [riskFilter, setRiskFilter] = useState('');
  const [statusFilter, setStatusFilter] = useState('');

  const fetchQueue = async () => {
    setIsLoading(true);
    try {
      const params = {};
      if (search) params.search = search;
      if (riskFilter) params.riskLevel = riskFilter;
      if (statusFilter) params.status = statusFilter;

      const res = await fraudService.getQueue(params);
      if (res.data?.success) {
        setQueue(res.data.queue || []);
      }
    } catch (err) {
      console.error('Failed to load fraud queue:', err);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchQueue();
  }, [riskFilter, statusFilter]);

  const handleSearchSubmit = (e) => {
    e.preventDefault();
    fetchQueue();
  };

  // Compute stats
  const totalFlagged = queue.length;
  const highRiskCount = queue.filter(q => q.fraud_risk_level === 'HIGH').length;
  const underInvestigationCount = queue.filter(q => q.investigation_status === 'UNDER_INVESTIGATION' || q.investigation_status === 'OPEN').length;
  const confirmedFraudCount = queue.filter(q => q.investigation_status === 'CONFIRMED_FRAUD' || q.current_status === 'REJECTED').length;

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2">
            <span className="p-1.5 rounded-lg bg-rose-100 text-rose-700">
              <ShieldAlert className="w-5 h-5" />
            </span>
            <h2 className="text-xl sm:text-2xl font-extrabold text-slate-900 tracking-tight">
              Special Investigation Unit (SIU)
            </h2>
          </div>
          <p className="text-xs sm:text-sm text-slate-500 mt-1">
            Automated anomaly detection & explainable fraud-risk triage workbench
          </p>
        </div>
        <div className="flex items-center gap-2">
          <Link
            to="/manager/reports"
            className="inline-flex items-center gap-2 px-3.5 py-2 text-xs font-semibold text-slate-700 bg-white border border-slate-300 rounded-xl hover:bg-slate-50 shadow-sm transition-all"
          >
            <TrendingUp className="w-3.5 h-3.5 text-indigo-600" />
            Fraud Trend Analytics
          </Link>
        </div>
      </div>

      {/* KPI Stats Row */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <div className="bg-white p-5 rounded-2xl border border-slate-200/80 shadow-sm">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold uppercase tracking-wider text-slate-500">Flagged Cases</span>
            <span className="p-2 rounded-xl bg-slate-100 text-slate-700">
              <AlertTriangle className="w-4 h-4" />
            </span>
          </div>
          <p className="text-2xl font-extrabold text-slate-900 mt-2">{totalFlagged}</p>
          <p className="text-[11px] text-slate-400 mt-0.5">Under surveillance or triage</p>
        </div>

        <div className="bg-white p-5 rounded-2xl border border-rose-200/80 shadow-sm bg-gradient-to-br from-white to-rose-50/30">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold uppercase tracking-wider text-rose-600">High Severity</span>
            <span className="p-2 rounded-xl bg-rose-100 text-rose-700">
              <ShieldAlert className="w-4 h-4" />
            </span>
          </div>
          <p className="text-2xl font-extrabold text-rose-600 mt-2">{highRiskCount}</p>
          <p className="text-[11px] text-rose-500/80 mt-0.5">Risk Score ≥ 70% threshold</p>
        </div>

        <div className="bg-white p-5 rounded-2xl border border-amber-200/80 shadow-sm bg-gradient-to-br from-white to-amber-50/30">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold uppercase tracking-wider text-amber-700">Active Inquiries</span>
            <span className="p-2 rounded-xl bg-amber-100 text-amber-700">
              <Clock className="w-4 h-4" />
            </span>
          </div>
          <p className="text-2xl font-extrabold text-amber-700 mt-2">{underInvestigationCount}</p>
          <p className="text-[11px] text-amber-600/80 mt-0.5">Open forensic reviews</p>
        </div>

        <div className="bg-white p-5 rounded-2xl border border-emerald-200/80 shadow-sm bg-gradient-to-br from-white to-emerald-50/30">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold uppercase tracking-wider text-emerald-700">Confirmed Fraud</span>
            <span className="p-2 rounded-xl bg-emerald-100 text-emerald-700">
              <XCircle className="w-4 h-4" />
            </span>
          </div>
          <p className="text-2xl font-extrabold text-emerald-700 mt-2">{confirmedFraudCount}</p>
          <p className="text-[11px] text-emerald-600/80 mt-0.5">Prevented fraudulent payouts</p>
        </div>
      </div>

      {/* Detection Engine Methodology Banner */}
      <div className="bg-gradient-to-r from-slate-900 via-indigo-950 to-slate-900 rounded-2xl p-4 sm:p-5 text-white shadow-lg border border-indigo-900/50 flex flex-col md:flex-row items-start md:items-center justify-between gap-4">
        <div className="flex items-start gap-3">
          <div className="w-10 h-10 rounded-xl bg-indigo-500/20 border border-indigo-400/30 flex items-center justify-center shrink-0 text-indigo-300">
            <Sparkles className="w-5 h-5" />
          </div>
          <div>
            <h4 className="text-sm font-bold text-white flex items-center gap-2">
              Explainable Rule-Based Fraud Scoring Engine Active
              <span className="text-[10px] font-mono px-2 py-0.5 rounded-full bg-indigo-500/30 text-indigo-200 border border-indigo-400/30">
                Deterministic
              </span>
            </h4>
            <p className="text-xs text-slate-300 mt-0.5 max-w-2xl leading-relaxed">
              Every submitted claim is dynamically audited against 7 verifiable fraud vectors: Policy Coverage Ratio (&gt;80%), Inception Velocity (&lt;30 days), Historical Claim Frequency (&gt;2/yr), Reporting Lag (&gt;45 days), Prior Fraud History, Keyword Red Flags, and Missing Proof of Loss.
            </p>
          </div>
        </div>
        <div className="flex items-center gap-2 self-end md:self-center shrink-0 text-xs font-mono text-indigo-300 bg-white/5 px-3 py-1.5 rounded-lg border border-white/10">
          Threshold: 70% Flag Rate
        </div>
      </div>

      {/* Filters & Search */}
      <div className="bg-white p-4 rounded-2xl border border-slate-200 shadow-sm flex flex-col md:flex-row items-center justify-between gap-3">
        <form onSubmit={handleSearchSubmit} className="w-full md:w-80 relative">
          <Search className="w-4 h-4 text-slate-400 absolute left-3 top-3 pointer-events-none" />
          <input
            type="text"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Search by Claim ID or Policyholder..."
            className="w-full pl-9 pr-4 py-2 text-xs bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-500"
          />
        </form>

        <div className="w-full md:w-auto flex flex-wrap items-center gap-2">
          <div className="flex items-center gap-1.5 bg-slate-50 border border-slate-200 rounded-xl p-1 text-xs">
            <span className="text-[11px] font-bold text-slate-400 px-2 flex items-center gap-1">
              <Filter className="w-3 h-3" /> Risk:
            </span>
            <button
              type="button"
              onClick={() => setRiskFilter('')}
              className={`px-2.5 py-1 rounded-lg text-xs font-semibold transition-all ${
                riskFilter === '' ? 'bg-white text-slate-800 shadow-xs' : 'text-slate-500 hover:text-slate-900'
              }`}
            >
              All
            </button>
            <button
              type="button"
              onClick={() => setRiskFilter('HIGH')}
              className={`px-2.5 py-1 rounded-lg text-xs font-semibold transition-all ${
                riskFilter === 'HIGH' ? 'bg-rose-600 text-white shadow-xs' : 'text-slate-500 hover:text-rose-600'
              }`}
            >
              High Risk (≥70%)
            </button>
            <button
              type="button"
              onClick={() => setRiskFilter('MEDIUM')}
              className={`px-2.5 py-1 rounded-lg text-xs font-semibold transition-all ${
                riskFilter === 'MEDIUM' ? 'bg-amber-600 text-white shadow-xs' : 'text-slate-500 hover:text-amber-600'
              }`}
            >
              Medium Risk
            </button>
          </div>

          <select
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
            className="px-3 py-2 text-xs bg-slate-50 border border-slate-200 rounded-xl font-medium text-slate-700 focus:outline-none focus:border-indigo-500"
          >
            <option value="">All SIU Statuses</option>
            <option value="OPEN">Open Alert</option>
            <option value="UNDER_INVESTIGATION">Under Investigation</option>
            <option value="CONFIRMED_FRAUD">Confirmed Fraud</option>
            <option value="CLEARED">Cleared</option>
          </select>
        </div>
      </div>

      {/* Flagged Claims Table */}
      <div className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs">
            <thead>
              <tr className="bg-slate-50/80 border-b border-slate-200/80 text-slate-500 uppercase font-bold tracking-wider text-[10px]">
                <th className="py-3 px-4">Claim ID</th>
                <th className="py-3 px-4">Policyholder</th>
                <th className="py-3 px-4">Type & Amount</th>
                <th className="py-3 px-4">Risk Severity</th>
                <th className="py-3 px-4">Risk Meter</th>
                <th className="py-3 px-4">SIU Status</th>
                <th className="py-3 px-4 text-right">Investigation</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {isLoading ? (
                <tr>
                  <td colSpan={7} className="py-12 text-center text-slate-400">
                    <div className="flex flex-col items-center justify-center gap-2">
                      <div className="w-6 h-6 border-2 border-indigo-600 border-t-transparent rounded-full animate-spin" />
                      <span>Scanning flagged claims portfolio...</span>
                    </div>
                  </td>
                </tr>
              ) : queue.length === 0 ? (
                <tr>
                  <td colSpan={7} className="py-12 text-center text-slate-400">
                    <CheckCircle2 className="w-8 h-8 text-emerald-500 mx-auto mb-2 opacity-80" />
                    <p className="font-semibold text-slate-700">No Flagged Suspicious Claims</p>
                    <p className="text-xs text-slate-400 mt-0.5">
                      No claims currently match the selected risk criteria or filters.
                    </p>
                  </td>
                </tr>
              ) : (
                queue.map((item) => {
                  const score = item.fraud_risk_score || 0;
                  const isHigh = score >= 70;
                  const claimDbId = item.claim_db_id || item.id;

                  return (
                    <tr
                      key={item.claim_id}
                      className={`hover:bg-slate-50/80 transition-colors ${
                        isHigh ? 'bg-rose-50/20' : ''
                      }`}
                    >
                      <td className="py-3.5 px-4">
                        <span className="font-mono font-bold text-slate-900 block">
                          {item.claim_id}
                        </span>
                        <span className="text-[11px] text-slate-400">
                          Pol: {item.policy_number}
                        </span>
                      </td>

                      <td className="py-3.5 px-4">
                        <span className="font-semibold text-slate-800 block">
                          {item.customer_name}
                        </span>
                        <span className="text-[11px] text-slate-400 truncate max-w-[140px] block">
                          {item.customer_email}
                        </span>
                      </td>

                      <td className="py-3.5 px-4">
                        <span className="font-bold text-slate-900 block">
                          ${Number(item.claim_amount).toLocaleString('en-US', { minimumFractionDigits: 2 })}
                        </span>
                        <span className="text-[11px] text-slate-500">
                          {item.claim_type}
                        </span>
                      </td>

                      <td className="py-3.5 px-4">
                        <FraudRiskBadge level={item.fraud_risk_level} score={score} />
                      </td>

                      <td className="py-3.5 px-4 min-w-[140px]">
                        <div className="flex items-center gap-2">
                          <div className="w-20 bg-slate-100 rounded-full h-2 overflow-hidden border border-slate-200/60">
                            <div
                              className={`h-full rounded-full transition-all duration-500 ${
                                score >= 70
                                  ? 'bg-rose-600'
                                  : score >= 35
                                  ? 'bg-amber-500'
                                  : 'bg-emerald-500'
                              }`}
                              style={{ width: `${Math.min(100, Math.max(5, score))}%` }}
                            />
                          </div>
                          <span className="font-mono font-bold text-[11px] text-slate-700">
                            {score}%
                          </span>
                        </div>
                      </td>

                      <td className="py-3.5 px-4">
                        <span
                          className={`inline-flex items-center gap-1 px-2 py-0.5 rounded-md text-[11px] font-bold ${
                            item.investigation_status === 'CONFIRMED_FRAUD'
                              ? 'bg-rose-100 text-rose-800'
                              : item.investigation_status === 'CLEARED'
                              ? 'bg-emerald-100 text-emerald-800'
                              : item.investigation_status === 'UNDER_INVESTIGATION'
                              ? 'bg-purple-100 text-purple-800'
                              : 'bg-amber-100 text-amber-800'
                          }`}
                        >
                          {item.investigation_status || 'OPEN_ALERT'}
                        </span>
                      </td>

                      <td className="py-3.5 px-4 text-right">
                        <Link
                          to={`/fraud/investigate/${claimDbId}`}
                          className="inline-flex items-center gap-1.5 px-3 py-1.5 text-xs font-bold text-white bg-slate-900 hover:bg-indigo-600 rounded-xl shadow-xs transition-all"
                        >
                          <span>Case Room</span>
                          <ArrowRight className="w-3 h-3" />
                        </Link>
                      </td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};

export default FraudDashboard;
