interface PaymentCardProps {
  payment: {
    type: string;
    date: string;
    transaction_number: string;
    base_price: number;
    admin_fee: number;
    total: number;
    passengers: number;
  };
  bookingNumber: string;
}

export function PaymentCard({ payment, bookingNumber }: PaymentCardProps) {
  return (
    <div className="bg-background rounded-xl p-6 border shadow-sm">
      <h3 className="font-semibold text-lg mb-4">Rincian Pembayaran</h3>

      <div className="space-y-3 mb-4">
        <div className="flex justify-between text-sm">
          <span className="text-muted-foreground">Type Pembayaran</span>
          <span className="font-semibold uppercase">{payment.type}</span>
        </div>
        <div className="flex justify-between text-sm">
          <span className="text-muted-foreground">Tanggal</span>
          <span className="font-semibold">{payment.date}</span>
        </div>
      </div>

      <div className="border-t-2 pt-4 space-y-3 mb-4">
        <div className="flex justify-between text-sm">
          <span className="text-muted-foreground">ID Pesanan</span>
          <span className="font-mono text-xs">{bookingNumber}</span>
        </div>
        <div className="flex justify-between text-sm">
          <span className="text-muted-foreground">No Transaksi</span>
          <span className="font-mono text-xs">{payment.transaction_number}</span>
        </div>
      </div>

      <div className="border-t-2 pt-4 space-y-3">
        <div className="flex justify-between text-sm">
          <span>Biaya Per penebeng ({payment.passengers} Org)</span>
          <span>Rp {payment.base_price.toLocaleString("id-ID")}</span>
        </div>
        <div className="flex justify-between text-sm">
          <span>Biaya Admin</span>
          <span>Rp {payment.admin_fee.toLocaleString("id-ID")}</span>
        </div>
        <div className="flex justify-between font-semibold text-base border-t-2 pt-3 mt-3">
          <span>Total Pembayaran</span>
          <span className="text-green-600">Rp {payment.total.toLocaleString("id-ID")}</span>
        </div>
      </div>
    </div>
  );
}
