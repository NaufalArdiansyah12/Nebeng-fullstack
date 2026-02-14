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
}

export function PendapatanChart({ availableMonths, currentMonthValue }: PendapatanChartProps) {
  const [chartData, setChartData] = useState<any[]>([]);
  const [selectedMonth, setSelectedMonth] = useState(currentMonthValue);

  useEffect(() => {
    api
      .get(`/pendapatan/chart?month=${selectedMonth}`)
      .then(res => {
        setChartData(res.data || []);
      })
      .catch(err => console.error("chart pendapatan error:", err));
  }, [selectedMonth]);

  return (
    <div className="bg-background p-5 border rounded-xl">
      <div className="flex justify-between items-start mb-2">
        <div>
          <h3 className="font-semibold text-lg">Pendapatan</h3>
          <p className="text-sm text-muted-foreground">Pendapatan dari penjualan Nebeng</p>
        </div>
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
      <ResponsiveContainer width="100%" height={250}>
        <AreaChart data={chartData}>
          <defs>
            <linearGradient id="colorValue" x1="0" y1="0" x2="0" y2="1">
              <stop offset="5%" stopColor="hsl(var(--primary))" stopOpacity={0.3}/>
              <stop offset="95%" stopColor="hsl(var(--primary))" stopOpacity={0}/>
            </linearGradient>
          </defs>
          <CartesianGrid strokeDasharray="3 3" stroke="hsl(var(--border))" />
          <XAxis dataKey="month" stroke="hsl(var(--muted-foreground))" fontSize={12} />
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
