import { useEffect, useState } from "react";
import DashboardLayout from "@/components/DashboardLayout";
import api from "@/lib/api";
import { RevenueCard } from "@/components/ui/dashboard/revenue-card";
import { UserStatsCard } from "@/components/ui/dashboard/user-stats-card";
import { PendapatanChart } from "@/components/ui/dashboard/pendapatan-chart";
import { PesananChart } from "@/components/ui/dashboard/pesanan-chart";
import { TransactionTable } from "@/components/ui/dashboard/transaction-table";

export default function Dashboard() {
  /* =========================
     STATE
  ========================= */
  const [totalMitra, setTotalMitra] = useState<number>(0);
  const [totalCustomer, setTotalCustomer] = useState<number>(0);
  
  // Generate available months (current month and previous 11 months)
  const generateAvailableMonths = () => {
    const months = [];
    const currentDate = new Date();
    
    for (let i = 0; i < 12; i++) {
      const date = new Date(currentDate.getFullYear(), currentDate.getMonth() - i, 1);
      const monthName = date.toLocaleDateString('id-ID', { month: 'short', year: 'numeric' });
      // Format with capital first letter
      const formattedLabel = monthName.charAt(0).toUpperCase() + monthName.slice(1);
      const monthValue = `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}`;
      months.push({ label: formattedLabel, value: monthValue });
    }
    
    return months;
  };

  const availableMonths = generateAvailableMonths();
  const currentMonthValue = availableMonths[0].value; // Current month

  /* =========================
     FETCH DATA
  ========================= */
  // total user
  useEffect(() => {
    api.get("/users/count-by-role")
      .then(res => {
        setTotalMitra(res.data.mitra ?? 0);
        setTotalCustomer(res.data.customer ?? 0);
      })
      .catch(err => console.error("user count error:", err));
  }, []);

  return (
    <DashboardLayout title="Dashboard">
      {/* Greeting Header */}
      <div className="mb-6">
        <h2 className="text-2xl font-semibold">Selamat Datang, Finance 👋</h2>
      </div>

      {/* Statistik */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-6">
        <RevenueCard 
          availableMonths={availableMonths} 
          currentMonthValue={currentMonthValue}
        />
        <UserStatsCard type="mitra" count={totalMitra} />
        <UserStatsCard type="customer" count={totalCustomer} />
      </div>

      {/* Chart */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-6">
        <PendapatanChart 
          availableMonths={availableMonths} 
          currentMonthValue={currentMonthValue}
        />
        <PesananChart 
          availableMonths={availableMonths} 
          currentMonthValue={currentMonthValue}
        />
      </div>

      {/* TABEL TRANSAKSI */}
      <TransactionTable 
        availableMonths={availableMonths} 
        currentMonthValue={currentMonthValue}
      />
    </DashboardLayout>
  );
}
