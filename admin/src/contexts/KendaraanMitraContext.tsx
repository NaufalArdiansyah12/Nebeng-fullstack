import { createContext, useContext, useState, ReactNode, useEffect } from "react";
import { mitraApi } from "../services/api";

export interface KendaraanMitraData {
  id: string;
  mitraId: string;
  namaMitra: string;
  kendaraan: "Mobil" | "Motor";
  merkKendaraan: string;
  platNomor: string;
  warna: string;
  tanggal: Date;
}

interface KendaraanMitraContextType {
  kendaraanMitraList: KendaraanMitraData[];
  loading: boolean;
  error: string | null;
  fetchKendaraanByMitra: (mitraId: string) => Promise<void>;
}

const KendaraanMitraContext = createContext<KendaraanMitraContextType | undefined>(undefined);

export function KendaraanMitraProvider({ children }: { children: ReactNode }) {
  const [kendaraanMitraList, setKendaraanMitraList] = useState<KendaraanMitraData[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Fetch all kendaraan from all mitra
  useEffect(() => {
    const fetchAllKendaraan = async () => {
      try {
        setLoading(true);
        setError(null);

        // First, get all mitra
        const mitraResponse = await mitraApi.getAll();
        const mitraList = Array.isArray(mitraResponse.data) ? mitraResponse.data : [];

        // Then fetch kendaraan for each mitra
        const allKendaraan: KendaraanMitraData[] = [];

        for (const mitra of mitraList) {
          try {
            const kendaraanResponse = await mitraApi.getKendaraan(String(mitra.id));
            const kendaraanData = Array.isArray(kendaraanResponse.data)
              ? kendaraanResponse.data
              : [];

            const transformed = kendaraanData.map((k: any) => ({
              id: String(k.id),
              mitraId: String(mitra.id),
              namaMitra: mitra.nama_lengkap || mitra.nama || "Unknown",
              kendaraan: (k.jenis_kendaraan || "Motor").charAt(0).toUpperCase() + (k.jenis_kendaraan || "Motor").slice(1),
              merkKendaraan: k.merek_kendaraan || k.merk || "",
              platNomor: k.plat_nomor || k.nomor_plat || "",
              warna: k.warna || "",
              tanggal: new Date(k.created_at || k.tanggal || new Date()),
            }));

            allKendaraan.push(...transformed);
          } catch (err) {
            console.error(`Failed to fetch kendaraan for mitra ${mitra.id}:`, err);
          }
        }

        setKendaraanMitraList(allKendaraan);
      } catch (err) {
        console.error("Failed to fetch all kendaraan:", err);
        setError(err instanceof Error ? err.message : "Failed to fetch kendaraan");
      } finally {
        setLoading(false);
      }
    };

    fetchAllKendaraan();
  }, []);

  const fetchKendaraanByMitra = async (mitraId: string) => {
    try {
      setLoading(true);
      setError(null);

      const response = await mitraApi.getKendaraan(mitraId);
      const kendaraanData = Array.isArray(response.data) ? response.data : [];

      const transformed = kendaraanData.map((k: any) => ({
        id: String(k.id),
        mitraId: String(mitraId),
        namaMitra: k.mitra_nama || "Unknown",
        kendaraan: (k.jenis_kendaraan || "Motor").charAt(0).toUpperCase() + (k.jenis_kendaraan || "Motor").slice(1),
        merkKendaraan: k.merek_kendaraan || k.merk || "",
        platNomor: k.plat_nomor || k.nomor_plat || "",
        warna: k.warna || "",
        tanggal: new Date(k.created_at || k.tanggal || new Date()),
      }));

      // Update list with new data for this mitra
      setKendaraanMitraList((prev) =>
        [
          ...prev.filter((k) => k.mitraId !== mitraId),
          ...transformed,
        ]
      );
    } catch (err) {
      console.error(`Failed to fetch kendaraan for mitra ${mitraId}:`, err);
      setError(err instanceof Error ? err.message : "Failed to fetch kendaraan");
    } finally {
      setLoading(false);
    }
  };

  const value = {
    kendaraanMitraList,
    loading,
    error,
    fetchKendaraanByMitra,
  };

  return (
    <KendaraanMitraContext.Provider value={value}>
      {children}
    </KendaraanMitraContext.Provider>
  );
}

export function useKendaraanMitra() {
  const context = useContext(KendaraanMitraContext);
  if (context === undefined) {
    throw new Error("useKendaraanMitra must be used within a KendaraanMitraProvider");
  }
  return context;
}
