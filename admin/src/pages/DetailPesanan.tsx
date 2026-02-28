import { useParams, useNavigate } from "react-router-dom";
import { ChevronLeft, Copy } from "lucide-react";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import { useToast } from "@/hooks/use-toast";
import { usePesanan } from "@/contexts/PesananContext";
import { useState, useEffect } from "react";
import { pesananApi, customerApi, mitraApi } from "@/services/api";
import axios from "axios";

const api = axios.create({
  baseURL: import.meta.env.VITE_API_URL || 'http://localhost:8000/api',
  headers: {
    'Content-Type': 'application/json',
  },
});

const getStatusBadge = (status: string) => {
  switch (status) {
    case "SELESAI":
      return <Badge className="bg-green-500 hover:bg-green-600 text-white text-xs px-3">Selesai</Badge>;
    case "BATAL":
      return <Badge className="bg-red-500 hover:bg-red-600 text-white text-xs px-3">Batal</Badge>;
    case "PROSES":
      return <Badge className="bg-orange-500 hover:bg-orange-600 text-white text-xs px-3">Proses</Badge>;
    default:
      return <Badge className="bg-gray-500 text-white text-xs px-3">{status}</Badge>;
  }
};

const formatCurrency = (amount: number) => {
  return new Intl.NumberFormat('id-ID', {
    style: 'currency',
    currency: 'IDR',
    minimumFractionDigits: 0,
  }).format(amount).replace('IDR', 'Rp');
};

