import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';
import { claimService, policyService } from '../../services/api';
import {
  FileText,
  FilePlus,
  CheckCircle2,
  Clock,
  Shield,
  ArrowRight,
  TrendingUp,
  AlertCircle
} from 'lucide-react';
import StatCard from '../../components/common/StatCard';
import { StatusBadge } from '../../components/common/Badge';
import Button from '../../components/common/Button';

const CustomerDashboard = () => {
  const { user } = useAuth();
  const [claims, setClaims] = useState([]);
  const [policies, setPolicies] = useState([]);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const fetchData = async () => {
      try {
        const [claimsRes, policiesRes] = await Promise.all([
          claimService.getClaims(),
          policyService.getPolicies()
        ]);

        if (claimsRes.data?.success) {
          setClaims(claimsRes.data.claims || []);
        }
        if (policiesRes.data?.success) {
          setPolicies(policiesRes.data.policies || []);
        }
      } catch (err) {
        console.error('Customer dashboard load error:', err);
      } finally {
        setIsLoading(false);
      }
    };

    fetchData();
  }, []);

  // Compute metrics
  const totalClaims = claims.length;
  const approvedClaims = claims.filter(c => c.current_status === 'APPROVED');
  const pendingClaims = claims.filter(c => !['APPROVED', 'REJECTED'].includes(c.current_status));
  const totalPayout = approvedClaims.reduce((sum, c) => sum + (parseFloat(c.payout_amount) || 0), 0);

  return (
    <div className="space-y-8">
      {/* Welcome Banner */}
      <div className="bg-gradient-to-r from-slate-900 to-indigo-950 rounded-2xl p-6 sm:p-8 text-white shadow-lg border border-indigo-900/40 flex flex-col md:flex-row items-start md:items-center justify-between gap-6">
        <div>
          <span className="text-xs font-semibold text-indigo-300 font-mono tracking-wider uppercase">
            Policyholder Portal
          </span>
          <h2 className="text-2xl sm:text-3xl font-extrabold text-white mt-1">
            Welcome back, {user?.name}
          </h2>
          <p className="text-xs sm:text-sm text-slate-300 mt-1 max-w-xl">
            Track active claims, upload supporting bills, and view real-time adjudication status.
          </p>
        </div>

        <Link to="/customer/submit-claim">
          <Button variant="primary" size="lg" icon={FilePlus}>
            Submit New Claim
          </Button>
        </Link>
      </div>

      {/* KPI Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
        <StatCard
          title="Total Submitted Claims"
          value={totalClaims}
          icon={FileText}
          color="indigo"
          subtitle="All-time claims filed"
        />
        <StatCard
          title="Under Review"
          value={pendingClaims.length}
          icon={Clock}
          color="amber"
          subtitle="In document or fraud check"
        />
        <StatCard
          title="Approved Claims"
          value={approvedClaims.length}
          icon={CheckCircle2}
          color="emerald"
          subtitle="Successfully adjudicated"
        />
        <StatCard
          title="Total Settlements"
          value={totalPayout}
          icon={TrendingUp}
          color="blue"
          prefix="$"
          subtitle="Disbursed reimbursement"
        />
      </div>

      {/* Main Content Grid: Recent Claims & Policies */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        {/* Claims Table */}
        <div className="lg:col-span-2 bg-white rounded-2xl p-6 border border-slate-200/90 shadow-sm">
          <div className="flex items-center justify-between pb-5 border-b border-slate-100">
            <div>
              <h3 className="text-base font-bold text-slate-900">Recent Claims</h3>
              <p className="text-xs text-slate-500">Latest activity and live status updates</p>
            </div>
            <Link
              to="/customer/claims"
              className="text-xs font-semibold text-indigo-600 hover:text-indigo-800 flex items-center gap-1"
            >
              View All Claims <ArrowRight className="w-3.5 h-3.5" />
            </Link>
          </div>

          <div className="mt-4 overflow-x-auto">
            {isLoading ? (
              <div className="py-8 text-center text-xs text-slate-400">Loading claims...</div>
            ) : claims.length === 0 ? (
              <div className="py-12 text-center">
                <FileText className="w-10 h-10 text-slate-300 mx-auto mb-2" />
                <p className="text-xs text-slate-500">No claims filed yet.</p>
                <Link to="/customer/submit-claim" className="inline-block mt-3">
                  <Button size="sm">File Your First Claim</Button>
                </Link>
              </div>
            ) : (
              <table className="w-full text-left text-xs">
                <thead>
                  <tr className="border-b border-slate-100 text-slate-400 font-medium">
                    <th className="pb-3">Claim ID</th>
                    <th className="pb-3">Category</th>
                    <th className="pb-3">Claim Amount</th>
                    <th className="pb-3">Status</th>
                    <th className="pb-3 text-right">Action</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100">
                  {claims.slice(0, 5).map((claim) => (
                    <tr key={claim.id} className="hover:bg-slate-50/80 transition">
                      <td className="py-3.5 font-mono font-bold text-slate-900">
                        {claim.claim_id}
                      </td>
                      <td className="py-3.5">
                        <span className="font-semibold text-slate-700">{claim.claim_type}</span>
                        <div className="text-[11px] text-slate-400">{claim.incident_date}</div>
                      </td>
                      <td className="py-3.5 font-bold text-slate-900">
                        ${parseFloat(claim.claim_amount).toLocaleString()}
                      </td>
                      <td className="py-3.5">
                        <StatusBadge status={claim.current_status} />
                      </td>
                      <td className="py-3.5 text-right">
                        <Link
                          to={`/customer/claims/${claim.id}`}
                          className="text-xs font-semibold text-indigo-600 hover:text-indigo-800"
                        >
                          Details →
                        </Link>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </div>
        </div>

        {/* Active Policies Summary */}
        <div className="bg-white rounded-2xl p-6 border border-slate-200/90 shadow-sm flex flex-col justify-between">
          <div>
            <div className="flex items-center justify-between pb-4 border-b border-slate-100">
              <div>
                <h3 className="text-base font-bold text-slate-900">My Active Policies</h3>
                <p className="text-xs text-slate-500">Registered coverage contracts</p>
              </div>
              <Shield className="w-5 h-5 text-indigo-600" />
            </div>

            <div className="mt-4 space-y-3">
              {policies.map((p) => (
                <div key={p.id} className="p-3.5 rounded-xl bg-slate-50 border border-slate-200/70">
                  <div className="flex items-center justify-between">
                    <span className="text-xs font-bold text-slate-900">{p.policy_type} Insurance</span>
                    <span className="text-[10px] font-semibold font-mono px-2 py-0.5 rounded-full bg-emerald-100 text-emerald-800">
                      {p.status}
                    </span>
                  </div>
                  <div className="text-[11px] font-mono text-slate-500 mt-1">{p.policy_number}</div>
                  <div className="mt-2 pt-2 border-t border-slate-200/50 flex justify-between text-xs">
                    <span className="text-slate-500">Limit: <strong className="text-slate-800">${parseFloat(p.coverage_amount).toLocaleString()}</strong></span>
                    <span className="text-slate-500">Deductible: <strong className="text-slate-800">${parseFloat(p.deductible).toLocaleString()}</strong></span>
                  </div>
                </div>
              ))}
            </div>
          </div>

          <div className="mt-6 pt-4 border-t border-slate-100">
            <Link to="/customer/profile" className="text-xs font-semibold text-indigo-600 hover:text-indigo-800 flex items-center justify-center gap-1">
              Manage Policy Details <ArrowRight className="w-3.5 h-3.5" />
            </Link>
          </div>
        </div>
      </div>
    </div>
  );
};

export default CustomerDashboard;
