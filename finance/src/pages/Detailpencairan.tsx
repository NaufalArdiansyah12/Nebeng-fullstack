import { Search } from "lucide-react";
import DashboardLayout from "@/components/DashboardLayout";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import { useNavigate, useParams } from "react-router-dom";

const DetailPencairanDana = () => {
  const navigate = useNavigate();
  const { id } = useParams();

  return (
    <DashboardLayout title="Detail Pencairan Dana">
      <div className="space-y-6">
        {/* Header Search */}
        <div className="flex items-center justify-end">
          <div className="relative w-64">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
            <Input placeholder="Search" className="pl-9" />
          </div>
        </div>

        {/* Card */}
        <div className="bg-background border border-border rounded-xl p-6 space-y-6">
          {/* User Info */}
          <div className="flex items-center justify-between bg-muted/40 rounded-lg p-4">
            <div className="flex items-center gap-4">
              <div className="w-12 h-12 rounded-full bg-muted flex items-center justify-center text-sm font-semibold">
                MA
              </div>
              <div>
                <p className="font-semibold">Muhammad Abdul</p>
                <p className="text-sm text-muted-foreground">Nebeng Motor</p>
              </div>
              <Badge variant="destructive" className="ml-2">Batal</Badge>
            </div>

            <Button size="sm" onClick={() => navigate(`/pencairan/${id}/edit`)}>
              Edit
            </Button>
          </div>

          {/* Informasi Pribadi */}
          <div className="space-y-4">
            <h3 className="font-semibold">Informasi Pribadi</h3>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label className="text-xs text-muted-foreground">Nama Lengkap</label>
                <Input value="Muhammad Abdul Kadir" disabled />
              </div>

              <div>
                <label className="text-xs text-muted-foreground">Username</label>
                <Input value="Abdul.sa" disabled />
              </div>

              <div>
                <label className="text-xs text-muted-foreground">Email</label>
                <Input value="abdul123@gmail.com" disabled />
              </div>

              <div>
                <label className="text-xs text-muted-foreground">No. Tlp</label>
                <Input value="0821992891" disabled />
              </div>

              <div>
                <label className="text-xs text-muted-foreground">Kode Referral</label>
                <Input value="asdasj45" disabled />
              </div>

              <div>
                <label className="text-xs text-muted-foreground">Jenis Kelamin</label>
                <Input value="Laki - Laki" disabled />
              </div>

              <div>
                <label className="text-xs text-muted-foreground">Metode Pencairan</label>
                <Input value="BRI" disabled />
              </div>

              <div>
                <label className="text-xs text-muted-foreground">Layanan</label>
                <Input value="Nebeng Motor" disabled />
              </div>

              <div>
                <label className="text-xs text-muted-foreground">Total Saldo</label>
                <Input value="Rp. 600.000,-" disabled />
              </div>

              <div>
                <label className="text-xs text-muted-foreground">Total Pencairan</label>
                <Input value="Rp. 200.000,-" disabled />
              </div>
            </div>
          </div>

          {/* Footer */}
          <div className="flex justify-end">
            <Button variant="outline">Bukti Nota</Button>
          </div>
        </div>
      </div>
    </DashboardLayout>
  );
};

export default DetailPencairanDana;
