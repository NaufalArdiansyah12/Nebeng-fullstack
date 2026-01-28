import { Briefcase, Users, ShieldCheck, UserCheck, Eye, ChevronDown } from "lucide-react";
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

// Stats data
const statsData = [
  {
    title: "Total Mitra",
    value: "10.213",
    icon: Briefcase,
    bgColor: "bg-[#1e3a5f]",
    iconBg: "bg-white/20",
  },
  {
    title: "Total Pelanggan",
    value: "9.563",
    icon: Users,
    bgColor: "bg-[#1e3a5f]",
    iconBg: "bg-white/20",
  },
  {
    title: "Verifikasi Mitra",
    value: "10.213",
    icon: ShieldCheck,
    bgColor: "bg-white border",
    iconBg: "bg-primary/10",
    textColor: "text-foreground",
    iconColor: "text-primary",
  },
  {
    title: "Verifikasi Pelanggan",
    value: "9.563",
    icon: UserCheck,
    bgColor: "bg-white border",
    iconBg: "bg-orange-100",
    textColor: "text-foreground",
    iconColor: "text-orange-500",
  },
];

// Chart data
const chartData = [
  { name: "Nebeng Mobil", value: 120, color: "#1e3a5f" },
  { name: "Nebeng Motor", value: 80, color: "#1e3a5f" },
  { name: "Nebeng Barang", value: 580, color: "#6366f1" },
  { name: "Titip Barang", value: 450, color: "#6366f1" },
];

// Tujuan terbanyak data
const tujuanData = [
  { no: 1, kotaAsal: "Lampung", kotaTujuan: "Pontianak", total: "19.509" },
  { no: 2, kotaAsal: "Bandung", kotaTujuan: "Surabaya", total: "19.103" },
  { no: 3, kotaAsal: "Yogyakarta", kotaTujuan: "Padang", total: "15.800" },
  { no: 4, kotaAsal: "Denpasar", kotaTujuan: "Banjarmasin", total: "10.310" },
  { no: 5, kotaAsal: "Palembang", kotaTujuan: "Pekan Baru", total: "5.987" },
  { no: 6, kotaAsal: "Balikpapan", kotaTujuan: "Makassar", total: "5.250" },
  { no: 7, kotaAsal: "Manado", kotaTujuan: "Bengkulu", total: "5.229" },
];

// Data Mitra
const mitraData = [
  {
    id: "100092",
    nama: "Muhammda Abdul",
    email: "dul22345@gmail.com",
    noTlp: "089563245757",
    layanan: "Motor",
    status: "TERVERIFIKASI",
  },
  {
    id: "100092",
    nama: "Muhammda Abdul",
    email: "dul22345@gmail.com",
    noTlp: "089563245757",
    layanan: "Mobil",
    status: "DITOLAK",
  },
  {
    id: "100092",
    nama: "Muhammda Abdul",
    email: "dul22345@gmail.com",
    noTlp: "089563245757",
    layanan: "Titip Barang",
    status: "PENGAJUAN",
  },
];

const getStatusColor = (status: string) => {
  switch (status) {
    case "TERVERIFIKASI":
      return "bg-green-500 hover:bg-green-600";
    case "DITOLAK":
      return "bg-red-500 hover:bg-red-600";
    case "PENGAJUAN":
      return "bg-orange-500 hover:bg-orange-600";
    default:
      return "bg-gray-500";
  }
};

const Dashboard = () => {
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
                (5000 Pesanan)
              </span>
            </CardTitle>
            <Button variant="ghost" size="sm" className="text-muted-foreground">
              Jun 2025 <ChevronDown size={16} className="ml-1" />
            </Button>
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
                  domain={[0, 600]}
                  ticks={[0, 100, 200, 300, 400, 500, 600]}
                />
                <Bar dataKey="value" radius={[4, 4, 0, 0]}>
                  {chartData.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={entry.color} />
                  ))}
                  <LabelList
                    dataKey="value"
                    position="top"
                    formatter={(value: number) =>
                      value === 580 ? "78%" : ""
                    }
                    style={{ fontSize: 11, fill: "#fff" }}
                  />
                </Bar>
              </BarChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>

        {/* Tujuan Terbanyak */}
        <Card className="shadow-sm">
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-lg font-semibold">
              Tujuan Terbanyak
            </CardTitle>
            <Button variant="ghost" size="sm" className="text-muted-foreground">
              Jun 2025 <ChevronDown size={16} className="ml-1" />
            </Button>
          </CardHeader>
          <CardContent>
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
          </CardContent>
        </Card>
      </div>

      {/* Data Mitra Table */}
      <Card className="shadow-sm">
        <CardHeader className="flex flex-row items-center justify-between pb-2">
          <CardTitle className="text-lg font-semibold">Data Mitra</CardTitle>
          <div className="flex items-center gap-2">
            <Button variant="ghost" size="sm" className="text-muted-foreground">
              Jun 2025 <ChevronDown size={16} className="ml-1" />
            </Button>
            <Button variant="link" size="sm" className="text-primary">
              Lihat Lebih
            </Button>
          </div>
        </CardHeader>
        <CardContent>
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="text-muted-foreground border-b">
                  <th className="text-left py-3 font-medium">NO. ID</th>
                  <th className="text-left py-3 font-medium">NAMA</th>
                  <th className="text-left py-3 font-medium">EMAIL</th>
                  <th className="text-left py-3 font-medium">NO. TLP</th>
                  <th className="text-left py-3 font-medium">LAYANAN</th>
                  <th className="text-left py-3 font-medium">STATUS</th>
                  <th className="text-center py-3 font-medium">AKSI</th>
                </tr>
              </thead>
              <tbody>
                {mitraData.map((mitra, index) => (
                  <tr key={index} className="border-b border-border/50">
                    <td className="py-4">{mitra.id}</td>
                    <td className="py-4">{mitra.nama}</td>
                    <td className="py-4">{mitra.email}</td>
                    <td className="py-4">{mitra.noTlp}</td>
                    <td className="py-4">{mitra.layanan}</td>
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
        </CardContent>
      </Card>
    </div>
  );
};

export default Dashboard;
