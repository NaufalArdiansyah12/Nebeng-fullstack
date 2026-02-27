import { useEffect, useState } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Button } from "@/components/ui/button";
import api from "@/lib/api";
import { toast } from "sonner";
import { Info, Save, Package2 } from "lucide-react";

interface BarangConfigData {
  base_price: number;
  price_category_kecil: number;
  price_category_sedang: number;
  price_category_besar: number;
}

const weightCategories = [
  { key: "price_category_kecil" as const, label: "Kategori Kecil", range: "0 – 5 kg", color: "bg-blue-50 border-blue-100" },
  { key: "price_category_sedang" as const, label: "Kategori Sedang", range: "5 – 10 kg", color: "bg-amber-50 border-amber-100" },
  { key: "price_category_besar" as const, label: "Kategori Besar", range: "10 – 20 kg", color: "bg-rose-50 border-rose-100" },
];

const BarangConfig = () => {
  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [config, setConfig] = useState<BarangConfigData>({
    base_price: 0,
    price_category_kecil: 0,
    price_category_sedang: 0,
    price_category_besar: 0,
  });

  useEffect(() => {
    fetchConfig();
  }, []);

  const fetchConfig = async () => {
    try {
      setLoading(true);
      const res = await api.get("/finance/pricing-config/barang");
      const data = res.data.data;
      const profile = data.pricing_profiles?.[0];
      if (profile) {
        setConfig({
          base_price: profile.base_price || 0,
          price_category_kecil: profile.price_category_kecil || 0,
          price_category_sedang: profile.price_category_sedang || 0,
          price_category_besar: profile.price_category_besar || 0,
        });
      }
    } catch (err: any) {
      console.error(err);
      toast.error("Gagal memuat konfigurasi barang");
    } finally {
      setLoading(false);
    }
  };

  const handleSave = async () => {
    try {
      setSaving(true);
      const roundNearest = (v: number, n = 500) => Math.round((v || 0) / n) * n;

      const payload = {
        configs: [
          {
            base_price: roundNearest(config.base_price),
            price_per_km: 0,
            price_category_kecil: roundNearest(config.price_category_kecil),
            price_category_sedang: roundNearest(config.price_category_sedang),
            price_category_besar: roundNearest(config.price_category_besar),
          },
        ],
      };

      await api.put("/finance/pricing-config/barang", payload);
      toast.success("Konfigurasi barang berhasil disimpan");
      fetchConfig();
    } catch (err: any) {
      console.error(err);
      toast.error(err.response?.data?.message || "Gagal menyimpan konfigurasi");
    } finally {
      setSaving(false);
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center py-16 text-gray-400 text-sm">
        <div className="animate-spin rounded-full h-5 w-5 border-b-2 border-primary mr-3" />
        Memuat konfigurasi...
      </div>
    );
  }

  return (
    <div className="space-y-4">
      <Card className="border border-gray-200 shadow-sm">
        <CardHeader className="pb-3 border-b border-gray-100">
          <div className="flex items-center gap-2">
            <div className="p-1.5 bg-primary/10 rounded-lg">
              <Package2 className="w-4 h-4 text-primary" />
            </div>
            <div>
              <CardTitle className="text-base font-semibold text-gray-900">Tebengan Barang</CardTitle>
              <div className="flex items-center gap-1.5 mt-0.5">
                <Info className="w-3 h-3 text-gray-400" />
                <p className="text-xs text-gray-500">Formula: Harga Dasar + (Berat × Harga per KG)</p>
              </div>
            </div>
          </div>
        </CardHeader>
        <CardContent className="pt-5 space-y-6">
          {/* Harga Dasar */}
          <div className="space-y-1.5">
            <Label className="text-sm font-medium text-gray-700">Harga Dasar</Label>
              <div className="relative">
              <span className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400 text-sm font-medium">Rp</span>
              <Input
                type="text"
                value={String(config.base_price ?? 0)}
                onChange={(e) => {
                  const raw = e.target.value;
                  const digits = raw.replace(/\D/g, "");
                  const clean = digits.replace(/^0+(?=\d)/, "");
                  setConfig({ ...config, base_price: Number(clean || 0) });
                }}
                className="pl-10 h-10 border-gray-200 focus:border-primary focus:ring-1 focus:ring-primary/20 bg-white"
              />
            </div>
          </div>

          {/* Weight Categories */}
          <div className="space-y-3">
            <Label className="text-sm font-semibold text-gray-700">Harga per KG Berdasarkan Kategori Berat</Label>
            <div className="grid grid-cols-1 gap-3">
              {weightCategories.map((cat) => (
                <div key={cat.key} className={`flex items-center gap-4 p-3.5 rounded-lg border ${cat.color}`}>
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-medium text-gray-800">{cat.label}</p>
                    <p className="text-xs text-gray-500">{cat.range}</p>
                  </div>
                  <div className="relative w-48">
                    <span className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400 text-sm font-medium">Rp</span>
                    <Input
                      type="text"
                      placeholder="0"
                      value={String(config[cat.key] ?? 0)}
                      onChange={(e) => {
                        const raw = e.target.value;
                        const digits = raw.replace(/\D/g, "");
                        const clean = digits.replace(/^0+(?=\d)/, "");
                        setConfig({ ...config, [cat.key]: Number(clean || 0) });
                      }}
                      className="pl-10 h-9 bg-white border-gray-200 text-sm focus:border-primary focus:ring-1 focus:ring-primary/20"
                    />
                  </div>
                </div>
              ))}
            </div>
          </div>
        </CardContent>
      </Card>

      <div className="flex justify-end pt-1">
        <Button onClick={handleSave} disabled={saving} size="default" className="gap-2 px-6">
          <Save className="w-4 h-4" />
          {saving ? "Menyimpan..." : "Simpan Konfigurasi"}
        </Button>
      </div>
    </div>
  );
};

export default BarangConfig;