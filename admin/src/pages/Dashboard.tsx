import { Briefcase, Users, ShieldCheck, UserCheck, Eye, ChevronDown, ChevronLeft, ChevronRight } from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { dashboardApi } from "@/services/api";
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  ResponsiveContainer,
  Cell,
  LabelList,
  Tooltip,
} from "recharts";

const Dashboard = () => {
  const navigate = useNavigate();
  const [statistics, setStatistics] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  
  // State untuk filter bulan
  const [selectedMonth, setSelectedMonth] = useState(new Date().getMonth() + 1); // 1-12
  const [selectedYear, setSelectedYear] = useState(new Date().getFullYear());
  
  const currentDate = new Date();
  const currentMonth = currentDate.getMonth() + 1;
  const currentYear = currentDate.getFullYear();
  
  const fetchDashboardData = async () => {
    try {
      setLoading(true);
      console.log(`📊 Fetching dashboard for ${selectedMonth}/${selectedYear}...`);
      const response = await dashboardApi.getStatistics(selectedMonth, selectedYear);
      
      if (response.data.success) {
        console.log('✅ Dashboard data:', response.data.data);
        setStatistics(response.data.data);
      }
    } catch (err: any) {
      console.error('❌ Failed to fetch dashboard:', err);
      setError(err.response?.data?.message || 'Failed to load dashboard');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchDashboardData();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [selectedMonth, selectedYear]);
  
  // Function untuk navigasi bulan
  const goToPreviousMonth = () => {
    if (selectedMonth === 1) {
      setSelectedMonth(12);
      setSelectedYear(selectedYear - 1);
    } else {
      setSelectedMonth(selectedMonth - 1);
    }
  };
  
  const goToNextMonth = () => {
    // Cek apakah bulan berikutnya melebihi bulan saat ini
    const nextMonth = selectedMonth === 12 ? 1 : selectedMonth + 1;
    const nextYear = selectedMonth === 12 ? selectedYear + 1 : selectedYear;
    
    if (nextYear > currentYear || (nextYear === currentYear && nextMonth > currentMonth)) {
      // Tidak boleh maju ke bulan depan
      return;
    }
    
    setSelectedMonth(nextMonth);
    setSelectedYear(nextYear);
  };
  
  const isNextMonthDisabled = () => {
    const nextMonth = selectedMonth === 12 ? 1 : selectedMonth + 1;
    const nextYear = selectedMonth === 12 ? selectedYear + 1 : selectedYear;
    return nextYear > currentYear || (nextYear === currentYear && nextMonth > currentMonth);
  };
  
  const getMonthYearDisplay = () => {
    const monthNames = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return `${monthNames[selectedMonth - 1]} ${selectedYear}`;
  };

  // Stats data dari API
  const statsData = statistics ? [
    {
      title: "Total Mitra",
      value: statistics.statistics.totalMitra?.toLocaleString() || "0",
      icon: Briefcase,
      bgColor: "bg-[#1e3a5f]",
      iconBg: "bg-white/20",
    },
    {
      title: "Total Pelanggan",
      value: statistics.statistics.totalCustomer?.toLocaleString() || "0",
      icon: Users,
      bgColor: "bg-[#1e3a5f]",
      iconBg: "bg-white/20",
    },
    {
      title: "Verifikasi Mitra",
      value: statistics.statistics.pendingVerifikasiMitra?.toLocaleString() || "0",
      icon: ShieldCheck,
      bgColor: "bg-white border",
      iconBg: "bg-primary/10",
      textColor: "text-foreground",
      iconColor: "text-primary",
    },
    {
      title: "Verifikasi Pelanggan",
      value: statistics.statistics.pendingVerifikasiCustomer?.toLocaleString() || "0",
      icon: UserCheck,
      bgColor: "bg-white border",
      iconBg: "bg-orange-100",
      textColor: "text-foreground",
      iconColor: "text-orange-500",
    },
  ] : [];

  if (loading) {
    return (
      <div className="space-y-6">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-semibold text-foreground">Dashboard</h1>
            <p className="text-sm text-muted-foreground mt-1">Loading...</p>
          </div>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="space-y-6">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-semibold text-foreground">Dashboard</h1>
            <p className="text-sm text-red-500 mt-1">{error}</p>
          </div>
        </div>
      </div>
    );
  }

  // Chart data - bisa diambil dari statistics.grafik
  const chartData = statistics?.grafik?.map((item: any) => ({
    name: item.date,
    value: item.count,
    month: item.month,
    color: "#6366f1"
  })) || [];
  
  // Debug: Log chart data
  console.log('📊 Chart Data:', chartData);
  console.log('📊 Total items:', chartData.length);

  // Recent orders
  const recentOrders = statistics?.pesananTerbaru || [];
  
  // Custom tooltip untuk chart
  const CustomTooltip = ({ active, payload }: any) => {
    if (active && payload && payload.length) {
      return (
        <div className="bg-white border border-gray-200 rounded-lg shadow-lg p-3">
          <p className="font-semibold text-sm">{payload[0].payload.month}</p>
          <p className="text-primary font-bold text-lg">{payload[0].value} Pesanan</p>
        </div>
      );
    }
    return null;
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case "completed":
        return "bg-green-500 hover:bg-green-600";
      case "cancelled":
      case "rejected":
        return "bg-red-500 hover:bg-red-600";
      case "pending":
        return "bg-orange-500 hover:bg-orange-600";
      case "accepted":
        return "bg-blue-500 hover:bg-blue-600";
      default:
        return "bg-gray-500";
    }
  };

  const getStatusLabel = (status: string) => {
    switch (status) {
      case "completed":
        return "Selesai";
      case "cancelled":
        return "Dibatalkan";
      case "rejected":
        return "Ditolak";
      case "pending":
        return "Menunggu";
      case "accepted":
        return "Diterima";
      default:
        return status;
    }
  };

  return (
    <div className="space-y-6">
      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        {statsData.map((stat, index) => (
          <Card
            key={index}
            className={`${stat.bgColor} ${
              stat.textColor ? "" : "text-white"
            } shadow-sm`}
          >
            <CardContent className="p-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-3xl font-bold">{stat.value}</p>
                  <p
                    className={`text-sm mt-1 ${
                      stat.textColor ? "text-muted-foreground" : "text-white/70"
                    }`}
                  >
                    {stat.title}
                  </p>
                </div>
                <div
                  className={`w-12 h-12 rounded-lg ${stat.iconBg} flex items-center justify-center`}
                >
                  <stat.icon
                    size={24}
                    className={stat.iconColor || "text-white"}
                  />
                </div>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>

      {/* Charts Row */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Pesanan Chart */}
        <Card className="shadow-sm">
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-lg font-semibold">
              Pesanan{" "}
              <span className="text-sm font-normal text-muted-foreground">
                ({statistics?.statistics?.totalPesanan || 0} Pesanan)
              </span>
            </CardTitle>
            <div className="flex items-center gap-2">
              <Button 
                variant="ghost" 
                size="icon" 
                className="h-8 w-8"
                onClick={goToPreviousMonth}
              >
                <ChevronLeft size={16} />
              </Button>
              <span className="text-sm font-medium min-w-[120px] text-center">
                {getMonthYearDisplay()}
              </span>
              <Button 
                variant="ghost" 
                size="icon" 
                className="h-8 w-8"
                onClick={goToNextMonth}
                disabled={isNextMonthDisabled()}
              >
                <ChevronRight size={16} className={isNextMonthDisabled() ? 'opacity-30' : ''} />
              </Button>
            </div>
          </CardHeader>
          <CardContent>
            <ResponsiveContainer width="100%" height={280}>
              <BarChart data={chartData} barCategoryGap="20%">
                <CartesianGrid strokeDasharray="3 3" vertical={false} />
                <XAxis
                  dataKey="name"
                  tick={{ fontSize: 11 }}
                  tickLine={false}
                  axisLine={false}
                />
                <YAxis
                  tick={{ fontSize: 11 }}
                  tickLine={false}
                  axisLine={false}
                  domain={[0, 'auto']}
                  allowDecimals={false}
                />
                <Tooltip content={<CustomTooltip />} cursor={{fill: 'rgba(99, 102, 241, 0.1)'}} />
                <Bar 
                  dataKey="value" 
                  radius={[4, 4, 0, 0]}
                  minPointSize={5}
                  fill="#6366f1"
                >
                  {chartData.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={entry.color} />
                  ))}
                </Bar>
              </BarChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>

        {/* Tujuan Terbanyak */}
        <Card className="shadow-sm">
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-lg font-semibold">
              Pesanan Terbaru
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead>
                  <tr className="text-muted-foreground">
                    <th className="text-left py-2 font-medium">ID</th>
                    <th className="text-left py-2 font-medium">Customer</th>
                    <th className="text-left py-2 font-medium">Mitra</th>
                    <th className="text-right py-2 font-medium">Total</th>
                    <th className="text-center py-2 font-medium">Status</th>
                  </tr>
                </thead>
                <tbody>
                  {recentOrders.length > 0 ? (
                    recentOrders.map((order: any) => (
                      <tr key={order.id} className="border-t border-border/50">
                        <td className="py-2">#{order.id}</td>
                        <td className="py-2">{order.customer_name}</td>
                        <td className="py-2">{order.mitra_name}</td>
                        <td className="py-2 text-right">
                          Rp {order.total_price?.toLocaleString('id-ID') || '0'}
                        </td>
                        <td className="py-2 text-center">
                          <Badge className={`${getStatusColor(order.status)} text-white text-xs`}>
                            {getStatusLabel(order.status)}
                          </Badge>
                        </td>
                      </tr>
                    ))
                  ) : (
                    <tr>
                      <td colSpan={5} className="py-4 text-center text-muted-foreground">
                        Tidak ada pesanan terbaru
                      </td>
                    </tr>
                  )}
                </tbody>
              </table>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Additional Stats Row */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <Card className="shadow-sm">
          <CardContent className="p-6">
            <p className="text-sm text-muted-foreground">Total Pesanan</p>
            <p className="text-2xl font-bold mt-1">
              {statistics?.statistics?.totalPesanan?.toLocaleString() || '0'}
            </p>
          </CardContent>
        </Card>

        <Card className="shadow-sm">
          <CardContent className="p-6">
            <p className="text-sm text-muted-foreground">Pesanan Selesai</p>
            <p className="text-2xl font-bold mt-1 text-green-600">
              {statistics?.statistics?.pesananSelesai?.toLocaleString() || '0'}
            </p>
          </CardContent>
        </Card>

        <Card className="shadow-sm">
          <CardContent className="p-6">
            <p className="text-sm text-muted-foreground">Pesanan Hari Ini</p>
            <p className="text-2xl font-bold mt-1 text-blue-600">
              {statistics?.statistics?.pesananHariIni?.toLocaleString() || '0'}
            </p>
          </CardContent>
        </Card>

        <Card className="shadow-sm">
          <CardContent className="p-6">
            <p className="text-sm text-muted-foreground">Total Pendapatan</p>
            <p className="text-2xl font-bold mt-1 text-primary">
              Rp {statistics?.statistics?.totalPendapatan?.toLocaleString('id-ID') || '0'}
            </p>
          </CardContent>
        </Card>
      </div>
    </div>
  );
};

export default Dashboard;
