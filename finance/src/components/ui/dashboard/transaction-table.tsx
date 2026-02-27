import { useEffect, useState } from "react";
import { Eye } from "lucide-react";
import { Button } from "@/components/ui/button";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { useNavigate } from "react-router-dom";
import api from "@/lib/api";

interface TransactionTableProps {
  availableMonths: Array<{ label: string; value: string }>;
  currentMonthValue: string;
}

export function TransactionTable({ availableMonths, currentMonthValue }: TransactionTableProps) {
  const [transactions, setTransactions] = useState<any[]>([]);
  const [selectedMonth, setSelectedMonth] = useState(currentMonthValue);
  const navigate = useNavigate();

  useEffect(() => {
    api.get(`/finance/bookings/transactions?month=${selectedMonth}`)
      .then(res => setTransactions(res.data))
      .catch(err => console.error("transactions error:", err));
  }, [selectedMonth]);

  const mapStatus = (status: string) => {
    const s = (status ?? "").toString().toLowerCase().replace(/_/g, " ").trim();
    if (!s) return "-";
    if (s.includes("sampai") && s.includes("tujuan")) return "SAMPAI TUJUAN";
    switch (s) {
      case "pending":
        return "PROSES";
      case "paid":
        return "SELESAI";
      case "cancelled":
        return "BATAL";
      default:
        return s.toUpperCase();
    }
  };

  const getStatusColor = (status: string) => {
    const s = (status ?? "").toString().toLowerCase().replace(/_/g, " ").trim();
    if (!s) return "bg-gray-500";
    if (s.includes("sampai") && s.includes("tujuan")) return "bg-green-600";
    switch (s) {
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
    <div className="bg-background rounded-xl border overflow-hidden">
      <div className="flex justify-between items-center p-5 border-b">
        <h3 className="font-semibold text-lg">Daftar Transaksi</h3>
        <Select value={selectedMonth} onValueChange={setSelectedMonth}>
          <SelectTrigger className="w-32 h-8 text-sm">
            <SelectValue />
          </SelectTrigger>
          <SelectContent>
            {availableMonths.map((month) => (
              <SelectItem key={month.value} value={month.value}>
                {month.label}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>
      <table className="w-full">
        <thead className="bg-muted/50">
          <tr>
            {["NO.", "TANGGAL", "NAMA DRIVER", "NAMA COSTUMER", "NO. ORDERAN", "STATUS", "AKSI"].map(h => (
              <th key={h} className="px-4 py-3 text-xs font-semibold text-left">{h}</th>
            ))}
          </tr>
        </thead>
        <tbody>
          {transactions.map((tx, i) => (
            <tr key={tx.id} className="border-b hover:bg-muted/30 transition-colors">
              <td className="px-4 py-3 text-sm">{i + 1}</td>
              <td className="px-4 py-3 text-sm">
                {new Date(tx.tanggal).toLocaleDateString("id-ID", {
                  weekday: 'short',
                  day: '2-digit',
                  month: 'short',
                  year: 'numeric'
                })}
              </td>
              <td className="px-4 py-3 text-sm">{tx.driver ?? "-"}</td>
              <td className="px-4 py-3 text-sm">{tx.customer}</td>
              <td className="px-4 py-3 text-sm font-mono">{tx.booking_number}</td>
              <td className="px-4 py-3">
                <span
                  className={`px-3 py-1 rounded-full text-xs font-semibold text-white uppercase ${getStatusColor(tx.status)}`}
                >
                  {mapStatus(tx.status)}
                </span>
              </td>
              <td className="px-4 py-3">
                <Button
                  size="icon"
                  variant="ghost"
                  className="h-8 w-8 rounded-full bg-muted hover:bg-muted/80"
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
  );
}
