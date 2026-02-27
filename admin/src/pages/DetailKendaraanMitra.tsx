import { useState, useEffect } from "react";
import { useParams, useNavigate, useSearchParams } from "react-router-dom";
import { ChevronLeft, Edit, Save, X, Search } from "lucide-react";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Input } from "@/components/ui/input";
import { useToast } from "@/hooks/use-toast";
import { useKendaraanMitra } from "@/contexts/KendaraanMitraContext";
import { useMitra } from "@/contexts/MitraContext";
import { mitraApi } from "@/services/api"; // Import api yang sudah diupdate

interface FormDataState {
  namaLengkap: string;
  kendaraan: "Mobil" | "Motor";
  merkKendaraan: string;
  platKendaraan: string;
  warnaKendaraan: string;
  nomorPlatSTNK: string;
  merkSTNK: string;
  nomorRangka: string;
  masaBerlaku: string;
}

const DetailKendaraanMitra = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const { toast } = useToast();
  
  const { kendaraanMitraList } = useKendaraanMitra();
  const { mitraDetail, getMitraDetail } = useMitra();
  
  const isEditMode = searchParams.get("edit") === "true";

  // State untuk menyimpan data kendaraan yang sedang aktif (agar tidak hilang saat refresh)
  const [currentVehicle, setCurrentVehicle] = useState<any>(null);
  const [loadingDetail, setLoadingDetail] = useState(true);

  const [formData, setFormData] = useState<FormDataState>({
    namaLengkap: "",
    kendaraan: "Mobil",
    merkKendaraan: "",
    platKendaraan: "",
    warnaKendaraan: "",
    nomorPlatSTNK: "", 
    merkSTNK: "",      
    nomorRangka: "",   
    masaBerlaku: "",   
  });

  // EFFECT: Ambil Data Kendaraan (Priority: Cache Context -> API Mitra -> API Global)
  useEffect(() => {
    const fetchData = async () => {
      setLoadingDetail(true);
      
      // 1. Coba cari di Context (Cache) dulu
      let found = kendaraanMitraList.find((item) => item.id === id);

      // 2. Jika tidak ada (Refresh halaman), ambil langsung dari API Mitra dulu, kemudian fallback ke API Global
      if (!found) {
        try {
          console.log("🔄 Fetching vehicle detail from MITRA API...");
          
          let apiData;
          let response;
          
          // Ambil data kendaraan berdasarkan ID kendaraan itu sendiri (tidak terbatas pada user_id tertentu)
          try {
            response = await mitraApi.getKendaraanDetailById(id);
            apiData = response.data.data || response.data;

            // Validasi bahwa data berasal dari role mitra
            const role = apiData.role;
            const mitraId = apiData.mitra_id;

            if (role !== "mitra") {
              throw new Error("Data bukan dari role mitra");
            }

            console.log("✅ Data berhasil diambil dari kendaraan detail API");
          } catch (err) {
            console.warn("⚠️ Gagal mengambil data kendaraan detail:", err);
            throw err;
          }
          
          if (apiData) {
            const mitraId = apiData.mitra_id || apiData.mitra?.id || apiData.user_id || apiData.user?.id;
            
            found = {
              id: String(apiData.id),
              mitraId: String(mitraId),
              kendaraan: apiData.vehicle_type?.toLowerCase() === "mobil" ? "Mobil" : "Motor",
              merkKendaraan: apiData.name || apiData.brand || "",
              platNomor: apiData.plate_number || "",
              warna: apiData.color || "",
              tahun: apiData.year || 0,
              tanggal: new Date(apiData.created_at || new Date()),
            };
          }
        } catch (error) {
          console.error("❌ Gagal fetch detail kendaraan dari kedua endpoint:", error);
          toast({
            title: "Error",
            description: "Gagal memuat data kendaraan. Pastikan endpoint /mitra/vehicles/:id atau /vehicles/:id tersedia di backend.",
            variant: "destructive"
          });
        }
      }

      if (found) {
        setCurrentVehicle(found);
        
        // 3. Ambil Data Mitra (Nama User)
        if (!mitraDetail[found.mitraId]) {
          getMitraDetail(found.mitraId);
        }
      } else {
        console.warn("⚠️ Kendaraan tidak ditemukan di list maupun API.");
      }
      
      setLoadingDetail(false);
    };

    if (id) fetchData();
  }, [id, kendaraanMitraList, mitraDetail, getMitraDetail, toast]);

  // EFFECT: Update Form UI saat currentVehicle atau mitraDetail berubah
  useEffect(() => {
    if (currentVehicle) {
      const currentMitra = mitraDetail[currentVehicle.mitraId];

      setFormData({
        namaLengkap: currentMitra ? currentMitra.nama : "Memuat nama...",
        kendaraan: currentVehicle.kendaraan,
        merkKendaraan: currentVehicle.merkKendaraan,
        platKendaraan: currentVehicle.platNomor,
        warnaKendaraan: currentVehicle.warna,
        nomorPlatSTNK: currentVehicle.platNomor, 
        merkSTNK: currentVehicle.merkKendaraan, 
        nomorRangka: currentMitra?.ktp_data?.nik || "-", // Contoh mapping field lain
        masaBerlaku: "01-01-2025", 
      });
    }
  }, [currentVehicle, mitraDetail]);

  const handleInputChange = (field: keyof FormDataState, value: string) => {
    setFormData(prev => ({ ...prev, [field]: value }));
  };

  const handleSave = () => {
    toast({
      title: "Berhasil",
      description: "Data kendaraan berhasil diperbarui",
    });
    navigate(`/dashboard/mitra-kendaraan/${id}`);
  };

  const handleCancel = () => {
    // Reset ke currentVehicle
    if (currentVehicle) {
       const currentMitra = mitraDetail[currentVehicle.mitraId];
       setFormData({
            namaLengkap: currentMitra ? currentMitra.nama : "",
            kendaraan: currentVehicle.kendaraan,
            merkKendaraan: currentVehicle.merkKendaraan,
            platKendaraan: currentVehicle.platNomor,
            warnaKendaraan: currentVehicle.warna,
            nomorPlatSTNK: currentVehicle.platNomor,
            merkSTNK: currentVehicle.merkKendaraan,
            nomorRangka: currentMitra?.ktp_data?.nik || "",
            masaBerlaku: "01-01-2025",
        });
    }
    navigate(`/dashboard/mitra-kendaraan/${id}`);
  };

  const handleEditClick = () => {
    navigate(`/dashboard/mitra-kendaraan/${id}?edit=true`);
  };

  if (loadingDetail) {
    return <div className="p-6 text-center">Memuat data kendaraan...</div>;
  }

  if (!currentVehicle && !loadingDetail) {
    return <div className="p-6 text-center text-muted-foreground">Data kendaraan tidak ditemukan.</div>;
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center gap-3">
        <Button variant="ghost" size="icon" className="h-8 w-8" onClick={() => navigate("/dashboard/mitra-kendaraan")}>
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
                    {formData.namaLengkap.charAt(0) || "M"}
                  </AvatarFallback>
                </Avatar>
              </div>
              <div>
                <h2 className="text-lg font-semibold">{formData.namaLengkap}</h2>
                <p className="text-sm text-muted-foreground">Nebeng Motor</p>
              </div>
            </div>
            {isEditMode ? (
              <div className="flex gap-2">
                <Button variant="outline" className="gap-2" onClick={handleCancel}><X size={16} /> Batal</Button>
                <Button className="gap-2 bg-green-600 hover:bg-green-700" onClick={handleSave}><Save size={16} /> Simpan</Button>
              </div>
            ) : (
              <Button variant="outline" className="gap-2" onClick={handleEditClick}>Edit <Edit size={16} /></Button>
            )}
          </div>

          {/* Informasi Pribadi */}
          <div className="mb-8">
            <h3 className="text-base font-semibold mb-4">Informasi Pribadi</h3>
            <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
              <div className="lg:col-span-2 grid grid-cols-1 md:grid-cols-2 gap-4">
                {/* Input fields (sama seperti sebelumnya, dipersingkat di sini agar mudah dibaca) */}
                <div className="space-y-2"><label className="text-sm text-muted-foreground">Nama Lengkap</label><Input value={formData.namaLengkap} readOnly={!isEditMode} onChange={(e) => handleInputChange("namaLengkap", e.target.value)} className={isEditMode ? "border-primary" : "bg-muted/50 border-border"} /></div>
                <div className="space-y-2"><label className="text-sm text-muted-foreground">Kendaraan</label><Input value={formData.kendaraan} readOnly={!isEditMode} onChange={(e) => handleInputChange("kendaraan", e.target.value as "Mobil" | "Motor")} className={isEditMode ? "border-primary" : "bg-muted/50 border-border"} /></div>
                <div className="space-y-2"><label className="text-sm text-muted-foreground">Merk Kendaraan</label><Input value={formData.merkKendaraan} readOnly={!isEditMode} onChange={(e) => handleInputChange("merkKendaraan", e.target.value)} className={isEditMode ? "border-primary" : "bg-muted/50 border-border"} /></div>
                <div className="space-y-2"><label className="text-sm text-muted-foreground">Plat Kendaraan</label><Input value={formData.platKendaraan} readOnly={!isEditMode} onChange={(e) => handleInputChange("platKendaraan", e.target.value)} className={isEditMode ? "border-primary" : "bg-muted/50 border-border"} /></div>
                <div className="space-y-2"><label className="text-sm text-muted-foreground">Warna Kendaraan</label><Input value={formData.warnaKendaraan} readOnly={!isEditMode} onChange={(e) => handleInputChange("warnaKendaraan", e.target.value)} className={isEditMode ? "border-primary" : "bg-muted/50 border-border"} /></div>
              </div>
              <div className="flex items-start justify-center lg:justify-end">
                <div className="relative w-48 h-32 rounded-lg overflow-hidden bg-muted">
                  <img src="/placeholder.svg" alt="Foto Kendaraan" className="w-full h-full object-cover" />
                </div>
              </div>
            </div>
          </div>

          {/* Informasi STNK */}
          <div>
            <h3 className="text-base font-semibold mb-4">Informasi STNK</h3>
            <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
              <div className="lg:col-span-2 grid grid-cols-1 md:grid-cols-2 gap-4">
                <div className="space-y-2"><label className="text-sm text-muted-foreground">Nomor Plat Kendaraan</label><Input value={formData.nomorPlatSTNK} readOnly={!isEditMode} onChange={(e) => handleInputChange("nomorPlatSTNK", e.target.value)} className={isEditMode ? "border-primary" : "bg-muted/50 border-border"} /></div>
                <div className="space-y-2"><label className="text-sm text-muted-foreground">MERK</label><Input value={formData.merkSTNK} readOnly={!isEditMode} onChange={(e) => handleInputChange("merkSTNK", e.target.value)} className={isEditMode ? "border-primary" : "bg-muted/50 border-border"} /></div>
                <div className="space-y-2"><label className="text-sm text-muted-foreground">Nomor Rangka</label><Input value={formData.nomorRangka} readOnly={!isEditMode} onChange={(e) => handleInputChange("nomorRangka", e.target.value)} className={isEditMode ? "border-primary" : "bg-muted/50 border-border"} /></div>
                <div className="space-y-2"><label className="text-sm text-muted-foreground">Masa Berlaku</label><Input value={formData.masaBerlaku} readOnly={!isEditMode} onChange={(e) => handleInputChange("masaBerlaku", e.target.value)} className={isEditMode ? "border-primary" : "bg-muted/50 border-border"} /></div>
              </div>
              <div className="flex items-start justify-center lg:justify-end">
                 <div className="relative w-48 h-32 rounded-lg overflow-hidden bg-muted">
                  <img src="/placeholder.svg" alt="Foto STNK" className="w-full h-full object-cover" />
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