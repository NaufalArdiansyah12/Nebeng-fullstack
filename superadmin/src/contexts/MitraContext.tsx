import { createContext, useContext, useState, ReactNode, useEffect } from "react";
import { mitraApi } from "../services/api";

export interface MitraData {
  id: string;
  nama: string;
  email: string;
  noTlp: string;
  layanan: string;
  status: string;
  tanggal: Date;
  kode?: string;
}

// Interface untuk data KTP dari API
interface KtpData {
  id: number;
  mitra_id: number;
  nama_lengkap: string | null;
  nik: string | null;
  tanggal_lahir: string | null;
  alamat: string | null;
  photo_wajah: string | null;
  photo_ktp: string | null;
  photo_ktp_wajah: string | null;
  status: string | null;
  reviewer_id: number | null;
  reviewed_at: string | null;
  created_at: string;
  updated_at: string;
}

// Interface untuk data kendaraan
interface KendaraanData {
  id: number;
  user_id: number;
  vehicle_type: string;
  name: string;
  plate_number: string;
  brand: string;
  model: string;
  color: string;
  year: number;
  is_active: number;
  created_at: string;
  updated_at: string;
}

export interface MitraDetailData {
  id: string;
  nama: string;
  email: string;
  no_tlp: string | null;
  jenis_kelamin: string | null;
  tempat_lahir: string | null;
  tanggal_lahir: string | null;
  tanggal_daftar: string;
  layanan: string;
  kode: string;
  status: "PENGAJUAN" | "TERVERIFIKASI" | "DITOLAK" | "DIBLOCK";
  ktp_data: KtpData | null;
  kendaraan: KendaraanData[];
  
  // Backward compatibility
  informasiPribadi: {
    namaLengkap: string;
    email: string;
    tempatLahir: string;
    tanggalLahir: string;
    jenisKelamin: string;
    noTlp: string;
  };
  informasiKTP: {
    namaLengkap: string;
    nik: string;
    jenisKelamin: string;
    tanggalLahir: string;
    fotoKTP: string;
  };
  informasiSIM: {
    namaLengkap: string;
    nomorSIM: string;
    jenisKelamin: string;
    tanggalLahir: string;
    fotoSIM: string;
  };
}

interface MitraContextType {
  mitraList: MitraData[];
  mitraDetail: Record<string, MitraDetailData>;
  blockMitra: (id: string) => void;
  unblockMitra: (id: string) => void;
  updateMitraStatus: (id: string, status: "PENGAJUAN" | "TERVERIFIKASI" | "DITOLAK" | "DIBLOCK") => void;
  getMitraDetail: (id: string) => Promise<MitraDetailData | null>;
  loading: boolean;
  error: string | null;
}

const MitraContext = createContext<MitraContextType | undefined>(undefined);

