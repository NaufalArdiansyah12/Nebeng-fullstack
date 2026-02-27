import { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { MapPin, Users, ChevronDown, ChevronUp, Eye, Plus, X } from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
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
  DialogDescription,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog";
import { locationsApi, posmitraUsersApi, posmitraApi } from "@/services/api";

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
  const [showAddPosMitraForm, setShowAddPosMitraForm] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [showAddLocationDialog, setShowAddLocationDialog] = useState(false);
  const [isSubmittingLocation, setIsSubmittingLocation] = useState(false);

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

  const getStatusColor = (status: string) => {
    switch (status) {
      case "approved":
        return "bg-green-100 text-green-800";
      case "pending":
        return "bg-yellow-100 text-yellow-800";
      case "rejected":
        return "bg-red-100 text-red-800";
      default:
        return "bg-gray-100 text-gray-800";
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
      alert("Mohon lengkapi semua field yang required");
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

      alert("Lokasi Terminal berhasil ditambahkan!");
      
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
      alert("Gagal menambahkan lokasi terminal");
    } finally {
      setIsSubmittingLocation(false);
    }
  };

  const handleAddPosMitra = async () => {
    // Validasi form
    if (!formData.name || !formData.email || !formData.phone || !formData.location_id) {
      alert("Mohon lengkapi semua field yang required");
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

      alert("Pos Mitra berhasil ditambahkan!");
      
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
      alert("Gagal menambahkan pos mitra. Pastikan data sudah benar.");
    } finally {
      setIsSubmitting(false);
    }
  };

  if (isLoading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="text-lg text-gray-600">Loading...</div>
      </div>
    );
  }

  return (
    <div className="flex flex-col gap-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Pos Mitra by Terminal</h1>
          <p className="text-gray-500 mt-2">
            Kelola posmitra berdasarkan lokasi terminal
          </p>
        </div>
        <div className="flex gap-3">
          {/* Dialog Tambah Lokasi */}
          <Dialog open={showAddLocationDialog} onOpenChange={setShowAddLocationDialog}>
            <DialogTrigger asChild>
              <Button variant="outline" className="gap-2 border-blue-600 text-blue-600 hover:bg-blue-50">
                <Plus size={20} />
                Tambah Terminal
              </Button>
            </DialogTrigger>
            <DialogContent className="max-w-md">
              <DialogHeader>
                <DialogTitle>Tambah Lokasi Terminal Baru</DialogTitle>
                <DialogDescription>
                  Masukkan informasi lokasi terminal baru
                </DialogDescription>
              </DialogHeader>
              <div className="space-y-4">
                {/* Nama Terminal */}
                <div>
                  <Label className="text-sm font-medium text-gray-700 mb-2 block">
                    Nama Terminal *
                  </Label>
                  <Input
                    placeholder="Contoh: Terminal Pusat Kota"
                    value={locationFormData.name}
                    onChange={(e) => handleLocationInputChange("name", e.target.value)}
                    className="bg-white border-gray-300"
                  />
                </div>

                {/* Kota */}
                <div>
                  <Label className="text-sm font-medium text-gray-700 mb-2 block">
                    Kota *
                  </Label>
                  <Input
                    placeholder="Contoh: Jakarta"
                    value={locationFormData.city}
                    onChange={(e) => handleLocationInputChange("city", e.target.value)}
                    className="bg-white border-gray-300"
                  />
                </div>

                {/* Alamat */}
                <div>
                  <Label className="text-sm font-medium text-gray-700 mb-2 block">
                    Alamat *
                  </Label>
                  <Input
                    placeholder="Contoh: Jl. Sudirman No. 1"
                    value={locationFormData.address}
                    onChange={(e) => handleLocationInputChange("address", e.target.value)}
                    className="bg-white border-gray-300"
                  />
                </div>

                {/* Latitude */}
                <div>
                  <Label className="text-sm font-medium text-gray-700 mb-2 block">
                    Latitude
                  </Label>
                  <Input
                    placeholder="Contoh: -6.2088"
                    value={locationFormData.latitude}
                    onChange={(e) => handleLocationInputChange("latitude", e.target.value)}
                    className="bg-white border-gray-300"
                  />
                </div>

                {/* Longitude */}
                <div>
                  <Label className="text-sm font-medium text-gray-700 mb-2 block">
                    Longitude
                  </Label>
                  <Input
                    placeholder="Contoh: 106.8270"
                    value={locationFormData.longitude}
                    onChange={(e) => handleLocationInputChange("longitude", e.target.value)}
                    className="bg-white border-gray-300"
                  />
                </div>
              </div>

              {/* Action Buttons */}
              <div className="flex gap-3 mt-6">
                <Button
                  variant="outline"
                  onClick={() => setShowAddLocationDialog(false)}
                  className="flex-1"
                >
                  Batal
                </Button>
                <Button
                  onClick={handleAddLocation}
                  disabled={isSubmittingLocation}
                  className="flex-1 bg-blue-600 hover:bg-blue-700"
                >
                  {isSubmittingLocation ? "Menyimpan..." : "Simpan Terminal"}
                </Button>
              </div>
            </DialogContent>
          </Dialog>

          {/* Button Tambah Pos Mitra */}
          <Button
            onClick={() => setShowAddPosMitraForm(!showAddPosMitraForm)}
            className="gap-2 bg-blue-600 hover:bg-blue-700"
          >
            <Plus size={20} />
            Tambah Pos Mitra
          </Button>
        </div>
      </div>

      {/* Add Pos Mitra Form */}
      {showAddPosMitraForm && (
        <Card className="border-2 border-blue-200 bg-blue-50">
          <CardHeader className="flex flex-row items-center justify-between pb-3">
            <CardTitle>Tambah Pos Mitra Baru</CardTitle>
            <button
              onClick={() => setShowAddPosMitraForm(false)}
              className="text-gray-400 hover:text-gray-600"
            >
              <X size={24} />
            </button>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {/* Nama Lengkap */}
              <div>
                <Label className="text-sm font-medium text-gray-700 mb-2 block">
                  Nama Lengkap *
                </Label>
                <Input
                  placeholder="Masukkan nama lengkap"
                  value={formData.name}
                  onChange={(e) => handleInputChange("name", e.target.value)}
                  className="bg-white border-gray-300"
                />
              </div>

              {/* Email */}
              <div>
                <Label className="text-sm font-medium text-gray-700 mb-2 block">
                  Email *
                </Label>
                <Input
                  type="email"
                  placeholder="Masukkan email"
                  value={formData.email}
                  onChange={(e) => handleInputChange("email", e.target.value)}
                  className="bg-white border-gray-300"
                />
              </div>

              {/* No. Telepon */}
              <div>
                <Label className="text-sm font-medium text-gray-700 mb-2 block">
                  No. Telepon *
                </Label>
                <Input
                  placeholder="Masukkan nomor telepon"
                  value={formData.phone}
                  onChange={(e) => handleInputChange("phone", e.target.value)}
                  className="bg-white border-gray-300"
                />
              </div>

              {/* Lokasi Terminal */}
              <div>
                <Label className="text-sm font-medium text-gray-700 mb-2 block">
                  Lokasi Terminal *
                </Label>
                <Select value={formData.location_id} onValueChange={(value) => handleInputChange("location_id", value)}>
                  <SelectTrigger className="bg-white border-gray-300">
                    <SelectValue placeholder="Pilih terminal" />
                  </SelectTrigger>
                  <SelectContent>
                    {locations.map((loc) => (
                      <SelectItem key={loc.id} value={loc.id.toString()}>
                        {loc.name} - {loc.city}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>

              {/* Nama di KTP */}
              <div>
                <Label className="text-sm font-medium text-gray-700 mb-2 block">
                  Nama di KTP
                </Label>
                <Input
                  placeholder="Masukkan nama sesuai KTP"
                  value={formData.verifikasi_nama}
                  onChange={(e) => handleInputChange("verifikasi_nama", e.target.value)}
                  className="bg-white border-gray-300"
                />
              </div>

              {/* NIK */}
              <div>
                <Label className="text-sm font-medium text-gray-700 mb-2 block">
                  NIK
                </Label>
                <Input
                  placeholder="Masukkan NIK"
                  value={formData.nik}
                  onChange={(e) => handleInputChange("nik", e.target.value)}
                  className="bg-white border-gray-300"
                />
              </div>

              {/* Jenis Kelamin */}
              <div>
                <Label className="text-sm font-medium text-gray-700 mb-2 block">
                  Jenis Kelamin
                </Label>
                <Select value={formData.jenis_kelamin} onValueChange={(value) => handleInputChange("jenis_kelamin", value)}>
                  <SelectTrigger className="bg-white border-gray-300">
                    <SelectValue placeholder="Pilih jenis kelamin" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="Laki - Laki">Laki - Laki</SelectItem>
                    <SelectItem value="Perempuan">Perempuan</SelectItem>
                  </SelectContent>
                </Select>
              </div>

              {/* Tanggal Lahir */}
              <div>
                <Label className="text-sm font-medium text-gray-700 mb-2 block">
                  Tanggal Lahir
                </Label>
                <Input
                  type="date"
                  value={formData.tanggal_lahir}
                  onChange={(e) => handleInputChange("tanggal_lahir", e.target.value)}
                  className="bg-white border-gray-300"
                />
              </div>

              {/* Alamat */}
              <div className="md:col-span-2">
                <Label className="text-sm font-medium text-gray-700 mb-2 block">
                  Alamat
                </Label>
                <Input
                  placeholder="Masukkan alamat"
                  value={formData.alamat}
                  onChange={(e) => handleInputChange("alamat", e.target.value)}
                  className="bg-white border-gray-300"
                />
              </div>
            </div>

            {/* Action Buttons */}
            <div className="flex gap-3 mt-6">
              <Button
                variant="outline"
                onClick={() => setShowAddPosMitraForm(false)}
                className="flex-1"
              >
                Batal
              </Button>
              <Button
                onClick={handleAddPosMitra}
                disabled={isSubmitting}
                className="flex-1 bg-blue-600 hover:bg-blue-700"
              >
                {isSubmitting ? "Menyimpan..." : "Simpan Pos Mitra"}
              </Button>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Locations List */}
      <div className="space-y-4">
        {locations.map((location) => {
          const posmitraList = posMitraByLocation[location.id] || [];
          const isExpanded = expandedLocation === location.id;

          return (
            <Card key={location.id} className="overflow-hidden">
              <div
                onClick={() => toggleLocation(location.id)}
                className="cursor-pointer hover:bg-gray-50"
              >
                <CardHeader className="pb-3">
                  <div className="flex items-start justify-between">
                    <div className="flex items-start gap-4 flex-1">
                      <MapPin className="w-6 h-6 text-blue-600 mt-1 flex-shrink-0" />
                      <div className="flex-1">
                        <CardTitle className="text-lg mb-2">
                          {location.name}
                        </CardTitle>
                        <div className="grid grid-cols-1 md:grid-cols-2 gap-2 text-sm text-gray-600">
                          <div>
                            <span className="font-medium">Kota:</span> {location.city}
                          </div>
                          <div>
                            <span className="font-medium">Alamat:</span>{" "}
                            {location.address}
                          </div>
                          <div>
                            <span className="font-medium">Koordinat:</span>{" "}
                            {location.latitude}, {location.longitude}
                          </div>
                        </div>
                      </div>
                    </div>

                    <div className="flex items-center gap-4 flex-shrink-0">
                      <div className="flex items-center gap-2 bg-blue-50 px-3 py-2 rounded-lg">
                        <Users size={18} className="text-blue-600" />
                        <span className="font-bold text-blue-600">
                          {posmitraList.length}
                        </span>
                      </div>
                      <button className="text-gray-400 hover:text-gray-600 p-2">
                        {isExpanded ? (
                          <ChevronUp size={24} />
                        ) : (
                          <ChevronDown size={24} />
                        )}
                      </button>
                    </div>
                  </div>
                </CardHeader>
              </div>

              {/* Expanded Content */}
              {isExpanded && (
                <CardContent className="pt-0 border-t">
                  {posmitraList.length > 0 ? (
                    <div className="space-y-3 mt-4">
                      {posmitraList.map((pos, index) => (
                        <div
                          key={pos.id}
                          className="flex items-center justify-between p-4 bg-gray-50 rounded-lg hover:bg-gray-100 transition"
                        >
                          <div className="flex-1">
                            <div className="flex items-center gap-3">
                              <span className="text-sm font-medium text-gray-500 w-6">
                                {index + 1}.
                              </span>
                              <div className="flex-1">
                                <div className="font-medium text-gray-900">
                                  {pos.name}
                                </div>
                                <div className="text-sm text-gray-600">
                                  {pos.email}
                                </div>
                                <div className="text-sm text-gray-500">
                                  {pos.phone}
                                </div>
                              </div>
                            </div>
                          </div>

                          <div className="flex items-center gap-3">
                            <span
                              className={`px-3 py-1 rounded-full text-xs font-medium ${getStatusColor(
                                pos.verifikasi_status
                              )}`}
                            >
                              {pos.verifikasi_status}
                            </span>
                            <Button
                              variant="outline"
                              size="sm"
                              onClick={() => handleViewDetail(pos.id)}
                              className="gap-2"
                            >
                              <Eye size={16} />
                              Detail
                            </Button>
                          </div>
                        </div>
                      ))}
                    </div>
                  ) : (
                    <div className="py-8 text-center text-gray-500">
                      <p>Tidak ada posmitra di lokasi ini</p>
                    </div>
                  )}
                </CardContent>
              )}
            </Card>
          );
        })}
      </div>

      {/* Empty State */}
      {locations.length === 0 && (
        <Card>
          <CardContent className="py-12 text-center text-gray-500">
            <MapPin size={48} className="mx-auto mb-4 text-gray-400" />
            <p>Tidak ada lokasi terminal tersedia</p>
          </CardContent>
        </Card>
      )}
    </div>
  );
};

export default PosMitraByLocation;