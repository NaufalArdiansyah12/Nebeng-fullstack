import { useState, useEffect } from "react";
import {
  Gift, Plus, Pencil, Trash2, Package, Star, X, Save, Search, Image as ImageIcon, Upload,
} from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Badge } from "@/components/ui/badge";
import { Textarea } from "@/components/ui/textarea";
import {
  Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter,
} from "@/components/ui/dialog";
import { toast } from "sonner";
import { rewardApi } from "@/services/api";

interface Reward {
  id: number;
  title: string;
  description: string;
  points_cost: number;
  image_url: string;
  stock: number;
  created_at?: string;
}

const emptyForm = { title: "", description: "", points_cost: 0, image_url: "", stock: 0 };

const RewardCatalog = () => {
  const [rewards, setRewards] = useState<Reward[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState("");
  const [dialogOpen, setDialogOpen] = useState(false);
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [editingId, setEditingId] = useState<number | null>(null);
  const [targetDelete, setTargetDelete] = useState<Reward | null>(null);
  const [saving, setSaving] = useState(false);
  const [form, setForm] = useState({ ...emptyForm });
  const [isDragging, setIsDragging] = useState(false);

  const resolveImageUrl = (url?: string) => {
    if (!url) return url;
    if (url.startsWith("data:")) return url;
    try {
      let resolved = url.replace(/https?:\/\/10\.0\.2\.2(:\d+)?/g, "http://localhost$1");
      const parsed = new URL(resolved, window.location.origin);
      if (parsed.pathname.startsWith("/uploads/")) {
        const backendBase = (import.meta.env.VITE_API_URL as string || "http://localhost:3001/api").replace(/\/api\/?.*$/, "");
        return `${backendBase}${parsed.pathname}`;
      }
      return resolved;
    } catch { return url; }
  };

  const loadRewards = async () => {
    setLoading(true);
    try {
      const res = await rewardApi.getAllRewards();
      setRewards(Array.isArray(res.data) ? res.data : []);
    } catch (e) {
      console.error("Failed loading rewards", e);
      toast.error("Gagal memuat data reward");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { loadRewards(); }, []);

  const readFileAsDataURL = (file: File): Promise<string> =>
    new Promise((resolve, reject) => {
      const fr = new FileReader();
      fr.onload = () => resolve(String(fr.result));
      fr.onerror = reject;
      fr.readAsDataURL(file);
    });

  const handlePickImage = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    if (!file.type.startsWith("image/")) { toast.error("Format tidak didukung."); return; }
    if (file.size > 5 * 1024 * 1024) { toast.error("Ukuran file maksimal 5MB."); return; }
    setForm({ ...form, image_url: await readFileAsDataURL(file) });
  };

  const handleDrop = async (e: React.DragEvent) => {
    e.preventDefault();
    setIsDragging(false);
    const file = e.dataTransfer?.files?.[0];
    if (!file || !file.type.startsWith("image/")) return;
    setForm({ ...form, image_url: await readFileAsDataURL(file) });
  };

  const openCreate = () => {
    setEditingId(null);
    setForm({ ...emptyForm });
    setDialogOpen(true);
  };

  const openEdit = (r: Reward) => {
    setEditingId(r.id);
    setForm({ title: r.title, description: r.description || "", points_cost: r.points_cost, image_url: r.image_url || "", stock: r.stock ?? 0 });
    setDialogOpen(true);
  };

  const handleSave = async () => {
    if (!form.title.trim()) { toast.error("Judul reward wajib diisi."); return; }
    if (form.points_cost <= 0) { toast.error("Poin reward harus lebih dari 0."); return; }
    setSaving(true);
    try {
      if (editingId !== null) {
        await rewardApi.updateReward(String(editingId), form);
        toast.success("Reward berhasil diperbarui.");
      } else {
        await rewardApi.createReward(form);
        toast.success("Reward berhasil ditambahkan.");
      }
      setDialogOpen(false);
      await loadRewards();
    } catch {
      toast.error("Gagal menyimpan reward.");
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async () => {
    if (!targetDelete) return;
    try {
      await rewardApi.deleteReward(String(targetDelete.id));
      toast.success(`Reward "${targetDelete.title}" dihapus.`);
      setDeleteDialogOpen(false);
      setTargetDelete(null);
      loadRewards();
    } catch {
      toast.error("Gagal menghapus reward.");
    }
  };

  const filtered = rewards.filter(
    (r) =>
      r.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
      (r.description || "").toLowerCase().includes(searchQuery.toLowerCase())
  );

  const totalStock = rewards.reduce((s, r) => s + (r.stock ?? 0), 0);
  const avgPoints = rewards.length ? Math.round(rewards.reduce((s, r) => s + r.points_cost, 0) / rewards.length) : 0;

  return (
    <div className="space-y-6">
      {/* Stats */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        {[
          { label: "Total Reward", value: rewards.length, icon: Gift, color: "text-[#1e3a5f]", bg: "bg-[#1e3a5f]/10" },
          { label: "Total Stok", value: totalStock, icon: Package, color: "text-green-600", bg: "bg-green-50" },
          { label: "Rata-rata Poin", value: avgPoints || "—", icon: Star, color: "text-amber-500", bg: "bg-amber-50" },
        ].map((s) => (
          <Card key={s.label} className="shadow-sm">
            <CardContent className="flex items-center gap-4 p-5">
              <div className={`flex h-10 w-10 items-center justify-center rounded-lg ${s.bg}`}>
                <s.icon className={`h-5 w-5 ${s.color}`} />
              </div>
              <div>
                <p className="text-2xl font-bold">{s.value}</p>
                <p className="text-xs text-muted-foreground">{s.label}</p>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>

      {/* Table Card */}
      <Card className="shadow-sm">
        <CardHeader className="pb-4">
          <div className="flex items-center justify-between">
            <CardTitle className="text-xl font-semibold">Katalog Reward</CardTitle>
            <Button onClick={openCreate} className="gap-2 bg-[#1e3a5f] hover:bg-[#152a45]">
              <Plus size={16} /> Buat Reward
            </Button>
          </div>
        </CardHeader>
        <CardContent>
          {/* Search */}
          <div className="relative w-72 mb-6">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-muted-foreground" size={16} />
            <Input
              placeholder="Cari reward..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="pl-9 h-10"
            />
          </div>

          {/* Table */}
          <div className="overflow-x-auto rounded-lg border border-border">
            <table className="w-full text-sm">
              <thead>
                <tr className="bg-[#1e3a5f] text-white">
                  <th className="text-left py-3 px-4 font-medium rounded-tl-lg w-12">NO</th>
                  <th className="text-left py-3 px-4 font-medium w-24">GAMBAR</th>
                  <th className="text-left py-3 px-4 font-medium">NAMA REWARD</th>
                  <th className="text-left py-3 px-4 font-medium">DESKRIPSI</th>
                  <th className="text-center py-3 px-4 font-medium">POIN</th>
                  <th className="text-center py-3 px-4 font-medium">STOK</th>
                  <th className="text-center py-3 px-4 font-medium rounded-tr-lg">AKSI</th>
                </tr>
              </thead>
              <tbody>
                {loading ? (
                  <tr>
                    <td colSpan={7} className="py-16 text-center">
                      <span className="inline-block animate-spin h-6 w-6 border-2 border-[#1e3a5f]/30 border-t-[#1e3a5f] rounded-full" />
                    </td>
                  </tr>
                ) : filtered.length > 0 ? (
                  filtered.map((reward, idx) => (
                    <tr key={reward.id} className="border-b border-border/50 hover:bg-muted/30 transition-colors">
                      <td className="py-3 px-4 text-muted-foreground">{idx + 1}</td>
                      <td className="py-3 px-4">
                        <div className="h-12 w-16 rounded-lg overflow-hidden bg-muted flex items-center justify-center">
                          {reward.image_url ? (
                            <img src={resolveImageUrl(reward.image_url)} alt={reward.title} className="h-full w-full object-cover" />
                          ) : (
                            <ImageIcon size={18} className="text-muted-foreground" />
                          )}
                        </div>
                      </td>
                      <td className="py-3 px-4 font-medium">{reward.title}</td>
                      <td className="py-3 px-4 text-muted-foreground max-w-xs">
                        <p className="truncate">{reward.description || "—"}</p>
                      </td>
                      <td className="py-3 px-4 text-center">
                        <Badge className="bg-amber-50 text-amber-700 border border-amber-200 hover:bg-amber-100 gap-1">
                          <Star size={10} /> {reward.points_cost.toLocaleString("id-ID")}
                        </Badge>
                      </td>
                      <td className="py-3 px-4 text-center">
                        <span className={`font-medium ${(reward.stock ?? 0) <= 5 ? "text-red-500" : "text-foreground"}`}>
                          {reward.stock ?? 0}
                        </span>
                      </td>
                      <td className="py-3 px-4">
                        <div className="flex items-center justify-center gap-1">
                          <Button variant="ghost" size="icon" className="h-8 w-8 hover:bg-[#1e3a5f]/10" onClick={() => openEdit(reward)}>
                            <Pencil size={15} className="text-[#1e3a5f]" />
                          </Button>
                          <Button variant="ghost" size="icon" className="h-8 w-8 hover:bg-red-50"
                            onClick={() => { setTargetDelete(reward); setDeleteDialogOpen(true); }}>
                            <Trash2 size={15} className="text-red-500" />
                          </Button>
                        </div>
                      </td>
                    </tr>
                  ))
                ) : (
                  <tr>
                    <td colSpan={7} className="py-16 text-center text-muted-foreground">
                      <Gift size={36} className="mx-auto mb-3 text-gray-300" />
                      <p>{searchQuery ? "Tidak ada reward yang cocok" : "Belum ada reward"}</p>
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </CardContent>
      </Card>

      {/* Create / Edit Dialog */}
      <Dialog open={dialogOpen} onOpenChange={(o) => { setDialogOpen(o); }}>
        <DialogContent className="max-w-lg">
          <DialogHeader>
            <DialogTitle>{editingId !== null ? "Edit Reward" : "Buat Reward Baru"}</DialogTitle>
          </DialogHeader>
          <div className="space-y-4 py-2">
            <div>
              <Label className="text-sm font-medium">Nama Reward <span className="text-destructive">*</span></Label>
              <Input className="mt-1.5" placeholder="Contoh: Mug Nebeng" value={form.title} onChange={(e) => setForm({ ...form, title: e.target.value })} />
            </div>
            <div>
              <Label className="text-sm font-medium">Deskripsi</Label>
              <Textarea className="mt-1.5 resize-none" rows={2} placeholder="Deskripsi singkat..." value={form.description} onChange={(e) => setForm({ ...form, description: e.target.value })} />
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <Label className="text-sm font-medium">Poin yang Dibutuhkan <span className="text-destructive">*</span></Label>
                <Input className="mt-1.5" type="number" min={1} placeholder="150" value={form.points_cost || ""} onChange={(e) => setForm({ ...form, points_cost: parseInt(e.target.value) || 0 })} />
              </div>
              <div>
                <Label className="text-sm font-medium">Stok</Label>
                <Input className="mt-1.5" type="number" min={0} placeholder="50" value={form.stock || ""} onChange={(e) => setForm({ ...form, stock: parseInt(e.target.value) || 0 })} />
              </div>
            </div>
            {/* Image upload */}
            <div>
              <Label className="text-sm font-medium">Gambar Reward</Label>
              {form.image_url ? (
                <div className="relative mt-1.5 overflow-hidden rounded-lg border h-36">
                  <img src={resolveImageUrl(form.image_url)} alt="preview" className="h-full w-full object-cover" />
                  <button onClick={() => setForm({ ...form, image_url: "" })}
                    className="absolute right-2 top-2 rounded-full bg-foreground/70 p-1.5 text-background hover:bg-foreground">
                    <X className="h-3 w-3" />
                  </button>
                </div>
              ) : (
                <div
                  onDragOver={(e) => { e.preventDefault(); setIsDragging(true); }}
                  onDragLeave={() => setIsDragging(false)}
                  onDrop={handleDrop}
                  onClick={() => document.getElementById("reward-img-input")?.click()}
                  className={`mt-1.5 flex flex-col items-center justify-center rounded-xl border-2 border-dashed p-8 cursor-pointer transition-all ${isDragging ? "border-primary bg-primary/5" : "border-border hover:border-primary/50 hover:bg-muted/30"}`}
                >
                  <Upload size={24} className="text-muted-foreground mb-2" />
                  <p className="text-xs text-muted-foreground">Klik atau drag gambar di sini</p>
                  <p className="text-xs text-muted-foreground mt-1">JPG, PNG, WEBP • Maks 5MB</p>
                  <input id="reward-img-input" type="file" accept="image/*" className="hidden" onChange={handlePickImage} />
                </div>
              )}
            </div>
          </div>
          <DialogFooter className="gap-2">
            <Button variant="outline" onClick={() => setDialogOpen(false)} disabled={saving}>Batal</Button>
            <Button onClick={handleSave} disabled={saving} className="bg-[#1e3a5f] hover:bg-[#152a45] gap-2">
              {saving ? <span className="animate-spin h-4 w-4 border-2 border-white/30 border-t-white rounded-full" /> : <Save size={15} />}
              {editingId !== null ? "Simpan" : "Buat Reward"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Delete Confirm Dialog */}
      <Dialog open={deleteDialogOpen} onOpenChange={setDeleteDialogOpen}>
        <DialogContent className="max-w-sm">
          <DialogHeader>
            <DialogTitle>Hapus Reward?</DialogTitle>
          </DialogHeader>
          <p className="text-sm text-muted-foreground py-2">
            Reward <strong>"{targetDelete?.title}"</strong> akan dihapus secara permanen dan tidak bisa dikembalikan.
          </p>
          <DialogFooter className="gap-2">
            <Button variant="outline" onClick={() => setDeleteDialogOpen(false)}>Batal</Button>
            <Button variant="destructive" onClick={handleDelete}>Hapus</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
};

export default RewardCatalog;
