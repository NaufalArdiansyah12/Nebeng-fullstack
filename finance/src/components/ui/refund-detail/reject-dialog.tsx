import { Loader2 } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Textarea } from "@/components/ui/textarea";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";

interface RejectDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  rejectionReason: string;
  onReasonChange: (value: string) => void;
  onConfirm: () => void;
  loading: boolean;
}

export const RejectDialog = ({
  open,
  onOpenChange,
  rejectionReason,
  onReasonChange,
  onConfirm,
  loading,
}: RejectDialogProps) => {
  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Tolak Refund</DialogTitle>
          <DialogDescription>
            Berikan alasan penolakan yang jelas kepada customer.
          </DialogDescription>
        </DialogHeader>
        <div className="py-4">
          <label className="text-sm font-medium mb-2 block">Alasan Penolakan</label>
          <Textarea
            value={rejectionReason}
            onChange={(e) => onReasonChange(e.target.value)}
            placeholder="Jelaskan alasan penolakan refund..."
            rows={4}
          />
        </div>
        <DialogFooter>
          <Button
            variant="outline"
            onClick={() => onOpenChange(false)}
            disabled={loading}
          >
            Batal
          </Button>
          <Button
            variant="destructive"
            onClick={onConfirm}
            disabled={loading}
          >
            {loading && <Loader2 className="w-4 h-4 mr-2 animate-spin" />}
            Tolak
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
};
