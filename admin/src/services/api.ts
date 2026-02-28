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
    // Log error details for debugging
    console.error('🔴 API Error:', error.message, error.response?.status);
    
    if (error.response?.status === 401) {
      console.error('❌ Unauthorized - Token invalid or expired');
    }
    
    if (error.response?.status === 403) {
      console.error('❌ Forbidden - Access denied');
    }
    
    if (error.response?.status === 404) {
      console.error('❌ Not Found - Resource tidak ditemukan');
      // Extract the error message from backend response if available
      const errorMessage = error.response?.data?.error || 'Resource not found';
      // Return a rejected promise with the error message so the calling code can handle it properly
      return Promise.reject(new Error(errorMessage));
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
  // ✅ UPDATED: Hanya kirim newPassword (tidak perlu currentPassword)
  updatePassword: (data: { newPassword: string }) => api.put('/admin/password', data),
};

// Customer API
export const customerApi = {
  // Get operations
  getAll: () => api.get('/customers'),
  getById: (id: string) => api.get(`/customers/${id}`),
  
  // Create operation
  create: (data: any) => api.post('/customers', data),
  
  // Update operations - UPDATED ✅
  update: (id: string, data: any) => api.put(`/customers/${id}`, data),
  
  // Full update dengan semua field
  updateCustomer: (id: string, data: {
    // Info Pribadi
    nama?: string;
    email?: string;
    noTlp?: string;
    jenisKelamin?: string;
    tanggalLahir?: string;
    alamat?: string;
    
    // Info KTP
    nik?: string;
    namaLengkapKtp?: string;
    jenisKelaminKtp?: string;
    
    // Photos
    photoWajah?: string;
    photoKtp?: string;
    
    // Backward compatibility
    ktp?: {
      nama_lengkap?: string;
      nik?: string;
      alamat?: string;
      tanggal_lahir?: string;
    };
  }) => api.put(`/customers/${id}`, data),
  
  // Partial update - hanya update field tertentu
  updateFields: (id: string, fields: {
    nama?: string;
    email?: string;
    noTlp?: string;
    no_tlp?: string;
    jenisKelamin?: string;
    jenis_kelamin?: string;
    nik?: string;
    alamat?: string;
    tanggalLahir?: string;
    tanggal_lahir?: string;
    photoWajah?: string;
    photo_wajah?: string;
    photoKtp?: string;
    photo_ktp?: string;
    namaLengkapKtp?: string;
    jenisKelaminKtp?: string;
  }) => api.patch(`/customers/${id}/fields`, fields),
  
  // Delete operation
  delete: (id: string) => api.delete(`/customers/${id}`),
  
  // Status operations
  updateStatus: (id: string, status: string) => api.patch(`/customers/${id}/status`, { status }),
  block: (id: string) => api.post(`/customers/${id}/block`),
  unblock: (id: string) => api.post(`/customers/${id}/unblock`),
};

