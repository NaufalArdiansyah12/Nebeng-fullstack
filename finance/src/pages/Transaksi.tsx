import { useEffect, useState } from "react";
import { Eye, ChevronDown, ChevronLeft, ChevronRight } from "lucide-react";
import { Button } from "@/components/ui/button";
import { useNavigate } from "react-router-dom";
import api from "@/lib/api";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger
} from "@/components/ui/dropdown-menu";
import DashboardLayout from "@/components/DashboardLayout";

type Transaction = {
  id: number;
  tanggal: string;
  driver: string | null;
  customer: string;
  booking_number: string;
  order_code?: string;
  status: "pending" | "paid" | "cancelled";
};

const Transaksi = () => {
  const navigate = useNavigate();

  const [transactions, setTransactions] = useState<Transaction[]>([]);
  const [statusFilter, setStatusFilter] = useState<string>("Semua");
  const [currentPage, setCurrentPage] = useState(1);

  const itemsPerPage = 10;

  /* =========================
     FETCH TRANSAKSI
  ========================= */
  useEffect(() => {
    api
      .get("/bookings/transactions")
      .then((res) => setTransactions(res.data))
      .catch((err) =>
        console.error("gagal ambil transaksi:", err.response?.data || err)
      );
  }, []);

  /* =========================
     FILTER & PAGINATION
  ========================= */
  const filteredTransactions =
    statusFilter === "Semua"
      ? transactions
      : transactions.filter(
          (tx) => mapStatus(tx.status) === statusFilter
        );

  const totalPages = Math.ceil(filteredTransactions.length / itemsPerPage);
  const startIndex = (currentPage - 1) * itemsPerPage;
  const paginatedTransactions = filteredTransactions.slice(
    startIndex,
    startIndex + itemsPerPage
  );

  /* =========================
     HELPER
  ========================= */
  const mapStatus = (status: string) => {
    switch (status) {
      case "pending":
        return "PROSES";
      case "paid":
        return "SELESAI";
      case "cancelled":
        return "BATAL";
      default:
        return status;
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case "PROSES":
        return "bg-yellow-500";
      case "SELESAI":
        return "bg-green-500";
      case "BATAL":
        return "bg-red-500";
      default:
        return "bg-gray-500";
    }
  };

  return (
    <DashboardLayout title="Transaksi">
      <div className="bg-background rounded-xl border border-border overflow-hidden">
        {/* Header */}
        <div className="p-5 border-b border-border flex items-center justify-between">
          <h3 className="font-semibold">Daftar Transaksi</h3>

          <DropdownMenu>
            <DropdownMenuTrigger asChild>
              <button className="flex items-center gap-2 text-sm text-muted-foreground">
                Status: {statusFilter}
                <ChevronDown className="h-4 w-4" />
              </button>
            </DropdownMenuTrigger>
            <DropdownMenuContent align="end">
              {["Semua", "PROSES", "SELESAI", "BATAL"].map((s) => (
                <DropdownMenuItem
                  key={s}
                  onClick={() => {
                    setStatusFilter(s);
                    setCurrentPage(1);
                  }}
                >
                  {s}
                </DropdownMenuItem>
              ))}
            </DropdownMenuContent>
          </DropdownMenu>
        </div>

        {/* Table */}
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-muted/50">
              <tr>
                {[
                  "NO",
                  "TANGGAL",
                  "DRIVER",
                  "CUSTOMER",
                  "NO TRANSAKSI",
                  "NO ORDER",
                  "STATUS",
                  "AKSI",
                ].map((h) => (
                  <th key={h} className="px-5 py-3 text-left text-xs">
                    {h}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody>
              {paginatedTransactions.map((tx, i) => {
                const statusText = mapStatus(tx.status);
                return (
                  <tr
                    key={tx.id}
                    className="border-b hover:bg-muted/30"
                  >
                    <td className="px-5 py-4">
                      {startIndex + i + 1}
                    </td>
                    <td className="px-5 py-4">
                      {new Date(tx.tanggal).toLocaleString("id-ID")}
                    </td>
                    <td className="px-5 py-4">
                      {tx.driver ?? "-"}
                    </td>
                    <td className="px-5 py-4">
                      {tx.customer}
                    </td>
                    <td className="px-5 py-4">
                      {tx.booking_number}
                    </td>
                    <td className="px-5 py-4">
                      {tx.order_code ?? tx.booking_number}
                    </td>
                    <td className="px-5 py-4">
                      <span
                        className={`px-3 py-1 rounded-full text-xs text-white ${getStatusColor(
                          statusText
                        )}`}
                      >
                        {statusText}
                      </span>
                    </td>
                    <td className="px-5 py-4">
  <Button
    size="icon"
    variant="ghost"
    onClick={() => navigate(`/transactions/${tx.id}`)}
  >
    <Eye className="h-4 w-4" />
  </Button>
                    </td>
                  </tr>
                );
              })}

              {paginatedTransactions.length === 0 && (
                <tr>
                  <td
                    colSpan={8}
                    className="text-center py-6 text-muted-foreground"
                  >
                    tidak ada data transaksi
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>

        {/* Pagination */}
        <div className="p-4 border-t border-border flex justify-between">
          <span className="text-sm text-muted-foreground">
            halaman {currentPage} dari {totalPages || 1}
          </span>
          <div className="flex gap-2">
            <Button
              size="icon"
              variant="outline"
              disabled={currentPage === 1}
              onClick={() => setCurrentPage((p) => p - 1)}
            >
              <ChevronLeft className="h-4 w-4" />
            </Button>
            <Button
              size="icon"
              variant="outline"
              disabled={currentPage === totalPages}
              onClick={() => setCurrentPage((p) => p + 1)}
            >
              <ChevronRight className="h-4 w-4" />
            </Button>
          </div>
        </div>
      </div>
    </DashboardLayout>
  );
};

export default Transaksi;
