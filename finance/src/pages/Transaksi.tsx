import { useEffect, useState } from "react";
import api from "@/lib/api";
import DashboardLayout from "@/components/DashboardLayout";
import { StatusFilterDropdown } from "@/components/ui/transaksi/status-filter-dropdown";
import { TransactionTable } from "@/components/ui/transaksi/transaction-table";
import { PaginationControls } from "@/components/ui/transaksi/pagination-controls";
import { mapStatus } from "@/lib/transaction-utils";

type Transaction = {
  id: number;
  tanggal: string;
  driver: string | null;
  customer: string;
  booking_number: string;
  jenis: string;
  service_type?: string;
  status: "pending" | "paid" | "cancelled";
};

const Transaksi = () => {
  const [transactions, setTransactions] = useState<Transaction[]>([]);
  const [statusFilter, setStatusFilter] = useState<string>("Semua");
  const [currentPage, setCurrentPage] = useState(1);
  const [itemsPerPage, setItemsPerPage] = useState(10);

  useEffect(() => {
    api
      .get("/bookings/transactions")
      .then((res) => setTransactions(res.data))
      .catch((err) =>
        console.error("gagal ambil transaksi:", err.response?.data || err)
      );
  }, []);

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

  const handleStatusChange = (status: string) => {
    setStatusFilter(status);
    setCurrentPage(1);
  };

  const handleItemsPerPageChange = (value: number) => {
    setItemsPerPage(value);
    setCurrentPage(1);
  };

  return (
    <DashboardLayout title="Transaksi">
      <div className="bg-background rounded-xl border border-border overflow-hidden shadow-sm">
        <div className="px-6 py-4 border-b border-border flex items-center justify-between">
          <h3 className="font-semibold text-lg">Daftar Transaksi</h3>
          <StatusFilterDropdown 
            statusFilter={statusFilter}
            onStatusChange={handleStatusChange}
          />
        </div>

        <TransactionTable 
          transactions={paginatedTransactions}
          startIndex={startIndex}
        />

        <PaginationControls
          currentPage={currentPage}
          totalPages={totalPages}
          itemsPerPage={itemsPerPage}
          totalItems={filteredTransactions.length}
          onPageChange={setCurrentPage}
          onItemsPerPageChange={handleItemsPerPageChange}
        />
      </div>
    </DashboardLayout>
  );
};

export default Transaksi;
