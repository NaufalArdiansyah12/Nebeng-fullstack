import { createContext, useContext, useState, ReactNode, useEffect } from "react";
import { pesananApi } from "../services/api";

export interface PesananData {
  id: string;
  noOrder: string;
  namaCustomer: string;
  namaDriver: string;
  tanggal: Date;
  layanan: string;
  harga: number;
  status: "PROSES" | "SELESAI" | "BATAL";
}

export interface PesananDetailData {
  id: string;
  idPesanan: string;
  status: "PROSES" | "SELESAI" | "BATAL";
  customer: {
    nama: string;
    namaLengkap: string;
    noTlp: string;
    catatan: string;
  };
  mitra: {
    nama: string;
    kode: string;
    namaLengkap: string;
    noTlp: string;
    kendaraan: string;
    merkKendaraan: string;
    platNomor: string;
  };
  perjalanan: {
    tanggal: string;
    jarak: string;
    durasi: string;
    titikJemput: {
      lokasi: string;
      waktu: string;
      alamat: string;
    };
    tujuan: {
      lokasi: string;
      waktu: string;
      alamat: string;
    };
  };
  pembayaran: {
    type: string;
    tanggal: string;
    idPesanan: string;
    noTransaksi: string;
    biayaPenebeng: number;
    biayaAdmin: number;
    total: number;
  };
}

// Empty initial list - will be fetched from backend
const initialPesananList: PesananData[] = [];

