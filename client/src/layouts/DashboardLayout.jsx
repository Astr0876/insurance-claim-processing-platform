import React, { useState, useEffect } from 'react';
import { Outlet, Link, useLocation, useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { notificationService } from '../services/api';
import {
  Shield,
  LayoutDashboard,
  FilePlus,
  FileText,
  ShieldAlert,
  AlertTriangle,
  Users,
  BarChart3,
  ScrollText,
  Settings,
  Bell,
  LogOut,
  ChevronDown,
  Menu,
  X,
  CheckCircle,
  Clock,
  ArrowRight
} from 'lucide-react';
import DemoCredentialsBar from '../components/common/DemoCredentialsBar';

const DashboardLayout = ({ allowedRoles = [] }) => {
  const { user, logout, quickDemoLogin, getDashboardRoute } = useAuth();
  const location = useLocation();
  const navigate = useNavigate();

  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [notificationsOpen, setNotificationsOpen] = useState(false);
  const [notifications, setNotifications] = useState([]);
  const [unreadCount, setUnreadCount] = useState(0);

  // Security guard: verify role access
  useEffect(() => {
    if (!user) {
      navigate('/login');
      return;
    }

    if (allowedRoles.length > 0 && !allowedRoles.includes(user.role)) {
      console.warn(`Unauthorized role access: ${user.role} tried accessing ${location.pathname}`);
      navigate(getDashboardRoute(user.role), { replace: true });
    }
  }, [user, allowedRoles, location.pathname, navigate]);

  // Fetch notifications
  const fetchNotifications = async () => {
    try {
      const res = await notificationService.getNotifications();
      if (res.data?.success) {
        setNotifications(res.data.notifications || []);
        setUnreadCount(res.data.unreadCount || 0);
      }
    } catch (err) {
      console.warn('Failed to load notifications:', err.message);
    }
  };

  useEffect(() => {
    fetchNotifications();
    const interval = setInterval(fetchNotifications, 20000); // Polling every 20s
    return () => clearInterval(interval);
  }, []);

  const handleMarkAllRead = async () => {
    try {
      await notificationService.markAllAsRead();
      setUnreadCount(0);
      setNotifications(prev => prev.map(n => ({ ...n, is_read: 1 })));
    } catch (err) {
      console.error(err);
    }
  };

  const handleNotificationClick = async (notif) => {
    try {
      if (!notif.is_read) {
        await notificationService.markAsRead(notif.id);
        setUnreadCount(prev => Math.max(0, prev - 1));
        setNotifications(prev => prev.map(n => n.id === notif.id ? { ...n, is_read: 1 } : n));
      }
      setNotificationsOpen(false);

      if (notif.claim_id) {
        if (user.role === 'CUSTOMER') {
          navigate(`/customer/claims/${notif.claim_id}`);
        } else if (user.role === 'FRAUD_INVESTIGATOR') {
          navigate(`/fraud/investigate/${notif.claim_id}`);
        } else {
          navigate(`/staff/claims/${notif.claim_id}`);
        }
      }
    } catch (err) {
      console.error(err);
    }
  };

  // Build navigation items based on role
  const getNavItems = () => {
    switch (user?.role) {
      case 'CUSTOMER':
        return [
          { name: 'Dashboard', path: '/customer/dashboard', icon: LayoutDashboard },
          { name: 'Submit New Claim', path: '/customer/submit-claim', icon: FilePlus, highlight: true },
          { name: 'My Claims History', path: '/customer/claims', icon: FileText },
          { name: 'My Profile & Policies', path: '/customer/profile', icon: Shield },
          { name: 'Notifications', path: '/customer/notifications', icon: Bell, badge: unreadCount },
        ];
      case 'INSURANCE_STAFF':
        return [
          { name: 'Staff Dashboard', path: '/staff/dashboard', icon: LayoutDashboard },
          { name: 'Claims Queue', path: '/staff/claims', icon: FileText },
          { name: 'System Analytics', path: '/manager/reports', icon: BarChart3 },
          { name: 'Activity Audit Log', path: '/admin/audit-logs', icon: ScrollText },
        ];
      case 'FRAUD_INVESTIGATOR':
        return [
          { name: 'Fraud SIU Dashboard', path: '/fraud/dashboard', icon: ShieldAlert },
          { name: 'Suspicious Claims Queue', path: '/fraud/queue', icon: AlertTriangle, highlight: true },
          { name: 'All Claims Overview', path: '/staff/claims', icon: FileText },
          { name: 'Fraud Analytics', path: '/manager/reports', icon: BarChart3 },
          { name: 'Investigation Audit', path: '/admin/audit-logs', icon: ScrollText },
        ];
      case 'MANAGER':
        return [
          { name: 'Executive Dashboard', path: '/manager/dashboard', icon: LayoutDashboard },
          { name: 'Reports & Analytics', path: '/manager/reports', icon: BarChart3, highlight: true },
          { name: 'All Claims Review', path: '/staff/claims', icon: FileText },
          { name: 'SIU Fraud Queue', path: '/fraud/queue', icon: ShieldAlert },
          { name: 'System Audit Logs', path: '/admin/audit-logs', icon: ScrollText },
        ];
      case 'ADMIN':
        return [
          { name: 'Admin Dashboard', path: '/admin/dashboard', icon: LayoutDashboard },
          { name: 'User Management', path: '/admin/users', icon: Users, highlight: true },
          { name: 'All Claims Queue', path: '/staff/claims', icon: FileText },
          { name: 'SIU Fraud Queue', path: '/fraud/queue', icon: ShieldAlert },
          { name: 'Reports & Analytics', path: '/manager/reports', icon: BarChart3 },
          { name: 'Security Audit Logs', path: '/admin/audit-logs', icon: ScrollText },
          { name: 'System Settings', path: '/admin/settings', icon: Settings },
        ];
      default:
        return [];
    }
  };

  const navItems = getNavItems();

  const getRoleBadge = (role) => {
    switch (role) {
      case 'CUSTOMER':
        return { label: 'Policyholder', bg: 'bg-emerald-500/10 text-emerald-400 border-emerald-500/20' };
      case 'INSURANCE_STAFF':
        return { label: 'Claims Processor', bg: 'bg-blue-500/10 text-blue-400 border-blue-500/20' };
      case 'FRAUD_INVESTIGATOR':
        return { label: 'SIU Fraud Officer', bg: 'bg-purple-500/10 text-purple-400 border-purple-500/20' };
      case 'MANAGER':
        return { label: 'Operations Manager', bg: 'bg-amber-500/10 text-amber-400 border-amber-500/20' };
      case 'ADMIN':
        return { label: 'System Admin', bg: 'bg-rose-500/10 text-rose-400 border-rose-500/20' };
      default:
        return { label: role, bg: 'bg-slate-700 text-slate-300' };
    }
  };

  const roleBadge = getRoleBadge(user?.role);

  return (
    <div className="min-h-screen bg-slate-50 flex flex-col">
      {/* Top Demo Bar */}
      <div className="bg-slate-950 px-4 py-1.5 border-b border-slate-800 shrink-0">
        <div className="max-w-7xl mx-auto">
          <DemoCredentialsBar />
        </div>
      </div>

      <div className="flex-1 flex overflow-hidden">
        {/* Sidebar for Desktop */}
        <aside className="hidden lg:flex lg:flex-col w-64 bg-slate-900 border-r border-slate-800 text-white shrink-0">
          {/* Brand header */}
          <div className="p-6 border-b border-slate-800 flex items-center gap-3">
            <Link to="/" className="flex items-center gap-2.5">
              <div className="w-9 h-9 rounded-xl bg-gradient-to-tr from-indigo-600 to-indigo-400 flex items-center justify-center text-white shadow-md shadow-indigo-900/50">
                <Shield className="w-5 h-5 fill-white/20" />
              </div>
              <div>
                <span className="text-base font-extrabold tracking-tight text-white flex items-center gap-1">
                  Secure<span className="text-indigo-400">Claim</span>
                </span>
                <span className="block text-[10px] font-mono tracking-wider uppercase text-slate-400 -mt-0.5">
                  Enterprise Adjudication
                </span>
              </div>
            </Link>
          </div>

          {/* User Role Card */}
          <div className="p-4 mx-3 my-3 rounded-xl bg-slate-800/60 border border-slate-700/50">
            <div className="flex items-center gap-3">
              <div className="w-9 h-9 rounded-lg bg-indigo-600/30 text-indigo-300 flex items-center justify-center font-bold text-sm border border-indigo-500/30">
                {user?.name?.charAt(0) || 'U'}
              </div>
              <div className="overflow-hidden">
                <div className="text-xs font-semibold text-white truncate">{user?.name}</div>
                <div className="text-[11px] text-slate-400 truncate">{user?.email}</div>
              </div>
            </div>
            <div className="mt-2.5 pt-2 border-t border-slate-700/40 flex items-center justify-between">
              <span className={`text-[10px] font-semibold px-2 py-0.5 rounded-full border ${roleBadge.bg}`}>
                {roleBadge.label}
              </span>
              <span className="text-[10px] text-emerald-400 font-mono flex items-center gap-1">
                <span className="w-1.5 h-1.5 rounded-full bg-emerald-400 animate-pulse" />
                Online
              </span>
            </div>
          </div>

          {/* Navigation Links */}
          <nav className="flex-1 px-3 py-2 space-y-1 overflow-y-auto">
            {navItems.map((item) => {
              const isActive = location.pathname === item.path || location.pathname.startsWith(`${item.path}/`);
              const Icon = item.icon;

              return (
                <Link
                  key={item.path}
                  to={item.path}
                  className={`flex items-center justify-between px-3.5 py-2.5 rounded-xl text-xs font-medium transition-all ${
                    isActive
                      ? 'bg-indigo-600 text-white shadow-sm shadow-indigo-900/50 font-semibold'
                      : item.highlight
                      ? 'bg-indigo-950/60 text-indigo-300 hover:bg-indigo-900/50 hover:text-white border border-indigo-800/40'
                      : 'text-slate-300 hover:bg-slate-800 hover:text-white'
                  }`}
                >
                  <div className="flex items-center gap-3">
                    <Icon className={`w-4 h-4 shrink-0 ${isActive ? 'text-white' : item.highlight ? 'text-indigo-400' : 'text-slate-400'}`} />
                    <span>{item.name}</span>
                  </div>
                  {item.badge > 0 && (
                    <span className="px-2 py-0.5 text-[10px] font-bold rounded-full bg-rose-500 text-white animate-pulse">
                      {item.badge}
                    </span>
                  )}
                </Link>
              );
            })}
          </nav>

          {/* Bottom Actions */}
          <div className="p-4 border-t border-slate-800 space-y-2">
            <Link
              to="/"
              className="flex items-center gap-2.5 px-3 py-2 text-xs font-medium text-slate-400 hover:text-white hover:bg-slate-800 rounded-lg transition"
            >
              <Shield className="w-4 h-4 text-slate-500" />
              <span>Public Portal</span>
            </Link>
            <button
              type="button"
              onClick={() => { logout(); navigate('/login'); }}
              className="w-full flex items-center gap-2.5 px-3 py-2 text-xs font-medium text-rose-400 hover:bg-rose-950/40 hover:text-rose-300 rounded-lg transition"
            >
              <LogOut className="w-4 h-4" />
              <span>Sign Out</span>
            </button>
          </div>
        </aside>

        {/* Main Content Viewport */}
        <div className="flex-1 flex flex-col min-w-0 overflow-hidden">
          {/* Top Header Bar */}
          <header className="h-16 bg-white border-b border-slate-200/80 px-4 sm:px-6 lg:px-8 flex items-center justify-between shrink-0">
            {/* Mobile menu trigger */}
            <div className="flex items-center gap-3">
              <button
                type="button"
                onClick={() => setSidebarOpen(true)}
                className="lg:hidden p-2 rounded-lg text-slate-500 hover:bg-slate-100"
              >
                <Menu className="w-5 h-5" />
              </button>
              <div>
                <h1 className="text-base font-bold text-slate-900 capitalize">
                  {location.pathname.split('/')[2]?.replace('-', ' ') || 'Dashboard'}
                </h1>
                <p className="text-[11px] text-slate-400 hidden sm:block">
                  Insurance Claim Processing & Fraud Detection Platform
                </p>
              </div>
            </div>

            {/* Right side controls */}
            <div className="flex items-center gap-3">
              {/* Notification Popover */}
              <div className="relative">
                <button
                  type="button"
                  onClick={() => setNotificationsOpen(!notificationsOpen)}
                  className="relative p-2 rounded-xl text-slate-500 hover:bg-slate-100 hover:text-slate-700 transition"
                >
                  <Bell className="w-5 h-5" />
                  {unreadCount > 0 && (
                    <span className="absolute top-1 right-1 w-4 h-4 rounded-full bg-rose-500 text-white text-[10px] font-bold flex items-center justify-center">
                      {unreadCount}
                    </span>
                  )}
                </button>

                {/* Notifications Dropdown */}
                {notificationsOpen && (
                  <div className="absolute right-0 mt-2 w-80 sm:w-96 bg-white rounded-2xl shadow-2xl border border-slate-200/80 z-50 overflow-hidden">
                    <div className="px-4 py-3 border-b border-slate-100 flex items-center justify-between bg-slate-50/50">
                      <div className="flex items-center gap-2">
                        <span className="text-xs font-bold text-slate-900">Notifications</span>
                        {unreadCount > 0 && (
                          <span className="px-1.5 py-0.2 rounded-full text-[10px] font-semibold bg-rose-100 text-rose-700">
                            {unreadCount} new
                          </span>
                        )}
                      </div>
                      {unreadCount > 0 && (
                        <button
                          type="button"
                          onClick={handleMarkAllRead}
                          className="text-[11px] font-medium text-indigo-600 hover:text-indigo-800"
                        >
                          Mark all as read
                        </button>
                      )}
                    </div>

                    <div className="max-h-80 overflow-y-auto divide-y divide-slate-100">
                      {notifications.length === 0 ? (
                        <div className="p-6 text-center text-xs text-slate-400">
                          No notifications yet.
                        </div>
                      ) : (
                        notifications.slice(0, 15).map((notif) => (
                          <div
                            key={notif.id}
                            onClick={() => handleNotificationClick(notif)}
                            className={`p-3.5 hover:bg-slate-50 cursor-pointer transition ${
                              !notif.is_read ? 'bg-indigo-50/40' : ''
                            }`}
                          >
                            <div className="flex items-start justify-between gap-2">
                              <span className="text-xs font-semibold text-slate-900">{notif.title}</span>
                              <span className="text-[10px] text-slate-400 shrink-0 font-mono">
                                {new Date(notif.created_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                              </span>
                            </div>
                            <p className="text-xs text-slate-600 mt-1 line-clamp-2 leading-relaxed">
                              {notif.message}
                            </p>
                            {notif.claim_code && (
                              <span className="inline-block mt-1.5 text-[10px] font-mono font-semibold text-indigo-600 bg-indigo-50 px-1.5 py-0.5 rounded border border-indigo-100">
                                {notif.claim_code}
                              </span>
                            )}
                          </div>
                        ))
                      )}
                    </div>
                  </div>
                )}
              </div>

              {/* User Menu */}
              <div className="flex items-center gap-2.5 pl-3 border-l border-slate-200">
                <div className="w-8 h-8 rounded-lg bg-indigo-600 text-white font-bold text-xs flex items-center justify-center shadow-sm shadow-indigo-200">
                  {user?.name?.charAt(0) || 'U'}
                </div>
                <div className="hidden sm:block text-left">
                  <span className="block text-xs font-bold text-slate-900 leading-none">{user?.name}</span>
                  <span className="text-[10px] font-semibold text-indigo-600 leading-none">{roleBadge.label}</span>
                </div>
              </div>
            </div>
          </header>

          {/* Page Body */}
          <main className="flex-1 overflow-y-auto p-4 sm:p-6 lg:p-8">
            <div className="max-w-7xl mx-auto">
              <Outlet />
            </div>
          </main>
        </div>
      </div>
    </div>
  );
};

export default DashboardLayout;
