import { Eye, Users } from "lucide-react";
import { useEffect, useState } from "react";
import { Button } from "@/components/ui/button";
import { useNavigate } from "react-router-dom";
import DashboardLayout from "@/components/DashboardLayout";
import axios from "axios";
import api from "@/lib/api";
import {
  AreaChart,
  Area,
  XAxis,
  YAxis,
  Tooltip,
  ResponsiveContainer,
} from "recharts";

export default function Dashboard() {
  /* =========================
     STATE
  ========================= */
  const [pendapatan, setPendapatan] = useState<number>(0);
  const [chartPendapatan, setChartPendapatan] = useState<any[]>([]);

  const [totalMitra, setTotalMitra] = useState<number>(0);
  const [totalCustomer, setTotalCustomer] = useState<number>(0);

  const [chartPesanan, setChartPesanan] = useState<any[]>([]);
  const [transactions, setTransactions] = useState<any[]>([]);

  const sortedChartPesanan = [...chartPesanan].sort(
    (a, b) => b.total - a.total
  );
  const navigate = useNavigate();


  /* =========================
     FETCH DATA
  ========================= */
  // total pendapatan
  useEffect(() => {
    api
      .get("/pendapatan")
      .then(res => setPendapatan(res.data.pendapatan ?? 0))
      .catch(err => console.error("pendapatan error:", err));
  }, []);

   // chart pendapatan
  useEffect(() => {
    api
      .get("/pendapatan/chart")
      .then(res => {
        setChartPendapatan(
          res.data.map((i: any) => ({
            month: i.month_name,
            value: Number(i.total),
          }))
        );
      })
      .catch(err => console.error("chart pendapatan error:", err));
  }, []);

    // total user
  useEffect(() => {
    api.get("/users/count-by-role")
      .then(res => {
        setTotalMitra(res.data.mitra ?? 0);
        setTotalCustomer(res.data.customer ?? 0);
      })
      .catch(err => console.error("user count error:", err));
  }, []);

  useEffect(() => {
    api.get("/bookings/chart")
      .then(res => setChartPesanan(res.data))
      .catch(err => console.error("chart pesanan error:", err));
  }, []);

  useEffect(() => {
    api.get("/bookings/transactions")
      .then(res => setTransactions(res.data))
      .catch(err => console.error("transactions error:", err));
  }, []);




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
        return status.toUpperCase();
    }
  };
  const getStatusColor = (status: string) => {
    switch (status) {
      case "pending":
        return "bg-yellow-500";
      case "paid":
        return "bg-green-500";
      case "cancelled":
        return "bg-red-500";
      default:
        return "bg-gray-500";
    }
  };


  return (
    <DashboardLayout title="Dashboard">
      {/* Statistik */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-6">
        <div className="bg-background rounded-xl p-5 border">
          <p className="text-sm text-muted-foreground">Pendapatan</p>
          <p className="text-2xl font-bold">
            Rp {pendapatan.toLocaleString("id-ID")}
          </p>
        </div>

        <div className="bg-background rounded-xl p-5 border flex gap-4">
          <Users />
          <div>
            <p className="text-2xl font-bold">{totalMitra}</p>
            <p className="text-xs text-muted-foreground">Total Pengguna Mitra</p>
          </div>
        </div>

        <div className="bg-background rounded-xl p-5 border flex gap-4">
          <Users />
          <div>
            <p className="text-2xl font-bold">{totalCustomer}</p>
            <p className="text-xs text-muted-foreground">Total Pengguna Customer</p>
          </div>
        </div>
      </div>

      {/* Chart */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-6">
        <div className="bg-background p-5 border rounded-xl">
          <h3 className="mb-4 font-semibold">Pendapatan</h3>
          <ResponsiveContainer width="100%" height={220}>
            <AreaChart data={chartPendapatan}>
              <XAxis dataKey="month" />
              <YAxis />
              <Tooltip />
              <Area dataKey="value" fillOpacity={0.2} />
            </AreaChart>
          </ResponsiveContainer>
        </div>

        <div className="bg-background p-5 border rounded-xl">
          <h3 className="mb-4 font-semibold">Pesanan</h3>
<div className="flex items-end gap-8 h-48 justify-center">
  {sortedChartPesanan.map((item, i) => (
    <div key={i} className="text-center relative group">
      {/* Tooltip */}
      <div className="absolute -top-8 left-1/2 -translate-x-1/2
                      bg-black text-white text-xs px-2 py-1 rounded
                      opacity-0 group-hover:opacity-100 transition
                      whitespace-nowrap">
        {item.total} Pesanan
      </div>

      {/* Bar */}
      <div
        className="w-12 bg-primary rounded-t cursor-pointer"
        style={{ height: `${item.total * 4}px` }}

      />

      <p className="text-xs mt-2">{item.label}</p>
    </div>
  ))}
</div>

        </div>
      </div>

      {/* TABEL TRANSAKSI */}
      <div className="bg-background rounded-xl border overflow-hidden">
        <table className="w-full">
          <thead className="bg-muted/50">
            <tr>
              {["NO", "TANGGAL", "DRIVER", "CUSTOMER", "JENIS", "ORDER", "STATUS", "AKSI"].map(h => (
                <th key={h} className="px-4 py-3 text-xs text-left">{h}</th>
              ))}
            </tr>
          </thead>
          <tbody>
            {transactions.map((tx, i) => (
              <tr key={tx.id} className="border-b">
                <td className="px-4 py-3">{i + 1}</td>
                <td className="px-4 py-3">
                  {new Date(tx.tanggal).toLocaleDateString("id-ID")}
                </td>
                <td className="px-4 py-3">{tx.driver ?? "-"}</td>
                <td className="px-4 py-3">{tx.customer}</td>
                <td className="px-4 py-3">{tx.jenis}</td>
                <td className="px-4 py-3">{tx.booking_number}</td>
                <td className="px-5 py-4">
                  <span
                    className={`px-3 py-1 rounded-full text-xs text-white ${getStatusColor(tx.status)}`}
                  >
                    {mapStatus(tx.status)}
                  </span>
                </td>

<td className="px-4 py-3">
  <Button
    size="icon"
    variant="ghost"
    onClick={() => navigate(`/transactions/${tx.id}`)}
  >
    <Eye className="h-4 w-4" />
  </Button>
</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </DashboardLayout>
  );
}
