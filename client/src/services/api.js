import axios from 'axios';

const api = axios.create({
  baseURL: '/api',
  headers: {
    'Content-Type': 'application/json'
  }
});

// Request interceptor to attach JWT token
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => Promise.reject(error)
);

// Response interceptor for session expiration
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response && error.response.status === 401) {
      // Don't auto-clear if it was a login attempt failure
      const isLoginRequest = error.config.url.includes('/auth/login');
      if (!isLoginRequest) {
        localStorage.removeItem('token');
        localStorage.removeItem('user');
        if (window.location.pathname !== '/login') {
          window.location.href = '/login?expired=1';
        }
      }
    }
    return Promise.reject(error);
  }
);

// API service endpoints
export const authService = {
  login: (credentials) => api.post('/auth/login', credentials),
  register: (data) => api.post('/auth/register', data),
  getMe: () => api.get('/auth/me')
};

export const claimService = {
  getClaims: (params) => api.get('/claims', { params }),
  getClaimById: (id) => api.get(`/claims/${id}`),
  createClaim: (formData) => api.post('/claims', formData, {
    headers: { 'Content-Type': 'multipart/form-data' }
  }),
  updateStatus: (id, data) => api.put(`/claims/${id}/status`, data)
};

export const documentService = {
  upload: (claimId, formData) => api.post(`/documents/${claimId}/upload`, formData, {
    headers: { 'Content-Type': 'multipart/form-data' }
  }),
  verify: (documentId, data) => api.put(`/documents/${documentId}/verify`, data),
  downloadUrl: (documentId) => `/api/documents/${documentId}/download`
};

export const fraudService = {
  getQueue: (params) => api.get('/fraud/queue', { params }),
  getDetails: (claimId) => api.get(`/fraud/${claimId}`),
  updateInvestigation: (claimId, data) => api.put(`/fraud/${claimId}/investigate`, data)
};

export const reportService = {
  getSummary: () => api.get('/reports/summary'),
  getStatusDistribution: () => api.get('/reports/status'),
  getTypeDistribution: () => api.get('/reports/types'),
  getFraudDistribution: () => api.get('/reports/fraud'),
  getTrends: () => api.get('/reports/trends'),
  getExportData: () => api.get('/reports/export')
};

export const userService = {
  getUsers: (params) => api.get('/users', { params }),
  createUser: (data) => api.post('/users', data),
  updateRole: (id, roleName) => api.put(`/users/${id}/role`, { roleName }),
  toggleStatus: (id, status) => api.put(`/users/${id}/status`, { status })
};

export const policyService = {
  getPolicies: () => api.get('/policies'),
  createPolicy: (data) => api.post('/policies', data)
};

export const notificationService = {
  getNotifications: () => api.get('/notifications'),
  markAsRead: (id) => api.put(`/notifications/${id}/read`),
  markAllAsRead: () => api.put('/notifications/read-all')
};

export const auditService = {
  getLogs: (params) => api.get('/audit-logs', { params })
};

export const settingsService = {
  getSettings: () => api.get('/settings'),
  updateSetting: (data) => api.put('/settings', data)
};

export default api;
