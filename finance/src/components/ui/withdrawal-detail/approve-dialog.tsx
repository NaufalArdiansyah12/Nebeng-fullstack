import { Loader2 } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";

interface ApproveDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  adminFee: string;
  onAdminFeeChange: (value: string) => void;
  amount: number;
  calculatedTotal: number;
  formatCurrency: (amount: number) => string;
  onConfirm: () => void;
  loading: boolean;
}

export const ApproveDialog = ({
  open,
  onOpenChange,
  adminFee,
  onAdminFeeChange,
  amount,
  calculatedTotal,
  formatCurrency,
  onConfirm,
  loading,
}: ApproveDialogProps) => {
  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Setujui Penarikan</DialogTitle>
          <DialogDescription>
            Pastikan semua informasi sudah benar sebelum menyetujui penarikan ini.
          </DialogDescription>
        </DialogHeader>
        <div className="space-y-4 py-4">
          <div>
            <label className="text-sm font-medium mb-2 block">Biaya Admin</label>
            <Input
              type="number"
              value={adminFee}
              onChange={(e) => onAdminFeeChange(e.target.value)}
              placeholder="Masukkan biaya admin"
            />
          </div>
          <div className="bg-muted p-4 rounded-lg space-y-2">
            <div className="flex justify-between text-sm">
              <span>Jumlah Penarikan:</span>
              <span className="font-medium">{formatCurrency(amount)}</span>
            </div>
            <div className="flex justify-between text-sm">
              <span>Biaya Admin:</span>
              <span className="font-medium">- {formatCurrency(parseFloat(adminFee || "0"))}</span>
            </div>
            <div className="flex justify-between text-base font-semibold border-t pt-2">
              <span>Total Diterima:</span>
              <span className="text-green-600">{formatCurrency(calculatedTotal)}</span>
            </div>
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
            Setujui
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
};
