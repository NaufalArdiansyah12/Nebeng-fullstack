import { useEffect, useState } from "react";
import { Edit, Trash2, Plus, Image, TrendingUp, Eye, Upload, X, GripVertical } from "lucide-react";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { Switch } from "@/components/ui/switch";
import { Badge } from "@/components/ui/badge";
import { Label } from "@/components/ui/label";
import { cn } from "@/lib/utils";
import { toast } from "@/hooks/use-toast";
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
  // removed unused activeMenu state (sidebar handled by layout)
  const [list, setList] = useState<BannerData[]>([]);
  const [loading, setLoading] = useState(false);
  const [form, setForm] = useState({ title: "", image_url: "", is_active: true, position: "home", order: 0 });
  const [editing, setEditing] = useState<BannerData | null>(null);
  const [isDragging, setIsDragging] = useState(false);
  const [ratioWarning, setRatioWarning] = useState<string | null>(null);
  const loadData = async () => {
    setLoading(true);
    try {
      const res = await bannersApi.getAll();
      setList(res.data || []);
    } catch (e) {
      console.error("Failed to load banners", e);
    } finally {
      setLoading(false);
    }
  };
  useEffect(() => { loadData(); }, []);
  // Normalize image URLs so admin panel (running in browser) can preview images
  // even when backend returned 10.0.2.2 (Android emulator host).
  const resolveImageUrl = (url?: string) => {
    if (!url) return url;
    // Don't touch data URLs
    if (url.startsWith('data:')) return url;
    // If backend returned emulator host, replace with localhost (browser can access)
    try {
      if (url.includes('10.0.2.2')) {
        return url.replace(/https?:\/\/10\.0\.2\.2(:\d+)?/, `${window.location.protocol}//localhost$1`);
      }
    } catch (e) {
      // fallback return original
    }
    return url;
  };
  const RECOMMENDED_RATIO = 16 / 9;
  const RATIO_TOLERANCE = 0.12;
  const checkRatio = (img: HTMLImageElement) => {
    const ratio = img.naturalWidth / img.naturalHeight;
    const diff = Math.abs(ratio - RECOMMENDED_RATIO) / RECOMMENDED_RATIO;
    if (diff > RATIO_TOLERANCE) {
      setRatioWarning("Rasio gambar jauh dari 16:9 — sebaiknya gunakan rasio 16:9.");
    } else {
      setRatioWarning(null);
    }
  };
  const readFileAsDataURL = (file: File): Promise<string> => {
    return new Promise((resolve, reject) => {
      const fr = new FileReader();
      fr.onload = () => resolve(String(fr.result));
      fr.onerror = reject;
      fr.readAsDataURL(file);
    });
  };
  const handlePick = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    if (!file.type.startsWith("image/")) {
      toast({ title: "Format tidak didukung", description: "Silakan upload file gambar (JPG, PNG, WEBP)", variant: "destructive" });
      return;
    }
    if (file.size > 5 * 1024 * 1024) {
      toast({ title: "File terlalu besar", description: "Ukuran maksimal 5MB", variant: "destructive" });
      return;
    }
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
    if (!file.type.startsWith("image/")) {
      toast({ title: "Format tidak didukung", description: "Silakan upload file gambar (JPG, PNG, WEBP)", variant: "destructive" });
      return;
    }
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
      toast({ title: "Data belum lengkap", description: "Isi judul dan pilih gambar terlebih dahulu", variant: "destructive" });
      return;
    }
    try {
      if (editing) {
        await bannersApi.update(String(editing.id), form);
        toast({ title: "Banner diperbarui!", description: `"${form.title}" berhasil diperbarui.` });
      } else {
        await bannersApi.create(form);
        toast({ title: "Banner berhasil ditambahkan!", description: `"${form.title}" telah ditambahkan ke daftar banner.` });
      }
      await loadData();
      openCreate();
    } catch (e) {
      console.error("Save error", e);
      toast({ title: "Gagal menyimpan", description: "Terjadi kesalahan saat menyimpan banner", variant: "destructive" });
    }
  };
  const handleDelete = async (item: BannerData) => {
    if (!window.confirm("Hapus banner ini?")) return;
    try {
      await bannersApi.delete(String(item.id));
      toast({ title: "Banner dihapus", description: `"${item.title}" telah dihapus.` });
      loadData();
    } catch (e) {
      console.error("Delete error", e);
      toast({ title: "Gagal menghapus", description: "Terjadi kesalahan saat menghapus banner", variant: "destructive" });
    }
  };
  const clearImage = () => {
    setForm({ ...form, image_url: "" });
    setRatioWarning(null);
  };
  const activeBanners = list.filter((b) => b.is_active);
  const inactiveBanners = list.filter((b) => !b.is_active);
  return (
    <div className="min-h-screen bg-background">
      <div className="min-h-screen">
        {/* Header */}
        <header className="sticky top-0 z-30 border-b bg-background/80 backdrop-blur-sm">
          <div className="flex h-16 items-center justify-between px-8">
            <div>
              <h1 className="text-lg font-semibold">Manajemen Banner</h1>
              <p className="text-xs text-muted-foreground">Kelola gambar banner untuk halaman utama</p>
            </div>
            <div className="flex items-center gap-2">
              <div className="flex h-8 w-8 items-center justify-center rounded-full bg-primary text-xs font-bold text-primary-foreground">
                A
              </div>
            </div>
          </div>
        </header>
        <div className="p-8">
          {/* Stats */}
          <div className="mb-8 grid grid-cols-3 gap-4">
            {[
              { label: "Total Banner", value: list.length, icon: Image, color: "text-primary" },
              { label: "Banner Aktif", value: activeBanners.length, icon: TrendingUp, color: "text-success" },
              { label: "Banner Nonaktif", value: inactiveBanners.length, icon: Eye, color: "text-muted-foreground" },
            ].map((stat) => (
              <Card key={stat.label} className="animate-fade-in">
                <CardContent className="flex items-center gap-4 p-5">
                  <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-accent/10">
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
            {/* Upload / Edit Form */}
            <div className="lg:col-span-2">
              <Card>
                <CardHeader>
                  <CardTitle className="text-base">
                    {editing ? "Edit Banner" : "Upload Banner Baru"}
                  </CardTitle>
                  <CardDescription>
                    {editing ? `Mengedit "${editing.title}"` : "Tambahkan gambar banner untuk ditampilkan di halaman utama"}
                  </CardDescription>
                </CardHeader>
                <CardContent>
                  <div className="space-y-5 animate-fade-in">
                    <div>
                      <Label htmlFor="banner-title" className="text-sm font-medium">Judul Banner</Label>
                      <Input
                        id="banner-title"
                        placeholder="Contoh: Promo Akhir Tahun"
                        value={form.title}
                        onChange={(e) => setForm({ ...form, title: e.target.value })}
                        className="mt-1.5"
                      />
                    </div>
                    <div className="flex items-center gap-3">
                      <Switch
                        checked={form.is_active}
                        onCheckedChange={(checked) => setForm({ ...form, is_active: checked })}
                      />
                      <Label className="text-sm">Banner Aktif</Label>
                    </div>
                    {/* Image Upload Zone */}
                    {form.image_url ? (
                      <div className="relative overflow-hidden rounded-lg border">
                        <img src={resolveImageUrl(form.image_url)} alt="Preview" className="h-48 w-full object-cover" />
                        <button
                          onClick={clearImage}
                          className="absolute right-2 top-2 rounded-full bg-foreground/70 p-1.5 text-background transition-colors hover:bg-foreground"
                        >
                          <X className="h-4 w-4" />
                        </button>
                      </div>
                    ) : (
                      <div
                        onDragOver={(e) => { e.preventDefault(); setIsDragging(true); }}
                        onDragLeave={() => setIsDragging(false)}
                        onDrop={handleDrop}
                        className={cn(
                          "flex flex-col items-center justify-center rounded-xl border-2 border-dashed p-10 transition-all cursor-pointer",
                          isDragging
                            ? "border-dropzone-border bg-dropzone-hover scale-[1.01]"
                            : "border-border bg-dropzone hover:border-dropzone-border hover:bg-dropzone-hover"
                        )}
                        onClick={() => document.getElementById("file-input")?.click()}
                      >
                        <div className="flex h-14 w-14 items-center justify-center rounded-full bg-accent">
                          <Upload className="h-6 w-6 text-accent-foreground" />
                        </div>
                        <p className="mt-4 text-sm font-medium">Drag & drop gambar di sini</p>
                        <p className="mt-1 text-xs text-muted-foreground">atau klik untuk memilih file</p>
                        <p className="mt-3 text-xs text-muted-foreground">JPG, PNG, WEBP • Maks 5MB • Rasio 16:9 disarankan</p>
                        <input
                          id="file-input"
                          type="file"
                          accept="image/*"
                          className="hidden"
                          onChange={handlePick}
                        />
                      </div>
                    )}
                    {ratioWarning && (
                      <p className="text-xs text-destructive">{ratioWarning}</p>
                    )}
                    <div className="flex gap-2">
                      <Button onClick={handleSave} className="flex-1" disabled={!form.image_url || !form.title.trim()}>
                        {editing ? (
                          <><Edit className="mr-2 h-4 w-4" /> Simpan Perubahan</>
                        ) : (
                          <><Plus className="mr-2 h-4 w-4" /> Tambah Banner</>
                        )}
                      </Button>
                      {editing && (
                        <Button variant="outline" onClick={openCreate}>Batal</Button>
                      )}
                    </div>
                  </div>
                </CardContent>
              </Card>
            </div>
            {/* Banner List */}
            <div className="lg:col-span-3">
              <Card>
                <CardHeader>
                  <CardTitle className="text-base">Daftar Banner</CardTitle>
                  <CardDescription>{list.length} banner terdaftar</CardDescription>
                </CardHeader>
                <CardContent>
                  {loading ? (
                    <div className="flex flex-col items-center justify-center py-16 text-center">
                      <p className="text-sm text-muted-foreground">Memuat...</p>
                    </div>
                  ) : list.length === 0 ? (
                    <div className="flex flex-col items-center justify-center rounded-xl border border-dashed py-16 text-center animate-fade-in">
                      <div className="flex h-14 w-14 items-center justify-center rounded-full bg-muted">
                        <Eye className="h-6 w-6 text-muted-foreground" />
                      </div>
                      <p className="mt-4 text-sm font-medium">Belum ada banner</p>
                      <p className="mt-1 text-xs text-muted-foreground">Upload banner pertama Anda di form sebelah</p>
                    </div>
                  ) : (
                    <div className="space-y-3">
                      {list.map((banner, index) => (
                        <div
                          key={banner.id}
                          className="group flex items-center gap-4 rounded-xl border bg-card p-3 transition-all hover:shadow-md animate-fade-in"
                          style={{ animationDelay: `${index * 60}ms` }}
                        >
                          <div className="flex-shrink-0 cursor-grab text-muted-foreground/40">
                            <GripVertical className="h-5 w-5" />
                          </div>
                          <div className="h-16 w-28 flex-shrink-0 overflow-hidden rounded-lg bg-muted">
                            {banner.image_url ? (
                              <img src={resolveImageUrl(banner.image_url)} alt={banner.title} className="h-full w-full object-cover" />
                            ) : (
                              <div className="flex h-full w-full items-center justify-center">
                                <div className="rounded bg-muted-foreground/10 p-2">
                                  <Image className="h-6 w-6 text-muted-foreground" />
                                </div>
                              </div>
                            )}
                          </div>
                          <div className="flex-1 min-w-0">
                            <p className="text-sm font-medium truncate">{banner.title || "-"}</p>
                            <p className="text-xs text-muted-foreground mt-0.5">
                              Posisi: {banner.position} • Urutan: {banner.order}
                            </p>
                          </div>
                          <Badge
                            variant={banner.is_active ? "default" : "secondary"}
                            className="cursor-default select-none"
                          >
                            {banner.is_active ? "Aktif" : "Nonaktif"}
                          </Badge>
                          <Button
                            variant="ghost"
                            size="icon"
                            className="h-8 w-8 text-muted-foreground opacity-0 transition-opacity group-hover:opacity-100"
                            onClick={() => openEdit(banner)}
                          >
                            <Edit className="h-4 w-4" />
                          </Button>
                          <Button
                            variant="ghost"
                            size="icon"
                            className="h-8 w-8 text-muted-foreground opacity-0 transition-opacity group-hover:opacity-100 hover:text-destructive"
                            onClick={() => handleDelete(banner)}
                          >
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
      </div>
    </div>
  );
};
export default Banners;