import { Input } from "@/components/ui/input";

interface WithdrawalInfoCardProps {
  amount: number;
  adminFee: string;
  totalAmount: number;
  calculatedTotal: number;
  status: string;
  rejectionReason: string | null;
  notes: string | null;
  formatCurrency: (amount: number) => string;
  onAdminFeeChange: (value: string) => void;
}

export const WithdrawalInfoCard = ({
  amount,
  adminFee,
  totalAmount,
  calculatedTotal,
  status,
  rejectionReason,
  notes,
  formatCurrency,
  onAdminFeeChange,
}: WithdrawalInfoCardProps) => {
  return (
    <div className="bg-background border border-border rounded-xl p-6 shadow-sm">
      <h3 className="font-semibold text-base mb-5 pb-3 border-b">Informasi Penarikan</h3>
      <div className="space-y-5">
        <div className="bg-muted/50 rounded-lg p-4">
          <div className="grid grid-cols-3 gap-4">
            <div>
              <label className="text-xs font-medium text-muted-foreground mb-2 block uppercase tracking-wide">
                Jumlah Penarikan
              </label>
              <div className="text-lg font-bold">{formatCurrency(amount)}</div>
            </div>
            <div>
              <label className="text-xs font-medium text-muted-foreground mb-2 block uppercase tracking-wide">
                Biaya Admin
              </label>
              {status === 'pending' || status === 'verifying' ? (
                <Input 
                  type="text"
                  value={formatCurrency(parseFloat(adminFee || "0"))} 
                  onChange={(e) => {
                    const value = e.target.value.replace(/[^0-9]/g, '');
                    onAdminFeeChange(value);
                  }}
                  className="h-8 text-sm font-semibold text-red-600"
                />
              ) : (
                <div className="text-lg font-bold text-red-600">- {formatCurrency(parseFloat(adminFee || "0"))}</div>
              )}
            </div>
            <div>
              <label className="text-xs font-medium text-muted-foreground mb-2 block uppercase tracking-wide">
                Total Diterima
              </label>
              <div className="text-lg font-bold text-green-600">
                {formatCurrency(status === 'pending' || status === 'verifying' ? calculatedTotal : totalAmount)}
              </div>
            </div>
          </div>
        </div>

        {rejectionReason && (
          <div className="bg-red-50 border border-red-200 rounded-lg p-4">
            <label className="text-xs font-medium text-red-700 mb-2 block uppercase tracking-wide">
              Alasan Penolakan
            </label>
            <p className="text-sm text-red-700">{rejectionReason}</p>
          </div>
        )}

        {notes && (
          <div className="bg-blue-50 border border-blue-200 rounded-lg p-4">
            <label className="text-xs font-medium text-blue-700 mb-2 block uppercase tracking-wide">
              Catatan
            </label>
            <p className="text-sm text-blue-700">{notes}</p>
          </div>
        )}
      </div>
    </div>
  );
};
