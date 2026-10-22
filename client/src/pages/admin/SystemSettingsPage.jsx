import React, { useState, useEffect } from 'react';
import { settingsService } from '../../services/api';
import {
  Settings,
  ShieldAlert,
  FileCheck,
  UploadCloud,
  DollarSign,
  Save,
  CheckCircle2,
  AlertTriangle,
  RotateCcw,
  Sliders,
  Sparkles
} from 'lucide-react';

const SystemSettingsPage = () => {
  const [settingsList, setSettingsList] = useState([]);
  const [formData, setFormData] = useState({});
  const [isLoading, setIsLoading] = useState(true);
  const [savingKey, setSavingKey] = useState(null);
  const [savedSuccessKey, setSavedSuccessKey] = useState(null);
  const [errorMessage, setErrorMessage] = useState(null);

  const fetchSettings = async () => {
    setIsLoading(true);
    try {
      const res = await settingsService.getSettings();
      if (res.data?.success) {
        const list = res.data.settings || [];
        setSettingsList(list);
        const map = {};
        list.forEach((s) => {
          map[s.key_name] = s.value_data;
        });
        setFormData(map);
      }
    } catch (err) {
      console.error('Failed to load settings:', err);
      setErrorMessage('Failed to load platform settings from database.');
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchSettings();
  }, []);

  const handleInputChange = (key, value) => {
    setFormData((prev) => ({ ...prev, [key]: value }));
  };

  const handleSaveSetting = async (key) => {
    setSavingKey(key);
    setErrorMessage(null);
    setSavedSuccessKey(null);

    try {
      const res = await settingsService.updateSetting({
        key,
        value: formData[key]
      });

      if (res.data?.success) {
        setSavedSuccessKey(key);
        setTimeout(() => setSavedSuccessKey(null), 3500);
      }
    } catch (err) {
      console.error('Save setting error:', err);
      setErrorMessage(err.response?.data?.message || `Failed to update ${key}.`);
    } finally {
      setSavingKey(null);
    }
  };

  return (
    <div className="space-y-6 max-w-4xl mx-auto pb-12">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2">
            <span className="p-1.5 rounded-lg bg-slate-900 text-white">
              <Settings className="w-5 h-5" />
            </span>
            <h2 className="text-xl sm:text-2xl font-extrabold text-slate-900 tracking-tight">
              Platform & Fraud Engine Configuration
            </h2>
          </div>
          <p className="text-xs sm:text-sm text-slate-500 mt-1">
            Fine-tune scoring thresholds, document compliance gates, and adjudication limits
          </p>
        </div>

        <button
          type="button"
          onClick={fetchSettings}
          className="inline-flex items-center gap-1.5 px-3 py-1.5 text-xs font-semibold text-slate-600 bg-white border border-slate-300 rounded-xl hover:bg-slate-50 shadow-xs"
        >
          <RotateCcw className="w-3.5 h-3.5" />
          Reload Settings
        </button>
      </div>

      {errorMessage && (
        <div className="p-3.5 rounded-xl bg-rose-50 border border-rose-200 text-rose-800 text-xs flex items-center justify-between">
          <span className="flex items-center gap-2 font-semibold">
            <AlertTriangle className="w-4 h-4 text-rose-600" />
            {errorMessage}
          </span>
          <button onClick={() => setErrorMessage(null)} className="text-rose-600 font-bold">×</button>
        </div>
      )}

      {/* Group 1: Fraud Engine Scoring Thresholds */}
      <div className="bg-white rounded-2xl border border-slate-200 shadow-sm p-6 space-y-6">
        <div className="flex items-center gap-3 border-b border-slate-100 pb-3">
          <div className="p-2 rounded-xl bg-rose-50 text-rose-600">
            <ShieldAlert className="w-5 h-5" />
          </div>
          <div>
            <h3 className="text-sm font-extrabold text-slate-900">
              AI / Rule Engine Risk Cutoff Thresholds
            </h3>
            <p className="text-xs text-slate-500">
              Determines when claims trigger red alerts and are routed to SIU
            </p>
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          {/* High Risk Cutoff */}
          <div className="p-4 rounded-xl border border-slate-200/90 bg-slate-50/50 space-y-3">
            <div className="flex items-center justify-between">
              <span className="text-xs font-extrabold text-slate-800">
                High-Risk Flag Cutoff (%)
              </span>
              <span className="text-[10px] font-mono text-rose-600 font-bold bg-rose-50 px-2 py-0.5 rounded border border-rose-200">
                SIU Intercept
              </span>
            </div>
            <p className="text-xs text-slate-500">
              Claims scoring at or above this threshold will be flagged as HIGH risk and routed to investigators.
            </p>
            <div className="flex items-center gap-2">
              <input
                type="number"
                min="50"
                max="95"
                value={formData['fraud_high_risk_threshold'] || '70'}
                onChange={(e) => handleInputChange('fraud_high_risk_threshold', e.target.value)}
                className="w-24 p-2 bg-white border border-slate-300 rounded-xl font-mono font-bold text-xs text-slate-800 focus:outline-none focus:border-indigo-500"
              />
              <span className="text-xs text-slate-500 font-mono">%</span>
              <button
                type="button"
                disabled={savingKey === 'fraud_high_risk_threshold'}
                onClick={() => handleSaveSetting('fraud_high_risk_threshold')}
                className="ml-auto inline-flex items-center gap-1.5 px-3 py-2 bg-slate-900 hover:bg-indigo-600 text-white rounded-xl text-xs font-bold transition-colors shadow-2xs"
              >
                <Save className="w-3 h-3" />
                {savingKey === 'fraud_high_risk_threshold' ? 'Saving...' : 'Apply'}
              </button>
            </div>
            {savedSuccessKey === 'fraud_high_risk_threshold' && (
              <p className="text-[11px] text-emerald-600 font-semibold flex items-center gap-1">
                <CheckCircle2 className="w-3.5 h-3.5" /> High-risk threshold updated in database.
              </p>
            )}
          </div>

          {/* Medium Risk Cutoff */}
          <div className="p-4 rounded-xl border border-slate-200/90 bg-slate-50/50 space-y-3">
            <div className="flex items-center justify-between">
              <span className="text-xs font-extrabold text-slate-800">
                Medium-Risk Warning Cutoff (%)
              </span>
              <span className="text-[10px] font-mono text-amber-600 font-bold bg-amber-50 px-2 py-0.5 rounded border border-amber-200">
                Warning Banner
              </span>
            </div>
            <p className="text-xs text-slate-500">
              Claims scoring at or above this score require staff verification before approval.
            </p>
            <div className="flex items-center gap-2">
              <input
                type="number"
                min="10"
                max="60"
                value={formData['fraud_medium_risk_threshold'] || '35'}
                onChange={(e) => handleInputChange('fraud_medium_risk_threshold', e.target.value)}
                className="w-24 p-2 bg-white border border-slate-300 rounded-xl font-mono font-bold text-xs text-slate-800 focus:outline-none focus:border-indigo-500"
              />
              <span className="text-xs text-slate-500 font-mono">%</span>
              <button
                type="button"
                disabled={savingKey === 'fraud_medium_risk_threshold'}
                onClick={() => handleSaveSetting('fraud_medium_risk_threshold')}
                className="ml-auto inline-flex items-center gap-1.5 px-3 py-2 bg-slate-900 hover:bg-indigo-600 text-white rounded-xl text-xs font-bold transition-colors shadow-2xs"
              >
                <Save className="w-3 h-3" />
                {savingKey === 'fraud_medium_risk_threshold' ? 'Saving...' : 'Apply'}
              </button>
            </div>
            {savedSuccessKey === 'fraud_medium_risk_threshold' && (
              <p className="text-[11px] text-emerald-600 font-semibold flex items-center gap-1">
                <CheckCircle2 className="w-3.5 h-3.5" /> Medium-risk threshold updated in database.
              </p>
            )}
          </div>
        </div>
      </div>

      {/* Group 2: Document Compliance & Adjudication Rules */}
      <div className="bg-white rounded-2xl border border-slate-200 shadow-sm p-6 space-y-6">
        <div className="flex items-center gap-3 border-b border-slate-100 pb-3">
          <div className="p-2 rounded-xl bg-blue-50 text-blue-600">
            <FileCheck className="w-5 h-5" />
          </div>
          <div>
            <h3 className="text-sm font-extrabold text-slate-900">
              Underwriting Compliance & Verification Gates
            </h3>
            <p className="text-xs text-slate-500">
              Mandatory business rules enforced during claim adjudication
            </p>
          </div>
        </div>

        <div className="space-y-4 text-xs">
          {/* Require verified documents */}
          <div className="p-4 rounded-xl border border-slate-200/90 bg-slate-50/50 flex flex-col sm:flex-row sm:items-center justify-between gap-3">
            <div>
              <span className="font-extrabold text-slate-800 block">
                Require Verified Documents Prior to Claim Approval
              </span>
              <p className="text-slate-500 text-[11px] mt-0.5">
                When enabled, the backend strictly rejects approval requests if all uploaded documents are not in "VERIFIED" state.
              </p>
            </div>
            <div className="flex items-center gap-3 shrink-0">
              <select
                value={formData['require_documents_for_approval'] || 'true'}
                onChange={(e) => handleInputChange('require_documents_for_approval', e.target.value)}
                className="p-2 bg-white border border-slate-300 rounded-xl font-bold text-xs"
              >
                <option value="true">Enforced (Strict)</option>
                <option value="false">Relaxed (Demo mode)</option>
              </select>
              <button
                type="button"
                disabled={savingKey === 'require_documents_for_approval'}
                onClick={() => handleSaveSetting('require_documents_for_approval')}
                className="px-3 py-2 bg-slate-900 hover:bg-indigo-600 text-white rounded-xl text-xs font-bold transition-colors"
              >
                Apply
              </button>
            </div>
          </div>

          {/* Auto flag high risk */}
          <div className="p-4 rounded-xl border border-slate-200/90 bg-slate-50/50 flex flex-col sm:flex-row sm:items-center justify-between gap-3">
            <div>
              <span className="font-extrabold text-slate-800 block">
                Auto-Intercept High-Risk Claims for SIU Review
              </span>
              <p className="text-slate-500 text-[11px] mt-0.5">
                Automatically transitions high-risk claims to INVESTIGATION_IN_PROGRESS upon intake submission.
              </p>
            </div>
            <div className="flex items-center gap-3 shrink-0">
              <select
                value={formData['auto_flag_high_risk'] || 'true'}
                onChange={(e) => handleInputChange('auto_flag_high_risk', e.target.value)}
                className="p-2 bg-white border border-slate-300 rounded-xl font-bold text-xs"
              >
                <option value="true">Enabled (Auto-Route)</option>
                <option value="false">Disabled (Manual)</option>
              </select>
              <button
                type="button"
                disabled={savingKey === 'auto_flag_high_risk'}
                onClick={() => handleSaveSetting('auto_flag_high_risk')}
                className="px-3 py-2 bg-slate-900 hover:bg-indigo-600 text-white rounded-xl text-xs font-bold transition-colors"
              >
                Apply
              </button>
            </div>
          </div>

          {/* Max upload size */}
          <div className="p-4 rounded-xl border border-slate-200/90 bg-slate-50/50 flex flex-col sm:flex-row sm:items-center justify-between gap-3">
            <div>
              <span className="font-extrabold text-slate-800 block">
                Maximum File Upload Limit (Multer Storage)
              </span>
              <p className="text-slate-500 text-[11px] mt-0.5">
                Maximum acceptable size for medical records, loss photos, and police reports in megabytes.
              </p>
            </div>
            <div className="flex items-center gap-3 shrink-0">
              <input
                type="number"
                min="2"
                max="50"
                value={formData['max_upload_size_mb'] || '10'}
                onChange={(e) => handleInputChange('max_upload_size_mb', e.target.value)}
                className="w-20 p-2 bg-white border border-slate-300 rounded-xl font-mono font-bold text-xs text-center"
              />
              <span className="font-mono text-slate-500">MB</span>
              <button
                type="button"
                disabled={savingKey === 'max_upload_size_mb'}
                onClick={() => handleSaveSetting('max_upload_size_mb')}
                className="px-3 py-2 bg-slate-900 hover:bg-indigo-600 text-white rounded-xl text-xs font-bold transition-colors"
              >
                Apply
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default SystemSettingsPage;
