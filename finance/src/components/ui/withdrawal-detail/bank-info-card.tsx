interface BankInfoCardProps {
  bankName: string;
  accountNumber: string;
  accountHolderName: string;
}

export const BankInfoCard = ({ bankName, accountNumber, accountHolderName }: BankInfoCardProps) => {
  return (
    <div className="bg-background border border-border rounded-xl p-6 shadow-sm">
      <h3 className="font-semibold text-base mb-5 pb-3 border-b">Informasi Rekening</h3>
      <div className="bg-gradient-to-br from-blue-50 to-indigo-50 rounded-lg p-5 border border-blue-100">
        <div className="grid grid-cols-3 gap-6">
          <div>
            <label className="text-xs font-medium text-blue-700 mb-2 block uppercase tracking-wide">
              Nama Bank
            </label>
            <div className="text-base font-bold text-blue-900">{bankName}</div>
          </div>
          <div>
            <label className="text-xs font-medium text-blue-700 mb-2 block uppercase tracking-wide">
              Nomor Rekening
            </label>
            <div className="text-base font-bold font-mono text-blue-900">{accountNumber}</div>
          </div>
          <div>
            <label className="text-xs font-medium text-blue-700 mb-2 block uppercase tracking-wide">
              Nama Pemilik
            </label>
            <div className="text-base font-bold text-blue-900">{accountHolderName}</div>
          </div>
        </div>
      </div>
    </div>
  );
};
