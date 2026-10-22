import React from 'react';
import { Shield, Zap, FileText, BarChart3, Lock, Users, Cpu, Clock, CheckCircle } from 'lucide-react';

const FeaturesPage = () => {
  const features = [
    {
      title: 'Explainable AI Fraud Risk Engine',
      icon: Cpu,
      desc: 'Unlike opaque black-box classifiers, our deterministic engine breaks risk down into 7 transparent pillars: financial exposure, inception velocity, historical claim frequency, and linguistic indicators. Every score includes a mathematical explanation.'
    },
    {
      title: 'Digital Document Verification',
      icon: FileText,
      desc: 'Multipart document upload support for police reports, medical bills, and repair estimates. Claims processors can inspect documents, add verification notes, and designate verification statuses.'
    },
    {
      title: 'Real-Time Status Timeline',
      icon: Clock,
      desc: 'Policyholders follow their claim across a live animated timeline with status updates from intake to disbursement, reducing manual customer support inquiries.'
    },
    {
      title: 'Role-Based Access Control (RBAC)',
      icon: Users,
      desc: 'Strict backend authentication ensuring customers, processors, fraud officers, managers, and system administrators only execute authorized actions.'
    },
    {
      title: 'Executive Analytics & BI Reports',
      icon: BarChart3,
      desc: 'Real-time charts powered by actual database aggregation: claim distribution by status, loss category breakdown, monthly filing velocity, and fraud prevention savings.'
    },
    {
      title: 'Compliance Audit Trail',
      icon: Lock,
      desc: 'Immutable audit logs capturing every login, status change, document verification, and fraud assessment with user ID, IP address, and payload parameters.'
    }
  ];

  return (
    <div className="py-16 px-4 sm:px-6 lg:px-8 max-w-6xl mx-auto">
      <div className="text-center max-w-2xl mx-auto mb-16">
        <span className="text-xs font-bold tracking-wider uppercase text-indigo-600 bg-indigo-50 px-3 py-1 rounded-full border border-indigo-200">
          Platform Capabilities
        </span>
        <h1 className="text-3xl sm:text-4xl font-extrabold text-slate-950 mt-4 tracking-tight">
          Engineered for Enterprise Insurance Processing
        </h1>
        <p className="text-sm text-slate-600 mt-2">
          Designed specifically to satisfy Software Requirements Specification (SRS) standards for modern claim adjudication.
        </p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
        {features.map((f) => {
          const Icon = f.icon;
          return (
            <div key={f.title} className="bg-white rounded-2xl p-6 border border-slate-200/90 shadow-sm hover:shadow-md transition">
              <div className="w-12 h-12 rounded-xl bg-indigo-50 text-indigo-600 flex items-center justify-center mb-5">
                <Icon className="w-6 h-6" />
              </div>
              <h3 className="text-base font-bold text-slate-900 mb-2">{f.title}</h3>
              <p className="text-xs text-slate-500 leading-relaxed">{f.desc}</p>
            </div>
          );
        })}
      </div>
    </div>
  );
};

export default FeaturesPage;
