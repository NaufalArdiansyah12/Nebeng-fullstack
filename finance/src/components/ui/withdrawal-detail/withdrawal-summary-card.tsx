interface WithdrawalSummaryCardProps {
  amount: number;
  adminFee: number;
  totalAmount: number;
  formatCurrency: (amount: number) => string;
}

export const WithdrawalSummaryCard = ({ amount, adminFee, totalAmount, formatCurrency }: WithdrawalSummaryCardProps) => {
  return (
    <div className="bg-gradient-to-br from-primary/5 to-primary/10 border border-primary/20 rounded-xl p-6 shadow-sm">
      <h3 className="font-semibold text-base mb-4 pb-3 border-b border-primary/20">Rincian Penarikan</h3>
      <div className="space-y-3">
        <div className="flex justify-between items-center py-2">
          <span className="text-sm text-muted-foreground">Jumlah Penarikan</span>
          <span className="font-bold text-base">{formatCurrency(amount)}</span>
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
              <span className="font-semibold text-sm">Total Diterima</span>
              <span className="font-bold text-primary text-2xl">
                {formatCurrency(totalAmount)}
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};
