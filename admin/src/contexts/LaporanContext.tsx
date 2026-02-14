import React, { createContext, useContext, useState, ReactNode, useEffect } from "react";
import { laporanApi } from "../services/api";

export interface LaporanData {
  id: string;
  noOrder: string;
  namaCustomer: string;
  customerId: string; // Link to CustomerContext
  tanggal: Date;
  layanan: string;
  laporan: string;
  status?: string;
  // Customer info
  customerAvatar?: string;
  customerPhone: string;
  customerNote: string;
  // Mitra info
  mitraId: string; // Link to MitraContext
  namaMitra: string;
  mitraAvatar?: string;
  mitraPhone: string;
  mitraKendaraan: string;
  mitraMerkKendaraan: string;
  mitraPlatNomor: string;
  // Mitra personal info for detail
  mitraEmail: string;
  mitraTempatLahir: string;
  mitraTanggalLahir: string;
  mitraJenisKelamin: string;
}

interface LaporanContextType {
  laporanList: LaporanData[];
  getLaporanDetail: (id: string) => LaporanData | undefined;
  updateLaporan: (id: string, laporan: string) => void;
  loading: boolean;
  error: string | null;
}

const LaporanContext = createContext<LaporanContextType | undefined>(undefined);

// Empty initial data - will be fetched from backend
const initialLaporanData: LaporanData[] = [];

export const LaporanProvider = ({ children }: { children: ReactNode }) => {
  const [laporanList, setLaporanList] = useState<LaporanData[]>(initialLaporanData);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Fetch laporan on mount
  useEffect(() => {
    const fetchLaporan = async () => {
      try {
        setLoading(true);
        setError(null);
        const response = await laporanApi.getAll();
        const laporan = Array.isArray(response.data) ? response.data : [];
        
        // Transform API response
        const transformedLaporan = laporan.map((l: any) => ({
          id: String(l.id),
          noOrder: l.no_order,
          namaCustomer: l.namaCustomer || l.customerName,
          customerId: String(l.customer_id || ""),
          tanggal: new Date(l.tanggal_laporan || new Date()),
          layanan: l.layanan,
          laporan: l.deskripsi_laporan || l.laporan,
          status: l.status,
          customerPhone: l.customerPhone || "",
          customerNote: "",
          mitraId: String(l.mitra_id || ""),
          namaMitra: l.namaMitra || l.driverName,
          mitraPhone: l.mitraPhone || l.driverPhone || "",
          mitraKendaraan: "",
          mitraMerkKendaraan: "",
          mitraPlatNomor: "",
          mitraEmail: "",
          mitraTempatLahir: "",
          mitraTanggalLahir: "",
          mitraJenisKelamin: "",
        }));
        
        setLaporanList(transformedLaporan);
      } catch (err) {
        console.error("Failed to fetch laporan:", err);
        setError(err instanceof Error ? err.message : "Failed to fetch laporan");
      } finally {
        setLoading(false);
      }
    };

    fetchLaporan();
  }, []);

  const getLaporanDetail = (id: string) => {
    return laporanList.find((laporan) => laporan.id === id);
  };

  const updateLaporan = (id: string, laporan: string) => {
    setLaporanList((prev) =>
      prev.map((item) =>
        item.id === id ? { ...item, laporan } : item
      )
    );
  };

  return (
    <LaporanContext.Provider value={{ laporanList, getLaporanDetail, updateLaporan, loading, error }}>
      {children}
    </LaporanContext.Provider>
  );
};

export const useLaporan = () => {
  const context = useContext(LaporanContext);
  if (!context) {
    throw new Error("useLaporan must be used within a LaporanProvider");
  }
  return context;
};
