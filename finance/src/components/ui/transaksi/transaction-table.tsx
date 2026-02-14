import { Eye } from "lucide-react";
import { Button } from "@/components/ui/button";
import { useNavigate } from "react-router-dom";
import { mapStatus, getStatusColor, formatDate, generateOrderNumber, getServiceType } from "@/lib/transaction-utils";

type Transaction = {
  id: number;
  tanggal: string;
  driver: string | null;
  customer: string;
  booking_number: string;
  jenis: string;
  service_type?: string;
  status: "pending" | "paid" | "cancelled";
};

interface TransactionTableProps {
  transactions: Transaction[];
  startIndex: number;
}

export const TransactionTable = ({ transactions, startIndex }: TransactionTableProps) => {
  const navigate = useNavigate();

  return (
    <div className="overflow-x-auto">
      <table className="w-full">
        <thead className="bg-muted/30 border-b">
          <tr>
            <th className="px-6 py-3 text-left text-xs font-semibold text-muted-foreground uppercase tracking-wider">
              NO.
            </th>
            <th className="px-6 py-3 text-left text-xs font-semibold text-muted-foreground uppercase tracking-wider">
              TANGGAL
            </th>
            <th className="px-6 py-3 text-left text-xs font-semibold text-muted-foreground uppercase tracking-wider">
              NAMA DRIVER
            </th>
            <th className="px-6 py-3 text-left text-xs font-semibold text-muted-foreground uppercase tracking-wider">
              NAMA COSTUMER
            </th>
            <th className="px-6 py-3 text-left text-xs font-semibold text-muted-foreground uppercase tracking-wider">
              JENIS TEBENGAN
            </th>
            <th className="px-6 py-3 text-left text-xs font-semibold text-muted-foreground uppercase tracking-wider">
              SERVICE TYPE
            </th>
            <th className="px-6 py-3 text-left text-xs font-semibold text-muted-foreground uppercase tracking-wider">
              NO. TRANSAKSI
            </th>
            <th className="px-6 py-3 text-left text-xs font-semibold text-muted-foreground uppercase tracking-wider">
              NO. ORDERAN
            </th>
            <th className="px-6 py-3 text-left text-xs font-semibold text-muted-foreground uppercase tracking-wider">
              STATUS
            </th>
            <th className="px-6 py-3 text-left text-xs font-semibold text-muted-foreground uppercase tracking-wider">
              AKSI
            </th>
          </tr>
        </thead>
        <tbody className="bg-background divide-y divide-border">
          {transactions.map((tx, i) => {
            const statusText = mapStatus(tx.status);
            return (
              <tr
                key={tx.id}
                className="hover:bg-muted/20 transition-colors"
              >
                <td className="px-6 py-4 whitespace-nowrap text-sm">
                  {startIndex + i + 1}
                </td>
                <td className="px-6 py-4 whitespace-nowrap text-sm">
                  {formatDate(tx.tanggal)}
                </td>
                <td className="px-6 py-4 whitespace-nowrap text-sm">
                  {tx.driver || "Maulana Injil"}
                </td>
                <td className="px-6 py-4 whitespace-nowrap text-sm">
                  {tx.customer}
                </td>
                <td className="px-6 py-4 whitespace-nowrap text-sm">
                  {tx.jenis}
                </td>
                <td className="px-6 py-4 whitespace-nowrap text-sm">
                  {getServiceType(tx.jenis, tx.service_type)}
                </td>
                <td className="px-6 py-4 whitespace-nowrap text-sm font-mono">
                  {tx.booking_number}
                </td>
                <td className="px-6 py-4 whitespace-nowrap text-sm font-mono">
                  {generateOrderNumber(tx.booking_number)}
                </td>
                <td className="px-6 py-4 whitespace-nowrap">
                  <span
                    className={`inline-flex items-center px-3 py-1 rounded-full text-xs font-semibold text-white ${getStatusColor(
                      statusText
                    )}`}
                  >
                    {statusText}
                  </span>
                </td>
                <td className="px-6 py-4 whitespace-nowrap">
                  <Button
                    size="icon"
                    variant="ghost"
                    className="h-9 w-9 rounded-lg bg-muted hover:bg-primary hover:text-white transition-colors"
                    onClick={() => navigate(`/transactions/${tx.id}`)}
                  >
                    <Eye className="h-4 w-4" />
                  </Button>
                </td>
              </tr>
            );
          })}

          {transactions.length === 0 && (
            <tr>
              <td
                colSpan={10}
                className="text-center py-8 text-muted-foreground text-sm"
              >
                Tidak ada data transaksi
              </td>
            </tr>
          )}
        </tbody>
      </table>
    </div>
  );
};
