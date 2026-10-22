import React from 'react';
import { ArrowUpRight, ArrowDownRight } from 'lucide-react';

const StatCard = ({
  title,
  value,
  subtitle,
  icon: Icon,
  trend,
  trendLabel,
  color = 'indigo',
  prefix = '',
  suffix = '',
  className = ''
}) => {
  const colorMap = {
    indigo: {
      bg: 'bg-indigo-50/70',
      text: 'text-indigo-600',
      border: 'border-indigo-100',
      accent: 'from-indigo-500/10 to-transparent'
    },
    blue: {
      bg: 'bg-blue-50/70',
      text: 'text-blue-600',
      border: 'border-blue-100',
      accent: 'from-blue-500/10 to-transparent'
    },
    emerald: {
      bg: 'bg-emerald-50/70',
      text: 'text-emerald-600',
      border: 'border-emerald-100',
      accent: 'from-emerald-500/10 to-transparent'
    },
    amber: {
      bg: 'bg-amber-50/70',
      text: 'text-amber-600',
      border: 'border-amber-100',
      accent: 'from-amber-500/10 to-transparent'
    },
    rose: {
      bg: 'bg-rose-50/70',
      text: 'text-rose-600',
      border: 'border-rose-100',
      accent: 'from-rose-500/10 to-transparent'
    },
    purple: {
      bg: 'bg-purple-50/70',
      text: 'text-purple-600',
      border: 'border-purple-100',
      accent: 'from-purple-500/10 to-transparent'
    }
  };

  const scheme = colorMap[color] || colorMap.indigo;

  return (
    <div className={`relative overflow-hidden rounded-2xl bg-white p-6 border border-slate-200/80 shadow-sm hover:shadow-md transition-all duration-200 ${className}`}>
      {/* Background soft gradient wash */}
      <div className={`absolute top-0 right-0 w-32 h-32 bg-gradient-to-bl ${scheme.accent} rounded-bl-full pointer-events-none`} />

      <div className="flex items-center justify-between">
        <span className="text-sm font-medium text-slate-500">{title}</span>
        {Icon && (
          <div className={`flex items-center justify-center w-11 h-11 rounded-xl ${scheme.bg} ${scheme.text} shrink-0`}>
            <Icon className="w-5 h-5" />
          </div>
        )}
      </div>

      <div className="mt-4 flex items-baseline gap-2">
        <span className="text-3xl font-extrabold tracking-tight text-slate-900">
          {prefix}{typeof value === 'number' ? value.toLocaleString() : value}{suffix}
        </span>
      </div>

      {(trend !== undefined || subtitle) && (
        <div className="mt-3 flex items-center gap-2 text-xs">
          {trend !== undefined && (
            <span
              className={`inline-flex items-center font-semibold ${
                trend >= 0 ? 'text-emerald-600' : 'text-rose-600'
              }`}
            >
              {trend >= 0 ? (
                <ArrowUpRight className="w-3.5 h-3.5 mr-0.5" />
              ) : (
                <ArrowDownRight className="w-3.5 h-3.5 mr-0.5" />
              )}
              {Math.abs(trend)}%
            </span>
          )}
          <span className="text-slate-500">{trendLabel || subtitle}</span>
        </div>
      )}
    </div>
  );
};

export default StatCard;
