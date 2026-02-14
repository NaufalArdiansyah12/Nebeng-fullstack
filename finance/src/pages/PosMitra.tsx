import { ChevronLeft, ChevronRight } from "lucide-react";
import { Button } from "@/components/ui/button";
import DashboardLayout from "@/components/DashboardLayout";
import { useState, useEffect } from "react";
import api from "@/lib/api";
import { toast } from "sonner";
import { PosMitraSearch } from "@/components/ui/posmitra/posmitra-search";
import { PosMitraTable } from "@/components/ui/posmitra/posmitra-table";

interface PosMitra {
  id: number;
  nama: string;
  email: string;
  phone: string;
  terminal: string | null;
  alamat_terminal: string | null;
  kode_referral: string | null;
}

const PosMitra = () => {
  const [search, setSearch] = useState("");
  const [currentPage, setCurrentPage] = useState(1);
  const [posMitraData, setPosMitraData] = useState<PosMitra[]>([]);
  const [loading, setLoading] = useState(true);
  const itemsPerPage = 10;

  useEffect(() => {
    fetchPosMitra();
  }, []);

  const fetchPosMitra = async () => {
    try {
      setLoading(true);
      const response = await api.get("/users/pos-mitra");
      setPosMitraData(response.data);
    } catch (error) {
      console.error("Error fetching pos mitra:", error);
      toast.error("Gagal mengambil data Pos Mitra");
    } finally {
      setLoading(false);
    }
  };

  const filteredData = posMitraData.filter(
    (p) =>
      p.nama?.toLowerCase().includes(search.toLowerCase()) ||
      p.kode_referral?.toLowerCase().includes(search.toLowerCase()) ||
      p.terminal?.toLowerCase().includes(search.toLowerCase())
  );

  const totalEntries = filteredData.length;
  const totalPages = Math.ceil(totalEntries / itemsPerPage);
  
  // Get paginated data
  const startIndex = (currentPage - 1) * itemsPerPage;
  const endIndex = startIndex + itemsPerPage;
  const paginatedData = filteredData.slice(startIndex, endIndex);

  return (
    <DashboardLayout title="Pos Mitra">
      <div className="bg-background border border-border rounded-xl overflow-hidden">
        {/* Header */}
        <div className="p-5 border-b border-border flex items-center justify-between">
          <h3 className="font-semibold">Daftar Pos Mitra</h3>
          <PosMitraSearch value={search} onChange={setSearch} />
        </div>

        {/* Table */}
        <PosMitraTable data={paginatedData} loading={loading} startIndex={startIndex} />

        {/* Pagination */}
        {!loading && paginatedData.length > 0 && (
          <div className="p-4 flex items-center justify-between text-sm text-muted-foreground border-t border-border">
            <span>
              {Math.min(startIndex + 1, totalEntries)} - {Math.min(endIndex, totalEntries)} of {totalEntries} entries
            </span>
            <div className="flex items-center gap-1">
              <Button 
                variant="ghost" 
                size="icon"
                className="h-8 w-8"
                onClick={() => setCurrentPage(Math.max(1, currentPage - 1))}
                disabled={currentPage === 1}
              >
                <ChevronLeft className="h-4 w-4" />
              </Button>
              {Array.from({ length: Math.min(3, totalPages) }, (_, i) => i + 1).map((page) => (
                <Button
                  key={page}
                  variant={currentPage === page ? "default" : "ghost"}
                  size="icon"
                  className="h-8 w-8"
                  onClick={() => setCurrentPage(page)}
                >
                  {page}
                </Button>
              ))}
              {totalPages > 3 && (
                <>
                  <span className="px-2">...</span>
                  <Button
                    variant="ghost"
                    size="icon"
                    className="h-8 w-8"
                    onClick={() => setCurrentPage(totalPages)}
                  >
                    {totalPages}
                  </Button>
                </>
              )}
              <Button 
                variant="ghost" 
                size="icon"
                className="h-8 w-8"
                onClick={() => setCurrentPage(Math.min(totalPages, currentPage + 1))}
                disabled={currentPage === totalPages}
              >
                <ChevronRight className="h-4 w-4" />
              </Button>
            </div>
          </div>
        )}
      </div>
    </DashboardLayout>
  );
};

export default PosMitra;
