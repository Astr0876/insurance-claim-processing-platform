import React from 'react';
import { Link } from 'react-router-dom';
import { Shield, FileCheck, CheckCircle2, AlertTriangle, ArrowRight, Upload, Search, BarChart3, Lock } from 'lucide-react';

const HowItWorksPage = () => {
  const steps = [
    {
      num: '01',
      title: 'Claim Submission & Intake',
      actor: 'Customer (Policyholder)',
      desc: 'The customer logs in and chooses an active insurance policy. They submit incident date, location, loss description, claimed amount, and upload mandatory receipts, repair estimates, or police FIR reports.',
      highlight: 'Generates a unique claim identifier (e.g. CLM-2026-1042) and initiates initial status tracking.'
    },
    {
      num: '02',
      title: 'Automated Fraud Risk Evaluation',
      actor: 'System Fraud Engine',
      desc: 'The deterministic explainable engine scans the claim across 7 dimensions: Coverage Ratio (>85%), Policy Velocity (<30 days from inception), Historical Claim Frequency (2+ in 6 months), Missing Documents, and Vocabulary Anomalies.',
      highlight: 'Computes Fraud Risk Score (0-100%). If Score ≥ 65%, automatically routes to the Fraud Investigation queue.'
    },
    {
      num: '03',
      title: 'Document Forensic Verification',
      actor: 'Claims Processor',
      desc: 'Authorized insurance staff inspects each uploaded document. They verify invoice tax IDs, doctor credentials, hospital stamps, or police signatures. Staff marks each document as Verified, Rejected, or Needs Review.',
      highlight: 'System policy prevents claim approval until all supporting documents are verified.'
    },
    {
      num: '04',
      title: 'Special Investigation Unit (SIU) Review',
      actor: 'Fraud Investigation Officer',
      desc: 'If flagged suspicious, a Fraud Officer reviews the triggered rule breakdown, conducts field or telematics audits, records investigation notes, and renders an investigation finding (Cleared or Confirmed Fraud).',
      highlight: 'If cleared, forwarded back for approval; if confirmed fraud, claim is immediately rejected.'
    },
    {
      num: '05',
      title: 'Final Adjudication & Payout Settlement',
      actor: 'Insurance Staff / Administrator',
      desc: 'With documents verified and fraud clearance obtained, the processor approves the final reimbursement payout or enters a rejection justification. The customer is notified and claim status is finalized.',
      highlight: 'Full immutable audit log entry is saved with timestamp, actor ID, and decision metadata.'
    }
  ];

  return (
    <div className="py-16 px-4 sm:px-6 lg:px-8 max-w-5xl mx-auto">
      <div className="text-center max-w-2xl mx-auto mb-16">
        <span className="text-xs font-bold tracking-wider uppercase text-indigo-600 bg-indigo-50 px-3 py-1 rounded-full border border-indigo-200">
          Architecture & Workflow
        </span>
        <h1 className="text-3xl sm:text-4xl font-extrabold text-slate-950 mt-4 tracking-tight">
          How the Adjudication Engine Works
        </h1>
        <p className="text-sm text-slate-600 mt-2">
          An automated, multi-stakeholder workflow connecting customers, processors, and investigators.
        </p>
      </div>

      <div className="space-y-8">
        {steps.map((s, idx) => (
          <div key={s.num} className="bg-white rounded-2xl p-6 sm:p-8 border border-slate-200 shadow-sm relative overflow-hidden flex flex-col md:flex-row gap-6 items-start">
            <div className="w-16 h-16 rounded-2xl bg-indigo-50 border border-indigo-100 flex items-center justify-center font-black text-2xl text-indigo-600 font-mono shrink-0">
              {s.num}
            </div>
            <div className="flex-1">
              <div className="flex flex-wrap items-center gap-3 mb-1.5">
                <h3 className="text-lg font-bold text-slate-900">{s.title}</h3>
                <span className="text-xs font-semibold px-2.5 py-0.5 rounded-full bg-slate-100 text-slate-700 border border-slate-200">
                  {s.actor}
                </span>
              </div>
              <p className="text-sm text-slate-600 leading-relaxed mb-3">{s.desc}</p>
              <div className="p-3 bg-indigo-50/50 rounded-xl border border-indigo-100/80 text-xs text-indigo-900 font-medium flex items-center gap-2">
                <CheckCircle2 className="w-4 h-4 text-indigo-600 shrink-0" />
                <span>{s.highlight}</span>
              </div>
            </div>
          </div>
        ))}
      </div>

      <div className="mt-14 text-center">
        <Link
          to="/login"
          className="inline-flex items-center gap-2 px-6 py-3 rounded-xl font-bold text-sm text-white bg-indigo-600 hover:bg-indigo-700 shadow-lg shadow-indigo-100 transition active:scale-95"
        >
          <span>Launch Demo & Test Workflow</span>
          <ArrowRight className="w-4 h-4" />
        </Link>
      </div>
    </div>
  );
};

export default HowItWorksPage;