// Mitra API
export const mitraApi = {
  getAll: () => api.get('/mitra'),
  getById: (id: string) => api.get(`/mitra/${id}`),
  getMitraById: (id: string) => api.get(`/mitra/${id}`),
  create: (data: any) => api.post('/mitra', data),
  update: (id: string, data: any) => api.put(`/mitra/${id}`, data),
  updateMitra: (id: string, data: {
    nama: string;
    email: string;
    noTlp: string;
    jenisKelamin: string;
    tanggalLahir?: string;
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
  // Kendaraan
  getKendaraan: (id: string) => api.get(`/mitra/${id}/kendaraan`),
  getAllKendaraan: () => api.get(`/mitra/kendaraan/all`),
  getKendaraanDetail: (mitraId: string, kendaraanId: string) => api.get(`/mitra/${mitraId}/kendaraan/${kendaraanId}`),
  getKendaraanDetailById: (kendaraanId: string) => api.get(`/mitra/kendaraan/detail/${kendaraanId}`),
  addKendaraan: (id: string, data: any) => api.post(`/mitra/${id}/kendaraan`, data),
  updateKendaraan: (mitraId: string, kendaraanId: string, data: any) => api.put(`/mitra/${mitraId}/kendaraan/${kendaraanId}`, data),
  deleteKendaraan: (mitraId: string, kendaraanId: string) => api.delete(`/mitra/${mitraId}/kendaraan/${kendaraanId}`),
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
  respond: (id: string, data: { tanggapan: string }) => api.post(`/laporan/${id}/respond`, data),
};

// Refund API
export const refundApi = {
  getAll: () => api.get('/refund'),
  getById: (id: string) => api.get(`/refund/${id}`),
  create: (data: any) => api.post('/refund', data),
  updateStatus: (id: string, status: string) => api.patch(`/refund/${id}/status`, { status }),
  delete: (id: string) => api.delete(`/refund/${id}`),
};

// Dashboard API
export const dashboardApi = {
  getStats: () => api.get('/dashboard/stats'),
  getOrderChart: (month?: number, year?: number) => {
    const params = month && year ? { month, year } : {};
    return api.get('/dashboard/orders/chart', { params });
  },
  getTopDestinations: (month?: number, year?: number) => {
    const params = month && year ? { month, year } : {};
    return api.get('/dashboard/destinations/top', { params });
  },
  getRecentMitra: (month?: number, year?: number) => {
    const params = month && year ? { month, year } : {};
    return api.get('/dashboard/mitra/recent', { params });
  },
  getAllMitra: () => api.get('/dashboard/mitra/all'),
};

// Verifikasi API
export const verifikasiApi = {
  getMitra: () => api.get('/verifikasi/mitra'),
  getCustomer: () => api.get('/verifikasi/customer'),
  updateMitraStatus: (id: string, status: string) => api.patch(`/verifikasi/mitra/${id}/status`, { status }),
  updateCustomerStatus: (id: string, status: string) => api.patch(`/verifikasi/customer/${id}/status`, { status }),
};

// Locations API
export const locationsApi = {
  getAll: () => api.get('/locations'),
  getById: (id: string) => api.get(`/locations/${id}`),
  create: (data: any) => api.post('/locations', data),
  update: (id: string, data: any) => api.put(`/locations/${id}`, data),
  delete: (id: string) => api.delete(`/locations/${id}`),
};

// Posmitra API
export const posmitraApi = {
  getAll: () => api.get('/posmitra'),
  getById: (id: string) => api.get(`/posmitra/${id}`),
  create: (data: any) => api.post('/posmitra', data),
  update: (id: string, data: any) => api.put(`/posmitra/${id}`, data),
  approve: (id: string, data: any) => api.patch(`/posmitra/${id}/approve`, data),
  delete: (id: string) => api.delete(`/posmitra/${id}`),
};

// Posmitra Users API ✅ UPDATED
export const posmitraUsersApi = {
  getAll: () => api.get('/posmitra-users'),
  getById: (id: string) => api.get(`/posmitra-users/${id}`),
  create: (data: any) => api.post('/posmitra-users', data),
  update: (id: string, data: any) => api.put(`/posmitra-users/${id}`, data),
  delete: (id: string) => api.delete(`/posmitra-users/${id}`),
};

// Reward API
export const rewardApi = {
  getAll: () => api.get('/reward'),
  getById: (id: string) => api.get(`/reward/${id}`),
  updateStatus: (id: string, status: string) => api.patch(`/reward/${id}/status`, { status }),
  delete: (id: string) => api.delete(`/reward/${id}`),
  getAllRewards: () => api.get('/reward/rewards/all'),
};

// Banners API
export const bannersApi = {
  getAll: () => api.get('/v1/banners'),
  getById: (id: string) => api.get(`/v1/banners/${id}`),
  create: (data: any) => api.post('/v1/banners', data),
  update: (id: string, data: any) => api.put(`/v1/banners/${id}`, data),
  delete: (id: string) => api.delete(`/v1/banners/${id}`),
};

export default api;
