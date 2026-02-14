import { Eye } from "lucide-react";
import { Button } from "@/components/ui/button";
import { useNavigate } from "react-router-dom";

interface Refund {
  id: number;
  booking_id: number;
  booking_type: string;
  customer_name: string;
  customer_email: string;
  customer_phone: string;
  refund_reason: string;
  total_amount: number;
  refund_amount: number;
  admin_fee: number;
  bank_name: string;
  account_number: string;
  account_holder_name: string;
  status: "pending" | "approved" | "processing" | "completed" | "rejected";
  submitted_at: string;
  created_at: string;
}

interface RefundTableProps {
  data: Refund[];
  loading: boolean;
  formatCurrency: (amount: number) => string;
  formatDate: (dateString: string) => string;
}

const statusColors = {
  pending: "bg-yellow-100 text-yellow-800 border-yellow-200",
  approved: "bg-blue-100 text-blue-800 border-blue-200",
  processing: "bg-purple-100 text-purple-800 border-purple-200",
  completed: "bg-green-100 text-green-800 border-green-200",
  rejected: "bg-red-100 text-red-800 border-red-200",
};

const statusLabels = {
  pending: "Menunggu",
  approved: "Disetujui",
  processing: "Diproses",
  completed: "Selesai",
  rejected: "Ditolak",
};

export const RefundTable = ({ data, loading, formatCurrency, formatDate }: RefundTableProps) => {
  const navigate = useNavigate();

  return (
    <div className="overflow-x-auto">
      <table className="w-full">
        <thead className="bg-muted/50">
          <tr>
            <th className="px-5 py-3 text-left text-xs text-muted-foreground">ID</th>
            <th className="px-5 py-3 text-left text-xs text-muted-foreground">CUSTOMER</th>
            <th className="px-5 py-3 text-left text-xs text-muted-foreground">BOOKING ID</th>
            <th className="px-5 py-3 text-left text-xs text-muted-foreground">TIPE</th>
            <th className="px-5 py-3 text-left text-xs text-muted-foreground">ALASAN</th>
            <th className="px-5 py-3 text-left text-xs text-muted-foreground">JUMLAH REFUND</th>
            <th className="px-5 py-3 text-left text-xs text-muted-foreground">STATUS</th>
            <th className="px-5 py-3 text-left text-xs text-muted-foreground">TANGGAL</th>
            <th className="px-5 py-3 text-left text-xs text-muted-foreground">AKSI</th>
          </tr>
        </thead>
        <tbody>
          {loading ? (
            <tr>
              <td colSpan={9} className="px-5 py-8 text-center text-muted-foreground">
                Memuat data...
              </td>
            </tr>
          ) : data.length === 0 ? (
            <tr>
              <td colSpan={9} className="px-5 py-8 text-center text-muted-foreground">
                Data refund tidak ditemukan
              </td>
            </tr>
          ) : (
            data.map((refund) => (
              <tr
                key={refund.id}
                className="border-b border-border hover:bg-muted/30"
              >
                <td className="px-5 py-4 text-sm">#{refund.id}</td>
                <td className="px-5 py-4 text-sm">
                  <div>
                    <p className="font-medium">{refund.customer_name}</p>
                    <p className="text-xs text-muted-foreground">{refund.customer_email}</p>
                  </div>
                </td>
                <td className="px-5 py-4 text-sm">{refund.booking_id}</td>
                <td className="px-5 py-4 text-sm capitalize">{refund.booking_type}</td>
                <td className="px-5 py-4 text-sm max-w-xs truncate">
                  {refund.refund_reason}
                </td>
                <td className="px-5 py-4 text-sm font-medium">
                  {formatCurrency(refund.refund_amount)}
                </td>
                <td className="px-5 py-4">
                  <span
                    className={`inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium border ${
                      statusColors[refund.status]
                    }`}
                  >
                    {statusLabels[refund.status]}
                  </span>
                </td>
                <td className="px-5 py-4 text-sm text-muted-foreground">
                  {formatDate(refund.created_at)}
                </td>
                <td className="px-5 py-4">
                  <Button
                    size="icon"
                    variant="ghost"
                    onClick={() => navigate(`/refund/${refund.id}`)}
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
