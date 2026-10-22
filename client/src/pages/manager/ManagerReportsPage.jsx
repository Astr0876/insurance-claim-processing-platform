import React, { useState, useEffect } from 'react';
import { reportService } from '../../services/api';
import {
  BarChart3,
  TrendingUp,
  Download,
  Calendar,
  Filter,
  PieChart as PieChartIcon,
  ShieldAlert,
  FileSpreadsheet,
  CheckCircle2,
  RefreshCw,
  DollarSign,
  Layers
} from 'lucide-react';
import {
  ResponsiveContainer,
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  PieChart,
  Pie,
  Cell,
  LineChart,
  Line
} from 'recharts';
import { StatusBadge, FraudRiskBadge } from '../../components/common/Badge';

const PALETTE = ['#4f46e5', '#06b6d4', '#10b981', '#f59e0b', '#ef4444', '#8b5cf6'];

const ManagerReportsPage = () => {
  const [metrics, setMetrics] = useState(null);
  const [statusData, setStatusData] = useState([]);
  const [typeData, setTypeData] = useState([]);
  const [fraudData, setFraudData] = useState([]);
  const [trendsData, setTrendsData] = useState([]);
  const [exportPreview, setExportPreview] = useState([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isExporting, setIsExporting] = useState(false);
  const [exportSuccess, setExportSuccess] = useState(false);

  const fetchAllReportData = async () => {
    setIsLoading(true);
    try {
      const [sumRes, statRes, typeRes, fraudRes, trendRes, exportRes] = await Promise.all([
        reportService.getSummary(),
        reportService.getStatusDistribution(),
        reportService.getTypeDistribution(),
        reportService.getFraudDistribution(),
        reportService.getTrends(),
        reportService.getExportData()
      ]);

      if (sumRes.data?.success) setMetrics(sumRes.data.metrics);
      if (statRes.data?.success) setStatusData(statRes.data.data || []);
      if (typeRes.data?.success) setTypeData(typeRes.data.data || []);
      if (fraudRes.data?.success) setFraudData(fraudRes.data.data || []);
      if (trendRes.data?.success) setTrendsData(trendRes.data.data || []);
      if (exportRes.data?.success) setExportPreview(exportRes.data.data || []);
    } catch (err) {
      console.error('Failed to load reports:', err);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchAllReportData();
  }, []);

  // Functional CSV Exporter
  const handleDownloadCSV = async () => {
    setIsExporting(true);
    try {
      let data = exportPreview;
      if (!data || data.length === 0) {
        const res = await reportService.getExportData();
        data = res.data?.data || [];
      }

      if (data.length === 0) {
        alert('No data available to export.');
        return;
      }

      // Format CSV Headers
      const headers = [
        'Claim ID',
        'Customer Name',
        'Customer Email',
        'Policy Number',
        'Claim Type',
        'Incident Date',
        'Claim Amount',
        'Status',
        'Verification Status',
        'Fraud Risk Level',
        'Fraud Risk Score',
        'Payout Amount',
        'Decision Reason',
        'Created At'
      ];

      // Convert rows
      const rows = data.map((item) => [
        `"${item.claim_id || ''}"`,
        `"${(item.customer_name || '').replace(/"/g, '""')}"`,
        `"${item.customer_email || ''}"`,
        `"${item.policy_number || ''}"`,
        `"${item.claim_type || ''}"`,
        `"${item.incident_date || ''}"`,
        Number(item.claim_amount || 0).toFixed(2),
        `"${item.current_status || ''}"`,
        `"${item.verification_status || ''}"`,
        `"${item.fraud_risk_level || ''}"`,
        item.fraud_risk_score || 0,
        Number(item.payout_amount || 0).toFixed(2),
        `"${(item.decision_reason || '').replace(/"/g, '""')}"`,
        `"${item.created_at || ''}"`
      ]);

      const csvContent = [headers.join(','), ...rows.map((r) => r.join(','))].join('\r\n');

      // Create download blob
      const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
      const url = URL.createObjectURL(blob);
      const link = document.createElement('a');
      link.setAttribute('href', url);
      link.setAttribute('download', `Insurance_Claims_Report_${new Date().toISOString().slice(0, 10)}.csv`);
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);

      setExportSuccess(true);
      setTimeout(() => setExportSuccess(false), 5000);
    } catch (err) {
      console.error('Export CSV Error:', err);
    } finally {
      setIsExporting(false);
    }
  };

  return (
    <div className="space-y-6">
      {/* Page Title & Actions */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2">
            <span className="p-1.5 rounded-lg bg-indigo-100 text-indigo-700">
              <FileSpreadsheet className="w-5 h-5" />
            </span>
            <h2 className="text-xl sm:text-2xl font-extrabold text-slate-900 tracking-tight">
              Reports, Audit & BI Analytics
            </h2>
          </div>
          <p className="text-xs sm:text-sm text-slate-500 mt-1">
            Aggregated underwriting metrics, fraud exposure distributions, and data exports
          </p>
        </div>

        <div className="flex items-center gap-2">
          <button
            type="button"
            onClick={fetchAllReportData}
            className="p-2 text-slate-600 bg-white border border-slate-300 rounded-xl hover:bg-slate-50 shadow-xs"
            title="Refresh Data"
          >
            <RefreshCw className="w-4 h-4" />
          </button>

          <button
            type="button"
            disabled={isExporting}
            onClick={handleDownloadCSV}
            className="inline-flex items-center gap-2 px-4 py-2 text-xs font-bold text-white bg-slate-900 hover:bg-indigo-600 rounded-xl shadow-xs transition-colors"
          >
            <Download className="w-3.5 h-3.5" />
            {isExporting ? 'Generating CSV...' : 'Export Dataset (.CSV)'}
          </button>
        </div>
      </div>

      {exportSuccess && (
        <div className="p-3.5 rounded-xl bg-emerald-50 border border-emerald-200 text-emerald-800 text-xs flex items-center justify-between shadow-xs">
          <span className="flex items-center gap-2 font-semibold">
            <CheckCircle2 className="w-4 h-4 text-emerald-600" />
            Report successfully exported! Download commenced for {exportPreview.length} claim records.
          </span>
          <button onClick={() => setExportSuccess(false)} className="text-emerald-700 font-bold">×</button>
        </div>
      )}

      {/* KPI Metric Strip */}
      <div className="grid grid-cols-2 lg:grid-cols-6 gap-3">
        <div className="bg-white p-3.5 rounded-xl border border-slate-200 shadow-2xs">
          <span className="text-[10px] font-bold uppercase text-slate-400 block">Total Claims</span>
          <span className="text-xl font-extrabold text-slate-900 mt-1 block">
            {metrics?.totalClaims || 0}
          </span>
        </div>
        <div className="bg-white p-3.5 rounded-xl border border-slate-200 shadow-2xs">
          <span className="text-[10px] font-bold uppercase text-slate-400 block">Total Incurred</span>
          <span className="text-xl font-extrabold text-slate-900 mt-1 block">
            ${Number(metrics?.totalClaimedAmount || 0).toLocaleString()}
          </span>
        </div>
        <div className="bg-white p-3.5 rounded-xl border border-slate-200 shadow-2xs">
          <span className="text-[10px] font-bold uppercase text-emerald-600 block">Total Settled</span>
          <span className="text-xl font-extrabold text-emerald-600 mt-1 block">
            ${Number(metrics?.totalPayoutAmount || 0).toLocaleString()}
          </span>
        </div>
        <div className="bg-white p-3.5 rounded-xl border border-slate-200 shadow-2xs">
          <span className="text-[10px] font-bold uppercase text-rose-600 block">Fraud Shielded</span>
          <span className="text-xl font-extrabold text-rose-600 mt-1 block">
            ${Number(metrics?.fraudSavings || 0).toLocaleString()}
          </span>
        </div>
        <div className="bg-white p-3.5 rounded-xl border border-slate-200 shadow-2xs">
          <span className="text-[10px] font-bold uppercase text-slate-400 block">Approval Ratio</span>
          <span className="text-xl font-extrabold text-indigo-600 mt-1 block">
            {metrics?.approvalRate || 0}%
          </span>
        </div>
        <div className="bg-white p-3.5 rounded-xl border border-slate-200 shadow-2xs">
          <span className="text-[10px] font-bold uppercase text-slate-400 block">Avg Settlement</span>
          <span className="text-xl font-extrabold text-slate-900 mt-1 block">
            {metrics?.averageProcessingDays || 2.8}d
          </span>
        </div>
      </div>

      {/* 2x2 Charts Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">

        {/* Chart 1: Monthly Financial Trend */}
        <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm space-y-3">
          <div className="flex items-center justify-between border-b border-slate-100 pb-2">
            <div>
              <h3 className="text-sm font-extrabold text-slate-900">
                Monthly Intake vs Settlement Payout
              </h3>
              <p className="text-[11px] text-slate-400">Total claim value vs disbursements</p>
            </div>
            <span className="text-xs font-mono font-bold text-slate-400">USD ($)</span>
          </div>
          <div className="h-64 w-full">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={trendsData} margin={{ top: 10, right: 10, left: -15, bottom: 0 }}>
                <CartesianGrid strokeDasharray="3 3" stroke="#f1f5f9" />
                <XAxis dataKey="month" tick={{ fontSize: 11, fill: '#64748b' }} />
                <YAxis tick={{ fontSize: 11, fill: '#64748b' }} />
                <Tooltip
                  contentStyle={{ backgroundColor: '#0f172a', borderRadius: '0.5rem', color: '#fff', fontSize: '11px' }}
                />
                <Legend wrapperStyle={{ fontSize: '11px' }} />
                <Bar dataKey="totalAmount" name="Incurred Claims ($)" fill="#4f46e5" radius={[4, 4, 0, 0]} />
                <Bar dataKey="payoutAmount" name="Settled Payouts ($)" fill="#10b981" radius={[4, 4, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Chart 2: Category Breakdown */}
        <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm space-y-3">
          <div className="flex items-center justify-between border-b border-slate-100 pb-2">
            <div>
              <h3 className="text-sm font-extrabold text-slate-900">
                Claims by Insurance Line
              </h3>
              <p className="text-[11px] text-slate-400">Distribution across Auto, Health, Property, Life</p>
            </div>
            <Layers className="w-4 h-4 text-indigo-500" />
          </div>
          <div className="h-64 w-full">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={typeData} layout="vertical" margin={{ top: 10, right: 20, left: 10, bottom: 0 }}>
                <CartesianGrid strokeDasharray="3 3" stroke="#f1f5f9" />
                <XAxis type="number" tick={{ fontSize: 11, fill: '#64748b' }} />
                <YAxis dataKey="category" type="category" tick={{ fontSize: 11, fill: '#64748b' }} />
                <Tooltip
                  contentStyle={{ backgroundColor: '#0f172a', borderRadius: '0.5rem', color: '#fff', fontSize: '11px' }}
                />
                <Bar dataKey="count" name="Claim Count" fill="#06b6d4" radius={[0, 4, 4, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Chart 3: Fraud Severity Tiering */}
        <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm space-y-3">
          <div className="flex items-center justify-between border-b border-slate-100 pb-2">
            <div>
              <h3 className="text-sm font-extrabold text-slate-900 flex items-center gap-1.5">
                <ShieldAlert className="w-4 h-4 text-rose-500" />
                Fraud Risk Classification Mix
              </h3>
              <p className="text-[11px] text-slate-400">Claims classified by rule engine score</p>
            </div>
          </div>
          <div className="h-64 w-full">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={fraudData} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
                <CartesianGrid strokeDasharray="3 3" stroke="#f1f5f9" />
                <XAxis dataKey="risk_level" tick={{ fontSize: 11, fill: '#64748b' }} />
                <YAxis tick={{ fontSize: 11, fill: '#64748b' }} />
                <Tooltip
                  contentStyle={{ backgroundColor: '#0f172a', borderRadius: '0.5rem', color: '#fff', fontSize: '11px' }}
                />
                <Bar dataKey="count" name="Number of Claims" fill="#f43f5e" radius={[4, 4, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Chart 4: Status Distribution */}
        <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm space-y-3">
          <div className="flex items-center justify-between border-b border-slate-100 pb-2">
            <div>
              <h3 className="text-sm font-extrabold text-slate-900 flex items-center gap-1.5">
                <PieChartIcon className="w-4 h-4 text-indigo-500" />
                Lifecycle Adjudication Distribution
              </h3>
              <p className="text-[11px] text-slate-400">Current status of all submitted claims</p>
            </div>
          </div>
          <div className="h-64 w-full flex items-center justify-center">
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <Pie
                  data={statusData}
                  dataKey="count"
                  nameKey="status"
                  cx="50%"
                  cy="50%"
                  outerRadius={80}
                  label={({ status, count }) => `${status}: ${count}`}
                >
                  {statusData.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={PALETTE[index % PALETTE.length]} />
                  ))}
                </Pie>
                <Tooltip
                  contentStyle={{ backgroundColor: '#0f172a', borderRadius: '0.5rem', color: '#fff', fontSize: '11px' }}
                />
              </PieChart>
            </ResponsiveContainer>
          </div>
        </div>

      </div>

      {/* Export Dataset Preview Table */}
      <div className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
        <div className="p-4 border-b border-slate-100 flex items-center justify-between">
          <div>
            <h3 className="text-sm font-extrabold text-slate-900 flex items-center gap-2">
              <FileSpreadsheet className="w-4 h-4 text-emerald-600" />
              Underwriting Dataset Preview ({exportPreview.length} records)
            </h3>
            <p className="text-[11px] text-slate-400">Exportable table view synchronized with the database</p>
          </div>
          <button
            type="button"
            onClick={handleDownloadCSV}
            className="text-xs font-bold text-indigo-600 hover:text-indigo-800 flex items-center gap-1"
          >
            <Download className="w-3.5 h-3.5" /> Download Full CSV
          </button>
        </div>

        <div className="overflow-x-auto max-h-96">
          <table className="w-full text-left text-xs">
            <thead className="sticky top-0 bg-slate-50 border-b border-slate-200 text-slate-500 uppercase font-bold tracking-wider text-[10px]">
              <tr>
                <th className="py-2.5 px-3">Claim ID</th>
                <th className="py-2.5 px-3">Policyholder</th>
                <th className="py-2.5 px-3">Policy #</th>
                <th className="py-2.5 px-3">Line</th>
                <th className="py-2.5 px-3">Amount</th>
                <th className="py-2.5 px-3">Status</th>
                <th className="py-2.5 px-3">Risk Level</th>
                <th className="py-2.5 px-3">Score</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {exportPreview.map((item) => (
                <tr key={item.claim_id} className="hover:bg-slate-50">
                  <td className="py-2.5 px-3 font-mono font-bold text-slate-900">{item.claim_id}</td>
                  <td className="py-2.5 px-3 text-slate-700">{item.customer_name}</td>
                  <td className="py-2.5 px-3 font-mono text-slate-500">{item.policy_number}</td>
                  <td className="py-2.5 px-3 text-slate-500">{item.claim_type}</td>
                  <td className="py-2.5 px-3 font-bold text-slate-900">
                    ${Number(item.claim_amount).toLocaleString('en-US', { minimumFractionDigits: 2 })}
                  </td>
                  <td className="py-2.5 px-3">
                    <StatusBadge status={item.current_status} />
                  </td>
                  <td className="py-2.5 px-3">
                    <FraudRiskBadge level={item.fraud_risk_level} score={item.fraud_risk_score} />
                  </td>
                  <td className="py-2.5 px-3 font-mono font-bold text-slate-700">{item.fraud_risk_score}%</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};

export default ManagerReportsPage;
