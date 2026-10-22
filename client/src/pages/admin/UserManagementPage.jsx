import React, { useState, useEffect } from 'react';
import { userService } from '../../services/api';
import { useAuth } from '../../context/AuthContext';
import {
  Users,
  UserPlus,
  Search,
  Filter,
  Shield,
  CheckCircle2,
  AlertTriangle,
  UserCheck,
  UserX,
  Edit,
  Mail,
  Phone,
  Lock,
  X
} from 'lucide-react';
import Modal from '../../components/common/Modal';

const ROLES = [
  { value: 'CUSTOMER', label: 'Customer (Policyholder)', color: 'bg-emerald-100 text-emerald-800' },
  { value: 'INSURANCE_STAFF', label: 'Claims Processor (Staff)', color: 'bg-blue-100 text-blue-800' },
  { value: 'FRAUD_INVESTIGATOR', label: 'SIU Fraud Officer', color: 'bg-purple-100 text-purple-800' },
  { value: 'MANAGER', label: 'Operations Manager', color: 'bg-amber-100 text-amber-800' },
  { value: 'ADMIN', label: 'System Administrator', color: 'bg-rose-100 text-rose-800' },
];

const UserManagementPage = () => {
  const { user: currentUser } = useAuth();
  const [users, setUsers] = useState([]);
  const [isLoading, setIsLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [roleFilter, setRoleFilter] = useState('');
  const [statusFilter, setStatusFilter] = useState('');

  // Modals state
  const [isCreateModalOpen, setIsCreateModalOpen] = useState(false);
  const [isRoleModalOpen, setIsRoleModalOpen] = useState(false);
  const [selectedUser, setSelectedUser] = useState(null);
  const [targetRole, setTargetRole] = useState('INSURANCE_STAFF');

  // New User Form State
  const [createFormData, setCreateFormData] = useState({
    name: '',
    email: '',
    phone: '',
    password: 'Password123!',
    roleName: 'INSURANCE_STAFF'
  });
  const [modalError, setModalError] = useState(null);
  const [successMessage, setSuccessMessage] = useState(null);

  const fetchUsers = async () => {
    setIsLoading(true);
    try {
      const params = {};
      if (search) params.search = search;
      if (roleFilter) params.role = roleFilter;
      if (statusFilter) params.status = statusFilter;

      const res = await userService.getUsers(params);
      if (res.data?.success) {
        setUsers(res.data.users || []);
      }
    } catch (err) {
      console.error('Failed to load users:', err);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchUsers();
  }, [roleFilter, statusFilter]);

  const handleSearchSubmit = (e) => {
    e.preventDefault();
    fetchUsers();
  };

  // Toggle user account active/suspended
  const handleToggleStatus = async (targetUser) => {
    if (targetUser.id === currentUser?.id) {
      alert('You cannot suspend your own administrative account.');
      return;
    }

    const nextStatus = targetUser.status === 'ACTIVE' ? 'SUSPENDED' : 'ACTIVE';
    const confirmMsg = `Are you sure you want to mark ${targetUser.name}'s account as ${nextStatus}?`;
    if (!window.confirm(confirmMsg)) return;

    try {
      const res = await userService.toggleStatus(targetUser.id, nextStatus);
      if (res.data?.success) {
        setSuccessMessage(`Account status updated to ${nextStatus} for ${targetUser.name}.`);
        fetchUsers();
      }
    } catch (err) {
      alert(err.response?.data?.message || 'Failed to update user status.');
    }
  };

  // Change user role
  const handleRoleChangeSubmit = async (e) => {
    e.preventDefault();
    if (!selectedUser) return;

    try {
      const res = await userService.updateRole(selectedUser.id, targetRole);
      if (res.data?.success) {
        setSuccessMessage(`Role for ${selectedUser.name} changed to ${targetRole}.`);
        setIsRoleModalOpen(false);
        fetchUsers();
      }
    } catch (err) {
      setModalError(err.response?.data?.message || 'Failed to update role.');
    }
  };

  // Create new user
  const handleCreateUserSubmit = async (e) => {
    e.preventDefault();
    setModalError(null);

    if (!createFormData.name || !createFormData.email || !createFormData.password) {
      setModalError('Name, email, and password are required.');
      return;
    }

    try {
      const res = await userService.createUser(createFormData);
      if (res.data?.success) {
        setSuccessMessage(`Staff account created successfully for ${createFormData.name}.`);
        setIsCreateModalOpen(false);
        setCreateFormData({
          name: '',
          email: '',
          phone: '',
          password: 'Password123!',
          roleName: 'INSURANCE_STAFF'
        });
        fetchUsers();
      }
    } catch (err) {
      setModalError(err.response?.data?.message || 'Failed to create user.');
    }
  };

  return (
    <div className="space-y-6">
      {/* Page Title & Provision Button */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2">
            <span className="p-1.5 rounded-lg bg-indigo-100 text-indigo-700">
              <Users className="w-5 h-5" />
            </span>
            <h2 className="text-xl sm:text-2xl font-extrabold text-slate-900 tracking-tight">
              User & Role Management
            </h2>
          </div>
          <p className="text-xs sm:text-sm text-slate-500 mt-1">
            Role-Based Access Control (RBAC) directory and staff credential provisioning
          </p>
        </div>

        <button
          type="button"
          onClick={() => {
            setModalError(null);
            setIsCreateModalOpen(true);
          }}
          className="inline-flex items-center gap-2 px-4 py-2 text-xs font-bold text-white bg-indigo-600 hover:bg-indigo-700 rounded-xl shadow-xs transition-colors"
        >
          <UserPlus className="w-3.5 h-3.5" />
          Provision New User
        </button>
      </div>

      {/* Success Notification */}
      {successMessage && (
        <div className="p-3.5 rounded-xl bg-emerald-50 border border-emerald-200 text-emerald-800 text-xs flex items-center justify-between">
          <span className="flex items-center gap-2 font-semibold">
            <CheckCircle2 className="w-4 h-4 text-emerald-600" />
            {successMessage}
          </span>
          <button onClick={() => setSuccessMessage(null)} className="text-emerald-700 font-bold">×</button>
        </div>
      )}

      {/* Filters and Search Bar */}
      <div className="bg-white p-4 rounded-2xl border border-slate-200 shadow-sm flex flex-col md:flex-row items-center justify-between gap-3">
        <form onSubmit={handleSearchSubmit} className="w-full md:w-80 relative">
          <Search className="w-4 h-4 text-slate-400 absolute left-3 top-3 pointer-events-none" />
          <input
            type="text"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Search by name, email, or phone..."
            className="w-full pl-9 pr-4 py-2 text-xs bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-500"
          />
        </form>

        <div className="w-full md:w-auto flex flex-wrap items-center gap-2">
          <select
            value={roleFilter}
            onChange={(e) => setRoleFilter(e.target.value)}
            className="px-3 py-2 text-xs bg-slate-50 border border-slate-200 rounded-xl font-medium text-slate-700 focus:outline-none focus:border-indigo-500"
          >
            <option value="">All Roles</option>
            <option value="CUSTOMER">Customer (Policyholder)</option>
            <option value="INSURANCE_STAFF">Claims Processor</option>
            <option value="FRAUD_INVESTIGATOR">SIU Fraud Officer</option>
            <option value="MANAGER">Operations Manager</option>
            <option value="ADMIN">System Administrator</option>
          </select>

          <select
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
            className="px-3 py-2 text-xs bg-slate-50 border border-slate-200 rounded-xl font-medium text-slate-700 focus:outline-none focus:border-indigo-500"
          >
            <option value="">All Statuses</option>
            <option value="ACTIVE">Active Accounts</option>
            <option value="SUSPENDED">Suspended Accounts</option>
          </select>
        </div>
      </div>

      {/* User Directory Table */}
      <div className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs">
            <thead>
              <tr className="bg-slate-50/80 border-b border-slate-200/80 text-slate-500 uppercase font-bold tracking-wider text-[10px]">
                <th className="py-3 px-4">User</th>
                <th className="py-3 px-4">Role Assignment</th>
                <th className="py-3 px-4">Contact</th>
                <th className="py-3 px-4">Associated Records</th>
                <th className="py-3 px-4">Account Status</th>
                <th className="py-3 px-4">Registered</th>
                <th className="py-3 px-4 text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {isLoading ? (
                <tr>
                  <td colSpan={7} className="py-12 text-center text-slate-400">
                    <div className="w-6 h-6 border-2 border-indigo-600 border-t-transparent rounded-full animate-spin mx-auto mb-2" />
                    <span>Loading system user directory...</span>
                  </td>
                </tr>
              ) : users.length === 0 ? (
                <tr>
                  <td colSpan={7} className="py-12 text-center text-slate-400">
                    No users matching criteria.
                  </td>
                </tr>
              ) : (
                users.map((u) => {
                  const roleObj = ROLES.find((r) => r.value === u.role_name) || {
                    label: u.role_name,
                    color: 'bg-slate-100 text-slate-800'
                  };
                  const isCurrent = u.id === currentUser?.id;

                  return (
                    <tr key={u.id} className="hover:bg-slate-50/80 transition-colors">
                      <td className="py-3 px-4">
                        <div className="flex items-center gap-2.5">
                          <div className="w-8 h-8 rounded-full bg-slate-200 text-slate-700 flex items-center justify-center font-bold text-xs uppercase shrink-0">
                            {u.name.charAt(0)}
                          </div>
                          <div>
                            <span className="font-bold text-slate-900 block flex items-center gap-1.5">
                              {u.name}
                              {isCurrent && (
                                <span className="text-[9px] font-mono uppercase bg-indigo-100 text-indigo-700 px-1.5 py-0.2 rounded font-bold">
                                  You
                                </span>
                              )}
                            </span>
                            <span className="text-[11px] text-slate-400">{u.email}</span>
                          </div>
                        </div>
                      </td>

                      <td className="py-3 px-4">
                        <span className={`inline-block px-2.5 py-1 rounded-lg text-[11px] font-bold ${roleObj.color}`}>
                          {roleObj.label}
                        </span>
                      </td>

                      <td className="py-3 px-4 font-mono text-slate-600 text-[11px]">
                        {u.phone || '—'}
                      </td>

                      <td className="py-3 px-4 text-[11px] text-slate-500">
                        {u.claims_count !== undefined && (
                          <span className="font-semibold text-slate-700">{u.claims_count} claims</span>
                        )}
                        {u.policies_count !== undefined && (
                          <span className="ml-1 text-slate-400">({u.policies_count} policies)</span>
                        )}
                      </td>

                      <td className="py-3 px-4">
                        <span
                          className={`inline-flex items-center gap-1 px-2 py-0.5 rounded-md text-[10px] font-bold ${
                            u.status === 'ACTIVE'
                              ? 'bg-emerald-100 text-emerald-800'
                              : 'bg-rose-100 text-rose-800'
                          }`}
                        >
                          {u.status === 'ACTIVE' ? <UserCheck className="w-3 h-3" /> : <UserX className="w-3 h-3" />}
                          {u.status}
                        </span>
                      </td>

                      <td className="py-3 px-4 text-slate-400 font-mono text-[11px]">
                        {new Date(u.created_at).toLocaleDateString()}
                      </td>

                      <td className="py-3 px-4 text-right space-x-1">
                        <button
                          type="button"
                          disabled={isCurrent}
                          onClick={() => {
                            setSelectedUser(u);
                            setTargetRole(u.role_name);
                            setModalError(null);
                            setIsRoleModalOpen(true);
                          }}
                          className={`p-1.5 rounded-lg border text-xs font-semibold transition-colors ${
                            isCurrent
                              ? 'opacity-40 cursor-not-allowed border-slate-200 text-slate-400'
                              : 'border-slate-200 text-slate-700 hover:bg-slate-100 hover:text-indigo-600'
                          }`}
                          title="Change Role"
                        >
                          <Edit className="w-3.5 h-3.5" />
                        </button>

                        <button
                          type="button"
                          disabled={isCurrent}
                          onClick={() => handleToggleStatus(u)}
                          className={`p-1.5 rounded-lg border text-xs font-semibold transition-colors ${
                            isCurrent
                              ? 'opacity-40 cursor-not-allowed border-slate-200 text-slate-400'
                              : u.status === 'ACTIVE'
                              ? 'border-rose-200 text-rose-600 hover:bg-rose-50'
                              : 'border-emerald-200 text-emerald-600 hover:bg-emerald-50'
                          }`}
                          title={u.status === 'ACTIVE' ? 'Suspend Account' : 'Reactivate Account'}
                        >
                          {u.status === 'ACTIVE' ? <UserX className="w-3.5 h-3.5" /> : <UserCheck className="w-3.5 h-3.5" />}
                        </button>
                      </td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Modal: Change Role */}
      {isRoleModalOpen && selectedUser && (
        <Modal
          isOpen={isRoleModalOpen}
          onClose={() => setIsRoleModalOpen(false)}
          title={`Modify RBAC Role: ${selectedUser.name}`}
        >
          <form onSubmit={handleRoleChangeSubmit} className="space-y-4 text-xs">
            {modalError && (
              <div className="p-3 rounded-xl bg-rose-50 text-rose-700 border border-rose-200 flex items-center gap-2">
                <AlertTriangle className="w-4 h-4 shrink-0" />
                {modalError}
              </div>
            )}

            <div>
              <label className="font-bold text-slate-700 block mb-1">Select New Assigned Role</label>
              <select
                value={targetRole}
                onChange={(e) => setTargetRole(e.target.value)}
                className="w-full p-2.5 bg-slate-50 border border-slate-200 rounded-xl text-xs font-medium text-slate-800 focus:outline-none focus:border-indigo-500"
              >
                {ROLES.map((r) => (
                  <option key={r.value} value={r.value}>
                    {r.label}
                  </option>
                ))}
              </select>
              <p className="text-[11px] text-slate-400 mt-1">
                Updating the role instantly recalibrates dashboard navigation, workflow permissions, and backend API route guards.
              </p>
            </div>

            <div className="flex justify-end gap-2 pt-3 border-t border-slate-100">
              <button
                type="button"
                onClick={() => setIsRoleModalOpen(false)}
                className="px-3.5 py-2 rounded-xl border border-slate-300 text-slate-700 font-bold hover:bg-slate-50"
              >
                Cancel
              </button>
              <button
                type="submit"
                className="px-4 py-2 rounded-xl bg-indigo-600 text-white font-bold hover:bg-indigo-700 shadow-xs"
              >
                Confirm Role Update
              </button>
            </div>
          </form>
        </Modal>
      )}

      {/* Modal: Provision New User */}
      {isCreateModalOpen && (
        <Modal
          isOpen={isCreateModalOpen}
          onClose={() => setIsCreateModalOpen(false)}
          title="Provision New System User"
        >
          <form onSubmit={handleCreateUserSubmit} className="space-y-3.5 text-xs">
            {modalError && (
              <div className="p-3 rounded-xl bg-rose-50 text-rose-700 border border-rose-200 flex items-center gap-2">
                <AlertTriangle className="w-4 h-4 shrink-0" />
                {modalError}
              </div>
            )}

            <div>
              <label className="font-bold text-slate-700 block mb-1">Full Legal Name *</label>
              <input
                type="text"
                required
                value={createFormData.name}
                onChange={(e) => setCreateFormData({ ...createFormData, name: e.target.value })}
                placeholder="e.g. Agent Robert Vance"
                className="w-full p-2.5 bg-slate-50 border border-slate-200 rounded-xl text-xs focus:outline-none focus:border-indigo-500"
              />
            </div>

            <div>
              <label className="font-bold text-slate-700 block mb-1">Corporate Email Address *</label>
              <input
                type="email"
                required
                value={createFormData.email}
                onChange={(e) => setCreateFormData({ ...createFormData, email: e.target.value })}
                placeholder="e.g. robert.vance@secureclaim.internal"
                className="w-full p-2.5 bg-slate-50 border border-slate-200 rounded-xl text-xs focus:outline-none focus:border-indigo-500"
              />
            </div>

            <div>
              <label className="font-bold text-slate-700 block mb-1">Phone Number</label>
              <input
                type="tel"
                value={createFormData.phone}
                onChange={(e) => setCreateFormData({ ...createFormData, phone: e.target.value })}
                placeholder="e.g. +1 (555) 234-5678"
                className="w-full p-2.5 bg-slate-50 border border-slate-200 rounded-xl text-xs focus:outline-none focus:border-indigo-500"
              />
            </div>

            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="font-bold text-slate-700 block mb-1">Initial Password *</label>
                <input
                  type="password"
                  required
                  value={createFormData.password}
                  onChange={(e) => setCreateFormData({ ...createFormData, password: e.target.value })}
                  className="w-full p-2.5 bg-slate-50 border border-slate-200 rounded-xl text-xs focus:outline-none focus:border-indigo-500"
                />
              </div>

              <div>
                <label className="font-bold text-slate-700 block mb-1">Role Permission *</label>
                <select
                  value={createFormData.roleName}
                  onChange={(e) => setCreateFormData({ ...createFormData, roleName: e.target.value })}
                  className="w-full p-2.5 bg-slate-50 border border-slate-200 rounded-xl text-xs font-semibold focus:outline-none focus:border-indigo-500"
                >
                  <option value="INSURANCE_STAFF">Claims Processor</option>
                  <option value="FRAUD_INVESTIGATOR">SIU Fraud Officer</option>
                  <option value="MANAGER">Operations Manager</option>
                  <option value="ADMIN">System Administrator</option>
                  <option value="CUSTOMER">Customer (Policyholder)</option>
                </select>
              </div>
            </div>

            <div className="flex justify-end gap-2 pt-3 border-t border-slate-100">
              <button
                type="button"
                onClick={() => setIsCreateModalOpen(false)}
                className="px-3.5 py-2 rounded-xl border border-slate-300 text-slate-700 font-bold hover:bg-slate-50"
              >
                Cancel
              </button>
              <button
                type="submit"
                className="px-4 py-2 rounded-xl bg-indigo-600 text-white font-bold hover:bg-indigo-700 shadow-xs"
              >
                Create Account
              </button>
            </div>
          </form>
        </Modal>
      )}
    </div>
  );
};

export default UserManagementPage;
