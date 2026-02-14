interface RefundSummaryCardProps {
  totalAmount: number;
  adminFee: number;
  refundAmount: number;
  formatCurrency: (amount: number) => string;
}

export const RefundSummaryCard = ({ 
  totalAmount, 
  adminFee, 
  refundAmount, 
  formatCurrency 
}: RefundSummaryCardProps) => {
  return (
    <div className="bg-gradient-to-br from-primary/5 to-primary/10 border border-primary/20 rounded-xl p-6 shadow-sm">
      <h3 className="font-semibold text-base mb-4 pb-3 border-b border-primary/20">Rincian Dana Refund</h3>
      <div className="space-y-3">
        <div className="flex justify-between items-center py-2">
          <span className="text-sm text-muted-foreground">Total Dana Asli</span>
          <span className="font-bold text-base">{formatCurrency(totalAmount)}</span>
        </div>
        {adminFee > 0 && (
          <div className="flex justify-between items-center py-2">
            <span className="text-sm text-muted-foreground">Biaya Admin</span>
            <span className="font-bold text-base text-red-600">
              - {formatCurrency(adminFee)}
            </span>
          </div>
        )}
        <div className="border-t border-primary/20 pt-3 mt-3">
          <div className="bg-primary/10 rounded-lg p-4">
            <div className="flex justify-between items-center">
              <span className="font-semibold text-sm">Estimasi Refund</span>
              <span className="font-bold text-primary text-2xl">
                {formatCurrency(refundAmount)}
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};
