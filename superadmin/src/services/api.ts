import axios from 'axios';

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:3001/api';

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

// Admin API
export const adminApi = {
  getProfile: () => api.get('/admin/profile'),
  updateProfile: (data: any) => api.put('/admin/profile', data),
};

// Customer API
export const customerApi = {
  getAll: () => api.get('/customers'),
  getById: (id: string) => api.get(`/customers/${id}`),
  create: (data: any) => api.post('/customers', data),
  update: (id: string, data: any) => api.put(`/customers/${id}`, data),
  delete: (id: string) => api.delete(`/customers/${id}`),
  updateStatus: (id: string, status: string) => api.patch(`/customers/${id}/status`, { status }),
  block: (id: string) => api.post(`/customers/${id}/block`),
  unblock: (id: string) => api.post(`/customers/${id}/unblock`),
};

// Mitra API
export const mitraApi = {
  getAll: () => api.get('/mitra'),
  getById: (id: string) => api.get(`/mitra/${id}`),
  create: (data: any) => api.post('/mitra', data),
  update: (id: string, data: any) => api.put(`/mitra/${id}`, data),
  
  // ✅ TAMBAHKAN INI
  updateMitra: (id: string, data: {
    nama: string;
    email: string;
    noTlp: string;
    jenisKelamin: string;
    ktp?: {
      nama_lengkap: string;
      nik: string;
      alamat: string;
      tanggal_lahir: string;
    };
  }) => api.put(`/mitra/${id}`, data),
  
  delete: (id: string) => api.delete(`/mitra/${id}`),
  updateStatus: (id: string, status: string) => api.patch(`/mitra/${id}/status`, { status }),
  block: (id: string) => api.post(`/mitra/${id}/block`),
  unblock: (id: string) => api.post(`/mitra/${id}/unblock`),
  getKendaraan: (id: string) => api.get(`/mitra/${id}/kendaraan`),
  addKendaraan: (id: string, data: any) => api.post(`/mitra/${id}/kendaraan`, data),
};

// Pesanan API
export const pesananApi = {
  getAll: () => api.get('/pesanan'),
  getById: (id: string) => api.get(`/pesanan/${id}`),
  create: (data: any) => api.post('/pesanan', data),
  updateStatus: (id: string, status: string) => api.patch(`/pesanan/${id}/status`, { status }),
  addPerjalanan: (id: string, data: any) => api.post(`/pesanan/${id}/perjalanan`, data),
  addPembayaran: (id: string, data: any) => api.post(`/pesanan/${id}/pembayaran`, data),
};

// Laporan API
export const laporanApi = {
  getAll: () => api.get('/laporan'),
  getById: (id: string) => api.get(`/laporan/${id}`),
  create: (data: any) => api.post('/laporan', data),
  updateStatus: (id: string, status: string) => api.patch(`/laporan/${id}/status`, { status }),
  delete: (id: string) => api.delete(`/laporan/${id}`),
};

// Refund API
export const refundApi = {
  getAll: () => api.get('/refund'),
  getById: (id: string) => api.get(`/refund/${id}`),
  create: (data: any) => api.post('/refund', data),
  updateStatus: (id: string, status: string) => api.patch(`/refund/${id}/status`, { status }),
  delete: (id: string) => api.delete(`/refund/${id}`),
};

// Verifikasi API
export const verifikasiApi = {
  getMitra: () => api.get('/verifikasi/mitra'),
  getCustomer: () => api.get('/verifikasi/customer'),
  updateMitraStatus: (id: string, status: string) => api.patch(`/verifikasi/mitra/${id}/status`, { status }),
  updateCustomerStatus: (id: string, status: string) => api.patch(`/verifikasi/customer/${id}/status`, { status }),
};

export default api;