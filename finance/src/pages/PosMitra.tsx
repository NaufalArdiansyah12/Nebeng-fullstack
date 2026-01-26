import { Eye, Search } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import DashboardLayout from "@/components/DashboardLayout";
import { useNavigate } from "react-router-dom";

const posMitraData = [
  {
    id: "1",
    nama: "Muhammad Abdul",
    kode: "sssd23",
    terminal: "TERMINAL 1",
    alamat:
      "Jl. Jend. Sudirman No.296, Pereng, Sokarengga, Kec. Purwokerto Tim., Kabupaten Banyumas, Jawa Tengah 53116",
  },
  {
    id: "2",
    nama: "Muhammad Abdul",
    kode: "sssd23",
    terminal: "TERMINAL 2",
    alamat:
      "Jl. Jend. Sudirman No.296, Pereng, Sokarengga, Kec. Purwokerto Tim., Kabupaten Banyumas, Jawa Tengah 53116",
  },
];

const PosMitra = () => {
  const navigate = useNavigate();

  return (
    <DashboardLayout title="Pos Mitra">
      <div className="bg-background border border-border rounded-xl">
        {/* Header */}
        <div className="p-5 border-b border-border flex items-center justify-between">
          <h3 className="font-semibold">Daftar Pos Mitra</h3>

          <div className="relative w-64">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
            <Input placeholder="Search" className="pl-9" />
          </div>
        </div>

        {/* Table */}
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-muted/50">
              <tr>
                <th className="px-5 py-3 text-left text-xs text-muted-foreground">NO</th>
                <th className="px-5 py-3 text-left text-xs text-muted-foreground">NAMA</th>
                <th className="px-5 py-3 text-left text-xs text-muted-foreground">KODE REFERRAL</th>
                <th className="px-5 py-3 text-left text-xs text-muted-foreground">TERMINAL</th>
                <th className="px-5 py-3 text-left text-xs text-muted-foreground">ALAMAT TERMINAL</th>
                <th className="px-5 py-3 text-left text-xs text-muted-foreground">AKSI</th>
              </tr>
            </thead>
            <tbody>
              {posMitraData.map((p, i) => (
                <tr
                  key={p.id}
                  className="border-b border-border hover:bg-muted/30"
                >
                  <td className="px-5 py-4 text-sm">{i + 1}</td>
                  <td className="px-5 py-4 text-sm font-medium">{p.nama}</td>
                  <td className="px-5 py-4 text-sm">{p.kode}</td>
                  <td className="px-5 py-4 text-sm">{p.terminal}</td>
                  <td className="px-5 py-4 text-sm max-w-md">
                    {p.alamat}
                  </td>
                  <td className="px-5 py-4">
                    <Button
                      size="icon"
                      variant="ghost"
                      onClick={() => navigate(`/pos-mitra/${p.id}`)}
                    >
                      <Eye className="w-4 h-4" />
                    </Button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </DashboardLayout>
  );
};

export default PosMitra;
