import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { userService, auditService, reportService } from '../../services/api';
import {
  Shield,
  Users,
  ScrollText,
  Settings,
  FileText,
  AlertTriangle,
  BarChart3,
  CheckCircle2,
  Lock,
  Server,
  ArrowRight,
  Database,
  Cpu,
  Sparkles
} from 'lucide-react';

const AdminDashboard = () => {
  const [metrics, setMetrics] = useState(null);
  const [userCount, setUserCount] = useState(0);
  const [recentLogs, setRecentLogs] = useState([]);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const fetchData = async () => {
      setIsLoading(true);
      try {
        const [sumRes, userRes, logsRes] = await Promise.all([
          reportService.getSummary(),
          userService.getUsers({ limit: 1 }),
          auditService.getLogs({ limit: 6 })
        ]);

        if (sumRes.data?.success) setMetrics(sumRes.data.metrics);
        if (userRes.data?.success) setUserCount(userRes.data.count || 0);
        if (logsRes.data?.success) setRecentLogs(logsRes.data.logs || []);
      } catch (err) {
        console.error('Failed to load admin dashboard:', err);
      } finally {
        setIsLoading(false);
      }
    };

    fetchData();
  }, []);

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2">
            <span className="p-1.5 rounded-lg bg-rose-100 text-rose-700">
              <Shield className="w-5 h-5" />
            </span>
            <h2 className="text-xl sm:text-2xl font-extrabold text-slate-900 tracking-tight">
              System Administration Hub
            </h2>
          </div>
          <p className="text-xs sm:text-sm text-slate-500 mt-1">
            RBAC security management, immutable audit trails, and platform configurations
          </p>
        </div>

        <div className="flex items-center gap-2">
          <Link
            to="/admin/users"
            className="inline-flex items-center gap-2 px-3.5 py-2 text-xs font-bold text-white bg-indigo-600 hover:bg-indigo-700 rounded-xl shadow-xs transition-colors"
          >
            <Users className="w-3.5 h-3.5" />
            Manage Users
          </Link>
          <Link
            to="/admin/settings"
            className="inline-flex items-center gap-2 px-3.5 py-2 text-xs font-semibold text-slate-700 bg-white border border-slate-300 hover:bg-slate-50 rounded-xl shadow-xs transition-colors"
          >
            <Settings className="w-3.5 h-3.5 text-slate-500" />
            Settings
          </Link>
        </div>
      </div>

      {/* System Telemetry Row */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <div className="bg-white p-5 rounded-2xl border border-slate-200/80 shadow-sm">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold uppercase tracking-wider text-slate-500">Registered Accounts</span>
            <span className="p-2 rounded-xl bg-indigo-50 text-indigo-700">
              <Users className="w-4 h-4" />
            </span>
          </div>
          <p className="text-2xl font-extrabold text-slate-900 mt-2">{userCount}</p>
          <p className="text-[11px] text-slate-400 mt-0.5">Across 5 system roles</p>
        </div>

        <div className="bg-white p-5 rounded-2xl border border-slate-200/80 shadow-sm">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold uppercase tracking-wider text-slate-500">Total Claims Processed</span>
            <span className="p-2 rounded-xl bg-blue-50 text-blue-700">
              <FileText className="w-4 h-4" />
            </span>
          </div>
          <p className="text-2xl font-extrabold text-slate-900 mt-2">{metrics?.totalClaims || 0}</p>
          <p className="text-[11px] text-slate-400 mt-0.5">
            ${Number(metrics?.totalClaimedAmount || 0).toLocaleString()} aggregate value
          </p>
        </div>

        <div className="bg-white p-5 rounded-2xl border border-purple-200/80 shadow-sm bg-gradient-to-br from-white to-purple-50/20">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold uppercase tracking-wider text-purple-700">Fraud Engine Status</span>
            <span className="p-2 rounded-xl bg-purple-100 text-purple-700">
              <Cpu className="w-4 h-4" />
            </span>
          </div>
          <p className="text-lg font-black text-purple-900 mt-2 flex items-center gap-1.5">
            <span className="w-2.5 h-2.5 rounded-full bg-emerald-500 animate-pulse" />
            Operational
          </p>
          <p className="text-[11px] text-purple-600/80 mt-0.5">7 Deterministic Rules Active</p>
        </div>

        <div className="bg-white p-5 rounded-2xl border border-slate-200/80 shadow-sm">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold uppercase tracking-wider text-slate-500">Database Adapter</span>
            <span className="p-2 rounded-xl bg-slate-100 text-slate-700">
              <Database className="w-4 h-4" />
            </span>
          </div>
          <p className="text-lg font-black text-slate-900 mt-2 flex items-center gap-1.5">
            <span className="w-2.5 h-2.5 rounded-full bg-emerald-500" />
            Connected
          </p>
          <p className="text-[11px] text-slate-400 mt-0.5">Dual MySQL / SQLite Storage</p>
        </div>
      </div>

      {/* Admin Modules Navigation Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <Link
          to="/admin/users"
          className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm hover:border-indigo-300 hover:shadow-md transition-all group"
        >
          <div className="flex items-center gap-3">
            <div className="p-3 rounded-xl bg-indigo-50 text-indigo-600 group-hover:bg-indigo-600 group-hover:text-white transition-colors">
              <Users className="w-5 h-5" />
            </div>
            <div>
              <h4 className="text-sm font-extrabold text-slate-900 group-hover:text-indigo-600 transition-colors">
                User & Role Management
              </h4>
              <p className="text-xs text-slate-500 mt-0.5">
                Assign RBAC roles, provision staff, and toggle account states
              </p>
            </div>
          </div>
          <div className="mt-4 pt-3 border-t border-slate-100 flex items-center justify-between text-xs font-bold text-indigo-600">
            <span>Open User Directory</span>
            <ArrowRight className="w-3.5 h-3.5 group-hover:translate-x-1 transition-transform" />
          </div>
        </Link>

        <Link
          to="/admin/audit-logs"
          className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm hover:border-indigo-300 hover:shadow-md transition-all group"
        >
          <div className="flex items-center gap-3">
            <div className="p-3 rounded-xl bg-slate-100 text-slate-700 group-hover:bg-slate-900 group-hover:text-white transition-colors">
              <ScrollText className="w-5 h-5" />
            </div>
            <div>
              <h4 className="text-sm font-extrabold text-slate-900 group-hover:text-indigo-600 transition-colors">
                Forensic Audit Logs
              </h4>
              <p className="text-xs text-slate-500 mt-0.5">
                Inspect tamper-proof action traces and JSON state mutations
              </p>
            </div>
          </div>
          <div className="mt-4 pt-3 border-t border-slate-100 flex items-center justify-between text-xs font-bold text-indigo-600">
            <span>View Security Logs</span>
            <ArrowRight className="w-3.5 h-3.5 group-hover:translate-x-1 transition-transform" />
          </div>
        </Link>

        <Link
          to="/admin/settings"
          className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm hover:border-indigo-300 hover:shadow-md transition-all group"
        >
          <div className="flex items-center gap-3">
            <div className="p-3 rounded-xl bg-amber-50 text-amber-700 group-hover:bg-amber-600 group-hover:text-white transition-colors">
              <Settings className="w-5 h-5" />
            </div>
            <div>
              <h4 className="text-sm font-extrabold text-slate-900 group-hover:text-indigo-600 transition-colors">
                System Configurations
              </h4>
              <p className="text-xs text-slate-500 mt-0.5">
                Configure fraud risk cutoffs, auto-flagging, and file policies
              </p>
            </div>
          </div>
          <div className="mt-4 pt-3 border-t border-slate-100 flex items-center justify-between text-xs font-bold text-indigo-600">
            <span>Configure Engine</span>
            <ArrowRight className="w-3.5 h-3.5 group-hover:translate-x-1 transition-transform" />
          </div>
        </Link>
      </div>

      {/* Recent Audit Trail Stream */}
      <div className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
        <div className="p-4 sm:p-5 border-b border-slate-100 flex items-center justify-between">
          <div>
            <h3 className="text-sm font-extrabold text-slate-900 flex items-center gap-2">
              <ScrollText className="w-4 h-4 text-slate-500" />
              Live Security & Adjudication Audit Trail
            </h3>
            <p className="text-xs text-slate-500 mt-0.5">
              Latest transactions recorded with actor ID, timestamp, and IP reference
            </p>
          </div>
          <Link
            to="/admin/audit-logs"
            className="text-xs font-bold text-indigo-600 hover:text-indigo-800 flex items-center gap-1"
          >
            All Logs <ArrowRight className="w-3 h-3" />
          </Link>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs">
            <thead>
              <tr className="bg-slate-50/80 border-b border-slate-200/80 text-slate-500 uppercase font-bold tracking-wider text-[10px]">
                <th className="py-3 px-4">Timestamp</th>
                <th className="py-3 px-4">Actor</th>
                <th className="py-3 px-4">Role</th>
                <th className="py-3 px-4">Action</th>
                <th className="py-3 px-4">Entity</th>
                <th className="py-3 px-4">IP Address</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {isLoading ? (
                <tr>
                  <td colSpan={6} className="py-8 text-center text-slate-400">
                    Loading security audit logs...
                  </td>
                </tr>
              ) : recentLogs.length === 0 ? (
                <tr>
                  <td colSpan={6} className="py-8 text-center text-slate-400">
                    No audit logs recorded yet.
                  </td>
                </tr>
              ) : (
                recentLogs.map((log) => (
                  <tr key={log.id} className="hover:bg-slate-50/80 transition-colors">
                    <td className="py-3 px-4 font-mono text-slate-500 text-[11px]">
                      {new Date(log.created_at).toLocaleTimeString()} {new Date(log.created_at).toLocaleDateString()}
                    </td>
                    <td className="py-3 px-4 font-semibold text-slate-800">
                      {log.user_name || 'System Worker'}
                    </td>
                    <td className="py-3 px-4">
                      <span className="font-mono text-[10px] font-bold px-2 py-0.5 rounded bg-slate-100 text-slate-700">
                        {log.user_role || 'SYSTEM'}
                      </span>
                    </td>
                    <td className="py-3 px-4">
                      <span className="font-mono font-bold text-indigo-700 bg-indigo-50 px-2 py-0.5 rounded border border-indigo-100 text-[11px]">
                        {log.action}
                      </span>
                    </td>
                    <td className="py-3 px-4 font-mono text-slate-600 text-[11px]">
                      {log.entity_type} {log.entity_id ? `#${log.entity_id}` : ''}
                    </td>
                    <td className="py-3 px-4 font-mono text-slate-400 text-[11px]">
                      {log.ip_address || '127.0.0.1'}
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};

export default AdminDashboard;
