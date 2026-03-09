import { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { Search, Eye, Trash2, Plus, Download } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
} from "@/components/ui/dialog";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { posmitraUsersApi, posmitraApi, locationsApi } from "@/services/api";
import * as XLSX from "xlsx";
import { format } from "date-fns";

const getStatusBadge = (item: any) => {
  if (!item.verifikasi_id) {
    return <Badge className="bg-gray-400 hover:bg-gray-500 text-white text-xs">Belum Ada</Badge>;
  }
  switch (item.verifikasi_status) {
    case "approved":
      return <Badge className="bg-green-500 hover:bg-green-600 text-white text-xs">Terverifikasi</Badge>;
    case "rejected":
      return <Badge className="bg-red-500 hover:bg-red-600 text-white text-xs">Ditolak</Badge>;
    default:
      return <Badge className="bg-yellow-500 hover:bg-yellow-600 text-white text-xs">Menunggu</Badge>;
  }
};

const PosMitra = () => {
  const navigate = useNavigate();
  const [posMitraList, setPosMitraList] = useState<any[]>([]);
  const [locations, setLocations] = useState<any[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState("");
  const [currentPage, setCurrentPage] = useState(1);
  const [entriesPerPage, setEntriesPerPage] = useState("10");
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

  const itemsPerPage = parseInt(entriesPerPage) || 10;
  const totalEntries = filteredData.length;
  const totalPages = Math.ceil(totalEntries / itemsPerPage) || 1;
  const paginatedData = filteredData.slice(
    (currentPage - 1) * itemsPerPage,
    currentPage * itemsPerPage
  );

  const handleViewDetail = (posMitra: any) => {
    navigate(`/dashboard/pos-mitra/${posMitra.id}`);
  };

  const handleDelete = async (posMitra: any) => {
    if (!window.confirm(`Hapus akun "${posMitra.name}"?`)) return;
    try {
      await posmitraUsersApi.delete(posMitra.id);
      loadData();
    } catch (error) {
      console.error("Error deleting posmitra:", error);
    }
  };

  const handleDownload = () => {
    if (filteredData.length === 0) return;
    const data = filteredData.map((item, i) => ({
      "NO": i + 1,
      "NAMA": item.name || "-",
      "EMAIL": item.email || "-",
      "TELEPON": item.phone || "-",
      "STATUS VERIFIKASI": item.verifikasi_id
        ? item.verifikasi_status === "approved"
          ? "Terverifikasi"
          : item.verifikasi_status === "rejected"
          ? "Ditolak"
          : "Menunggu"
        : "Belum Ada",
    }));
    const ws = XLSX.utils.json_to_sheet(data);
    ws["!cols"] = [{ wch: 6 }, { wch: 25 }, { wch: 30 }, { wch: 16 }, { wch: 20 }];
    const wb = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(wb, ws, "Daftar Pos Mitra");
    XLSX.writeFile(wb, `pos-mitra-${format(new Date(), "yyyy-MM-dd")}.xlsx`);
  };

  const getPageNumbers = () => {
    const pages: (number | string)[] = [];
    if (totalPages <= 5) {
      for (let i = 1; i <= totalPages; i++) pages.push(i);
    } else if (currentPage <= 3) {
      pages.push(1, 2, 3, "...", totalPages);
    } else if (currentPage >= totalPages - 2) {
      pages.push(1, "...", totalPages - 2, totalPages - 1, totalPages);
    } else {
      pages.push(1, "...", currentPage, "...", totalPages);
    }
    return pages;
  };

  const handleInputChange = (field: string, value: string) => {
    setFormData((prev) => ({ ...prev, [field]: value }));
  };

  const handleAddPosMitra = async () => {
    // Validasi form
    if (!formData.name || !formData.email || !formData.phone || !formData.location_id) {
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
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="space-y-6">
      {/* Modal: Tambah Pos Mitra */}
      <Dialog open={showAddForm} onOpenChange={(open) => { setShowAddForm(open); if (!open) setFormData({ name: "", email: "", phone: "", location_id: "", verifikasi_nama: "", jenis_kelamin: "", tanggal_lahir: "", nik: "", alamat: "" }); }}>
        <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle className="text-lg font-semibold text-[#1e3a5f]">Tambah Pos Mitra Baru</DialogTitle>
          </DialogHeader>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4 py-2">
            {/* Nama Lengkap */}
            <div className="space-y-1.5">
              <Label className="text-sm font-medium">Nama Lengkap <span className="text-red-500">*</span></Label>
              <Input
                placeholder="Masukkan nama lengkap"
                value={formData.name}
                onChange={(e) => handleInputChange("name", e.target.value)}
              />
            </div>

            {/* Email */}
            <div className="space-y-1.5">
              <Label className="text-sm font-medium">Email <span className="text-red-500">*</span></Label>
              <Input
                type="email"
                placeholder="Masukkan email"
                value={formData.email}
                onChange={(e) => handleInputChange("email", e.target.value)}
              />
            </div>

            {/* No. Telepon */}
            <div className="space-y-1.5">
              <Label className="text-sm font-medium">No. Telepon <span className="text-red-500">*</span></Label>
              <Input
                placeholder="Contoh: 08123456789"
                value={formData.phone}
                onChange={(e) => handleInputChange("phone", e.target.value)}
              />
            </div>

            {/* Lokasi Terminal */}
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

            {/* Nama di KTP */}
            <div className="space-y-1.5">
              <Label className="text-sm font-medium">Nama di KTP</Label>
              <Input
                placeholder="Sesuai KTP (kosongkan jika sama)"
                value={formData.verifikasi_nama}
                onChange={(e) => handleInputChange("verifikasi_nama", e.target.value)}
              />
            </div>

            {/* NIK */}
            <div className="space-y-1.5">
              <Label className="text-sm font-medium">NIK</Label>
              <Input
                placeholder="16 digit NIK"
                maxLength={16}
                value={formData.nik}
                onChange={(e) => handleInputChange("nik", e.target.value)}
              />
            </div>

            {/* Jenis Kelamin */}
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

            {/* Tanggal Lahir */}
            <div className="space-y-1.5">
              <Label className="text-sm font-medium">Tanggal Lahir</Label>
              <Input
                type="date"
                value={formData.tanggal_lahir}
                onChange={(e) => handleInputChange("tanggal_lahir", e.target.value)}
              />
            </div>

            {/* Alamat */}
            <div className="space-y-1.5 md:col-span-2">
              <Label className="text-sm font-medium">Alamat</Label>
              <Input
                placeholder="Masukkan alamat lengkap"
                value={formData.alamat}
                onChange={(e) => handleInputChange("alamat", e.target.value)}
              />
            </div>
          </div>

          <DialogFooter className="gap-2 mt-2">
            <Button variant="outline" onClick={() => setShowAddForm(false)} disabled={isSubmitting}>
              Batal
            </Button>
            <Button onClick={handleAddPosMitra} disabled={isSubmitting} className="bg-[#1e3a5f] hover:bg-[#152a45]">
              {isSubmitting ? "Menyimpan..." : "Simpan Pos Mitra"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Main Table Card */}
      <Card className="shadow-sm">
        <CardHeader className="pb-4">
          <CardTitle className="text-xl font-semibold">Daftar Akun Pos Mitra</CardTitle>
        </CardHeader>
        <CardContent>
          {/* Filters */}
          <div className="flex items-center justify-between mb-6">
            <div className="relative w-72">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-muted-foreground" size={18} />
              <Input
                placeholder="Cari nama, email, atau telepon..."
                value={searchTerm}
                onChange={(e) => { setSearchTerm(e.target.value); setCurrentPage(1); }}
                className="pl-10 h-10 bg-background border-border"
              />
            </div>
            <div className="flex items-center gap-3">
              <Button className="gap-2 bg-primary hover:bg-primary/90" onClick={handleDownload} disabled={filteredData.length === 0}>
                <Download size={18} />
                Download
              </Button>
              <Button className="gap-2 bg-[#1e3a5f] hover:bg-[#152a45]" onClick={() => setShowAddForm(true)}>
                <Plus size={18} />
                Tambah Pos Mitra
              </Button>
            </div>
          </div>

          {/* Table */}
          <div className="overflow-x-auto">
            {isLoading ? (
              <div className="flex items-center justify-center py-12">
                <p className="text-muted-foreground">Memuat data...</p>
              </div>
            ) : (
              <table className="w-full text-sm">
                <thead>
                  <tr className="bg-[#1e3a5f] text-white">
                    <th className="text-left py-3 px-4 font-medium rounded-tl-lg">NO</th>
                    <th className="text-left py-3 px-4 font-medium">NAMA</th>
                    <th className="text-left py-3 px-4 font-medium">EMAIL</th>
                    <th className="text-left py-3 px-4 font-medium">TELEPON</th>
                    <th className="text-center py-3 px-4 font-medium">STATUS VERIFIKASI</th>
                    <th className="text-center py-3 px-4 font-medium rounded-tr-lg">AKSI</th>
                  </tr>
                </thead>
                <tbody>
                  {paginatedData.length > 0 ? (
                    paginatedData.map((item, index) => (
                      <tr key={item.id} className="border-b border-border/50 hover:bg-muted/30">
                        <td className="py-4 px-4">{(currentPage - 1) * itemsPerPage + index + 1}</td>
                        <td className="py-4 px-4 font-medium text-primary">{item.name || "-"}</td>
                        <td className="py-4 px-4">{item.email || "-"}</td>
                        <td className="py-4 px-4">{item.phone || "-"}</td>
                        <td className="py-4 px-4 text-center">{getStatusBadge(item)}</td>
                        <td className="py-4 px-4">
                          <div className="flex items-center justify-center gap-2">
                            <Button
                              variant="ghost"
                              size="icon"
                              className="h-8 w-8 bg-[#1e3a5f] hover:bg-[#152a45]"
                              onClick={() => handleViewDetail(item)}
                              title="Lihat Detail"
                            >
                              <Eye size={18} className="text-white" />
                            </Button>
                            <Button
                              variant="ghost"
                              size="icon"
                              className="h-8 w-8 bg-red-500 hover:bg-red-600"
                              onClick={() => handleDelete(item)}
                              title="Hapus"
                            >
                              <Trash2 size={18} className="text-white" />
                            </Button>
                          </div>
                        </td>
                      </tr>
                    ))
                  ) : (
                    <tr>
                      <td colSpan={6} className="py-8 text-center text-muted-foreground">
                        {posMitraList.length === 0 ? "Belum ada data pos mitra" : "Tidak ada data yang sesuai pencarian"}
                      </td>
                    </tr>
                  )}
                </tbody>
              </table>
            )}
          </div>

          {/* Pagination */}
          {!isLoading && (
            <div className="flex items-center justify-between mt-6">
              <div className="flex items-center gap-2 text-sm text-muted-foreground">
                <Select value={entriesPerPage} onValueChange={(v) => { setEntriesPerPage(v); setCurrentPage(1); }}>
                  <SelectTrigger className="w-16 h-8"><SelectValue /></SelectTrigger>
                  <SelectContent>
                    <SelectItem value="10">10</SelectItem>
                    <SelectItem value="25">25</SelectItem>
                    <SelectItem value="50">50</SelectItem>
                  </SelectContent>
                </Select>
                <span>of {totalEntries} entries</span>
              </div>
              <div className="flex items-center gap-1">
                <Button variant="ghost" size="icon" className="h-8 w-8" disabled={currentPage === 1} onClick={() => setCurrentPage(currentPage - 1)}>&lt;</Button>
                {getPageNumbers().map((page, idx) =>
                  typeof page === "number" ? (
                    <Button key={idx} variant={currentPage === page ? "default" : "ghost"} size="icon" className={`h-8 w-8 ${currentPage === page ? "bg-primary text-white" : ""}`} onClick={() => setCurrentPage(page)}>{page}</Button>
                  ) : (
                    <span key={idx} className="px-2 text-muted-foreground">{page}</span>
                  )
                )}
                <Button variant="ghost" size="icon" className="h-8 w-8" disabled={currentPage === totalPages || totalPages === 0} onClick={() => setCurrentPage(currentPage + 1)}>&gt;</Button>
              </div>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
};

export default PosMitra;