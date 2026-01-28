import { useState, useMemo } from "react";
import { useNavigate } from "react-router-dom";
import { Search, Calendar as CalendarIcon, Download, Eye, Lock, LockOpen } from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Calendar } from "@/components/ui/calendar";
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover";
import { format } from "date-fns";
import { id as localeId } from "date-fns/locale";
import { cn } from "@/lib/utils";
import * as XLSX from "xlsx";
import BlockMitraPopup from "@/components/BlockMitraPopup";
import UnblockMitraPopup from "@/components/UnblockMitraPopup";
import { useMitra } from "@/contexts/MitraContext";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";

const getStatusBadge = (status: string) => {
  switch (status) {
    case "PENGAJUAN":
      return <Badge className="bg-orange-500 hover:bg-orange-600 text-white text-xs">PENGAJUAN</Badge>;
    case "TERVERIFIKASI":
      return <Badge className="bg-green-500 hover:bg-green-600 text-white text-xs">TERVERIFIKASI</Badge>;
    case "DITOLAK":
      return <Badge className="bg-red-500 hover:bg-red-600 text-white text-xs">DITOLAK</Badge>;
    case "DIBLOCK":
      return <Badge className="bg-gray-500 hover:bg-gray-600 text-white text-xs">DIBLOCK</Badge>;
    default:
      return <Badge className="bg-gray-500 text-white text-xs">{status}</Badge>;
  }
};

