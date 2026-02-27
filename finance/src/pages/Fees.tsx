import { useEffect, useState } from "react";
import DashboardLayout from "@/components/DashboardLayout";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import api from "@/lib/api";
import { toast } from "sonner";

export default function Fees() {
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [adminFee, setAdminFee] = useState<string>("0");
  const [rescheduleFee, setRescheduleFee] = useState<string>("0");
  const [originalAdminFee, setOriginalAdminFee] = useState<string>("0");
  const [originalRescheduleFee, setOriginalRescheduleFee] = useState<string>("0");

  useEffect(() => {
    fetchFees();
  }, []);

  const fetchFees = async () => {
    try {
      setLoading(true);
      const res = await api.get('/finance/settings/fees');
      const af = String(res.data.admin_fee ?? 0);
      const rf = String(res.data.reschedule_fee ?? 0);
      setAdminFee(af);
      setRescheduleFee(rf);
      setOriginalAdminFee(af);
      setOriginalRescheduleFee(rf);
    } catch (error) {
      console.error('fetch fees error', error);
      toast.error('Gagal mengambil data biaya');
    } finally {
      setLoading(false);
    }
  };

  const handleSave = async () => {
    try {
      setSaving(true);
      const payload = {
        admin_fee: parseFloat(adminFee) || 0,
        reschedule_fee: parseFloat(rescheduleFee) || 0,
      };
      const res = await api.put('/finance/settings/fees', payload);
      if (res.status === 200 || res.status === 201) {
        toast.success('Biaya berhasil disimpan');
        // update originals
        const af = String(res.data.data?.admin_fee ?? payload.admin_fee);
        const rf = String(res.data.data?.reschedule_fee ?? payload.reschedule_fee);
        setOriginalAdminFee(af);
        setOriginalRescheduleFee(rf);
        setAdminFee(af);
        setRescheduleFee(rf);
      } else {
        toast.error('Gagal menyimpan biaya');
      }
    } catch (error) {
      console.error('save fees error', error);
      toast.error('Gagal menyimpan biaya');
    } finally {
      setSaving(false);
    }
  };

  const isDirty = () => {
    return adminFee !== originalAdminFee || rescheduleFee !== originalRescheduleFee;
  };

  return (
    <DashboardLayout title="Pengaturan Biaya">
      <div className="py-6 space-y-6">
        <div>
          <h2 className="text-2xl font-bold mb-2">Pengaturan Biaya</h2>
          <p className="text-sm text-muted-foreground">Atur nominal biaya administrasi dan biaya ubah jadwal.</p>
        </div>

        <div className="bg-background rounded-xl border border-border overflow-hidden shadow-sm">
          <div className="px-6 py-4 border-b border-border flex items-center justify-between">
            <h3 className="font-semibold text-lg">Biaya Administrasi</h3>
          </div>

          <div className="p-6">
            <p className="text-sm text-muted-foreground mb-3">Nominal biaya admin yang dipotong per transaksi.</p>
            <div className="flex gap-3 items-center">
              <Input
                type="number"
                value={adminFee}
                onChange={(e: any) => setAdminFee(e.target.value)}
                className="w-48"
                disabled={loading || saving}
              />
              <span className="text-sm">Rp</span>
            </div>
          </div>
        </div>

        <div className="bg-background rounded-xl border border-border overflow-hidden shadow-sm">
          <div className="px-6 py-4 border-b border-border flex items-center justify-between">
            <h3 className="font-semibold text-lg">Biaya Ubah Jadwal</h3>
          </div>

          <div className="p-6">
            <p className="text-sm text-muted-foreground mb-3">Biaya yang dikenakan saat pengguna mengubah jadwal booking.</p>
            <div className="flex gap-3 items-center">
              <Input
                type="number"
                value={rescheduleFee}
                onChange={(e: any) => setRescheduleFee(e.target.value)}
                className="w-48"
                disabled={loading || saving}
              />
              <span className="text-sm">Rp</span>
            </div>
          </div>
        </div>

        <div className="flex justify-end">
          <Button onClick={handleSave} disabled={saving || !isDirty()}>
            {saving ? 'Menyimpan...' : 'Simpan'}
          </Button>
        </div>
      </div>
    </DashboardLayout>
  );
}
