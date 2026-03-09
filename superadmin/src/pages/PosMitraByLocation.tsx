import { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { MapPin, Users, ChevronDown, ChevronUp, Eye, Plus, Search } from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Badge } from "@/components/ui/badge";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
} from "@/components/ui/dialog";
import { locationsApi, posmitraUsersApi, posmitraApi } from "@/services/api";
import MapPicker from "@/components/MapPicker";

interface Location {
  id: number;
  name: string;
  city: string;
  address: string;
  latitude: string;
  longitude: string;
}

interface PosMitra {
  id: number;
  name: string;
  email: string;
  phone: string;
  verifikasi_nama: string;
  verifikasi_status: string;
  location_id: number;
}

const PosMitraByLocation = () => {
  const navigate = useNavigate();
  const [locations, setLocations] = useState<Location[]>([]);
  const [expandedLocation, setExpandedLocation] = useState<number | null>(null);
  const [posMitraByLocation, setPosMitraByLocation] = useState<{
    [key: number]: PosMitra[];
  }>({});
  const [isLoading, setIsLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState("");
  const [showAddPosMitraForm, setShowAddPosMitraForm] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [showAddLocationDialog, setShowAddLocationDialog] = useState(false);
  const [isSubmittingLocation, setIsSubmittingLocation] = useState(false);
  const [markerLat, setMarkerLat] = useState<number | null>(null);
  const [markerLng, setMarkerLng] = useState<number | null>(null);

  const [formData, setFormData] = useState({
    name: "",
    email: "",
    phone: "",
    location_id: "",
    verifikasi_nama: "",
    jenis_kelamin: "",
    tanggal_lahir: "",
    nik: "",
    alamat: "",
  });

  const [locationFormData, setLocationFormData] = useState({
    name: "",
    city: "",
    address: "",
    latitude: "",
    longitude: "",
  });

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    setIsLoading(true);
    try {
      // Fetch all locations
      const locationsResponse = await locationsApi.getAll();
      setLocations(locationsResponse.data);

      // Fetch all posmitra users dengan verifikasi data
      const posmitraUsersResponse = await posmitraUsersApi.getAll();
      const posmitraUsersData = posmitraUsersResponse.data;

      // Group posmitra by location_id
      const grouped: { [key: number]: PosMitra[] } = {};
      posmitraUsersData.forEach((pos: any) => {
        const locationId = pos.location_id;
        
        if (!grouped[locationId]) {
          grouped[locationId] = [];
        }

        grouped[locationId].push({
          id: pos.id,
          name: pos.name || "-",
          email: pos.email || "-",
          phone: pos.phone || "-",
          verifikasi_nama: pos.verifikasi_nama || "-",
          verifikasi_status: pos.verifikasi_status || "pending",
          location_id: locationId,
        });
      });

      setPosMitraByLocation(grouped);
    } catch (error) {
      console.error("Error loading data:", error);
    } finally {
      setIsLoading(false);
    }
  };

  const toggleLocation = (locationId: number) => {
    setExpandedLocation(expandedLocation === locationId ? null : locationId);
  };

  const getStatusBadge = (status: string) => {
    switch (status) {
      case "approved":
        return <Badge className="bg-green-500 hover:bg-green-600 text-white text-xs">Terverifikasi</Badge>;
      case "rejected":
        return <Badge className="bg-red-500 hover:bg-red-600 text-white text-xs">Ditolak</Badge>;
      case "pending":
        return <Badge className="bg-yellow-500 hover:bg-yellow-600 text-white text-xs">Menunggu</Badge>;
      default:
        return <Badge className="bg-gray-400 hover:bg-gray-500 text-white text-xs">Belum Ada</Badge>;
    }
  };

  const handleViewDetail = (posId: number) => {
    navigate(`/dashboard/pos-mitra/${posId}`);
  };

  const handleInputChange = (field: string, value: string) => {
    setFormData((prev) => ({ ...prev, [field]: value }));
  };

  const handleLocationInputChange = (field: string, value: string) => {
    setLocationFormData((prev) => ({ ...prev, [field]: value }));
  };

  const handleAddLocation = async () => {
    // Validasi form
    if (!locationFormData.name || !locationFormData.city || !locationFormData.address) {
      return;
    }

    setIsSubmittingLocation(true);
    try {
      await locationsApi.create({
        name: locationFormData.name,
        city: locationFormData.city,
        address: locationFormData.address,
        latitude: locationFormData.latitude || null,
        longitude: locationFormData.longitude || null,
      } as any);

      // Reset form
      setLocationFormData({
        name: "",
        city: "",
        address: "",
        latitude: "",
        longitude: "",
      });
      setShowAddLocationDialog(false);

      // Reload data
      loadData();
    } catch (error) {
      console.error("Error adding location:", error);
    } finally {
      setIsSubmittingLocation(false);
    }
  };

  const handleAddPosMitra = async () => {
    // Validasi form
    if (!formData.name || !formData.email || !formData.phone || !formData.location_id) {
      return;
    }

    setIsSubmitting(true);
    try {
      // Step 1: Create posmitra user di posmitra_users table
      const userResponse = await posmitraUsersApi.create({
        name: formData.name,
        email: formData.email,
        phone: formData.phone,
        location_id: parseInt(formData.location_id),
      } as any);

      const userId = userResponse.data.id;

      // Step 2: Create verifikasi KTP record di verifikasi_ktp_posmitra table
      await posmitraApi.create({
        posmitra_id: userId,
        nama_lengkap: formData.verifikasi_nama || formData.name,
        nik: formData.nik || null,
        tanggal_lahir: formData.tanggal_lahir || null,
        jenis_kelamin: formData.jenis_kelamin || null,
        alamat: formData.alamat || null,
        photo_ktp: null,
        status: "pending",
      } as any);

      // Reset form
      setFormData({
        name: "",
        email: "",
        phone: "",
        location_id: "",
        verifikasi_nama: "",
        jenis_kelamin: "",
        tanggal_lahir: "",
        nik: "",
        alamat: "",
      });
      setShowAddPosMitraForm(false);

      // Reload data
      loadData();
    } catch (error) {
      console.error("Error adding posmitra:", error);
    } finally {
      setIsSubmitting(false);
    }
  };

  if (isLoading) {
    return (
      <div className="flex items-center justify-center py-16">
        <p className="text-muted-foreground">Memuat data...</p>
      </div>
    );
  }

  const filteredLocations = locations.filter((loc) =>
    searchTerm === "" ||
    loc.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
    loc.city.toLowerCase().includes(searchTerm.toLowerCase())
  );

  return (
    <div className="space-y-6">

      {/* ── Modal: Tambah Terminal ── */}
      <Dialog open={showAddLocationDialog} onOpenChange={(open) => {
        setShowAddLocationDialog(open);
        if (!open) {
          setLocationFormData({ name: "", city: "", address: "", latitude: "", longitude: "" });
          setMarkerLat(null);
          setMarkerLng(null);
        }
      }}>
        <DialogContent className="max-w-lg">
          <DialogHeader>
            <DialogTitle className="text-lg font-semibold text-[#1e3a5f]">Tambah Lokasi Terminal Baru</DialogTitle>
          </DialogHeader>
          <div className="space-y-4 py-2">
            <div className="space-y-1.5">
              <Label className="text-sm font-medium">Nama Terminal <span className="text-red-500">*</span></Label>
              <Input placeholder="Contoh: Terminal Pusat Kota" value={locationFormData.name} onChange={(e) => handleLocationInputChange("name", e.target.value)} />
            </div>
            <div className="space-y-1.5">
              <Label className="text-sm font-medium">Kota <span className="text-red-500">*</span></Label>
              <Input placeholder="Contoh: Jakarta" value={locationFormData.city} onChange={(e) => handleLocationInputChange("city", e.target.value)} />
            </div>
            <div className="space-y-1.5">
              <Label className="text-sm font-medium">Alamat <span className="text-red-500">*</span></Label>
              <Input placeholder="Contoh: Jl. Sudirman No. 1" value={locationFormData.address} onChange={(e) => handleLocationInputChange("address", e.target.value)} />
            </div>
            <div className="grid grid-cols-2 gap-3">
              <div className="space-y-1.5">
                <Label className="text-sm font-medium">Latitude</Label>
                <Input
                  placeholder="-6.2088"
                  value={locationFormData.latitude}
                  onChange={(e) => {
                    handleLocationInputChange("latitude", e.target.value);
                    const v = parseFloat(e.target.value);
                    setMarkerLat(isNaN(v) ? null : v);
                  }}
                />
              </div>
              <div className="space-y-1.5">
                <Label className="text-sm font-medium">Longitude</Label>
                <Input
                  placeholder="106.8270"
                  value={locationFormData.longitude}
                  onChange={(e) => {
                    handleLocationInputChange("longitude", e.target.value);
                    const v = parseFloat(e.target.value);
                    setMarkerLng(isNaN(v) ? null : v);
                  }}
                />
              </div>
            </div>
            {/* Map picker */}
            <div className="space-y-1.5">
              <Label className="text-sm font-medium">Tandai Lokasi di Peta</Label>
              <p className="text-xs text-muted-foreground">Klik pada peta untuk menentukan koordinat secara visual</p>
              <MapPicker
                lat={markerLat}
                lng={markerLng}
                onChange={(lat, lng) => {
                  setMarkerLat(lat);
                  setMarkerLng(lng);
                  handleLocationInputChange("latitude", lat.toFixed(6));
                  handleLocationInputChange("longitude", lng.toFixed(6));
                }}
              />
            </div>
          </div>
          <DialogFooter className="gap-2">
            <Button variant="outline" onClick={() => setShowAddLocationDialog(false)} disabled={isSubmittingLocation}>Batal</Button>
            <Button onClick={handleAddLocation} disabled={isSubmittingLocation} className="bg-[#1e3a5f] hover:bg-[#152a45]">
              {isSubmittingLocation ? "Menyimpan..." : "Simpan Terminal"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* ── Modal: Tambah Pos Mitra ── */}
      <Dialog open={showAddPosMitraForm} onOpenChange={(open) => {
        setShowAddPosMitraForm(open);
        if (!open) setFormData({ name: "", email: "", phone: "", location_id: "", verifikasi_nama: "", jenis_kelamin: "", tanggal_lahir: "", nik: "", alamat: "" });
      }}>
        <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle className="text-lg font-semibold text-[#1e3a5f]">Tambah Pos Mitra Baru</DialogTitle>
          </DialogHeader>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4 py-2">
            <div className="space-y-1.5">
              <Label className="text-sm font-medium">Nama Lengkap <span className="text-red-500">*</span></Label>
              <Input placeholder="Masukkan nama lengkap" value={formData.name} onChange={(e) => handleInputChange("name", e.target.value)} />
            </div>
            <div className="space-y-1.5">
              <Label className="text-sm font-medium">Email <span className="text-red-500">*</span></Label>
              <Input type="email" placeholder="Masukkan email" value={formData.email} onChange={(e) => handleInputChange("email", e.target.value)} />
            </div>
            <div className="space-y-1.5">
              <Label className="text-sm font-medium">No. Telepon <span className="text-red-500">*</span></Label>
              <Input placeholder="Contoh: 08123456789" value={formData.phone} onChange={(e) => handleInputChange("phone", e.target.value)} />
            </div>
            <div className="space-y-1.5">
              <Label className="text-sm font-medium">Lokasi Terminal <span className="text-red-500">*</span></Label>
              <Select value={formData.location_id} onValueChange={(v) => handleInputChange("location_id", v)}>
                <SelectTrigger><SelectValue placeholder="Pilih terminal" /></SelectTrigger>
                <SelectContent>
                  {locations.map((loc) => (
                    <SelectItem key={loc.id} value={loc.id.toString()}>{loc.name} - {loc.city}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <div className="space-y-1.5">
              <Label className="text-sm font-medium">Nama di KTP</Label>
              <Input placeholder="Sesuai KTP (kosongkan jika sama)" value={formData.verifikasi_nama} onChange={(e) => handleInputChange("verifikasi_nama", e.target.value)} />
            </div>
            <div className="space-y-1.5">
              <Label className="text-sm font-medium">NIK</Label>
              <Input placeholder="16 digit NIK" maxLength={16} value={formData.nik} onChange={(e) => handleInputChange("nik", e.target.value)} />
            </div>
            <div className="space-y-1.5">
              <Label className="text-sm font-medium">Jenis Kelamin</Label>
              <Select value={formData.jenis_kelamin} onValueChange={(v) => handleInputChange("jenis_kelamin", v)}>
                <SelectTrigger><SelectValue placeholder="Pilih jenis kelamin" /></SelectTrigger>
                <SelectContent>
                  <SelectItem value="Laki - Laki">Laki - Laki</SelectItem>
                  <SelectItem value="Perempuan">Perempuan</SelectItem>
                </SelectContent>
              </Select>
            </div>
            <div className="space-y-1.5">
              <Label className="text-sm font-medium">Tanggal Lahir</Label>
              <Input type="date" value={formData.tanggal_lahir} onChange={(e) => handleInputChange("tanggal_lahir", e.target.value)} />
            </div>
            <div className="space-y-1.5 md:col-span-2">
              <Label className="text-sm font-medium">Alamat</Label>
              <Input placeholder="Masukkan alamat lengkap" value={formData.alamat} onChange={(e) => handleInputChange("alamat", e.target.value)} />
            </div>
          </div>
          <DialogFooter className="gap-2 mt-2">
            <Button variant="outline" onClick={() => setShowAddPosMitraForm(false)} disabled={isSubmitting}>Batal</Button>
            <Button onClick={handleAddPosMitra} disabled={isSubmitting} className="bg-[#1e3a5f] hover:bg-[#152a45]">
              {isSubmitting ? "Menyimpan..." : "Simpan Pos Mitra"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* ── Main Card ── */}
      <Card className="shadow-sm">
        <CardHeader className="pb-4">
          <CardTitle className="text-xl font-semibold">Daftar Terminal &amp; Pos Mitra</CardTitle>
        </CardHeader>
        <CardContent>
          {/* Toolbar */}
          <div className="flex items-center justify-between mb-6">
            <div className="relative w-72">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-muted-foreground" size={18} />
              <Input
                placeholder="Cari terminal atau kota..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="pl-10 h-10 bg-background border-border"
              />
            </div>
            <div className="flex items-center gap-3">
              <Button variant="outline" className="gap-2 border-[#1e3a5f] text-[#1e3a5f] hover:bg-[#1e3a5f]/5" onClick={() => setShowAddLocationDialog(true)}>
                <MapPin size={18} />
                Tambah Terminal
              </Button>
              <Button className="gap-2 bg-[#1e3a5f] hover:bg-[#152a45]" onClick={() => setShowAddPosMitraForm(true)}>
                <Plus size={18} />
                Tambah Pos Mitra
              </Button>
            </div>
          </div>

          {/* Locations accordion */}
          <div className="space-y-3">
            {filteredLocations.length === 0 ? (
              <div className="py-12 text-center text-muted-foreground">
                <MapPin size={40} className="mx-auto mb-3 text-gray-300" />
                <p>Tidak ada lokasi terminal tersedia</p>
              </div>
            ) : (
              filteredLocations.map((location) => {
                const posmitraList = posMitraByLocation[location.id] || [];
                const isExpanded = expandedLocation === location.id;

                return (
                  <div key={location.id} className="border border-border rounded-lg overflow-hidden">
                    {/* Location header row */}
                    <div
                      className="flex items-center justify-between px-5 py-4 bg-[#1e3a5f] text-white cursor-pointer hover:bg-[#172f4f] transition"
                      onClick={() => toggleLocation(location.id)}
                    >
                      <div className="flex items-center gap-3">
                        <MapPin size={18} className="text-blue-300 flex-shrink-0" />
                        <div>
                          <p className="font-semibold text-sm">{location.name}</p>
                          <p className="text-xs text-blue-200">{location.city} · {location.address}</p>
                        </div>
                      </div>
                      <div className="flex items-center gap-4">
                        <div className="flex items-center gap-1.5 bg-white/10 px-3 py-1 rounded-full text-xs">
                          <Users size={14} />
                          <span>{posmitraList.length} Pos Mitra</span>
                        </div>
                        {isExpanded ? <ChevronUp size={18} /> : <ChevronDown size={18} />}
                      </div>
                    </div>

                    {/* Expanded: inner table */}
                    {isExpanded && (
                      <div className="bg-background">
                        {posmitraList.length > 0 ? (
                          <table className="w-full text-sm">
                            <thead>
                              <tr className="bg-muted/50 border-b border-border">
                                <th className="text-left py-3 px-5 font-medium text-muted-foreground">NO</th>
                                <th className="text-left py-3 px-4 font-medium text-muted-foreground">NAMA</th>
                                <th className="text-left py-3 px-4 font-medium text-muted-foreground">EMAIL</th>
                                <th className="text-left py-3 px-4 font-medium text-muted-foreground">TELEPON</th>
                                <th className="text-center py-3 px-4 font-medium text-muted-foreground">STATUS</th>
                                <th className="text-center py-3 px-4 font-medium text-muted-foreground">AKSI</th>
                              </tr>
                            </thead>
                            <tbody>
                              {posmitraList.map((pos, index) => (
                                <tr key={pos.id} className="border-b border-border/50 hover:bg-muted/30">
                                  <td className="py-3 px-5">{index + 1}</td>
                                  <td className="py-3 px-4 font-medium text-primary">{pos.name}</td>
                                  <td className="py-3 px-4">{pos.email}</td>
                                  <td className="py-3 px-4">{pos.phone}</td>
                                  <td className="py-3 px-4 text-center">{getStatusBadge(pos.verifikasi_status)}</td>
                                  <td className="py-3 px-4">
                                    <div className="flex items-center justify-center">
                                      <Button
                                        variant="ghost"
                                        size="icon"
                                        className="h-8 w-8 bg-[#1e3a5f] hover:bg-[#152a45]"
                                        onClick={() => handleViewDetail(pos.id)}
                                        title="Lihat Detail"
                                      >
                                        <Eye size={16} className="text-white" />
                                      </Button>
                                    </div>
                                  </td>
                                </tr>
                              ))}
                            </tbody>
                          </table>
                        ) : (
                          <div className="py-8 text-center text-muted-foreground text-sm">
                            Tidak ada pos mitra di terminal ini
                          </div>
                        )}
                      </div>
                    )}
                  </div>
                );
              })
            )}
          </div>
        </CardContent>
      </Card>
    </div>
  );
};

export default PosMitraByLocation;