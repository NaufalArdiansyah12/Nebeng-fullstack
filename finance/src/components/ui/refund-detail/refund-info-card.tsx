import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";

interface RefundInfoCardProps {
  refundReason: string;
  totalAmount: number;
  adminFee: string;
  refundAmount: number;
  calculatedRefund: number;
  status: string;
  rejectionReason: string | null;
  formatCurrency: (amount: number) => string;
  onAdminFeeChange: (value: string) => void;
}

export const RefundInfoCard = ({ 
  refundReason,
  totalAmount,
  adminFee,
  refundAmount,
  calculatedRefund,
  status,
  rejectionReason,
  formatCurrency,
  onAdminFeeChange
}: RefundInfoCardProps) => {
  return (
    <div className="bg-background border border-border rounded-xl p-6">
      <h3 className="font-semibold mb-4">Informasi Refund</h3>
      <div className="space-y-4">
        <div>
          <label className="text-xs text-muted-foreground mb-1.5 block">Alasan Refund</label>
          <Textarea 
            disabled 
            value={refundReason} 
            className="bg-muted resize-none" 
            rows={3}
          />
        </div>

        <div className="grid grid-cols-3 gap-4">
          <div>
            <label className="text-xs text-muted-foreground mb-1.5 block">Total Amount</label>
            <Input 
              disabled 
              value={formatCurrency(totalAmount)} 
              className="bg-muted font-semibold" 
            />
          </div>
          <div>
            <label className="text-xs text-muted-foreground mb-1.5 block">Biaya Admin</label>
            <Input 
              disabled={status !== 'pending'} 
              value={formatCurrency(parseFloat(adminFee || "0"))} 
              onChange={(e) => {
                const value = e.target.value.replace(/[^0-9]/g, '');
                onAdminFeeChange(value);
              }}
              className={status === 'pending' ? '' : 'bg-muted'}
            />
          </div>
          <div>
            <label className="text-xs text-muted-foreground mb-1.5 block">Jumlah Refund</label>
            <Input 
              disabled 
              value={formatCurrency(status === 'pending' ? calculatedRefund : refundAmount)} 
              className="bg-muted font-semibold text-green-600" 
            />
          </div>
        </div>

        {rejectionReason && (
          <div>
            <label className="text-xs text-muted-foreground mb-1.5 block">Alasan Penolakan</label>
            <Textarea 
              disabled 
              value={rejectionReason} 
              className="bg-red-50 border-red-200 text-red-600 resize-none" 
              rows={2}
            />
          </div>
        )}
      </div>
    </div>
  );
};
