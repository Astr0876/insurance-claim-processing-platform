import React, { useState, useEffect } from 'react';
import { useParams, Link } from 'react-router-dom';
import { claimService, documentService } from '../../services/api';
import {
  FileText,
  Shield,
  ArrowLeft,
  Upload,
  Download,
  CheckCircle2,
  AlertTriangle,
  Clock,
  PlusCircle,
  FileCheck
} from 'lucide-react';
import { StatusBadge, DocumentStatusBadge } from '../../components/common/Badge';
import { ClaimProgressTimeline, StatusHistoryTimeline } from '../../components/common/Timeline';
import Button from '../../components/common/Button';
import Modal from '../../components/common/Modal';

const CustomerClaimDetailPage = () => {
  const { id } = useParams();
  const [claim, setClaim] = useState(null);
  const [isLoading, setIsLoading] = useState(true);

  // Upload modal state
  const [uploadModalOpen, setUploadModalOpen] = useState(false);
  const [docType, setDocType] = useState('Medical Bill');
  const [filesToUpload, setFilesToUpload] = useState([]);
  const [isUploading, setIsUploading] = useState(false);
  const [uploadError, setUploadError] = useState('');

  const fetchClaimDetails = async () => {
    try {
      const res = await claimService.getClaimById(id);
      if (res.data?.success) {
        setClaim(res.data.claim);
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

  const handleUploadSubmit = async (e) => {
    e.preventDefault();
    if (filesToUpload.length === 0) {
      setUploadError('Please select at least one file to upload.');
      return;
    }

    setIsUploading(true);
    setUploadError('');

    try {
      const formData = new FormData();
      formData.append('documentType', docType);
      filesToUpload.forEach(f => formData.append('documents', f));

      const res = await documentService.upload(claim.id, formData);
      if (res.data?.success) {
        setUploadModalOpen(false);
        setFilesToUpload([]);
        fetchClaimDetails();
      }
    } catch (err) {
      setUploadError(err.response?.data?.message || err.message || 'Failed to upload document.');
    } finally {
      setIsUploading(false);
    }
  };

  if (isLoading) {
    return <div className="py-20 text-center text-xs text-slate-400">Loading claim dossier...</div>;
  }

  if (!claim) {
    return (
      <div className="py-20 text-center">
        <h3 className="text-base font-bold text-slate-800">Claim Not Found</h3>
        <p className="text-xs text-slate-500 mt-1">This claim may not exist or belongs to another user.</p>
        <Link to="/customer/claims" className="inline-block mt-4">
          <Button size="sm">Return to Claims</Button>
        </Link>
      </div>
    );
  }

  const isDocsVerified = claim.verification_status === 'VERIFIED';
  const hasDocs = claim.documents && claim.documents.length > 0;

  return (
    <div className="space-y-8 max-w-5xl mx-auto">
      {/* Back Link & Header */}
      <div>
        <Link
          to="/customer/claims"
          className="text-xs font-semibold text-slate-500 hover:text-indigo-600 inline-flex items-center gap-1.5 mb-3"
        >
          <ArrowLeft className="w-3.5 h-3.5" /> Back to My Claims
        </Link>

        <div className="bg-white rounded-2xl p-6 sm:p-8 border border-slate-200/90 shadow-sm flex flex-col md:flex-row md:items-center justify-between gap-6">
          <div>
            <div className="flex items-center gap-3">
              <h2 className="text-2xl font-black font-mono text-slate-900 tracking-tight">
                {claim.claim_id}
              </h2>
              <StatusBadge status={claim.current_status} />
            </div>
            <p className="text-xs text-slate-500 mt-1">
              Filed on <strong>{new Date(claim.created_at).toLocaleDateString()}</strong> under Policy <strong>{claim.policy_number}</strong> ({claim.claim_type})
            </p>
          </div>

          <div className="flex flex-col sm:flex-row items-start sm:items-center gap-4 border-t sm:border-t-0 sm:border-l border-slate-200 sm:pl-6 pt-4 sm:pt-0">
            <div>
              <span className="text-[11px] font-semibold text-slate-400 block uppercase tracking-wider">
                Claim Amount
              </span>
              <span className="text-2xl font-extrabold text-slate-900 font-mono">
                ${parseFloat(claim.claim_amount).toLocaleString()}
              </span>
            </div>

            {claim.current_status === 'APPROVED' && (
              <div className="pl-4 border-l border-slate-200">
                <span className="text-[11px] font-semibold text-emerald-600 block uppercase tracking-wider">
                  Approved Settlement
                </span>
                <span className="text-2xl font-black text-emerald-600 font-mono">
                  ${parseFloat(claim.payout_amount).toLocaleString()}
                </span>
              </div>
            )}
          </div>
        </div>
      </div>

      {/* Visual Timeline Tracker */}
      <div className="bg-white rounded-2xl p-6 sm:p-8 border border-slate-200/90 shadow-sm">
        <h3 className="text-sm font-bold text-slate-900 mb-1">Claim Adjudication Lifecycle</h3>
        <p className="text-xs text-slate-500 mb-4">
          Real-time progression through underwriting, document checks, and final decision
        </p>

        <ClaimProgressTimeline
          status={claim.current_status}
          fraudLevel={claim.fraud_risk_level}
          hasDocs={hasDocs}
          isDocsVerified={isDocsVerified}
        />
      </div>

      {/* Main Grid: Details & Documents */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        {/* Left Column: Claim Information */}
        <div className="lg:col-span-2 space-y-6">
          {/* Incident Details Card */}
          <div className="bg-white rounded-2xl p-6 border border-slate-200/90 shadow-sm space-y-4">
            <h3 className="text-sm font-bold text-slate-900 pb-3 border-b border-slate-100">
              Incident & Coverage Information
            </h3>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 text-xs">
              <div>
                <span className="text-slate-400 block text-[11px]">Date of Incident</span>
                <span className="font-semibold text-slate-800">{claim.incident_date}</span>
              </div>
              <div>
                <span className="text-slate-400 block text-[11px]">Incident Location</span>
                <span className="font-semibold text-slate-800">{claim.incident_location}</span>
              </div>
              <div>
                <span className="text-slate-400 block text-[11px]">Policy Coverage Limit</span>
                <span className="font-mono font-semibold text-slate-800">
                  ${parseFloat(claim.coverage_amount).toLocaleString()}
                </span>
              </div>
              <div>
                <span className="text-slate-400 block text-[11px]">Policy Deductible</span>
                <span className="font-mono font-semibold text-slate-800">
                  ${parseFloat(claim.deductible).toLocaleString()}
                </span>
              </div>
              <div className="col-span-full">
                <span className="text-slate-400 block text-[11px] mb-1">Incident Description</span>
                <p className="text-slate-700 leading-relaxed bg-slate-50 p-3 rounded-xl border border-slate-200/60">
                  {claim.description}
                </p>
              </div>

              {claim.decision_reason && (
                <div className="col-span-full pt-2">
                  <span className="text-slate-400 block text-[11px] mb-1">Official Decision Notes</span>
                  <div className={`p-3 rounded-xl border text-xs leading-relaxed ${
                    claim.current_status === 'APPROVED'
                      ? 'bg-emerald-50 text-emerald-800 border-emerald-200'
                      : 'bg-rose-50 text-rose-800 border-rose-200'
                  }`}>
                    {claim.decision_reason}
                  </div>
                </div>
              )}
            </div>
          </div>

          {/* Uploaded Documents Card */}
          <div className="bg-white rounded-2xl p-6 border border-slate-200/90 shadow-sm space-y-4">
            <div className="flex items-center justify-between pb-3 border-b border-slate-100">
              <div>
                <h3 className="text-sm font-bold text-slate-900">Supporting Documents ({claim.documents?.length || 0})</h3>
                <p className="text-xs text-slate-500">Invoices, police records, and damage estimates</p>
              </div>
              <Button
                variant="outline"
                size="sm"
                icon={PlusCircle}
                onClick={() => setUploadModalOpen(true)}
              >
                Upload File
              </Button>
            </div>

            {(!claim.documents || claim.documents.length === 0) ? (
              <div className="py-8 text-center bg-slate-50 rounded-xl border border-dashed border-slate-200">
                <FileText className="w-8 h-8 text-slate-300 mx-auto mb-1" />
                <p className="text-xs text-slate-500">No supporting documents uploaded.</p>
                <button
                  type="button"
                  onClick={() => setUploadModalOpen(true)}
                  className="mt-2 text-xs font-semibold text-indigo-600 hover:text-indigo-800"
                >
                  Click here to attach receipts & reports
                </button>
              </div>
            ) : (
              <div className="divide-y divide-slate-100">
                {claim.documents.map((doc) => (
                  <div key={doc.id} className="py-3 flex flex-col sm:flex-row sm:items-center justify-between gap-3">
                    <div className="flex items-start gap-3">
                      <FileCheck className="w-5 h-5 text-indigo-600 shrink-0 mt-0.5" />
                      <div>
                        <span className="font-semibold text-xs text-slate-900 block truncate max-w-sm">
                          {doc.original_name}
                        </span>
                        <div className="flex items-center gap-2 text-[11px] text-slate-400 mt-0.5">
                          <span className="font-medium text-slate-600">{doc.document_type}</span>
                          <span>•</span>
                          <span className="font-mono">{(doc.file_size / 1024).toFixed(0)} KB</span>
                        </div>
                        {doc.verification_notes && (
                          <p className="text-[11px] text-slate-500 italic mt-1">
                            Staff Note: {doc.verification_notes}
                          </p>
                        )}
                      </div>
                    </div>

                    <div className="flex items-center gap-3 shrink-0">
                      <DocumentStatusBadge status={doc.verification_status} />
                      <a
                        href={documentService.downloadUrl(doc.id)}
                        target="_blank"
                        rel="noreferrer"
                        className="p-1.5 rounded-lg border border-slate-200 text-slate-500 hover:text-indigo-600 hover:bg-slate-50 transition"
                        title="Download document"
                      >
                        <Download className="w-4 h-4" />
                      </a>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>

        {/* Right Column: Status Transition History */}
        <div className="bg-white rounded-2xl p-6 border border-slate-200/90 shadow-sm space-y-4">
          <div className="pb-3 border-b border-slate-100">
            <h3 className="text-sm font-bold text-slate-900">Activity & Audit Trail</h3>
            <p className="text-xs text-slate-500">Every state change recorded with timestamp</p>
          </div>

          <StatusHistoryTimeline history={claim.history} />
        </div>
      </div>

      {/* Upload Document Modal */}
      <Modal
        isOpen={uploadModalOpen}
        onClose={() => setUploadModalOpen(false)}
        title="Upload Supporting Document"
        subtitle={`Attach document to claim ${claim.claim_id}`}
      >
        {uploadError && (
          <div className="mb-4 p-2.5 rounded-xl bg-rose-50 border border-rose-200 text-rose-700 text-xs">
            {uploadError}
          </div>
        )}

        <form onSubmit={handleUploadSubmit} className="space-y-4">
          <div>
            <label className="block text-xs font-semibold text-slate-700 mb-1">
              Document Category
            </label>
            <select
              value={docType}
              onChange={(e) => setDocType(e.target.value)}
              className="w-full px-3 py-2 text-xs rounded-xl border border-slate-300 bg-white focus:outline-none focus:ring-2 focus:ring-indigo-500"
            >
              <option value="Medical Bill">Medical Bill / Hospital Invoice</option>
              <option value="Police Report">Police Incident / FIR Report</option>
              <option value="Repair Estimate">Repair Estimate / Mechanics Bill</option>
              <option value="Damage Photo">Damage Photograph</option>
              <option value="Payment Receipt">Proof of Payment</option>
              <option value="Other">Other Verification Document</option>
            </select>
          </div>

          <div>
            <label className="block text-xs font-semibold text-slate-700 mb-1">
              Select File
            </label>
            <input
              type="file"
              required
              multiple
              onChange={(e) => setFilesToUpload(Array.from(e.target.files))}
              accept=".pdf,.png,.jpg,.jpeg,.doc,.docx"
              className="w-full text-xs text-slate-500 file:mr-3 file:py-2 file:px-3 file:rounded-lg file:border-0 file:text-xs file:font-semibold file:bg-indigo-50 file:text-indigo-700 hover:file:bg-indigo-100 cursor-pointer"
            />
          </div>

          <div className="pt-3 flex justify-end gap-2 border-t border-slate-100">
            <Button
              type="button"
              variant="outline"
              size="sm"
              onClick={() => setUploadModalOpen(false)}
            >
              Cancel
            </Button>
            <Button
              type="submit"
              variant="primary"
              size="sm"
              isLoading={isUploading}
              icon={Upload}
            >
              Upload Document
            </Button>
          </div>
        </form>
      </Modal>
    </div>
  );
};

export default CustomerClaimDetailPage;
