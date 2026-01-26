import { useState } from "react";
import { Search } from "lucide-react";
import DashboardLayout from "@/components/DashboardLayout";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";

const EditDetailPencairanDana = () => {
  const [form, setForm] = useState({
    nama: "Muhammad Abdul Kadir",
    username: "Abdul.sa",
    email: "abdul123@gmail.com",
    phone: "0821992891",
    kode: "asdasj928",
    gender: "Laki - Laki",
    metode: "BRI",
    layanan: "Nebeng Motor",
    saldo: "Rp. 600.000,-",
    jumlah: "Rp. 200.000,-",
  });

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
              <Badge className="bg-green-500">Selesai</Badge>
            </div>

            <Button size="sm">Simpan</Button>
          </div>

          {/* Informasi Pribadi */}
          <div className="space-y-4">
            <h3 className="font-semibold">Informasi Pribadi</h3>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label className="text-xs text-muted-foreground">Nama Lengkap</label>
                <Input value={form.nama} onChange={(e) => setForm({ ...form, nama: e.target.value })} />
              </div>

              <div>
                <label className="text-xs text-muted-foreground">Username</label>
                <Input value={form.username} onChange={(e) => setForm({ ...form, username: e.target.value })} />
              </div>

              <div>
                <label className="text-xs text-muted-foreground">Email</label>
                <Input value={form.email} onChange={(e) => setForm({ ...form, email: e.target.value })} />
              </div>

              <div>
                <label className="text-xs text-muted-foreground">No. Tlp</label>
                <Input value={form.phone} onChange={(e) => setForm({ ...form, phone: e.target.value })} />
              </div>

              <div>
                <label className="text-xs text-muted-foreground">Kode Referral</label>
                <Input value={form.kode} onChange={(e) => setForm({ ...form, kode: e.target.value })} />
              </div>

              <div>
                <label className="text-xs text-muted-foreground">Jenis Kelamin</label>
                <Select value={form.gender} onValueChange={(v) => setForm({ ...form, gender: v })}>
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="Laki - Laki">Laki - Laki</SelectItem>
                    <SelectItem value="Perempuan">Perempuan</SelectItem>
                  </SelectContent>
                </Select>
              </div>

              <div>
                <label className="text-xs text-muted-foreground">Metode Pencairan</label>
                <Input value={form.metode} onChange={(e) => setForm({ ...form, metode: e.target.value })} />
              </div>

              <div>
                <label className="text-xs text-muted-foreground">Layanan</label>
                <Input value={form.layanan} onChange={(e) => setForm({ ...form, layanan: e.target.value })} />
              </div>

              <div>
                <label className="text-xs text-muted-foreground">Total Saldo</label>
                <Input value={form.saldo} disabled />
              </div>

              <div>
                <label className="text-xs text-muted-foreground">Total Pencairan</label>
                <Input value={form.jumlah} disabled />
              </div>
            </div>
          </div>

          {/* Footer */}
          <div className="flex justify-end gap-3">
            <Button variant="outline">Batal</Button>
            <Button>Simpan</Button>
          </div>
        </div>
      </div>
    </DashboardLayout>
  );
};

export default EditDetailPencairanDana;
