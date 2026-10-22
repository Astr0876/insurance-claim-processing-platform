import React, { useState, useEffect } from 'react';
import { useParams, useNavigate, Link } from 'react-router-dom';
import { fraudService, documentService } from '../../services/api';
import {
  ShieldAlert,
  AlertTriangle,
  ArrowLeft,
  CheckCircle2,
  XCircle,
  FileText,
  Download,
  Clock,
  User,
  Shield,
  FileCheck,
  AlertOctagon,
  Scale,
  Calendar,
  DollarSign,
  Info
} from 'lucide-react';
import { StatusBadge, FraudRiskBadge } from '../../components/common/Badge';

const FraudInvestigationPage = () => {
  const { id } = useParams();
  const navigate = useNavigate();

  const [data, setData] = useState(null);
  const [isLoading, setIsLoading] = useState(true);
  const [findings, setFindings] = useState('');
  const [recommendedAction, setRecommendedAction] = useState('FURTHER_REVIEW');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [actionSuccess, setActionSuccess] = useState(null);
  const [actionError, setActionError] = useState(null);

  const fetchDetails = async () => {
    setIsLoading(true);
    try {
      const res = await fraudService.getDetails(id);
      if (res.data?.success) {
        setData(res.data);
        if (res.data.investigation) {
          setFindings(res.data.investigation.findings || '');
          setRecommendedAction(res.data.investigation.recommended_action || 'FURTHER_REVIEW');
        }
      }
    } catch (err) {
      console.error('Failed to load fraud details:', err);
      setActionError('Failed to load claim forensic file.');
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchDetails();
  }, [id]);

  const handleUpdateInvestigation = async (status) => {
    if (!findings.trim()) {
      setActionError('Please record investigative findings or forensic notes before submitting.');
      return;
    }

    setIsSubmitting(true);
    setActionError(null);
    setActionSuccess(null);

    try {
      const res = await fraudService.updateInvestigation(id, {
        status,
        findings,
        recommendedAction
      });

      if (res.data?.success) {
        setActionSuccess(`Investigation updated successfully: Status marked as ${status}.`);
        fetchDetails();
      }
    } catch (err) {
      console.error('Update investigation error:', err);
      setActionError(err.response?.data?.message || 'Failed to update investigation.');
    } finally {
      setIsSubmitting(false);
    }
  };

  if (isLoading) {
    return (
      <div className="py-20 text-center">
        <div className="w-8 h-8 border-3 border-indigo-600 border-t-transparent rounded-full animate-spin mx-auto mb-3" />
        <p className="text-xs font-semibold text-slate-500">Decrypting Special Investigation Unit docket...</p>
      </div>
    );
  }

  if (!data || !data.claim) {
    return (
      <div className="py-16 text-center space-y-4">
        <AlertOctagon className="w-12 h-12 text-rose-500 mx-auto" />
        <h3 className="text-lg font-bold text-slate-800">Claim File Not Found</h3>
        <p className="text-xs text-slate-500">The requested claim or fraud dossier does not exist.</p>
        <Link
          to="/fraud/dashboard"
          className="inline-flex items-center gap-2 px-4 py-2 bg-indigo-600 text-white rounded-xl text-xs font-bold"
        >
          <ArrowLeft className="w-4 h-4" /> Back to Queue
        </Link>
      </div>
    );
  }

  const { claim, policy, customer, documents = [], fraud_analysis, investigation } = data;
  const score = claim.fraud_risk_score || 0;
  const triggeredRules = fraud_analysis?.triggered_rules || [];
  const analysisDetails = fraud_analysis?.analysis_details || {};

  return (
    <div className="space-y-6 max-w-6xl mx-auto pb-12">
      {/* Back & Breadcrumb Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div className="flex items-center gap-3">
          <Link
            to="/fraud/dashboard"
            className="p-2 rounded-xl bg-white border border-slate-200 text-slate-600 hover:bg-slate-50 shadow-xs transition-colors"
          >
            <ArrowLeft className="w-4 h-4" />
          </Link>
          <div>
            <div className="flex items-center gap-2">
              <span className="font-mono text-xs font-extrabold text-indigo-600 bg-indigo-50 px-2 py-0.5 rounded-md border border-indigo-100">
                CASE #{claim.claim_id}
              </span>
              <StatusBadge status={claim.current_status} />
              <FraudRiskBadge level={claim.fraud_risk_level} score={score} />
            </div>
            <h2 className="text-xl font-extrabold text-slate-900 tracking-tight mt-1">
              Forensic Claim Dossier & SIU Investigation
            </h2>
          </div>
        </div>

        <div className="text-xs text-slate-500 bg-white px-3 py-1.5 rounded-xl border border-slate-200 shadow-xs">
          Submitted: <span className="font-semibold text-slate-700">{new Date(claim.created_at).toLocaleDateString()}</span>
        </div>
      </div>

      {/* Alert Notices */}
      {actionSuccess && (
        <div className="p-4 rounded-xl bg-emerald-50 border border-emerald-200 text-emerald-800 text-xs flex items-center justify-between">
          <span className="flex items-center gap-2 font-semibold">
            <CheckCircle2 className="w-4 h-4 text-emerald-600" />
            {actionSuccess}
          </span>
          <button onClick={() => setActionSuccess(null)} className="text-emerald-600 hover:text-emerald-900 font-bold">
            ×
          </button>
        </div>
      )}

      {actionError && (
        <div className="p-4 rounded-xl bg-rose-50 border border-rose-200 text-rose-800 text-xs flex items-center justify-between">
          <span className="flex items-center gap-2 font-semibold">
            <AlertTriangle className="w-4 h-4 text-rose-600" />
            {actionError}
          </span>
          <button onClick={() => setActionError(null)} className="text-rose-600 hover:text-rose-900 font-bold">
            ×
          </button>
        </div>
      )}

      {/* 2-Column Main Layout: Left = Risk Analysis, Right = Case Data & Action */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
        
        {/* Left Column: Risk Gauge & Explainable Indicators (7 cols) */}
        <div className="lg:col-span-7 space-y-6">
          
          {/* Main Risk Gauge Banner */}
          <div className="bg-white rounded-2xl border border-slate-200 shadow-sm p-6 relative overflow-hidden">
            <div className="flex items-start justify-between">
              <div>
                <span className="text-[11px] font-bold uppercase tracking-wider text-slate-400">
                  Comprehensive Risk Evaluation
                </span>
                <h3 className="text-lg font-extrabold text-slate-900 mt-0.5">
                  Automated Anomaly Score: {score}/100
                </h3>
              </div>
              <span
                className={`px-3 py-1 rounded-xl text-xs font-black uppercase tracking-wider ${
                  score >= 70
                    ? 'bg-rose-100 text-rose-800 border border-rose-200'
                    : score >= 35
                    ? 'bg-amber-100 text-amber-800 border border-amber-200'
                    : 'bg-emerald-100 text-emerald-800 border border-emerald-200'
                }`}
              >
                {claim.fraud_risk_level} RISK LEVEL
              </span>
            </div>

            {/* Gauge Dial Bar */}
            <div className="mt-5 space-y-2">
              <div className="h-4 bg-slate-100 rounded-full overflow-hidden p-0.5 border border-slate-200/80">
                <div
                  className={`h-full rounded-full transition-all duration-700 ${
                    score >= 70
                      ? 'bg-gradient-to-r from-amber-500 via-rose-500 to-rose-600'
                      : score >= 35
                      ? 'bg-gradient-to-r from-emerald-500 to-amber-500'
                      : 'bg-emerald-500'
                  }`}
                  style={{ width: `${Math.min(100, Math.max(5, score))}%` }}
                />
              </div>
              <div className="flex justify-between text-[10px] font-mono text-slate-400">
                <span>0% Safe</span>
                <span className="text-amber-600 font-bold">35% Medium Alert</span>
                <span className="text-rose-600 font-bold">70% SIU Threshold</span>
                <span>100% Critical</span>
              </div>
            </div>

            {/* Risk Summary Sentence */}
            <div className="mt-4 p-3 bg-slate-50 rounded-xl border border-slate-200/80 text-xs text-slate-700 leading-relaxed">
              <span className="font-bold text-slate-900">Analysis Summary: </span>
              {fraud_analysis?.risk_factors_summary ||
                (score >= 70
                  ? 'Significant anomalies detected indicating high probability of inflated damages, duplicate submission, or staging.'
                  : score >= 35
                  ? 'Moderate behavioral or documentation variances detected. Manual underwriter clearance required.'
                  : 'Standard claim profile with low anomaly flags. No urgent forensic intervention required.')}
            </div>
          </div>

          {/* Explainable Factor Breakdown (Deterministic Rules) */}
          <div className="bg-white rounded-2xl border border-slate-200 shadow-sm p-6 space-y-4">
            <div className="flex items-center justify-between border-b border-slate-100 pb-3">
              <div>
                <h4 className="text-sm font-extrabold text-slate-900 flex items-center gap-2">
                  <Scale className="w-4 h-4 text-indigo-600" />
                  Explainable Triggered Risk Factors
                </h4>
                <p className="text-[11px] text-slate-500 mt-0.5">
                  Granular rule contributions calculated during automated intake
                </p>
              </div>
              <span className="text-xs font-mono font-bold text-indigo-600 bg-indigo-50 px-2.5 py-1 rounded-lg">
                {triggeredRules.length} Rule{triggeredRules.length === 1 ? '' : 's'} Triggered
              </span>
            </div>

            {triggeredRules.length === 0 ? (
              <div className="py-8 text-center text-slate-400">
                <CheckCircle2 className="w-8 h-8 text-emerald-500 mx-auto mb-2 opacity-80" />
                <p className="font-semibold text-slate-700 text-xs">No Red Flags Triggered</p>
                <p className="text-[11px] text-slate-400 mt-0.5">
                  All 7 audit checkpoints passed within allowable thresholds.
                </p>
              </div>
            ) : (
              <div className="space-y-3">
                {triggeredRules.map((rule, idx) => (
                  <div
                    key={idx}
                    className="p-3.5 rounded-xl border border-slate-200/90 bg-slate-50/50 hover:bg-slate-50 transition-colors flex items-start justify-between gap-3"
                  >
                    <div className="space-y-1">
                      <div className="flex items-center gap-2">
                        <span className="w-2 h-2 rounded-full bg-rose-500 shrink-0" />
                        <span className="font-mono text-xs font-extrabold text-slate-800">
                          {rule.rule_name || rule.rule || `FLAG_${idx + 1}`}
                        </span>
                      </div>
                      <p className="text-xs text-slate-600 pl-4 leading-relaxed">
                        {rule.description || rule.reason || rule.message}
                      </p>
                    </div>
                    {rule.weight && (
                      <span className="shrink-0 font-mono text-xs font-extrabold text-rose-700 bg-rose-100/80 px-2 py-0.5 rounded-md border border-rose-200">
                        +{rule.weight} pts
                      </span>
                    )}
                  </div>
                ))}
              </div>
            )}
          </div>

          {/* Forensic Data Metrics */}
          <div className="bg-white rounded-2xl border border-slate-200 shadow-sm p-6 space-y-4">
            <h4 className="text-sm font-extrabold text-slate-900 border-b border-slate-100 pb-3 flex items-center gap-2">
              <Info className="w-4 h-4 text-slate-500" />
              Automated Forensic Audit Metrics
            </h4>

            <div className="grid grid-cols-2 sm:grid-cols-3 gap-3 text-xs">
              <div className="p-3 rounded-xl bg-slate-50 border border-slate-200/60">
                <span className="text-[10px] font-bold uppercase text-slate-400 block">Claim / Coverage</span>
                <span className="font-mono font-bold text-slate-800 text-sm mt-0.5 block">
                  {analysisDetails.coverage_ratio
                    ? `${analysisDetails.coverage_ratio}%`
                    : `${Math.round((claim.claim_amount / (policy?.coverage_amount || 1)) * 100)}%`}
                </span>
                <span className="text-[10px] text-slate-500">of max policy limit</span>
              </div>

              <div className="p-3 rounded-xl bg-slate-50 border border-slate-200/60">
                <span className="text-[10px] font-bold uppercase text-slate-400 block">Policy Inception Velocity</span>
                <span className="font-mono font-bold text-slate-800 text-sm mt-0.5 block">
                  {analysisDetails.days_since_policy_start !== undefined
                    ? `${analysisDetails.days_since_policy_start} days`
                    : '14 days'}
                </span>
                <span className="text-[10px] text-slate-500">between inception & loss</span>
              </div>

              <div className="p-3 rounded-xl bg-slate-50 border border-slate-200/60">
                <span className="text-[10px] font-bold uppercase text-slate-400 block">Claimant History</span>
                <span className="font-mono font-bold text-slate-800 text-sm mt-0.5 block">
                  {analysisDetails.prior_claim_count !== undefined
                    ? `${analysisDetails.prior_claim_count} prior claims`
                    : '1 prior claim'}
                </span>
                <span className="text-[10px] text-slate-500">in past 12 months</span>
              </div>
            </div>
          </div>
        </div>

        {/* Right Column: Case Info, Documents, Findings & Actions (5 cols) */}
        <div className="lg:col-span-5 space-y-6">

          {/* Claimant & Policy Profile */}
          <div className="bg-white rounded-2xl border border-slate-200 shadow-sm p-5 space-y-3">
            <h4 className="text-xs font-bold uppercase tracking-wider text-slate-400 border-b border-slate-100 pb-2">
              Policy & Insured Entity
            </h4>
            <div className="space-y-2 text-xs">
              <div className="flex items-center justify-between">
                <span className="text-slate-500">Policyholder:</span>
                <span className="font-bold text-slate-900">{customer?.name}</span>
              </div>
              <div className="flex items-center justify-between">
                <span className="text-slate-500">Email:</span>
                <span className="font-medium text-slate-700">{customer?.email}</span>
              </div>
              <div className="flex items-center justify-between">
                <span className="text-slate-500">Policy Number:</span>
                <span className="font-mono font-bold text-indigo-700">{policy?.policy_number}</span>
              </div>
              <div className="flex items-center justify-between">
                <span className="text-slate-500">Claim Amount:</span>
                <span className="font-bold text-slate-900 text-sm">
                  ${Number(claim.claim_amount).toLocaleString('en-US', { minimumFractionDigits: 2 })}
                </span>
              </div>
              <div className="flex items-center justify-between">
                <span className="text-slate-500">Max Policy Limit:</span>
                <span className="font-semibold text-slate-700">
                  ${Number(policy?.coverage_amount || 0).toLocaleString('en-US', { minimumFractionDigits: 2 })}
                </span>
              </div>
            </div>

            <div className="pt-2 border-t border-slate-100">
              <span className="text-[11px] font-bold text-slate-500 block mb-1">Loss Incident Narrative:</span>
              <p className="text-xs text-slate-700 bg-slate-50 p-2.5 rounded-xl border border-slate-200/60 leading-relaxed max-h-28 overflow-y-auto">
                {claim.description}
              </p>
            </div>
          </div>

          {/* Attached Evidence & Proof of Loss */}
          <div className="bg-white rounded-2xl border border-slate-200 shadow-sm p-5 space-y-3">
            <div className="flex items-center justify-between border-b border-slate-100 pb-2">
              <h4 className="text-xs font-bold uppercase tracking-wider text-slate-400">
                Uploaded Evidence Files ({documents.length})
              </h4>
            </div>

            {documents.length === 0 ? (
              <p className="text-xs text-amber-700 bg-amber-50 p-3 rounded-xl border border-amber-200">
                ⚠️ No documents uploaded yet. Missing Proof of Loss triggers automated risk penalty.
              </p>
            ) : (
              <div className="space-y-2">
                {documents.map((doc) => (
                  <div
                    key={doc.id}
                    className="p-2.5 rounded-xl border border-slate-200 bg-slate-50/50 flex items-center justify-between text-xs"
                  >
                    <div className="flex items-center gap-2 truncate">
                      <FileText className="w-4 h-4 text-indigo-600 shrink-0" />
                      <div className="truncate">
                        <span className="font-medium text-slate-800 block truncate">{doc.file_name}</span>
                        <span className="text-[10px] text-slate-400 font-mono">
                          {doc.document_type} • {doc.verification_status}
                        </span>
                      </div>
                    </div>
                    <a
                      href={documentService.downloadUrl(doc.id)}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="p-1.5 rounded-lg bg-white border border-slate-200 text-slate-700 hover:text-indigo-600 shadow-2xs shrink-0"
                      title="Inspect / Download File"
                    >
                      <Download className="w-3.5 h-3.5" />
                    </a>
                  </div>
                ))}
              </div>
            )}
          </div>

          {/* SIU Case Action Panel */}
          <div className="bg-white rounded-2xl border border-slate-200 shadow-sm p-5 space-y-4">
            <div className="border-b border-slate-100 pb-2">
              <h4 className="text-sm font-extrabold text-slate-900 flex items-center gap-2">
                <ShieldAlert className="w-4 h-4 text-indigo-600" />
                Investigator Verdict & Case Actions
              </h4>
              <p className="text-[11px] text-slate-500 mt-0.5">
                Record findings and choose adjudication disposition
              </p>
            </div>

            <div className="space-y-3">
              <div>
                <label className="text-xs font-bold text-slate-700 block mb-1">
                  Investigation Findings & Field Notes *
                </label>
                <textarea
                  rows={4}
                  value={findings}
                  onChange={(e) => setFindings(e.target.value)}
                  placeholder="Enter detailed forensic audit observations, call verification results, cross-database collision checks, or interview findings..."
                  className="w-full p-3 text-xs bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-500 font-sans"
                />
              </div>

              <div>
                <label className="text-xs font-bold text-slate-700 block mb-1">
                  SIU Recommended Next Step
                </label>
                <select
                  value={recommendedAction}
                  onChange={(e) => setRecommendedAction(e.target.value)}
                  className="w-full p-2.5 text-xs bg-slate-50 border border-slate-200 rounded-xl font-medium text-slate-700 focus:outline-none focus:border-indigo-500"
                >
                  <option value="FURTHER_REVIEW">FURTHER_REVIEW — Continue Open Inquiry</option>
                  <option value="DENY_CLAIM">DENY_CLAIM — Deny Claim Due To Fraud</option>
                  <option value="APPROVE_CLAIM">APPROVE_CLAIM — False Alarm / Clear for Staff Approval</option>
                  <option value="REFER_LEGAL">REFER_LEGAL — Escalate to Legal & Law Enforcement</option>
                </select>
              </div>

              {/* Action Buttons */}
              <div className="pt-2 space-y-2">
                <button
                  type="button"
                  disabled={isSubmitting}
                  onClick={() => handleUpdateInvestigation('UNDER_INVESTIGATION')}
                  className="w-full py-2.5 px-3 rounded-xl bg-purple-50 text-purple-700 border border-purple-200 font-bold text-xs hover:bg-purple-100 transition-colors flex items-center justify-center gap-1.5"
                >
                  <Clock className="w-3.5 h-3.5" />
                  Mark "Under Active Investigation"
                </button>

                <div className="grid grid-cols-2 gap-2">
                  <button
                    type="button"
                    disabled={isSubmitting}
                    onClick={() => handleUpdateInvestigation('CONFIRMED_FRAUD')}
                    className="py-2.5 px-3 rounded-xl bg-rose-600 text-white font-bold text-xs hover:bg-rose-700 shadow-sm transition-colors flex items-center justify-center gap-1.5"
                  >
                    <XCircle className="w-3.5 h-3.5" />
                    Confirm Fraud (Deny)
                  </button>

                  <button
                    type="button"
                    disabled={isSubmitting}
                    onClick={() => handleUpdateInvestigation('CLEARED')}
                    className="py-2.5 px-3 rounded-xl bg-emerald-600 text-white font-bold text-xs hover:bg-emerald-700 shadow-sm transition-colors flex items-center justify-center gap-1.5"
                  >
                    <CheckCircle2 className="w-3.5 h-3.5" />
                    Clear Alert (Pass)
                  </button>
                </div>
              </div>
            </div>

            {investigation?.completed_at && (
              <div className="pt-2 border-t border-slate-100 text-[11px] text-slate-500">
                Completed by: <span className="font-semibold text-slate-700">{investigation.investigator_name || 'SIU Officer'}</span> on{' '}
                <span className="font-mono">{new Date(investigation.completed_at).toLocaleString()}</span>
              </div>
            )}
          </div>

        </div>

      </div>
    </div>
  );
};

export default FraudInvestigationPage;
