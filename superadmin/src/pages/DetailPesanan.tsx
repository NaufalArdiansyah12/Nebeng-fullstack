import { useParams, useNavigate } from "react-router-dom";
import { ChevronLeft, Copy } from "lucide-react";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import { useToast } from "@/hooks/use-toast";
import { usePesanan } from "@/contexts/PesananContext";

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

  // Get data based on id
  const data = id ? getPesananDetail(id) : undefined;

  if (!data) {
    return (
      <div className="flex items-center justify-center h-64">
        <p className="text-muted-foreground">Data pesanan tidak ditemukan</p>
      </div>
    );
  }

  const handleCopyId = () => {
    navigator.clipboard.writeText(data.idPesanan);
    toast({
      title: "Berhasil",
      description: "ID Pesanan berhasil disalin",
    });
  };

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
        <span className="text-sm text-muted-foreground">{data.idPesanan}</span>
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
                <AvatarImage src="/placeholder.svg" />
                <AvatarFallback className="bg-gray-200 text-gray-600">
                  {data.customer.nama.charAt(0)}
                </AvatarFallback>
              </Avatar>
              <div className="flex-1">
                <h3 className="font-semibold">{data.customer.nama}</h3>
                <p className="text-sm text-muted-foreground">Costumer</p>
                <div className="mt-1">
                  {getStatusBadge(data.status)}
                </div>
              </div>
            </div>

            <h4 className="font-semibold mb-4">Informasi Costumer</h4>
            <div className="grid grid-cols-2 gap-4 mb-4">
              <div className="space-y-2">
                <label className="text-sm text-muted-foreground">Nama Lengkap</label>
                <Input value={data.customer.namaLengkap} readOnly className="bg-muted/50" />
              </div>
              <div className="space-y-2">
                <label className="text-sm text-muted-foreground">No. Tlp</label>
                <Input value={data.customer.noTlp} readOnly className="bg-muted/50" />
              </div>
            </div>
            <div className="space-y-2">
              <label className="text-sm text-muted-foreground">Catatan Untuk Driver</label>
              <Input value={data.customer.catatan} readOnly className="bg-muted/50" />
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
                  {data.mitra.nama.charAt(0)}
                </AvatarFallback>
              </Avatar>
              <div className="flex-1">
                <h3 className="font-semibold">{data.mitra.nama}</h3>
                <p className="text-sm text-muted-foreground">Mitra</p>
                <div className="mt-1">
                  {getStatusBadge(data.status)}
                </div>
              </div>
              <div className="text-right">
                <p className="text-xs text-muted-foreground">ID MITRA</p>
                <p className="text-sm font-medium">{data.mitra.kode}</p>
              </div>
            </div>

            <h4 className="font-semibold mb-4">Informasi Mitra</h4>
            <div className="grid grid-cols-2 gap-4 mb-4">
              <div className="space-y-2">
                <label className="text-sm text-muted-foreground">Nama Lengkap</label>
                <Input value={data.mitra.namaLengkap} readOnly className="bg-muted/50" />
              </div>
              <div className="space-y-2">
                <label className="text-sm text-muted-foreground">No. Tlp</label>
                <Input value={data.mitra.noTlp} readOnly className="bg-muted/50" />
              </div>
            </div>
            <div className="grid grid-cols-2 gap-4 mb-4">
              <div className="space-y-2">
                <label className="text-sm text-muted-foreground">Kendaraan</label>
                <Input value={data.mitra.kendaraan} readOnly className="bg-muted/50" />
              </div>
              <div className="space-y-2">
                <label className="text-sm text-muted-foreground">Merk Kendaraan</label>
                <Input value={data.mitra.merkKendaraan} readOnly className="bg-muted/50" />
              </div>
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <label className="text-sm text-muted-foreground">Plat Nomor Kendaraan</label>
                <Input value={data.mitra.platNomor} readOnly className="bg-muted/50" />
              </div>
              <div className="space-y-2">
                <label className="text-sm text-muted-foreground">Merk Kendaraan</label>
                <Input value={data.mitra.merkKendaraan} readOnly className="bg-muted/50" />
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
              <span className="text-muted-foreground">{data.perjalanan.tanggal}</span>
              <span className="text-muted-foreground">{data.perjalanan.jarak} - {data.perjalanan.durasi}</span>
            </div>

            <div className="grid grid-cols-2 gap-4">
              {/* Titik Jemput */}
              <div>
                <p className="text-xs text-primary font-medium mb-2">Titik Jemput</p>
                <h5 className="font-semibold text-primary text-lg">{data.perjalanan.titikJemput.lokasi}</h5>
                <p className="text-sm text-muted-foreground">{data.perjalanan.titikJemput.waktu}</p>
                <p className="text-xs text-muted-foreground mt-1">{data.perjalanan.titikJemput.alamat}</p>
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
              <h5 className="font-semibold text-primary text-lg">{data.perjalanan.tujuan.lokasi}</h5>
              <p className="text-sm text-muted-foreground">{data.perjalanan.tujuan.waktu}</p>
              <p className="text-xs text-muted-foreground mt-1">{data.perjalanan.tujuan.alamat}</p>
            </div>
          </CardContent>
        </Card>

        {/* Rincian Pembayaran */}
        <Card className="shadow-sm">
          <CardContent className="p-6">
            <h4 className="font-semibold mb-4">Rincian Pembayaran</h4>
            
            <div className="space-y-3">
              <div className="flex justify-between">
                <span className="text-sm text-muted-foreground">Type Pembayaran</span>
                <span className="text-sm font-medium">{data.pembayaran.type}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-sm text-muted-foreground">Tanggal</span>
                <span className="text-sm font-medium">{data.pembayaran.tanggal}</span>
              </div>
              
              <div className="border-t pt-3 mt-3">
                <div className="flex justify-between mb-2">
                  <span className="text-sm text-muted-foreground">ID Pesanan</span>
                  <span className="text-sm font-medium">{data.pembayaran.idPesanan}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-sm text-muted-foreground">No Transaksi</span>
                  <span className="text-sm font-medium">{data.pembayaran.noTransaksi}</span>
                </div>
              </div>

              <div className="border-t pt-3 mt-3">
                <div className="flex justify-between mb-2">
                  <span className="text-sm text-muted-foreground">Biaya Per penebeng (2 Org)</span>
                  <span className="text-sm font-medium">{formatCurrency(data.pembayaran.biayaPenebeng)}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-sm text-muted-foreground">Biaya Admin</span>
                  <span className="text-sm font-medium">{formatCurrency(data.pembayaran.biayaAdmin)}</span>
                </div>
              </div>

              <div className="border-t pt-3 mt-3">
                <div className="flex justify-between">
                  <span className="text-sm font-semibold">Total</span>
                  <span className={`text-lg font-bold ${data.status === "BATAL" ? "text-red-500 line-through" : "text-primary"}`}>
                    {formatCurrency(data.pembayaran.total)}
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
