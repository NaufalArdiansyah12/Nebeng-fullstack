import React, { createContext, useContext, useState, ReactNode, useEffect } from "react";
import { laporanApi } from "../services/api";

export interface LaporanData {
  id: string;
  noOrder: string;
  namaCustomer: string;
  customerId: string;
  tanggal: Date;
  layanan: string;
  laporan: string;
  status?: string;
  rating: number;
  type: 'customer_rating' | 'driver_rating';
  pickup_location?: string;
  destination?: string;
  customerAvatar?: string;
  customerPhone: string;
  customerNote: string;
  mitraId: string;
  namaMitra: string;
  mitraAvatar?: string;
  mitraPhone: string;
  mitraKendaraan: string;
  mitraMerkKendaraan: string;
  mitraPlatNomor: string;
  mitraEmail: string;
  mitraTempatLahir: string;
  mitraTanggalLahir: string;
  mitraJenisKelamin: string;
  tanggapan?: string;
}

interface LaporanContextType {
  laporanList: LaporanData[];
  getLaporanDetail: (id: string) => LaporanData | undefined;
  updateLaporan: (id: string, laporan: string) => void;
  respondLaporan: (id: string, tanggapan: string, status?: string) => Promise<void>;
  loading: boolean;
  error: string | null;
}

const LaporanContext = createContext<LaporanContextType | undefined>(undefined);

const initialLaporanData: LaporanData[] = [];

export const LaporanProvider = ({ children }: { children: ReactNode }) => {
  const [laporanList, setLaporanList] = useState<LaporanData[]>(initialLaporanData);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchLaporan = async () => {
      try {
        setLoading(true);
        setError(null);
        const response = await laporanApi.getAll();
        const laporan = Array.isArray(response.data) ? response.data : [];
        
        const transformedLaporan = laporan.map((l: any) => ({
          id: String(l.id),
          noOrder: l.no_order,
          namaCustomer: l.namaCustomer || l.customerName,
          customerId: String(l.customer_id || ""),
          tanggal: new Date(l.tanggal_laporan || new Date()),
          layanan: l.layanan,
          laporan: l.deskripsi_laporan || l.laporan,
          status: l.status,
          rating: l.rating || 0,
          type: l.type || 'customer_rating',
          pickup_location: l.pickup_location,
          destination: l.destination,
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
          tanggapan: l.admin_response || l.tanggapan || "",
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

  const respondLaporan = async (id: string, tanggapan: string, status?: string) => {
    try {
      await laporanApi.respond(id, { tanggapan, status });
      setLaporanList((prev) =>
        prev.map((item) =>
          item.id === id ? { 
            ...item, 
            tanggapan, 
            status: status || item.status 
          } : item
        )
      );
    } catch (err) {
      console.error("Failed to respond to laporan:", err);
      throw err;
    }
  };

  return (
    <LaporanContext.Provider value={{ laporanList, getLaporanDetail, updateLaporan, respondLaporan, loading, error }}>
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
