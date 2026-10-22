import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { policyService, claimService } from '../../services/api';
import {
  Shield,
  FileText,
  Upload,
  CheckCircle2,
  AlertCircle,
  ArrowRight,
  ArrowLeft,
  X,
  FileCheck,
  Calendar,
  MapPin,
  DollarSign,
  AlertTriangle
} from 'lucide-react';
import Button from '../../components/common/Button';

const STEPS = [
  { id: 1, name: 'Select Policy' },
  { id: 2, name: 'Incident Details' },
  { id: 3, name: 'Claim Amount' },
  { id: 4, name: 'Supporting Docs' },
  { id: 5, name: 'Review & Submit' }
];

const SubmitClaimPage = () => {
  const navigate = useNavigate();

  const [currentStep, setCurrentStep] = useState(1);
  const [policies, setPolicies] = useState([]);
  const [isLoadingPolicies, setIsLoadingPolicies] = useState(true);

  // Form State
  const [selectedPolicyId, setSelectedPolicyId] = useState('');
  const [incidentDate, setIncidentDate] = useState(new Date().toISOString().split('T')[0]);
  const [incidentLocation, setIncidentLocation] = useState('');
  const [description, setDescription] = useState('');
  const [claimType, setClaimType] = useState('AUTO');
  const [claimAmount, setClaimAmount] = useState('');
  const [documentType, setDocumentType] = useState('Repair Estimate');
  const [selectedFiles, setSelectedFiles] = useState([]);
  const [certified, setCertified] = useState(false);

  // Submission State
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState('');
  const [submissionSuccess, setSubmissionSuccess] = useState(null);

  useEffect(() => {
    const fetchPolicies = async () => {
      try {
        const res = await policyService.getPolicies();
        if (res.data?.success) {
          const list = res.data.policies || [];
          setPolicies(list);
          if (list.length > 0) {
            setSelectedPolicyId(list[0].id);
            setClaimType(list[0].policy_type);
          }
        }
      } catch (err) {
        console.error('Failed to load policies:', err);
      } finally {
        setIsLoadingPolicies(false);
      }
    };

    fetchPolicies();
  }, []);

  const selectedPolicy = policies.find(p => p.id === Number(selectedPolicyId));

  const handlePolicySelect = (policy) => {
    setSelectedPolicyId(policy.id);
    setClaimType(policy.policy_type);
  };

  const handleFileChange = (e) => {
    const files = Array.from(e.target.files);
    setSelectedFiles(prev => [...prev, ...files]);
  };

  const handleRemoveFile = (index) => {
    setSelectedFiles(prev => prev.filter((_, i) => i !== index));
  };

  // Validation per step
  const validateStep = () => {
    setError('');
    if (currentStep === 1) {
      if (!selectedPolicyId) {
        setError('Please select an active policy.');
        return false;
      }
    } else if (currentStep === 2) {
      if (!incidentDate) {
        setError('Please specify the incident date.');
        return false;
      }
      if (!incidentLocation.trim()) {
        setError('Please specify the incident location.');
        return false;
      }
      if (description.trim().length < 15) {
        setError('Please provide a detailed description (at least 15 characters).');
        return false;
      }
    } else if (currentStep === 3) {
      const amount = parseFloat(claimAmount);
      if (isNaN(amount) || amount <= 0) {
        setError('Please enter a valid claim amount.');
        return false;
      }
      if (selectedPolicy && amount > parseFloat(selectedPolicy.coverage_amount)) {
        setError(`Claim amount exceeds policy coverage limit of $${parseFloat(selectedPolicy.coverage_amount).toLocaleString()}.`);
        return false;
      }
    } else if (currentStep === 5) {
      if (!certified) {
        setError('You must certify that the information provided is true and accurate.');
        return false;
      }
    }
    return true;
  };

  const handleNext = () => {
    if (validateStep()) {
      setCurrentStep(prev => Math.min(prev + 1, 5));
    }
  };

  const handleBack = () => {
    setError('');
    setCurrentStep(prev => Math.max(prev - 1, 1));
  };

  const handleSubmitClaim = async (e) => {
    e.preventDefault();
    if (!validateStep()) return;

    setIsSubmitting(true);
    setError('');

    try {
      const formData = new FormData();
      formData.append('policyId', selectedPolicyId);
      formData.append('claimType', claimType);
      formData.append('incidentDate', incidentDate);
      formData.append('incidentLocation', incidentLocation);
      formData.append('claimAmount', claimAmount);
      formData.append('description', description);
      formData.append('documentType', documentType);

      selectedFiles.forEach((file) => {
        formData.append('documents', file);
      });

      const res = await claimService.createClaim(formData);
      if (res.data?.success) {
        setSubmissionSuccess(res.data.claim);
      }
    } catch (err) {
      setError(err.response?.data?.message || err.message || 'Claim submission failed.');
    } finally {
      setIsSubmitting(false);
    }
  };

  // SUCCESS SCREEN
  if (submissionSuccess) {
    return (
      <div className="max-w-2xl mx-auto py-12 px-4 sm:px-6">
        <div className="bg-white rounded-3xl p-8 sm:p-10 border border-slate-200/90 shadow-xl text-center space-y-6">
          <div className="w-16 h-16 rounded-2xl bg-emerald-100 text-emerald-600 flex items-center justify-center mx-auto shadow-md shadow-emerald-100">
            <CheckCircle2 className="w-9 h-9" />
          </div>

          <div>
            <span className="text-xs font-bold uppercase tracking-wider text-emerald-600 bg-emerald-50 px-3 py-1 rounded-full border border-emerald-200">
              Claim Registered Successfully
            </span>
            <h2 className="text-2xl sm:text-3xl font-extrabold text-slate-900 mt-3">
              Claim ID: <span className="font-mono text-indigo-600">{submissionSuccess.claim_id}</span>
            </h2>
            <p className="text-xs sm:text-sm text-slate-500 mt-2 max-w-md mx-auto leading-relaxed">
              Your claim for <strong>${parseFloat(submissionSuccess.claim_amount).toLocaleString()}</strong> has been submitted into the adjudication system.
            </p>
          </div>

          {/* Automated System Actions Card */}
          <div className="p-5 rounded-2xl bg-slate-50 border border-slate-200/80 text-left space-y-3">
            <div className="text-xs font-bold text-slate-800 uppercase tracking-wider flex items-center gap-2">
              <Shield className="w-4 h-4 text-indigo-600" />
              <span>Automated Backend Workflows Triggered</span>
            </div>
            <ul className="space-y-2 text-xs text-slate-600">
              <li className="flex items-center gap-2 text-emerald-700">
                <CheckCircle2 className="w-4 h-4 text-emerald-600 shrink-0" />
                <span>Deterministic AI Fraud Risk Engine executed on claim parameters</span>
              </li>
              <li className="flex items-center gap-2 text-indigo-700">
                <CheckCircle2 className="w-4 h-4 text-indigo-600 shrink-0" />
                <span>Document verification ticket created for Claims Processing queue</span>
              </li>
              <li className="flex items-center gap-2 text-slate-700">
                <CheckCircle2 className="w-4 h-4 text-slate-600 shrink-0" />
                <span>Status history initialized and customer email notification dispatched</span>
              </li>
            </ul>
          </div>

          <div className="flex flex-col sm:flex-row items-center justify-center gap-3 pt-2">
            <Button
              onClick={() => navigate(`/customer/claims/${submissionSuccess.id}`)}
              size="lg"
              variant="primary"
              icon={ArrowRight}
            >
              Track Claim Status
            </Button>
            <Button
              onClick={() => navigate('/customer/dashboard')}
              size="lg"
              variant="outline"
            >
              Return to Dashboard
            </Button>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="max-w-3xl mx-auto py-6">
      {/* Stepper Header */}
      <div className="mb-8">
        <h2 className="text-2xl font-extrabold text-slate-900 tracking-tight">
          Submit New Insurance Claim
        </h2>
        <p className="text-xs text-slate-500 mt-1">
          Complete the 5-step intake wizard to submit your claim for automated verification.
        </p>

        {/* Stepper Progress */}
        <div className="mt-6 flex items-center justify-between relative">
          <div className="absolute left-4 right-4 top-4 -translate-y-1/2 h-0.5 bg-slate-200 -z-0" />
          <div
            className="absolute left-4 top-4 -translate-y-1/2 h-0.5 bg-indigo-600 -z-0 transition-all duration-300"
            style={{ width: `calc(${((currentStep - 1) / 4) * 100}% - 32px)` }}
          />

          {STEPS.map((s) => {
            const isCompleted = s.id < currentStep;
            const isCurrent = s.id === currentStep;

            return (
              <div key={s.id} className="relative z-10 flex flex-col items-center">
                <div
                  className={`w-8 h-8 rounded-full flex items-center justify-center text-xs font-bold transition-all ${
                    isCompleted
                      ? 'bg-indigo-600 text-white shadow'
                      : isCurrent
                      ? 'bg-white border-2 border-indigo-600 text-indigo-600 ring-4 ring-indigo-50'
                      : 'bg-white border border-slate-300 text-slate-400'
                  }`}
                >
                  {isCompleted ? <CheckCircle2 className="w-4 h-4" /> : s.id}
                </div>
                <span className={`text-[11px] font-medium mt-1.5 hidden sm:block ${
                  isCurrent ? 'text-indigo-600 font-bold' : isCompleted ? 'text-slate-800' : 'text-slate-400'
                }`}>
                  {s.name}
                </span>
              </div>
            );
          })}
        </div>
      </div>

      {/* Main Step Form Container */}
      <div className="bg-white rounded-2xl p-6 sm:p-8 border border-slate-200/90 shadow-sm">
        {error && (
          <div className="mb-6 p-3 rounded-xl bg-rose-50 border border-rose-200 text-rose-700 text-xs flex items-center gap-2">
            <AlertCircle className="w-4 h-4 shrink-0 text-rose-600" />
            <span>{error}</span>
          </div>
        )}

        {/* STEP 1: SELECT POLICY */}
        {currentStep === 1 && (
          <div className="space-y-4">
            <div>
              <h3 className="text-sm font-bold text-slate-900">Step 1: Choose Policy for this Claim</h3>
              <p className="text-xs text-slate-500 mt-0.5">Select from your registered active policies</p>
            </div>

            {isLoadingPolicies ? (
              <div className="py-6 text-center text-xs text-slate-400">Loading your policies...</div>
            ) : policies.length === 0 ? (
              <div className="p-6 text-center text-xs text-slate-500 bg-slate-50 rounded-xl">
                No active policies found. Please contact administration.
              </div>
            ) : (
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3.5 pt-2">
                {policies.map((p) => {
                  const isSelected = String(selectedPolicyId) === String(p.id);
                  return (
                    <div
                      key={p.id}
                      onClick={() => handlePolicySelect(p)}
                      className={`p-4 rounded-xl border-2 cursor-pointer transition-all ${
                        isSelected
                          ? 'border-indigo-600 bg-indigo-50/40 shadow-sm'
                          : 'border-slate-200 hover:border-slate-300 bg-white'
                      }`}
                    >
                      <div className="flex items-center justify-between">
                        <span className="text-xs font-bold text-slate-900">{p.policy_type} Policy</span>
                        <div className={`w-4 h-4 rounded-full border flex items-center justify-center ${
                          isSelected ? 'border-indigo-600 bg-indigo-600 text-white' : 'border-slate-300'
                        }`}>
                          {isSelected && <div className="w-1.5 h-1.5 rounded-full bg-white" />}
                        </div>
                      </div>
                      <div className="text-[11px] font-mono text-slate-500 mt-1">{p.policy_number}</div>
                      <div className="mt-3 pt-2 border-t border-slate-200/60 flex items-center justify-between text-xs">
                        <span className="text-slate-500">Coverage: <strong className="text-slate-800">${parseFloat(p.coverage_amount).toLocaleString()}</strong></span>
                        <span className="text-slate-500">Deductible: <strong className="text-slate-800">${parseFloat(p.deductible).toLocaleString()}</strong></span>
                      </div>
                    </div>
                  );
                })}
              </div>
            )}
          </div>
        )}

        {/* STEP 2: INCIDENT DETAILS */}
        {currentStep === 2 && (
          <div className="space-y-4">
            <div>
              <h3 className="text-sm font-bold text-slate-900">Step 2: Incident Details</h3>
              <p className="text-xs text-slate-500 mt-0.5">When, where, and what occurred</p>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div>
                <label className="block text-xs font-semibold text-slate-700 mb-1">
                  Incident Date
                </label>
                <div className="relative">
                  <Calendar className="w-4 h-4 text-slate-400 absolute left-3 top-3 pointer-events-none" />
                  <input
                    type="date"
                    required
                    value={incidentDate}
                    max={new Date().toISOString().split('T')[0]}
                    onChange={(e) => setIncidentDate(e.target.value)}
                    className="w-full pl-9 pr-3.5 py-2 text-xs rounded-xl border border-slate-300 focus:outline-none focus:ring-2 focus:ring-indigo-500"
                  />
                </div>
              </div>

              <div>
                <label className="block text-xs font-semibold text-slate-700 mb-1">
                  Incident Location
                </label>
                <div className="relative">
                  <MapPin className="w-4 h-4 text-slate-400 absolute left-3 top-3 pointer-events-none" />
                  <input
                    type="text"
                    required
                    value={incidentLocation}
                    onChange={(e) => setIncidentLocation(e.target.value)}
                    placeholder="e.g. 5th Ave & Pine St, Seattle, WA"
                    className="w-full pl-9 pr-3.5 py-2 text-xs rounded-xl border border-slate-300 focus:outline-none focus:ring-2 focus:ring-indigo-500"
                  />
                </div>
              </div>
            </div>

            <div>
              <label className="block text-xs font-semibold text-slate-700 mb-1">
                Description of Loss / Event
              </label>
              <textarea
                rows={4}
                required
                value={description}
                onChange={(e) => setDescription(e.target.value)}
                placeholder="Provide a factual summary of what happened, damages sustained, and any third parties involved..."
                className="w-full p-3 text-xs rounded-xl border border-slate-300 focus:outline-none focus:ring-2 focus:ring-indigo-500 leading-relaxed"
              />
              <p className="text-[11px] text-slate-400 mt-1">
                Detailed descriptions reduce verification turnaround and expedite fraud clearance.
              </p>
            </div>
          </div>
        )}

        {/* STEP 3: CLAIM AMOUNT & LINE */}
        {currentStep === 3 && (
          <div className="space-y-4">
            <div>
              <h3 className="text-sm font-bold text-slate-900">Step 3: Claim Amount & Type</h3>
              <p className="text-xs text-slate-500 mt-0.5">Specify loss compensation requested</p>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div>
                <label className="block text-xs font-semibold text-slate-700 mb-1">
                  Claim Type / Line
                </label>
                <select
                  value={claimType}
                  onChange={(e) => setClaimType(e.target.value)}
                  className="w-full px-3.5 py-2 text-xs rounded-xl border border-slate-300 bg-white focus:outline-none focus:ring-2 focus:ring-indigo-500"
                >
                  <option value="AUTO">Auto Collision / Damage</option>
                  <option value="HEALTH">Health & Hospitalization</option>
                  <option value="HOME">Homeowners Property Loss</option>
                  <option value="PROPERTY">Commercial Property Damage</option>
                </select>
              </div>

              <div>
                <label className="block text-xs font-semibold text-slate-700 mb-1">
                  Total Claim Amount ($ USD)
                </label>
                <div className="relative">
                  <DollarSign className="w-4 h-4 text-slate-400 absolute left-3 top-3 pointer-events-none" />
                  <input
                    type="number"
                    step="0.01"
                    min="1"
                    required
                    value={claimAmount}
                    onChange={(e) => setClaimAmount(e.target.value)}
                    placeholder="e.g. 4500.00"
                    className="w-full pl-9 pr-3.5 py-2 text-xs rounded-xl border border-slate-300 focus:outline-none focus:ring-2 focus:ring-indigo-500"
                  />
                </div>
              </div>
            </div>

            {selectedPolicy && (
              <div className="p-3.5 rounded-xl bg-indigo-50/60 border border-indigo-100 flex items-center justify-between text-xs">
                <span className="text-indigo-900">Selected Policy Limit:</span>
                <span className="font-mono font-bold text-indigo-900">
                  ${parseFloat(selectedPolicy.coverage_amount).toLocaleString()}
                </span>
              </div>
            )}
          </div>
        )}

        {/* STEP 4: SUPPORTING DOCUMENTS */}
        {currentStep === 4 && (
          <div className="space-y-4">
            <div>
              <h3 className="text-sm font-bold text-slate-900">Step 4: Attach Supporting Documents</h3>
              <p className="text-xs text-slate-500 mt-0.5">Upload invoices, repair bills, doctor reports, or police records</p>
            </div>

            <div>
              <label className="block text-xs font-semibold text-slate-700 mb-1">
                Document Category
              </label>
              <select
                value={documentType}
                onChange={(e) => setDocumentType(e.target.value)}
                className="w-full px-3.5 py-2 text-xs rounded-xl border border-slate-300 bg-white focus:outline-none focus:ring-2 focus:ring-indigo-500 mb-3"
              >
                <option value="Repair Estimate">Repair Estimate / Body Shop Bill</option>
                <option value="Police Report">Police Incident / FIR Report</option>
                <option value="Medical Bill">Hospital / Physician Invoice</option>
                <option value="Damage Photo">Damage Photograph</option>
                <option value="Payment Receipt">Official Payment Receipt</option>
              </select>
            </div>

            {/* Upload Drop Zone */}
            <div className="border-2 border-dashed border-slate-300 hover:border-indigo-400 rounded-2xl p-6 text-center cursor-pointer transition bg-slate-50/50">
              <input
                type="file"
                multiple
                id="claimFileInput"
                onChange={handleFileChange}
                accept=".pdf,.png,.jpg,.jpeg,.doc,.docx"
                className="hidden"
              />
              <label htmlFor="claimFileInput" className="cursor-pointer block">
                <Upload className="w-8 h-8 text-indigo-500 mx-auto mb-2" />
                <span className="text-xs font-semibold text-slate-800 block">
                  Click to select files or drag and drop
                </span>
                <span className="text-[11px] text-slate-400 mt-0.5 block">
                  Supports PDF, JPG, PNG, DOCX up to 10MB
                </span>
              </label>
            </div>

            {/* Selected Files List */}
            {selectedFiles.length > 0 && (
              <div className="space-y-2 pt-2">
                <span className="text-xs font-semibold text-slate-700">Attached Documents ({selectedFiles.length}):</span>
                {selectedFiles.map((file, idx) => (
                  <div key={idx} className="flex items-center justify-between p-2.5 rounded-lg bg-slate-50 border border-slate-200 text-xs">
                    <div className="flex items-center gap-2 truncate">
                      <FileCheck className="w-4 h-4 text-emerald-600 shrink-0" />
                      <span className="font-medium text-slate-800 truncate">{file.name}</span>
                      <span className="text-[10px] text-slate-400 font-mono">
                        ({(file.size / 1024).toFixed(0)} KB)
                      </span>
                    </div>
                    <button
                      type="button"
                      onClick={() => handleRemoveFile(idx)}
                      className="text-slate-400 hover:text-rose-600 p-1"
                    >
                      <X className="w-4 h-4" />
                    </button>
                  </div>
                ))}
              </div>
            )}
          </div>
        )}

        {/* STEP 5: REVIEW & SUBMIT */}
        {currentStep === 5 && (
          <div className="space-y-5">
            <div>
              <h3 className="text-sm font-bold text-slate-900">Step 5: Review & Certify Claim</h3>
              <p className="text-xs text-slate-500 mt-0.5">Please verify all claim information prior to submission</p>
            </div>

            <div className="p-4 rounded-xl bg-slate-50 border border-slate-200 space-y-3 text-xs">
              <div className="grid grid-cols-2 gap-2">
                <div>
                  <span className="text-slate-400 block text-[11px]">Policy:</span>
                  <span className="font-mono font-bold text-slate-900">{selectedPolicy?.policy_number}</span>
                </div>
                <div>
                  <span className="text-slate-400 block text-[11px]">Category:</span>
                  <span className="font-bold text-slate-900">{claimType}</span>
                </div>
                <div>
                  <span className="text-slate-400 block text-[11px]">Incident Date:</span>
                  <span className="font-medium text-slate-800">{incidentDate}</span>
                </div>
                <div>
                  <span className="text-slate-400 block text-[11px]">Location:</span>
                  <span className="font-medium text-slate-800 truncate block">{incidentLocation}</span>
                </div>
                <div className="col-span-2">
                  <span className="text-slate-400 block text-[11px]">Claim Amount:</span>
                  <span className="text-lg font-black text-indigo-600 font-mono">
                    ${parseFloat(claimAmount).toLocaleString()}
                  </span>
                </div>
                <div className="col-span-2">
                  <span className="text-slate-400 block text-[11px]">Description:</span>
                  <p className="text-slate-700 mt-0.5 leading-relaxed bg-white p-2.5 rounded border border-slate-200/60">
                    {description}
                  </p>
                </div>
                <div className="col-span-2">
                  <span className="text-slate-400 block text-[11px]">Attached Documents:</span>
                  <span className="font-semibold text-slate-800">
                    {selectedFiles.length > 0 ? `${selectedFiles.length} file(s) ready for upload` : 'None attached'}
                  </span>
                </div>
              </div>
            </div>

            <div className="flex items-start gap-2.5 pt-2">
              <input
                type="checkbox"
                id="certifyCheck"
                checked={certified}
                onChange={(e) => setCertified(e.target.checked)}
                className="mt-0.5 w-4 h-4 rounded text-indigo-600 focus:ring-indigo-500 border-slate-300"
              />
              <label htmlFor="certifyCheck" className="text-xs text-slate-600 leading-relaxed cursor-pointer">
                I hereby declare and certify under penalty of policy voidance that the incident information and expenses submitted above represent genuine losses incurred.
              </label>
            </div>
          </div>
        )}

        {/* Stepper Navigation Buttons */}
        <div className="mt-8 pt-5 border-t border-slate-100 flex items-center justify-between">
          {currentStep > 1 ? (
            <Button
              type="button"
              variant="outline"
              size="md"
              onClick={handleBack}
              icon={ArrowLeft}
            >
              Previous
            </Button>
          ) : (
            <div />
          )}

          {currentStep < 5 ? (
            <Button
              type="button"
              variant="primary"
              size="md"
              onClick={handleNext}
            >
              Continue Next →
            </Button>
          ) : (
            <Button
              type="button"
              variant="primary"
              size="md"
              isLoading={isSubmitting}
              onClick={handleSubmitClaim}
              icon={CheckCircle2}
            >
              Submit Claim Now
            </Button>
          )}
        </div>
      </div>
    </div>
  );
};

export default SubmitClaimPage;
