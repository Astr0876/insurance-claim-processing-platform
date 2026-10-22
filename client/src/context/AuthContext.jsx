import React, { createContext, useContext, useState, useEffect } from 'react';
import { authService } from '../services/api';

const AuthContext = createContext(null);

export const DEMO_ACCOUNTS = [
  { role: 'CUSTOMER', email: 'customer@example.com', label: 'Policyholder', badgeColor: 'bg-emerald-50 text-emerald-700 border-emerald-200' },
  { role: 'INSURANCE_STAFF', email: 'staff@example.com', label: 'Claims Processor', badgeColor: 'bg-blue-50 text-blue-700 border-blue-200' },
  { role: 'FRAUD_INVESTIGATOR', email: 'fraud@example.com', label: 'SIU Fraud Officer', badgeColor: 'bg-purple-50 text-purple-700 border-purple-200' },
  { role: 'MANAGER', email: 'manager@example.com', label: 'Operations Manager', badgeColor: 'bg-amber-50 text-amber-700 border-amber-200' },
  { role: 'ADMIN', email: 'admin@example.com', label: 'System Admin', badgeColor: 'bg-rose-50 text-rose-700 border-rose-200' },
];

export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(() => {
    const saved = localStorage.getItem('user');
    return saved ? JSON.parse(saved) : null;
  });
  const [token, setToken] = useState(() => localStorage.getItem('token'));
  const [loading, setLoading] = useState(true);

  // Validate session on app launch
  useEffect(() => {
    const checkAuth = async () => {
      const storedToken = localStorage.getItem('token');
      if (storedToken) {
        try {
          const res = await authService.getMe();
          if (res.data?.success) {
            setUser(res.data.user);
            localStorage.setItem('user', JSON.stringify(res.data.user));
          }
        } catch (err) {
          console.warn('Session expired or invalid token:', err.message);
          localStorage.removeItem('token');
          localStorage.removeItem('user');
          setUser(null);
          setToken(null);
        }
      }
      setLoading(false);
    };

    checkAuth();
  }, []);

  const login = async (email, password) => {
    const res = await authService.login({ email, password });
    if (res.data?.success) {
      const { token: newToken, user: userData } = res.data;
      localStorage.setItem('token', newToken);
      localStorage.setItem('user', JSON.stringify(userData));
      setToken(newToken);
      setUser(userData);
      return userData;
    }
    throw new Error(res.data?.message || 'Login failed.');
  };

  const register = async (data) => {
    const res = await authService.register(data);
    if (res.data?.success) {
      const { token: newToken, user: userData } = res.data;
      localStorage.setItem('token', newToken);
      localStorage.setItem('user', JSON.stringify(userData));
      setToken(newToken);
      setUser(userData);
      return userData;
    }
    throw new Error(res.data?.message || 'Registration failed.');
  };

  const logout = () => {
    localStorage.removeItem('token');
    localStorage.removeItem('user');
    setToken(null);
    setUser(null);
  };

  const quickDemoLogin = async (email) => {
    return await login(email, 'Password123!');
  };

  const getDashboardRoute = (roleToRoute = user?.role) => {
    switch (roleToRoute) {
      case 'CUSTOMER':
        return '/customer/dashboard';
      case 'INSURANCE_STAFF':
        return '/staff/dashboard';
      case 'FRAUD_INVESTIGATOR':
        return '/fraud/dashboard';
      case 'ADMIN':
        return '/admin/dashboard';
      case 'MANAGER':
        return '/manager/dashboard';
      default:
        return '/login';
    }
  };

  const value = {
    user,
    token,
    loading,
    login,
    register,
    logout,
    quickDemoLogin,
    getDashboardRoute,
    isAuthenticated: !!token && !!user,
    isCustomer: user?.role === 'CUSTOMER',
    isStaff: user?.role === 'INSURANCE_STAFF',
    isFraudInvestigator: user?.role === 'FRAUD_INVESTIGATOR',
    isAdmin: user?.role === 'ADMIN',
    isManager: user?.role === 'MANAGER'
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
};

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};
