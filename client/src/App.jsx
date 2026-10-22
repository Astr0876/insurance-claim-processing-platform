import React from 'react';
import { Routes, Route, Navigate } from 'react-router-dom';
import { useAuth } from './context/AuthContext';

// Layouts
import PublicLayout from './layouts/PublicLayout';
import DashboardLayout from './layouts/DashboardLayout';

// Public Pages
import HomePage from './pages/public/HomePage';
import HowItWorksPage from './pages/public/HowItWorksPage';
import FeaturesPage from './pages/public/FeaturesPage';
import AboutPage from './pages/public/AboutPage';
import LoginPage from './pages/public/LoginPage';
import RegisterPage from './pages/public/RegisterPage';

// Customer Pages
import CustomerDashboard from './pages/customer/CustomerDashboard';
import SubmitClaimPage from './pages/customer/SubmitClaimPage';
import CustomerClaimsPage from './pages/customer/CustomerClaimsPage';
import CustomerClaimDetailPage from './pages/customer/CustomerClaimDetailPage';
import CustomerProfilePage from './pages/customer/CustomerProfilePage';
import CustomerNotificationsPage from './pages/customer/CustomerNotificationsPage';

// Staff Pages
import StaffDashboard from './pages/staff/StaffDashboard';
import StaffClaimsPage from './pages/staff/StaffClaimsPage';
import StaffClaimReviewPage from './pages/staff/StaffClaimReviewPage';

// Fraud Pages
import FraudDashboard from './pages/fraud/FraudDashboard';
import FraudInvestigationPage from './pages/fraud/FraudInvestigationPage';

// Manager Pages
import ManagerDashboard from './pages/manager/ManagerDashboard';
import ManagerReportsPage from './pages/manager/ManagerReportsPage';

// Admin Pages
import AdminDashboard from './pages/admin/AdminDashboard';
import UserManagementPage from './pages/admin/UserManagementPage';
import AuditLogsPage from './pages/admin/AuditLogsPage';
import SystemSettingsPage from './pages/admin/SystemSettingsPage';

// Route Guard Wrapper for Authenticated Users
const ProtectedRoute = ({ children, allowedRoles }) => {
  const { user, loading, getDashboardRoute } = useAuth();

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-slate-900 text-white">
        <div className="flex flex-col items-center gap-3">
          <div className="w-8 h-8 border-3 border-indigo-500 border-t-transparent rounded-full animate-spin" />
          <span className="text-xs font-mono tracking-wider text-slate-400">Authenticating session...</span>
        </div>
      </div>
    );
  }

  if (!user) {
    return <Navigate to="/login" replace />;
  }

  if (allowedRoles && !allowedRoles.includes(user.role)) {
    return <Navigate to={getDashboardRoute(user.role)} replace />;
  }

  return children;
};

function App() {
  const { user, getDashboardRoute } = useAuth();

  return (
    <Routes>
      {/* Public Pages */}
      <Route element={<PublicLayout />}>
        <Route path="/" element={<HomePage />} />
        <Route path="/how-it-works" element={<HowItWorksPage />} />
        <Route path="/features" element={<FeaturesPage />} />
        <Route path="/about" element={<AboutPage />} />
        <Route path="/login" element={<LoginPage />} />
        <Route path="/register" element={<RegisterPage />} />
      </Route>

      {/* Customer Workspace */}
      <Route
        path="/customer"
        element={
          <ProtectedRoute allowedRoles={['CUSTOMER']}>
            <DashboardLayout allowedRoles={['CUSTOMER']} />
          </ProtectedRoute>
        }
      >
        <Route index element={<Navigate to="/customer/dashboard" replace />} />
        <Route path="dashboard" element={<CustomerDashboard />} />
        <Route path="submit-claim" element={<SubmitClaimPage />} />
        <Route path="claims" element={<CustomerClaimsPage />} />
        <Route path="claims/:id" element={<CustomerClaimDetailPage />} />
        <Route path="profile" element={<CustomerProfilePage />} />
        <Route path="notifications" element={<CustomerNotificationsPage />} />
      </Route>

      {/* Insurance Staff Workspace */}
      <Route
        path="/staff"
        element={
          <ProtectedRoute allowedRoles={['INSURANCE_STAFF', 'MANAGER', 'ADMIN']}>
            <DashboardLayout allowedRoles={['INSURANCE_STAFF', 'MANAGER', 'ADMIN']} />
          </ProtectedRoute>
        }
      >
        <Route index element={<Navigate to="/staff/dashboard" replace />} />
        <Route path="dashboard" element={<StaffDashboard />} />
        <Route path="claims" element={<StaffClaimsPage />} />
        <Route path="claims/:id" element={<StaffClaimReviewPage />} />
      </Route>

      {/* SIU Fraud Unit Workspace */}
      <Route
        path="/fraud"
        element={
          <ProtectedRoute allowedRoles={['FRAUD_INVESTIGATOR', 'MANAGER', 'ADMIN']}>
            <DashboardLayout allowedRoles={['FRAUD_INVESTIGATOR', 'MANAGER', 'ADMIN']} />
          </ProtectedRoute>
        }
      >
        <Route index element={<Navigate to="/fraud/dashboard" replace />} />
        <Route path="dashboard" element={<FraudDashboard />} />
        <Route path="queue" element={<FraudDashboard />} />
        <Route path="investigate/:id" element={<FraudInvestigationPage />} />
      </Route>

      {/* Operations & Management Workspace */}
      <Route
        path="/manager"
        element={
          <ProtectedRoute allowedRoles={['INSURANCE_STAFF', 'FRAUD_INVESTIGATOR', 'MANAGER', 'ADMIN']}>
            <DashboardLayout allowedRoles={['INSURANCE_STAFF', 'FRAUD_INVESTIGATOR', 'MANAGER', 'ADMIN']} />
          </ProtectedRoute>
        }
      >
        <Route index element={<Navigate to="/manager/dashboard" replace />} />
        <Route path="dashboard" element={<ManagerDashboard />} />
        <Route path="reports" element={<ManagerReportsPage />} />
      </Route>

      {/* System Administrator Workspace */}
      <Route
        path="/admin"
        element={
          <ProtectedRoute allowedRoles={['INSURANCE_STAFF', 'FRAUD_INVESTIGATOR', 'MANAGER', 'ADMIN']}>
            <DashboardLayout allowedRoles={['INSURANCE_STAFF', 'FRAUD_INVESTIGATOR', 'MANAGER', 'ADMIN']} />
          </ProtectedRoute>
        }
      >
        <Route index element={<Navigate to="/admin/dashboard" replace />} />
        <Route path="dashboard" element={<AdminDashboard />} />
        <Route path="users" element={<UserManagementPage />} />
        <Route path="audit-logs" element={<AuditLogsPage />} />
        <Route path="settings" element={<SystemSettingsPage />} />
      </Route>

      {/* Fallback route */}
      <Route
        path="*"
        element={
          user ? (
            <Navigate to={getDashboardRoute(user.role)} replace />
          ) : (
            <Navigate to="/" replace />
          )
        }
      />
    </Routes>
  );
}

export default App;
