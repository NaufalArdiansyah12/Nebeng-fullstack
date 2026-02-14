import { ChevronLeft } from "lucide-react";
import { Button } from "@/components/ui/button";
import { detailStatusLabels, statusColors } from "@/lib/refund-utils";

interface RefundHeaderProps {
  refundId: number;
  bookingId: number;
  status: "pending" | "approved" | "processing" | "completed" | "rejected";
  onBack: () => void;
}

export const RefundHeader = ({ refundId, bookingId, status, onBack }: RefundHeaderProps) => {
  return (
    <div className="flex items-center justify-between mb-6">
      <div className="flex items-center gap-3">
        <Button variant="ghost" size="icon" onClick={onBack}>
          <ChevronLeft />
        </Button>
        <div>
          <h2 className="font-semibold text-lg">Detail Refund #{refundId}</h2>
          <p className="text-sm text-muted-foreground">
            Booking ID: {bookingId}
          </p>
        </div>
      </div>

      <span
        className={`inline-flex items-center px-3 py-1.5 rounded-full text-sm font-medium border ${
          statusColors[status]
        }`}
      >
        {detailStatusLabels[status]}
      </span>
    </div>
  );
};
