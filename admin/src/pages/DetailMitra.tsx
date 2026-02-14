import { useState, useEffect } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { ChevronLeft, Edit, Calendar, Search as SearchIcon, CheckCircle, XCircle, AlertTriangle, LockOpen } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Input } from "@/components/ui/input";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { RadioGroup, RadioGroupItem } from "@/components/ui/radio-group";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { useMitra, MitraDetailData } from "@/contexts/MitraContext";
import { mitraApi } from "@/services/api";
import UnblockMitraPopup from "@/components/UnblockMitraPopup";

const alasanPenolakan = [
  "Tidak Memenuhi Persyaratan Kendaraan",
  "Ketidaksesuaian Data Pengemudi",
  "Dokumen Kendaraan Tidak Valid",
  "Riwayat Pengemudi Tidak Memenuhi Kriteria",
  "Kendaraan Tidak Layak Operasi",
  "Penolakan Terhadap Aturan dan Kebijakan Aplikasi",
  "Indikasi Penipuan atau Kecurangan",
  "Lainnya",
];

const alasanPerubahan = [
  "Data sudah diperbaiki",
  "Dokumen baru diunggah",
  "Verifikasi ulang diperlukan",
  "Kesalahan penolakan sebelumnya",
];

const getStatusBadge = (status: "PENGAJUAN" | "TERVERIFIKASI" | "DITOLAK" | "DIBLOCK") => {
  switch (status) {
    case "PENGAJUAN":
      return <Badge className="bg-orange-500 hover:bg-orange-600 text-white text-xs">Pengajuan</Badge>;
    case "TERVERIFIKASI":
      return <Badge className="bg-green-500 hover:bg-green-600 text-white text-xs">Terverifikasi</Badge>;
    case "DITOLAK":
      return <Badge className="bg-red-500 hover:bg-red-600 text-white text-xs">Ditolak</Badge>;
    case "DIBLOCK":
      return <Badge className="bg-gray-500 hover:bg-gray-600 text-white text-xs">Diblock</Badge>;
    default:
      return null;
  }
};

