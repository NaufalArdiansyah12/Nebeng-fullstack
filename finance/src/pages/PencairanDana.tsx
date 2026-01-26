import { Eye, Search } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import DashboardLayout from "@/components/DashboardLayout";
import { Badge } from "@/components/ui/badge";
import { useNavigate } from "react-router-dom";

const pencairanData = [
  {
    id: "0091",
    nama: "Muhammad Abdul",
    kode: "asdasj45",
    saldo: "Rp. 600.000,-",
    jumlah: "Rp. 200.000,-",
    status: "proses",
  },
  {
    id: "0092",
    nama: "Muhammad Abdul",
    kode: "asdasj45",
    saldo: "Rp. 600.000,-",
    jumlah: "Rp. 200.000,-",
    status: "selesai",
  },
  {
    id: "0093",
    nama: "Muhammad Abdul",
    kode: "asdasj45",
    saldo: "Rp. 600.000,-",
    jumlah: "Rp. 200.000,-",
    status: "batal",
  },
];

const statusBadge = (status: string) => {
  switch (status) {
    case "proses":
      return <Badge className="bg-yellow-400 text-black">PROSES</Badge>;
    case "selesai":
      return <Badge className="bg-green-500">SELESAI</Badge>;
    case "batal":
      return <Badge className="bg-red-500">BATAL</Badge>;
    default:
      return <Badge>-</Badge>;
  }
};

const PencairanDana = () => {
  const navigate = useNavigate();

  return (
    <DashboardLayout title="Pencairan Dana">
      <div className="bg-background border border-border rounded-xl">
        {/* Header */}
        <div className="p-5 border-b border-border flex items-center justify-between">
          <h3 className="font-semibold">Daftar Pencairan</h3>

          <div className="flex items-center gap-3">
            <div className="relative w-64">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
              <Input placeholder="Search" className="pl-9" />
            </div>

            <Button variant="outline" size="sm">
              Status
            </Button>
          </div>
        </div>

        {/* Table */}
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-muted/50">
              <tr>
                <th className="px-5 py-3 text-left text-xs text-muted-foreground">ID</th>
                <th className="px-5 py-3 text-left text-xs text-muted-foreground">NAMA POS MITRA</th>
                <th className="px-5 py-3 text-left text-xs text-muted-foreground">KODE REFERRAL</th>
                <th className="px-5 py-3 text-left text-xs text-muted-foreground">SALDO SAAT INI</th>
                <th className="px-5 py-3 text-left text-xs text-muted-foreground">JUMLAH PENCAIRAN</th>
                <th className="px-5 py-3 text-left text-xs text-muted-foreground">STATUS</th>
                <th className="px-5 py-3 text-left text-xs text-muted-foreground">AKSI</th>
              </tr>
            </thead>
            <tbody>
              {pencairanData.map((item) => (
                <tr
                  key={item.id}
                  className="border-b border-border hover:bg-muted/30"
                >
                  <td className="px-5 py-4 text-sm">{item.id}</td>
                  <td className="px-5 py-4 text-sm font-medium">{item.nama}</td>
                  <td className="px-5 py-4 text-sm">{item.kode}</td>
                  <td className="px-5 py-4 text-sm">{item.saldo}</td>
                  <td className="px-5 py-4 text-sm">{item.jumlah}</td>
                  <td className="px-5 py-4">{statusBadge(item.status)}</td>
                  <td className="px-5 py-4">
                    <Button
                      size="icon"
                      variant="ghost"
                      onClick={() => navigate(`/pencairan/${item.id}`)}
                    >
                      <Eye className="w-4 h-4" />
                    </Button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        {/* Pagination */}
        <div className="p-4 flex items-center justify-between text-sm text-muted-foreground">
          <span>10 of 120 entries</span>
          <div className="flex items-center gap-2">
            <Button variant="outline" size="sm">‹</Button>
            <Button variant="outline" size="sm">1</Button>
            <Button variant="outline" size="sm">2</Button>
            <Button variant="outline" size="sm">3</Button>
            <Button variant="outline" size="sm">›</Button>
          </div>
        </div>
      </div>
    </DashboardLayout>
  );
};

export default PencairanDana;
