import { useEffect, useState } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Button } from "@/components/ui/button";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import api from "@/lib/api";
import { toast } from "sonner";
import { Save, Info, Bus, Train, Plane } from "lucide-react";

interface TransportConfig {
  slug: string;
  name: string;
  base_price: number;
  price_category_kecil: number;
  price_category_sedang: number;
  price_category_besar: number;
}

const transportMeta = {
  "titip-barang-bus": { name: "Bus", Icon: Bus, color: "text-green-600", bg: "bg-green-50" },
  "titip-barang-kereta": { name: "Kereta", Icon: Train, color: "text-blue-600", bg: "bg-blue-50" },
  "titip-barang-pesawat": { name: "Pesawat", Icon: Plane, color: "text-sky-600", bg: "bg-sky-50" },
};

const weightCategories = [
  { key: "price_category_kecil" as const, label: "Kategori Kecil", range: "0 – 5 kg", color: "bg-blue-50 border-blue-100" },
  { key: "price_category_sedang" as const, label: "Kategori Sedang", range: "5 – 10 kg", color: "bg-amber-50 border-amber-100" },
  { key: "price_category_besar" as const, label: "Kategori Besar", range: "10 – 20 kg", color: "bg-rose-50 border-rose-100" },
];

const TitipBarangConfig = () => {
  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState<string | null>(null);
  const [configs, setConfigs] = useState<TransportConfig[]>([
    { slug: "titip-barang-bus", name: "Bus", base_price: 0, price_category_kecil: 0, price_category_sedang: 0, price_category_besar: 0 },
    { slug: "titip-barang-kereta", name: "Kereta", base_price: 0, price_category_kecil: 0, price_category_sedang: 0, price_category_besar: 0 },
    { slug: "titip-barang-pesawat", name: "Pesawat", base_price: 0, price_category_kecil: 0, price_category_sedang: 0, price_category_besar: 0 },
  ]);

  useEffect(() => { fetchAllConfigs(); }, []);

  const fetchAllConfigs = async () => {
    try {
      setLoading(true);
      const newConfigs = await Promise.all(
        ["titip-barang-bus", "titip-barang-kereta", "titip-barang-pesawat"].map(async (slug) => {
          try {
            const res = await api.get(`/finance/pricing-config/${slug}`);
            const data = res.data.data;
            const meta = transportMeta[slug as keyof typeof transportMeta];
            const config: TransportConfig = {
              slug,
              name: meta.name,
              base_price: 0,
              price_category_kecil: 0,
              price_category_sedang: 0,
              price_category_besar: 0,
            };
            const profile = data.pricing_profiles?.[0];
            if (profile) {
              config.base_price = profile.base_price || 0;
              config.price_category_kecil = profile.price_category_kecil || 0;
              config.price_category_sedang = profile.price_category_sedang || 0;
              config.price_category_besar = profile.price_category_besar || 0;
            }
            return config;
          } catch {
            const meta = transportMeta[slug as keyof typeof transportMeta];
            return { slug, name: meta.name, base_price: 0, price_category_kecil: 0, price_category_sedang: 0, price_category_besar: 0 };
          }
        })
      );
      setConfigs(newConfigs);
    } catch (err: any) {
      console.error(err);
      toast.error("Gagal memuat konfigurasi titip barang");
    } finally {
      setLoading(false);
    }
  };

  const handleSave = async (slug: string) => {
    const config = configs.find((c) => c.slug === slug);
    if (!config) return;
    try {
      setSaving(slug);
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
      await api.put(`/finance/pricing-config/${slug}`, payload);
      toast.success(`Konfigurasi ${config.name} berhasil disimpan`);
      fetchAllConfigs();
    } catch (err: any) {
      console.error(err);
      toast.error(err.response?.data?.message || "Gagal menyimpan konfigurasi");
    } finally {
      setSaving(null);
    }
  };

  const updateConfig = (slug: string, updates: Partial<TransportConfig>) => {
    setConfigs(configs.map((c) => (c.slug === slug ? { ...c, ...updates } : c)));
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
      <Tabs defaultValue="titip-barang-bus" className="w-full">
        <TabsList className="grid w-full grid-cols-3 bg-gray-100/80 p-1 rounded-xl h-auto gap-1">
          {Object.entries(transportMeta).map(([slug, { name, Icon }]) => (
            <TabsTrigger
              key={slug}
              value={slug}
              className="flex items-center gap-2 rounded-lg py-2.5 text-sm font-medium transition-all data-[state=active]:bg-white data-[state=active]:shadow-sm data-[state=active]:text-primary"
            >
              <Icon className="w-4 h-4" />
              <span>{name}</span>
            </TabsTrigger>
          ))}
        </TabsList>

        {configs.map((config) => {
          const meta = transportMeta[config.slug as keyof typeof transportMeta];
          const { Icon } = meta;
          return (
            <TabsContent key={config.slug} value={config.slug} className="mt-4">
              <Card className="border border-gray-200 shadow-sm">
                <CardHeader className="pb-3 border-b border-gray-100">
                  <div className="flex items-center gap-2">
                    <div className={`p-1.5 ${meta.bg} rounded-lg`}>
                      <Icon className={`w-4 h-4 ${meta.color}`} />
                    </div>
                    <div>
                      <CardTitle className="text-base font-semibold text-gray-900">
                        Titip Barang via {config.name}
                      </CardTitle>
                      <div className="flex items-center gap-1.5 mt-0.5">
                        <Info className="w-3 h-3 text-gray-400" />
                        <p className="text-xs text-gray-500">
                          Formula: Harga Dasar Transportasi + (Berat × Harga per KG)
                        </p>
                      </div>
                    </div>
                  </div>
                </CardHeader>
                <CardContent className="pt-5 space-y-6">
                  {/* Harga Dasar */}
                  <div className="space-y-1.5">
                    <Label className="text-sm font-medium text-gray-700">
                      Harga Dasar Transportasi {config.name}
                    </Label>
                    <div className="relative max-w-xs">
                      <span className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400 text-sm font-medium">Rp</span>
                      <Input
                        type="text"
                        value={String(config.base_price ?? 0)}
                        onChange={(e) => {
                          const raw = e.target.value;
                          const digits = raw.replace(/\D/g, "");
                          const clean = digits.replace(/^0+(?=\d)/, "");
                          updateConfig(config.slug, { base_price: Number(clean || 0) });
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
                            <span className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400 text-xs font-medium">Rp</span>
                            <Input
                              type="text"
                              placeholder="0"
                              value={String(config[cat.key] ?? 0)}
                              onChange={(e) => {
                                const raw = e.target.value;
                                const digits = raw.replace(/\D/g, "");
                                const clean = digits.replace(/^0+(?=\d)/, "");
                                updateConfig(config.slug, { [cat.key]: Number(clean || 0) });
                              }}
                              className="pl-9 h-9 bg-white border-gray-200 text-sm focus:border-primary focus:ring-1 focus:ring-primary/20"
                            />
                          </div>
                        </div>
                      ))}
                    </div>
                  </div>

                  <div className="flex justify-end pt-1">
                    <Button
                      onClick={() => handleSave(config.slug)}
                      disabled={saving === config.slug}
                      className="gap-2 px-6"
                    >
                      <Save className="w-4 h-4" />
                      {saving === config.slug ? "Menyimpan..." : `Simpan Konfigurasi ${config.name}`}
                    </Button>
                  </div>
                </CardContent>
              </Card>
            </TabsContent>
          );
        })}
      </Tabs>
    </div>
  );
};

export default TitipBarangConfig;