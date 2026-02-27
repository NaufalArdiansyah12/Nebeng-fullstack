import { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { Search, Eye, Trash2, Plus, X } from "lucide-react";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { posmitraUsersApi, posmitraApi, locationsApi } from "@/services/api";

const PosMitra = () => {
  const navigate = useNavigate();
  const [posMitraList, setPosMitraList] = useState<any[]>([]);
  const [locations, setLocations] = useState<any[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState("");
  const [currentPage, setCurrentPage] = useState(1);
  const [itemsPerPage] = useState(10);
  const [showAddForm, setShowAddForm] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);

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

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    setIsLoading(true);
    try {
      // Fetch posmitra users
      const posmitraResponse = await posmitraUsersApi.getAll();
      setPosMitraList(posmitraResponse.data || []);

      // Fetch locations for dropdown
      const locationsResponse = await locationsApi.getAll();
      setLocations(locationsResponse.data || []);
    } catch (error) {
      console.error("Error loading data:", error);
    } finally {
      setIsLoading(false);
    }
  };

  const filteredData = posMitraList.filter(
    (item) =>
      item.name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      item.email?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      item.phone?.toLowerCase().includes(searchTerm.toLowerCase())
  );

  const paginatedData = filteredData.slice(
    (currentPage - 1) * itemsPerPage,
    currentPage * itemsPerPage
  );

  const totalPages = Math.ceil(filteredData.length / itemsPerPage);

  const handleViewDetail = (posMitra: any) => {
    navigate(`/dashboard/pos-mitra/${posMitra.id}`);
  };

  const handleDelete = async (posMitra: any) => {
    if (window.confirm(`Apakah Anda yakin ingin menghapus akun "${posMitra.name}"?`)) {
      try {
        // Delete posmitra user
        await posmitraUsersApi.delete(posMitra.id);
        alert("Pos Mitra berhasil dihapus");
        loadData();
      } catch (error) {
        console.error("Error deleting posmitra:", error);
        alert("Gagal menghapus pos mitra");
      }
    }
  };

  const handleInputChange = (field: string, value: string) => {
    setFormData((prev) => ({ ...prev, [field]: value }));
  };

  const handleAddPosMitra = async () => {
    // Validasi form
    if (!formData.name || !formData.email || !formData.phone || !formData.location_id) {
      alert("Mohon lengkapi semua field yang required");
      return;
    }

    setIsSubmitting(true);
    try {
      // Step 1: Create posmitra user
      const userResponse = await posmitraUsersApi.create({
        name: formData.name,
        email: formData.email,
        phone: formData.phone,
        location_id: parseInt(formData.location_id),
      } as any);

      const userId = userResponse.data.id;

      // Step 2: Create verifikasi KTP record
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
      setShowAddForm(false);

      // Reload data
      loadData();
    } catch (error) {
      console.error("Error adding posmitra:", error);
      alert("Gagal menambahkan pos mitra");
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="flex flex-col gap-4">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Pos Mitra</h1>
          <p className="text-gray-500 mt-2">
            Kelola dan pantau semua akun pos mitra Anda
          </p>
        </div>
        <Button
          onClick={() => setShowAddForm(!showAddForm)}
          className="gap-2 bg-blue-600 hover:bg-blue-700"
        >
          <Plus size={20} />
          Tambah Pos Mitra
        </Button>
      </div>

      {/* Add Form */}
      {showAddForm && (
        <Card className="border-2 border-blue-200 bg-blue-50">
          <CardHeader className="flex flex-row items-center justify-between pb-3">
            <CardTitle>Tambah Pos Mitra Baru</CardTitle>
            <button
              onClick={() => setShowAddForm(false)}
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
                <Select
                  value={formData.location_id}
                  onValueChange={(value) => handleInputChange("location_id", value)}
                >
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
                <Select
                  value={formData.jenis_kelamin}
                  onValueChange={(value) => handleInputChange("jenis_kelamin", value)}
                >
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
                onClick={() => setShowAddForm(false)}
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

      {/* Search and Filters */}
      <Card>
        <CardHeader>
          <CardTitle>Daftar Akun Pos Mitra</CardTitle>
        </CardHeader>
        <CardContent className="flex flex-col gap-4">
          <div className="relative">
            <Search className="absolute left-3 top-3 text-gray-400" size={20} />
            <Input
              placeholder="Cari berdasarkan nama, email, atau telepon..."
              value={searchTerm}
              onChange={(e) => {
                setSearchTerm(e.target.value);
                setCurrentPage(1);
              }}
              className="pl-10"
            />
          </div>

          {isLoading ? (
            <div className="flex items-center justify-center py-8">
              <p className="text-gray-500">Memuat data...</p>
            </div>
          ) : posMitraList.length === 0 ? (
            <div className="flex items-center justify-center py-8">
              <p className="text-gray-500">Belum ada data pos mitra</p>
            </div>
          ) : (
            <>
              {/* Table */}
              <div className="border rounded-lg overflow-hidden">
                <Table>
                  <TableHeader>
                    <TableRow className="bg-gray-50">
                      <TableHead className="w-12">NO</TableHead>
                      <TableHead>NAMA</TableHead>
                      <TableHead>EMAIL</TableHead>
                      <TableHead>TELEPON</TableHead>
                      <TableHead>STATUS VERIFIKASI</TableHead>
                      <TableHead className="w-32 text-center">AKSI</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {paginatedData.map((item, index) => (
                      <TableRow key={item.id} className="hover:bg-gray-50">
                        <TableCell className="font-medium">
                          {(currentPage - 1) * itemsPerPage + index + 1}
                        </TableCell>
                        <TableCell className="font-medium">{item.name}</TableCell>
                        <TableCell>{item.email}</TableCell>
                        <TableCell>{item.phone || "-"}</TableCell>
                        <TableCell>
                          {item.verifikasi_id ? (
                            <span
                              className={`px-3 py-1 rounded-full text-xs font-semibold ${
                                item.verifikasi_status === "approved"
                                  ? "bg-green-100 text-green-800"
                                  : item.verifikasi_status === "rejected"
                                  ? "bg-red-100 text-red-800"
                                  : "bg-yellow-100 text-yellow-800"
                              }`}
                            >
                              {item.verifikasi_status === "approved"
                                ? "Terverifikasi"
                                : item.verifikasi_status === "rejected"
                                ? "Ditolak"
                                : "Menunggu Verifikasi"}
                            </span>
                          ) : (
                            <span className="px-3 py-1 rounded-full text-xs font-semibold bg-gray-100 text-gray-800">
                              Belum Ada
                            </span>
                          )}
                        </TableCell>
                        <TableCell>
                          <div className="flex items-center justify-center gap-2">
                            <Button
                              variant="ghost"
                              size="sm"
                              onClick={() => handleViewDetail(item)}
                              title="Lihat Detail"
                            >
                              <Eye size={18} />
                            </Button>
                            <Button
                              variant="ghost"
                              size="sm"
                              className="text-red-600 hover:text-red-700 hover:bg-red-50"
                              onClick={() => handleDelete(item)}
                              title="Hapus"
                            >
                              <Trash2 size={18} />
                            </Button>
                          </div>
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </div>

              {/* Pagination */}
              <div className="flex items-center justify-between">
                <div className="text-sm text-gray-600">
                  Menampilkan{" "}
                  {Math.min((currentPage - 1) * itemsPerPage + 1, filteredData.length)}{" "}
                  sampai{" "}
                  {Math.min(currentPage * itemsPerPage, filteredData.length)} dari{" "}
                  {filteredData.length} entri
                </div>
                <div className="flex items-center gap-2">
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={() => setCurrentPage((prev) => Math.max(1, prev - 1))}
                    disabled={currentPage === 1}
                  >
                    Sebelumnya
                  </Button>

                  {Array.from({ length: totalPages }, (_, i) => i + 1).map(
                    (page) => (
                      <Button
                        key={page}
                        variant={currentPage === page ? "default" : "outline"}
                        size="sm"
                        onClick={() => setCurrentPage(page)}
                      >
                        {page}
                      </Button>
                    )
                  )}

                  <Button
                    variant="outline"
                    size="sm"
                    onClick={() =>
                      setCurrentPage((prev) => Math.min(totalPages, prev + 1))
                    }
                    disabled={currentPage === totalPages}
                  >
                    Selanjutnya
                  </Button>
                </div>
              </div>
            </>
          )}
        </CardContent>
      </Card>
    </div>
  );
};

export default PosMitra;