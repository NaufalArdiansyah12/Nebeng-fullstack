import { useState, useEffect } from "react"; // 1. Tambahkan useEffect
import { useParams, useNavigate } from "react-router-dom";
import { ChevronLeft, Calendar, Edit, Check, X, CheckCircle, XCircle, Lock, LockOpen } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Input } from "@/components/ui/input";
import { useCustomer } from "@/contexts/CustomerContext";
import { Dialog, DialogContent } from "@/components/ui/dialog";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { useToast } from "@/hooks/use-toast"; 
import ktpPlaceholder from "@/assets/ktp-placeholder.png";
import BlockCustomerPopup from "@/components/BlockCustomerPopup";
import UnblockCustomerPopup from "@/components/UnblockCustomerPopup";

const getStatusBadge = (status?: string | null) => {
  switch (status) {
    case "TERVERIFIKASI":
      return <Badge className="bg-green-500 hover:bg-green-600 text-white text-xs">Terverifikasi</Badge>;
    case "DITOLAK":
      return <Badge className="bg-red-500 hover:bg-red-600 text-white text-xs">Ditolak</Badge>;
    case "PENGAJUAN":
      return <Badge className="bg-orange-500 hover:bg-orange-600 text-white text-xs">Pengajuan</Badge>;
    case "DIBLOCK":
      return <Badge className="bg-gray-500 hover:bg-gray-600 text-white text-xs">Diblock</Badge>;
    default:
      return null;
  }
};

