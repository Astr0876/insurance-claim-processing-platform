import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { claimService, reportService } from '../../services/api';
import {
  FileText,
  Clock,
  CheckCircle2,
  AlertTriangle,
  ArrowRight,
  ShieldAlert,
  Search,
  FileCheck
} from 'lucide-react';
import StatCard from '../../components/common/StatCard';
import { StatusBadge, FraudRiskBadge } from '../../components/common/Badge';
import Button from '../../components/common/Button';

const StaffDashboard = () => {
  const [claims, setClaims] = useState([]);
  const [metrics, setMetrics] = useState(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const fetchData = async () => {
      try {
        const [claimsRes, metricsRes] = await Promise.all([
          claimService.getClaims(),
          reportService.getSummary()
        ]);

        if (claimsRes.data?.success) {
          setClaims(claimsRes.data.claims || []);
        }
        if (metricsRes.data?.success) {
          setMetrics(metricsRes.data.metrics);
        }
      } catch (err) {
        console.error('Staff dashboard error:', err);
      } finally {
        setIsLoading(false);
      }
    };

    fetchData();
  }, []);

  // Filter queues
  const claimsNeedingAction = claims.filter(c =>
    ['SUBMITTED', 'UNDER_REVIEW', 'DOCS_PENDING', 'DOCS_VERIFIED'].includes(c.current_status)
  );

  const highRiskClaims = claims.filter(c => c.fraud_risk_level === 'HIGH');

  return (
    <div className="space-y-8">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <span className="text-xs font-semibold text-indigo-600 font-mono tracking-wider uppercase">
            Adjudication Operations
          </span>
          <h2 className="text-2xl font-extrabold text-slate-900 tracking-tight mt-0.5">
            Claims Processing Queue
          </h2>
          <p className="text-xs text-slate-500 mt-1">
            Review supporting documentation, evaluate fraud scores, and render settlement decisions
          </p>
        </div>

        <Link to="/staff/claims">
          <Button variant="primary" size="md" icon={FileText}>
            Open Full Queue ({claims.length})
          </Button>
        </Link>
      </div>

      {/* KPI Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
        <StatCard
          title="Actionable Queue"
          value={claimsNeedingAction.length}
          icon={Clock}
          color="amber"
          subtitle="Pending staff decision"
        />
        <StatCard
          title="Total Claims in System"
          value={metrics?.totalClaims || claims.length}
          icon={FileText}
          color="indigo"
          subtitle="Cumulative intake volume"
        />
        <StatCard
          title="High Risk SIU Claims"
          value={metrics?.highRiskClaims || highRiskClaims.length}
          icon={ShieldAlert}
          color="rose"
          subtitle="Flagged by fraud engine"
        />
        <StatCard
          title="Approved Claims"
          value={metrics?.approvedClaims || 0}
          icon={CheckCircle2}
          color="emerald"
          subtitle={`${metrics?.approvalRate || 0}% overall approval rate`}
        />
      </div>

      {/* Processing Queue Table */}
      <div className="bg-white rounded-2xl p-6 border border-slate-200/90 shadow-sm">
        <div className="flex items-center justify-between pb-4 border-b border-slate-100">
          <div>
            <h3 className="text-base font-bold text-slate-900">Priority Claims Awaiting Action</h3>
            <p className="text-xs text-slate-500">Ordered by date and underwriting priority</p>
          </div>
          <Link
            to="/staff/claims"
            className="text-xs font-semibold text-indigo-600 hover:text-indigo-800 flex items-center gap-1"
          >
            View All Claims <ArrowRight className="w-3.5 h-3.5" />
          </Link>
        </div>

        <div className="mt-4 overflow-x-auto">
          {isLoading ? (
            <div className="py-12 text-center text-xs text-slate-400">Loading adjudication queue...</div>
          ) : claimsNeedingAction.length === 0 ? (
            <div className="py-12 text-center">
              <CheckCircle2 className="w-10 h-10 text-emerald-400 mx-auto mb-2" />
              <h4 className="text-sm font-bold text-slate-800">Queue is Clear!</h4>
              <p className="text-xs text-slate-500 mt-1">All submitted claims have been processed.</p>
            </div>
          ) : (
            <table className="w-full text-left text-xs">
              <thead className="bg-slate-50 border-b border-slate-100 text-slate-500 font-semibold">
                <tr>
                  <th className="py-3 px-3">Claim ID</th>
                  <th className="py-3 px-3">Policyholder</th>
                  <th className="py-3 px-3">Policy #</th>
                  <th className="py-3 px-3">Claim Amount</th>
                  <th className="py-3 px-3">Status</th>
                  <th className="py-3 px-3">Fraud Risk</th>
                  <th className="py-3 px-3 text-right">Adjudicate</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {claimsNeedingAction.slice(0, 6).map((claim) => (
                  <tr key={claim.id} className="hover:bg-slate-50/80 transition">
                    <td className="py-3.5 px-3 font-mono font-bold text-indigo-600">
                      {claim.claim_id}
                    </td>
                    <td className="py-3.5 px-3">
                      <span className="font-semibold text-slate-900 block">{claim.customer_name}</span>
                      <span className="text-[11px] text-slate-400">{claim.customer_email}</span>
                    </td>
                    <td className="py-3.5 px-3 font-mono text-slate-600">
                      {claim.policy_number}
                    </td>
                    <td className="py-3.5 px-3 font-mono font-bold text-slate-900">
                      ${parseFloat(claim.claim_amount).toLocaleString()}
                    </td>
                    <td className="py-3.5 px-3">
                      <StatusBadge status={claim.current_status} />
                    </td>
                    <td className="py-3.5 px-3">
                      <FraudRiskBadge level={claim.fraud_risk_level} score={claim.fraud_risk_score} />
                    </td>
                    <td className="py-3.5 px-3 text-right">
                      <Link
                        to={`/staff/claims/${claim.id}`}
                        className="inline-flex items-center gap-1 px-3 py-1.5 rounded-lg bg-indigo-50 hover:bg-indigo-100 text-indigo-700 font-semibold text-xs transition"
                      >
                        Review <ArrowRight className="w-3.5 h-3.5" />
                      </Link>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
      </div>
    </div>
  );
};

export default StaffDashboard;
