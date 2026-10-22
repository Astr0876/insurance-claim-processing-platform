import React from 'react';
import { CheckCircle2, Clock, AlertTriangle, XCircle, ShieldCheck } from 'lucide-react';

export const ClaimProgressTimeline = ({ status, fraudLevel, hasDocs, isDocsVerified }) => {
  // Steps in the claim lifecycle:
  // 1: Submitted
  // 2: Documents Verified
  // 3: Fraud Analysis
  // 4: Staff Review / SIU
  // 5: Decision (Approved / Rejected)

  let currentStep = 1;
  let isRejected = status === 'REJECTED';
  let isApproved = status === 'APPROVED';

  if (status === 'SUBMITTED') {
    currentStep = 1;
  } else if (status === 'DOCS_PENDING') {
    currentStep = 1;
  } else if (status === 'DOCS_VERIFIED') {
    currentStep = 3;
  } else if (status === 'UNDER_REVIEW') {
    currentStep = 4;
  } else if (status === 'INVESTIGATION_REQUIRED' || status === 'INVESTIGATION_IN_PROGRESS') {
    currentStep = 4;
  } else if (isApproved || isRejected) {
    currentStep = 5;
  }

  const steps = [
    {
      id: 1,
      name: 'Submitted',
      description: 'Claim registered in portal'
    },
    {
      id: 2,
      name: 'Document Check',
      description: isDocsVerified ? 'All documents verified' : (hasDocs ? 'Verification pending' : 'Awaiting uploads')
    },
    {
      id: 3,
      name: 'Fraud Analysis',
      description: fraudLevel === 'HIGH' ? 'Flagged for SIU review' : 'Underwriting scan passed'
    },
    {
      id: 4,
      name: 'Adjudication',
      description: status === 'INVESTIGATION_REQUIRED' ? 'SIU Investigation' : 'Staff reviewing claim'
    },
    {
      id: 5,
      name: isRejected ? 'Rejected' : (isApproved ? 'Approved' : 'Final Settlement'),
      description: isRejected ? 'Claim denied' : (isApproved ? 'Settlement issued' : 'Pending decision')
    }
  ];

  return (
    <div className="w-full py-4">
      <div className="relative flex items-center justify-between">
        {/* Continuous background track line */}
        <div className="absolute left-6 right-6 top-5 -translate-y-1/2 h-1 bg-slate-200 z-0" />

        {/* Dynamic active track line */}
        <div
          className={`absolute left-6 top-5 -translate-y-1/2 h-1 z-0 transition-all duration-500 ${
            isRejected ? 'bg-rose-500' : 'bg-indigo-600'
          }`}
          style={{
            width: `calc(${((Math.min(currentStep, 5) - 1) / 4) * 100}% - 48px)`
          }}
        />

        {steps.map((step) => {
          const isCompleted = step.id < currentStep || (step.id === 5 && (isApproved || isRejected));
          const isCurrent = step.id === currentStep && !(isApproved || isRejected);

          return (
            <div key={step.id} className="relative z-10 flex flex-col items-center text-center">
              <div
                className={`flex items-center justify-center w-10 h-10 rounded-full border-2 transition-all duration-300 ${
                  step.id === 5 && isRejected
                    ? 'bg-rose-600 border-rose-600 text-white shadow-lg shadow-rose-200'
                    : isCompleted
                    ? 'bg-indigo-600 border-indigo-600 text-white shadow-md shadow-indigo-100'
                    : isCurrent
                    ? 'bg-white border-indigo-600 text-indigo-600 ring-4 ring-indigo-50 shadow-sm'
                    : 'bg-white border-slate-300 text-slate-400'
                }`}
              >
                {step.id === 5 && isRejected ? (
                  <XCircle className="w-5 h-5" />
                ) : isCompleted ? (
                  <CheckCircle2 className="w-5 h-5" />
                ) : isCurrent ? (
                  <Clock className="w-5 h-5 animate-pulse" />
                ) : (
                  <span className="text-xs font-semibold">{step.id}</span>
                )}
              </div>
              <div className="mt-3">
                <span
                  className={`block text-xs font-semibold ${
                    step.id === 5 && isRejected
                      ? 'text-rose-600'
                      : isCompleted || isCurrent
                      ? 'text-slate-900'
                      : 'text-slate-400'
                  }`}
                >
                  {step.name}
                </span>
                <span className="hidden sm:block text-[11px] text-slate-500 max-w-[110px] mt-0.5 leading-tight">
                  {step.description}
                </span>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
};

export const StatusHistoryTimeline = ({ history = [] }) => {
  if (!history || history.length === 0) {
    return <p className="text-sm text-slate-500 italic">No status transitions recorded yet.</p>;
  }

  return (
    <div className="relative pl-6 space-y-6 before:absolute before:left-2 before:top-2 before:bottom-2 before:w-0.5 before:bg-slate-200">
      {history.map((item, idx) => (
        <div key={item.id || idx} className="relative flex items-start gap-4">
          <div className="absolute -left-6 top-1 w-4 h-4 rounded-full bg-white border-2 border-indigo-600 ring-2 ring-white" />
          <div className="flex-1 bg-slate-50 rounded-lg p-3 border border-slate-200/60">
            <div className="flex flex-wrap items-center justify-between gap-2">
              <span className="text-xs font-bold text-slate-800">
                {item.from_status ? `${item.from_status} → ` : ''}{item.to_status}
              </span>
              <span className="text-[11px] text-slate-400 font-mono">
                {new Date(item.created_at).toLocaleString()}
              </span>
            </div>
            {item.notes && (
              <p className="text-xs text-slate-600 mt-1">{item.notes}</p>
            )}
            <div className="mt-2 text-[11px] text-slate-400">
              Updated by: <span className="font-medium text-slate-600">{item.changed_by_name || 'System Engine'}</span>
              {item.changed_by_role && (
                <span className="ml-1 px-1.5 py-0.2 rounded bg-slate-200 text-slate-600 font-mono text-[10px]">
                  {item.changed_by_role}
                </span>
              )}
            </div>
          </div>
        </div>
      ))}
    </div>
  );
};
