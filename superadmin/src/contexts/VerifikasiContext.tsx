import { createContext, useContext, useState, ReactNode, useEffect } from "react";
import { verifikasiApi } from "../services/api";

export interface VerifikasiMitraData {
  id: string; // Ini sekarang menggunakan user_id
  internalId: string; // ID asli dari tabel verifikasi_ktp_mitras
  userId: string;
  nikMitra: string;
  namaLengkap: string;
  tanggalLahir: Date;
  status: "pending" | "approved" | "rejected" | "diblock" | "aktif";
  tanggalPengajuan: Date;
}

export interface VerifikasiCustomerData {
  id: string; // Ini sekarang menggunakan user_id
  internalId: string; // ID asli dari tabel verifikasi_ktp_customers
  userId: string;
  nikCustomer: string;
  namaLengkap: string;
  tanggalLahir: Date;
  status: "pending" | "approved" | "rejected" | "diblock" | "aktif";
  tanggalPengajuan: Date;
}

interface VerifikasiContextType {
  verifikasiMitraList: VerifikasiMitraData[];
  verifikasiCustomerList: VerifikasiCustomerData[];
  updateVerifikasiMitraStatus: (userId: string, status: string) => void;
  updateVerifikasiCustomerStatus: (userId: string, status: string) => void;
  loading: boolean;
  error: string | null;
}

const VerifikasiContext = createContext<VerifikasiContextType | undefined>(undefined);

export function VerifikasiProvider({ children }: { children: ReactNode }) {
  const [verifikasiMitraList, setVerifikasiMitraList] = useState<VerifikasiMitraData[]>([]);
  const [verifikasiCustomerList, setVerifikasiCustomerList] = useState<VerifikasiCustomerData[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Fetch verifikasi mitra and customer on mount
  useEffect(() => {
    const fetchVerifikasi = async () => {
      try {
        setLoading(true);
        setError(null);

        // Fetch verifikasi mitra
        try {
          const mitraResponse = await verifikasiApi.getMitra();
          const mitraData = Array.isArray(mitraResponse.data) ? mitraResponse.data : [];
          
          const transformedMitra = mitraData.map((m: any) => ({
            id: String(m.user_id), // PERBAIKAN: Gunakan user_id sebagai ID utama
            internalId: String(m.id), // Simpan ID asli dari tabel
            userId: String(m.user_id),
            nikMitra: m.nik,
            namaLengkap: m.nama_lengkap,
            tanggalLahir: new Date(m.tanggal_lahir),
            status: (m.status || 'pending').toLowerCase(),
            tanggalPengajuan: new Date(m.tanggal_pengajuan || m.created_at),
          }));
          
          setVerifikasiMitraList(transformedMitra);
        } catch (err) {
          console.error("Failed to fetch verifikasi mitra:", err);
        }

        // Fetch verifikasi customer
        try {
          const customerResponse = await verifikasiApi.getCustomer();
          const customerData = Array.isArray(customerResponse.data) ? customerResponse.data : [];
          
          const transformedCustomer = customerData.map((c: any) => ({
            id: String(c.user_id), // PERBAIKAN: Gunakan user_id sebagai ID utama
            internalId: String(c.id), // Simpan ID asli dari tabel
            userId: String(c.user_id),
            nikCustomer: c.nik,
            namaLengkap: c.nama_lengkap,
            tanggalLahir: new Date(c.tanggal_lahir),
            status: (c.status || 'pending').toLowerCase(),
            tanggalPengajuan: new Date(c.tanggal_pengajuan || c.created_at),
          }));
          
          setVerifikasiCustomerList(transformedCustomer);
        } catch (err) {
          console.error("Failed to fetch verifikasi customer:", err);
        }
      } catch (err) {
        console.error("Failed to fetch verifikasi:", err);
        setError(err instanceof Error ? err.message : "Failed to fetch verifikasi");
      } finally {
        setLoading(false);
      }
    };

    fetchVerifikasi();
  }, []);

  // Update functions now use userId (which is the id field)
  const updateVerifikasiMitraStatus = (userId: string, status: string) => {
    setVerifikasiMitraList(prev =>
      prev.map(v => v.id === userId ? { ...v, status: status as any } : v)
    );
  };

  const updateVerifikasiCustomerStatus = (userId: string, status: string) => {
    setVerifikasiCustomerList(prev =>
      prev.map(v => v.id === userId ? { ...v, status: status as any } : v)
    );
  };

  const value = {
    verifikasiMitraList,
    verifikasiCustomerList,
    updateVerifikasiMitraStatus,
    updateVerifikasiCustomerStatus,
    loading,
    error,
  };

  return (
    <VerifikasiContext.Provider value={value}>
      {children}
    </VerifikasiContext.Provider>
  );
}

export function useVerifikasi() {
  const context = useContext(VerifikasiContext);
  if (context === undefined) {
    throw new Error("useVerifikasi must be used within a VerifikasiProvider");
  }
  return context;
}