// Empty initial detail - will be fetched from backend
const initialPesananDetail: Record<string, PesananDetailData> = {
  "P001": {
    id: "P001",
    idPesanan: "NEBENG-A9823818734710",
    status: "PROSES",
    customer: {
      nama: "Clara Aulia",
      namaLengkap: "Clara Aulia Putri",
      noTlp: "089373933994",
      catatan: "Jika sudah di titik, maju lagi sedikit yah mas.",
    },
    mitra: {
      nama: "Muhammad Abdul",
      kode: "001235",
      namaLengkap: "Muhammad Abdul Kadir",
      noTlp: "080373933994",
      kendaraan: "Motor",
      merkKendaraan: "HONDA",
      platNomor: "B 4949 MBH",
    },
    perjalanan: {
      tanggal: "Selasa, 17.10.2023",
      jarak: "14 km",
      durasi: "25 menit",
      titikJemput: { lokasi: "Yogyakarta", waktu: "09.30 WIB", alamat: "Alun-alun Yogyakarta" },
      tujuan: { lokasi: "Purwokerto", waktu: "09.55 WIB", alamat: "Alun-alun Purwokerto" },
    },
    pembayaran: {
      type: "QRIS",
      tanggal: "17/10/2023",
      idPesanan: "NEBENG-98299A",
      noTransaksi: "INV/20231017/123456789",
      biayaPenebeng: 45000,
      biayaAdmin: 15000,
      total: 60000,
    },
  },
  "P002": {
    id: "P002",
    idPesanan: "NEBENG-B7234567891234",
    status: "SELESAI",
    customer: {
      nama: "Budi Santoso",
      namaLengkap: "Budi Santoso Wijaya",
      noTlp: "081234567890",
      catatan: "Tolong hubungi sebelum sampai ya.",
    },
    mitra: {
      nama: "Ahmad Rizki",
      kode: "001236",
      namaLengkap: "Ahmad Rizki Pratama",
      noTlp: "082345678901",
      kendaraan: "Motor",
      merkKendaraan: "YAMAHA",
      platNomor: "B 1234 ABC",
    },
    perjalanan: {
      tanggal: "Rabu, 18.10.2023",
      jarak: "10 km",
      durasi: "20 menit",
      titikJemput: { lokasi: "Jakarta Selatan", waktu: "10.00 WIB", alamat: "Blok M Plaza" },
      tujuan: { lokasi: "Jakarta Pusat", waktu: "10.20 WIB", alamat: "Monas" },
    },
    pembayaran: {
      type: "Transfer Bank",
      tanggal: "18/10/2023",
      idPesanan: "NEBENG-98300B",
      noTransaksi: "INV/20231018/234567890",
      biayaPenebeng: 40000,
      biayaAdmin: 15000,
      total: 55000,
    },
  },
  "P003": {
    id: "P003",
    idPesanan: "NEBENG-C8345678912345",
    status: "SELESAI",
    customer: {
      nama: "Dewi Kartika",
      namaLengkap: "Dewi Kartika Sari",
      noTlp: "083456789012",
      catatan: "Mohon datang tepat waktu.",
    },
    mitra: {
      nama: "Eko Prasetyo",
      kode: "001237",
      namaLengkap: "Eko Prasetyo Utomo",
      noTlp: "084567890123",
      kendaraan: "Mobil",
      merkKendaraan: "TOYOTA",
      platNomor: "B 5678 DEF",
    },
    perjalanan: {
      tanggal: "Kamis, 19.10.2023",
      jarak: "25 km",
      durasi: "45 menit",
      titikJemput: { lokasi: "Bandung", waktu: "08.00 WIB", alamat: "Dago" },
      tujuan: { lokasi: "Cimahi", waktu: "08.45 WIB", alamat: "Cimahi Mall" },
    },
    pembayaran: {
      type: "QRIS",
      tanggal: "19/10/2023",
      idPesanan: "NEBENG-98301C",
      noTransaksi: "INV/20231019/345678901",
      biayaPenebeng: 100000,
      biayaAdmin: 20000,
      total: 120000,
    },
  },
  "P004": {
    id: "P004",
    idPesanan: "NEBENG-D9456789123456",
    status: "SELESAI",
    customer: {
      nama: "Rina Wati",
      namaLengkap: "Rina Wati Susanti",
      noTlp: "085678901234",
      catatan: "Barang mudah pecah, tolong hati-hati.",
    },
    mitra: {
      nama: "Gilang Ramadhan",
      kode: "001238",
      namaLengkap: "Gilang Ramadhan Putra",
      noTlp: "086789012345",
      kendaraan: "Motor",
      merkKendaraan: "HONDA",
      platNomor: "B 9012 GHI",
    },
    perjalanan: {
      tanggal: "Jumat, 20.10.2023",
      jarak: "8 km",
      durasi: "15 menit",
      titikJemput: { lokasi: "Surabaya", waktu: "14.00 WIB", alamat: "Tunjungan Plaza" },
      tujuan: { lokasi: "Surabaya", waktu: "14.15 WIB", alamat: "Galaxy Mall" },
    },
    pembayaran: {
      type: "Cash",
      tanggal: "20/10/2023",
      idPesanan: "NEBENG-98302D",
      noTransaksi: "INV/20231020/456789012",
      biayaPenebeng: 35000,
      biayaAdmin: 10000,
      total: 45000,
    },
  },
  "P005": {
    id: "P005",
    idPesanan: "NEBENG-E0567890234567",
    status: "PROSES",
    customer: {
      nama: "Agus Setiawan",
      namaLengkap: "Agus Setiawan Hidayat",
      noTlp: "087890123456",
      catatan: "Titip makanan, jangan sampai tumpah.",
    },
    mitra: {
      nama: "Hendra Wijaya",
      kode: "001239",
      namaLengkap: "Hendra Wijaya Kusuma",
      noTlp: "088901234567",
      kendaraan: "Motor",
      merkKendaraan: "SUZUKI",
      platNomor: "B 3456 JKL",
    },
    perjalanan: {
      tanggal: "Sabtu, 21.10.2023",
      jarak: "5 km",
      durasi: "10 menit",
      titikJemput: { lokasi: "Semarang", waktu: "12.00 WIB", alamat: "Simpang Lima" },
      tujuan: { lokasi: "Semarang", waktu: "12.10 WIB", alamat: "Paragon Mall" },
    },
    pembayaran: {
      type: "QRIS",
      tanggal: "21/10/2023",
      idPesanan: "NEBENG-98303E",
      noTransaksi: "INV/20231021/567890123",
      biayaPenebeng: 25000,
      biayaAdmin: 10000,
      total: 35000,
    },
  },
  "P006": {
    id: "P006",
    idPesanan: "NEBENG-F1678901345678",
    status: "BATAL",
    customer: {
      nama: "Siti Nurhaliza",
      namaLengkap: "Siti Nurhaliza Putri",
      noTlp: "089012345678",
      catatan: "Dibatalkan karena perubahan jadwal.",
    },
    mitra: {
      nama: "Joko Susilo",
      kode: "001240",
      namaLengkap: "Joko Susilo Prabowo",
      noTlp: "080123456789",
      kendaraan: "Motor",
      merkKendaraan: "HONDA",
      platNomor: "B 7890 MNO",
    },
    perjalanan: {
      tanggal: "Minggu, 22.10.2023",
      jarak: "12 km",
      durasi: "22 menit",
      titikJemput: { lokasi: "Malang", waktu: "09.00 WIB", alamat: "Alun-alun Malang" },
      tujuan: { lokasi: "Batu", waktu: "09.22 WIB", alamat: "Jatim Park" },
    },
    pembayaran: {
      type: "Transfer Bank",
      tanggal: "22/10/2023",
      idPesanan: "NEBENG-98304F",
      noTransaksi: "INV/20231022/678901234",
      biayaPenebeng: 40000,
      biayaAdmin: 10000,
      total: 50000,
    },
  },
  "P007": {
    id: "P007",
    idPesanan: "NEBENG-G2789012456789",
    status: "BATAL",
    customer: {
      nama: "Rudi Hermawan",
      namaLengkap: "Rudi Hermawan Saputra",
      noTlp: "081234567891",
      catatan: "Driver tidak ditemukan.",
    },
    mitra: {
      nama: "Indra Permana",
      kode: "001241",
      namaLengkap: "Indra Permana Putra",
      noTlp: "082345678902",
      kendaraan: "Motor",
      merkKendaraan: "YAMAHA",
      platNomor: "B 1234 PQR",
    },
    perjalanan: {
      tanggal: "Senin, 23.10.2023",
      jarak: "15 km",
      durasi: "28 menit",
      titikJemput: { lokasi: "Solo", waktu: "07.30 WIB", alamat: "Stasiun Solo Balapan" },
      tujuan: { lokasi: "Sukoharjo", waktu: "07.58 WIB", alamat: "The Park Mall" },
    },
    pembayaran: {
      type: "QRIS",
      tanggal: "23/10/2023",
      idPesanan: "NEBENG-98305G",
      noTransaksi: "INV/20231023/789012345",
      biayaPenebeng: 50000,
      biayaAdmin: 15000,
      total: 65000,
    },
  },
  "P008": {
    id: "P008",
    idPesanan: "NEBENG-H3890123567890",
    status: "BATAL",
    customer: {
      nama: "Linda Kusuma",
      namaLengkap: "Linda Kusuma Dewi",
      noTlp: "083456789013",
      catatan: "Customer membatalkan pesanan.",
    },
    mitra: {
      nama: "Wahyu Saputra",
      kode: "001242",
      namaLengkap: "Wahyu Saputra Hadi",
      noTlp: "084567890124",
      kendaraan: "Mobil",
      merkKendaraan: "DAIHATSU",
      platNomor: "B 5678 STU",
    },
    perjalanan: {
      tanggal: "Selasa, 24.10.2023",
      jarak: "30 km",
      durasi: "50 menit",
      titikJemput: { lokasi: "Bekasi", waktu: "06.00 WIB", alamat: "Summarecon Mall Bekasi" },
      tujuan: { lokasi: "Jakarta", waktu: "06.50 WIB", alamat: "Sudirman" },
    },
    pembayaran: {
      type: "Transfer Bank",
      tanggal: "24/10/2023",
      idPesanan: "NEBENG-98306H",
      noTransaksi: "INV/20231024/890123456",
      biayaPenebeng: 130000,
      biayaAdmin: 20000,
      total: 150000,
    },
  },
  "P009": {
    id: "P009",
    idPesanan: "NEBENG-I4901234678901",
    status: "PROSES",
    customer: {
      nama: "Andi Pratama",
      namaLengkap: "Andi Pratama Wijaya",
      noTlp: "085678901235",
      catatan: "Barang elektronik, handle with care.",
    },
    mitra: {
      nama: "Dedi Kurniawan",
      kode: "001243",
      namaLengkap: "Dedi Kurniawan Putra",
      noTlp: "086789012346",
      kendaraan: "Motor",
      merkKendaraan: "HONDA",
      platNomor: "B 9012 VWX",
    },
    perjalanan: {
      tanggal: "Rabu, 25.10.2023",
      jarak: "7 km",
      durasi: "12 menit",
      titikJemput: { lokasi: "Depok", waktu: "11.00 WIB", alamat: "Margonda" },
      tujuan: { lokasi: "Depok", waktu: "11.12 WIB", alamat: "UI" },
    },
    pembayaran: {
      type: "Cash",
      tanggal: "25/10/2023",
      idPesanan: "NEBENG-98307I",
      noTransaksi: "INV/20231025/901234567",
      biayaPenebeng: 30000,
      biayaAdmin: 10000,
      total: 40000,
    },
  },
  "P010": {
    id: "P010",
    idPesanan: "NEBENG-J5012345789012",
    status: "SELESAI",
    customer: {
      nama: "Maya Sari",
      namaLengkap: "Maya Sari Indah",
      noTlp: "087890123457",
      catatan: "Terima kasih, pelayanan sangat baik!",
    },
    mitra: {
      nama: "Firman Hidayat",
      kode: "001244",
      namaLengkap: "Firman Hidayat Putra",
      noTlp: "088901234568",
      kendaraan: "Motor",
      merkKendaraan: "SUZUKI",
      platNomor: "B 3456 YZA",
    },
    perjalanan: {
      tanggal: "Kamis, 26.10.2023",
      jarak: "18 km",
      durasi: "32 menit",
      titikJemput: { lokasi: "Tangerang", waktu: "15.00 WIB", alamat: "Alam Sutera" },
      tujuan: { lokasi: "Jakarta Barat", waktu: "15.32 WIB", alamat: "Central Park" },
    },
    pembayaran: {
      type: "QRIS",
      tanggal: "26/10/2023",
      idPesanan: "NEBENG-98308J",
      noTransaksi: "INV/20231026/012345678",
      biayaPenebeng: 55000,
      biayaAdmin: 15000,
      total: 70000,
    },
  },
};

