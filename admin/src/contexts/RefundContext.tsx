import { createContext, useContext, useState, ReactNode, useEffect } from "react";
import { refundApi } from "../services/api";

export interface RefundData {
  id: string;
  noOrder: string;
  namaCustomer: string;
  namaDriver: string;
  bookingType?: string;
  refundReason?: string;
  tanggal: Date;
  noTransaksi: string;
  jumlahRefund: number;
  status: "PROSES" | "SELESAI" | "BATAL";
}

export interface RefundDetail {
  id: string;
  noOrder: string;
  namaCustomer: string;
  namaDriver: string;
  bookingType?: string;
  refundReason?: string;
  tanggal: Date;
  noTransaksi: string;
  jumlahRefund: number;
  status: "PROSES" | "SELESAI" | "BATAL";
  idPesanan: string;
  metodeRefund: string;
  layananNebeng: string;
  biayaPenumpang: { quantity: number; price: number };
  biayaAdmin: number;
  totalRefund: number;
  titikJemput: { lokasi: string; waktu: string; alamat: string };
  tujuan: { lokasi: string; waktu: string; alamat: string };
}

const initialRefundList: RefundData[] = [];

interface RefundContextType {
  refundList: RefundData[];
  getRefundDetail: (id: string) => RefundDetail | undefined;
  updateRefundStatus: (id: string, status: "PROSES" | "SELESAI" | "BATAL") => void;
  loading: boolean;
  error: string | null;
}

const RefundContext = createContext<RefundContextType | undefined>(undefined);

export function RefundProvider({ children }: { children: ReactNode }) {
  const [refundList, setRefundList] = useState<RefundData[]>(initialRefundList);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Fetch refund on mount
  useEffect(() => {
    const fetchRefund = async () => {
      try {
        setLoading(true);
        setError(null);
        const response = await refundApi.getAll();
        const refund = Array.isArray(response.data) ? response.data : [];
        
        // Transform API response
        const transformedRefund = refund.map((r: any) => ({
          id: String(r.id),
          noOrder: String(r.no_order || r.booking_number || r.booking_id || ''),
          namaCustomer: r.namaCustomer || r.customerName || '',
          namaDriver: r.namaDriver || r.driverName || r.nama_driver || '',
          bookingType: r.booking_type || r.tipe || r.bookingType || '-',
          refundReason: r.refund_reason || r.alasan || r.reason || '-',
          tanggal: new Date(r.tanggal || r.submitted_at || r.tanggal_refund || r.created_at || new Date()),
          noTransaksi: r.no_transaksi || r.external_id || r.transaction_id || '',
          jumlahRefund: r.jumlah_refund ?? r.refund_amount ?? r.amount ?? 0,
          status: r.status,
        }));
        
        setRefundList(transformedRefund);
      } catch (err) {
        console.error("Failed to fetch refund:", err);
        setError(err instanceof Error ? err.message : "Failed to fetch refund");
      } finally {
        setLoading(false);
      }
    };

    fetchRefund();
  }, []);

  const updateRefundStatus = (id: string, status: "PROSES" | "SELESAI" | "BATAL") => {
    setRefundList(prev => prev.map(refund => 
      refund.id === id ? { ...refund, status } : refund
    ));
  };

  const getRefundDetail = (id: string): RefundDetail | undefined => {
    const refund = refundList.find((r) => r.id === id);
    if (!refund) return undefined;

    return {
      ...refund,
      idPesanan: "NEBENG-98299A",
      metodeRefund: "Transfer BRIVA",
      layananNebeng: "Motor",
      biayaPenumpang: { quantity: 2, price: 30000 },
      biayaAdmin: 0,
      totalRefund: refund.jumlahRefund,
      titikJemput: { lokasi: "Yogyakarta", waktu: "09.30 WIB", alamat: "Alun-alun Yogyakarta" },
      tujuan: { lokasi: "Purwokerto", waktu: "09.30 WIB", alamat: "Alun-alun Purwokerto" },
    };
  };

  const value = { refundList, getRefundDetail, updateRefundStatus, loading, error };

  return (
    <RefundContext.Provider value={value}>
      {children}
    </RefundContext.Provider>
  );
}

export function useRefund() {
  const context = useContext(RefundContext);
  if (context === undefined) {
    throw new Error("useRefund must be used within a RefundProvider");
  }
  return context;
}
