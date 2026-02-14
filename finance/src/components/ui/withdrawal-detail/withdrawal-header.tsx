import { ChevronLeft } from "lucide-react";
import { Button } from "@/components/ui/button";
import { statusColors, statusLabels } from "@/lib/withdrawal-utils";

interface WithdrawalHeaderProps {
  withdrawalId: number;
  transactionId: string;
  status: string;
  onBack: () => void;
}

export const WithdrawalHeader = ({ withdrawalId, transactionId, status, onBack }: WithdrawalHeaderProps) => {
  return (
    <div className="flex items-center justify-between mb-6">
      <div className="flex items-center gap-3">
        <Button variant="ghost" size="icon" onClick={onBack}>
          <ChevronLeft />
        </Button>
        <div>
          <h2 className="font-semibold text-lg">Detail Penarikan #{withdrawalId}</h2>
          <p className="text-sm text-muted-foreground">{transactionId}</p>
        </div>
      </div>

      <span
        className={`inline-flex items-center px-3 py-1.5 rounded-full text-sm font-medium border ${
          statusColors[status]
        }`}
      >
        {statusLabels[status]}
      </span>
    </div>
  );
};
