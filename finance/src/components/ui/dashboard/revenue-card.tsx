import { Eye, EyeOff } from "lucide-react";
import { useState, useEffect } from "react";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import api from "@/lib/api";

interface RevenueCardProps {
  availableMonths: Array<{ label: string; value: string }>;
  currentMonthValue: string;
}

export function RevenueCard({ availableMonths, currentMonthValue }: RevenueCardProps) {
  const [pendapatan, setPendapatan] = useState<number>(0);
  const [showAccountNumber, setShowAccountNumber] = useState(false);
  const [selectedMonth, setSelectedMonth] = useState(currentMonthValue);

  useEffect(() => {
    api
      .get(`/pendapatan?month=${selectedMonth}`)
      .then(res => setPendapatan(res.data.pendapatan ?? 0))
      .catch(err => console.error("pendapatan error:", err));
  }, [selectedMonth]);

  return (
    <div className="bg-primary rounded-xl p-5 text-white relative">
      <div className="flex justify-between items-start mb-4">
        <p className="text-sm">Pendapatan</p>
        <Select value={selectedMonth} onValueChange={setSelectedMonth}>
          <SelectTrigger className="w-32 h-8 bg-white/10 border-white/20 text-white text-sm">
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
      
      <div className="flex items-center gap-3 mb-4">
        <p className="text-3xl font-bold">
          Rp {pendapatan.toLocaleString("id-ID")}
        </p>
        <button 
          onClick={() => setShowAccountNumber(!showAccountNumber)}
          className="p-1 hover:bg-white/10 rounded"
        >
          {showAccountNumber ? <EyeOff className="h-5 w-5" /> : <Eye className="h-5 w-5" />}
        </button>
      </div>

      <div className="border-t border-white/20 pt-3 space-y-1">
        <p className="text-xs opacity-80">No. Rekening</p>
        <p className="text-sm font-mono">
          {showAccountNumber ? "7981 0283 9877 897" : "•••• •••• •••• •••"}
        </p>
      </div>
    </div>
  );
}
