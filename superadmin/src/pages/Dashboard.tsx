import { useState, useEffect } from "react";
import { Briefcase, Users, ShieldCheck, UserCheck, Eye } from "lucide-react";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  ResponsiveContainer,
  Cell,
  LabelList,
} from "recharts";
import { dashboardApi } from "@/services/api";

// Interfaces for dashboard data
interface DashboardStats {
  totalMitra: number;
  totalCustomer: number;
  verifiedMitra: number;
  verifiedCustomer: number;
}

interface ChartDataItem {
  name: string;
  value: number;
  color: string;
}

interface DestinationData {
  no: number;
  kotaAsal: string;
  kotaTujuan: string;
  total: string;
}

interface MitraData {
  id: string;
  nama: string;
  email: string;
  noTlp: string;
  gender: string;
  status: string;
}

const getStatusColor = (status: string) => {
  const normalizedStatus = status?.toLowerCase() || 'active';
  switch (normalizedStatus) {
    case "active":
      return "bg-green-500 hover:bg-green-600";
    case "blocked":
      return "bg-red-500 hover:bg-red-600";
    case "pengajuan":
      return "bg-orange-500 hover:bg-orange-600";
    default:
      return "bg-gray-500";
  }
};

const Dashboard = () => {
  const [statsData, setStatsData] = useState([
    {
      title: "Total Mitra",
      value: "0",
      icon: Briefcase,
      bgColor: "bg-[#1e3a5f]",
      iconBg: "bg-white/20",
    },
    {
      title: "Total Pelanggan",
      value: "0",
      icon: Users,
      bgColor: "bg-[#1e3a5f]",
      iconBg: "bg-white/20",
    },
    {
      title: "Verifikasi Mitra",
      value: "0",
      icon: ShieldCheck,
      bgColor: "bg-white border",
      iconBg: "bg-primary/10",
      textColor: "text-foreground",
      iconColor: "text-primary",
    },
    {
      title: "Verifikasi Pelanggan",
      value: "0",
      icon: UserCheck,
      bgColor: "bg-white border",
      iconBg: "bg-orange-100",
      textColor: "text-foreground",
      iconColor: "text-orange-500",
    },
  ]);

  const [chartData, setChartData] = useState<ChartDataItem[]>([
    { name: "Nebeng Mobil", value: 0, color: "#1e3a5f" },
    { name: "Nebeng Motor", value: 0, color: "#1e3a5f" },
    { name: "Nebeng Barang", value: 0, color: "#6366f1" },
    { name: "Titip Barang", value: 0, color: "#6366f1" },
  ]);

  const [tujuanData, setTujuanData] = useState<DestinationData[]>([]);
  const [mitraData, setMitraData] = useState<MitraData[]>([]);
  const [allMitraData, setAllMitraData] = useState<MitraData[]>([]);
  const [showAllMitra, setShowAllMitra] = useState(false);
  const [isLoading, setIsLoading] = useState(true);
  const [isFilterLoading, setIsFilterLoading] = useState(false);
  const [selectedMonth, setSelectedMonth] = useState(new Date().getMonth() + 1);
  const [selectedYear, setSelectedYear] = useState(new Date().getFullYear());

  // Function to fetch all mitra data
  const fetchAllMitraData = async () => {
    try {
      const response = await dashboardApi.getAllMitra();
      setAllMitraData(response.data);
    } catch (error) {
      console.error('Failed to fetch all mitra data:', error);
    }
  };

  // Fetch dashboard data on component mount
  useEffect(() => {
    const fetchDashboardData = async () => {
      try {
        setIsLoading(true);

        // Fetch stats
        const statsResponse = await dashboardApi.getStats();
        const stats = statsResponse.data;

        setStatsData([
          {
            title: "Total Mitra",
            value: stats.totalMitra.toLocaleString(),
            icon: Briefcase,
            bgColor: "bg-[#1e3a5f]",
            iconBg: "bg-white/20",
          },
          {
            title: "Total Pelanggan",
            value: stats.totalCustomer.toLocaleString(),
            icon: Users,
            bgColor: "bg-[#1e3a5f]",
            iconBg: "bg-white/20",
          },
          {
            title: "Verifikasi Mitra",
            value: stats.verifiedMitra.toLocaleString(),
            icon: ShieldCheck,
            bgColor: "bg-white border",
            iconBg: "bg-primary/10",
            textColor: "text-foreground",
            iconColor: "text-primary",
          },
          {
            title: "Verifikasi Pelanggan",
            value: stats.verifiedCustomer.toLocaleString(),
            icon: UserCheck,
            bgColor: "bg-white border",
            iconBg: "bg-orange-100",
            textColor: "text-foreground",
            iconColor: "text-orange-500",
          },
        ]);

      } catch (error) {
        console.error('Failed to fetch dashboard data:', error);
      } finally {
        setIsLoading(false);
      }
    };

    fetchDashboardData();
  }, []);

  // Fetch filtered data when month/year changes (realtime without reload)
  useEffect(() => {
    const fetchFilteredData = async () => {
      // Skip initial load as it's handled by the first useEffect
      if (isLoading) return;

      try {
        setIsFilterLoading(true);

        // Fetch chart data for selected month/year
        const chartResponse = await dashboardApi.getOrderChart(selectedMonth, selectedYear);
        setChartData(chartResponse.data.data);

        // Fetch top destinations for selected month/year
        const destinationsResponse = await dashboardApi.getTopDestinations(selectedMonth, selectedYear);
        setTujuanData(destinationsResponse.data);

        // Fetch mitra registered in selected month/year
        const mitraResponse = await dashboardApi.getRecentMitra(selectedMonth, selectedYear);
        setMitraData(mitraResponse.data);

      } catch (error) {
        console.error('Failed to fetch filtered data:', error);
      } finally {
        setIsFilterLoading(false);
      }
    };

    fetchFilteredData();
  }, [selectedMonth, selectedYear, isLoading]);

  if (isLoading) {
    return (
      <div className="space-y-6">
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
          {[...Array(4)].map((_, i) => (
            <Card key={i} className="shadow-sm">
              <CardContent className="p-6">
                <div className="animate-pulse">
                  <div className="h-4 bg-gray-200 rounded w-3/4 mb-2"></div>
                  <div className="h-8 bg-gray-200 rounded w-1/2"></div>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
        <div className="text-center py-8">Memuat data dashboard...</div>
      </div>
    );
  }

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
                ({chartData?.reduce((sum, item) => sum + item.value, 0) || 0} Pesanan)
              </span>
            </CardTitle>
            <div className="flex items-center gap-2">
              {isFilterLoading && (
                <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-primary"></div>
              )}
              <Select
                value={selectedMonth.toString()}
                onValueChange={(value) => setSelectedMonth(parseInt(value))}
              >
                <SelectTrigger className="w-24 h-8">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="1">Jan</SelectItem>
                  <SelectItem value="2">Feb</SelectItem>
                  <SelectItem value="3">Mar</SelectItem>
                  <SelectItem value="4">Apr</SelectItem>
                  <SelectItem value="5">Mei</SelectItem>
                  <SelectItem value="6">Jun</SelectItem>
                  <SelectItem value="7">Jul</SelectItem>
                  <SelectItem value="8">Ags</SelectItem>
                  <SelectItem value="9">Sep</SelectItem>
                  <SelectItem value="10">Okt</SelectItem>
                  <SelectItem value="11">Nov</SelectItem>
                  <SelectItem value="12">Des</SelectItem>
                </SelectContent>
              </Select>
              <Select
                value={selectedYear.toString()}
                onValueChange={(value) => setSelectedYear(parseInt(value))}
              >
                <SelectTrigger className="w-20 h-8">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="2023">2023</SelectItem>
                  <SelectItem value="2024">2024</SelectItem>
                  <SelectItem value="2025">2025</SelectItem>
                  <SelectItem value="2026">2026</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </CardHeader>
          <CardContent>
            <div className="relative min-h-[280px]">
              <div 
                className={`absolute inset-0 flex items-center justify-center transition-opacity duration-300 ${
                  isFilterLoading ? 'opacity-100 z-10' : 'opacity-0 -z-10'
                }`}
              >
                <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
              </div>
              <div 
                className={`transition-opacity duration-300 ${
                  isFilterLoading ? 'opacity-30' : 'opacity-100'
                }`}
              >
                <ResponsiveContainer width="100%" height={280}>
                  <BarChart data={chartData || []} barCategoryGap="20%">
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
                      domain={[0, 'dataMax + 50']}
                    />
                    <Bar dataKey="value" radius={[4, 4, 0, 0]}>
                      {(chartData || []).map((entry, index) => (
                        <Cell key={`cell-${index}`} fill={entry.color} />
                      ))}
                      <LabelList
                        dataKey="value"
                        position="top"
                        style={{ fontSize: 11, fill: "#666" }}
                      />
                    </Bar>
                  </BarChart>
                </ResponsiveContainer>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Tujuan Terbanyak */}
        <Card className="shadow-sm">
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-lg font-semibold">
              Tujuan Terbanyak
            </CardTitle>
            <div className="flex items-center gap-2">
              {isFilterLoading && (
                <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-primary"></div>
              )}
              <Select
                value={selectedMonth.toString()}
                onValueChange={(value) => setSelectedMonth(parseInt(value))}
              >
                <SelectTrigger className="w-24 h-8">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="1">Jan</SelectItem>
                  <SelectItem value="2">Feb</SelectItem>
                  <SelectItem value="3">Mar</SelectItem>
                  <SelectItem value="4">Apr</SelectItem>
                  <SelectItem value="5">Mei</SelectItem>
                  <SelectItem value="6">Jun</SelectItem>
                  <SelectItem value="7">Jul</SelectItem>
                  <SelectItem value="8">Ags</SelectItem>
                  <SelectItem value="9">Sep</SelectItem>
                  <SelectItem value="10">Okt</SelectItem>
                  <SelectItem value="11">Nov</SelectItem>
                  <SelectItem value="12">Des</SelectItem>
                </SelectContent>
              </Select>
              <Select
                value={selectedYear.toString()}
                onValueChange={(value) => setSelectedYear(parseInt(value))}
              >
                <SelectTrigger className="w-20 h-8">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="2023">2023</SelectItem>
                  <SelectItem value="2024">2024</SelectItem>
                  <SelectItem value="2025">2025</SelectItem>
                  <SelectItem value="2026">2026</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </CardHeader>
          <CardContent>
            <div className="relative min-h-[280px]">
              <div 
                className={`absolute inset-0 flex items-center justify-center transition-opacity duration-300 ${
                  isFilterLoading ? 'opacity-100 z-10' : 'opacity-0 -z-10'
                }`}
              >
                <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
              </div>
              <div 
                className={`transition-opacity duration-300 ${
                  isFilterLoading ? 'opacity-30' : 'opacity-100'
                }`}
              >
                <div className="overflow-x-auto">
                  <table className="w-full text-sm">
                    <thead>
                      <tr className="text-muted-foreground">
                        <th className="text-left py-2 font-medium">No</th>
                        <th className="text-left py-2 font-medium">Kota Asal</th>
                        <th className="text-left py-2 font-medium">Kota Tujuan</th>
                        <th className="text-right py-2 font-medium">Tot. Perjalanan</th>
                      </tr>
                    </thead>
                    <tbody>
                      {tujuanData.map((item) => (
                        <tr key={item.no} className="border-t border-border/50">
                          <td className="py-2">{item.no}.</td>
                          <td className="py-2">{item.kotaAsal}</td>
                          <td className="py-2">{item.kotaTujuan}</td>
                          <td className="py-2 text-right">{item.total}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Data Mitra Table */}
      <Card className="shadow-sm">
        <CardHeader className="flex flex-row items-center justify-between pb-2">
          <CardTitle className="text-lg font-semibold">Data Mitra</CardTitle>
          <div className="flex items-center gap-2">
            {isFilterLoading && (
              <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-primary"></div>
            )}
            <Select
              value={selectedMonth.toString()}
              onValueChange={(value) => setSelectedMonth(parseInt(value))}
            >
              <SelectTrigger className="w-24 h-8">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="1">Jan</SelectItem>
                <SelectItem value="2">Feb</SelectItem>
                <SelectItem value="3">Mar</SelectItem>
                <SelectItem value="4">Apr</SelectItem>
                <SelectItem value="5">Mei</SelectItem>
                <SelectItem value="6">Jun</SelectItem>
                <SelectItem value="7">Jul</SelectItem>
                <SelectItem value="8">Ags</SelectItem>
                <SelectItem value="9">Sep</SelectItem>
                <SelectItem value="10">Okt</SelectItem>
                <SelectItem value="11">Nov</SelectItem>
                <SelectItem value="12">Des</SelectItem>
              </SelectContent>
            </Select>
            <Select
              value={selectedYear.toString()}
              onValueChange={(value) => setSelectedYear(parseInt(value))}
            >
              <SelectTrigger className="w-20 h-8">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="2023">2023</SelectItem>
                <SelectItem value="2024">2024</SelectItem>
                <SelectItem value="2025">2025</SelectItem>
                <SelectItem value="2026">2026</SelectItem>
              </SelectContent>
            </Select>
            <Button
              variant="link"
              size="sm"
              className="text-primary"
              onClick={async () => {
                if (!showAllMitra) {
                  await fetchAllMitraData();
                }
                setShowAllMitra(!showAllMitra);
              }}
            >
              {showAllMitra ? 'Sembunyikan' : 'Lihat Lebih'}
            </Button>
          </div>
        </CardHeader>
        <CardContent>
          <div className="relative min-h-[200px]">
            <div 
              className={`absolute inset-0 flex items-center justify-center transition-opacity duration-300 ${
                isFilterLoading ? 'opacity-100 z-10' : 'opacity-0 -z-10'
              }`}
            >
              <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
            </div>
            <div 
              className={`transition-opacity duration-300 ${
                isFilterLoading ? 'opacity-30' : 'opacity-100'
              }`}
            >
              <div className="overflow-x-auto">
                <table className="w-full text-sm">
                  <thead>
                    <tr className="text-muted-foreground border-b">
                      <th className="text-left py-3 font-medium">NO. ID</th>
                      <th className="text-left py-3 font-medium">NAMA</th>
                      <th className="text-left py-3 font-medium">EMAIL</th>
                      <th className="text-left py-3 font-medium">NO. TLP</th>
                      <th className="text-left py-3 font-medium">JENIS KELAMIN</th>
                      <th className="text-left py-3 font-medium">STATUS</th>
                      <th className="text-center py-3 font-medium">AKSI</th>
                    </tr>
                  </thead>
                  <tbody>
                    {(showAllMitra ? allMitraData : mitraData).map((mitra, index) => (
                      <tr key={index} className="border-b border-border/50">
                        <td className="py-4">{mitra.id}</td>
                        <td className="py-4">{mitra.nama}</td>
                        <td className="py-4">{mitra.email}</td>
                        <td className="py-4">{mitra.noTlp}</td>
                        <td className="py-4">{mitra.gender || '-'}</td>
                        <td className="py-4">
                          <Badge className={`${getStatusColor(mitra.status)} text-white text-xs`}>
                            {mitra.status}
                          </Badge>
                        </td>
                        <td className="py-4 text-center">
                          <Button variant="ghost" size="icon" className="h-8 w-8">
                            <Eye size={18} className="text-primary" />
                          </Button>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
};

export default Dashboard;
