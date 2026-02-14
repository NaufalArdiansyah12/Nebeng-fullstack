import { useState } from "react";
import { useParams, useNavigate, useSearchParams } from "react-router-dom";
import { ChevronLeft, Edit, Save, X, Search } from "lucide-react";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Input } from "@/components/ui/input";
import { useToast } from "@/hooks/use-toast";

// Sample data for the detail view
const kendaraanDetail = {
  id: "K001",
  namaMitra: "Muhammad Abdul",
  namaLengkap: "Muhammad Abdul Kadir",
  kendaraan: "Mobil",
  merkKendaraan: "Toyota",
  platKendaraan: "B 82929 MH",
  warnaKendaraan: "Putih",
  fotoKendaraan: "/placeholder.svg",
  // STNK Info
  nomorPlatSTNK: "B 9090 AM",
  merkSTNK: "SKYLINE GT-R",
  nomorRangka: "MH1JK3210XX12345",
  masaBerlaku: "01-02-1999",
  fotoSTNK: "/placeholder.svg",
};

const DetailKendaraanMitra = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const { toast } = useToast();
  
  const isEditMode = searchParams.get("edit") === "true";

  // Form state
  const [formData, setFormData] = useState({
    namaLengkap: kendaraanDetail.namaLengkap,
    kendaraan: kendaraanDetail.kendaraan,
    merkKendaraan: kendaraanDetail.merkKendaraan,
    platKendaraan: kendaraanDetail.platKendaraan,
    warnaKendaraan: kendaraanDetail.warnaKendaraan,
    nomorPlatSTNK: kendaraanDetail.nomorPlatSTNK,
    merkSTNK: kendaraanDetail.merkSTNK,
    nomorRangka: kendaraanDetail.nomorRangka,
    masaBerlaku: kendaraanDetail.masaBerlaku,
  });

  const handleInputChange = (field: string, value: string) => {
    setFormData(prev => ({ ...prev, [field]: value }));
  };

  const handleSave = () => {
    // In real app, save to backend
    toast({
      title: "Berhasil",
      description: "Data kendaraan berhasil diperbarui",
    });
    navigate(`/dashboard/mitra-kendaraan/${id}`);
  };

  const handleCancel = () => {
    // Reset form data
    setFormData({
      namaLengkap: kendaraanDetail.namaLengkap,
      kendaraan: kendaraanDetail.kendaraan,
      merkKendaraan: kendaraanDetail.merkKendaraan,
      platKendaraan: kendaraanDetail.platKendaraan,
      warnaKendaraan: kendaraanDetail.warnaKendaraan,
      nomorPlatSTNK: kendaraanDetail.nomorPlatSTNK,
      merkSTNK: kendaraanDetail.merkSTNK,
      nomorRangka: kendaraanDetail.nomorRangka,
      masaBerlaku: kendaraanDetail.masaBerlaku,
    });
    navigate(`/dashboard/mitra-kendaraan/${id}`);
  };

  const handleEditClick = () => {
    navigate(`/dashboard/mitra-kendaraan/${id}?edit=true`);
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center gap-3">
        <Button
          variant="ghost"
          size="icon"
          className="h-8 w-8"
          onClick={() => navigate("/dashboard/mitra-kendaraan")}
        >
          <ChevronLeft size={20} />
        </Button>
        <h1 className="text-xl font-semibold">
          {isEditMode ? "Edit Data Kendaraan" : "Detail Data Mitra"}
        </h1>
      </div>

      <Card className="shadow-sm">
        <CardContent className="p-6">
          {/* Profile Header */}
          <div className="flex items-center justify-between mb-8">
            <div className="flex items-center gap-4">
              <div className="relative">
                <Avatar className="h-16 w-16">
                  <AvatarImage src="/placeholder.svg" />
                  <AvatarFallback className="bg-orange-100 text-orange-600 text-lg">
                    {kendaraanDetail.namaMitra.charAt(0)}
                  </AvatarFallback>
                </Avatar>
                <div className="absolute -bottom-1 -right-1 bg-primary rounded-full p-1">
                  <svg viewBox="0 0 24 24" className="w-3 h-3 text-white" fill="currentColor">
                    <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/>
                  </svg>
                </div>
              </div>
              <div>
                <h2 className="text-lg font-semibold">{kendaraanDetail.namaMitra}</h2>
                <p className="text-sm text-muted-foreground">Nebeng Motor</p>
              </div>
            </div>
            {isEditMode ? (
              <div className="flex gap-2">
                <Button variant="outline" className="gap-2" onClick={handleCancel}>
                  <X size={16} /> Batal
                </Button>
                <Button className="gap-2 bg-green-600 hover:bg-green-700" onClick={handleSave}>
                  <Save size={16} /> Simpan
                </Button>
              </div>
            ) : (
              <Button variant="outline" className="gap-2" onClick={handleEditClick}>
                Edit <Edit size={16} />
              </Button>
            )}
          </div>

          {/* Informasi Pribadi */}
          <div className="mb-8">
            <h3 className="text-base font-semibold mb-4">Informasi Pribadi</h3>
            <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
              <div className="lg:col-span-2 grid grid-cols-1 md:grid-cols-2 gap-4">
                <div className="space-y-2">
                  <label className="text-sm text-muted-foreground">Nama Lengkap</label>
                  <Input 
                    value={formData.namaLengkap} 
                    readOnly={!isEditMode}
                    onChange={(e) => handleInputChange("namaLengkap", e.target.value)}
                    className={isEditMode ? "border-primary" : "bg-muted/50 border-border"}
                  />
                </div>
                <div className="space-y-2">
                  <label className="text-sm text-muted-foreground">Kendaraan</label>
                  <Input 
                    value={formData.kendaraan} 
                    readOnly={!isEditMode}
                    onChange={(e) => handleInputChange("kendaraan", e.target.value)}
                    className={isEditMode ? "border-primary" : "bg-muted/50 border-border"}
                  />
                </div>
                <div className="space-y-2">
                  <label className="text-sm text-muted-foreground">Merk Kendaraan</label>
                  <Input 
                    value={formData.merkKendaraan} 
                    readOnly={!isEditMode}
                    onChange={(e) => handleInputChange("merkKendaraan", e.target.value)}
                    className={isEditMode ? "border-primary" : "bg-muted/50 border-border"}
                  />
                </div>
                <div className="space-y-2">
                  <label className="text-sm text-muted-foreground">Plat Kendaraan</label>
                  <Input 
                    value={formData.platKendaraan} 
                    readOnly={!isEditMode}
                    onChange={(e) => handleInputChange("platKendaraan", e.target.value)}
                    className={isEditMode ? "border-primary" : "bg-muted/50 border-border"}
                  />
                </div>
                <div className="space-y-2">
                  <label className="text-sm text-muted-foreground">Warna Kendaraan</label>
                  <Input 
                    value={formData.warnaKendaraan} 
                    readOnly={!isEditMode}
                    onChange={(e) => handleInputChange("warnaKendaraan", e.target.value)}
                    className={isEditMode ? "border-primary" : "bg-muted/50 border-border"}
                  />
                </div>
              </div>
              <div className="flex items-start justify-center lg:justify-end">
                <div className="relative w-48 h-32 rounded-lg overflow-hidden bg-muted">
                  <img 
                    src={kendaraanDetail.fotoKendaraan} 
                    alt="Foto Kendaraan" 
                    className="w-full h-full object-cover"
                  />
                  <Button
                    variant="ghost"
                    size="icon"
                    className="absolute bottom-2 right-2 h-8 w-8 bg-primary/80 hover:bg-primary"
                  >
                    <Search size={16} className="text-white" />
                  </Button>
                </div>
              </div>
            </div>
          </div>

          {/* Informasi STNK */}
          <div>
            <h3 className="text-base font-semibold mb-4">Informasi STNK</h3>
            <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
              <div className="lg:col-span-2 grid grid-cols-1 md:grid-cols-2 gap-4">
                <div className="space-y-2">
                  <label className="text-sm text-muted-foreground">Nomor Plat Kendaraan</label>
                  <Input 
                    value={formData.nomorPlatSTNK} 
                    readOnly={!isEditMode}
                    onChange={(e) => handleInputChange("nomorPlatSTNK", e.target.value)}
                    className={isEditMode ? "border-primary" : "bg-muted/50 border-border"}
                  />
                </div>
                <div className="space-y-2">
                  <label className="text-sm text-muted-foreground">MERK</label>
                  <Input 
                    value={formData.merkSTNK} 
                    readOnly={!isEditMode}
                    onChange={(e) => handleInputChange("merkSTNK", e.target.value)}
                    className={isEditMode ? "border-primary" : "bg-muted/50 border-border"}
                  />
                </div>
                <div className="space-y-2">
                  <label className="text-sm text-muted-foreground">Nomor Rangka</label>
                  <Input 
                    value={formData.nomorRangka} 
                    readOnly={!isEditMode}
                    onChange={(e) => handleInputChange("nomorRangka", e.target.value)}
                    className={isEditMode ? "border-primary" : "bg-muted/50 border-border"}
                  />
                </div>
                <div className="space-y-2">
                  <label className="text-sm text-muted-foreground">Masa Berlaku</label>
                  <div className="relative">
                    <Input 
                      value={formData.masaBerlaku} 
                      readOnly={!isEditMode}
                      onChange={(e) => handleInputChange("masaBerlaku", e.target.value)}
                      className={`pr-10 ${isEditMode ? "border-primary" : "bg-muted/50 border-border"}`}
                    />
                    <svg 
                      viewBox="0 0 24 24" 
                      className="absolute right-3 top-1/2 -translate-y-1/2 w-5 h-5 text-muted-foreground" 
                      fill="none" 
                      stroke="currentColor" 
                      strokeWidth="2"
                    >
                      <rect x="3" y="4" width="18" height="18" rx="2" ry="2"/>
                      <line x1="16" y1="2" x2="16" y2="6"/>
                      <line x1="8" y1="2" x2="8" y2="6"/>
                      <line x1="3" y1="10" x2="21" y2="10"/>
                    </svg>
                  </div>
                </div>
              </div>
              <div className="flex items-start justify-center lg:justify-end">
                <div className="relative w-48 h-32 rounded-lg overflow-hidden bg-muted">
                  <img 
                    src={kendaraanDetail.fotoSTNK} 
                    alt="Foto STNK" 
                    className="w-full h-full object-cover"
                  />
                  <Button
                    variant="ghost"
                    size="icon"
                    className="absolute bottom-2 right-2 h-8 w-8 bg-primary/80 hover:bg-primary"
                  >
                    <Search size={16} className="text-white" />
                  </Button>
                </div>
              </div>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
};

export default DetailKendaraanMitra;
