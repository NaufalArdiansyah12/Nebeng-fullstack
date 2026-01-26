import { ChevronLeft } from "lucide-react";
import { Button } from "@/components/ui/button";
import DashboardLayout from "@/components/DashboardLayout";
import { useNavigate, useParams } from "react-router-dom";
import { useEffect, useState } from "react";
import api from "@/lib/api";

const DetailTransaksi = () => {
  const navigate = useNavigate();
  const { id } = useParams();

  const [transaksi, setTransaksi] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    api
      .get(`/transactions/${id}`)
      .then((res) => {
        setTransaksi(res.data.data);
      })
      .catch(() => {
        setError("Gagal mengambil data transaksi");
      })
      .finally(() => {
        setLoading(false);
      });
  }, [id]);

  if (loading) {
    return (
      <DashboardLayout title="Detail Transaksi">
        <p>Loading data transaksi...</p>
      </DashboardLayout>
    );
  }

  if (error || !transaksi) {
    return (
      <DashboardLayout title="Detail Transaksi">
        <p>{error || "Data transaksi tidak ditemukan"}</p>
      </DashboardLayout>
    );
  }

  return (
    <DashboardLayout title="Detail Transaksi">
      {/* HEADER */}
      <div className="flex items-center gap-3 mb-6">
        <Button variant="ghost" size="icon" onClick={() => navigate(-1)}>
          <ChevronLeft />
        </Button>
        <h2 className="text-lg font-semibold">Detail Transaksi</h2>
      </div>

      <div className="space-y-6">
        {/* ID PESANAN */}
        <div className="border rounded-xl p-5">
          <p className="text-sm text-muted-foreground">ID Pesanan</p>
          <p className="font-semibold text-lg">
            {transaksi.booking_number}
          </p>
          <p className="text-sm text-muted-foreground">
            {new Date(transaksi.created_at).toLocaleDateString("id-ID")}
          </p>
        </div>

        {/* INFORMASI CUSTOMER */}
        <div className="border rounded-xl p-5">
          <h4 className="font-semibold mb-4">Informasi Customer</h4>
          <p className="font-semibold">{transaksi.customer.name}</p>
          <p className="text-sm text-muted-foreground">
            {transaksi.customer.phone}
          </p>
        </div>

        {/* RINCIAN PEMBAYARAN */}
        <div className="border rounded-xl p-5">
          <h4 className="font-semibold mb-4">Rincian Pembayaran</h4>

          <div className="flex justify-between mb-2">
            <span className="text-sm text-muted-foreground">
              Metode Pembayaran
            </span>
            <span className="font-semibold">
              {transaksi.payment_method}
            </span>
          </div>

          <div className="flex justify-between mb-2">
            <span className="text-sm text-muted-foreground">
              Biaya Penumpang
            </span>
            <span className="font-semibold">
              Rp {Number(transaksi.amount).toLocaleString("id-ID")}
            </span>
          </div>

          <div className="flex justify-between mb-2">
            <span className="text-sm text-muted-foreground">
              Biaya Admin
            </span>
            <span className="font-semibold">
              Rp {Number(transaksi.admin_fee).toLocaleString("id-ID")}
            </span>
          </div>

          <div className="border-t pt-4 mt-4 flex justify-between font-semibold text-lg">
            <span>Total</span>
            <span className="text-green-600">
              Rp {Number(transaksi.total_amount).toLocaleString("id-ID")}
            </span>
          </div>
        </div>
      </div>
    </DashboardLayout>
  );
};

export default DetailTransaksi;
