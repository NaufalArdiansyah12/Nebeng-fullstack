import { useState, useMemo } from "react";
import { useNavigate } from "react-router-dom";
import { Search, Calendar as CalendarIcon, Download, Eye } from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { Calendar } from "@/components/ui/calendar";
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover";
import { format } from "date-fns";
import { id as localeId } from "date-fns/locale";
import { cn } from "@/lib/utils";
import * as XLSX from "xlsx";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { useLaporan } from "@/contexts/LaporanContext";

const Laporan = () => {
  const navigate = useNavigate();
  const { laporanList } = useLaporan();
  const [searchQuery, setSearchQuery] = useState("");
  const [currentPage, setCurrentPage] = useState(1);
  const [entriesPerPage, setEntriesPerPage] = useState("10");
  const [selectedDate, setSelectedDate] = useState<Date | undefined>(undefined);

  // Filter data based on search and date
  const filteredData = useMemo(() => {
    return laporanList.filter((laporan) => {
      const matchesSearch = searchQuery === "" || 
        laporan.namaCustomer.toLowerCase().includes(searchQuery.toLowerCase()) ||
        laporan.noOrder.includes(searchQuery) ||
        laporan.layanan.toLowerCase().includes(searchQuery.toLowerCase()) ||
        laporan.laporan.toLowerCase().includes(searchQuery.toLowerCase());

      const matchesDate = !selectedDate || 
        (laporan.tanggal.getFullYear() === selectedDate.getFullYear() &&
         laporan.tanggal.getMonth() === selectedDate.getMonth() &&
         laporan.tanggal.getDate() === selectedDate.getDate());

      return matchesSearch && matchesDate;
    });
  }, [laporanList, searchQuery, selectedDate]);

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

    const excelData = dataToExport.map(laporan => ({
      "NO. ORDER": laporan.noOrder,
      "NAMA COSTUMER": laporan.namaCustomer,
      "TANGGAL": format(laporan.tanggal, "EEEE, dd MMM yyyy", { locale: localeId }),
      "LAYANAN": laporan.layanan,
      "LAPORAN": laporan.laporan,
    }));

    const worksheet = XLSX.utils.json_to_sheet(excelData);

    const columnWidths = [
      { wch: 12 },
      { wch: 20 },
      { wch: 20 },
      { wch: 15 },
      { wch: 40 },
    ];
    worksheet["!cols"] = columnWidths;

    const workbook = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(workbook, worksheet, "Laporan");

    XLSX.writeFile(workbook, `laporan-${format(new Date(), "yyyy-MM-dd")}.xlsx`);
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
          <CardTitle className="text-xl font-semibold">Daftar Pesanan</CardTitle>
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
                  <th className="text-left py-3 px-4 font-medium rounded-tl-lg">NO. ORDER</th>
                  <th className="text-left py-3 px-4 font-medium">NAMA COSTUMER</th>
                  <th className="text-left py-3 px-4 font-medium">TANGGAL</th>
                  <th className="text-left py-3 px-4 font-medium">LAYANAN</th>
                  <th className="text-left py-3 px-4 font-medium">LAPORAN</th>
                  <th className="text-center py-3 px-4 font-medium rounded-tr-lg">AKSI</th>
                </tr>
              </thead>
              <tbody>
                {paginatedData.length > 0 ? (
                  paginatedData.map((laporan, index) => (
                    <tr key={index} className="border-b border-border/50 hover:bg-muted/30">
                      <td className="py-4 px-4">{laporan.noOrder}</td>
                      <td className="py-4 px-4">{laporan.namaCustomer}</td>
                      <td className="py-4 px-4">
                        {format(laporan.tanggal, "EEEE, dd MMM yyyy", { locale: localeId })}
                      </td>
                      <td className="py-4 px-4">{laporan.layanan}</td>
                      <td className="py-4 px-4 max-w-xs truncate">{laporan.laporan}</td>
                      <td className="py-4 px-4">
                        <div className="flex items-center justify-center">
                          <Button 
                            variant="ghost" 
                            size="icon" 
                            className="h-8 w-8 bg-[#1e3a5f] hover:bg-[#152a45]"
                            onClick={() => navigate(`/dashboard/laporan/${laporan.id}`)}
                          >
                            <Eye size={18} className="text-white" />
                          </Button>
                        </div>
                      </td>
                    </tr>
                  ))
                ) : (
                  <tr>
                    <td colSpan={6} className="py-8 text-center text-muted-foreground">
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

export default Laporan;
