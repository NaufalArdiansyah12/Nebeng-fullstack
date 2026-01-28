import { useState, useMemo } from "react";
import { useNavigate } from "react-router-dom";
import { Search, Calendar as CalendarIcon, Download, Eye, Edit } from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { Calendar } from "@/components/ui/calendar";
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover";
import { format } from "date-fns";
import { id as localeId } from "date-fns/locale";
import { cn } from "@/lib/utils";
import * as XLSX from "xlsx";
import { useKendaraanMitra } from "@/contexts/KendaraanMitraContext";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";

const KendaraanMitra = () => {
  const navigate = useNavigate();
  const { kendaraanMitraList, loading, error } = useKendaraanMitra();
  const [searchQuery, setSearchQuery] = useState("");
  const [currentPage, setCurrentPage] = useState(1);
  const [entriesPerPage, setEntriesPerPage] = useState("10");
  const [selectedDate, setSelectedDate] = useState<Date | undefined>(undefined);

  // Filter data based on search and date
  const filteredData = useMemo(() => {
    return kendaraanMitraList.filter((kendaraan) => {
      const matchesSearch = searchQuery === "" || 
        kendaraan.namaMitra.toLowerCase().includes(searchQuery.toLowerCase()) ||
        kendaraan.kendaraan.toLowerCase().includes(searchQuery.toLowerCase()) ||
        kendaraan.merkKendaraan.toLowerCase().includes(searchQuery.toLowerCase()) ||
        kendaraan.platNomor.toLowerCase().includes(searchQuery.toLowerCase()) ||
        kendaraan.warna.toLowerCase().includes(searchQuery.toLowerCase());

      const matchesDate = !selectedDate || 
        (kendaraan.tanggal.getFullYear() === selectedDate.getFullYear() &&
         kendaraan.tanggal.getMonth() === selectedDate.getMonth() &&
         kendaraan.tanggal.getDate() === selectedDate.getDate());

      return matchesSearch && matchesDate;
    });
  }, [kendaraanMitraList, searchQuery, selectedDate]);

  // Pagination
  const itemsPerPage = parseInt(entriesPerPage);
  const totalEntries = filteredData.length;
  const totalPages = Math.ceil(totalEntries / itemsPerPage);
  const paginatedData = filteredData.slice(
    (currentPage - 1) * itemsPerPage,
    currentPage * itemsPerPage
  );

  const handleSearchChange = (value: string) => {
    setSearchQuery(value);
    setCurrentPage(1);
  };

  const handleDateChange = (date: Date | undefined) => {
    setSelectedDate(date);
    setCurrentPage(1);
  };

  // Download Excel function
  const handleDownload = () => {
    const dataToExport = filteredData;
    
    if (dataToExport.length === 0) {
      return;
    }

    const excelData = dataToExport.map(kendaraan => ({
      "NAMA MITRA": kendaraan.namaMitra,
      "KENDARAAN": kendaraan.kendaraan,
      "MERK KENDARAAN": kendaraan.merkKendaraan,
      "PLAT NOMOR": kendaraan.platNomor,
      "WARNA": kendaraan.warna,
      "TANGGAL": format(kendaraan.tanggal, "dd-MM-yyyy")
    }));

    const worksheet = XLSX.utils.json_to_sheet(excelData);

    const columnWidths = [
      { wch: 25 },
      { wch: 12 },
      { wch: 18 },
      { wch: 15 },
      { wch: 12 },
      { wch: 12 },
    ];
    worksheet["!cols"] = columnWidths;

    const workbook = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(workbook, worksheet, "Kendaraan Mitra");

    XLSX.writeFile(workbook, `kendaraan-mitra-${format(new Date(), "yyyy-MM-dd")}.xlsx`);
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

  // Placeholder image for vehicle
  const getVehicleImage = (kendaraan: string) => {
    return (
      <div className="w-16 h-10 bg-gray-100 rounded flex items-center justify-center">
        {kendaraan === "Mobil" ? (
          <svg viewBox="0 0 24 24" className="w-10 h-6 text-gray-400" fill="currentColor">
            <path d="M18.92 6.01C18.72 5.42 18.16 5 17.5 5h-11c-.66 0-1.21.42-1.42 1.01L3 12v8c0 .55.45 1 1 1h1c.55 0 1-.45 1-1v-1h12v1c0 .55.45 1 1 1h1c.55 0 1-.45 1-1v-8l-2.08-5.99zM6.5 16c-.83 0-1.5-.67-1.5-1.5S5.67 13 6.5 13s1.5.67 1.5 1.5S7.33 16 6.5 16zm11 0c-.83 0-1.5-.67-1.5-1.5s.67-1.5 1.5-1.5 1.5.67 1.5 1.5-.67 1.5-1.5 1.5zM5 11l1.5-4.5h11L19 11H5z"/>
          </svg>
        ) : (
          <svg viewBox="0 0 24 24" className="w-8 h-6 text-gray-400" fill="currentColor">
            <path d="M19.44 9.03L15.41 5H11v2h3.59l2 2H5c-2.8 0-5 2.2-5 5s2.2 5 5 5c2.46 0 4.45-1.69 4.9-4h1.65l2.77-2.77c-.21.54-.32 1.14-.32 1.77 0 2.8 2.2 5 5 5s5-2.2 5-5c0-2.65-1.97-4.77-4.56-4.97zM7.82 15C7.4 16.15 6.28 17 5 17c-1.63 0-3-1.37-3-3s1.37-3 3-3c1.28 0 2.4.85 2.82 2H5v2h2.82zM19 17c-1.66 0-3-1.34-3-3s1.34-3 3-3 3 1.34 3 3-1.34 3-3 3z"/>
          </svg>
        )}
      </div>
    );
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
                placeholder="Search"
                value={searchQuery}
                onChange={(e) => handleSearchChange(e.target.value)}
                className="pl-10 h-10 bg-background border-border"
              />
            </div>
            <div className="flex items-center gap-3">
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
                  <th className="text-left py-3 px-4 font-medium rounded-tl-lg">IMAGE</th>
                  <th className="text-left py-3 px-4 font-medium">NAMA</th>
                  <th className="text-left py-3 px-4 font-medium">KENDARAAN</th>
                  <th className="text-left py-3 px-4 font-medium">MERK KENDARAAN</th>
                  <th className="text-left py-3 px-4 font-medium">PLAT NOMOR</th>
                  <th className="text-left py-3 px-4 font-medium">WARNA</th>
                  <th className="text-center py-3 px-4 font-medium rounded-tr-lg">AKSI</th>
                </tr>
              </thead>
              <tbody>
                {loading ? (
                  <tr>
                    <td colSpan={7} className="py-8 text-center text-gray-500">
                      Memuat data...
                    </td>
                  </tr>
                ) : error ? (
                  <tr>
                    <td colSpan={7} className="py-8 text-center text-red-500">
                      Error: {error}
                    </td>
                  </tr>
                ) : paginatedData.length > 0 ? (
                  paginatedData.map((kendaraan, index) => (
                    <tr key={index} className="border-b border-border/50 hover:bg-muted/30">
                      <td className="py-4 px-4">
                        {getVehicleImage(kendaraan.kendaraan)}
                      </td>
                      <td className="py-4 px-4">{kendaraan.namaMitra}</td>
                      <td className="py-4 px-4">{kendaraan.kendaraan}</td>
                      <td className="py-4 px-4">{kendaraan.merkKendaraan}</td>
                      <td className="py-4 px-4">{kendaraan.platNomor}</td>
                      <td className="py-4 px-4">{kendaraan.warna}</td>
                      <td className="py-4 px-4">
                        <div className="flex items-center justify-center gap-2">
                          <Button 
                            variant="ghost" 
                            size="icon" 
                            className="h-8 w-8 bg-[#1e3a5f] hover:bg-[#152a45]"
                            onClick={() => navigate(`/dashboard/mitra-kendaraan/${kendaraan.id}`)}
                          >
                            <Eye size={18} className="text-white" />
                          </Button>
                          <Button 
                            variant="ghost" 
                            size="icon" 
                            className="h-8 w-8 bg-orange-500 hover:bg-orange-600"
                            onClick={() => navigate(`/dashboard/mitra-kendaraan/${kendaraan.id}?edit=true`)}
                          >
                            <Edit size={18} className="text-white" />
                          </Button>
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
    </div>
  );
};

export default KendaraanMitra;