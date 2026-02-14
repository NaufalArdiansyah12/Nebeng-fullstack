import { Loader2 } from "lucide-react";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";

interface ProcessDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  bankName: string;
  accountNumber: string;
  accountHolderName: string;
  refundAmount: number;
  formatCurrency: (amount: number) => string;
  onConfirm: () => void;
  loading: boolean;
}

export const ProcessDialog = ({
  open,
  onOpenChange,
  bankName,
  accountNumber,
  accountHolderName,
  refundAmount,
  formatCurrency,
  onConfirm,
  loading,
}: ProcessDialogProps) => {
  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Proses Refund</DialogTitle>
          <DialogDescription>
            Pastikan informasi rekening tujuan sudah benar sebelum memproses transfer.
          </DialogDescription>
        </DialogHeader>
        <div className="space-y-4 py-4">
          <div className="bg-muted/50 rounded-lg p-4 space-y-3">
            <h4 className="font-semibold text-sm mb-3">Informasi Rekening Tujuan</h4>
            
            <div>
              <label className="text-xs text-muted-foreground mb-1 block">Nama Bank</label>
              <div className="bg-background border rounded-md px-3 py-2">
                <p className="font-semibold">{bankName}</p>
              </div>
            </div>
            
            <div>
              <label className="text-xs text-muted-foreground mb-1 block">Nomor Rekening</label>
              <div className="bg-background border rounded-md px-3 py-2">
                <p className="font-mono font-semibold">{accountNumber}</p>
              </div>
            </div>
            
            <div>
              <label className="text-xs text-muted-foreground mb-1 block">Nama Pemilik Rekening</label>
              <div className="bg-background border rounded-md px-3 py-2">
                <p className="font-semibold">{accountHolderName}</p>
              </div>
            </div>
          </div>

          <div className="bg-primary/10 border border-primary/20 rounded-lg p-4">
            <div className="flex justify-between items-center">
              <span className="text-sm font-medium">Jumlah yang akan ditransfer:</span>
              <span className="text-xl font-bold text-primary">
                {formatCurrency(refundAmount)}
              </span>
            </div>
          </div>

          <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-3">
            <p className="text-xs text-yellow-800">
              <strong>Perhatian:</strong> Pastikan Anda telah melakukan transfer ke rekening di atas sebelum mengklik tombol "Proses" di bawah ini.
            </p>
          </div>
        </div>
        <DialogFooter>
          <Button
            variant="outline"
            onClick={() => onOpenChange(false)}
            disabled={loading}
          >
            Batal
          </Button>
          <Button onClick={onConfirm} disabled={loading}>
            {loading && <Loader2 className="w-4 h-4 mr-2 animate-spin" />}
            Proses Transfer
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
};
