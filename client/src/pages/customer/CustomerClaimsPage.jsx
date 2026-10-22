import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { claimService } from '../../services/api';
import { Search, Filter, FileText, ArrowRight, Clock, PlusCircle } from 'lucide-react';
import { StatusBadge } from '../../components/common/Badge';
import Button from '../../components/common/Button';

const CustomerClaimsPage = () => {
  const [claims, setClaims] = useState([]);
  const [isLoading, setIsLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('');
  const [typeFilter, setTypeFilter] = useState('');

  const fetchClaims = async () => {
    setIsLoading(true);
    try {
      const params = {};
      if (search) params.search = search;
      if (statusFilter) params.status = statusFilter;
      if (typeFilter) params.claim_type = typeFilter;

      const res = await claimService.getClaims(params);
      if (res.data?.success) {
        setClaims(res.data.claims || []);
      }
    } catch (err) {
      console.error('Failed to load claims:', err);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchClaims();
  }, [statusFilter, typeFilter]);

  const handleSearchSubmit = (e) => {
    e.preventDefault();
    fetchClaims();
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h2 className="text-xl sm:text-2xl font-extrabold text-slate-900 tracking-tight">
            My Insurance Claims
          </h2>
          <p className="text-xs text-slate-500 mt-0.5">
            View history, monitor document verifications, and track settlement decisions
          </p>
        </div>

        <Link to="/customer/submit-claim">
          <Button size="md" variant="primary" icon={PlusCircle}>
            Submit New Claim
          </Button>
        </Link>
      </div>

      {/* Filter / Search Bar */}
      <div className="bg-white p-4 rounded-2xl border border-slate-200/90 shadow-sm flex flex-col md:flex-row items-center justify-between gap-3">
        <form onSubmit={handleSearchSubmit} className="w-full md:w-80 relative">
          <Search className="w-4 h-4 text-slate-400 absolute left-3 top-3 pointer-events-none" />
          <input
            type="text"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Search by Claim ID or location..."
            className="w-full pl-9 pr-3.5 py-2 text-xs rounded-xl border border-slate-300 focus:outline-none focus:ring-2 focus:ring-indigo-500"
          />
        </form>

        <div className="flex items-center gap-2.5 w-full md:w-auto">
          <select
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
            className="px-3 py-2 text-xs rounded-xl border border-slate-300 bg-white focus:outline-none focus:ring-2 focus:ring-indigo-500 w-full sm:w-auto"
          >
            <option value="">All Statuses</option>
            <option value="SUBMITTED">Submitted</option>
            <option value="UNDER_REVIEW">Under Review</option>
            <option value="DOCS_VERIFIED">Docs Verified</option>
            <option value="DOCS_PENDING">Docs Pending</option>
            <option value="APPROVED">Approved</option>
            <option value="REJECTED">Rejected</option>
          </select>

          <select
            value={typeFilter}
            onChange={(e) => setTypeFilter(e.target.value)}
            className="px-3 py-2 text-xs rounded-xl border border-slate-300 bg-white focus:outline-none focus:ring-2 focus:ring-indigo-500 w-full sm:w-auto"
          >
            <option value="">All Lines</option>
            <option value="AUTO">Auto</option>
            <option value="HEALTH">Health</option>
            <option value="HOME">Home</option>
            <option value="PROPERTY">Property</option>
          </select>
        </div>
      </div>

      {/* Claims List Table */}
      <div className="bg-white rounded-2xl border border-slate-200/90 shadow-sm overflow-hidden">
        {isLoading ? (
          <div className="py-16 text-center text-xs text-slate-400">Loading claims...</div>
        ) : claims.length === 0 ? (
          <div className="py-16 text-center px-4">
            <FileText className="w-12 h-12 text-slate-300 mx-auto mb-2" />
            <h4 className="text-sm font-bold text-slate-800">No Claims Found</h4>
            <p className="text-xs text-slate-500 mt-1 max-w-sm mx-auto">
              No insurance claims match your active filters. Try resetting the search or submit a new claim.
            </p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs">
              <thead className="bg-slate-50 border-b border-slate-100 text-slate-500 font-semibold">
                <tr>
                  <th className="py-3 px-4">Claim ID</th>
                  <th className="py-3 px-4">Policy #</th>
                  <th className="py-3 px-4">Category</th>
                  <th className="py-3 px-4">Incident Date</th>
                  <th className="py-3 px-4">Claim Amount</th>
                  <th className="py-3 px-4">Current Status</th>
                  <th className="py-3 px-4">Docs</th>
                  <th className="py-3 px-4 text-right">Action</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {claims.map((claim) => (
                  <tr key={claim.id} className="hover:bg-slate-50/80 transition">
                    <td className="py-3.5 px-4 font-mono font-bold text-indigo-600">
                      {claim.claim_id}
                    </td>
                    <td className="py-3.5 px-4 font-mono text-slate-600">
                      {claim.policy_number}
                    </td>
                    <td className="py-3.5 px-4 font-semibold text-slate-800">
                      {claim.claim_type}
                    </td>
                    <td className="py-3.5 px-4 text-slate-600">
                      {claim.incident_date}
                    </td>
                    <td className="py-3.5 px-4 font-mono font-bold text-slate-900">
                      ${parseFloat(claim.claim_amount).toLocaleString()}
                    </td>
                    <td className="py-3.5 px-4">
                      <StatusBadge status={claim.current_status} />
                    </td>
                    <td className="py-3.5 px-4 font-mono text-slate-500">
                      {claim.document_count || 0} attached
                    </td>
                    <td className="py-3.5 px-4 text-right">
                      <Link
                        to={`/customer/claims/${claim.id}`}
                        className="text-xs font-semibold text-indigo-600 hover:text-indigo-800 inline-flex items-center gap-1"
                      >
                        Track <ArrowRight className="w-3.5 h-3.5" />
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

export default CustomerClaimsPage;
