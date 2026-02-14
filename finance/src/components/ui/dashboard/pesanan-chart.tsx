import { useEffect, useState } from "react";
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  Tooltip,
  ResponsiveContainer,
  CartesianGrid,
  Cell,
} from "recharts";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import api from "@/lib/api";

interface PesananChartProps {
  availableMonths: Array<{ label: string; value: string }>;
  currentMonthValue: string;
}

export function PesananChart({ availableMonths, currentMonthValue }: PesananChartProps) {
  const [chartData, setChartData] = useState<any[]>([]);
  const [selectedMonth, setSelectedMonth] = useState(currentMonthValue);

  useEffect(() => {
    api.get(`/bookings/chart?month=${selectedMonth}`)
      .then(res => setChartData(res.data))
      .catch(err => console.error("chart pesanan error:", err));
  }, [selectedMonth]);

  const sortedChartData = [...chartData].sort((a, b) => b.total - a.total);

  // Calculate Y-axis ticks
  const maxPesanan = Math.max(...chartData.map(item => item.total), 0);
  const getYAxisTicks = (max: number) => {
    if (max === 0) return [0, 50, 100, 150, 200];
    
    const maxRounded = Math.ceil(max / 100) * 100;
    const step = maxRounded <= 200 ? 50 : maxRounded <= 500 ? 100 : 200;
    
    const ticks = [0];
    let current = step;
    while (current < maxRounded) {
      ticks.push(current);
      current += step;
    }
    ticks.push(maxRounded);
    
    return ticks;
  };
  const yAxisTicks = getYAxisTicks(maxPesanan);

  return (
    <div className="bg-background p-5 border rounded-xl">
      <div className="flex justify-between items-start mb-2">
        <div>
          <h3 className="font-semibold text-lg">Pesanan</h3>
          <p className="text-sm text-muted-foreground">Pesanan dari Layanan</p>
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
        <BarChart 
          data={sortedChartData}
          margin={{ top: 10, right: 10, left: 0, bottom: 0 }}
        >
          <defs>
            <linearGradient id="barDark" x1="0" y1="0" x2="0" y2="1">
              <stop offset="0%" stopColor="#1e3a8a" />
              <stop offset="100%" stopColor="#1e40af" />
            </linearGradient>
            <linearGradient id="barLight" x1="0" y1="0" x2="0" y2="1">
              <stop offset="0%" stopColor="#93c5fd" />
              <stop offset="100%" stopColor="#60a5fa" />
            </linearGradient>
          </defs>
          <CartesianGrid 
            strokeDasharray="5 5" 
            stroke="#e5e7eb" 
            horizontal={true}
            vertical={false}
          />
          <XAxis 
            dataKey="label" 
            stroke="#6b7280" 
            fontSize={12}
            axisLine={false}
            tickLine={false}
          />
          <YAxis 
            stroke="#6b7280" 
            fontSize={12}
            axisLine={false}
            tickLine={false}
            domain={[0, yAxisTicks[yAxisTicks.length - 1]]}
            ticks={yAxisTicks}
          />
          <Tooltip 
            contentStyle={{
              backgroundColor: 'white',
              border: '1px solid #e5e7eb',
              borderRadius: '8px',
              boxShadow: '0 2px 8px rgba(0,0,0,0.1)'
            }}
            cursor={{ fill: 'rgba(0,0,0,0.05)' }}
          />
          <Bar 
            dataKey="total" 
            radius={[4, 4, 0, 0]}
            maxBarSize={80}
          >
            {sortedChartData.map((entry, index) => (
              <Cell 
                key={`cell-${index}`}
                fill={index === sortedChartData.length - 1 ? "url(#barLight)" : "url(#barDark)"}
              />
            ))}
          </Bar>
        </BarChart>
      </ResponsiveContainer>
    </div>
  );
}