export const MitraProvider = ({ children }: { children: ReactNode }) => {
  const [mitraList, setMitraList] = useState<MitraData[]>([]);
  const [mitraDetail, setMitraDetail] = useState<Record<string, MitraDetailData>>({});
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Fetch all mitra on mount
  useEffect(() => {
    const fetchMitra = async () => {
      try {
        setLoading(true);
        setError(null);
        const response = await mitraApi.getAll();
        
        // Transform API response to match MitraData interface
        const transformedMitra = response.data.map((m: any) => ({
          id: String(m.id),
          nama: m.nama,
          email: m.email,
          noTlp: m.no_tlp || m.noTlp || "",
          layanan: m.layanan,
          status: m.status || "PENGAJUAN",
          tanggal: new Date(m.tanggal_daftar || m.createdAt || new Date()),
          kode: m.kode || "",
        }));
        
        setMitraList(transformedMitra);
      } catch (err) {
        console.error("❌ Failed to fetch mitra list:", err);
        setError(err instanceof Error ? err.message : "Failed to fetch mitra");
      } finally {
        setLoading(false);
      }
    };

    fetchMitra();
  }, []);

  // Helper function to map status
  const mapStatus = (status: string | null): "PENGAJUAN" | "TERVERIFIKASI" | "DITOLAK" | "DIBLOCK" => {
    if (!status) return "PENGAJUAN";
    
    const statusMap: Record<string, "PENGAJUAN" | "TERVERIFIKASI" | "DITOLAK" | "DIBLOCK"> = {
      'pending': 'PENGAJUAN',
      'approved': 'TERVERIFIKASI',
      'rejected': 'DITOLAK',
      'suspended': 'DIBLOCK',
      'inactive': 'DIBLOCK'
    };
    
    return statusMap[status.toLowerCase()] || "PENGAJUAN";
  };

  // Fetch detail mitra by ID
  const getMitraDetail = async (id: string): Promise<MitraDetailData | null> => {
    try {
      // Check if already in cache
      if (mitraDetail[id]) {
        console.log(`✅ Mitra ${id} loaded from cache`);
        return mitraDetail[id];
      }

      console.log(`🔄 Fetching mitra ${id} from API...`);
      const response = await mitraApi.getById(id);
      const detail = response.data;

      console.log('📊 Raw API response:', detail);

      // Transform API response to match MitraDetailData interface
      const transformedDetail: MitraDetailData = {
        id: String(detail.id),
        nama: detail.nama,
        email: detail.email,
        no_tlp: detail.no_tlp,
        // Ambil dari ktp_data jika tidak ada di users
        jenis_kelamin: detail.jenis_kelamin || null,
        tempat_lahir: detail.tempat_lahir || null,
        tanggal_lahir: detail.tanggal_lahir || detail.ktp_data?.tanggal_lahir || null,
        tanggal_daftar: detail.tanggal_daftar,
        layanan: "Motor",
        kode: `#${detail.id}`,
        status: mapStatus(detail.ktp_data?.status),
        ktp_data: detail.ktp_data || null,
        kendaraan: detail.kendaraan || [],
        
        // Backward compatibility
        informasiPribadi: {
          namaLengkap: detail.nama || "",
          email: detail.email || "",
          tempatLahir: detail.tempat_lahir || "-",
          tanggalLahir: detail.tanggal_lahir || detail.ktp_data?.tanggal_lahir || "",
          jenisKelamin: detail.jenis_kelamin || "-",
          noTlp: detail.no_tlp || "",
        },
        informasiKTP: {
          namaLengkap: detail.ktp_data?.nama_lengkap || "",
          nik: detail.ktp_data?.nik || "",
          jenisKelamin: "-",
          tanggalLahir: detail.ktp_data?.tanggal_lahir || "",
          fotoKTP: detail.ktp_data?.photo_ktp || "/placeholder.svg",
        },
        informasiSIM: {
          namaLengkap: "-",
          nomorSIM: "-",
          jenisKelamin: "-",
          tanggalLahir: "-",
          fotoSIM: "/placeholder.svg",
        },
      };

      console.log('✅ Transformed detail:', transformedDetail);

      // Cache result
      setMitraDetail(prev => ({
        ...prev,
        [id]: transformedDetail
      }));

      console.log(`✅ Mitra ${id} fetched successfully`);
      return transformedDetail;
    } catch (err) {
      console.error(`❌ Failed to fetch mitra detail ${id}:`, err);
      return null;
    }
  };

  const blockMitra = async (id: string) => {
    try {
      // Update UI immediately
      setMitraList(prev => 
        prev.map(mitra => 
          mitra.id === id ? { ...mitra, status: "DIBLOCK" } : mitra
        )
      );
      
      setMitraDetail(prev => {
        if (prev[id]) {
          return {
            ...prev,
            [id]: { ...prev[id], status: "DIBLOCK" }
          };
        }
        return prev;
      });
      
      // Call API
      await mitraApi.block(id);
      console.log(`✅ Mitra ${id} blocked successfully`);
    } catch (err) {
      console.error(`❌ Failed to block mitra ${id}:`, err);
      // Revert on error
      setMitraList(prev => 
        prev.map(mitra => 
          mitra.id === id ? { ...mitra, status: "TERVERIFIKASI" } : mitra
        )
      );
    }
  };

  const unblockMitra = async (id: string) => {
    try {
      // Update UI immediately
      setMitraList(prev => 
        prev.map(mitra => 
          mitra.id === id ? { ...mitra, status: "TERVERIFIKASI" } : mitra
        )
      );
      
      setMitraDetail(prev => {
        if (prev[id]) {
          return {
            ...prev,
            [id]: { ...prev[id], status: "TERVERIFIKASI" }
          };
        }
        return prev;
      });
      
      // Call API
      await mitraApi.unblock(id);
      console.log(`✅ Mitra ${id} unblocked successfully`);
    } catch (err) {
      console.error(`❌ Failed to unblock mitra ${id}:`, err);
      // Revert on error
      setMitraList(prev => 
        prev.map(mitra => 
          mitra.id === id ? { ...mitra, status: "DIBLOCK" } : mitra
        )
      );
    }
  };

  const updateMitraStatus = async (id: string, status: "PENGAJUAN" | "TERVERIFIKASI" | "DITOLAK" | "DIBLOCK") => {
    try {
      // Update UI immediately
      setMitraList(prev => 
        prev.map(mitra => 
          mitra.id === id ? { ...mitra, status } : mitra
        )
      );
      
      setMitraDetail(prev => {
        if (prev[id]) {
          return {
            ...prev,
            [id]: { ...prev[id], status }
          };
        }
        return prev;
      });

      // Call API
      await mitraApi.updateStatus(id, status);
      console.log(`✅ Mitra ${id} status updated to ${status}`);
    } catch (err) {
      console.error(`❌ Failed to update mitra ${id} status:`, err);
    }
  };

  return (
    <MitraContext.Provider value={{ 
      mitraList, 
      mitraDetail, 
      blockMitra, 
      unblockMitra, 
      updateMitraStatus, 
      getMitraDetail, 
      loading, 
      error 
    }}>
      {children}
    </MitraContext.Provider>
  );
};

export const useMitra = () => {
  const context = useContext(MitraContext);
  if (!context) {
    throw new Error("useMitra must be used within a MitraProvider");
  }
  return context;
};