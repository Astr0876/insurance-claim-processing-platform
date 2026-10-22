import React, { useState, useEffect } from 'react';
import { useAuth } from '../../context/AuthContext';
import { policyService } from '../../services/api';
import { Shield, User, Mail, Phone, PlusCircle, CheckCircle2 } from 'lucide-react';
import Button from '../../components/common/Button';
import Modal from '../../components/common/Modal';

const CustomerProfilePage = () => {
  const { user } = useAuth();
  const [policies, setPolicies] = useState([]);
  const [isLoading, setIsLoading] = useState(true);

  // New policy modal
  const [modalOpen, setModalOpen] = useState(false);
  const [newPolicyType, setNewPolicyType] = useState('AUTO');
  const [newCoverage, setNewCoverage] = useState(50000);
  const [isCreating, setIsCreating] = useState(false);

  const fetchPolicies = async () => {
    try {
      const res = await policyService.getPolicies();
      if (res.data?.success) {
        setPolicies(res.data.policies || []);
      }
    } catch (err) {
      console.error(err);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchPolicies();
  }, []);

  const handleCreatePolicy = async (e) => {
    e.preventDefault();
    setIsCreating(true);
    try {
      await policyService.createPolicy({
        policyType: newPolicyType,
        coverageAmount: newCoverage
      });
      setModalOpen(false);
      fetchPolicies();
    } catch (err) {
      console.error(err);
    } finally {
      setIsCreating(false);
    }
  };

  return (
    <div className="space-y-8 max-w-4xl mx-auto">
      <div>
        <h2 className="text-xl sm:text-2xl font-extrabold text-slate-900 tracking-tight">
          Profile & Policies
        </h2>
        <p className="text-xs text-slate-500 mt-0.5">
          Manage your account profile and view registered coverage policies
        </p>
      </div>

      {/* Profile Card */}
      <div className="bg-white rounded-2xl p-6 sm:p-8 border border-slate-200/90 shadow-sm">
        <h3 className="text-sm font-bold text-slate-900 pb-3 border-b border-slate-100 flex items-center gap-2">
          <User className="w-4 h-4 text-indigo-600" />
          <span>Policyholder Identity</span>
        </h3>

        <div className="mt-4 grid grid-cols-1 sm:grid-cols-3 gap-6 text-xs">
          <div>
            <span className="text-slate-400 block text-[11px]">Full Name</span>
            <span className="font-bold text-slate-900 text-sm mt-0.5 block">{user?.name}</span>
          </div>
          <div>
            <span className="text-slate-400 block text-[11px]">Email Address</span>
            <span className="font-medium text-slate-700 mt-0.5 block font-mono">{user?.email}</span>
          </div>
          <div>
            <span className="text-slate-400 block text-[11px]">Contact Phone</span>
            <span className="font-medium text-slate-700 mt-0.5 block">{user?.phone || 'Not provided'}</span>
          </div>
        </div>
      </div>

      {/* Policies List */}
      <div className="bg-white rounded-2xl p-6 sm:p-8 border border-slate-200/90 shadow-sm space-y-4">
        <div className="flex items-center justify-between pb-3 border-b border-slate-100">
          <div>
            <h3 className="text-sm font-bold text-slate-900">Active Insurance Policies</h3>
            <p className="text-xs text-slate-500">Coverage limit contracts available for claim submission</p>
          </div>
          <Button
            size="sm"
            variant="outline"
            icon={PlusCircle}
            onClick={() => setModalOpen(true)}
          >
            Add New Policy
          </Button>
        </div>

        {isLoading ? (
          <div className="py-8 text-center text-xs text-slate-400">Loading policies...</div>
        ) : (
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 pt-2">
            {policies.map((p) => (
              <div key={p.id} className="p-4 rounded-xl bg-slate-50 border border-slate-200/80">
                <div className="flex items-center justify-between">
                  <span className="text-xs font-bold text-slate-900">{p.policy_type} Insurance</span>
                  <span className="text-[10px] font-semibold px-2 py-0.5 rounded-full bg-emerald-100 text-emerald-800">
                    {p.status}
                  </span>
                </div>
                <div className="text-[11px] font-mono text-slate-500 mt-1">{p.policy_number}</div>
                <div className="mt-3 pt-2 border-t border-slate-200/60 grid grid-cols-2 gap-2 text-xs">
                  <div>
                    <span className="text-slate-400 block text-[10px]">Coverage Limit</span>
                    <span className="font-mono font-bold text-slate-800">
                      ${parseFloat(p.coverage_amount).toLocaleString()}
                    </span>
                  </div>
                  <div>
                    <span className="text-slate-400 block text-[10px]">Standard Deductible</span>
                    <span className="font-mono font-bold text-slate-800">
                      ${parseFloat(p.deductible).toLocaleString()}
                    </span>
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Add Policy Modal */}
      <Modal
        isOpen={modalOpen}
        onClose={() => setModalOpen(false)}
        title="Register Additional Policy"
        subtitle="Provision a new insurance line for demonstration"
      >
        <form onSubmit={handleCreatePolicy} className="space-y-4">
          <div>
            <label className="block text-xs font-semibold text-slate-700 mb-1">
              Insurance Line
            </label>
            <select
              value={newPolicyType}
              onChange={(e) => setNewPolicyType(e.target.value)}
              className="w-full px-3 py-2 text-xs rounded-xl border border-slate-300 bg-white focus:outline-none focus:ring-2 focus:ring-indigo-500"
            >
              <option value="AUTO">Auto Insurance</option>
              <option value="HEALTH">Health & Medical</option>
              <option value="HOME">Homeowners</option>
              <option value="PROPERTY">Commercial Property</option>
            </select>
          </div>

          <div>
            <label className="block text-xs font-semibold text-slate-700 mb-1">
              Coverage Limit
            </label>
            <select
              value={newCoverage}
              onChange={(e) => setNewCoverage(Number(e.target.value))}
              className="w-full px-3 py-2 text-xs rounded-xl border border-slate-300 bg-white focus:outline-none focus:ring-2 focus:ring-indigo-500"
            >
              <option value={25000}>$25,000</option>
              <option value={50000}>$50,000</option>
              <option value={100000}>$100,000</option>
              <option value={250000}>$250,000</option>
            </select>
          </div>

          <div className="pt-3 flex justify-end gap-2 border-t border-slate-100">
            <Button
              type="button"
              variant="outline"
              size="sm"
              onClick={() => setModalOpen(false)}
            >
              Cancel
            </Button>
            <Button
              type="submit"
              variant="primary"
              size="sm"
              isLoading={isCreating}
            >
              Add Policy
            </Button>
          </div>
        </form>
      </Modal>
    </div>
  );
};

export default CustomerProfilePage;
