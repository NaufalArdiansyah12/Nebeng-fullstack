import axios from 'axios';

// ✅ UPDATE: Connect ke Laravel backend
const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000/api/admin';

const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

// ✅ INTERCEPTOR UNTUK TOKEN
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
      console.log('🔑 Token added to request:', config.url);
    } else {
      console.warn('⚠️ No token found in localStorage');
    }
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// ✅ INTERCEPTOR UNTUK HANDLE ERROR RESPONSE
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      console.error('❌ Unauthorized - Token invalid or expired');
      // Optional: redirect to login
      // window.location.href = '/login';
    }
    
    // ✅ TAMBAHAN: Handle 403, 404, 500
    if (error.response?.status === 403) {
      console.error('❌ Forbidden - Access denied');
    }
    
    if (error.response?.status === 404) {
      console.error('❌ Not Found - Resource tidak ditemukan');
    }
    
    if (error.response?.status === 500) {
      console.error('❌ Server Error - Hubungi administrator');
    }
    
    return Promise.reject(error);
  }
);

// Admin API (Auth & Profile)
export const adminApi = {
  // Auth endpoints menggunakan /auth prefix
  login: (email: string, password: string) => 
    axios.post('http://localhost:8000/api/admin/auth/login', { email, password }),
  logout: () => api.post('/auth/logout'),
  verify: () => api.get('/auth/verify'),
  
  // Profile endpoints
  getProfile: () => api.get('/auth/profile'),
  updateProfile: (data: any) => api.put('/auth/profile', data),
};

// Dashboard API
export const dashboardApi = {
  getStatistics: (month?: number, year?: number) => {
    const params: any = {};
    if (month) params.month = month;
    if (year) params.year = year;
    return api.get('/dashboard', { params });
  },
};

// Customer API
export const customerApi = {
  getAll: (params?: any) => api.get('/customers', { params }),
  getPendingVerification: (params?: any) => api.get('/customers/pending-verification', { params }),
  getBlocked: (params?: any) => api.get('/customers/blocked', { params }),
  getById: (id: string) => api.get(`/customers/${id}`),
  verify: (id: string) => api.post(`/customers/${id}/verify`),
  block: (id: string, reason: string) => api.post(`/customers/${id}/block`, { reason }),
  unblock: (id: string) => api.post(`/customers/${id}/unblock`),
};

// Mitra API
export const mitraApi = {
  getAll: (params?: any) => api.get('/mitra', { params }),
  getById: (id: string) => api.get(`/mitra/${id}`),
  verify: (id: string) => api.post(`/mitra/${id}/verify`),
  reject: (id: string, reason: string) => api.post(`/mitra/${id}/reject`, { reason }),
  block: (id: string, reason: string) => api.post(`/mitra/${id}/block`, { reason }),
  unblock: (id: string) => api.post(`/mitra/${id}/unblock`),
  getVehicles: (id: string) => api.get(`/mitra/${id}/vehicles`),
  
  // Vehicle endpoints
  getAllVehicles: (params?: any) => api.get('/vehicles', { params }),
  getVehicleDetail: (id: string) => api.get(`/vehicles/${id}`),
};

// Pesanan API
export const pesananApi = {
  getAll: (params?: any) => api.get('/pesanan', { params }),
  getStatistics: () => api.get('/pesanan/statistics'),
  getById: (id: string) => api.get(`/pesanan/${id}`),
};

// Laporan API
export const laporanApi = {
  getAll: (params?: any) => api.get('/laporan', { params }),
  getStatistics: () => api.get('/laporan/statistics'),
  getById: (id: string) => api.get(`/laporan/${id}`),
  create: (data: any) => api.post('/laporan', data),
  updateStatus: (id: string, status: string, admin_notes?: string) => 
    api.put(`/laporan/${id}/status`, { status, admin_notes }),
  resolve: (id: string, resolution: string, action_taken?: string) => 
    api.post(`/laporan/${id}/resolve`, { resolution, action_taken }),
};

// Refund API
export const refundApi = {
  getAll: (params?: any) => api.get('/refund', { params }),
  getStatistics: () => api.get('/refund/statistics'),
  getById: (id: string) => api.get(`/refund/${id}`),
  approve: (id: string, admin_notes?: string, refund_amount?: number) => 
    api.post(`/refund/${id}/approve`, { admin_notes, refund_amount }),
  reject: (id: string, reason: string, admin_notes?: string) => 
    api.post(`/refund/${id}/reject`, { reason, admin_notes }),
  updateStatus: (id: string, status: string, admin_notes?: string) => 
    api.put(`/refund/${id}/status`, { status, admin_notes }),
};

// Verifikasi API (untuk kompatibilitas backward)
export const verifikasiApi = {
  getMitra: () => mitraApi.getAll({ status: 'pending' }),
  getCustomer: () => customerApi.getPendingVerification(),
  updateMitraStatus: (id: string, status: string) => {
    if (status === 'verified') return mitraApi.verify(id);
    if (status === 'rejected') return mitraApi.reject(id, 'Rejected by admin');
    return Promise.reject('Invalid status');
  },
  updateCustomerStatus: (id: string, status: string) => {
    if (status === 'verified') return customerApi.verify(id);
    return Promise.reject('Invalid status');
  },
};

export default api;