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
        setLoading(true);
        setError(null);
        
        console.log('🔍 Fetching admin profile...');
        const response = await adminApi.getProfile();
        
        console.log('📦 API Response:', response);
        console.log('📦 Response data:', response.data);
        
        // Check if response has the expected structure
        if (!response.data || !response.data.data) {
          console.error('❌ Invalid response structure:', response);
          throw new Error('Invalid response structure from API');
        }
        
        const data = response.data.data;
        console.log('🔍 Raw API Data:', data);
        
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
        
        console.log('✅ Parsed Admin Profile:', adminProfile);
        setProfile(adminProfile);
        
      } catch (err: any) {
        console.error("❌ Failed to fetch admin profile:", err);
        console.error("Error details:", {
          message: err.message,
          response: err.response,
          status: err.response?.status,
          data: err.response?.data
        });
        
        setError(err.message || "Failed to fetch admin profile");
        // Don't use default profile on error - keep trying
        // setProfile(defaultProfile);
      } finally {
        setLoading(false);
      }
    };

    fetchAdminProfile();
  }, []);

  const updateProfile = async (data: Partial<AdminProfile>) => {
    try {
      console.log('📝 Updating profile with:', data);
      const response = await adminApi.updateProfile(data);
      console.log('✅ Update response:', response.data);
      
      if (response.data.success && response.data.data) {
        const updatedData = response.data.data;
        const updatedProfile: AdminProfile = {
          namaLengkap: updatedData.namaLengkap || updatedData.nama_lengkap || updatedData.name,
          email: updatedData.email,
          tempatLahir: updatedData.tempatLahir || updatedData.tempat_lahir || '',
          tanggalLahir: updatedData.tanggalLahir || updatedData.tanggal_lahir || '',
          jenisKelamin: updatedData.jenisKelamin || updatedData.jenis_kelamin || '',
          noTlp: updatedData.noTlp || updatedData.no_tlp || '',
          role: updatedData.role,
          layanan: updatedData.layanan || 'Nebeng',
          foto: updatedData.foto || '',
        };
        setProfile(updatedProfile);
      } else {
        // Fallback: update local state
        setProfile((prev) => ({ ...prev, ...data }));
      }
    } catch (err) {
      console.error("❌ Failed to update admin profile:", err);
      throw err;
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