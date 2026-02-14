import { useState } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { ChevronLeft, Copy, ExternalLink } from "lucide-react";
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
  const { getLaporanDetail, updateLaporan } = useLaporan();
  const { blockMitra } = useMitra();
  const { blockCustomer } = useCustomer();
  const laporan = getLaporanDetail(id || "");

  const [showBlockConfirm, setShowBlockConfirm] = useState(false);
  const [showBlockSuccess, setShowBlockSuccess] = useState(false);
  const [showSaveSuccess, setShowSaveSuccess] = useState(false);
  const [showMitraDetail, setShowMitraDetail] = useState(false);
  const [editedLaporan, setEditedLaporan] = useState(laporan?.laporan || "");
  const [isEditing, setIsEditing] = useState(false);

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

  const handleTanggapi = () => {
    setShowMitraDetail(true);
  };

  // Detail Laporan View
  if (!showMitraDetail) {
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
              <div className="flex items-center justify-between mb-4">
                <h4 className="font-semibold text-lg">Laporan</h4>
                <Button 
                  variant="link" 
                  className="text-primary p-0 h-auto"
                  onClick={handleTanggapi}
                >
                  Tanggapi
                </Button>
              </div>
              <div className="bg-gray-100 rounded-lg p-4">
                <p className="text-foreground">{laporan.laporan}</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>
    );
  }

  // Detail Data Mitra View (after clicking Tanggapi)
  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center gap-4">
        <Button
          variant="ghost"
          size="icon"
          onClick={() => setShowMitraDetail(false)}
          className="h-8 w-8"
        >
          <ChevronLeft size={24} />
        </Button>
        <h1 className="text-2xl font-semibold">Detail Data Mitra</h1>
      </div>

      {/* Laporan Section with Edit */}
      <Card>
        <CardContent className="p-6">
          <div className="flex items-center justify-between mb-4">
            <h4 className="font-semibold text-lg">Laporan</h4>
            {!isEditing ? (
              <Button 
                variant="outline" 
                className="gap-2"
                onClick={() => setIsEditing(true)}
              >
                Edit
                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15.232 5.232l3.536 3.536m-2.036-5.036a2.5 2.5 0 113.536 3.536L6.5 21.036H3v-3.572L16.732 3.732z" />
                </svg>
              </Button>
            ) : (
              <Button 
                className="bg-primary"
                onClick={handleSaveLaporan}
              >
                Simpan
              </Button>
            )}
          </div>
          <div className="bg-gray-100 rounded-lg p-4">
            {isEditing ? (
              <Textarea
                value={editedLaporan}
                onChange={(e) => setEditedLaporan(e.target.value)}
                className="min-h-[100px] bg-white"
              />
            ) : (
              <p className="text-foreground">{editedLaporan}</p>
            )}
          </div>
        </CardContent>
      </Card>

      {/* Tindakan Section */}
      <Card>
        <CardContent className="p-6">
          <div className="flex items-center justify-between">
            <h4 className="font-semibold text-lg">Tindakan</h4>
            <Button 
              variant="outline"
              className="border-red-500 text-red-500 hover:bg-red-50"
              onClick={() => setShowBlockConfirm(true)}
            >
              Block Akun
            </Button>
          </div>
          <p className="text-sm text-muted-foreground mt-2">
            Blokir mitra atau customer yang terlibat dalam laporan ini
          </p>
        </CardContent>
      </Card>

      {/* Mitra Profile Card */}
      <Card>
        <CardContent className="p-6">
          <div className="flex items-center gap-4 mb-6">
            <div className="relative">
              <div className="w-20 h-20 bg-amber-100 rounded-full flex items-center justify-center overflow-hidden">
                <img
                  src="/placeholder.svg"
                  alt={laporan.namaMitra}
                  className="w-full h-full object-cover"
                />
              </div>
              <div className="absolute -bottom-1 -right-1 w-6 h-6 bg-blue-500 rounded-full flex items-center justify-center">
                <svg className="w-4 h-4 text-white" fill="currentColor" viewBox="0 0 24 24">
                  <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/>
                </svg>
              </div>
            </div>
            <div>
              <h3 className="font-semibold text-xl">{laporan.namaMitra}</h3>
              <p className="text-muted-foreground">Nebeng {laporan.mitraKendaraan}</p>
              <div className="flex items-center gap-1 text-primary">
                <span className="font-medium">{laporan.mitraId}</span>
                <ExternalLink size={14} />
              </div>
            </div>
          </div>

          {/* Personal Info */}
          <div className="mt-6">
            <h4 className="font-semibold text-lg mb-4">Informasi Pribadi</h4>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="text-sm text-muted-foreground">Nama Lengkap</label>
                <Input value={laporan.namaMitra} disabled className="mt-1 bg-gray-50" />
              </div>
              <div>
                <label className="text-sm text-muted-foreground">Email</label>
                <Input value={laporan.mitraEmail} disabled className="mt-1 bg-gray-50" />
              </div>
            </div>
            <div className="grid grid-cols-2 gap-4 mt-4">
              <div>
                <label className="text-sm text-muted-foreground">Tempat Lahir</label>
                <Input value={laporan.mitraTempatLahir} disabled className="mt-1 bg-gray-50" />
              </div>
              <div>
                <label className="text-sm text-muted-foreground">Tanggal Lahir</label>
                <div className="relative">
                  <Input value={laporan.mitraTanggalLahir} disabled className="mt-1 bg-gray-50" />
                  <svg className="absolute right-3 top-1/2 -translate-y-1/2 mt-0.5 w-4 h-4 text-muted-foreground" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
                  </svg>
                </div>
              </div>
            </div>
            <div className="grid grid-cols-2 gap-4 mt-4">
              <div>
                <label className="text-sm text-muted-foreground">Jenis Kelamin</label>
                <div className="relative">
                  <Input value={laporan.mitraJenisKelamin} disabled className="mt-1 bg-gray-50" />
                  <svg className="absolute right-3 top-1/2 -translate-y-1/2 mt-0.5 w-4 h-4 text-muted-foreground" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
                  </svg>
                </div>
              </div>
              <div>
                <label className="text-sm text-muted-foreground">No. Tlp</label>
                <Input value={laporan.mitraPhone} disabled className="mt-1 bg-gray-50" />
              </div>
            </div>
          </div>

          {/* KTP Info */}
          <div className="mt-8">
            <h4 className="font-semibold text-lg mb-4">Informasi KTP</h4>
            {/* Placeholder for KTP info */}
          </div>
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
