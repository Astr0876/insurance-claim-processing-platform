import React from 'react';
import {
  CheckCircle,
  Clock,
  AlertTriangle,
  XCircle,
  FileSearch,
  ShieldAlert,
  ShieldCheck,
  HelpCircle
} from 'lucide-react';

export const StatusBadge = ({ status }) => {
  const configs = {
    SUBMITTED: {
      label: 'Submitted',
      color: 'bg-slate-100 text-slate-800 border-slate-200',
      icon: Clock
    },
    UNDER_REVIEW: {
      label: 'Under Review',
      color: 'bg-blue-50 text-blue-700 border-blue-200',
      icon: Clock
    },
    DOCS_PENDING: {
      label: 'Docs Pending',
      color: 'bg-amber-50 text-amber-700 border-amber-200',
      icon: HelpCircle
    },
    DOCS_VERIFIED: {
      label: 'Docs Verified',
      color: 'bg-teal-50 text-teal-700 border-teal-200',
      icon: FileSearch
    },
    INVESTIGATION_REQUIRED: {
      label: 'Investigation Required',
      color: 'bg-purple-50 text-purple-700 border-purple-200',
      icon: AlertTriangle
    },
    INVESTIGATION_IN_PROGRESS: {
      label: 'Investigating',
      color: 'bg-purple-50 text-purple-700 border-purple-200',
      icon: AlertTriangle
    },
    APPROVED: {
      label: 'Approved',
      color: 'bg-emerald-50 text-emerald-700 border-emerald-200',
      icon: CheckCircle
    },
    REJECTED: {
      label: 'Rejected',
      color: 'bg-rose-50 text-rose-700 border-rose-200',
      icon: XCircle
    }
  };

  const config = configs[status] || {
    label: status?.replace('_', ' ') || 'Unknown',
    color: 'bg-gray-100 text-gray-800 border-gray-200',
    icon: Clock
  };

  const Icon = config.icon;

  return (
    <span className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold border ${config.color}`}>
      <Icon className="w-3.5 h-3.5 shrink-0" />
      {config.label}
    </span>
  );
};

export const FraudRiskBadge = ({ level, score }) => {
  const configs = {
    LOW: {
      label: 'Low Risk',
      color: 'bg-emerald-50 text-emerald-700 border-emerald-200',
      icon: ShieldCheck
    },
    MEDIUM: {
      label: 'Medium Risk',
      color: 'bg-amber-50 text-amber-700 border-amber-200',
      icon: AlertTriangle
    },
    HIGH: {
      label: 'High Risk',
      color: 'bg-rose-50 text-rose-700 border-rose-200',
      icon: ShieldAlert
    }
  };

  const config = configs[level] || configs.LOW;
  const Icon = config.icon;

  return (
    <span className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold border ${config.color}`}>
      <Icon className="w-3.5 h-3.5 shrink-0" />
      <span>{config.label}</span>
      {score !== undefined && score !== null && (
        <span className="font-bold ml-0.5 opacity-80">({score}%)</span>
      )}
    </span>
  );
};

export const DocumentStatusBadge = ({ status }) => {
  const configs = {
    VERIFIED: {
      label: 'Verified',
      color: 'bg-emerald-50 text-emerald-700 border-emerald-200',
      icon: CheckCircle
    },
    REJECTED: {
      label: 'Rejected',
      color: 'bg-rose-50 text-rose-700 border-rose-200',
      icon: XCircle
    },
    PENDING: {
      label: 'Pending Review',
      color: 'bg-amber-50 text-amber-700 border-amber-200',
      icon: Clock
    }
  };

  const config = configs[status] || configs.PENDING;
  const Icon = config.icon;

  return (
    <span className={`inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium border ${config.color}`}>
      <Icon className="w-3 h-3 shrink-0" />
      {config.label}
    </span>
  );
};
