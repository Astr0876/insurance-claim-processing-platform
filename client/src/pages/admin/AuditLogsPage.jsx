import React, { useState, useEffect } from 'react';
import { auditService } from '../../services/api';
import {
  ScrollText,
  Search,
  Filter,
  Eye,
  Calendar,
  User,
  Shield,
  Layers,
  Clock,
  Terminal,
  RefreshCw,
  Code
} from 'lucide-react';
import Modal from '../../components/common/Modal';

const ACTION_COLORS = {
  CLAIM_CREATED: 'bg-blue-100 text-blue-800 border-blue-200',
  STATUS_CHANGE_APPROVED: 'bg-emerald-100 text-emerald-800 border-emerald-200',
  STATUS_CHANGE_REJECTED: 'bg-rose-100 text-rose-800 border-rose-200',
  DOCUMENT_VERIFIED: 'bg-emerald-100 text-emerald-800 border-emerald-200',
  DOCUMENT_REJECTED: 'bg-rose-100 text-rose-800 border-rose-200',
  FRAUD_INVESTIGATION_CONFIRMED_FRAUD: 'bg-rose-100 text-rose-800 border-rose-200',
  FRAUD_INVESTIGATION_CLEARED: 'bg-emerald-100 text-emerald-800 border-emerald-200',
  FRAUD_INVESTIGATION_UNDER_INVESTIGATION: 'bg-purple-100 text-purple-800 border-purple-200',
  USER_ROLE_CHANGED: 'bg-amber-100 text-amber-800 border-amber-200',
  SYSTEM_SETTING_CHANGED: 'bg-indigo-100 text-indigo-800 border-indigo-200'
};

