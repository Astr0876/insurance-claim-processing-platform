import React, { useState, useEffect } from 'react';
import { useParams, Link, useNavigate } from 'react-router-dom';
import { claimService, documentService } from '../../services/api';
import {
  FileText,
  Shield,
  ArrowLeft,
  CheckCircle2,
  XCircle,
  AlertTriangle,
  Download,
  DollarSign,
  User,
  Clock,
  HelpCircle,
  FileCheck,
  Send
} from 'lucide-react';
import { StatusBadge, FraudRiskBadge, DocumentStatusBadge } from '../../components/common/Badge';
import { ClaimProgressTimeline, StatusHistoryTimeline } from '../../components/common/Timeline';
import Button from '../../components/common/Button';
import Modal from '../../components/common/Modal';

const StaffClaimReviewPage = () => {
  const { id } = useParams();
  const navigate = useNavigate();

  const [claim, setClaim] = useState(null);
  const [isLoading, setIsLoading] = useState(true);

  // Document verify modal
  const [verifyModalOpen, setVerifyModalOpen] = useState(false);
  const [selectedDoc, setSelectedDoc] = useState(null);
  const [verifyStatus, setVerifyStatus] = useState('VERIFIED');
  const [verifyNotes, setVerifyNotes] = useState('');
  const [isUpdatingDoc, setIsUpdatingDoc] = useState(false);

  // Adjudication decision form
  const [decisionAction, setDecisionAction] = useState('APPROVE');
  const [payoutAmount, setPayoutAmount] = useState('');
  const [decisionReason, setDecisionReason] = useState('');
  const [isSubmittingDecision, setIsSubmittingDecision] = useState(false);
  const [decisionError, setDecisionError] = useState('');
  const [decisionSuccess, setDecisionSuccess] = useState('');

  const fetchClaimDetails = async () => {
    try {
      const res = await claimService.getClaimById(id);
      if (res.data?.success) {
        const c = res.data.claim;
        setClaim(c);
        setPayoutAmount(c.claim_amount);
      }
    } catch (err) {
      console.error('Failed to load claim details:', err);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchClaimDetails();
  }, [id]);

  const openVerifyModal = (doc, defaultStatus = 'VERIFIED') => {
    setSelectedDoc(doc);
    setVerifyStatus(defaultStatus);
    setVerifyNotes(doc.verification_notes || '');
    setVerifyModalOpen(true);
  };

  const handleDocumentVerifySubmit = async (e) => {
    e.preventDefault();
    if (!selectedDoc) return;

    setIsUpdatingDoc(true);
    try {
      await documentService.verify(selectedDoc.id, {
        status: verifyStatus,
        notes: verifyNotes
      });
      setVerifyModalOpen(false);
      fetchClaimDetails();
    } catch (err) {
      alert(err.response?.data?.message || 'Failed to update document verification.');
    } finally {
      setIsUpdatingDoc(false);
    }
  };

  const handleDecisionSubmit = async (e) => {
    e.preventDefault();
    setDecisionError('');
    setDecisionSuccess('');

    // Business rule checks before submission
    const docs = claim.documents || [];
    const hasUnverifiedDocs = docs.some(d => d.verification_status !== 'VERIFIED');

    if (decisionAction === 'APPROVE') {
      if (docs.length === 0) {
        setDecisionError('Cannot approve claim: No supporting documents uploaded.');
        return;
      }
      if (hasUnverifiedDocs) {
        setDecisionError('Cannot approve claim: All uploaded documents must be verified prior to approval.');
        return;
      }
      if (claim.fraud_risk_level === 'HIGH') {
        const isCleared = claim.investigations?.some(i => i.status === 'CLEARED');
        if (!isCleared) {
          setDecisionError('Cannot approve claim: Claim was flagged as HIGH fraud risk and requires clearance from a Fraud Investigation Officer before approval.');
          return;
        }
      }
    }

    setIsSubmittingDecision(true);
    try {
      const payload = {
        action: decisionAction === 'APPROVE' ? 'APPROVED' : (decisionAction === 'REJECT' ? 'REJECTED' : 'DOCS_PENDING'),
        payoutAmount: decisionAction === 'APPROVE' ? parseFloat(payoutAmount) : 0,
        decisionReason
      };

      const res = await claimService.updateStatus(claim.id, payload);
      if (res.data?.success) {
        setDecisionSuccess(`Claim successfully updated to ${payload.action}!`);
        fetchClaimDetails();
      }
    } catch (err) {
      setDecisionError(err.response?.data?.message || err.message || 'Adjudication failed.');
    } finally {
      setIsSubmittingDecision(false);
    }
  };

  if (isLoading) {
    return <div className="py-20 text-center text-xs text-slate-400">Loading claim adjudication file...</div>;
  }

  if (!claim) {
    return (
      <div className="py-20 text-center">
        <h3 className="text-base font-bold text-slate-800">Claim Not Found</h3>
        <Link to="/staff/claims" className="inline-block mt-4">
          <Button size="sm">Return to Queue</Button>
        </Link>
      </div>
    );
  }

  const docs = claim.documents || [];
  const allDocsVerified = docs.length > 0 && docs.every(d => d.verification_status === 'VERIFIED');
  const fraudHighUncleared = claim.fraud_risk_level === 'HIGH' && !claim.investigations?.some(i => i.status === 'CLEARED');

  return (
    <div className="space-y-8 max-w-6xl mx-auto">
      {/* Header & Back Link */}
      <div>
        <Link
          to="/staff/claims"
          className="text-xs font-semibold text-slate-500 hover:text-indigo-600 inline-flex items-center gap-1.5 mb-3"
        >
          <ArrowLeft className="w-3.5 h-3.5" /> Back to Claims Queue
        </Link>

        <div className="bg-white rounded-2xl p-6 sm:p-8 border border-slate-200/90 shadow-sm flex flex-col md:flex-row md:items-center justify-between gap-6">
          <div>
            <div className="flex items-center gap-3">
              <h2 className="text-2xl font-black font-mono text-slate-900 tracking-tight">
                {claim.claim_id}
              </h2>
              <StatusBadge status={claim.current_status} />
              <FraudRiskBadge level={claim.fraud_risk_level} score={claim.fraud_risk_score} />
            </div>
            <p className="text-xs text-slate-500 mt-1">
              Policyholder: <strong className="text-slate-800">{claim.customer_name}</strong> ({claim.customer_email}) • Policy: <strong className="font-mono text-slate-800">{claim.policy_number}</strong>
            </p>
          </div>

          <div className="flex items-center gap-6 border-t sm:border-t-0 sm:border-l border-slate-200 sm:pl-6 pt-4 sm:pt-0">
            <div>
              <span className="text-[11px] font-semibold text-slate-400 block uppercase tracking-wider">
                Claim Amount
              </span>
              <span className="text-2xl font-extrabold text-slate-900 font-mono">
                ${parseFloat(claim.claim_amount).toLocaleString()}
              </span>
            </div>

            {claim.current_status === 'APPROVED' && (
              <div>
                <span className="text-[11px] font-semibold text-emerald-600 block uppercase tracking-wider">
                  Settlement
                </span>
                <span className="text-2xl font-black text-emerald-600 font-mono">
                  ${parseFloat(claim.payout_amount).toLocaleString()}
                </span>
              </div>
            )}
          </div>
        </div>
      </div>

      {/* Lifecycle Progress */}
      <div className="bg-white rounded-2xl p-6 border border-slate-200/90 shadow-sm">
        <h3 className="text-xs font-bold text-slate-900 uppercase tracking-wider mb-2">Lifecycle Stage</h3>
        <ClaimProgressTimeline
          status={claim.current_status}
          fraudLevel={claim.fraud_risk_level}
          hasDocs={docs.length > 0}
          isDocsVerified={allDocsVerified}
        />
      </div>

      {/* Main Review Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        {/* Left 2 Cols: Incident Details, Document Verification, Fraud Assessment */}
        <div className="lg:col-span-2 space-y-6">
          {/* Incident Details */}
          <div className="bg-white rounded-2xl p-6 border border-slate-200/90 shadow-sm space-y-4">
            <h3 className="text-sm font-bold text-slate-900 pb-3 border-b border-slate-100 flex items-center justify-between">
              <span>Incident File Details</span>
              <span className="text-xs font-semibold font-mono text-slate-500">{claim.claim_type} Insurance</span>
            </h3>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 text-xs">
              <div>
                <span className="text-slate-400 block text-[11px]">Incident Date</span>
                <span className="font-semibold text-slate-800">{claim.incident_date}</span>
              </div>
              <div>
                <span className="text-slate-400 block text-[11px]">Incident Location</span>
                <span className="font-semibold text-slate-800">{claim.incident_location}</span>
              </div>
              <div>
                <span className="text-slate-400 block text-[11px]">Coverage Limit</span>
                <span className="font-mono font-semibold text-slate-800">${parseFloat(claim.coverage_amount).toLocaleString()}</span>
              </div>
              <div>
                <span className="text-slate-400 block text-[11px]">Deductible Amount</span>
                <span className="font-mono font-semibold text-slate-800">${parseFloat(claim.deductible).toLocaleString()}</span>
              </div>
              <div className="col-span-full">
                <span className="text-slate-400 block text-[11px] mb-1">Loss Description</span>
                <p className="text-slate-700 leading-relaxed bg-slate-50 p-3 rounded-xl border border-slate-200/60">
                  {claim.description}
                </p>
              </div>
            </div>
          </div>

          {/* Document Verification Table */}
          <div className="bg-white rounded-2xl p-6 border border-slate-200/90 shadow-sm space-y-4">
            <div className="flex items-center justify-between pb-3 border-b border-slate-100">
              <div>
                <h3 className="text-sm font-bold text-slate-900">Document Verification Queue</h3>
                <p className="text-xs text-slate-500">Every document must be audited before claim approval is unlocked</p>
              </div>
              <span className={`text-xs font-semibold px-2.5 py-1 rounded-full ${
                allDocsVerified ? 'bg-emerald-100 text-emerald-800' : 'bg-amber-100 text-amber-800'
              }`}>
                {allDocsVerified ? 'All Documents Verified' : 'Verification Required'}
              </span>
            </div>

            {docs.length === 0 ? (
              <div className="py-8 text-center bg-slate-50 rounded-xl border border-dashed border-slate-200 text-xs text-slate-500">
                No documents uploaded by policyholder.
              </div>
            ) : (
              <div className="divide-y divide-slate-100">
                {docs.map((doc) => (
                  <div key={doc.id} className="py-3.5 flex flex-col sm:flex-row sm:items-center justify-between gap-3">
                    <div className="flex items-start gap-3">
                      <FileCheck className="w-5 h-5 text-indigo-600 shrink-0 mt-0.5" />
                      <div>
                        <span className="font-semibold text-xs text-slate-900 block">{doc.original_name}</span>
                        <div className="flex items-center gap-2 text-[11px] text-slate-400 mt-0.5">
                          <span className="font-medium text-slate-600">{doc.document_type}</span>
                          <span>•</span>
                          <span className="font-mono">{(doc.file_size / 1024).toFixed(0)} KB</span>
                        </div>
                        {doc.verification_notes && (
                          <p className="text-[11px] text-slate-500 italic mt-1">Audit Note: {doc.verification_notes}</p>
                        )}
                      </div>
                    </div>

                    <div className="flex items-center gap-2 shrink-0">
                      <DocumentStatusBadge status={doc.verification_status} />

                      <a
                        href={documentService.downloadUrl(doc.id)}
                        target="_blank"
                        rel="noreferrer"
                        className="p-1.5 rounded-lg border border-slate-200 text-slate-500 hover:text-indigo-600 hover:bg-slate-50"
                        title="Download / View"
                      >
                        <Download className="w-4 h-4" />
                      </a>

                      <button
                        type="button"
                        onClick={() => openVerifyModal(doc, 'VERIFIED')}
                        className="px-2.5 py-1 text-xs font-semibold rounded-lg bg-emerald-50 hover:bg-emerald-100 text-emerald-700 transition"
                      >
                        Verify
                      </button>

                      <button
                        type="button"
                        onClick={() => openVerifyModal(doc, 'REJECTED')}
                        className="px-2.5 py-1 text-xs font-semibold rounded-lg bg-rose-50 hover:bg-rose-100 text-rose-700 transition"
                      >
                        Reject
                      </button>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>

          {/* Fraud Risk Engine Summary */}
          {claim.fraud_analysis && (
            <div className={`p-6 rounded-2xl border ${
              claim.fraud_risk_level === 'HIGH'
                ? 'bg-rose-50/50 border-rose-200 text-rose-950'
                : 'bg-indigo-50/40 border-indigo-100 text-indigo-950'
            }`}>
              <div className="flex items-center justify-between pb-3 border-b border-indigo-200/50">
                <div className="flex items-center gap-2">
                  <Shield className="w-5 h-5 text-indigo-600" />
                  <h3 className="text-sm font-bold">Fraud Risk Analysis Breakdown</h3>
                </div>
                <FraudRiskBadge level={claim.fraud_risk_level} score={claim.fraud_risk_score} />
              </div>

              {fraudHighUncleared && (
                <div className="my-3 p-3 rounded-xl bg-rose-100 border border-rose-200 text-rose-800 text-xs font-semibold flex items-center gap-2">
                  <AlertTriangle className="w-4 h-4 text-rose-600 shrink-0" />
                  <span>High Fraud Risk Detected: Claim approval locked until Fraud Officer clearance.</span>
                </div>
              )}

              <div className="mt-3 space-y-2 text-xs">
                <span className="font-semibold block text-[11px] uppercase tracking-wider opacity-75">
                  Triggered Underwriting Rules:
                </span>
                {claim.fraud_analysis.triggered_rules?.map((r, idx) => (
                  <div key={idx} className="flex items-start gap-2 bg-white/70 p-2.5 rounded-lg border border-slate-200/50">
                    <AlertTriangle className="w-3.5 h-3.5 text-amber-600 shrink-0 mt-0.5" />
                    <div className="flex-1">
                      <span className="font-semibold text-slate-800">{r.description || r.ruleId}</span>
                      {r.weight && (
                        <span className="ml-2 font-mono text-[10px] bg-slate-200/80 px-1.5 py-0.2 rounded text-slate-700">
                          +{r.weight} pts
                        </span>
                      )}
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}
        </div>

        {/* Right Column: Adjudication Decision Panel & History */}
        <div className="space-y-6">
          {/* Adjudication Decision Panel */}
          <div className="bg-white rounded-2xl p-6 border border-slate-200/90 shadow-sm space-y-4">
            <h3 className="text-sm font-bold text-slate-900 pb-3 border-b border-slate-100 flex items-center gap-2">
              <Shield className="w-4 h-4 text-indigo-600" />
              <span>Adjudication Decision</span>
            </h3>

            {decisionError && (
              <div className="p-3 rounded-xl bg-rose-50 border border-rose-200 text-rose-700 text-xs flex items-start gap-2">
                <AlertTriangle className="w-4 h-4 text-rose-600 shrink-0 mt-0.5" />
                <span>{decisionError}</span>
              </div>
            )}

            {decisionSuccess && (
              <div className="p-3 rounded-xl bg-emerald-50 border border-emerald-200 text-emerald-700 text-xs flex items-center gap-2">
                <CheckCircle2 className="w-4 h-4 text-emerald-600 shrink-0" />
                <span>{decisionSuccess}</span>
              </div>
            )}

            <form onSubmit={handleDecisionSubmit} className="space-y-4">
              <div>
                <label className="block text-xs font-semibold text-slate-700 mb-1.5">
                  Select Action
                </label>
                <div className="grid grid-cols-3 gap-2">
                  <button
                    type="button"
                    onClick={() => setDecisionAction('APPROVE')}
                    className={`py-2 text-xs font-bold rounded-xl border text-center transition ${
                      decisionAction === 'APPROVE'
                        ? 'border-emerald-600 bg-emerald-50 text-emerald-700'
                        : 'border-slate-200 text-slate-600 hover:bg-slate-50'
                    }`}
                  >
                    Approve
                  </button>
                  <button
                    type="button"
                    onClick={() => setDecisionAction('REJECT')}
                    className={`py-2 text-xs font-bold rounded-xl border text-center transition ${
                      decisionAction === 'REJECT'
                        ? 'border-rose-600 bg-rose-50 text-rose-700'
                        : 'border-slate-200 text-slate-600 hover:bg-slate-50'
                    }`}
                  >
                    Reject
                  </button>
                  <button
                    type="button"
                    onClick={() => setDecisionAction('REQUEST_INFO')}
                    className={`py-2 text-xs font-bold rounded-xl border text-center transition ${
                      decisionAction === 'REQUEST_INFO'
                        ? 'border-amber-600 bg-amber-50 text-amber-700'
                        : 'border-slate-200 text-slate-600 hover:bg-slate-50'
                    }`}
                  >
                    Request Info
                  </button>
                </div>
              </div>

              {decisionAction === 'APPROVE' && (
                <div>
                  <label className="block text-xs font-semibold text-slate-700 mb-1">
                    Approved Reimbursement Payout ($ USD)
                  </label>
                  <div className="relative">
                    <DollarSign className="w-4 h-4 text-slate-400 absolute left-3 top-2.5 pointer-events-none" />
                    <input
                      type="number"
                      step="0.01"
                      required
                      value={payoutAmount}
                      onChange={(e) => setPayoutAmount(e.target.value)}
                      className="w-full pl-9 pr-3.5 py-2 text-xs rounded-xl border border-slate-300 focus:outline-none focus:ring-2 focus:ring-indigo-500 font-mono font-bold"
                    />
                  </div>
                </div>
              )}

              <div>
                <label className="block text-xs font-semibold text-slate-700 mb-1">
                  Adjudication Rationale / Decision Notes
                </label>
                <textarea
                  rows={3}
                  required
                  value={decisionReason}
                  onChange={(e) => setDecisionReason(e.target.value)}
                  placeholder={
                    decisionAction === 'APPROVE'
                      ? 'e.g. Validated invoices, all receipts verified against provider, payout complies with policy.'
                      : (decisionAction === 'REJECT'
                      ? 'e.g. Inconsistent loss documentation, damage falls outside coverage parameters.'
                      : 'e.g. Please upload police incident report and certified damage photos.')
                  }
                  className="w-full p-2.5 text-xs rounded-xl border border-slate-300 focus:outline-none focus:ring-2 focus:ring-indigo-500"
                />
              </div>

              <Button
                type="submit"
                variant={decisionAction === 'APPROVE' ? 'success' : (decisionAction === 'REJECT' ? 'danger' : 'warning')}
                isLoading={isSubmittingDecision}
                className="w-full"
                icon={Send}
              >
                Submit {decisionAction === 'APPROVE' ? 'Approval' : (decisionAction === 'REJECT' ? 'Rejection' : 'Request')}
              </Button>
            </form>
          </div>

          {/* Status Timeline History */}
          <div className="bg-white rounded-2xl p-6 border border-slate-200/90 shadow-sm space-y-4">
            <h3 className="text-sm font-bold text-slate-900 pb-3 border-b border-slate-100">
              Audit Trail & Status History
            </h3>
            <StatusHistoryTimeline history={claim.history} />
          </div>
        </div>
      </div>

      {/* Verify Document Modal */}
      <Modal
        isOpen={verifyModalOpen}
        onClose={() => setVerifyModalOpen(false)}
        title="Audit & Verify Supporting Document"
        subtitle={selectedDoc ? selectedDoc.original_name : ''}
      >
        <form onSubmit={handleDocumentVerifySubmit} className="space-y-4">
          <div>
            <label className="block text-xs font-semibold text-slate-700 mb-1">
              Audit Status
            </label>
            <div className="grid grid-cols-3 gap-2">
              <button
                type="button"
                onClick={() => setVerifyStatus('VERIFIED')}
                className={`py-2 text-xs font-bold rounded-xl border transition ${
                  verifyStatus === 'VERIFIED'
                    ? 'border-emerald-600 bg-emerald-50 text-emerald-700'
                    : 'border-slate-200 text-slate-600'
                }`}
              >
                Verified
              </button>
              <button
                type="button"
                onClick={() => setVerifyStatus('REJECTED')}
                className={`py-2 text-xs font-bold rounded-xl border transition ${
                  verifyStatus === 'REJECTED'
                    ? 'border-rose-600 bg-rose-50 text-rose-700'
                    : 'border-slate-200 text-slate-600'
                }`}
              >
                Rejected
              </button>
              <button
                type="button"
                onClick={() => setVerifyStatus('PENDING')}
                className={`py-2 text-xs font-bold rounded-xl border transition ${
                  verifyStatus === 'PENDING'
                    ? 'border-amber-600 bg-amber-50 text-amber-700'
                    : 'border-slate-200 text-slate-600'
                }`}
              >
                Needs Review
              </button>
            </div>
          </div>

          <div>
            <label className="block text-xs font-semibold text-slate-700 mb-1">
              Verification Notes
            </label>
            <textarea
              rows={3}
              value={verifyNotes}
              onChange={(e) => setVerifyNotes(e.target.value)}
              placeholder="e.g. Valid SFPD seal confirmed, repair invoice labor rates conform to regional schedule."
              className="w-full p-2.5 text-xs rounded-xl border border-slate-300 focus:outline-none focus:ring-2 focus:ring-indigo-500"
            />
          </div>

          <div className="pt-3 flex justify-end gap-2 border-t border-slate-100">
            <Button
              type="button"
              variant="outline"
              size="sm"
              onClick={() => setVerifyModalOpen(false)}
            >
              Cancel
            </Button>
            <Button
              type="submit"
              variant="primary"
              size="sm"
              isLoading={isUpdatingDoc}
            >
              Save Verification
            </Button>
          </div>
        </form>
      </Modal>
    </div>
  );
};

export default StaffClaimReviewPage;
