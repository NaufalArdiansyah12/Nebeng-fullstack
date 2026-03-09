import { createContext, useContext, useState, ReactNode } from "react";
import { mitraApi } from "../services/api";

export interface KendaraanMitraData {
  id: string;
  mitraId: string;
  kendaraan: "Mobil" | "Motor";
  merkKendaraan: string;
  platNomor: string;
  warna: string;
  tahun: number;
  tanggal: Date;
  status: string; // pending, approved, rejected, deletion_pending
}

interface KendaraanMitraContextType {
  kendaraanMitraList: KendaraanMitraData[];
  loading: boolean;
  error: string | null;
  fetchKendaraanByMitra: (mitraId: string) => Promise<void>;
  fetchAllKendaraan: () => Promise<void>;
  refreshData: (mitraId?: string) => Promise<void>;
}

const KendaraanMitraContext =
  createContext<KendaraanMitraContextType | undefined>(undefined);

export function KendaraanMitraProvider({ children }: { children: ReactNode }) {
  const [kendaraanMitraList, setKendaraanMitraList] = useState<KendaraanMitraData[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const fetchKendaraanByMitra = async (mitraId: string) => {
    try {
      setLoading(true);
      setError(null);

      const response = await mitraApi.getKendaraan(mitraId);

      // backend: { success: true, data: [...] }
      const kendaraanData = Array.isArray(response.data?.data)
        ? response.data.data
        : [];

      const transformed: KendaraanMitraData[] = kendaraanData.map((k: any) => ({
        id: String(k.id),
        mitraId: String(k.user_id),
        kendaraan:
          k.vehicle_type?.toLowerCase() === "mobil" ? "Mobil" : "Motor",
        merkKendaraan: k.name || "",
        platNomor: k.plate_number || "",
        warna: k.color || "",
        tahun: k.year || 0,
        tanggal: new Date(k.created_at),
        status: k.status || "pending", // pending, approved, rejected, deletion_pending
      }));

      setKendaraanMitraList(transformed);
    } catch (err) {
      console.error("Failed to fetch kendaraan:", err);
      setError(err instanceof Error ? err.message : "Failed to fetch kendaraan");
    } finally {
      setLoading(false);
    }
  };

  /* ===========================
     GET semua kendaraan dari semua mitra
     =========================== */
  const fetchAllKendaraan = async () => {
    try {
      setLoading(true);
      setError(null);

      const response = await mitraApi.getAllKendaraan();

      // backend: { success: true, data: [...] }
      const kendaraanData = Array.isArray(response.data?.data)
        ? response.data.data
        : [];

      const transformed: KendaraanMitraData[] = kendaraanData.map((k: any) => ({
        id: String(k.id),
        mitraId: String(k.user_id),
        kendaraan:
          k.vehicle_type?.toLowerCase() === "mobil" ? "Mobil" : "Motor",
        merkKendaraan: k.name || "",
        platNomor: k.plate_number || "",
        warna: k.color || "",
        tahun: k.year || 0,
        tanggal: new Date(k.created_at),
        status: k.status || "pending", // pending, approved, rejected, deletion_pending
      }));

      setKendaraanMitraList(transformed);
    } catch (err) {
      console.error("Failed to fetch all kendaraan:", err);
      setError(err instanceof Error ? err.message : "Failed to fetch kendaraan");
    } finally {
      setLoading(false);
    }
  };

  /* ===========================
     Refresh data (bisa untuk specific mitra atau semua)
     =========================== */
  const refreshData = async (mitraId?: string) => {
    if (mitraId) {
      await fetchKendaraanByMitra(mitraId);
    } else {
      await fetchAllKendaraan();
    }
  };

  return (
    <KendaraanMitraContext.Provider
      value={{
        kendaraanMitraList,
        loading,
        error,
        fetchKendaraanByMitra,
        fetchAllKendaraan,
        refreshData,
      }}
    >
      {children}
    </KendaraanMitraContext.Provider>
  );
}

export function useKendaraanMitra() {
  const context = useContext(KendaraanMitraContext);
  if (!context) {
    throw new Error("useKendaraanMitra must be used within KendaraanMitraProvider");
  }
  return context;
}