const AuditLogsPage = () => {
  const [logs, setLogs] = useState([]);
  const [total, setTotal] = useState(0);
  const [isLoading, setIsLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [actionFilter, setActionFilter] = useState('');
  const [entityFilter, setEntityFilter] = useState('');
  const [selectedLog, setSelectedLog] = useState(null);

  const fetchLogs = async () => {
    setIsLoading(true);
    try {
      const params = { limit: 100 };
      if (search) params.search = search;
      if (actionFilter) params.action = actionFilter;
      if (entityFilter) params.entityType = entityFilter;

      const res = await auditService.getLogs(params);
      if (res.data?.success) {
        setLogs(res.data.logs || []);
        setTotal(res.data.total || res.data.count || 0);
      }
    } catch (err) {
      console.error('Failed to load audit trail:', err);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchLogs();
  }, [actionFilter, entityFilter]);

  const handleSearchSubmit = (e) => {
    e.preventDefault();
    fetchLogs();
  };

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2">
            <span className="p-1.5 rounded-lg bg-slate-900 text-white">
              <ScrollText className="w-5 h-5" />
            </span>
            <h2 className="text-xl sm:text-2xl font-extrabold text-slate-900 tracking-tight">
              Platform Forensic Audit Logs
            </h2>
          </div>
          <p className="text-xs sm:text-sm text-slate-500 mt-1">
            Immutable timeline of state modifications, authorization checks, and adjudication actions
          </p>
        </div>

        <div className="flex items-center gap-2">
          <button
            type="button"
            onClick={fetchLogs}
            className="inline-flex items-center gap-1.5 px-3.5 py-2 text-xs font-semibold text-slate-700 bg-white border border-slate-300 rounded-xl hover:bg-slate-50 shadow-xs"
          >
            <RefreshCw className="w-3.5 h-3.5" />
            Refresh Stream
          </button>
        </div>
      </div>

      {/* Filter and Search Bar */}
      <div className="bg-white p-4 rounded-2xl border border-slate-200 shadow-sm flex flex-col md:flex-row items-center justify-between gap-3">
        <form onSubmit={handleSearchSubmit} className="w-full md:w-80 relative">
          <Search className="w-4 h-4 text-slate-400 absolute left-3 top-3 pointer-events-none" />
          <input
            type="text"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Search by action, user, entity ID, or IP..."
            className="w-full pl-9 pr-4 py-2 text-xs bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-500"
          />
        </form>

        <div className="w-full md:w-auto flex flex-wrap items-center gap-2">
          <select
            value={entityFilter}
            onChange={(e) => setEntityFilter(e.target.value)}
            className="px-3 py-2 text-xs bg-slate-50 border border-slate-200 rounded-xl font-medium text-slate-700 focus:outline-none focus:border-indigo-500"
          >
            <option value="">All Entities</option>
            <option value="CLAIM">Claim Transactions</option>
            <option value="DOCUMENT">Document Storage</option>
            <option value="FRAUD_INVESTIGATION">SIU Investigations</option>
            <option value="USER">User & Roles</option>
            <option value="SETTING">System Settings</option>
          </select>

          <select
            value={actionFilter}
            onChange={(e) => setActionFilter(e.target.value)}
            className="px-3 py-2 text-xs bg-slate-50 border border-slate-200 rounded-xl font-medium text-slate-700 focus:outline-none focus:border-indigo-500"
          >
            <option value="">All Actions</option>
            <option value="CLAIM_CREATED">CLAIM_CREATED</option>
            <option value="STATUS_CHANGE">STATUS_CHANGE_*</option>
            <option value="DOCUMENT_VERIFIED">DOCUMENT_VERIFIED</option>
            <option value="FRAUD_INVESTIGATION">FRAUD_INVESTIGATION_*</option>
            <option value="USER_ROLE">USER_ROLE_CHANGED</option>
          </select>
        </div>
      </div>

      {/* Audit Logs Table */}
      <div className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs">
            <thead>
              <tr className="bg-slate-50/80 border-b border-slate-200/80 text-slate-500 uppercase font-bold tracking-wider text-[10px]">
                <th className="py-3 px-4">Timestamp</th>
                <th className="py-3 px-4">Actor</th>
                <th className="py-3 px-4">Action Signature</th>
                <th className="py-3 px-4">Entity Type</th>
                <th className="py-3 px-4">IP Address</th>
                <th className="py-3 px-4 text-right">State Payload</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {isLoading ? (
                <tr>
                  <td colSpan={6} className="py-12 text-center text-slate-400">
                    <div className="w-6 h-6 border-2 border-indigo-600 border-t-transparent rounded-full animate-spin mx-auto mb-2" />
                    <span>Loading forensic audit logs...</span>
                  </td>
                </tr>
              ) : logs.length === 0 ? (
                <tr>
                  <td colSpan={6} className="py-12 text-center text-slate-400">
                    No audit records matching query filters.
                  </td>
                </tr>
              ) : (
                logs.map((log) => {
                  const badgeColor =
                    ACTION_COLORS[log.action] ||
                    (log.action.includes('APPROVED')
                      ? 'bg-emerald-100 text-emerald-800'
                      : log.action.includes('REJECTED')
                      ? 'bg-rose-100 text-rose-800'
                      : 'bg-indigo-50 text-indigo-700 border-indigo-100');

                  return (
                    <tr key={log.id} className="hover:bg-slate-50/80 transition-colors">
                      <td className="py-3.5 px-4 font-mono text-[11px] text-slate-500">
                        <span className="block font-bold text-slate-700">
                          {new Date(log.created_at).toLocaleTimeString()}
                        </span>
                        <span>{new Date(log.created_at).toLocaleDateString()}</span>
                      </td>

                      <td className="py-3.5 px-4">
                        <span className="font-bold text-slate-900 block">
                          {log.user_name || 'System Auto-Engine'}
                        </span>
                        <span className="text-[10px] font-mono text-slate-400">
                          {log.user_role || 'DAEMON'}
                        </span>
                      </td>

                      <td className="py-3.5 px-4">
                        <span
                          className={`font-mono font-bold px-2 py-0.5 rounded border text-[11px] ${badgeColor}`}
                        >
                          {log.action}
                        </span>
                      </td>

                      <td className="py-3.5 px-4 font-mono text-[11px]">
                        <span className="font-semibold text-slate-800">{log.entity_type}</span>{' '}
                        {log.entity_id && (
                          <span className="text-slate-400">#{log.entity_id}</span>
                        )}
                      </td>

                      <td className="py-3.5 px-4 font-mono text-[11px] text-slate-400">
                        {log.ip_address || '127.0.0.1'}
                      </td>

                      <td className="py-3.5 px-4 text-right">
                        <button
                          type="button"
                          onClick={() => setSelectedLog(log)}
                          className="inline-flex items-center gap-1 px-2.5 py-1 rounded-lg border border-slate-200 text-slate-700 hover:bg-slate-100 hover:text-indigo-600 font-mono text-[11px] transition-colors"
                        >
                          <Code className="w-3 h-3" />
                          <span>Inspect</span>
                        </button>
                      </td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Modal: JSON State Payload Inspector */}
      {selectedLog && (
        <Modal
          isOpen={!!selectedLog}
          onClose={() => setSelectedLog(null)}
          title={`Forensic Audit Record #${selectedLog.id}`}
        >
          <div className="space-y-4 text-xs">
            <div className="grid grid-cols-2 gap-2 p-3 bg-slate-50 rounded-xl border border-slate-200/80 text-[11px]">
              <div>
                <span className="text-slate-400 block font-bold">Action Event:</span>
                <span className="font-mono font-bold text-indigo-700">{selectedLog.action}</span>
              </div>
              <div>
                <span className="text-slate-400 block font-bold">Recorded At:</span>
                <span className="font-mono">{new Date(selectedLog.created_at).toLocaleString()}</span>
              </div>
              <div>
                <span className="text-slate-400 block font-bold">Authenticated User:</span>
                <span className="font-semibold text-slate-800">
                  {selectedLog.user_name} ({selectedLog.user_role || 'SYSTEM'})
                </span>
              </div>
              <div>
                <span className="text-slate-400 block font-bold">Client IP Address:</span>
                <span className="font-mono text-slate-700">{selectedLog.ip_address || '127.0.0.1'}</span>
              </div>
            </div>

            <div>
              <span className="font-bold text-slate-700 block mb-1 flex items-center gap-1.5">
                <Terminal className="w-3.5 h-3.5 text-slate-500" />
                Raw JSON Context Payload:
              </span>
              <pre className="p-3.5 bg-slate-900 text-emerald-400 font-mono text-[11px] rounded-xl overflow-x-auto max-h-72 border border-slate-800">
                {JSON.stringify(selectedLog.details || {}, null, 2)}
              </pre>
            </div>

            <div className="flex justify-end pt-2 border-t border-slate-100">
              <button
                type="button"
                onClick={() => setSelectedLog(null)}
                className="px-4 py-2 rounded-xl bg-slate-900 text-white font-bold hover:bg-slate-800"
              >
                Close Inspector
              </button>
            </div>
          </div>
        </Modal>
      )}
    </div>
  );
};

export default AuditLogsPage;
