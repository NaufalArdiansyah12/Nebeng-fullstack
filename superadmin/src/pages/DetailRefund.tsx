import { useNavigate, useParams } from "react-router-dom";
import { Check, X } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { useRefund } from "@/contexts/RefundContext";
import { format } from "date-fns";
import { id as localeId } from "date-fns/locale";

const formatCurrency = (amount: number | undefined) => {
  if (amount === undefined || amount === null) return "0.00,-";
  return `${amount.toLocaleString('id-ID')}.00,-`;
};

const formatCurrencyWithRp = (amount: number | undefined) => {
  if (amount === undefined || amount === null) return "0.00,-";
  return `${amount.toLocaleString('id-ID')}.00,-`;
};

const DetailRefund = () => {
  const navigate = useNavigate();
  const { id } = useParams<{ id: string }>();
  const { getRefundDetail } = useRefund();
  
  const refund = id ? getRefundDetail(id) : undefined;

  if (!refund) {
    return (
      <div className="flex items-center justify-center min-h-[400px]">
        <p className="text-muted-foreground">Data refund tidak ditemukan</p>
      </div>
    );
  }

  const getStatusConfig = (status: string) => {
    switch (status) {
      case "SELESAI":
        return {
          title: "REFUND SALDO BERHASIL",
          bgColor: "bg-[#6366f1]",
          iconBg: "bg-[#3b82f6]",
          icon: <Check className="text-white" size={32} />,
          textColor: "text-foreground",
        };
      case "PROSES":
        return {
          title: "REFUND SALDO DIPROSES",
          bgColor: "bg-[#6366f1]",
          iconBg: "bg-transparent",
          icon: (
            <div className="flex gap-1">
              <div className="w-3 h-3 rounded-full bg-[#1e3a5f]"></div>
              <div className="w-3 h-3 rounded-full bg-gray-300"></div>
              <div className="w-3 h-3 rounded-full bg-gray-300"></div>
            </div>
          ),
          textColor: "text-foreground",
        };
      case "BATAL":
        return {
          title: "REFUND SALDO DIBATALKAN",
          bgColor: "bg-gray-400",
          iconBg: "bg-gray-400",
          icon: <X className="text-white" size={32} />,
          textColor: "text-gray-400",
        };
      default:
        return {
          title: "REFUND SALDO",
          bgColor: "bg-gray-400",
          iconBg: "bg-gray-400",
          icon: null,
          textColor: "text-foreground",
        };
    }
  };

  const statusConfig = getStatusConfig(refund.status);

  return (
    <div className="flex items-center justify-center min-h-[calc(100vh-120px)] bg-background p-4">
      <Card className="w-full max-w-md bg-white rounded-2xl overflow-hidden shadow-xl">
        {/* Header */}
        <div className="text-center pt-8 pb-6 px-6">
          <h2 className={`text-lg font-bold mb-6 ${refund.status === "BATAL" ? "text-gray-400" : "text-foreground"}`}>
            {statusConfig.title}
          </h2>
          
          {/* Icon */}
          <div className="flex justify-center mb-4">
            {refund.status === "SELESAI" && (
              <div className="w-16 h-16 rounded-full bg-[#3b82f6] flex items-center justify-center">
                <Check className="text-white" size={32} />
              </div>
            )}
            {refund.status === "PROSES" && (
              <div className="flex gap-2 py-4">
                <div className="w-4 h-4 rounded-full bg-[#1e3a5f]"></div>
                <div className="w-4 h-4 rounded-full bg-gray-300"></div>
                <div className="w-4 h-4 rounded-full bg-gray-300"></div>
              </div>
            )}
            {refund.status === "BATAL" && (
              <div className="w-16 h-16 rounded-full bg-gray-300 flex items-center justify-center">
                <X className="text-white" size={32} />
              </div>
            )}
          </div>

          {/* Date */}
          <p className={`text-sm mb-2 ${refund.status === "BATAL" ? "text-gray-400" : "text-muted-foreground"}`}>
            {format(refund.tanggal, "EEEE, dd MMMM yyyy", { locale: localeId })}
          </p>

          {/* Amount */}
          <p className={`text-3xl font-bold ${refund.status === "BATAL" ? "text-gray-400" : "text-foreground"}`}>
            {formatCurrency(refund.jumlahRefund)}
          </p>
        </div>

        {/* Divider */}
        <div className="border-t border-dashed border-gray-200 mx-6"></div>

        {/* Details */}
        <div className="px-6 py-4 space-y-3">
          <div className="flex justify-between text-sm">
            <span className="text-muted-foreground">ID Pesanan</span>
            <span className="font-medium">{refund.idPesanan}</span>
          </div>
          <div className="flex justify-between text-sm">
            <span className="text-muted-foreground">No. Transaksi</span>
            <span className="font-medium">{refund.noTransaksi}</span>
          </div>
        </div>

        {/* Divider */}
        <div className="border-t border-gray-200 mx-6"></div>

        {/* Breakdown */}
        <div className="px-6 py-4 space-y-3">
          <div className="flex justify-between text-sm">
            <span className="text-muted-foreground">Metode Refund</span>
            <span className="font-medium">{refund.metodeRefund}</span>
          </div>
          <div className="flex justify-between text-sm">
            <span className="text-muted-foreground">Layanan Nebeng</span>
            <span className="font-medium">{refund.layananNebeng}</span>
          </div>
          <div className="flex justify-between text-sm">
            <span className="text-muted-foreground">Biaya Penumpang</span>
            <span className="font-medium"></span>
          </div>
          <div className="flex justify-between text-sm pl-4">
            <span className="text-muted-foreground">{refund.biayaPenumpang.quantity} x {formatCurrencyWithRp(refund.biayaPenumpang.price)}</span>
            <span className="font-medium">{formatCurrencyWithRp(refund.biayaPenumpang.quantity * refund.biayaPenumpang.price)}</span>
          </div>
          <div className="flex justify-between text-sm">
            <span className="text-muted-foreground">Biaya Admin</span>
            <span className="font-medium">{formatCurrencyWithRp(refund.biayaAdmin)}</span>
          </div>
        </div>

        {/* Total */}
        <div className="px-6 py-3 border-t border-gray-200">
          <div className="flex justify-between text-sm">
            <span className="font-medium">Total Refund</span>
            <span className="font-bold text-lg">{formatCurrency(refund.totalRefund)}</span>
          </div>
        </div>

        {/* Divider */}
        <div className="border-t border-gray-200 mx-6"></div>

        {/* Route Info */}
        <div className="px-6 py-4">
          <div className="flex justify-between">
            <div>
              <p className="text-sm text-[#3b82f6] font-medium mb-1">Titik Jemput</p>
              <p className="font-semibold">{refund.titikJemput.lokasi}</p>
              <p className="text-sm text-muted-foreground">{refund.titikJemput.waktu}</p>
              <p className="text-sm text-muted-foreground">{refund.titikJemput.alamat}</p>
            </div>
            <div className="flex items-center px-4">
              <div className="flex items-center gap-1">
                <div className="w-2 h-2 rounded-full bg-[#3b82f6]"></div>
                <div className="w-1 h-1 rounded-full bg-gray-300"></div>
                <div className="w-1 h-1 rounded-full bg-gray-300"></div>
                <div className="w-1 h-1 rounded-full bg-gray-300"></div>
                <div className="w-2 h-2 rounded-full bg-red-400"></div>
              </div>
            </div>
            <div className="text-right">
              <p className="text-sm text-[#3b82f6] font-medium mb-1">Tujuan</p>
              <p className="font-semibold">{refund.tujuan.lokasi}</p>
              <p className="text-sm text-muted-foreground">{refund.tujuan.waktu}</p>
              <p className="text-sm text-muted-foreground">{refund.tujuan.alamat}</p>
            </div>
          </div>
        </div>

        {/* Close Button */}
        <div className="px-6 pb-6">
          <Button 
            className="w-full bg-[#1e3a5f] hover:bg-[#152a45] text-white py-6"
            onClick={() => navigate("/dashboard/refund")}
          >
            CLOSE
          </Button>
        </div>
      </Card>
    </div>
  );
};

export default DetailRefund;
