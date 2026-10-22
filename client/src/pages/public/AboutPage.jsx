import React from 'react';
import { Shield, BookOpen, CheckCircle2, User, Award, Layers } from 'lucide-react';

const AboutPage = () => {
  return (
    <div className="py-16 px-4 sm:px-6 lg:px-8 max-w-4xl mx-auto">
      <div className="text-center max-w-2xl mx-auto mb-14">
        <span className="text-xs font-bold tracking-wider uppercase text-indigo-600 bg-indigo-50 px-3 py-1 rounded-full border border-indigo-200">
          Academic Project Case Study
        </span>
        <h1 className="text-3xl sm:text-4xl font-extrabold text-slate-950 mt-4 tracking-tight">
          Insurance Claim Processing & Fraud Detection Platform
        </h1>
        <p className="text-sm text-slate-600 mt-2">
          Course: Software Engineering Lab • Academic Year 2026
        </p>
      </div>

      <div className="bg-white rounded-2xl p-8 border border-slate-200/90 shadow-sm space-y-6">
        <div>
          <h2 className="text-lg font-bold text-slate-900 mb-2">Project Overview</h2>
          <p className="text-xs sm:text-sm text-slate-600 leading-relaxed">
            The platform automates the traditional manual insurance claim intake and settlement lifecycle. By coupling web-based claim submission with digital document verification, explainable AI fraud detection, and role-based adjudication, the system reduces settlement delays from weeks to days while preventing fraudulent insurance payouts.
          </p>
        </div>

        <div className="pt-4 border-t border-slate-100">
          <h2 className="text-lg font-bold text-slate-900 mb-3">Project Authors & Team</h2>
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div className="p-4 rounded-xl bg-slate-50 border border-slate-200/80 flex items-center gap-3">
              <div className="w-10 h-10 rounded-full bg-indigo-600 text-white flex items-center justify-center font-bold text-sm">
                YP
              </div>
              <div>
                <h4 className="text-xs font-bold text-slate-900">Yash Patel</h4>
                <p className="text-xs text-slate-500 font-mono">Roll No: 2024300162</p>
                <span className="text-[10px] text-indigo-600 font-semibold">Lead Developer & Systems Architect</span>
              </div>
            </div>

            <div className="p-4 rounded-xl bg-slate-50 border border-slate-200/80 flex items-center gap-3">
              <div className="w-10 h-10 rounded-full bg-blue-600 text-white flex items-center justify-center font-bold text-sm">
                RP
              </div>
              <div>
                <h4 className="text-xs font-bold text-slate-900">Rudra Patel</h4>
                <p className="text-xs text-slate-500 font-mono">Roll No: 2024300163</p>
                <span className="text-[10px] text-blue-600 font-semibold">Requirements & Security Lead</span>
              </div>
            </div>
          </div>
        </div>

        <div className="pt-4 border-t border-slate-100">
          <h2 className="text-lg font-bold text-slate-900 mb-3">Requirements Traceability Matrix</h2>
          <div className="space-y-2 text-xs">
            {[
              { id: 'FR-01', name: 'User Registration & Secure Login', status: 'Implemented (bcrypt + JWT + RBAC)' },
              { id: 'FR-02', name: 'Online Claim Submission & ID Generation', status: 'Implemented (5-step wizard with CLM code)' },
              { id: 'FR-03', name: 'Document Upload & Verification', status: 'Implemented (Multer uploads + Staff audit)' },
              { id: 'FR-04', name: 'Automated Fraud Detection & Scoring', status: 'Implemented (7-factor deterministic engine)' },
              { id: 'FR-05', name: 'Claim Processing & Adjudication', status: 'Implemented (Staff approvals & payout checks)' },
              { id: 'FR-06', name: 'Claim Status Tracking & Timeline', status: 'Implemented (Real-time animated visual tracking)' },
            ].map(req => (
              <div key={req.id} className="flex items-center justify-between p-2.5 rounded-lg bg-slate-50 border border-slate-200/60">
                <div className="flex items-center gap-2">
                  <span className="font-mono font-bold text-indigo-600">{req.id}</span>
                  <span className="font-medium text-slate-700">{req.name}</span>
                </div>
                <span className="text-[11px] font-semibold text-emerald-600 flex items-center gap-1">
                  <CheckCircle2 className="w-3.5 h-3.5" />
                  {req.status}
                </span>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
};

export default AboutPage;