const DaftarMitra = () => {
  const navigate = useNavigate();
  const { mitraList, blockMitra, unblockMitra } = useMitra();
  const [searchQuery, setSearchQuery] = useState("");
  const [currentPage, setCurrentPage] = useState(1);
  const [entriesPerPage, setEntriesPerPage] = useState("10");
  const [selectedDate, setSelectedDate] = useState<Date | undefined>(undefined);
  const [statusFilter, setStatusFilter] = useState<string>("AKTIF");
  const [blockPopupOpen, setBlockPopupOpen] = useState(false);
  const [blockSuccessOpen, setBlockSuccessOpen] = useState(false);
  const [unblockPopupOpen, setUnblockPopupOpen] = useState(false);
  const [unblockSuccessOpen, setUnblockSuccessOpen] = useState(false);
  const [selectedMitraId, setSelectedMitraId] = useState<string | null>(null);

  // Filter data based on search, date, and status filter
  const filteredData = useMemo(() => {
    return mitraList.filter((mitra) => {
      const matchesSearch = searchQuery === "" || 
        mitra.nama.toLowerCase().includes(searchQuery.toLowerCase()) ||
        mitra.email.toLowerCase().includes(searchQuery.toLowerCase()) ||
        mitra.id.toLowerCase().includes(searchQuery.toLowerCase()) ||
        mitra.noTlp.includes(searchQuery) ||
        mitra.layanan.toLowerCase().includes(searchQuery.toLowerCase()) ||
        mitra.status.toLowerCase().includes(searchQuery.toLowerCase());

      const matchesDate = !selectedDate || 
        (mitra.tanggal.getFullYear() === selectedDate.getFullYear() &&
         mitra.tanggal.getMonth() === selectedDate.getMonth() &&
         mitra.tanggal.getDate() === selectedDate.getDate());

      const matchesStatus = 
        statusFilter === "SEMUA" ||
        (statusFilter === "AKTIF" && mitra.status !== "DIBLOCK") ||
        (statusFilter === "DIBLOCK" && mitra.status === "DIBLOCK");

      return matchesSearch && matchesDate && matchesStatus;
    });
  }, [mitraList, searchQuery, selectedDate, statusFilter]);

  // Pagination
  const itemsPerPage = parseInt(entriesPerPage);
  const totalEntries = filteredData.length;
  const totalPages = Math.ceil(totalEntries / itemsPerPage);
  const paginatedData = filteredData.slice(
    (currentPage - 1) * itemsPerPage,
    currentPage * itemsPerPage
  );

  // Reset to page 1 when search or date changes
  const handleSearchChange = (value: string) => {
    setSearchQuery(value);
    setCurrentPage(1);
  };

  const handleDateChange = (date: Date | undefined) => {
    setSelectedDate(date);
    setCurrentPage(1);
  };

  // Download Excel function with auto column width
  const handleDownload = () => {
    const dataToExport = filteredData;
    
    if (dataToExport.length === 0) {
      return;
    }

    const excelData = dataToExport.map(mitra => ({
      "NO. ID": mitra.id,
      "NAMA": mitra.nama,
      "EMAIL": mitra.email,
      "NO. TLP": mitra.noTlp,
      "LAYANAN": mitra.layanan,
      "STATUS": mitra.status,
      "TANGGAL": format(mitra.tanggal, "dd-MM-yyyy")
    }));

    const worksheet = XLSX.utils.json_to_sheet(excelData);

    const columnWidths = [
      { wch: 10 },
      { wch: 25 },
      { wch: 30 },
      { wch: 15 },
      { wch: 15 },
      { wch: 15 },
      { wch: 12 },
    ];
    worksheet["!cols"] = columnWidths;

    const workbook = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(workbook, worksheet, "Daftar Mitra");

    XLSX.writeFile(workbook, `daftar-mitra-${format(new Date(), "yyyy-MM-dd")}.xlsx`);
  };

  // Handle block mitra
  const handleBlockClick = (mitraId: string) => {
    setSelectedMitraId(mitraId);
    setBlockPopupOpen(true);
  };

  const handleBlockConfirm = () => {
    setBlockPopupOpen(false);
    if (selectedMitraId) {
      blockMitra(selectedMitraId);
    }
    setBlockSuccessOpen(true);
  };

  // Handle unblock mitra
  const handleUnblockClick = (mitraId: string) => {
    setSelectedMitraId(mitraId);
    setUnblockPopupOpen(true);
  };

  const handleUnblockConfirm = () => {
    setUnblockPopupOpen(false);
    if (selectedMitraId) {
      unblockMitra(selectedMitraId);
    }
    setUnblockSuccessOpen(true);
  };

  // Handle status filter change
  const handleStatusFilterChange = (value: string) => {
    setStatusFilter(value);
    setCurrentPage(1);
  };

  // Generate page numbers for pagination
  const getPageNumbers = () => {
    const pages: (number | string)[] = [];
    if (totalPages <= 5) {
      for (let i = 1; i <= totalPages; i++) pages.push(i);
    } else {
      if (currentPage <= 3) {
        pages.push(1, 2, 3, "...", totalPages);
      } else if (currentPage >= totalPages - 2) {
        pages.push(1, "...", totalPages - 2, totalPages - 1, totalPages);
      } else {
        pages.push(1, "...", currentPage, "...", totalPages);
      }
    }
    return pages;
  };

  return (
    <div className="space-y-6">
      <Card className="shadow-sm">
        <CardHeader className="pb-4">
          <CardTitle className="text-xl font-semibold">Daftar Mitra</CardTitle>
        </CardHeader>
        <CardContent>
          {/* Filters */}
          <div className="flex items-center justify-between mb-6">
            <div className="relative w-72">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-muted-foreground" size={18} />
              <Input
                placeholder="Search nama, email, ID, layanan..."
                value={searchQuery}
                onChange={(e) => handleSearchChange(e.target.value)}
                className="pl-10 h-10 bg-background border-border"
              />
            </div>
            <div className="flex items-center gap-3">
              {/* Status Filter */}
              <Select value={statusFilter} onValueChange={handleStatusFilterChange}>
                <SelectTrigger className="w-40 h-10">
                  <SelectValue placeholder="Filter Status" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="AKTIF">Mitra Aktif</SelectItem>
                  <SelectItem value="DIBLOCK">Mitra Diblock</SelectItem>
                  <SelectItem value="SEMUA">Semua Mitra</SelectItem>
                </SelectContent>
              </Select>

              <Popover>
                <PopoverTrigger asChild>
                  <Button variant="outline" className={cn("gap-2", selectedDate && "text-primary border-primary")}>
                    <CalendarIcon size={18} />
                    {selectedDate ? format(selectedDate, "dd MMM yyyy", { locale: localeId }) : "Kalender"}
                  </Button>
                </PopoverTrigger>
                <PopoverContent className="w-auto p-0" align="end">
                  <Calendar
                    mode="single"
                    selected={selectedDate}
                    onSelect={handleDateChange}
                    initialFocus
                    className="p-3 pointer-events-auto"
                  />
                  {selectedDate && (
                    <div className="p-2 border-t">
                      <Button 
                        variant="ghost" 
                        size="sm" 
                        className="w-full"
                        onClick={() => handleDateChange(undefined)}
                      >
                        Reset Filter Tanggal
                      </Button>
                    </div>
                  )}
                </PopoverContent>
              </Popover>
              <Button className="gap-2 bg-primary" onClick={handleDownload} disabled={filteredData.length === 0}>
                <Download size={18} />
                Download
              </Button>
            </div>
          </div>

          {/* Table */}
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="bg-[#1e3a5f] text-white">
                  <th className="text-left py-3 px-4 font-medium rounded-tl-lg">NO. ID</th>
                  <th className="text-left py-3 px-4 font-medium">NAMA</th>
                  <th className="text-left py-3 px-4 font-medium">EMAIL</th>
                  <th className="text-left py-3 px-4 font-medium">NO. TLP</th>
                  <th className="text-left py-3 px-4 font-medium">LAYANAN</th>
                  <th className="text-left py-3 px-4 font-medium">STATUS</th>
                  <th className="text-center py-3 px-4 font-medium rounded-tr-lg">AKSI</th>
                </tr>
              </thead>
              <tbody>
                {paginatedData.length > 0 ? (
                  paginatedData.map((mitra, index) => (
                    <tr key={index} className="border-b border-border/50 hover:bg-muted/30">
                      <td className="py-4 px-4">{mitra.id}</td>
                      <td className="py-4 px-4">{mitra.nama}</td>
                      <td className="py-4 px-4 text-primary">{mitra.email}</td>
                      <td className="py-4 px-4">{mitra.noTlp}</td>
                      <td className="py-4 px-4">{mitra.layanan}</td>
                      <td className="py-4 px-4">
                        {getStatusBadge(mitra.status)}
                      </td>
                      <td className="py-4 px-4">
                        <div className="flex items-center justify-center gap-2">
                          <Button 
                            variant="ghost" 
                            size="icon" 
                            className="h-8 w-8 bg-[#1e3a5f] hover:bg-[#152a45]"
                            onClick={() => navigate(`/dashboard/mitra/${mitra.id}`)}
                          >
                            <Eye size={18} className="text-white" />
                          </Button>
                          {mitra.status === "DIBLOCK" ? (
                            <Button 
                              variant="ghost" 
                              size="icon" 
                              className="h-8 w-8 bg-green-600 hover:bg-green-700"
                              onClick={() => handleUnblockClick(mitra.id)}
                            >
                              <LockOpen size={18} className="text-white" />
                            </Button>
                          ) : (
                            <Button 
                              variant="ghost" 
                              size="icon" 
                              className="h-8 w-8 bg-red-600 hover:bg-red-700"
                              onClick={() => handleBlockClick(mitra.id)}
                            >
                              <Lock size={18} className="text-white" />
                            </Button>
                          )}
                        </div>
                      </td>
                    </tr>
                  ))
                ) : (
                  <tr>
                    <td colSpan={7} className="py-8 text-center text-muted-foreground">
                      Tidak ada data yang ditemukan
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>

          {/* Pagination */}
          <div className="flex items-center justify-between mt-6">
            <div className="flex items-center gap-2 text-sm text-muted-foreground">
              <Select value={entriesPerPage} onValueChange={(value) => { setEntriesPerPage(value); setCurrentPage(1); }}>
                <SelectTrigger className="w-16 h-8">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="10">10</SelectItem>
                  <SelectItem value="25">25</SelectItem>
                  <SelectItem value="50">50</SelectItem>
                </SelectContent>
              </Select>
              <span>of {totalEntries} entries</span>
            </div>
            <div className="flex items-center gap-1">
              <Button
                variant="ghost"
                size="icon"
                className="h-8 w-8"
                disabled={currentPage === 1}
                onClick={() => setCurrentPage(currentPage - 1)}
              >
                &lt;
              </Button>
              {getPageNumbers().map((page, idx) => (
                typeof page === "number" ? (
                  <Button
                    key={idx}
                    variant={currentPage === page ? "default" : "ghost"}
                    size="icon"
                    className={`h-8 w-8 ${currentPage === page ? "bg-primary text-white" : ""}`}
                    onClick={() => setCurrentPage(page)}
                  >
                    {page}
                  </Button>
                ) : (
                  <span key={idx} className="px-2 text-muted-foreground">{page}</span>
                )
              ))}
              <Button
                variant="ghost"
                size="icon"
                className="h-8 w-8"
                disabled={currentPage === totalPages || totalPages === 0}
                onClick={() => setCurrentPage(currentPage + 1)}
              >
                &gt;
              </Button>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Block Confirmation Popup */}
      <BlockMitraPopup
        open={blockPopupOpen}
        onOpenChange={setBlockPopupOpen}
        onConfirm={handleBlockConfirm}
        type="confirm"
      />

      {/* Block Success Popup */}
      <BlockMitraPopup
        open={blockSuccessOpen}
        onOpenChange={setBlockSuccessOpen}
        onConfirm={() => {}}
        type="success"
      />

      {/* Unblock Confirmation Popup */}
      <UnblockMitraPopup
        open={unblockPopupOpen}
        onOpenChange={setUnblockPopupOpen}
        onConfirm={handleUnblockConfirm}
        type="confirm"
      />

      {/* Unblock Success Popup */}
      <UnblockMitraPopup
        open={unblockSuccessOpen}
        onOpenChange={setUnblockSuccessOpen}
        onConfirm={() => {}}
        type="success"
      />
    </div>
  );
};

export default DaftarMitra;