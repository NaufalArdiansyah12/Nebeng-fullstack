import { Eye } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { useNavigate } from "react-router-dom";
import { statusColors, statusLabels } from "@/lib/withdrawal-utils";

interface Withdrawal {
  id: number;
  transaction_id: string;
  user_name: string;
  user_email: string;
  amount: number;
  admin_fee: number;
  total_amount: number;
  status: string;
  type: "mitra" | "posmitra";
  created_at: string;
}

interface WithdrawalTableProps {
  data: Withdrawal[];
  loading: boolean;
  formatCurrency: (amount: number) => string;
  formatDate: (dateString: string) => string;
}

export const WithdrawalTable = ({ data, loading, formatCurrency, formatDate }: WithdrawalTableProps) => {
  const navigate = useNavigate();

  return (
    <div className="overflow-x-auto">
      <table className="w-full">
        <thead className="bg-muted/50">
          <tr>
            <th className="px-5 py-3 text-left text-xs font-medium text-muted-foreground uppercase tracking-wide">
              ID Transaksi
            </th>
            <th className="px-5 py-3 text-left text-xs font-medium text-muted-foreground uppercase tracking-wide">
              Nama
            </th>
            <th className="px-5 py-3 text-left text-xs font-medium text-muted-foreground uppercase tracking-wide">
              Tipe
            </th>
            <th className="px-5 py-3 text-left text-xs font-medium text-muted-foreground uppercase tracking-wide">
              Jumlah
            </th>
            <th className="px-5 py-3 text-left text-xs font-medium text-muted-foreground uppercase tracking-wide">
              Tanggal
            </th>
            <th className="px-5 py-3 text-left text-xs font-medium text-muted-foreground uppercase tracking-wide">
              Status
            </th>
            <th className="px-5 py-3 text-left text-xs font-medium text-muted-foreground uppercase tracking-wide">
              Aksi
            </th>
          </tr>
        </thead>
        <tbody>
          {loading ? (
            <tr>
              <td colSpan={7} className="px-5 py-8 text-center text-muted-foreground">
                Loading...
              </td>
            </tr>
          ) : data.length === 0 ? (
            <tr>
              <td colSpan={7} className="px-5 py-8 text-center text-muted-foreground">
                Tidak ada data penarikan
              </td>
            </tr>
          ) : (
            data.map((item) => (
              <tr
                key={`${item.type}-${item.id}`}
                className="border-b border-border hover:bg-muted/30 transition-colors"
              >
                <td className="px-5 py-4 text-sm font-mono">
                  {item.transaction_id}
                </td>
                <td className="px-5 py-4">
                  <div>
                    <p className="text-sm font-medium">{item.user_name}</p>
                    <p className="text-xs text-muted-foreground">{item.user_email}</p>
                  </div>
                </td>
                <td className="px-5 py-4">
                  <Badge variant="outline" className="capitalize">
                    {item.type === "posmitra" ? "Pos Mitra" : "Mitra"}
                  </Badge>
                </td>
                <td className="px-5 py-4 text-sm font-semibold">
                  {formatCurrency(item.total_amount)}
                </td>
                <td className="px-5 py-4 text-sm text-muted-foreground">
                  {formatDate(item.created_at)}
                </td>
                <td className="px-5 py-4">
                  <Badge
                    className={`border ${statusColors[item.status]}`}
                    variant="outline"
                  >
                    {statusLabels[item.status]}
                  </Badge>
                </td>
                <td className="px-5 py-4">
                  <Button
                    size="icon"
                    variant="ghost"
                    className="hover:bg-primary hover:text-white transition-colors"
                    onClick={() => navigate(`/withdrawals/${item.id}?type=${item.type}`)}
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