interface PesananContextType {
  pesananList: PesananData[];
  pesananDetail: Record<string, Omit<PesananDetailData, 'status'>>;
  getPesananDetail: (id: string) => (PesananDetailData & { status: "PROSES" | "SELESAI" | "BATAL" }) | undefined;
  loading: boolean;
  error: string | null;
}

const PesananContext = createContext<PesananContextType | undefined>(undefined);

export const PesananProvider = ({ children }: { children: ReactNode }) => {
  const [pesananList, setPesananList] = useState<PesananData[]>(initialPesananList);
  const [pesananDetail, setPesananDetail] = useState<Record<string, PesananDetailData>>(initialPesananDetail);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Fetch pesanan on mount
  useEffect(() => {
    const fetchPesanan = async () => {
      try {
        setLoading(true);
        setError(null);
        const response = await pesananApi.getAll();
        const pesanan = Array.isArray(response.data) ? response.data : [];
        
        // Transform API response
        const transformedPesanan = pesanan.map((p: any) => ({
          id: String(p.id),
          noOrder: p.no_order,
          namaCustomer: p.namaCustomer || p.customerName,
          namaDriver: p.namaDriver || p.driverName,
          tanggal: new Date(p.tanggal_pesanan || new Date()),
          layanan: p.layanan,
          harga: p.harga,
          status: p.status,
        }));
        
        setPesananList(transformedPesanan);
      } catch (err) {
        console.error("Failed to fetch pesanan:", err);
        setError(err instanceof Error ? err.message : "Failed to fetch pesanan");
      } finally {
        setLoading(false);
      }
    };

    fetchPesanan();
  }, []);

  // Get detail with status from list (single source of truth)
  const getPesananDetail = (id: string) => {
    const detail = pesananDetail[id];
    const listItem = pesananList.find(p => p.id === id);
    
    if (!detail || !listItem) return undefined;
    
    // Return detail with status from the list (single source of truth)
    return {
      ...detail,
      status: listItem.status,
      customer: {
        ...detail.customer,
        nama: listItem.namaCustomer,
      },
      mitra: {
        ...detail.mitra,
        nama: listItem.namaDriver,
      },
    };
  };

  return (
    <PesananContext.Provider value={{ pesananList, pesananDetail, getPesananDetail, loading, error }}>
      {children}
    </PesananContext.Provider>
  );
};

export const usePesanan = () => {
  const context = useContext(PesananContext);
  if (!context) {
    throw new Error("usePesanan must be used within a PesananProvider");
  }
  return context;
};
