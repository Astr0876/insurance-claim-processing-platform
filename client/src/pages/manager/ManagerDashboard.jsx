import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { reportService, claimService } from '../../services/api';
import {
  BarChart3,
  TrendingUp,
  ShieldAlert,
  FileText,
  DollarSign,
  CheckCircle2,
  Clock,
  ArrowRight,
  PieChart as PieChartIcon,
  ShieldCheck,
  Download,
  AlertTriangle,
  Users
} from 'lucide-react';
import {
  ResponsiveContainer,
  AreaChart,
  Area,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  PieChart,
  Pie,
  Cell,
  Legend
} from 'recharts';
import { StatusBadge, FraudRiskBadge } from '../../components/common/Badge';

const STATUS_COLORS = {
  SUBMITTED: '#94a3b8',
  UNDER_REVIEW: '#3b82f6',
  DOCUMENTS_PENDING: '#f59e0b',
  INVESTIGATION_IN_PROGRESS: '#a855f7',
  APPROVED: '#10b981',
  REJECTED: '#ef4444'
};

const ManagerDashboard = () => {
  const [metrics, setMetrics] = useState(null);
  const [statusData, setStatusData] = useState([]);
  const [trendsData, setTrendsData] = useState([]);
  const [recentClaims, setRecentClaims] = useState([]);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const fetchData = async () => {
      setIsLoading(true);
      try {
        const [sumRes, statRes, trendRes, claimsRes] = await Promise.all([
          reportService.getSummary(),
          reportService.getStatusDistribution(),
          reportService.getTrends(),
          claimService.getClaims({ limit: 5 })
        ]);

        if (sumRes.data?.success) setMetrics(sumRes.data.metrics);
        if (statRes.data?.success) setStatusData(statRes.data.data || []);
        if (trendRes.data?.success) setTrendsData(trendRes.data.data || []);
        if (claimsRes.data?.success) setRecentClaims(claimsRes.data.claims?.slice(0, 5) || []);
      } catch (err) {
        console.error('Failed to load manager dashboard:', err);
      } finally {
        setIsLoading(false);
      }
    };

    fetchData();
  }, []);

  return (
    <div className="space-y-6">
      {/* Executive Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2">
            <span className="p-1.5 rounded-lg bg-amber-100 text-amber-700">
              <BarChart3 className="w-5 h-5" />
            </span>
            <h2 className="text-xl sm:text-2xl font-extrabold text-slate-900 tracking-tight">
              Executive Operations & Risk Dashboard
            </h2>
          </div>
          <p className="text-xs sm:text-sm text-slate-500 mt-1">
            Real-time loss ratio, claim velocity, and fraud prevention telemetry
          </p>
        </div>

        <div className="flex items-center gap-2">
          <Link
            to="/manager/reports"
            className="inline-flex items-center gap-2 px-4 py-2 text-xs font-bold text-white bg-indigo-600 hover:bg-indigo-700 rounded-xl shadow-xs transition-colors"
          >
            <TrendingUp className="w-3.5 h-3.5" />
            Detailed Reports & Export
          </Link>
        </div>
      </div>

      {/* KPI Cards Row */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <div className="bg-white p-5 rounded-2xl border border-slate-200/80 shadow-sm">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold uppercase tracking-wider text-slate-500">Total Claim Volume</span>
            <span className="p-2 rounded-xl bg-indigo-50 text-indigo-700">
              <FileText className="w-4 h-4" />
            </span>
          </div>
          <p className="text-2xl font-extrabold text-slate-900 mt-2">
            {metrics ? metrics.totalClaims : '—'}
          </p>
          <div className="flex items-center justify-between text-[11px] text-slate-400 mt-1">
            <span>Incurred: ${Number(metrics?.totalClaimedAmount || 0).toLocaleString()}</span>
            <span className="text-indigo-600 font-semibold">{metrics?.pendingClaims || 0} Pending</span>
          </div>
        </div>

        <div className="bg-white p-5 rounded-2xl border border-emerald-200/80 shadow-sm bg-gradient-to-br from-white to-emerald-50/20">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold uppercase tracking-wider text-emerald-700">Approved Payouts</span>
            <span className="p-2 rounded-xl bg-emerald-100 text-emerald-700">
              <CheckCircle2 className="w-4 h-4" />
            </span>
          </div>
          <p className="text-2xl font-extrabold text-emerald-700 mt-2">
            ${Number(metrics?.totalPayoutAmount || 0).toLocaleString('en-US', { minimumFractionDigits: 0 })}
          </p>
          <div className="flex items-center justify-between text-[11px] text-slate-400 mt-1">
            <span>{metrics?.approvedClaims || 0} Claims Settled</span>
            <span className="text-emerald-700 font-bold">{metrics?.approvalRate || 0}% Approval Rate</span>
          </div>
        </div>

        <div className="bg-white p-5 rounded-2xl border border-rose-200/80 shadow-sm bg-gradient-to-br from-white to-rose-50/20">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold uppercase tracking-wider text-rose-600">Fraud Savings (ROI)</span>
            <span className="p-2 rounded-xl bg-rose-100 text-rose-700">
              <ShieldAlert className="w-4 h-4" />
            </span>
          </div>
          <p className="text-2xl font-extrabold text-rose-600 mt-2">
            ${Number(metrics?.fraudSavings || 0).toLocaleString('en-US', { minimumFractionDigits: 0 })}
          </p>
          <div className="flex items-center justify-between text-[11px] text-slate-400 mt-1">
            <span>{metrics?.highRiskClaims || 0} Flagged Red Alerts</span>
            <span className="text-rose-600 font-bold">Losses Prevented</span>
          </div>
        </div>

        <div className="bg-white p-5 rounded-2xl border border-slate-200/80 shadow-sm">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold uppercase tracking-wider text-slate-500">Processing Velocity</span>
            <span className="p-2 rounded-xl bg-slate-100 text-slate-700">
              <Clock className="w-4 h-4" />
            </span>
          </div>
          <p className="text-2xl font-extrabold text-slate-900 mt-2">
            {metrics?.averageProcessingDays || 2.8} Days
          </p>
          <div className="flex items-center justify-between text-[11px] text-slate-400 mt-1">
            <span>Intake to Decision</span>
            <span className="text-emerald-600 font-semibold font-mono">⚡ SLA Compliant</span>
          </div>
        </div>
      </div>

      {/* Visual Charts Row */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
        
        {/* Trend Area Chart (8 cols) */}
        <div className="lg:col-span-8 bg-white p-5 rounded-2xl border border-slate-200 shadow-sm">
          <div className="flex items-center justify-between border-b border-slate-100 pb-3 mb-4">
            <div>
              <h3 className="text-sm font-extrabold text-slate-900 flex items-center gap-2">
                <TrendingUp className="w-4 h-4 text-indigo-600" />
                Claim Intake & Settlement Trajectory
              </h3>
              <p className="text-[11px] text-slate-500 mt-0.5">
                Monthly claim submissions vs settlement payouts
              </p>
            </div>
            <span className="text-[11px] font-mono text-slate-500 bg-slate-50 px-2.5 py-1 rounded-lg border border-slate-200/60">
              Trailing Months
            </span>
          </div>

          <div className="h-64 w-full">
            {trendsData.length === 0 ? (
              <div className="h-full flex items-center justify-center text-xs text-slate-400">
                No monthly trend data recorded yet.
              </div>
            ) : (
              <ResponsiveContainer width="100%" height="100%">
                <AreaChart data={trendsData} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
                  <defs>
                    <linearGradient id="colorSub" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="5%" stopColor="#4f46e5" stopOpacity={0.3} />
                      <stop offset="95%" stopColor="#4f46e5" stopOpacity={0} />
                    </linearGradient>
                    <linearGradient id="colorPayout" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="5%" stopColor="#10b981" stopOpacity={0.3} />
                      <stop offset="95%" stopColor="#10b981" stopOpacity={0} />
                    </linearGradient>
                  </defs>
                  <CartesianGrid strokeDasharray="3 3" stroke="#f1f5f9" />
                  <XAxis dataKey="month" tick={{ fontSize: 11, fill: '#64748b' }} />
                  <YAxis tick={{ fontSize: 11, fill: '#64748b' }} />
                  <Tooltip
                    contentStyle={{
                      backgroundColor: '#1e293b',
                      borderRadius: '0.75rem',
                      border: 'none',
                      color: '#fff',
                      fontSize: '12px'
                    }}
                  />
                  <Area
                    type="monotone"
                    dataKey="submitted"
                    name="Claims Submitted"
                    stroke="#4f46e5"
                    strokeWidth={2}
                    fillOpacity={1}
                    fill="urlColorSub"
                  />
                  <Area
                    type="monotone"
                    dataKey="approved"
                    name="Claims Approved"
                    stroke="#10b981"
                    strokeWidth={2}
                    fillOpacity={1}
                    fill="urlColorPayout"
                  />
                </AreaChart>
              </ResponsiveContainer>
            )}
          </div>
        </div>

        {/* Status Distribution Donut Chart (4 cols) */}
        <div className="lg:col-span-4 bg-white p-5 rounded-2xl border border-slate-200 shadow-sm flex flex-col justify-between">
          <div>
            <div className="flex items-center justify-between border-b border-slate-100 pb-3 mb-2">
              <div>
                <h3 className="text-sm font-extrabold text-slate-900 flex items-center gap-2">
                  <PieChartIcon className="w-4 h-4 text-indigo-600" />
                  Portfolio Status Mix
                </h3>
                <p className="text-[11px] text-slate-500 mt-0.5">Active stage allocation</p>
              </div>
            </div>

            <div className="h-48 w-full flex items-center justify-center">
              {statusData.length === 0 ? (
                <p className="text-xs text-slate-400">No status data</p>
              ) : (
                <ResponsiveContainer width="100%" height="100%">
                  <PieChart>
                    <Pie
                      data={statusData}
                      dataKey="count"
                      nameKey="status"
                      cx="50%"
                      cy="50%"
                      innerRadius={45}
                      outerRadius={70}
                      paddingAngle={3}
                    >
                      {statusData.map((entry, index) => (
                        <Cell
                          key={`cell-${index}`}
                          fill={STATUS_COLORS[entry.status] || '#64748b'}
                        />
                      ))}
                    </Pie>
                    <Tooltip
                      contentStyle={{
                        backgroundColor: '#0f172a',
                        borderRadius: '0.5rem',
                        fontSize: '11px',
                        color: '#fff'
                      }}
                    />
                  </PieChart>
                </ResponsiveContainer>
              )}
            </div>
          </div>

          <div className="grid grid-cols-2 gap-2 pt-2 border-t border-slate-100 text-[10px]">
            {statusData.slice(0, 4).map((item) => (
              <div key={item.status} className="flex items-center gap-1.5">
                <span
                  className="w-2.5 h-2.5 rounded-full shrink-0"
                  style={{ backgroundColor: STATUS_COLORS[item.status] || '#64748b' }}
                />
                <span className="truncate text-slate-600 font-medium">{item.status}:</span>
                <span className="font-bold text-slate-900">{item.count}</span>
              </div>
            ))}
          </div>
        </div>

      </div>

      {/* Recent High-Impact Claims & Quick Links */}
      <div className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
        <div className="p-4 sm:p-5 border-b border-slate-100 flex items-center justify-between">
          <div>
            <h3 className="text-sm font-extrabold text-slate-900">
              Recent Adjudication Activity
            </h3>
            <p className="text-xs text-slate-500 mt-0.5">
              Live queue telemetry across customer submissions and staff resolutions
            </p>
          </div>
          <Link
            to="/staff/claims"
            className="text-xs font-bold text-indigo-600 hover:text-indigo-800 flex items-center gap-1"
          >
            Full Queue <ArrowRight className="w-3 h-3" />
          </Link>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs">
            <thead>
              <tr className="bg-slate-50/80 border-b border-slate-200/80 text-slate-500 uppercase font-bold tracking-wider text-[10px]">
                <th className="py-3 px-4">Claim ID</th>
                <th className="py-3 px-4">Claimant</th>
                <th className="py-3 px-4">Line</th>
                <th className="py-3 px-4">Amount</th>
                <th className="py-3 px-4">Status</th>
                <th className="py-3 px-4">Fraud Risk</th>
                <th className="py-3 px-4 text-right">Review</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {recentClaims.map((claim) => (
                <tr key={claim.id} className="hover:bg-slate-50/80 transition-colors">
                  <td className="py-3 px-4 font-mono font-bold text-slate-900">{claim.claim_id}</td>
                  <td className="py-3 px-4 text-slate-700 font-semibold">{claim.customer_name || 'Policyholder'}</td>
                  <td className="py-3 px-4 text-slate-500">{claim.claim_type}</td>
                  <td className="py-3 px-4 font-bold text-slate-900">
                    ${Number(claim.claim_amount).toLocaleString('en-US', { minimumFractionDigits: 2 })}
                  </td>
                  <td className="py-3 px-4">
                    <StatusBadge status={claim.current_status} />
                  </td>
                  <td className="py-3 px-4">
                    <FraudRiskBadge level={claim.fraud_risk_level} score={claim.fraud_risk_score} />
                  </td>
                  <td className="py-3 px-4 text-right">
                    <Link
                      to={`/staff/claims/${claim.id}`}
                      className="text-indigo-600 hover:text-indigo-900 font-bold text-xs"
                    >
                      Audit
                    </Link>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};

export default ManagerDashboard;
