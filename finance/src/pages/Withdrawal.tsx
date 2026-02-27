import DashboardLayout from "@/components/DashboardLayout";
import { useEffect, useState } from "react";
import api from "@/lib/api";
import { toast } from "sonner";
import { StatisticsCards } from "@/components/ui/withdrawal/statistics-cards";
import { WithdrawalSearch } from "@/components/ui/withdrawal/withdrawal-search";
import { TypeFilter } from "@/components/ui/withdrawal/type-filter";
import { StatusFilter } from "@/components/ui/withdrawal/status-filter";
import { WithdrawalTable } from "@/components/ui/withdrawal/withdrawal-table";
import { Pagination } from "@/components/ui/withdrawal/pagination";
import { formatCurrency, formatDate } from "@/lib/withdrawal-utils";

interface Withdrawal {
  id: number;
  transaction_id: string;
  user_name: string;
  user_email: string;
  amount: number;
  admin_fee: number;
  total_amount: number;
  status: string;
  type: "mitra" | "posmitra";
  created_at: string;
}

interface Statistics {
  total: number;
  pending: number;
  processing: number;
  completed: number;
  rejected: number;
}

const Withdrawal = () => {
  const [withdrawals, setWithdrawals] = useState<Withdrawal[]>([]);
  const [statistics, setStatistics] = useState<Statistics>({
    total: 0,
    pending: 0,
    processing: 0,
    completed: 0,
    rejected: 0,
  });
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [statusFilter, setStatusFilter] = useState<string>("all");
  const [typeFilter, setTypeFilter] = useState<string>("all");
  const [currentPage, setCurrentPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);

  useEffect(() => {
    fetchWithdrawals();
  }, [search, statusFilter, typeFilter, currentPage]);

  const fetchWithdrawals = async () => {
    try {
      setLoading(true);
      const params: any = {
        page: currentPage,
        per_page: 10,
      };

      if (search) params.search = search;
      if (statusFilter && statusFilter !== "all") params.status = statusFilter;
      if (typeFilter && typeFilter !== "all") params.type = typeFilter;

      const response = await api.get("/finance/withdrawals", { params });
      setWithdrawals(response.data.data);
      setStatistics(response.data.statistics);
      setTotalPages(response.data.meta.last_page);
    } catch (error) {
      console.error("Error fetching withdrawals:", error);
      toast.error("Gagal mengambil data penarikan");
    } finally {
      setLoading(false);
    }
  };

  return (
    <DashboardLayout title="Penarikan Dana">
      <StatisticsCards statistics={statistics} />

      <div className="bg-background border border-border rounded-xl">
        <div className="p-5 border-b border-border flex items-center justify-between">
          <h3 className="font-semibold">Daftar Penarikan Dana</h3>

          <div className="flex items-center gap-3">
            <WithdrawalSearch
              value={search}
              onChange={(value) => {
                setSearch(value);
                setCurrentPage(1);
              }}
            />

            <TypeFilter
              value={typeFilter}
              onChange={(value) => {
                setTypeFilter(value);
                setCurrentPage(1);
              }}
            />

            <StatusFilter
              value={statusFilter}
              onChange={(value) => {
                setStatusFilter(value);
                setCurrentPage(1);
              }}
            />
          </div>
        </div>

        <WithdrawalTable
          data={withdrawals}
          loading={loading}
          formatCurrency={formatCurrency}
          formatDate={formatDate}
        />

        {totalPages > 1 && (
          <Pagination
            currentPage={currentPage}
            totalPages={totalPages}
            onPageChange={setCurrentPage}
          />
        )}
      </div>
    </DashboardLayout>
  );
};

export default Withdrawal;
