import { CheckCircle, XCircle, Loader2 } from "lucide-react";
import { Button } from "@/components/ui/button";

interface ActionCardProps {
  status: "pending" | "approved" | "processing" | "completed" | "rejected";
  actionLoading: boolean;
  onApprove: () => void;
  onReject: () => void;
  onProcess: () => void;
  onComplete: () => void;
}

export const ActionCard = ({ 
  status, 
  actionLoading, 
  onApprove, 
  onReject, 
  onProcess, 
  onComplete 
}: ActionCardProps) => {
  return (
    <div className="bg-background border border-border rounded-xl p-6 shadow-sm">
      <h3 className="font-semibold text-base mb-5 pb-3 border-b">Aksi</h3>
      <div className="space-y-3">
        {status === "pending" && (
          <>
            <Button
              className="w-full"
              onClick={onApprove}
              disabled={actionLoading}
            >
              <CheckCircle className="w-4 h-4 mr-2" />
              Setujui Refund
            </Button>
            <Button
              variant="destructive"
              className="w-full"
              onClick={onReject}
              disabled={actionLoading}
            >
              <XCircle className="w-4 h-4 mr-2" />
              Tolak Refund
            </Button>
          </>
        )}

        {status === "approved" && (
          <Button
            className="w-full"
            onClick={onProcess}
            disabled={actionLoading}
          >
            {actionLoading ? (
              <Loader2 className="w-4 h-4 mr-2 animate-spin" />
            ) : (
              <Loader2 className="w-4 h-4 mr-2" />
            )}
            Proses Refund
          </Button>
        )}

        {status === "processing" && (
          <Button
            className="w-full"
            onClick={onComplete}
            disabled={actionLoading}
          >
            {actionLoading ? (
              <Loader2 className="w-4 h-4 mr-2 animate-spin" />
            ) : (
              <CheckCircle className="w-4 h-4 mr-2" />
            )}
            Selesaikan Refund
          </Button>
        )}

        {(status === "completed" || status === "rejected") && (
          <div className="text-center text-sm text-muted-foreground py-2">
            Refund sudah {status === "completed" ? "diselesaikan" : "ditolak"}
          </div>
        )}
      </div>
    </div>
  );
};
