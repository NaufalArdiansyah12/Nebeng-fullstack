import { useEffect, useState } from "react";
import {
  AreaChart,
  Area,
  XAxis,
  YAxis,
  Tooltip,
  ResponsiveContainer,
  CartesianGrid,
} from "recharts";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import api from "@/lib/api";

interface PendapatanChartProps {
  availableMonths: Array<{ label: string; value: string }>;
  currentMonthValue: string;
  availableYears?: Array<{ label: string; value: string }>;
  currentYearValue?: string;
}

export function PendapatanChart({ availableMonths, currentMonthValue, availableYears = [], currentYearValue }: PendapatanChartProps) {
  const [chartData, setChartData] = useState<any[]>([]);
  const [selectedMonth, setSelectedMonth] = useState(currentMonthValue);
  const [selectedYear, setSelectedYear] = useState(currentYearValue ?? (availableYears[0]?.value ?? ""));

  useEffect(() => {
    const query = selectedYear ? `year=${selectedYear}` : `month=${selectedMonth}`;
    api
      .get(`/finance/pendapatan/chart?${query}`)
      .then(res => {
        const data = res.data || [];
        // Normalize data to { label, value } for XAxis compatibility
        const normalized = (data || []).map((d: any) => ({
          label: d.year ?? d.month ?? d.label ?? d.monthLabel ?? d.month_name,
          value: d.value ?? d.pendapatan ?? 0,
        }));
        setChartData(normalized);
      })
      .catch(err => console.error("chart pendapatan error:", err));
  }, [selectedMonth, selectedYear]);

  return (
    <div className="bg-background p-5 border rounded-xl">
      <div className="flex justify-between items-start mb-2">
        <div>
          <h3 className="font-semibold text-lg">Pendapatan</h3>
          <p className="text-sm text-muted-foreground">Pendapatan dari penjualan Nebeng</p>
        </div>
        {availableYears.length > 0 ? (
          <Select value={selectedYear} onValueChange={setSelectedYear}>
            <SelectTrigger className="w-32 h-8 text-sm">
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              {availableYears.map((y) => (
                <SelectItem key={y.value} value={y.value}>
                  {y.label}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
        ) : (
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
        )}
      </div>
      <ResponsiveContainer width="100%" height={250}>
        <AreaChart data={chartData}>
          <defs>
            <linearGradient id="colorValue" x1="0" y1="0" x2="0" y2="1">
              <stop offset="5%" stopColor="hsl(var(--primary))" stopOpacity={0.3}/>
              <stop offset="95%" stopColor="hsl(var(--primary))" stopOpacity={0}/>
            </linearGradient>
          </defs>
          <CartesianGrid strokeDasharray="3 3" stroke="hsl(var(--border))" />
          <XAxis dataKey="label" stroke="hsl(var(--muted-foreground))" fontSize={12} />
          <YAxis stroke="hsl(var(--muted-foreground))" fontSize={12} />
          <Tooltip 
            contentStyle={{
              backgroundColor: 'hsl(var(--background))',
              border: '1px solid hsl(var(--border))',
              borderRadius: '8px'
            }}
          />
          <Area 
            type="monotone"
            dataKey="value" 
            stroke="hsl(var(--primary))"
            strokeWidth={2}
            fill="url(#colorValue)"
          />
        </AreaChart>
      </ResponsiveContainer>
    </div>
  );
}
