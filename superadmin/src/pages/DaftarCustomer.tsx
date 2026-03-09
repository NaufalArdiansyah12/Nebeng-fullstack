import { useState, useMemo, useEffect } from "react";
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
import BlockCustomerPopup from "@/components/BlockCustomerPopup";
import UnblockCustomerPopup from "@/components/UnblockCustomerPopup";
import { useCustomer } from "@/contexts/CustomerContext";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";

const getStatusBadge = (status: string) => {
  const normalizedStatus = status?.toLowerCase() || 'active';
  switch (normalizedStatus) {
    case "active":
    case "terverifikasi":
      return <Badge className="bg-green-500 hover:bg-green-600 text-white text-xs">ACTIVE</Badge>;
    case "diblock":
    case "blocked":
      return <Badge className="bg-red-500 hover:bg-red-600 text-white text-xs">BLOCKED</Badge>;
    default:
      return <Badge className="bg-gray-500 text-white text-xs">{status?.toUpperCase()}</Badge>;
  }
};

const DaftarCustomer = () => {
  const navigate = useNavigate();
  const { customers, blockCustomer, unblockCustomer } = useCustomer();
  const [searchQuery, setSearchQuery] = useState("");
  const [currentPage, setCurrentPage] = useState(1);
  const [entriesPerPage, setEntriesPerPage] = useState("10");
  const [selectedDate, setSelectedDate] = useState<Date | undefined>(undefined);
  const [statusFilter, setStatusFilter] = useState<string>("AKTIF");
  const [blockPopupOpen, setBlockPopupOpen] = useState(false);
  const [blockSuccessOpen, setBlockSuccessOpen] = useState(false);
  const [unblockPopupOpen, setUnblockPopupOpen] = useState(false);
  const [unblockSuccessOpen, setUnblockSuccessOpen] = useState(false);
  const [selectedCustomerId, setSelectedCustomerId] = useState<string | null>(null);

  // ✅ Filter data - tampilkan semua customer dengan filter
  const filteredData = useMemo(() => {
    // ✅ Safety check
    if (!customers || !Array.isArray(customers)) {
      return [];
    }

    return customers.filter((customer) => {
      const customerStatus = customer.status?.toLowerCase() || 'active';

      const matchesSearch = searchQuery === "" ||
        customer.nama?.toLowerCase().includes(searchQuery.toLowerCase()) ||
        customer.email?.toLowerCase().includes(searchQuery.toLowerCase()) ||
        customer.id?.toString().includes(searchQuery) ||
        customer.no_tlp?.includes(searchQuery) ||
        customer.jenis_kelamin?.toLowerCase().includes(searchQuery.toLowerCase()) ||
        customer.status?.toLowerCase().includes(searchQuery.toLowerCase());

      const matchesDate = !selectedDate ||
        (customer.tanggal_daftar instanceof Date &&
          customer.tanggal_daftar.getFullYear() === selectedDate.getFullYear() &&
          customer.tanggal_daftar.getMonth() === selectedDate.getMonth() &&
          customer.tanggal_daftar.getDate() === selectedDate.getDate());

      // Filter status: AKTIF = tidak blocked, DIBLOCK = blocked, SEMUA = semua
      const matchesStatus =
        statusFilter === "SEMUA" ||
        (statusFilter === "AKTIF" && customerStatus !== "diblock" && customerStatus !== "blocked") ||
        (statusFilter === "DIBLOCK" && (customerStatus === "diblock" || customerStatus === "blocked"));

      return matchesSearch && matchesDate && matchesStatus;
    });
  }, [customers, searchQuery, selectedDate, statusFilter]);

  // Pagination - safe parsing with fallback
  const itemsPerPage = parseInt(entriesPerPage) || 10;
  const totalEntries = filteredData.length;
  const totalPages = Math.ceil(totalEntries / itemsPerPage) || 1;
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

  // Download Excel function
  const handleDownload = () => {
    const dataToExport = filteredData;

    if (dataToExport.length === 0) {
      return;
    }

    const excelData = dataToExport.map(customer => ({
      "NO. ID": customer.id,
      "NAMA": customer.nama,
      "EMAIL": customer.email,
      "NO. TLP": customer.no_tlp,
      "JENIS KELAMIN": customer.jenis_kelamin,
      "STATUS": customer.status,
      "TANGGAL": customer.tanggal_daftar ? format(customer.tanggal_daftar, "dd-MM-yyyy") : "-"
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
    XLSX.utils.book_append_sheet(workbook, worksheet, "Daftar Customer");

    XLSX.writeFile(workbook, `daftar-customer-${format(new Date(), "yyyy-MM-dd")}.xlsx`);
  };

  // ✅ Handle block customer dengan auto-close success modal
  const handleBlockClick = (customerId: string) => {
    setSelectedCustomerId(customerId);
    setBlockPopupOpen(true);
  };

  const handleBlockConfirm = async () => {
    setBlockPopupOpen(false);
    if (selectedCustomerId) {
      await blockCustomer(selectedCustomerId);
    }
    setBlockSuccessOpen(true);

    // ✅ Auto close success modal setelah 1.5 detik
    setTimeout(() => {
      setBlockSuccessOpen(false);
      setSelectedCustomerId(null);
    }, 1500);
  };

  // ✅ Handle unblock customer dengan auto-close success modal
  const handleUnblockClick = (customerId: string) => {
    setSelectedCustomerId(customerId);
    setUnblockPopupOpen(true);
  };

  const handleUnblockConfirm = async () => {
    setUnblockPopupOpen(false);
    if (selectedCustomerId) {
      await unblockCustomer(selectedCustomerId);
    }
    setUnblockSuccessOpen(true);

    // ✅ Auto close success modal setelah 1.5 detik
    setTimeout(() => {
      setUnblockSuccessOpen(false);
      setSelectedCustomerId(null);
    }, 1500);
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

  // ✅ Loading state
  if (!customers) {
    return (
      <div className="flex items-center justify-center py-12">
        <p className="text-muted-foreground">Memuat data customer...</p>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <Card className="shadow-sm">
        <CardHeader className="pb-4">
          <CardTitle className="text-xl font-semibold">Daftar Customer</CardTitle>
        </CardHeader>
        <CardContent>
          {/* Filters */}
          <div className="flex items-center justify-between mb-6">
            <div className="relative w-72">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-muted-foreground" size={18} />
              <Input
                placeholder="Search nama, email, ID, jenis kelamin..."
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
                  <SelectItem value="AKTIF">Customer Aktif</SelectItem>
                  <SelectItem value="SEMUA">Semua Customer</SelectItem>
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
                  <th className="text-left py-3 px-4 font-medium">JENIS KELAMIN</th>
                  <th className="text-left py-3 px-4 font-medium">STATUS</th>
                  <th className="text-center py-3 px-4 font-medium rounded-tr-lg">AKSI</th>
                </tr>
              </thead>
              <tbody>
                {paginatedData.length > 0 ? (
                  paginatedData.map((customer, index) => (
                    <tr key={index} className="border-b border-border/50 hover:bg-muted/30">
                      <td className="py-4 px-4">{customer.id}</td>
                      <td className="py-4 px-4">{customer.nama}</td>
                      <td className="py-4 px-4 text-primary">{customer.email}</td>
                      <td className="py-4 px-4">{customer.no_tlp}</td>
                      <td className="py-4 px-4">{customer.jenis_kelamin || '-'}</td>
                      <td className="py-4 px-4">
                        {getStatusBadge(customer.status)}
                      </td>
                      <td className="py-4 px-4">
                        <div className="flex items-center justify-center gap-2">
                          <Button
                            variant="ghost"
                            size="icon"
                            className="h-8 w-8 bg-[#1e3a5f] hover:bg-[#152a45]"
                            onClick={() => navigate(`/dashboard/costumer/${customer.id}`)}
                          >
                            <Eye size={18} className="text-white" />
                          </Button>

                          {/* Conditional button: Block jika status TERVERIFIKASI, Unblock jika DIBLOCK */}
                          {customer.status?.toUpperCase() === 'DIBLOCK' ? (
                            <Button
                              variant="ghost"
                              size="icon"
                              className="h-8 w-8 bg-green-600 hover:bg-green-700"
                              onClick={() => handleUnblockClick(customer.id.toString())}
                              title="Unblock Customer"
                            >
                              <LockOpen size={18} className="text-white" />
                            </Button>
                          ) : (
                            <Button
                              variant="ghost"
                              size="icon"
                              className="h-8 w-8 bg-red-600 hover:bg-red-700"
                              onClick={() => handleBlockClick(customer.id.toString())}
                              title="Block Customer"
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
      <BlockCustomerPopup
        open={blockPopupOpen}
        onOpenChange={setBlockPopupOpen}
        onConfirm={handleBlockConfirm}
        type="confirm"
      />

      {/* Block Success Popup */}
      <BlockCustomerPopup
        open={blockSuccessOpen}
        onOpenChange={setBlockSuccessOpen}
        onConfirm={() => {}}
        type="success"
      />

      {/* Unblock Confirmation Popup */}
      <UnblockCustomerPopup
        open={unblockPopupOpen}
        onOpenChange={setUnblockPopupOpen}
        onConfirm={handleUnblockConfirm}
        type="confirm"
      />

      {/* Unblock Success Popup */}
      <UnblockCustomerPopup
        open={unblockSuccessOpen}
        onOpenChange={setUnblockSuccessOpen}
        onConfirm={() => {}}
        type="success"
      />
    </div>
  );
};

export default DaftarCustomer;