import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { claimService } from '../../services/api';
import { Search, Filter, FileText, ArrowRight, ShieldAlert, CheckCircle2 } from 'lucide-react';
import { StatusBadge, FraudRiskBadge } from '../../components/common/Badge';

const StaffClaimsPage = () => {
  const [claims, setClaims] = useState([]);
  const [isLoading, setIsLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('');
  const [riskFilter, setRiskFilter] = useState('');
  const [typeFilter, setTypeFilter] = useState('');

  const fetchClaims = async () => {
    setIsLoading(true);
    try {
      const params = {};
      if (search) params.search = search;
      if (statusFilter) params.status = statusFilter;
      if (riskFilter) params.fraud_level = riskFilter;
      if (typeFilter) params.claim_type = typeFilter;

      const res = await claimService.getClaims(params);
      if (res.data?.success) {
        setClaims(res.data.claims || []);
      }
    } catch (err) {
      console.error('Failed to load claims queue:', err);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchClaims();
  }, [statusFilter, riskFilter, typeFilter]);

  const handleSearchSubmit = (e) => {
    e.preventDefault();
    fetchClaims();
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h2 className="text-xl sm:text-2xl font-extrabold text-slate-900 tracking-tight">
            Comprehensive Claims Queue
          </h2>
          <p className="text-xs text-slate-500 mt-0.5">
            Filter by adjudication status, fraud severity, insurance line, or policyholder
          </p>
        </div>
      </div>

      {/* Filter and Search Bar */}
      <div className="bg-white p-4 rounded-2xl border border-slate-200/90 shadow-sm flex flex-col md:flex-row items-center justify-between gap-3">
        <form onSubmit={handleSearchSubmit} className="w-full md:w-80 relative">
          <Search className="w-4 h-4 text-slate-400 absolute left-3 top-3 pointer-events-none" />
          <input
            type="text"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Search claim ID, customer, location..."
            className="w-full pl-9 pr-3.5 py-2 text-xs rounded-xl border border-slate-300 focus:outline-none focus:ring-2 focus:ring-indigo-500"
          />
        </form>

        <div className="flex flex-wrap items-center gap-2.5 w-full md:w-auto">
          <select
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
            className="px-3 py-2 text-xs rounded-xl border border-slate-300 bg-white focus:outline-none focus:ring-2 focus:ring-indigo-500"
          >
            <option value="">All Statuses</option>
            <option value="SUBMITTED">Submitted</option>
            <option value="UNDER_REVIEW">Under Review</option>
            <option value="DOCS_VERIFIED">Docs Verified</option>
            <option value="INVESTIGATION_REQUIRED">Investigation Required</option>
            <option value="INVESTIGATION_IN_PROGRESS">Investigating</option>
            <option value="APPROVED">Approved</option>
            <option value="REJECTED">Rejected</option>
          </select>

          <select
            value={riskFilter}
            onChange={(e) => setRiskFilter(e.target.value)}
            className="px-3 py-2 text-xs rounded-xl border border-slate-300 bg-white focus:outline-none focus:ring-2 focus:ring-indigo-500"
          >
            <option value="">All Fraud Risks</option>
            <option value="LOW">Low Risk</option>
            <option value="MEDIUM">Medium Risk</option>
            <option value="HIGH">High Risk</option>
          </select>

          <select
            value={typeFilter}
            onChange={(e) => setTypeFilter(e.target.value)}
            className="px-3 py-2 text-xs rounded-xl border border-slate-300 bg-white focus:outline-none focus:ring-2 focus:ring-indigo-500"
          >
            <option value="">All Lines</option>
            <option value="AUTO">Auto</option>
            <option value="HEALTH">Health</option>
            <option value="HOME">Home</option>
            <option value="PROPERTY">Property</option>
          </select>
        </div>
      </div>

      {/* Claims Table */}
      <div className="bg-white rounded-2xl border border-slate-200/90 shadow-sm overflow-hidden">
        {isLoading ? (
          <div className="py-16 text-center text-xs text-slate-400">Loading claims list...</div>
        ) : claims.length === 0 ? (
          <div className="py-16 text-center">
            <FileText className="w-10 h-10 text-slate-300 mx-auto mb-2" />
            <p className="text-xs text-slate-500">No claims match the selected criteria.</p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs">
              <thead className="bg-slate-50 border-b border-slate-100 text-slate-500 font-semibold">
                <tr>
                  <th className="py-3 px-4">Claim ID</th>
                  <th className="py-3 px-4">Customer</th>
                  <th className="py-3 px-4">Policy #</th>
                  <th className="py-3 px-4">Type</th>
                  <th className="py-3 px-4">Claim Amount</th>
                  <th className="py-3 px-4">Status</th>
                  <th className="py-3 px-4">Fraud Score</th>
                  <th className="py-3 px-4 text-right">Review</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {claims.map((claim) => (
                  <tr key={claim.id} className="hover:bg-slate-50/80 transition">
                    <td className="py-3.5 px-4 font-mono font-bold text-indigo-600">
                      {claim.claim_id}
                    </td>
                    <td className="py-3.5 px-4">
                      <span className="font-semibold text-slate-900 block">{claim.customer_name}</span>
                      <span className="text-[11px] text-slate-400">{claim.customer_phone || claim.customer_email}</span>
                    </td>
                    <td className="py-3.5 px-4 font-mono text-slate-600">
                      {claim.policy_number}
                    </td>
                    <td className="py-3.5 px-4 font-semibold text-slate-800">
                      {claim.claim_type}
                    </td>
                    <td className="py-3.5 px-4 font-mono font-bold text-slate-900">
                      ${parseFloat(claim.claim_amount).toLocaleString()}
                    </td>
                    <td className="py-3.5 px-4">
                      <StatusBadge status={claim.current_status} />
                    </td>
                    <td className="py-3.5 px-4">
                      <FraudRiskBadge level={claim.fraud_risk_level} score={claim.fraud_risk_score} />
                    </td>
                    <td className="py-3.5 px-4 text-right">
                      <Link
                        to={`/staff/claims/${claim.id}`}
                        className="inline-flex items-center gap-1 px-3 py-1.5 rounded-lg bg-indigo-50 hover:bg-indigo-100 text-indigo-700 font-semibold text-xs transition"
                      >
                        Adjudicate <ArrowRight className="w-3.5 h-3.5" />
                      </Link>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
};

export default StaffClaimsPage;
