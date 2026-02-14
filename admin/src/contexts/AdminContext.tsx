import { createContext, useContext, useState, ReactNode, useEffect } from "react";
import { adminApi } from "../services/api";

export interface AdminProfile {
  namaLengkap: string;
  email: string;
  tempatLahir: string;
  tanggalLahir: string;
  jenisKelamin: string;
  noTlp: string;
  role: string;
  layanan: string;
  foto: string;
}

interface AdminContextType {
  profile: AdminProfile;
  updateProfile: (data: Partial<AdminProfile>) => Promise<void>;
  loading: boolean;
  error: string | null;
}

const defaultProfile: AdminProfile = {
  namaLengkap: "Administrator",
  email: "admin@nebeng.local",
  tempatLahir: "Indonesia",
  tanggalLahir: "",
  jenisKelamin: "",
  noTlp: "",
  role: "Admin",
  layanan: "Nebeng",
  foto: "",
};

const AdminContext = createContext<AdminContextType | undefined>(undefined);

export function AdminProvider({ children }: { children: ReactNode }) {
  const [profile, setProfile] = useState<AdminProfile>(defaultProfile);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Fetch admin profile from backend on mount
  useEffect(() => {
    const fetchAdminProfile = async () => {
      try {
        // Check if token exists
        const token = localStorage.getItem('token');
        if (!token) {
          console.log('⚠️ No token found, skipping profile fetch');
          setLoading(false);
          return;
        }

        setLoading(true);
        setError(null);
        
        console.log('🔍 Fetching admin profile from Laravel...');
        const response = await adminApi.getProfile();
        
        console.log('📦 Laravel Response:', response.data);
        
        // Laravel returns: { success: true, data: {...} }
        if (!response.data || !response.data.success) {
          console.error('❌ Invalid response from Laravel:', response);
          throw new Error('Invalid response from server');
        }
        
        const data = response.data.data;
        console.log('✅ Profile data from Laravel:', data);
        
        const adminProfile: AdminProfile = {
          namaLengkap: data.namaLengkap || data.nama_lengkap || data.name || defaultProfile.namaLengkap,
          email: data.email || defaultProfile.email,
          tempatLahir: data.tempatLahir || data.tempat_lahir || defaultProfile.tempatLahir,
          tanggalLahir: data.tanggalLahir || data.tanggal_lahir || defaultProfile.tanggalLahir,
          jenisKelamin: data.jenisKelamin || data.jenis_kelamin || defaultProfile.jenisKelamin,
          noTlp: data.noTlp || data.no_tlp || defaultProfile.noTlp,
          role: data.role || defaultProfile.role,
          layanan: data.layanan || defaultProfile.layanan,
          foto: data.foto || defaultProfile.foto,
        };
        
        console.log('✅ Admin Profile loaded:', adminProfile);
        setProfile(adminProfile);
        
      } catch (err: any) {
        console.error("❌ Failed to fetch admin profile:", err);
        
        // If 401, token invalid - redirect to login
        if (err.response?.status === 401) {
          console.log('🔒 Token invalid, clearing localStorage');
          localStorage.removeItem('token');
          localStorage.removeItem('user');
        }
        
        setError(err.response?.data?.message || err.message || "Failed to fetch admin profile");
        setProfile(defaultProfile);
      } finally {
        setLoading(false);
      }
    };

    fetchAdminProfile();
  }, []);

  const updateProfile = async (data: Partial<AdminProfile>) => {
    try {
      setLoading(true);
      console.log('📝 Updating profile to Laravel:', data);
      
      const response = await adminApi.updateProfile(data);
      console.log('✅ Profile updated:', response.data);
      
      if (response.data.success) {
        // Merge updated data with current profile
        setProfile(prev => ({
          ...prev,
          ...data
        }));
      }
    } catch (err: any) {
      console.error('❌ Failed to update profile:', err);
      setError(err.response?.data?.message || err.message || 'Failed to update profile');
      throw err;
    } finally {
      setLoading(false);
    }
  };

  return (
    <AdminContext.Provider value={{ profile, updateProfile, loading, error }}>
      {children}
    </AdminContext.Provider>
  );
}

export function useAdmin() {
  const context = useContext(AdminContext);
  if (context === undefined) {
    throw new Error("useAdmin must be used within an AdminProvider");
  }
  return context;
}