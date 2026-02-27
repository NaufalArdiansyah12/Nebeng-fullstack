import { useEffect, useState } from "react";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Button } from "@/components/ui/button";
import { Textarea } from "@/components/ui/textarea";
import { Switch } from "@/components/ui/switch";
import api from "@/lib/api";
import { toast } from "sonner";

const PricingFormDialog = ({ open, onOpenChange, profile, onSaved }: any) => {
  const [form, setForm] = useState({ 
    name: "", 
    description: "", 
    transport_mode_id: "", 
    active: true, 
    base_price: "", 
    price_per_km: "", 
    price_per_kg: "", 
    min_price: "" 
  });
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    if (profile) {
      setForm({
        name: profile.name || "",
        description: profile.description || "",
        transport_mode_id: profile.transport_mode_id || "",
        active: profile.active ?? true,
        base_price: profile.base_price || "",
        price_per_km: profile.price_per_km || "",
        price_per_kg: profile.price_per_kg || "",
        min_price: profile.min_price || "",
      });
    } else {
      setForm({ 
        name: "", 
        description: "", 
        transport_mode_id: "", 
        active: true, 
        base_price: "", 
        price_per_km: "", 
        price_per_kg: "", 
        min_price: "" 
      });
    }
  }, [profile, open]);

  const handleSave = async () => {
    if (!form.name) {
      toast.error("Nama profil harus diisi");
      return;
    }

    try {
      setSaving(true);
      const payload = {
        name: form.name,
        description: form.description,
        transport_mode_id: form.transport_mode_id ? Number(form.transport_mode_id) : null,
        active: form.active,
        base_price: form.base_price ? Number(form.base_price) : 0,
        price_per_km: form.price_per_km ? Number(form.price_per_km) : 0,
        price_per_kg: form.price_per_kg ? Number(form.price_per_kg) : 0,
        min_price: form.min_price ? Number(form.min_price) : null,
      };

      if (profile && profile.id) {
        await api.put(`/finance/pricing-profiles/${profile.id}`, payload);
        toast.success("Profil tarif berhasil diperbarui");
      } else {
        await api.post(`/finance/pricing-profiles`, payload);
        toast.success("Profil tarif berhasil dibuat");
      }
      onSaved();
      onOpenChange(false);
    } catch (err: any) {
      console.error(err);
      toast.error(err.response?.data?.message || "Gagal menyimpan profil");
    } finally {
      setSaving(false);
    }
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-2xl">
        <DialogHeader>
          <DialogTitle>{profile ? 'Edit Profil Tarif' : 'Tambah Profil Tarif'}</DialogTitle>
        </DialogHeader>
        <div className="space-y-4">
          <div>
            <Label htmlFor="name">Nama Profil *</Label>
            <Input 
              id="name"
              placeholder="Contoh: Tarif Motor Standar" 
              value={form.name} 
              onChange={(e) => setForm({...form, name: e.target.value})} 
            />
          </div>

          <div>
            <Label htmlFor="description">Deskripsi</Label>
            <Textarea 
              id="description"
              placeholder="Deskripsi profil tarif" 
              value={form.description} 
              onChange={(e) => setForm({...form, description: e.target.value})} 
              rows={3}
            />
          </div>

          <div>
            <Label htmlFor="transport_mode_id">ID Jenis Transportasi</Label>
            <Input 
              id="transport_mode_id"
              type="text"
              placeholder="Opsional" 
              value={form.transport_mode_id} 
              onChange={(e) => setForm({...form, transport_mode_id: e.target.value.replace(/\D/g, "")})} 
            />
            <p className="text-xs text-gray-500 mt-1">Kosongkan jika berlaku untuk semua jenis</p>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <Label htmlFor="base_price">Harga Dasar (Rp)</Label>
              <Input 
                id="base_price"
                type="text"
                placeholder="0" 
                value={form.base_price} 
                onChange={(e) => setForm({...form, base_price: e.target.value.replace(/\D/g, "").replace(/^0+(?=\d)/, "")})} 
              />
            </div>

            <div>
              <Label htmlFor="min_price">Harga Minimum (Rp)</Label>
              <Input 
                id="min_price"
                type="text"
                placeholder="Opsional" 
                value={form.min_price} 
                onChange={(e) => setForm({...form, min_price: e.target.value.replace(/\D/g, "").replace(/^0+(?=\d)/, "")})} 
              />
            </div>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <Label htmlFor="price_per_km">Harga per KM (Rp)</Label>
              <Input 
                id="price_per_km"
                type="text"
                placeholder="0" 
                value={form.price_per_km} 
                onChange={(e) => setForm({...form, price_per_km: e.target.value.replace(/\D/g, "").replace(/^0+(?=\d)/, "")})} 
              />
            </div>

            <div>
              <Label htmlFor="price_per_kg">Harga per KG (Rp)</Label>
              <Input 
                id="price_per_kg"
                type="text"
                placeholder="0" 
                value={form.price_per_kg} 
                onChange={(e) => setForm({...form, price_per_kg: e.target.value.replace(/\D/g, "").replace(/^0+(?=\d)/, "")})} 
              />
            </div>
          </div>

          <div className="flex items-center space-x-2">
            <Switch 
              id="active"
              checked={form.active} 
              onCheckedChange={(checked) => setForm({...form, active: checked})} 
            />
            <Label htmlFor="active">Aktif</Label>
          </div>

          <div className="flex justify-end gap-2 pt-4">
            <Button variant="outline" onClick={() => onOpenChange(false)}>
              Batal
            </Button>
            <Button onClick={handleSave} disabled={saving}>
              {saving ? 'Menyimpan...' : 'Simpan'}
            </Button>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  );
};

export default PricingFormDialog;
