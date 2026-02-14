import { Eye } from "lucide-react";
import { Button } from "@/components/ui/button";
import { useNavigate } from "react-router-dom";

interface PosMitra {
  id: number;
  nama: string;
  email: string;
  phone: string;
  terminal: string | null;
  alamat_terminal: string | null;
  kode_referral: string | null;
}

interface PosMitraTableProps {
  data: PosMitra[];
  loading: boolean;
  startIndex: number;
}

export const PosMitraTable = ({ data, loading, startIndex }: PosMitraTableProps) => {
  const navigate = useNavigate();

  return (
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
          {loading ? (
            <tr>
              <td colSpan={6} className="px-5 py-8 text-center text-muted-foreground">
                Memuat data...
              </td>
            </tr>
          ) : data.length === 0 ? (
            <tr>
              <td colSpan={6} className="px-5 py-8 text-center text-muted-foreground">
                Data Pos Mitra tidak ditemukan
              </td>
            </tr>
          ) : (
            data.map((p, i) => (
              <tr
                key={p.id}
                className="border-b border-border hover:bg-muted/30"
              >
                <td className="px-5 py-4 text-sm">{startIndex + i + 1}</td>
                <td className="px-5 py-4 text-sm font-medium">{p.nama}</td>
                <td className="px-5 py-4 text-sm">{p.kode_referral || "-"}</td>
                <td className="px-5 py-4 text-sm">{p.terminal || "-"}</td>
                <td className="px-5 py-4 text-sm max-w-md">
                  {p.alamat_terminal || "-"}
                </td>
                <td className="px-5 py-4">
                  <Button
                    size="icon"
                    variant="ghost"
                    onClick={() => navigate(`/pos-mitra/${p.id}`)}
                    className="text-muted-foreground hover:bg-primary hover:text-white"
                  >
                    <Eye className="w-4 h-4" />
                  </Button>
                </td>
              </tr>
            ))
          )}
        </tbody>
      </table>
    </div>
  );
};
