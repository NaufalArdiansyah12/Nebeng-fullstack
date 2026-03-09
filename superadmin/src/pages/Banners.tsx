import { useEffect, useState } from "react";
import { Edit, Trash2, Plus, Image, TrendingUp, Eye, Upload, X, GripVertical, Save } from "lucide-react";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { Switch } from "@/components/ui/switch";
import { Badge } from "@/components/ui/badge";
import { Label } from "@/components/ui/label";
import { cn } from "@/lib/utils";
import { toast } from "sonner";
import { bannersApi } from "@/services/api";

interface BannerData {
  id: number | string;
  title: string;
  image_url: string;
  is_active: boolean;
  position: string;
  order: number;
  created_at?: string;
}

const Banners = () => {
  const [list, setList] = useState<BannerData[]>([]);
  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [form, setForm] = useState({ title: "", image_url: "", is_active: true, position: "home", order: 0 });
  const [editing, setEditing] = useState<BannerData | null>(null);
  const [isDragging, setIsDragging] = useState(false);
  const [ratioWarning, setRatioWarning] = useState<string | null>(null);

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
    } catch {
      return url;
    }
  };

  const loadData = async () => {
    setLoading(true);
    try {
      const res = await bannersApi.getAll();
      setList(res.data || []);
    } catch (e) {
      console.error("Failed to load banners", e);
      toast.error("Gagal memuat data banner");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { loadData(); }, []);

  const readFileAsDataURL = (file: File): Promise<string> =>
    new Promise((resolve, reject) => {
      const fr = new FileReader();
      fr.onload = () => resolve(String(fr.result));
      fr.onerror = reject;
      fr.readAsDataURL(file);
    });

  const checkRatio = (img: HTMLImageElement) => {
    const ratio = img.naturalWidth / img.naturalHeight;
    const diff = Math.abs(ratio - 16 / 9) / (16 / 9);
    setRatioWarning(diff > 0.12 ? "Rasio gambar jauh dari 16:9 — sebaiknya gunakan rasio 16:9." : null);
  };

  const handlePick = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    if (!file.type.startsWith("image/")) { toast.error("Format tidak didukung. Gunakan JPG, PNG, atau WEBP."); return; }
    if (file.size > 5 * 1024 * 1024) { toast.error("Ukuran file maksimal 5MB."); return; }
    const dataUrl = await readFileAsDataURL(file);
    setForm({ ...form, image_url: dataUrl });
    const img = new window.Image();
    img.onload = () => checkRatio(img);
    img.src = dataUrl;
  };

  const handleDrop = async (e: React.DragEvent) => {
    e.preventDefault();
    setIsDragging(false);
    const file = e.dataTransfer?.files?.[0];
    if (!file) return;
    if (!file.type.startsWith("image/")) { toast.error("Format tidak didukung."); return; }
    const dataUrl = await readFileAsDataURL(file);
    setForm({ ...form, image_url: dataUrl });
    const img = new window.Image();
    img.onload = () => checkRatio(img);
    img.src = dataUrl;
  };

  const openEdit = (item: BannerData) => {
    setEditing(item);
    setForm({ title: item.title, image_url: item.image_url, is_active: item.is_active, position: item.position, order: item.order });
    setRatioWarning(null);
  };

  const openCreate = () => {
    setEditing(null);
    setForm({ title: "", image_url: "", is_active: true, position: "home", order: 0 });
    setRatioWarning(null);
  };

  const handleSave = async () => {
    if (!form.title.trim() || !form.image_url) {
      toast.error("Isi judul dan pilih gambar terlebih dahulu.");
      return;
    }
    setSaving(true);
    try {
      if (editing) {
        await bannersApi.update(String(editing.id), form);
        toast.success(`Banner "${form.title}" berhasil diperbarui.`);
      } else {
        await bannersApi.create(form);
        toast.success(`Banner "${form.title}" berhasil ditambahkan.`);
      }
      await loadData();
      openCreate();
    } catch (e) {
      toast.error("Gagal menyimpan banner.");
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async (item: BannerData) => {
    if (!window.confirm(`Hapus banner "${item.title}"?`)) return;
    try {
      await bannersApi.delete(String(item.id));
      toast.success(`Banner "${item.title}" dihapus.`);
      loadData();
    } catch {
      toast.error("Gagal menghapus banner.");
    }
  };

  const activeBanners = list.filter((b) => b.is_active);
  const inactiveBanners = list.filter((b) => !b.is_active);

  return (
    <div className="space-y-6">
      {/* Stats */}
      <div className="grid grid-cols-3 gap-4">
        {[
          { label: "Total Banner", value: list.length, icon: Image, color: "text-[#1e3a5f]", bg: "bg-[#1e3a5f]/10" },
          { label: "Banner Aktif", value: activeBanners.length, icon: TrendingUp, color: "text-green-600", bg: "bg-green-50" },
          { label: "Banner Nonaktif", value: inactiveBanners.length, icon: Eye, color: "text-muted-foreground", bg: "bg-muted" },
        ].map((stat) => (
          <Card key={stat.label} className="shadow-sm">
            <CardContent className="flex items-center gap-4 p-5">
              <div className={`flex h-10 w-10 items-center justify-center rounded-lg ${stat.bg}`}>
                <stat.icon className={`h-5 w-5 ${stat.color}`} />
              </div>
              <div>
                <p className="text-2xl font-bold">{stat.value}</p>
                <p className="text-xs text-muted-foreground">{stat.label}</p>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>

      {/* Main Content */}
      <div className="grid grid-cols-1 gap-6 lg:grid-cols-5">
        {/* Form */}
        <div className="lg:col-span-2">
          <Card className="shadow-sm">
            <CardHeader>
              <CardTitle className="text-base">{editing ? "Edit Banner" : "Upload Banner Baru"}</CardTitle>
              <CardDescription>
                {editing ? `Mengedit "${editing.title}"` : "Tambahkan gambar banner untuk halaman utama"}
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div>
                <Label className="text-sm font-medium">Judul Banner</Label>
                <Input
                  placeholder="Contoh: Promo Akhir Tahun"
                  value={form.title}
                  onChange={(e) => setForm({ ...form, title: e.target.value })}
                  className="mt-1.5"
                />
              </div>
              <div className="flex items-center gap-3">
                <Switch checked={form.is_active} onCheckedChange={(v) => setForm({ ...form, is_active: v })} />
                <Label className="text-sm">Banner Aktif</Label>
              </div>

              {/* Image Zone */}
              {form.image_url ? (
                <div className="relative overflow-hidden rounded-lg border">
                  <img src={resolveImageUrl(form.image_url)} alt="Preview" className="h-48 w-full object-cover" />
                  <button
                    onClick={() => { setForm({ ...form, image_url: "" }); setRatioWarning(null); }}
                    className="absolute right-2 top-2 rounded-full bg-foreground/70 p-1.5 text-background hover:bg-foreground"
                  >
                    <X className="h-4 w-4" />
                  </button>
                </div>
              ) : (
                <div
                  onDragOver={(e) => { e.preventDefault(); setIsDragging(true); }}
                  onDragLeave={() => setIsDragging(false)}
                  onDrop={handleDrop}
                  onClick={() => document.getElementById("banner-file-input")?.click()}
                  className={cn(
                    "flex flex-col items-center justify-center rounded-xl border-2 border-dashed p-10 transition-all cursor-pointer",
                    isDragging ? "border-primary bg-primary/5 scale-[1.01]" : "border-border bg-muted/30 hover:border-primary/50 hover:bg-muted/50"
                  )}
                >
                  <div className="flex h-14 w-14 items-center justify-center rounded-full bg-[#1e3a5f]/10">
                    <Upload className="h-6 w-6 text-[#1e3a5f]" />
                  </div>
                  <p className="mt-4 text-sm font-medium">Drag & drop gambar di sini</p>
                  <p className="mt-1 text-xs text-muted-foreground">atau klik untuk memilih file</p>
                  <p className="mt-3 text-xs text-muted-foreground">JPG, PNG, WEBP • Maks 5MB • Rasio 16:9 disarankan</p>
                  <input id="banner-file-input" type="file" accept="image/*" className="hidden" onChange={handlePick} />
                </div>
              )}

              {ratioWarning && <p className="text-xs text-destructive">{ratioWarning}</p>}

              <div className="flex gap-2">
                <Button
                  onClick={handleSave}
                  disabled={!form.image_url || !form.title.trim() || saving}
                  className="flex-1 bg-[#1e3a5f] hover:bg-[#152a45] gap-2"
                >
                  {saving ? (
                    <span className="animate-spin h-4 w-4 border-2 border-white/30 border-t-white rounded-full" />
                  ) : editing ? (
                    <><Save className="h-4 w-4" /> Simpan Perubahan</>
                  ) : (
                    <><Plus className="h-4 w-4" /> Tambah Banner</>
                  )}
                </Button>
                {editing && <Button variant="outline" onClick={openCreate}>Batal</Button>}
              </div>
            </CardContent>
          </Card>
        </div>

        {/* List */}
        <div className="lg:col-span-3">
          <Card className="shadow-sm">
            <CardHeader>
              <CardTitle className="text-base">Daftar Banner</CardTitle>
              <CardDescription>{list.length} banner terdaftar</CardDescription>
            </CardHeader>
            <CardContent>
              {loading ? (
                <div className="flex items-center justify-center py-16">
                  <span className="animate-spin h-6 w-6 border-2 border-[#1e3a5f]/30 border-t-[#1e3a5f] rounded-full" />
                </div>
              ) : list.length === 0 ? (
                <div className="flex flex-col items-center justify-center rounded-xl border border-dashed py-16 text-center">
                  <div className="flex h-14 w-14 items-center justify-center rounded-full bg-muted">
                    <Eye className="h-6 w-6 text-muted-foreground" />
                  </div>
                  <p className="mt-4 text-sm font-medium">Belum ada banner</p>
                  <p className="mt-1 text-xs text-muted-foreground">Upload banner pertama di form sebelah</p>
                </div>
              ) : (
                <div className="space-y-3">
                  {list.map((banner, index) => (
                    <div
                      key={banner.id}
                      className="group flex items-center gap-4 rounded-xl border bg-card p-3 transition-all hover:shadow-md"
                    >
                      <div className="flex-shrink-0 text-muted-foreground/40">
                        <GripVertical className="h-5 w-5" />
                      </div>
                      <div className="h-16 w-28 flex-shrink-0 overflow-hidden rounded-lg bg-muted">
                        {banner.image_url ? (
                          <img src={resolveImageUrl(banner.image_url)} alt={banner.title} className="h-full w-full object-cover" />
                        ) : (
                          <div className="flex h-full w-full items-center justify-center">
                            <Image className="h-6 w-6 text-muted-foreground" />
                          </div>
                        )}
                      </div>
                      <div className="flex-1 min-w-0">
                        <p className="text-sm font-medium truncate">{banner.title || "-"}</p>
                        <p className="text-xs text-muted-foreground mt-0.5">
                          Posisi: {banner.position} • Urutan: {banner.order}
                        </p>
                      </div>
                      <Badge variant={banner.is_active ? "default" : "secondary"}>
                        {banner.is_active ? "Aktif" : "Nonaktif"}
                      </Badge>
                      <Button variant="ghost" size="icon" className="h-8 w-8 opacity-0 group-hover:opacity-100" onClick={() => openEdit(banner)}>
                        <Edit className="h-4 w-4" />
                      </Button>
                      <Button variant="ghost" size="icon" className="h-8 w-8 opacity-0 group-hover:opacity-100 hover:text-destructive" onClick={() => handleDelete(banner)}>
                        <Trash2 className="h-4 w-4" />
                      </Button>
                    </div>
                  ))}
                </div>
              )}
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  );
};

export default Banners;
