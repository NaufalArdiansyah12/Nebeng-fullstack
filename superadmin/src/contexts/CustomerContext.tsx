import { createContext, useContext, useState, ReactNode, useEffect } from "react";
import { customerApi } from "../services/api";

// ==========================================
// 1. DEFINISI TIPE DATA (INTERFACES)
// ==========================================

// Format data untuk List Customer (Halaman Daftar)
export interface CustomerData {
  id: string;
  nama: string;
  email: string;
  no_tlp: string;
  status: string;
  tanggal: Date;
}

// Format data untuk Detail Customer (Halaman Detail)
export interface CustomerDetailData {
  id: string;
  nama: string;
  kode: string;
  status: "PENGAJUAN" | "TERVERIFIKASI" | "DITOLAK" | "DIBLOCK" | string;
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
    alamat: string;
  };
}

// ==========================================
// 2. STATE & CONTEXT DEFINITION
// ==========================================

const initialCustomerList: CustomerData[] = [];
const initialCustomerDetail: Record<string, CustomerDetailData> = {};

interface CustomerContextType {
  customerList: CustomerData[];
  customerDetail: Record<string, CustomerDetailData>;
  loading: boolean;
  error: string | null;

  fetchCustomerList: () => Promise<void>;
  fetchCustomerDetail: (id: string) => Promise<void>;
  updateCustomerStatus: (id: string, status: string) => void;
  updateCustomerInfo: (id: string, info: Partial<CustomerDetailData["informasiPribadi"]>) => void;
  blockCustomer: (id: string) => void;
  unblockCustomer: (id: string) => void;
}

const CustomerContext = createContext<CustomerContextType | undefined>(undefined);

// ==========================================
// 3. PROVIDER COMPONENT
// ==========================================

export const CustomerProvider = ({ children }: { children: ReactNode }) => {
  const [customerList, setCustomerList] = useState<CustomerData[]>(initialCustomerList);
  const [customerDetail, setCustomerDetail] = useState<Record<string, CustomerDetailData>>(initialCustomerDetail);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);

  // ------------------------------------------------
  // FETCH LIST CUSTOMER
  // ------------------------------------------------
  const fetchCustomerList = async () => {
    try {
      setLoading(true);
      setError(null);
      const response = await customerApi.getAll();
      
      const data = response.data;
      const customers = Array.isArray(data) ? data : [];

      const transformedList = customers.map((c: any) => ({
        id: String(c.id),
        nama: c.nama,
        email: c.email,
        no_tlp: c.no_tlp,
        status: c.status || "PENGAJUAN",
        tanggal: new Date(c.tanggal_daftar || Date.now()),
      }));

      setCustomerList(transformedList);
    } catch (err: any) {
      console.error("❌ Error fetching customers:", err);
      if (err.response?.status !== 401) {
        setError(err.response?.data?.message || "Gagal mengambil data customer");
      }
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchCustomerList();
  }, []);

  // ------------------------------------------------
  // FETCH DETAIL CUSTOMER - ✅ PERBAIKAN DI SINI
  // ------------------------------------------------
  const fetchCustomerDetail = async (id: string) => {
    try {
      const response = await customerApi.getById(id);
      const c = response.data;

      // ✅ MAPPING DATA DARI verifikasi_ktp_customers
      const detailData: CustomerDetailData = {
        id: String(c.id),
        nama: c.nama,
        kode: c.kode || "",
        status: c.status || "PENGAJUAN",
        informasiPribadi: {
          namaLengkap: c.nama || "",
          email: c.email || "",
          tempatLahir: "",
          tanggalLahir: c.tanggal_lahir || "",
          jenisKelamin: "",
          noTlp: c.no_tlp || "",
        },
        informasiKTP: {
          namaLengkap: c.nama_lengkap || c.nama || "",  // ✅ Dari verifikasi_ktp_customers
          nik: c.nik || "",  // ✅ Dari verifikasi_ktp_customers
          jenisKelamin: "",
          tanggalLahir: c.tanggal_lahir || "",  // ✅ Dari verifikasi_ktp_customers
          alamat: c.alamat || "",  // ✅ Dari verifikasi_ktp_customers
        },
      };

      setCustomerDetail(prev => ({ ...prev, [id]: detailData }));
    } catch (err) {
      console.error("❌ Error fetching customer detail:", err);
      throw err;
    }
  };

  // ------------------------------------------------
  // ACTION FUNCTIONS
  // ------------------------------------------------

  const updateCustomerStatus = (id: string, status: string) => {
    setCustomerList(prev => 
      prev.map(c => (c.id === id ? { ...c, status } : c))
    );

    setCustomerDetail(prev => {
      if (prev[id]) {
        return {
          ...prev,
          [id]: { ...prev[id], status }
        };
      }
      return prev;
    });

    customerApi.updateStatus(id, status).catch(err => {
      console.error("Gagal update status di server:", err);
    });
  };

  const updateCustomerInfo = (id: string, info: Partial<CustomerDetailData["informasiPribadi"]>) => {
    setCustomerList(prev =>
      prev.map(c =>
        c.id === id
          ? { 
              ...c, 
              nama: info.namaLengkap || c.nama, 
              email: info.email || c.email,
              no_tlp: info.noTlp || c.no_tlp
            }
          : c
      )
    );

    setCustomerDetail(prev => {
      if (prev[id]) {
        return {
          ...prev,
          [id]: {
            ...prev[id],
            nama: info.namaLengkap || prev[id].nama,
            informasiPribadi: { ...prev[id].informasiPribadi, ...info }
          }
        };
      }
      return prev;
    });

    customerApi.update(id, info).catch(err => {
      console.error("Gagal update info di server:", err);
    });
  };

  const blockCustomer = (id: string) => {
    updateCustomerStatus(id, "DIBLOCK");
  };

  const unblockCustomer = (id: string) => {
    updateCustomerStatus(id, "TERVERIFIKASI");
  };

  return (
    <CustomerContext.Provider
      value={{
        customerList,
        customerDetail,
        loading,
        error,
        fetchCustomerList,
        fetchCustomerDetail,
        updateCustomerStatus,
        updateCustomerInfo,
        blockCustomer,
        unblockCustomer,
      }}
    >
      {children}
    </CustomerContext.Provider>
  );
};

// ==========================================
// 4. CUSTOM HOOK
// ==========================================

export const useCustomer = () => {
  const context = useContext(CustomerContext);
  if (context === undefined) {
    throw new Error("useCustomer must be used within a CustomerProvider");
  }
  return context;
};