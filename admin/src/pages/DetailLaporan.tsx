import { useState } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { ChevronLeft, Copy, ExternalLink, CheckCircle, Send } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { useLaporan } from "@/contexts/LaporanContext";
import { useMitra } from "@/contexts/MitraContext";
import { useCustomer } from "@/contexts/CustomerContext";
import BlockLaporanPopup from "@/components/BlockLaporanPopup";
import SaveLaporanPopup from "@/components/SaveLaporanPopup";
import { toast } from "sonner";

const DetailLaporan = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  const { getLaporanDetail, updateLaporan, respondLaporan } = useLaporan();
  const { blockMitra } = useMitra();
  const { blockCustomer } = useCustomer();
  const laporan = getLaporanDetail(id || "");

  const [showBlockConfirm, setShowBlockConfirm] = useState(false);
  const [showBlockSuccess, setShowBlockSuccess] = useState(false);
  const [showSaveSuccess, setShowSaveSuccess] = useState(false);
  const [editedLaporan, setEditedLaporan] = useState(laporan?.laporan || "");
  const [editedTanggapan, setEditedTanggapan] = useState(laporan?.tanggapan || "");
  const [isEditing, setIsEditing] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);

  if (!laporan) {
    return (
      <div className="flex items-center justify-center min-h-[400px]">
        <p className="text-muted-foreground">Laporan tidak ditemukan</p>
      </div>
    );
  }

  const handleCopyId = (text: string) => {
    navigator.clipboard.writeText(text);
    toast.success("ID berhasil disalin");
  };

  const handleBlockConfirm = (blockType: "mitra" | "customer") => {
    if (blockType === "mitra") {
      blockMitra(laporan.mitraId);
      toast.success(`Mitra ${laporan.namaMitra} berhasil diblokir`);
    } else {
      blockCustomer(laporan.customerId);
      toast.success(`Customer ${laporan.namaCustomer} berhasil diblokir`);
    }
    setShowBlockConfirm(false);
    setShowBlockSuccess(true);
  };

  const handleSaveLaporan = () => {
    updateLaporan(laporan.id, editedLaporan);
    setIsEditing(false);
    setShowSaveSuccess(true);
  };

  const handleSaveTanggapan = async () => {
    if (!editedTanggapan.trim()) {
      toast.error("Tanggapan tidak boleh kosong");
      return;
    }
    
    setIsSubmitting(true);
    try {
      await respondLaporan(laporan.id, editedTanggapan, "SELESAI");
      toast.success("Tanggapan berhasil disimpan dan laporan diselesaikan");
    } catch (error) {
      toast.error("Gagal menyimpan tanggapan");
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center gap-4">
        <Button
          variant="ghost"
          size="icon"
          onClick={() => navigate("/dashboard/laporan")}
          className="h-8 w-8"
        >
          <ChevronLeft size={24} />
        </Button>
        <h1 className="text-2xl font-semibold">Detail Laporan</h1>
        {laporan.status === "SELESAI" && (
          <span className="bg-green-100 text-green-700 px-3 py-1 rounded-full text-sm font-medium flex items-center gap-1">
            <CheckCircle size={14} />
            Selesai
          </span>
        )}
      </div>

      {/* ID Pesanan */}
      <Card>
        <CardContent className="p-6">
          <div className="flex items-center justify-between">
            <span className="text-lg font-medium">ID Pesanan :</span>
            <div className="flex items-center gap-2">
              <span className="font-semibold">NEBENG-A9823018734710</span>
              <Button
                variant="ghost"
                size="icon"
                className="h-6 w-6"
                onClick={() => handleCopyId("NEBENG-A9823018734710")}
              >
                <Copy size={16} />
              </Button>
            </div>
          </div>

          {/* Customer and Mitra Info */}
          <div className="grid grid-cols-2 gap-8 mt-8">
            {/* Customer */}
            <div className="flex items-center gap-4">
              <div className="w-16 h-16 bg-gray-200 rounded-full flex items-center justify-center overflow-hidden">
                <img
                  src="/placeholder.svg"
                  alt={laporan.namaCustomer}
                  className="w-full h-full object-cover"
                />
              </div>
              <div>
                <h3 className="font-semibold text-lg">{laporan.namaCustomer}</h3>
                <p className="text-muted-foreground text-sm">Costumer</p>
                <p className="text-xs text-primary">ID: {laporan.customerId}</p>
              </div>
            </div>

            {/* Mitra */}
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-4">
                <div className="w-16 h-16 bg-amber-100 rounded-full flex items-center justify-center overflow-hidden">
                  <img
                    src="/placeholder.svg"
                    alt={laporan.namaMitra}
                    className="w-full h-full object-cover"
                  />
                </div>
                <div>
                  <h3 className="font-semibold text-lg">{laporan.namaMitra}</h3>
                  <p className="text-muted-foreground text-sm">Mitra</p>
                </div>
              </div>
              <div className="text-right">
                <p className="text-xs text-muted-foreground">ID MITRA</p>
                <div className="flex items-center gap-1">
                  <span className="text-primary font-medium">{laporan.mitraId}</span>
                  <ExternalLink size={14} className="text-primary" />
                </div>
              </div>
            </div>
          </div>

          {/* Customer Info */}
          <div className="mt-8">
            <h4 className="font-semibold text-lg mb-4">Informasi Costumer</h4>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="text-sm text-muted-foreground">Nama Lengkap</label>
                <Input value={laporan.namaCustomer} disabled className="mt-1 bg-gray-50" />
              </div>
              <div>
                <label className="text-sm text-muted-foreground">No. Tlp</label>
                <Input value={laporan.customerPhone} disabled className="mt-1 bg-gray-50" />
              </div>
            </div>
            <div className="mt-4">
              <label className="text-sm text-muted-foreground">Catatan Untuk Driver</label>
              <Input value={laporan.customerNote} disabled className="mt-1 bg-gray-50" />
            </div>
          </div>

          {/* Mitra Info */}
          <div className="mt-8">
            <h4 className="font-semibold text-lg mb-4">Informasi Mitra</h4>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="text-sm text-muted-foreground">Nama Lengkap</label>
                <Input value={laporan.namaMitra} disabled className="mt-1 bg-gray-50" />
              </div>
              <div>
                <label className="text-sm text-muted-foreground">No. Tlp</label>
                <Input value={laporan.mitraPhone} disabled className="mt-1 bg-gray-50" />
              </div>
            </div>
            <div className="grid grid-cols-2 gap-4 mt-4">
              <div>
                <label className="text-sm text-muted-foreground">Kendaraan</label>
                <Input value={laporan.mitraKendaraan} disabled className="mt-1 bg-gray-50" />
              </div>
              <div>
                <label className="text-sm text-muted-foreground">Merk Kendaraan</label>
                <Input value={laporan.mitraMerkKendaraan} disabled className="mt-1 bg-gray-50" />
              </div>
            </div>
            <div className="grid grid-cols-2 gap-4 mt-4">
              <div>
                <label className="text-sm text-muted-foreground">Plat Nomor Kendaraan</label>
                <Input value={laporan.mitraPlatNomor} disabled className="mt-1 bg-gray-50" />
              </div>
              <div>
                <label className="text-sm text-muted-foreground">Merk Kendaraan</label>
                <Input value={laporan.mitraMerkKendaraan} disabled className="mt-1 bg-gray-50" />
              </div>
            </div>
          </div>

          {/* Laporan Section */}
          <div className="mt-8">
            <h4 className="font-semibold text-lg mb-4">Laporan</h4>
            <div className="bg-gray-100 rounded-lg p-4">
              <p className="text-foreground">{laporan.laporan}</p>
            </div>
          </div>

          {/* Tanggapan Section - For unresolved reports */}
          {laporan.status !== "SELESAI" && (
            <div className="mt-8">
              <h4 className="font-semibold text-lg mb-4">Tanggapan</h4>
              <Textarea
                value={editedTanggapan}
                onChange={(e) => setEditedTanggapan(e.target.value)}
                placeholder="Tulis tanggapan Anda di sini..."
                className="min-h-[150px] bg-white"
              />
              <div className="flex gap-2 mt-4">
                <Button 
                  className="bg-primary gap-2"
                  onClick={handleSaveTanggapan}
                  disabled={isSubmitting}
                >
                  <Send size={16} />
                  {isSubmitting ? "Menyimpan..." : "Simpan & Selesaikan"}
                </Button>
              </div>
            </div>
          )}

          {/* Tanggapan Section - Display for resolved reports */}
          {laporan.tanggapan && laporan.status === "SELESAI" && (
            <div className="mt-8">
              <h4 className="font-semibold text-lg mb-4">Tanggapan</h4>
              <div className="bg-green-50 border border-green-200 rounded-lg p-4">
                <p className="text-foreground">{laporan.tanggapan}</p>
              </div>
            </div>
          )}

          {/* Block Account Section */}
          {laporan.status !== "SELESAI" && (
            <div className="mt-8 pt-6 border-t">
              <div className="flex items-center justify-between">
                <div>
                  <h4 className="font-semibold text-lg">Tindakan</h4>
                  <p className="text-sm text-muted-foreground mt-1">
                    Blokir mitra atau customer yang terlibat dalam laporan ini
                  </p>
                </div>
                <Button 
                  variant="outline"
                  className="border-red-500 text-red-500 hover:bg-red-50"
                  onClick={() => setShowBlockConfirm(true)}
                >
                  Block Akun
                </Button>
              </div>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Popups */}
      <BlockLaporanPopup
        open={showBlockConfirm}
        onOpenChange={setShowBlockConfirm}
        onConfirm={handleBlockConfirm}
        type="confirm"
        mitraName={laporan.namaMitra}
        customerName={laporan.namaCustomer}
      />
      <BlockLaporanPopup
        open={showBlockSuccess}
        onOpenChange={setShowBlockSuccess}
        onConfirm={() => {}}
        type="success"
      />
      <SaveLaporanPopup
        open={showSaveSuccess}
        onOpenChange={setShowSaveSuccess}
      />
    </div>
  );
};

export default DetailLaporan;
