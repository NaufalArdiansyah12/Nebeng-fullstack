import React, { createContext, useContext, useState, useCallback } from "react";
import { locationsApi, posmitraApi } from "../services/api";

export interface PosMitraData {
  id: number;
  posmitra_id: number;
  nama_lengkap: string;
  nik: string;
  tanggal_lahir: string;
  jenis_kelamin: string;
  alamat: string;
  photo_ktp: string | null;
  status: string;
  reviewer_id: number | null;
  reviewed_at: string | null;
  meta: any;
  created_at: string;
  updated_at: string;
  terminal_name: string;
  terminal_city: string;
  terminal_address: string;
  terminal_latitude: number | null;
  terminal_longitude: number | null;
}

interface PosMitraContextType {
  posMitraList: PosMitraData[];
  isLoading: boolean;
  error: string | null;
  fetchPosMitra: () => Promise<void>;
  addPosMitra: (data: Omit<PosMitraData, "id">) => Promise<void>;
  updatePosMitra: (id: number, data: Partial<PosMitraData>) => Promise<void>;
  deletePosMitra: (id: number) => Promise<void>;
}

const PosMitraContext = createContext<PosMitraContextType | undefined>(
  undefined
);

export const usePosMitra = () => {
  const context = useContext(PosMitraContext);
  if (!context) {
    throw new Error("usePosMitra must be used within PosMitraProvider");
  }
  return context;
};

interface PosMitraProviderProps {
  children: React.ReactNode;
}

export const PosMitraProvider: React.FC<PosMitraProviderProps> = ({
  children,
}) => {
  const [posMitraList, setPosMitraList] = useState<PosMitraData[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const fetchPosMitra = useCallback(async () => {
    setIsLoading(true);
    setError(null);
    try {
      const [posmitraResponse, locationsResponse] = await Promise.all([
        posmitraApi.getAll(),
        locationsApi.getAll()
      ]);

      const posmitraData = posmitraResponse.data || [];
      const locationsData = locationsResponse.data || [];

      // Combine posmitra data with terminal data from locations
      const combinedData = posmitraData.map((posmitra: any) => {
        const terminal = locationsData.find((loc: any) => loc.id === posmitra.posmitra_id);
        return {
          ...posmitra,
          terminal_name: terminal?.name || '',
          terminal_city: terminal?.city || '',
          terminal_address: terminal?.address || '',
          terminal_latitude: terminal?.latitude || null,
          terminal_longitude: terminal?.longitude || null,
        };
      });

      // If no data, provide sample data
      if (combinedData.length === 0) {
        setPosMitraList([
          {
            id: 1,
            posmitra_id: 1,
            nama_lengkap: "John Doe",
            nik: "1234567890123456",
            tanggal_lahir: "1990-01-01",
            jenis_kelamin: "laki-laki",
            alamat: "Jl. Contoh No. 123",
            photo_ktp: null,
            status: "pending",
            reviewer_id: null,
            reviewed_at: null,
            meta: null,
            created_at: new Date().toISOString(),
            updated_at: new Date().toISOString(),
            terminal_name: "Terminal Purwokerto",
            terminal_city: "Purwokerto",
            terminal_address: "Jl. Jend Sudirman No.296",
            terminal_latitude: -7.4214,
            terminal_longitude: 109.2471,
          }
        ]);
      } else {
        setPosMitraList(combinedData);
      }
      setIsLoading(false);
    } catch (err) {
      // If API call fails, provide sample data
      console.warn('API call failed, using sample data:', err);
      setPosMitraList([
        {
          id: 1,
          posmitra_id: 1,
          nama_lengkap: "John Doe",
          nik: "1234567890123456",
          tanggal_lahir: "1990-01-01",
          jenis_kelamin: "laki-laki",
          alamat: "Jl. Contoh No. 123",
          photo_ktp: null,
          status: "pending",
          reviewer_id: null,
          reviewed_at: null,
          meta: null,
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString(),
          terminal_name: "Terminal Purwokerto",
          terminal_city: "Purwokerto",
          terminal_address: "Jl. Jend Sudirman No.296",
          terminal_latitude: -7.4214,
          terminal_longitude: 109.2471,
        }
      ]);
      setIsLoading(false);
    }
  }, []);

  const addPosMitra = useCallback(
    async (data: Omit<PosMitraData, "id">) => {
      setIsLoading(true);
      setError(null);
      try {
        const response = await locationsApi.create(data);
        const newPosMitra = response.data;
        setPosMitraList([...posMitraList, newPosMitra]);
        setIsLoading(false);
      } catch (err) {
        setError(err instanceof Error ? err.message : "An error occurred");
        setIsLoading(false);
      }
    },
    [posMitraList]
  );

  const updatePosMitra = useCallback(
    async (id: number, data: Partial<PosMitraData>) => {
      setIsLoading(true);
      setError(null);
      try {
        const response = await locationsApi.update(id.toString(), data);
        const updatedPosMitra = response.data;
        setPosMitraList(
          posMitraList.map((item) =>
            item.id === id ? updatedPosMitra : item
          )
        );
        setIsLoading(false);
      } catch (err) {
        setError(err instanceof Error ? err.message : "An error occurred");
        setIsLoading(false);
      }
    },
    [posMitraList]
  );

  const deletePosMitra = useCallback(
    async (id: number) => {
      setIsLoading(true);
      setError(null);
      try {
        await locationsApi.delete(id.toString());
        setPosMitraList(posMitraList.filter((item) => item.id !== id));
        setIsLoading(false);
      } catch (err) {
        setError(err instanceof Error ? err.message : "An error occurred");
        setIsLoading(false);
      }
    },
    [posMitraList]
  );

  return (
    <PosMitraContext.Provider
      value={{
        posMitraList,
        isLoading,
        error,
        fetchPosMitra,
        addPosMitra,
        updatePosMitra,
        deletePosMitra,
      }}
    >
      {children}
    </PosMitraContext.Provider>
  );
};