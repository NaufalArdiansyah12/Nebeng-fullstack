import { Eye } from "lucide-react";
import { Button } from "../button";
import { useNavigate } from "react-router-dom";

interface Mitra {
  id: number;
  nama: string | null;
  email: string | null;
  telp: string | null;
}

interface MitraTableProps {
  data: Mitra[];
}

export function MitraTable({ data }: MitraTableProps) {
  const navigate = useNavigate();

  return (
    <div className="overflow-x-auto">
      <table className="w-full">
        <thead className="bg-muted/50">
          <tr>
            <th className="px-5 py-3 text-left text-xs text-muted-foreground">NO. ID</th>
            <th className="px-5 py-3 text-left text-xs text-muted-foreground">NAMA</th>
            <th className="px-5 py-3 text-left text-xs text-muted-foreground">EMAIL</th>
            <th className="px-5 py-3 text-left text-xs text-muted-foreground">NO. TLP</th>
            <th className="px-5 py-3 text-left text-xs text-muted-foreground">AKSI</th>
          </tr>
        </thead>
        <tbody>
          {data.map((m) => (
            <tr key={m.id} className="border-b border-border hover:bg-muted/30">
              <td className="px-5 py-4 text-sm">{m.id}</td>
              <td className="px-5 py-4 text-sm font-medium">
                {m.nama ?? "-"}
              </td>
              <td className="px-5 py-4 text-sm">
                {m.email ?? "-"}
              </td>
              <td className="px-5 py-4 text-sm">
                {m.telp ?? "-"}
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

          {data.length === 0 && (
            <tr>
              <td colSpan={5} className="text-center py-6 text-muted-foreground">
                data mitra tidak ditemukan
              </td>
            </tr>
          )}
        </tbody>
      </table>
    </div>
  );
}
