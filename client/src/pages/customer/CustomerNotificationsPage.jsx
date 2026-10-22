import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { notificationService } from '../../services/api';
import { Bell, CheckCircle2, ArrowRight } from 'lucide-react';
import Button from '../../components/common/Button';

const CustomerNotificationsPage = () => {
  const [notifications, setNotifications] = useState([]);
  const [isLoading, setIsLoading] = useState(true);

  const fetchNotifs = async () => {
    try {
      const res = await notificationService.getNotifications();
      if (res.data?.success) {
        setNotifications(res.data.notifications || []);
      }
    } catch (err) {
      console.error(err);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchNotifs();
  }, []);

  const handleMarkAllRead = async () => {
    try {
      await notificationService.markAllAsRead();
      setNotifications(prev => prev.map(n => ({ ...n, is_read: 1 })));
    } catch (err) {
      console.error(err);
    }
  };

  const handleSingleRead = async (id) => {
    try {
      await notificationService.markAsRead(id);
      setNotifications(prev => prev.map(n => n.id === id ? ({ ...n, is_read: 1 }) : n));
    } catch (err) {
      console.error(err);
    }
  };

  return (
    <div className="space-y-6 max-w-3xl mx-auto">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-xl sm:text-2xl font-extrabold text-slate-900 tracking-tight">
            Notifications Center
          </h2>
          <p className="text-xs text-slate-500 mt-0.5">
            Adjudication alerts, document reviews, and settlement announcements
          </p>
        </div>
        {notifications.some(n => !n.is_read) && (
          <Button size="sm" variant="outline" onClick={handleMarkAllRead}>
            Mark All Read
          </Button>
        )}
      </div>

      <div className="bg-white rounded-2xl border border-slate-200/90 shadow-sm overflow-hidden">
        {isLoading ? (
          <div className="py-12 text-center text-xs text-slate-400">Loading alerts...</div>
        ) : notifications.length === 0 ? (
          <div className="py-16 text-center">
            <Bell className="w-10 h-10 text-slate-300 mx-auto mb-2" />
            <p className="text-xs text-slate-500">No notifications yet.</p>
          </div>
        ) : (
          <div className="divide-y divide-slate-100">
            {notifications.map((notif) => (
              <div
                key={notif.id}
                className={`p-4 transition flex items-start justify-between gap-4 ${
                  !notif.is_read ? 'bg-indigo-50/40' : 'hover:bg-slate-50'
                }`}
              >
                <div className="flex items-start gap-3">
                  <div className={`w-8 h-8 rounded-full flex items-center justify-center shrink-0 mt-0.5 ${
                    notif.type === 'SUCCESS' ? 'bg-emerald-100 text-emerald-600' :
                    notif.type === 'ALERT' ? 'bg-rose-100 text-rose-600' :
                    notif.type === 'WARNING' ? 'bg-amber-100 text-amber-600' :
                    'bg-blue-100 text-blue-600'
                  }`}>
                    <Bell className="w-4 h-4" />
                  </div>
                  <div>
                    <h4 className="text-xs font-bold text-slate-900">{notif.title}</h4>
                    <p className="text-xs text-slate-600 mt-0.5 leading-relaxed">{notif.message}</p>
                    <div className="flex items-center gap-3 mt-2 text-[10px] text-slate-400">
                      <span className="font-mono">{new Date(notif.created_at).toLocaleString()}</span>
                      {notif.claim_code && (
                        <Link
                          to={`/customer/claims/${notif.claim_id}`}
                          onClick={() => handleSingleRead(notif.id)}
                          className="font-bold text-indigo-600 hover:text-indigo-800 flex items-center gap-1"
                        >
                          View Claim {notif.claim_code} <ArrowRight className="w-3 h-3" />
                        </Link>
                      )}
                    </div>
                  </div>
                </div>

                {!notif.is_read && (
                  <button
                    type="button"
                    onClick={() => handleSingleRead(notif.id)}
                    className="p-1 rounded text-slate-400 hover:text-indigo-600"
                    title="Mark as read"
                  >
                    <CheckCircle2 className="w-4 h-4" />
                  </button>
                )}
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
};

export default CustomerNotificationsPage;
