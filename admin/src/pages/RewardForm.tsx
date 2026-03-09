import { useState, useEffect } from "react";
import { useNavigate, useParams } from "react-router-dom";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Upload, X, Edit, Plus, Gift, ChevronLeft, Star, Package } from "lucide-react";
import { toast } from "@/hooks/use-toast";
import { cn } from "@/lib/utils";
import { rewardApi } from "@/services/api";

const RewardForm = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  const [loading, setLoading] = useState(false);
  const [values, setValues] = useState({
    title: "",
    description: "",
    points_cost: 0,
    stock: 0,
    image_url: "",
  });

  const imageOptions = [
    { label: "Pilih gambar...", value: "" },
    { label: "Mug Nebeng (placeholder)", value: "https://via.placeholder.com/600x300?text=Mug" },
    { label: "Kaos Nebeng (placeholder)", value: "https://via.placeholder.com/600x300?text=Kaos" },
    { label: "Voucher Diskon (placeholder)", value: "https://via.placeholder.com/600x300?text=Voucher" },
    { label: "Custom URL", value: "custom" },
  ];

  const [isDragging, setIsDragging] = useState(false);
  const [ratioWarning, setRatioWarning] = useState<string | null>(null);

  useEffect(() => {
    if (id) {
      (async () => {
        try {
          const res = await rewardApi.getAllRewards();
          const found = (res.data || []).find((r: any) => String(r.id) === String(id));
          if (found) {
            setValues({
              title: found.title || "",
              description: found.description || "",
              points_cost: found.points_cost || 0,
              stock: found.stock || 0,
              image_url: found.image_url || "",
            });
          }
        } catch (err) {
          console.error("Failed to load reward for edit", err);
        }
      })();
    }
  }, [id]);

  const resolveImageUrl = (url?: string) => {
    if (!url) return url;
    if (url.startsWith("data:")) return url;
    try {
      let resolved = url.replace(/https?:\/\/10\.0\.2\.2(:\d+)?/g, 'http://localhost$1');
      const parsed = new URL(resolved, window.location.origin);
      if (parsed.pathname.startsWith('/uploads/')) {
        const backendBase = (import.meta.env.VITE_API_URL as string || 'http://localhost:3001/api').replace(/\/api\/?.*$/, '');
        return `${backendBase}${parsed.pathname}`;
      }
      return resolved;
    } catch (e) {}
    return url;
  };

  // Customer reward cards render images at ~200x120 (width:height = 5:3).
  // Use the same recommended ratio so admin uploads match the customer view.
  const RECOMMENDED_RATIO = 5 / 3; // 1.666...
  const RATIO_TOLERANCE = 0.12;
  const checkRatio = (img: HTMLImageElement) => {
    const ratio = img.naturalWidth / img.naturalHeight;
    const diff = Math.abs(ratio - RECOMMENDED_RATIO) / RECOMMENDED_RATIO;
    setRatioWarning(
      diff > RATIO_TOLERANCE
        ? "Rasio gambar tidak sesuai dengan tampilan customer (disarankan 5:3)."
        : null
    );
  };

  const readFileAsDataURL = (file: File): Promise<string> =>
    new Promise((resolve, reject) => {
      const fr = new FileReader();
      fr.onload = () => resolve(String(fr.result));
      fr.onerror = reject;
      fr.readAsDataURL(file);
    });

  const processFile = async (file: File) => {
    if (!file.type.startsWith("image/")) {
      toast({ title: "Format tidak didukung", description: "Silakan upload file gambar (JPG, PNG, WEBP)", variant: "destructive" });
      return;
    }
    if (file.size > 5 * 1024 * 1024) {
      toast({ title: "File terlalu besar", description: "Ukuran maksimal 5MB", variant: "destructive" });
      return;
    }
    const dataUrl = await readFileAsDataURL(file);
    setValues((s) => ({ ...s, image_url: dataUrl }));
    const img = new window.Image();
    img.onload = () => checkRatio(img);
    img.src = dataUrl;
  };

  const handlePick = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) processFile(file);
  };

  const handleDrop = async (e: React.DragEvent) => {
    e.preventDefault();
    setIsDragging(false);
    const file = e.dataTransfer?.files?.[0];
    if (file) processFile(file);
  };

  const clearImage = () => {
    setValues((s) => ({ ...s, image_url: "" }));
    setRatioWarning(null);
  };

  const handleChange = (k: string, v: any) => setValues((s) => ({ ...s, [k]: v }));

  const handleSubmit = async (e: any) => {
    e.preventDefault();
    setLoading(true);
    try {
      if (id) {
        await rewardApi.updateReward(id, values);
        toast({ title: "Reward berhasil diupdate" });
      } else {
        await rewardApi.createReward(values);
        toast({ title: "Reward berhasil dibuat" });
      }
      navigate("/dashboard/reward/catalog");
    } catch (err) {
      console.error(err);
      toast({ title: "Gagal menyimpan reward", variant: "destructive" });
    } finally {
      setLoading(false);
    }
  };

  const isEdit = Boolean(id);

  return (
    <div
      className="min-h-screen p-6 md:p-8"
      style={{ fontFamily: "'DM Sans', 'Helvetica Neue', sans-serif", backgroundColor: "#f7f7f8" }}
    >
      {/* Header */}
      <div className="flex flex-col md:flex-row md:items-end justify-between gap-4 mb-8">
        <div>
          <div className="flex items-center gap-2 mb-1">
            <span
              className="inline-flex items-center justify-center rounded-lg p-1.5"
              style={{ backgroundColor: "#1a1a2e", color: "#fff" }}
            >
              <Gift size={16} />
            </span>
            <span className="text-xs font-semibold uppercase tracking-widest" style={{ color: "#888" }}>
              Reward Management
            </span>
          </div>
          <h1
            className="text-3xl font-bold tracking-tight"
            style={{ color: "#0f0f1a", letterSpacing: "-0.02em" }}
          >
            {isEdit ? "Edit Reward" : "Buat Reward"}
          </h1>
          <p className="mt-1 text-sm" style={{ color: "#6b7280" }}>
            {isEdit
              ? "Perbarui informasi reward yang tersedia di katalog"
              : "Tambahkan reward baru agar dapat ditukar oleh pengguna"}
          </p>
        </div>

        <Button
          variant="ghost"
          onClick={() => navigate("/dashboard/reward/catalog")}
          className="self-start md:self-auto flex items-center gap-2 px-4 py-2 rounded-xl text-sm font-semibold h-auto"
          style={{ color: "#6b7280", backgroundColor: "#fff", border: "1px solid #ebebed" }}
        >
          <ChevronLeft size={15} />
          Kembali ke Katalog
        </Button>
      </div>

      {/* Content Grid */}
      <form onSubmit={handleSubmit}>
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Main Form */}
          <div className="lg:col-span-2 flex flex-col gap-5">
            {/* Basic Info Card */}
            <div
              className="rounded-2xl overflow-hidden"
              style={{ backgroundColor: "#fff", border: "1px solid #ebebed" }}
            >
              <div
                className="px-6 py-4"
                style={{ borderBottom: "1px solid #f0f0f2" }}
              >
                <h2 className="text-sm font-semibold" style={{ color: "#0f0f1a" }}>
                  Informasi Dasar
                </h2>
                <p className="text-xs mt-0.5" style={{ color: "#9ca3af" }}>
                  Nama dan deskripsi reward yang terlihat oleh pengguna
                </p>
              </div>
              <div className="px-6 py-5 flex flex-col gap-4">
                <div>
                  <label className="block text-xs font-semibold mb-1.5" style={{ color: "#374151" }}>
                    Nama Reward
                  </label>
                  <Input
                    value={values.title}
                    onChange={(e) => handleChange("title", e.target.value)}
                    placeholder="Contoh: Mug Eksklusif Nebeng"
                    required
                    className="rounded-xl text-sm"
                    style={{ border: "1px solid #e5e7eb", height: "40px" }}
                  />
                </div>
                <div>
                  <label className="block text-xs font-semibold mb-1.5" style={{ color: "#374151" }}>
                    Deskripsi
                  </label>
                  <Input
                    value={values.description}
                    onChange={(e) => handleChange("description", e.target.value)}
                    placeholder="Tulis deskripsi singkat tentang reward ini..."
                    className="rounded-xl text-sm"
                    style={{ border: "1px solid #e5e7eb", height: "40px" }}
                  />
                </div>
              </div>
            </div>

            {/* Image Card */}
            <div
              className="rounded-2xl overflow-hidden"
              style={{ backgroundColor: "#fff", border: "1px solid #ebebed" }}
            >
              <div
                className="px-6 py-4"
                style={{ borderBottom: "1px solid #f0f0f2" }}
              >
                <h2 className="text-sm font-semibold" style={{ color: "#0f0f1a" }}>
                  Gambar Reward
                </h2>
                <p className="text-xs mt-0.5" style={{ color: "#9ca3af" }}>
                  Rasio 16:9 disarankan • JPG, PNG, WEBP • Maks 5MB
                </p>
              </div>
              <div className="px-6 py-5">
                {values.image_url ? (
                  <div className="relative overflow-hidden rounded-xl border" style={{ borderColor: "#e5e7eb" }}>
                    <img
                      src={resolveImageUrl(values.image_url)}
                      alt="Preview"
                      className="h-52 w-full object-cover"
                    />
                    <button
                      type="button"
                      onClick={clearImage}
                      className="absolute right-3 top-3 rounded-full p-1.5 transition-all"
                      style={{ backgroundColor: "rgba(15,15,26,0.65)", color: "#fff" }}
                    >
                      <X className="h-4 w-4" />
                    </button>
                    {ratioWarning && (
                      <div
                        className="absolute bottom-0 left-0 right-0 px-4 py-2 text-xs font-medium"
                        style={{ backgroundColor: "#fef3c7", color: "#b45309" }}
                      >
                        ⚠ {ratioWarning}
                      </div>
                    )}
                  </div>
                ) : (
                  <div
                    onDragOver={(e) => { e.preventDefault(); setIsDragging(true); }}
                    onDragLeave={() => setIsDragging(false)}
                    onDrop={handleDrop}
                    onClick={() => document.getElementById("reward-file-input")?.click()}
                    className={cn(
                      "flex flex-col items-center justify-center rounded-xl border-2 border-dashed p-10 transition-all cursor-pointer select-none"
                    )}
                    style={{
                      borderColor: isDragging ? "#4f46e5" : "#d1d5db",
                      backgroundColor: isDragging ? "#eef2ff" : "#fafafa",
                    }}
                  >
                    <div
                      className="flex h-12 w-12 items-center justify-center rounded-xl mb-3"
                      style={{ backgroundColor: isDragging ? "#e0e7ff" : "#f0f0f2" }}
                    >
                      <Upload size={22} style={{ color: isDragging ? "#4f46e5" : "#9ca3af" }} />
                    </div>
                    <p className="text-sm font-semibold" style={{ color: "#374151" }}>
                      Drag &amp; drop gambar di sini
                    </p>
                    <p className="text-xs mt-1" style={{ color: "#9ca3af" }}>
                      atau klik untuk memilih file
                    </p>
                    <input
                      id="reward-file-input"
                      type="file"
                      accept="image/*"
                      className="hidden"
                      onChange={handlePick}
                    />
                  </div>
                )}
              </div>
            </div>
          </div>

          {/* Sidebar */}
          <div className="flex flex-col gap-5">
            {/* Points & Stock Card */}
            <div
              className="rounded-2xl overflow-hidden"
              style={{ backgroundColor: "#fff", border: "1px solid #ebebed" }}
            >
              <div
                className="px-6 py-4"
                style={{ borderBottom: "1px solid #f0f0f2" }}
              >
                <h2 className="text-sm font-semibold" style={{ color: "#0f0f1a" }}>
                  Poin &amp; Stok
                </h2>
                <p className="text-xs mt-0.5" style={{ color: "#9ca3af" }}>
                  Atur biaya penukaran dan ketersediaan
                </p>
              </div>
              <div className="px-6 py-5 flex flex-col gap-4">
                <div>
                  <label className="flex items-center gap-1.5 text-xs font-semibold mb-1.5" style={{ color: "#374151" }}>
                    <Star size={12} style={{ color: "#d97706" }} />
                    Poin yang Dibutuhkan
                  </label>
                  <div className="relative">
                    <Input
                      type="number"
                      min={0}
                      value={values.points_cost}
                      onChange={(e) => handleChange("points_cost", Number(e.target.value))}
                      className="rounded-xl text-sm pr-12"
                      style={{ border: "1px solid #e5e7eb", height: "40px" }}
                    />
                    <span
                      className="absolute right-3 top-1/2 -translate-y-1/2 text-xs font-semibold"
                      style={{ color: "#d97706" }}
                    >
                      pts
                    </span>
                  </div>
                </div>
                <div>
                  <label className="flex items-center gap-1.5 text-xs font-semibold mb-1.5" style={{ color: "#374151" }}>
                    <Package size={12} style={{ color: "#059669" }} />
                    Stok Tersedia
                  </label>
                  <Input
                    type="number"
                    min={0}
                    value={values.stock}
                    onChange={(e) => handleChange("stock", Number(e.target.value))}
                    className="rounded-xl text-sm"
                    style={{ border: "1px solid #e5e7eb", height: "40px" }}
                  />
                </div>
              </div>
            </div>

            {/* Preview Card */}
            {(values.title || values.points_cost > 0) && (
              <div
                className="rounded-2xl overflow-hidden"
                style={{ backgroundColor: "#fff", border: "1px solid #ebebed" }}
              >
                <div
                  className="px-6 py-4"
                  style={{ borderBottom: "1px solid #f0f0f2" }}
                >
                  <h2 className="text-sm font-semibold" style={{ color: "#0f0f1a" }}>
                    Preview
                  </h2>
                </div>
                <div className="px-6 py-5">
                  <div className="rounded-xl overflow-hidden" style={{ border: "1px solid #f0f0f2" }}>
                    {values.image_url && (
                      <img
                        src={resolveImageUrl(values.image_url)}
                        alt="preview"
                        className="w-full h-28 object-cover"
                      />
                    )}
                    <div className="p-3">
                      <p className="font-semibold text-sm" style={{ color: "#0f0f1a" }}>
                        {values.title || "Nama Reward"}
                      </p>
                      {values.description && (
                        <p className="text-xs mt-0.5 line-clamp-2" style={{ color: "#9ca3af" }}>
                          {values.description}
                        </p>
                      )}
                      <div className="flex items-center justify-between mt-2">
                        <span
                          className="inline-flex items-center gap-1 text-xs font-semibold px-2 py-0.5 rounded-full"
                          style={{ backgroundColor: "#fef3c7", color: "#b45309" }}
                        >
                          <Star size={10} />
                          {values.points_cost} pts
                        </span>
                        <span className="text-xs" style={{ color: "#9ca3af" }}>
                          Stok: {values.stock}
                        </span>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            )}

            {/* Action Buttons */}
            <div className="flex flex-col gap-2">
              <Button
                type="submit"
                disabled={loading}
                className="w-full flex items-center justify-center gap-2 py-2.5 rounded-xl text-sm font-semibold"
                style={{ backgroundColor: "#1a1a2e", color: "#fff", border: "none", height: "42px" }}
              >
                {loading ? (
                  <div
                    className="w-4 h-4 rounded-full border-2 animate-spin"
                    style={{ borderColor: "rgba(255,255,255,0.3)", borderTopColor: "#fff" }}
                  />
                ) : isEdit ? (
                  <>
                    <Edit size={15} />
                    Simpan Perubahan
                  </>
                ) : (
                  <>
                    <Plus size={15} />
                    Buat Reward
                  </>
                )}
              </Button>
              <Button
                type="button"
                variant="ghost"
                onClick={() => navigate("/dashboard/reward/catalog")}
                className="w-full rounded-xl text-sm font-semibold h-10"
                style={{ color: "#6b7280", border: "1px solid #e5e7eb" }}
              >
                Batal
              </Button>
            </div>
          </div>
        </div>
      </form>
    </div>
  );
};

export default RewardForm;