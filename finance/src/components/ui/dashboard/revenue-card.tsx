import { Eye, EyeOff, ChevronDown } from "lucide-react";
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
  availableYears?: Array<{ label: string; value: string }>;
  currentYearValue?: string;
}

export function RevenueCard({
  availableMonths,
  currentMonthValue,
  availableYears = [],
  currentYearValue,
}: RevenueCardProps) {
  const [pendapatan, setPendapatan] = useState<number>(0);
  const [showAmount, setShowAmount] = useState(true);
  const [selectedMonth, setSelectedMonth] = useState(currentMonthValue);
  const [selectedYear, setSelectedYear] = useState(
    currentYearValue ?? (availableYears[0]?.value ?? String(new Date().getFullYear()))
  );

  useEffect(() => {
    const query = selectedYear
      ? `year=${selectedYear}`
      : `month=${selectedMonth}`;
    api
      .get(`/finance/pendapatan?${query}`)
      .then((res) => setPendapatan(res.data.pendapatan ?? 0))
      .catch((err) => console.error("pendapatan error:", err));
  }, [selectedMonth, selectedYear]);

  const formattedAmount = new Intl.NumberFormat("id-ID", {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  }).format(pendapatan);

  return (
    <div
      className="rounded-2xl p-5 text-white relative overflow-hidden"
      style={{
        background: "linear-gradient(135deg, #1a3a6b 0%, #1e4d8c 50%, #1a3a6b 100%)",
        minWidth: 320,
      }}
    >
      {/* Header Row */}
      <div className="flex items-center justify-between mb-5">
        <p className="text-sm font-medium text-white/90 tracking-wide">Pendapatan</p>

        {/* Month / Year Selector */}
        <Select
          value={availableYears.length > 0 ? selectedYear : selectedMonth}
          onValueChange={availableYears.length > 0 ? setSelectedYear : setSelectedMonth}
        >
          <SelectTrigger
            className="h-7 px-3 py-0 gap-1 border-0 bg-transparent text-white text-sm font-medium focus:ring-0 focus:ring-offset-0 [&>svg]:hidden w-auto"
            style={{ boxShadow: "none" }}
          >
            <SelectValue />
            <ChevronDown className="h-3.5 w-3.5 opacity-80" />
          </SelectTrigger>
          <SelectContent>
            {(availableYears.length > 0 ? availableYears : availableMonths).map((item) => (
              <SelectItem key={item.value} value={item.value}>
                {item.label}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>

      { /* Amount Row */ }
      <div className="flex items-center gap-3 mb-5">
        <p className="text-3xl font-bold tracking-tight leading-none">
          {showAmount ? `Rp ${formattedAmount}` : "Rp ••••••••••"}
        </p>
        <button
          onClick={() => setShowAmount(!showAmount)}
          className="flex-shrink-0 opacity-70 hover:opacity-100 transition-opacity"
          aria-label={showAmount ? "Sembunyikan jumlah" : "Tampilkan jumlah"}
        >
          {showAmount ? (
            <EyeOff className="h-5 w-5" strokeWidth={1.8} />
          ) : (
            <Eye className="h-5 w-5" strokeWidth={1.8} />
          )}
        </button>
      </div>

      {/* Divider */}
      <div className="border-t border-white/20 mb-3" />

      {/* Account Number Row */}
      {/* <div className="flex items-center justify-between">
        <p className="text-xs text-white/70 font-medium tracking-wide">No. Rekening</p>
        <p className="text-sm font-mono tracking-widest text-white/90">
          7981 0283 9877 897
        </p>
      </div> */}
    </div>
  );
}