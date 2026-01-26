import { Eye, Search } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import DashboardLayout from "@/components/DashboardLayout";
import { useNavigate } from "react-router-dom";
import { useEffect, useState } from "react";
import api from "@/lib/api";

interface Mitra {
  id: number;
  nama: string | null;
  email: string | null;
  telp: string | null;
  layanan?: string | null;
}

const Mitra = () => {
  const navigate = useNavigate();
  const [mitraData, setMitraData] = useState<Mitra[]>([]);
  const [search, setSearch] = useState("");

  useEffect(() => {
    api
      .get("/users/mitra")
      .then(res => {
        setMitraData(res.data);
      })
      .catch(err => {
        console.error("gagal ambil data mitra:", err);
      });
  }, []);

  const filteredData = mitraData.filter(m =>
    m.nama?.toLowerCase().includes(search.toLowerCase())
  );

  return (
    <DashboardLayout title="Mitra">
      <div className="bg-background border border-border rounded-xl overflow-hidden">
        {/* Header */}
        <div className="p-5 border-b border-border flex items-center justify-between">
          <h3 className="font-semibold">Daftar Mitra</h3>

          <div className="relative w-64">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
            <Input
              placeholder="Search"
              className="pl-9"
              value={search}
              onChange={e => setSearch(e.target.value)}
            />
          </div>
        </div>

        {/* Table */}
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-muted/50">
              <tr>
                <th className="px-5 py-3 text-left text-xs text-muted-foreground">NO</th>
                <th className="px-5 py-3 text-left text-xs text-muted-foreground">NAMA</th>
                <th className="px-5 py-3 text-left text-xs text-muted-foreground">EMAIL</th>
                <th className="px-5 py-3 text-left text-xs text-muted-foreground">NO. TLP</th>
                <th className="px-5 py-3 text-left text-xs text-muted-foreground">LAYANAN</th>
                <th className="px-5 py-3 text-left text-xs text-muted-foreground">AKSI</th>
              </tr>
            </thead>
            <tbody>
              {filteredData.map((m, i) => (
                <tr key={m.id} className="border-b border-border hover:bg-muted/30">
                  <td className="px-5 py-4 text-sm">{i + 1}</td>
                  <td className="px-5 py-4 text-sm font-medium">
                    {m.nama ?? "-"}
                  </td>
                  <td className="px-5 py-4 text-sm">
                    {m.email ?? "-"}
                  </td>
                  <td className="px-5 py-4 text-sm">
                    {m.telp ?? "-"}
                  </td>
                  <td className="px-5 py-4 text-sm">
                    {m.layanan ?? "-"}
                  </td>
                  <td className="px-5 py-4">
                    <Button
                      variant="ghost"
                      size="icon"
                      onClick={() => navigate(`/mitra/${m.id}`)}
                    >
                      <Eye className="w-4 h-4" />
                    </Button>
                  </td>
                </tr>
              ))}

              {filteredData.length === 0 && (
                <tr>
                  <td colSpan={6} className="text-center py-6 text-muted-foreground">
                    data mitra tidak ditemukan
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>
    </DashboardLayout>
  );
};

export default Mitra;
