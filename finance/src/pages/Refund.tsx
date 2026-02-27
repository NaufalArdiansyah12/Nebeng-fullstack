import DashboardLayout from "@/components/DashboardLayout";
import { useState, useEffect } from "react";
import api from "@/lib/api";
import { toast } from "sonner";
import { RefundSearch } from "@/components/ui/refund/refund-search";
import { StatusFilter } from "@/components/ui/refund/status-filter";
import { StatisticsCards } from "@/components/ui/refund/statistics-cards";
import { RefundTable } from "@/components/ui/refund/refund-table";
import { formatCurrency, formatDateShort } from "@/lib/refund-utils";

interface Refund {
  id: number;
  booking_id: number;
  booking_type: string;
  customer_name: string;
  customer_email: string;
  customer_phone: string;
  refund_reason: string;
  total_amount: number;
  refund_amount: number;
  admin_fee: number;
  bank_name: string;
  account_number: string;
  account_holder_name: string;
  status: "pending" | "approved" | "processing" | "completed" | "rejected";
  submitted_at: string;
  created_at: string;
}

const Refund = () => {
  const [search, setSearch] = useState("");
  const [statusFilter, setStatusFilter] = useState<string>("all");
  const [refunds, setRefunds] = useState<Refund[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchRefunds();
  }, [statusFilter]);

  const fetchRefunds = async () => {
    try {
      setLoading(true);
      const params = statusFilter !== "all" ? { status: statusFilter } : {};
      const response = await api.get("/finance/refunds", { params });
      setRefunds(response.data);
    } catch (error) {
      console.error("Error fetching refunds:", error);
      toast.error("Gagal mengambil data refund");
    } finally {
      setLoading(false);
    }
  };

  const filteredData = refunds.filter(
    (r) =>
      r.customer_name?.toLowerCase().includes(search.toLowerCase()) ||
      r.customer_email?.toLowerCase().includes(search.toLowerCase()) ||
      r.booking_id.toString().includes(search)
  );

  return (
    <DashboardLayout title="Refund">
      <div className="bg-background border border-border rounded-xl overflow-hidden">
        {/* Header */}
        <div className="p-5 border-b border-border">
          <div className="flex items-center justify-between mb-4">
            <h3 className="font-semibold">Daftar Refund</h3>
            <div className="flex items-center gap-3">
              <StatusFilter value={statusFilter} onChange={setStatusFilter} />
              <RefundSearch value={search} onChange={setSearch} />
            </div>
          </div>

          {/* Statistics Cards */}
          <StatisticsCards refunds={refunds} />
        </div>

        {/* Table */}
        <RefundTable 
          data={filteredData} 
          loading={loading} 
          formatCurrency={formatCurrency} 
          formatDate={formatDateShort} 
        />
      </div>
    </DashboardLayout>
  );
};

export default Refund;