const DetailMitra = () => {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const { mitraDetail, updateMitraStatus, unblockMitra, getMitraDetail } = useMitra();
  
  const [mitra, setMitra] = useState<MitraDetailData | null>(null);
  const [isLoadingDetail, setIsLoadingDetail] = useState(true);
  
  // Get current status from mitra data
  const currentStatus = mitra?.status || "PENGAJUAN";
  
  // Check if mitra is blocked
  const isBlocked = currentStatus === "DIBLOCK";
  
  // Edit mode state
  const [isEditMode, setIsEditMode] = useState(false);
  const [editStatus, setEditStatus] = useState<"PENGAJUAN" | "TERVERIFIKASI" | "DITOLAK" | "DIBLOCK">(currentStatus);
  
  // Edit form states untuk Informasi Pribadi
  const [editNama, setEditNama] = useState("");
  const [editEmail, setEditEmail] = useState("");
  const [editNoTlp, setEditNoTlp] = useState("");
  const [editJenisKelamin, setEditJenisKelamin] = useState("");
  const [editTanggalLahirPribadi, setEditTanggalLahirPribadi] = useState("");
  
  // Edit form states untuk Informasi KTP
  const [editNamaKTP, setEditNamaKTP] = useState("");
  const [editNIK, setEditNIK] = useState("");
  const [editAlamat, setEditAlamat] = useState("");
  const [editTanggalLahir, setEditTanggalLahir] = useState("");
  
  // Modal states
  const [showConfirmTolak, setShowConfirmTolak] = useState(false);
  const [showAlasanTolak, setShowAlasanTolak] = useState(false);
  const [showSuccessVerifikasi, setShowSuccessVerifikasi] = useState(false);
  const [showSuccessTolak, setShowSuccessTolak] = useState(false);
  const [showUbahStatus, setShowUbahStatus] = useState(false);
  const [showUnblockConfirm, setShowUnblockConfirm] = useState(false);
  const [showUnblockSuccess, setShowUnblockSuccess] = useState(false);
  const [showSuccessEdit, setShowSuccessEdit] = useState(false);
  const [previewImage, setPreviewImage] = useState<{ src: string; title: string } | null>(null);
  
  // Form states
  const [selectedAlasan, setSelectedAlasan] = useState("");
  const [catatanLainnya, setCatatanLainnya] = useState("");
  const [selectedAlasanPerubahan, setSelectedAlasanPerubahan] = useState("");
  
  // Fetch mitra detail on mount
  useEffect(() => {
    const fetchDetail = async () => {
      if (!id) return;
      
      try {
        setIsLoadingDetail(true);
        const detail = await getMitraDetail(id);
        console.log('📊 Detail data received:', detail);
        if (detail) {
          setMitra(detail);
          setEditStatus(detail.status);
          // Set initial form values
          setEditNama(detail.nama || "");
          setEditEmail(detail.email || "");
          setEditNoTlp(detail.no_tlp || "");
          setEditJenisKelamin(detail.jenis_kelamin || "");
          setEditTanggalLahirPribadi(detail.tanggal_lahir || detail.ktp_data?.tanggal_lahir || "");
          setEditNamaKTP(detail.ktp_data?.nama_lengkap || "");
          setEditNIK(detail.ktp_data?.nik || "");
          setEditAlamat(detail.ktp_data?.alamat || "");
          setEditTanggalLahir(detail.ktp_data?.tanggal_lahir || "");
        }
      } finally {
        setIsLoadingDetail(false);
      }
    };

    fetchDetail();
  }, [id, getMitraDetail]);

  if (isLoadingDetail) {
    return (
      <div className="p-6">
        <p>Memuat data mitra...</p>
      </div>
    );
  }

  if (!mitra) {
    return (
      <div className="p-6">
        <p>Data mitra tidak ditemukan</p>
        <Button onClick={() => navigate(-1)} className="mt-4">Kembali</Button>
      </div>
    );
  }

  const handleEnterEditMode = () => {
    setIsEditMode(true);
    setEditStatus(currentStatus);
  };

  const handleCancelEdit = () => {
    setIsEditMode(false);
    // Reset form values to original
    if (mitra) {
      setEditNama(mitra.nama || "");
      setEditEmail(mitra.email || "");
      setEditNoTlp(mitra.no_tlp || "");
      setEditJenisKelamin(mitra.jenis_kelamin || "");
      setEditTanggalLahirPribadi(mitra.tanggal_lahir || mitra.ktp_data?.tanggal_lahir || "");
      setEditNamaKTP(mitra.ktp_data?.nama_lengkap || "");
      setEditNIK(mitra.ktp_data?.nik || "");
      setEditAlamat(mitra.ktp_data?.alamat || "");
      setEditTanggalLahir(mitra.ktp_data?.tanggal_lahir || "");
      setEditStatus(currentStatus);
    }
  };

  const handleSave = async () => {
    if (!id) return;
    
    try {
      // Call API to update mitra data
      const updateData = {
        nama: editNama,
        email: editEmail,
        noTlp: editNoTlp,
        jenisKelamin: editJenisKelamin,
        ktp: {
          nama_lengkap: editNamaKTP,
          nik: editNIK,
          alamat: editAlamat,
          tanggal_lahir: editTanggalLahir
        }
      };
      
      console.log("💾 Saving mitra data:", updateData);
      
      await mitraApi.updateMitra(id, updateData);
      
      console.log("✅ Mitra data saved successfully");
      
      // Update local state
      if (mitra) {
        setMitra({
          ...mitra,
          nama: editNama,
          email: editEmail,
          no_tlp: editNoTlp,
          jenis_kelamin: editJenisKelamin,
          tanggal_lahir: editTanggalLahirPribadi,
          ktp_data: mitra.ktp_data ? {
            ...mitra.ktp_data,
            nama_lengkap: editNamaKTP,
            nik: editNIK,
            alamat: editAlamat,
            tanggal_lahir: editTanggalLahir
          } : null
        });
      }
      
      // If changing to DITOLAK, show rejection reason modal
      if (editStatus === "DITOLAK" && currentStatus !== "DITOLAK") {
        setShowConfirmTolak(true);
        return;
      }
      
      // If changing to TERVERIFIKASI
      if (editStatus === "TERVERIFIKASI" && currentStatus !== "TERVERIFIKASI") {
        updateMitraStatus(id, "TERVERIFIKASI");
        setShowSuccessVerifikasi(true);
        setIsEditMode(false);
        return;
      }
      
      // If changing from DITOLAK to PENGAJUAN
      if (editStatus === "PENGAJUAN" && currentStatus === "DITOLAK") {
        setShowUbahStatus(true);
        return;
      }
      
      // Show success modal
      setShowSuccessEdit(true);
      setIsEditMode(false);
    } catch (error) {
      console.error("❌ Failed to save mitra data:", error);
      alert("Gagal menyimpan data. Silakan coba lagi.");
    }
  };

  const handleTolakConfirm = () => {
    setShowConfirmTolak(false);
    setShowAlasanTolak(true);
  };

  const handleSubmitTolak = () => {
    if (!id) return;
    updateMitraStatus(id, "DITOLAK");
    setShowAlasanTolak(false);
    setShowSuccessTolak(true);
    setSelectedAlasan("");
    setCatatanLainnya("");
    setIsEditMode(false);
  };

  const handleUbahKeProses = () => {
    if (!id) return;
    updateMitraStatus(id, "PENGAJUAN");
    setEditStatus("PENGAJUAN");
    setShowUbahStatus(false);
    setSelectedAlasanPerubahan("");
    setIsEditMode(false);
  };

  const handleUnblock = () => {
    if (!id) return;
    unblockMitra(id);
    setShowUnblockConfirm(false);
    setShowUnblockSuccess(true);
  };

  // Helper function to format date
  const formatDate = (dateString: string | null | undefined) => {
    if (!dateString) return "-";
    try {
      const date = new Date(dateString);
      return date.toLocaleDateString('id-ID', { year: 'numeric', month: '2-digit', day: '2-digit' });
    } catch {
      return dateString;
    }
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center gap-4">
        <Button 
          variant="ghost" 
          size="icon" 
          onClick={() => navigate(-1)}
          className="h-8 w-8"
        >
          <ChevronLeft size={20} />
        </Button>
        <h1 className="text-xl font-semibold">Detail Data Mitra</h1>
      </div>

      {/* Profile Section */}
      <div className="bg-card rounded-lg p-6 shadow-sm">
        <div className="flex items-start justify-between">
          <div className="flex items-center gap-4">
            <div className="relative">
              <Avatar className="h-20 w-20">
                <AvatarImage src="/placeholder.svg" />
                <AvatarFallback className="bg-muted text-lg">
                  {mitra.nama.split(" ").map(n => n[0]).join("")}
                </AvatarFallback>
              </Avatar>
              <div className="absolute bottom-0 right-0 bg-primary rounded-full p-1">
                <svg width="12" height="12" viewBox="0 0 24 24" fill="white">
                  <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/>
                </svg>
              </div>
            </div>
            <div>
              <h2 className="text-lg font-semibold">{mitra.nama}</h2>
              <p className="text-muted-foreground text-sm">{mitra.layanan || "Motor"}</p>
              <div className="flex items-center gap-2 mt-1">
                <span className="text-primary font-medium">{mitra.kode || `#${mitra.id}`}</span>
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" className="text-primary">
                  <path d="M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71"/>
                  <path d="M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71"/>
                </svg>
              </div>
              <div className="mt-2">
                {isEditMode ? (
                  <Select value={editStatus} onValueChange={(val) => setEditStatus(val as "PENGAJUAN" | "TERVERIFIKASI" | "DITOLAK" | "DIBLOCK")}>
                    <SelectTrigger className="w-40 h-8">
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="PENGAJUAN">
                        <span className="text-orange-500">Pengajuan</span>
                      </SelectItem>
                      <SelectItem value="TERVERIFIKASI">
                        <span className="text-green-500">Terverifikasi</span>
                      </SelectItem>
                      <SelectItem value="DITOLAK">
                        <span className="text-red-500">Ditolak</span>
                      </SelectItem>
                    </SelectContent>
                  </Select>
                ) : (
                  <div className="flex items-center gap-2">
                    {getStatusBadge(currentStatus)}
                    {isBlocked && (
                      <span className="text-xs text-muted-foreground">(Status tidak dapat diubah)</span>
                    )}
                  </div>
                )}
              </div>
            </div>
          </div>
          <div className="flex items-center gap-2">
            {isEditMode ? (
              <>
                <Button 
                  variant="outline"
                  className="gap-2"
                  onClick={handleCancelEdit}
                >
                  Batal
                </Button>
                <Button 
                  className="gap-2 bg-primary hover:bg-primary/90"
                  onClick={handleSave}
                >
                  Simpan
                </Button>
              </>
            ) : isBlocked ? (
              <Button 
                className="gap-2 bg-green-600 hover:bg-green-700 text-white"
                onClick={() => setShowUnblockConfirm(true)}
              >
                <LockOpen size={16} />
                <span>Unblock</span>
              </Button>
            ) : (
              <Button 
                variant="outline" 
                className="gap-2"
                onClick={handleEnterEditMode}
              >
                <span>Edit</span>
                <Edit size={16} />
              </Button>
            )}
          </div>
        </div>

        {/* Informasi Pribadi */}
        <div className="mt-8">
          <h3 className="text-lg font-semibold mb-4">Informasi Pribadi</h3>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="text-sm text-muted-foreground">Nama Lengkap</label>
              {isEditMode ? (
                <Input 
                  value={editNama} 
                  onChange={(e) => setEditNama(e.target.value)}
                  className="mt-1" 
                />
              ) : (
                <Input value={mitra?.nama || "-"} readOnly className="mt-1 bg-muted/50" />
              )}
            </div>
            <div>
              <label className="text-sm text-muted-foreground">Email</label>
              {isEditMode ? (
                <Input 
                  type="email"
                  value={editEmail} 
                  onChange={(e) => setEditEmail(e.target.value)}
                  className="mt-1" 
                />
              ) : (
                <Input value={mitra?.email || "-"} readOnly className="mt-1 bg-muted/50" />
              )}
            </div>
            <div>
              <label className="text-sm text-muted-foreground">Alamat</label>
              {isEditMode ? (
                <Input 
                  value={editAlamat} 
                  onChange={(e) => setEditAlamat(e.target.value)}
                  className="mt-1" 
                />
              ) : (
                <Input value={mitra?.ktp_data?.alamat || "-"} readOnly className="mt-1 bg-muted/50" />
              )}
            </div>
            <div>
              <label className="text-sm text-muted-foreground">Tanggal Lahir</label>
              <div className="relative mt-1">
                {isEditMode ? (
                  <Input 
                    type="date"
                    value={editTanggalLahirPribadi} 
                    onChange={(e) => setEditTanggalLahirPribadi(e.target.value)}
                    className="pr-10" 
                  />
                ) : (
                  <>
                    <Input value={formatDate(mitra?.tanggal_lahir || mitra?.ktp_data?.tanggal_lahir)} readOnly className="bg-muted/50 pr-10" />
                    <Calendar className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground" size={18} />
                  </>
                )}
              </div>
            </div>
            <div>
              <label className="text-sm text-muted-foreground">Jenis Kelamin</label>
              {isEditMode ? (
                <Select value={editJenisKelamin} onValueChange={setEditJenisKelamin}>
                  <SelectTrigger className="mt-1">
                    <SelectValue placeholder="Pilih Jenis Kelamin" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="Laki-laki">Laki-laki</SelectItem>
                    <SelectItem value="Perempuan">Perempuan</SelectItem>
                  </SelectContent>
                </Select>
              ) : (
                <Input value={mitra?.jenis_kelamin || "-"} readOnly className="mt-1 bg-muted/50" />
              )}
            </div>
            <div>
              <label className="text-sm text-muted-foreground">No. Tlp</label>
              {isEditMode ? (
                <Input 
                  value={editNoTlp} 
                  onChange={(e) => setEditNoTlp(e.target.value)}
                  className="mt-1" 
                />
              ) : (
                <Input value={mitra?.no_tlp || "-"} readOnly className="mt-1 bg-muted/50" />
              )}
            </div>
          </div>
        </div>

        {/* Informasi KTP */}
        <div className="mt-8">
          <h3 className="text-lg font-semibold mb-4">Informasi KTP</h3>
          <div className="flex gap-6">
            <div className="flex-1 grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label className="text-sm text-muted-foreground">Nama Lengkap</label>
                {isEditMode ? (
                  <Input 
                    value={editNamaKTP} 
                    onChange={(e) => setEditNamaKTP(e.target.value)}
                    className="mt-1" 
                  />
                ) : (
                  <Input value={mitra?.ktp_data?.nama_lengkap || "-"} readOnly className="mt-1 bg-muted/50" />
                )}
              </div>
              <div>
                <label className="text-sm text-muted-foreground">NIK</label>
                {isEditMode ? (
                  <Input 
                    value={editNIK} 
                    onChange={(e) => setEditNIK(e.target.value)}
                    className="mt-1" 
                    maxLength={16}
                  />
                ) : (
                  <Input value={mitra?.ktp_data?.nik || "-"} readOnly className="mt-1 bg-muted/50" />
                )}
              </div>
              <div>
                <label className="text-sm text-muted-foreground">Jenis Kelamin</label>
                <Input value="-" readOnly className="mt-1 bg-muted/50" />
              </div>
              <div>
                <label className="text-sm text-muted-foreground">Tanggal Lahir</label>
                <div className="relative mt-1">
                  {isEditMode ? (
                    <Input 
                      type="date"
                      value={editTanggalLahir} 
                      onChange={(e) => setEditTanggalLahir(e.target.value)}
                      className="pr-10" 
                    />
                  ) : (
                    <>
                      <Input value={formatDate(mitra?.ktp_data?.tanggal_lahir)} readOnly className="bg-muted/50 pr-10" />
                      <Calendar className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground" size={18} />
                    </>
                  )}
                </div>
              </div>
            </div>
            {mitra?.ktp_data?.photo_ktp ? (
              <div 
                className="relative w-32 h-20 bg-muted rounded-lg flex items-center justify-center overflow-hidden border cursor-pointer hover:opacity-80 transition-opacity"
                onClick={() => setPreviewImage({ src: mitra?.ktp_data?.photo_ktp || "", title: "Foto KTP" })}
              >
                <img src={mitra.ktp_data.photo_ktp} alt="KTP" className="w-full h-full object-cover" />
                <div className="absolute bottom-1 right-1 bg-primary/80 rounded-full p-1">
                  <SearchIcon size={12} className="text-white" />
                </div>
              </div>
            ) : (
              <div className="relative w-32 h-20 bg-muted rounded-lg flex items-center justify-center overflow-hidden border">
                <span className="text-xs text-muted-foreground">No Image</span>
              </div>
            )}
          </div>
        </div>

        {/* Informasi SIM */}
        <div className="mt-8">
          <h3 className="text-lg font-semibold mb-4">Informasi SIM</h3>
          <div className="flex gap-6">
            <div className="flex-1 grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label className="text-sm text-muted-foreground">Nama Lengkap</label>
                <Input value="-" readOnly className="mt-1 bg-muted/50" />
              </div>
              <div>
                <label className="text-sm text-muted-foreground">Nomor SIM</label>
                <Input value="-" readOnly className="mt-1 bg-muted/50" />
              </div>
              <div>
                <label className="text-sm text-muted-foreground">Jenis Kelamin</label>
                <Input value="-" readOnly className="mt-1 bg-muted/50" />
              </div>
              <div>
                <label className="text-sm text-muted-foreground">Tangal Lahir</label>
                <div className="relative mt-1">
                  <Input value="-" readOnly className="bg-muted/50 pr-10" />
                  <Calendar className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground" size={18} />
                </div>
              </div>
            </div>
            <div className="relative w-32 h-20 bg-muted rounded-lg flex items-center justify-center overflow-hidden border">
              <span className="text-xs text-muted-foreground">No Image</span>
            </div>
          </div>
        </div>
      </div>

      {/* Modal: Konfirmasi Tolak */}
      <Dialog open={showConfirmTolak} onOpenChange={setShowConfirmTolak}>
        <DialogContent className="sm:max-w-md text-center">
          <div className="flex flex-col items-center py-4">
            <h2 className="text-lg font-semibold mb-2">
              Anda akan Menolak verifikasi mitra ini.
            </h2>
            <p className="text-muted-foreground mb-6">Apakah Anda yakin?</p>
            <div className="relative mb-6">
              <div className="w-20 h-24 bg-muted rounded-lg flex items-center justify-center">
                <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" className="text-muted-foreground">
                  <path d="M9 12h6M9 16h6M17 21H7a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h7l5 5v11a2 2 0 0 1-2 2z" />
                </svg>
              </div>
              <div className="absolute -bottom-2 -right-2 bg-red-500 rounded-full p-1">
                <XCircle size={20} className="text-white" />
              </div>
            </div>
            <div className="flex gap-3">
              <Button 
                variant="outline" 
                onClick={() => setShowConfirmTolak(false)}
                className="min-w-24"
              >
                Kembali
              </Button>
              <Button 
                className="min-w-24 bg-red-500 hover:bg-red-600"
                onClick={handleTolakConfirm}
              >
                Ya.
              </Button>
            </div>
          </div>
        </DialogContent>
      </Dialog>

      {/* Modal: Alasan Penolakan */}
      <Dialog open={showAlasanTolak} onOpenChange={setShowAlasanTolak}>
        <DialogContent className="sm:max-w-md">
          <DialogHeader>
            <div className="flex items-center gap-2">
              <Button 
                variant="ghost" 
                size="icon" 
                className="h-6 w-6"
                onClick={() => {
                  setShowAlasanTolak(false);
                  setShowConfirmTolak(true);
                }}
              >
                <ChevronLeft size={16} />
              </Button>
              <DialogTitle>Pembatalan Verifikasi Mitra</DialogTitle>
            </div>
          </DialogHeader>
          <div className="py-4">
            <p className="text-sm text-muted-foreground mb-4">
              Berikan alasan pembatalan verifikasi mitra!
            </p>
            <RadioGroup value={selectedAlasan} onValueChange={setSelectedAlasan}>
              {alasanPenolakan.map((alasan) => (
                <div key={alasan} className="flex items-center space-x-2 py-1">
                  <RadioGroupItem value={alasan} id={alasan} />
                  <Label htmlFor={alasan} className="text-sm font-normal cursor-pointer">
                    {alasan}
                  </Label>
                </div>
              ))}
            </RadioGroup>
            
            {selectedAlasan === "Lainnya" && (
              <Textarea
                placeholder="Tambahkan catatan (wajib jika memilih 'Lainnya')"
                value={catatanLainnya}
                onChange={(e) => setCatatanLainnya(e.target.value)}
                className="mt-4"
                rows={3}
              />
            )}
            
            <div className="flex flex-col gap-2 mt-6">
              <Button 
                className="w-full bg-red-500 hover:bg-red-600"
                onClick={handleSubmitTolak}
                disabled={!selectedAlasan || (selectedAlasan === "Lainnya" && !catatanLainnya)}
              >
                Tolak verifikasi
              </Button>
              <Button 
                variant="outline" 
                className="w-full"
                onClick={() => setShowAlasanTolak(false)}
              >
                Kembali
              </Button>
            </div>
          </div>
        </DialogContent>
      </Dialog>

      {/* Modal: Success Verifikasi */}
      <Dialog open={showSuccessVerifikasi} onOpenChange={setShowSuccessVerifikasi}>
        <DialogContent className="sm:max-w-md text-center">
          <div className="flex flex-col items-center py-4">
            <h2 className="text-lg font-semibold mb-2">
              Anda telah berhasil memverifikasi mitra.
            </h2>
            <p className="text-muted-foreground mb-6">Semua data sudah diperbarui.</p>
            <div className="relative mb-6">
              <div className="w-20 h-24 bg-blue-100 rounded-lg flex items-center justify-center">
                <svg width="40" height="40" viewBox="0 0 24 24" fill="none" className="text-primary">
                  <circle cx="9" cy="7" r="4" stroke="currentColor" strokeWidth="2" />
                  <path d="M3 21v-2a4 4 0 0 1 4-4h4a4 4 0 0 1 4 4v2" stroke="currentColor" strokeWidth="2" />
                  <rect x="12" y="8" width="8" height="10" rx="1" stroke="currentColor" strokeWidth="1.5" fill="white" />
                  <path d="M14 11h4M14 13h4M14 15h2" stroke="currentColor" strokeWidth="1" />
                </svg>
              </div>
              <div className="absolute -bottom-1 -right-1 bg-green-500 rounded-full p-0.5">
                <CheckCircle size={18} className="text-white" />
              </div>
            </div>
            <Button 
              className="min-w-24"
              onClick={() => setShowSuccessVerifikasi(false)}
            >
              Oke
            </Button>
          </div>
        </DialogContent>
      </Dialog>

      {/* Modal: Success Tolak */}
      <Dialog open={showSuccessTolak} onOpenChange={setShowSuccessTolak}>
        <DialogContent className="sm:max-w-md text-center">
          <div className="flex flex-col items-center py-4">
            <h2 className="text-lg font-semibold mb-6">
              Anda telah menolak verifikasi mitra
            </h2>
            <div className="relative mb-6">
              <div className="w-16 h-16 bg-red-100 rounded-full flex items-center justify-center">
                <svg width="40" height="40" viewBox="0 0 24 24" fill="none">
                  <circle cx="12" cy="12" r="10" stroke="hsl(var(--destructive))" strokeWidth="2" />
                  <path d="M8 8l8 8M16 8l-8 8" stroke="hsl(var(--destructive))" strokeWidth="2" strokeLinecap="round" />
                </svg>
              </div>
              <div className="absolute -top-1 -right-1 bg-red-500 text-white text-[8px] font-bold px-1 rounded transform rotate-12">
                CANCELLED
              </div>
            </div>
            <Button 
              className="min-w-24"
              onClick={() => setShowSuccessTolak(false)}
            >
              Oke
            </Button>
          </div>
        </DialogContent>
      </Dialog>

      {/* Modal: Ubah Status ke Proses */}
      <Dialog open={showUbahStatus} onOpenChange={setShowUbahStatus}>
        <DialogContent className="sm:max-w-md">
          <div className="py-4">
            <div className="flex items-center gap-2 text-amber-600 mb-2">
              <AlertTriangle size={20} />
              <h2 className="text-lg font-semibold">Konfirmasi Perubahan Status</h2>
            </div>
            <p className="text-sm text-muted-foreground mb-4">
              Anda ingin mengubah status dari Ditolak menjadi Proses.<br />
              Silakan pilih alasan perubahan.
            </p>
            
            <Select value={selectedAlasanPerubahan} onValueChange={setSelectedAlasanPerubahan}>
              <SelectTrigger className="w-full">
                <SelectValue placeholder="Pilih Alasan Perubahan" />
              </SelectTrigger>
              <SelectContent>
                {alasanPerubahan.map((alasan) => (
                  <SelectItem key={alasan} value={alasan}>
                    {alasan}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
            
            <div className="flex gap-3 mt-6">
              <Button 
                variant="outline" 
                onClick={() => setShowUbahStatus(false)}
              >
                Batal
              </Button>
              <Button 
                className="bg-primary"
                onClick={handleUbahKeProses}
                disabled={!selectedAlasanPerubahan}
              >
                Ubah ke proses verifikasi
              </Button>
            </div>
          </div>
        </DialogContent>
      </Dialog>

      {/* Modal: Image Preview */}
      <Dialog open={!!previewImage} onOpenChange={() => setPreviewImage(null)}>
        <DialogContent className="sm:max-w-2xl p-0 overflow-hidden">
          <DialogHeader className="p-4 pb-0">
            <DialogTitle>{previewImage?.title}</DialogTitle>
          </DialogHeader>
          <div className="p-4">
            <div className="w-full aspect-[3/2] bg-muted rounded-lg overflow-hidden flex items-center justify-center">
              <img 
                src={previewImage?.src} 
                alt={previewImage?.title} 
                className="max-w-full max-h-full object-contain"
              />
            </div>
          </div>
        </DialogContent>
      </Dialog>

      {/* Modal: Success Edit */}
      <Dialog open={showSuccessEdit} onOpenChange={setShowSuccessEdit}>
        <DialogContent className="sm:max-w-md text-center">
          <div className="flex flex-col items-center py-4">
            <h2 className="text-lg font-semibold mb-2">
              Data mitra berhasil diperbarui
            </h2>
            <p className="text-muted-foreground mb-6">Semua perubahan telah disimpan.</p>
            <div className="relative mb-6">
              <div className="w-16 h-16 bg-green-100 rounded-full flex items-center justify-center">
                <CheckCircle size={32} className="text-green-500" />
              </div>
            </div>
            <Button 
              className="min-w-24"
              onClick={() => setShowSuccessEdit(false)}
            >
              Oke
            </Button>
          </div>
        </DialogContent>
      </Dialog>

      {/* Modal: Unblock Confirmation */}
      <UnblockMitraPopup
        open={showUnblockConfirm}
        onOpenChange={setShowUnblockConfirm}
        onConfirm={handleUnblock}
        type="confirm"
      />

      {/* Modal: Unblock Success */}
      <UnblockMitraPopup
        open={showUnblockSuccess}
        onOpenChange={setShowUnblockSuccess}
        onConfirm={() => {}}
        type="success"
      />
    </div>
  );
};

export default DetailMitra;