const DetailCustomer = () => {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  
  // 2. Tambahkan fetchCustomerDetail di sini
  const { customerDetail, fetchCustomerDetail, updateCustomerStatus, updateCustomerInfo, blockCustomer, unblockCustomer } = useCustomer();
  
  const { toast } = useToast();
  
  const customer = id ? customerDetail[id] : null;
  const currentStatus = customer?.status || "PENGAJUAN";
  const isBlocked = currentStatus === "DIBLOCK";

  // Edit mode state
  const [isEditMode, setIsEditMode] = useState(false);
  const [editData, setEditData] = useState({
    namaLengkap: "",
    email: "",
    tempatLahir: "",
    tanggalLahir: "",
    jenisKelamin: "",
    noTlp: "",
  });
  
  // Modal states
  const [showConfirmTerima, setShowConfirmTerima] = useState(false);
  const [showConfirmTolak, setShowConfirmTolak] = useState(false);
  const [showTerimaModal, setShowTerimaModal] = useState(false);
  const [showTolakModal, setShowTolakModal] = useState(false);
  const [showEditSuccessModal, setShowEditSuccessModal] = useState(false);
  const [showKTPPreview, setShowKTPPreview] = useState(false);
  const [showBlockConfirm, setShowBlockConfirm] = useState(false);
  const [showBlockSuccess, setShowBlockSuccess] = useState(false);
  const [showUnblockConfirm, setShowUnblockConfirm] = useState(false);
  const [showUnblockSuccess, setShowUnblockSuccess] = useState(false);

  // 3. TAMBAHKAN LOGIC FETCH INI (PENTING)
  useEffect(() => {
    if (id) {
      // Jika data customer ini BELUM ada di context, ambil dari server
      if (!customerDetail[id]) {
        fetchCustomerDetail(id);
      }
    }
  }, [id, customerDetail, fetchCustomerDetail]);
  // ---------------------------------------

  if (!customer) {
    return (
      <div className="p-6">
        <p>Loading atau Data customer tidak ditemukan</p>
        <Button onClick={() => navigate(-1)} className="mt-4">Kembali</Button>
      </div>
    );
  }

  const handleEnterEditMode = () => {
    setEditData({
      namaLengkap: customer.informasiPribadi.namaLengkap,
      email: customer.informasiPribadi.email,
      tempatLahir: customer.informasiPribadi.tempatLahir,
      tanggalLahir: customer.informasiPribadi.tanggalLahir,
      jenisKelamin: customer.informasiPribadi.jenisKelamin,
      noTlp: customer.informasiPribadi.noTlp,
    });
    setIsEditMode(true);
  };

  const handleCancelEdit = () => {
    setIsEditMode(false);
  };

  const handleSaveEdit = () => {
    if (!id) return;
    
    if (!editData.namaLengkap.trim() || !editData.email.trim() || !editData.noTlp.trim()) {
      toast({
        title: "Error",
        description: "Nama, Email, dan No. Tlp wajib diisi",
        variant: "destructive",
      });
      return;
    }
    
    updateCustomerInfo(id, editData);
    setIsEditMode(false);
    setShowEditSuccessModal(true);
  };

  const handleInputChange = (field: keyof typeof editData, value: string) => {
    setEditData(prev => ({ ...prev, [field]: value }));
  };

  const handleTerimaClick = () => {
    setShowConfirmTerima(true);
  };

  const handleTolakClick = () => {
    setShowConfirmTolak(true);
  };

  const handleConfirmTerima = () => {
    if (!id) return;
    updateCustomerStatus(id, "TERVERIFIKASI");
    setShowConfirmTerima(false);
    setShowTerimaModal(true);
  };

  const handleConfirmTolak = () => {
    if (!id) return;
    updateCustomerStatus(id, "DITOLAK");
    setShowConfirmTolak(false);
    setShowTolakModal(true);
  };

  const handleBlock = () => {
    if (!id) return;
    blockCustomer(id);
    setShowBlockConfirm(false);
    setShowBlockSuccess(true);
  };

  const handleUnblock = () => {
    if (!id) return;
    unblockCustomer(id);
    setShowUnblockConfirm(false);
    setShowUnblockSuccess(true);
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
        <h1 className="text-xl font-semibold">Detail Data Costumer</h1>
      </div>

      {/* Profile Section */}
      <div className="bg-card rounded-lg p-6 shadow-sm">
        <div className="flex items-start justify-between">
          <div className="flex items-center gap-4">
            <div className="relative">
              <Avatar className="h-20 w-20 border-4 border-orange-200">
                <AvatarImage src="/placeholder.svg" />
                <AvatarFallback className="bg-orange-100 text-orange-600 text-lg">
                  {customer.nama.split(" ").map(n => n[0]).join("")}
                </AvatarFallback>
              </Avatar>
            </div>
            <div>
              <h2 className="text-lg font-semibold">{customer.nama}</h2>
              <p className="text-muted-foreground text-sm">Nebeng Motor</p>
              <span className="text-primary font-medium text-sm">{customer.kode || "No Code"}</span>
              <div className="mt-2">
                {getStatusBadge(customer.status)}
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
                  <X size={16} />
                  Batal
                </Button>
                <Button 
                  className="gap-2 bg-primary hover:bg-primary/90"
                  onClick={handleSaveEdit}
                >
                  <Check size={16} />
                  Simpan
                </Button>
              </>
            ) : (
              <Button 
                variant="outline" 
                className="gap-2 text-primary border-primary hover:bg-primary/10"
                onClick={handleEnterEditMode}
              >
                <Edit size={16} />
                Edit
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
              <Input 
                value={isEditMode ? editData.namaLengkap : customer.informasiPribadi.namaLengkap} 
                readOnly={!isEditMode}
                onChange={(e) => handleInputChange("namaLengkap", e.target.value)}
                className={`mt-1 ${isEditMode ? "bg-background" : "bg-muted/50"}`}
              />
            </div>
            <div>
              <label className="text-sm text-muted-foreground">Email</label>
              <Input 
                value={isEditMode ? editData.email : customer.informasiPribadi.email} 
                readOnly={!isEditMode}
                onChange={(e) => handleInputChange("email", e.target.value)}
                className={`mt-1 ${isEditMode ? "bg-background" : "bg-muted/50"}`}
              />
            </div>
            <div>
              <label className="text-sm text-muted-foreground">Tempat Lahir</label>
              <Input 
                value={isEditMode ? editData.tempatLahir : customer.informasiPribadi.tempatLahir} 
                readOnly={!isEditMode}
                onChange={(e) => handleInputChange("tempatLahir", e.target.value)}
                className={`mt-1 ${isEditMode ? "bg-background" : "bg-muted/50"}`}
              />
            </div>
            <div>
              <label className="text-sm text-muted-foreground">Tanggal Lahir</label>
              <div className="relative mt-1">
                <Input 
                  value={isEditMode ? editData.tanggalLahir : customer.informasiPribadi.tanggalLahir} 
                  readOnly={!isEditMode}
                  onChange={(e) => handleInputChange("tanggalLahir", e.target.value)}
                  className={`pr-10 ${isEditMode ? "bg-background" : "bg-muted/50"}`}
                />
                <Calendar className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground" size={18} />
              </div>
            </div>
            <div>
              <label className="text-sm text-muted-foreground">Jenis Kelamin</label>
              {isEditMode ? (
                <Select value={editData.jenisKelamin} onValueChange={(val) => handleInputChange("jenisKelamin", val)}>
                  <SelectTrigger className="mt-1">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="Laki - Laki">Laki - Laki</SelectItem>
                    <SelectItem value="Perempuan">Perempuan</SelectItem>
                  </SelectContent>
                </Select>
              ) : (
                <Select value={customer.informasiPribadi.jenisKelamin} disabled>
                  <SelectTrigger className="mt-1 bg-muted/50">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="Laki - Laki">Laki - Laki</SelectItem>
                    <SelectItem value="Perempuan">Perempuan</SelectItem>
                  </SelectContent>
                </Select>
              )}
            </div>
            <div>
              <label className="text-sm text-muted-foreground">No. Tlp</label>
              <Input 
                value={isEditMode ? editData.noTlp : customer.informasiPribadi.noTlp} 
                readOnly={!isEditMode}
                onChange={(e) => handleInputChange("noTlp", e.target.value)}
                className={`mt-1 ${isEditMode ? "bg-background" : "bg-muted/50"}`}
              />
            </div>
          </div>
        </div>

        {/* Informasi KTP */}
        <div className="mt-8">
          <h3 className="text-lg font-semibold mb-4">Informasi KTP</h3>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div className="md:col-span-2 space-y-4">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label className="text-sm text-muted-foreground">Nama Lengkap</label>
                  <Input 
                    value={customer.informasiKTP?.namaLengkap || customer.informasiPribadi.namaLengkap} 
                    readOnly
                    className="mt-1 bg-muted/50" 
                  />
                </div>
                <div>
                  <label className="text-sm text-muted-foreground">NIK</label>
                  <Input 
                    value={customer.informasiKTP?.nik || "-"} 
                    readOnly
                    className="mt-1 bg-muted/50" 
                  />
                </div>
                <div>
                  <label className="text-sm text-muted-foreground">Jenis Kelamin</label>
                  <Select value={customer.informasiKTP?.jenisKelamin || customer.informasiPribadi.jenisKelamin} disabled>
                    <SelectTrigger className="mt-1 bg-muted/50">
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="Laki - Laki">Laki - Laki</SelectItem>
                      <SelectItem value="Perempuan">Perempuan</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
                <div>
                  <label className="text-sm text-muted-foreground">Tanggal Lahir</label>
                  <div className="relative mt-1">
                    <Input 
                      value={customer.informasiKTP?.tanggalLahir || customer.informasiPribadi.tanggalLahir} 
                      readOnly
                      className="pr-10 bg-muted/50" 
                    />
                    <Calendar className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground" size={18} />
                  </div>
                </div>
              </div>
            </div>
            <div className="flex justify-center md:justify-end">
              <img 
                src={ktpPlaceholder} 
                alt={`KTP ${customer.informasiKTP?.namaLengkap || customer.nama}`}
                className="w-48 h-auto rounded-lg border-2 border-blue-200 shadow-md object-cover cursor-pointer hover:opacity-90 hover:shadow-lg transition-all"
                onClick={() => setShowKTPPreview(true)}
              />
            </div>
          </div>
        </div>

        {/* Action Buttons */}
        <div className="mt-8 flex gap-4">
          {isBlocked ? (
            <Button 
              className="bg-green-600 hover:bg-green-700 text-white px-8 gap-2"
              onClick={() => setShowUnblockConfirm(true)}
            >
              <LockOpen size={16} />
              Unblock
            </Button>
          ) : (
            <>
              <Button 
                className="bg-primary hover:bg-primary/90 text-primary-foreground px-8"
                onClick={handleTerimaClick}
              >
                Terima
              </Button>
              <Button 
                variant="outline"
                className="border-red-500 text-red-500 hover:bg-red-50 px-8"
                onClick={handleTolakClick}
              >
                Tolak
              </Button>
              <Button 
                variant="outline"
                className="border-gray-500 text-gray-700 hover:bg-gray-50 px-8 gap-2"
                onClick={() => setShowBlockConfirm(true)}
              >
                <Lock size={16} />
                Block
              </Button>
            </>
          )}
        </div>
      </div>

      {/* Modal: Konfirmasi Terima */}
      <Dialog open={showConfirmTerima} onOpenChange={setShowConfirmTerima}>
        <DialogContent className="sm:max-w-md text-center">
          <div className="flex flex-col items-center py-4">
            <h2 className="text-lg font-semibold mb-2">Anda akan Menerima verifikasi customer ini.</h2>
            <p className="text-muted-foreground mb-6">Apakah Anda yakin?</p>
            <div className="relative mb-6">
              <div className="w-20 h-24 bg-muted rounded-lg flex items-center justify-center">
                <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" className="text-muted-foreground"><path d="M9 12h6M9 16h6M17 21H7a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h7l5 5v11a2 2 0 0 1-2 2z" /></svg>
              </div>
              <div className="absolute -bottom-2 -right-2 bg-green-500 rounded-full p-1"><CheckCircle size={20} className="text-white" /></div>
            </div>
            <div className="flex gap-3">
              <Button variant="outline" onClick={() => setShowConfirmTerima(false)} className="min-w-24">Kembali</Button>
              <Button className="min-w-24 bg-primary hover:bg-primary/90" onClick={handleConfirmTerima}>Ya.</Button>
            </div>
          </div>
        </DialogContent>
      </Dialog>

      {/* Modal: Konfirmasi Tolak */}
      <Dialog open={showConfirmTolak} onOpenChange={setShowConfirmTolak}>
        <DialogContent className="sm:max-w-md text-center">
          <div className="flex flex-col items-center py-4">
            <h2 className="text-lg font-semibold mb-2">Anda akan Menolak verifikasi customer ini.</h2>
            <p className="text-muted-foreground mb-6">Apakah Anda yakin?</p>
            <div className="relative mb-6">
              <div className="w-20 h-24 bg-muted rounded-lg flex items-center justify-center">
                <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" className="text-muted-foreground"><path d="M9 12h6M9 16h6M17 21H7a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h7l5 5v11a2 2 0 0 1-2 2z" /></svg>
              </div>
              <div className="absolute -bottom-2 -right-2 bg-red-500 rounded-full p-1"><XCircle size={20} className="text-white" /></div>
            </div>
            <div className="flex gap-3">
              <Button variant="outline" onClick={() => setShowConfirmTolak(false)} className="min-w-24">Kembali</Button>
              <Button className="min-w-24 bg-red-500 hover:bg-red-600" onClick={handleConfirmTolak}>Ya.</Button>
            </div>
          </div>
        </DialogContent>
      </Dialog>

      {/* Terima Success Modal */}
      <Dialog open={showTerimaModal} onOpenChange={setShowTerimaModal}>
        <DialogContent className="sm:max-w-md text-center">
          <div className="flex flex-col items-center py-4">
            <h2 className="text-lg font-semibold mb-2">Anda telah berhasil memverifikasi customer.</h2>
            <p className="text-muted-foreground mb-6">Semua data sudah diperbarui.</p>
            <div className="relative mb-6">
              <div className="w-20 h-24 bg-blue-100 rounded-lg flex items-center justify-center">
                <svg width="40" height="40" viewBox="0 0 24 24" fill="none" className="text-primary"><circle cx="9" cy="7" r="4" stroke="currentColor" strokeWidth="2" /><path d="M3 21v-2a4 4 0 0 1 4-4h4a4 4 0 0 1 4 4v2" stroke="currentColor" strokeWidth="2" /><rect x="12" y="8" width="8" height="10" rx="1" stroke="currentColor" strokeWidth="1.5" fill="white" /><path d="M14 11h4M14 13h4M14 15h2" stroke="currentColor" strokeWidth="1" /></svg>
              </div>
              <div className="absolute -bottom-1 -right-1 bg-green-500 rounded-full p-0.5"><CheckCircle size={18} className="text-white" /></div>
            </div>
            <Button className="min-w-24" onClick={() => { setShowTerimaModal(false); navigate("/dashboard/verifikasi-costumer"); }}>Oke</Button>
          </div>
        </DialogContent>
      </Dialog>

      {/* Tolak Modal */}
      <Dialog open={showTolakModal} onOpenChange={setShowTolakModal}>
        <DialogContent className="sm:max-w-md text-center">
          <div className="flex flex-col items-center py-4">
            <h2 className="text-lg font-semibold mb-6">Anda telah menolak verifikasi customer</h2>
            <div className="relative mb-6">
              <div className="w-16 h-16 bg-red-100 rounded-full flex items-center justify-center">
                <svg width="40" height="40" viewBox="0 0 24 24" fill="none"><circle cx="12" cy="12" r="10" stroke="hsl(var(--destructive))" strokeWidth="2" /><path d="M8 8l8 8M16 8l-8 8" stroke="hsl(var(--destructive))" strokeWidth="2" strokeLinecap="round" /></svg>
              </div>
              <div className="absolute -top-1 -right-1 bg-red-500 text-white text-[8px] font-bold px-1 rounded transform rotate-12">CANCELLED</div>
            </div>
            <Button className="min-w-24" onClick={() => { setShowTolakModal(false); navigate("/dashboard/verifikasi-costumer"); }}>Oke</Button>
          </div>
        </DialogContent>
      </Dialog>

      {/* Edit Success Modal */}
      <Dialog open={showEditSuccessModal} onOpenChange={setShowEditSuccessModal}>
        <DialogContent className="sm:max-w-md text-center">
          <div className="flex flex-col items-center py-4">
            <h2 className="text-lg font-semibold mb-6">Data terbaru berhasil disimpan</h2>
            <div className="relative mb-6">
              <div className="w-20 h-24 bg-blue-100 rounded-lg flex items-center justify-center">
                <svg width="40" height="40" viewBox="0 0 24 24" fill="none" className="text-primary"><circle cx="9" cy="7" r="4" stroke="currentColor" strokeWidth="2" /><path d="M3 21v-2a4 4 0 0 1 4-4h4a4 4 0 0 1 4 4v2" stroke="currentColor" strokeWidth="2" /><rect x="12" y="8" width="8" height="10" rx="1" stroke="currentColor" strokeWidth="1.5" fill="white" /><path d="M14 11h4M14 13h4M14 15h2" stroke="currentColor" strokeWidth="1" /></svg>
              </div>
              <div className="absolute -bottom-1 -right-1 bg-green-500 rounded-full p-0.5"><CheckCircle size={18} className="text-white" /></div>
            </div>
            <Button className="min-w-24" onClick={() => setShowEditSuccessModal(false)}>Oke</Button>
          </div>
        </DialogContent>
      </Dialog>

      {/* KTP Preview Modal */}
      <Dialog open={showKTPPreview} onOpenChange={setShowKTPPreview}>
        <DialogContent className="sm:max-w-2xl p-4">
          <div className="flex flex-col items-center">
            <h3 className="text-lg font-semibold mb-4">Preview KTP</h3>
            <img 
              src={ktpPlaceholder} 
              alt={`KTP ${customer.informasiKTP?.namaLengkap || customer.nama}`}
              className="w-full max-w-lg h-auto rounded-lg border-2 border-blue-200 shadow-lg"
            />
            <p className="mt-4 text-sm text-muted-foreground">
              {customer.informasiKTP?.namaLengkap || customer.nama} - NIK: {customer.informasiKTP?.nik || "-"}
            </p>
          </div>
        </DialogContent>
      </Dialog>

      {/* Block Customer Popup */}
      <BlockCustomerPopup open={showBlockConfirm} onOpenChange={setShowBlockConfirm} onConfirm={handleBlock} type="confirm" />
      <BlockCustomerPopup open={showBlockSuccess} onOpenChange={setShowBlockSuccess} onConfirm={() => {}} type="success" />
      <UnblockCustomerPopup open={showUnblockConfirm} onOpenChange={setShowUnblockConfirm} onConfirm={handleUnblock} type="confirm" />
      <UnblockCustomerPopup open={showUnblockSuccess} onOpenChange={setShowUnblockSuccess} onConfirm={() => {}} type="success" />
    </div>
  );
};

export default DetailCustomer;