const DetailPesanan = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  const { toast } = useToast();
  const { getPesananDetail } = usePesanan();
  const [apiData, setApiData] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  // Get data based on id
  const data = id ? getPesananDetail(id) : undefined;

  // Fetch detailed data from API
  useEffect(() => {
    const fetchDetail = async () => {
      if (!id) return;

      try {
        setLoading(true);
        const response = await pesananApi.getById(id);
        const pesananData = response.data;

        console.log("✅ Pesanan Data from API:", pesananData);

        // Fetch customer data if user_id exists
        let customerData = null;
        if (pesananData.user_id) {
          try {
            const customerResponse = await customerApi.getById(pesananData.user_id);
            customerData = customerResponse.data;
          } catch (customerError) {
            console.warn("Failed to fetch customer data:", customerError);
          }
        }

        // Mitra data sudah ada di pesananData (driverId, driverName, driverEmail, etc)
        // Tidak perlu fetch tebengan lagi
        const mitraData = {
          name: pesananData.driverName,
          email: pesananData.driverEmail,
          phone: pesananData.driverPhone,
          address: pesananData.driverAddress,
          vehicleName: pesananData.vehicleName,
          platNomor: pesananData.platNomor,
          merek: pesananData.merek,
          model: pesananData.model,
          vehicleType: pesananData.vehicleType,
        };

        // Combine data
        const combinedData = {
          ...pesananData,
          customer: customerData,
          mitra: mitraData,
        };

        console.log("Combined Data:", combinedData);
        console.log("Price dari tebengan:", combinedData.tebenganPrice);

        setApiData(combinedData);
      } catch (error) {
        console.error("Failed to fetch pesanan detail:", error);
        toast({
          title: "Error",
          description: "Gagal memuat detail pesanan",
          variant: "destructive",
        });
      } finally {
        setLoading(false);
      }
    };

    fetchDetail();
  }, [id, toast]);

  // Use API data
  const displayData = apiData;

  if (!displayData) {
    return (
      <div className="flex items-center justify-center h-64">
        <p className="text-muted-foreground">
          {loading ? "Memuat data pesanan..." : "Data pesanan tidak ditemukan"}
        </p>
      </div>
    );
  }

  const handleCopyId = () => {
    navigator.clipboard.writeText(displayData.booking_number || displayData.idPesanan);
    toast({
      title: "Berhasil",
      description: "ID Pesanan berhasil disalin",
    });
  };

  // Fungsi untuk menghitung persentase biaya admin
  const calculateAdminFeePercentage = (price: number, fee: number): number => {
    if (price === 0) return 0;
    return Math.round((fee / price) * 100 * 100) / 100; // 2 desimal
  };

  // Hitung biaya admin (misalnya 10% dari harga tebengan)
  const basePrice = parseFloat(displayData?.tebenganPrice || '0'); // Konversi string ke number
  const adminFee = basePrice ? Math.round(basePrice * 0.1) : 0;
  const adminFeePercentage = calculateAdminFeePercentage(basePrice, adminFee);
  const totalAmount = basePrice + adminFee; // Sekarang penjumlahan numerik

  console.log("🧮 Kalkulasi Harga:", { basePrice, adminFee, adminFeePercentage, totalAmount });

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center gap-3">
        <Button
          variant="ghost"
          size="icon"
          className="h-8 w-8"
          onClick={() => navigate("/dashboard/pesanan")}
        >
          <ChevronLeft size={20} />
        </Button>
        <h1 className="text-xl font-semibold">Detail Pesanan</h1>
      </div>

      {/* ID Pesanan */}
      <div className="flex items-center gap-2">
        <span className="text-sm font-medium">ID Pesanan :</span>
        <span className="text-sm text-muted-foreground">{displayData.booking_number || displayData.idPesanan}</span>
        <Button variant="ghost" size="icon" className="h-6 w-6" onClick={handleCopyId}>
          <Copy size={14} />
        </Button>
      </div>

      {/* Customer and Mitra Cards */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Customer Card */}
        <Card className="shadow-sm">
          <CardContent className="p-6">
            <div className="flex items-center gap-4 mb-6">
              <Avatar className="h-14 w-14">
                <AvatarImage src={displayData.customer?.foto || "/placeholder.svg"} />
                <AvatarFallback className="bg-gray-200 text-gray-600">
                  {(displayData.customer?.nama || displayData.customerName || "").charAt(0)}
                </AvatarFallback>
              </Avatar>
              <div className="flex-1">
                <h3 className="font-semibold">{displayData.customer?.nama || displayData.customerName}</h3>
                <p className="text-sm text-muted-foreground">Customer</p>
                <div className="mt-1">
                  {getStatusBadge(displayData.status)}
                </div>
              </div>
            </div>

            <h4 className="font-semibold mb-4">Informasi Customer</h4>
            <div className="grid grid-cols-2 gap-4 mb-4">
              <div className="space-y-2">
                <label className="text-sm text-muted-foreground">Nama Lengkap</label>
                <Input value={displayData.customer?.namaLengkap || displayData.customer?.nama || displayData.customerName} readOnly className="bg-muted/50" />
              </div>
              <div className="space-y-2">
                <label className="text-sm text-muted-foreground">No. Tlp</label>
                <Input value={displayData.customer?.noTlp || displayData.customerPhone} readOnly className="bg-muted/50" />
              </div>
            </div>
            <div className="grid grid-cols-2 gap-4 mb-4">
              <div className="space-y-2">
                <label className="text-sm text-muted-foreground">Email</label>
                <Input value={displayData.customer?.email || displayData.customerEmail} readOnly className="bg-muted/50" />
              </div>
              <div className="space-y-2">
                <label className="text-sm text-muted-foreground">Alamat</label>
                <Input value={displayData.customer?.alamat || displayData.customer?.address} readOnly className="bg-muted/50" />
              </div>
            </div>
            <div className="space-y-2">
              <label className="text-sm text-muted-foreground">Catatan Untuk Driver</label>
              <Input value={displayData.notes || displayData.customer?.catatan || ""} readOnly className="bg-muted/50" />
            </div>
          </CardContent>
        </Card>

        {/* Mitra Card */}
        <Card className="shadow-sm">
          <CardContent className="p-6">
            <div className="flex items-center gap-4 mb-6">
              <Avatar className="h-14 w-14">
                <AvatarImage src="/placeholder.svg" />
                <AvatarFallback className="bg-orange-100 text-orange-600">
                  {(displayData.driverName || displayData.mitra?.nama || "").charAt(0)}
                </AvatarFallback>
              </Avatar>
              <div className="flex-1">
                <h3 className="font-semibold">{displayData.driverName || displayData.mitra?.nama}</h3>
                <p className="text-sm text-muted-foreground">Mitra</p>
                <div className="mt-1">
                  {getStatusBadge(displayData.status)}
                </div>
              </div>
              <div className="text-right">
                <p className="text-xs text-muted-foreground">ID MITRA</p>
                <p className="text-sm font-medium">{displayData.mitra?.kode || ""}</p>
              </div>
            </div>

            <h4 className="font-semibold mb-4">Informasi Mitra</h4>
            <div className="grid grid-cols-2 gap-4 mb-4">
              <div className="space-y-2">
                <label className="text-sm text-muted-foreground">Nama Lengkap</label>
                <Input value={displayData.driverName || displayData.mitra?.name || displayData.mitra?.namaLengkap || ""} readOnly className="bg-muted/50" />
              </div>
              <div className="space-y-2">
                <label className="text-sm text-muted-foreground">No. Tlp</label>
                <Input value={displayData.driverPhone || displayData.mitra?.phone || displayData.mitra?.noTlp || ""} readOnly className="bg-muted/50" />
              </div>
            </div>
            <div className="grid grid-cols-2 gap-4 mb-4">
              <div className="space-y-2">
                <label className="text-sm text-muted-foreground">Email</label>
                <Input value={displayData.driverEmail || displayData.mitra?.email || ""} readOnly className="bg-muted/50" />
              </div>
            </div>
            <div className="space-y-2 mb-4">
              <label className="text-sm text-muted-foreground">Alamat</label>
              <Input value={displayData.driverAddress || displayData.mitra?.alamat || ""} readOnly className="bg-muted/50" />
            </div>
            <div className="grid grid-cols-2 gap-4 mb-4">
              <div className="space-y-2">
                <label className="text-sm text-muted-foreground">Nama Kendaraan</label>
                <Input value={displayData.vehicleName || ""} readOnly className="bg-muted/50" />
              </div>
              <div className="space-y-2">
                <label className="text-sm text-muted-foreground">Merek Kendaraan</label>
                <Input value={displayData.merek || ""} readOnly className="bg-muted/50" />
              </div>
            </div>
            <div className="grid grid-cols-2 gap-4 mb-4">
              <div className="space-y-2">
                <label className="text-sm text-muted-foreground">Model Kendaraan</label>
                <Input value={displayData.model || ""} readOnly className="bg-muted/50" />
              </div>
              <div className="space-y-2">
                <label className="text-sm text-muted-foreground">Plat Nomor Kendaraan</label>
                <Input value={displayData.platNomor || ""} readOnly className="bg-muted/50" />
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Rincian Perjalanan and Pembayaran */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Rincian Perjalanan */}
        <Card className="shadow-sm">
          <CardContent className="p-6">
            <h4 className="font-semibold mb-4">Rincian Perjalanan</h4>
            <div className="flex items-center justify-between mb-4 text-sm">
              <span className="text-muted-foreground">{displayData.created_at ? new Date(displayData.created_at).toLocaleDateString('id-ID') : "N/A"}</span>
              <span className="text-muted-foreground">{displayData.distance || "N/A"} - {displayData.duration || "N/A"}</span>
            </div>

            <div className="grid grid-cols-2 gap-4">
              {/* Titik Jemput */}
              <div>
                <p className="text-xs text-primary font-medium mb-2">Titik Jemput</p>
                <h5 className="font-semibold text-primary text-lg">{displayData.originCity || displayData.origin_location || "N/A"}</h5>
                <p className="text-sm text-muted-foreground">{displayData.departure_time || "N/A"}</p>
                <p className="text-xs text-muted-foreground mt-1">{displayData.originAddress || displayData.origin_address || "N/A"}</p>
              </div>

              {/* Timeline dots */}
              <div className="relative">
                <div className="absolute left-0 top-1/2 -translate-y-1/2 flex items-center gap-1">
                  <div className="w-2 h-2 rounded-full bg-primary"></div>
                  <div className="w-1 h-1 rounded-full bg-red-500"></div>
                  <div className="w-1 h-1 rounded-full bg-red-500"></div>
                  <div className="w-1 h-1 rounded-full bg-red-500"></div>
                  <div className="w-2 h-2 rounded-full bg-primary"></div>
                </div>
              </div>
            </div>

            <div className="mt-4">
              <p className="text-xs text-primary font-medium mb-2">Tujuan</p>
              <h5 className="font-semibold text-primary text-lg">{displayData.destinationCity || displayData.destination_location || "N/A"}</h5>
              <p className="text-sm text-muted-foreground">{displayData.arrival_time || "N/A"}</p>
              <p className="text-xs text-muted-foreground mt-1">{displayData.destinationAddress || displayData.destination_address || "N/A"}</p>
            </div>
          </CardContent>
        </Card>

        {/* Rincian Pembayaran - UPDATED dengan harga dari tebengan */}
        <Card className="shadow-sm">
          <CardContent className="p-6">
            <h4 className="font-semibold mb-4">Rincian Pembayaran</h4>

            <div className="space-y-3">
              <div className="flex justify-between">
                <span className="text-sm text-muted-foreground">Type Pembayaran</span>
                <span className="text-sm font-medium">{displayData.payment_method || "Transfer Bank"}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-sm text-muted-foreground">Tanggal</span>
                <span className="text-sm font-medium">{displayData.created_at ? new Date(displayData.created_at).toLocaleDateString('id-ID') : "N/A"}</span>
              </div>

              <div className="border-t pt-3 mt-3">
                <div className="flex justify-between mb-2">
                  <span className="text-sm text-muted-foreground">ID Pesanan</span>
                  <span className="text-sm font-medium">{displayData.booking_number || "N/A"}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-sm text-muted-foreground">No Transaksi</span>
                  <span className="text-sm font-medium">{displayData.booking_number || "N/A"}</span>
                </div>
              </div>

              <div className="border-t pt-3 mt-3">
                <div className="flex justify-between mb-2">
                  <span className="text-sm text-muted-foreground">
                    {displayData.layanan === 'Titip Barang' || displayData.layanan === 'Barang' 
                      ? 'Biaya Kirim Barang' 
                      : displayData.layanan === 'Motor' || displayData.layanan === 'Mobil'
                      ? 'Biaya Per Penumpang (2 Org)'
                      : 'Biaya Layanan'}
                  </span>
                  <span className="text-sm font-medium">{formatCurrency(displayData.tebenganPrice || 0)}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-sm text-muted-foreground">
                    Biaya Admin ({adminFeePercentage}%)
                  </span>
                  <span className="text-sm font-medium">{formatCurrency(adminFee)}</span>
                </div>
              </div>

              <div className="border-t pt-3 mt-3">
                <div className="flex justify-between">
                  <span className="text-sm font-semibold">Total Pembayaran</span>
                  <span className={`text-lg font-bold ${displayData.status === "BATAL" ? "text-red-500 line-through" : "text-primary"}`}>
                    {formatCurrency(totalAmount)}
                  </span>
                </div>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
};

export default DetailPesanan;