import { useEffect, useState } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Button } from "@/components/ui/button";
import api from "@/lib/api";
import { toast } from "sonner";
import { Save, Car, Users, Package, LayoutGrid } from "lucide-react";

interface WeightRule {
  category: string;
  price_per_kg: number;
}

interface MobilConfigData {
  hanya_tebengan: { base_price: number; price_per_km: number; min_price: number };
  hanya_barang: { weight_rules: WeightRule[] };
  tebengan_dan_barang: { base_price: number; price_per_km: number; weight_rules: WeightRule[] };
}

const weightCategories = [
  { slug: "kecil", label: "Kecil", range: "0 – 5 kg", color: "bg-blue-50 border-blue-100" },
  { slug: "sedang", label: "Sedang", range: "5 – 10 kg", color: "bg-amber-50 border-amber-100" },
  { slug: "besar", label: "Besar", range: "10 – 20 kg", color: "bg-rose-50 border-rose-100" },
];

const WeightRulesSection = ({
  rules,
  onChange,
}: {
  rules: WeightRule[];
  onChange: (idx: number, val: number) => void;
}) => (
  <div className="space-y-2">
    <Label className="text-sm font-semibold text-gray-700">Harga per KG Berdasarkan Kategori Berat</Label>
    {weightCategories.map((cat, idx) => (
      <div key={cat.slug} className={`flex items-center gap-4 p-3 rounded-lg border ${cat.color}`}>
        <div className="flex-1 min-w-0">
          <p className="text-sm font-medium text-gray-800 capitalize">{cat.label}</p>
          <p className="text-xs text-gray-500">{cat.range}</p>
        </div>
          <div className="relative w-44">
          <span className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400 text-xs font-medium">Rp</span>
          <Input
            type="text"
            placeholder="0"
            value={String(rules[idx]?.price_per_kg ?? 0)}
            onChange={(e) => {
              const raw = e.target.value;
              const digits = raw.replace(/\D/g, "");
              const clean = digits.replace(/^0+(?=\d)/, "");
              onChange(idx, Number(clean || 0));
            }}
            className="pl-9 h-9 bg-white border-gray-200 text-sm focus:border-primary focus:ring-1 focus:ring-primary/20"
          />
        </div>
      </div>
    ))}
  </div>
);

const MobilConfig = () => {
  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [config, setConfig] = useState<MobilConfigData>({
    hanya_tebengan: { base_price: 0, price_per_km: 0, min_price: 0 },
    hanya_barang: {
      weight_rules: [
        { category: "kecil", price_per_kg: 0 },
        { category: "sedang", price_per_kg: 0 },
        { category: "besar", price_per_kg: 0 },
      ],
    },
    tebengan_dan_barang: {
      base_price: 0,
      price_per_km: 0,
      weight_rules: [
        { category: "kecil", price_per_kg: 0 },
        { category: "sedang", price_per_kg: 0 },
        { category: "besar", price_per_kg: 0 },
      ],
    },
  });

  useEffect(() => { fetchConfig(); }, []);

  const fetchConfig = async () => {
    try {
      setLoading(true);
      const res = await api.get("/finance/pricing-config/mobil");
      const data = res.data.data;
      const newConfig: MobilConfigData = {
        hanya_tebengan: { base_price: 0, price_per_km: 0, min_price: 0 },
        hanya_barang: {
          weight_rules: [
            { category: "kecil", price_per_kg: 0 },
            { category: "sedang", price_per_kg: 0 },
            { category: "besar", price_per_kg: 0 },
          ],
        },
        tebengan_dan_barang: {
          base_price: 0,
          price_per_km: 0,
          weight_rules: [
            { category: "kecil", price_per_kg: 0 },
            { category: "sedang", price_per_kg: 0 },
            { category: "besar", price_per_kg: 0 },
          ],
        },
      };

      data.pricing_profiles?.forEach((profile: any) => {
        if (profile.name.includes("Hanya Tebengan")) {
          newConfig.hanya_tebengan = {
            base_price: profile.base_price || 0,
            price_per_km: profile.price_per_km || 0,
            min_price: profile.min_price || 0,
          };
        } else if (profile.name.includes("Hanya Barang")) {
          profile.rules?.forEach((rule: any) => {
            const idx = newConfig.hanya_barang.weight_rules.findIndex(
              (r) => r.category === rule.weight_category?.slug
            );
            if (idx !== -1) newConfig.hanya_barang.weight_rules[idx].price_per_kg = rule.price || 0;
          });
        } else if (profile.name.includes("Tebengan dan Barang")) {
          newConfig.tebengan_dan_barang.base_price = profile.base_price || 0;
          newConfig.tebengan_dan_barang.price_per_km = profile.price_per_km || 0;
          profile.rules?.forEach((rule: any) => {
            const idx = newConfig.tebengan_dan_barang.weight_rules.findIndex(
              (r) => r.category === rule.weight_category?.slug
            );
            if (idx !== -1) newConfig.tebengan_dan_barang.weight_rules[idx].price_per_kg = rule.price || 0;
          });
        }
      });

      setConfig(newConfig);
    } catch (err: any) {
      console.error(err);
      toast.error("Gagal memuat konfigurasi mobil");
    } finally {
      setLoading(false);
    }
  };

  const handleSave = async () => {
    try {
      setSaving(true);
      const payload = {
        configs: [
          {
            service_type: "hanya_tebengan",
            base_price: config.hanya_tebengan.base_price,
            price_per_km: config.hanya_tebengan.price_per_km,
            min_price: config.hanya_tebengan.min_price,
          },
          {
            service_type: "hanya_barang",
            base_price: 0,
            price_per_km: 0,
            weight_rules: config.hanya_barang.weight_rules,
          },
          {
            service_type: "tebengan_dan_barang",
            base_price: config.tebengan_dan_barang.base_price,
            price_per_km: config.tebengan_dan_barang.price_per_km,
            weight_rules: config.tebengan_dan_barang.weight_rules,
          },
        ],
      };
      await api.put("/finance/pricing-config/mobil", payload);
      toast.success("Konfigurasi mobil berhasil disimpan");
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

  const rpInput = (value: number, onChange: (v: number) => void) => (
    <div className="relative">
      <span className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400 text-sm font-medium">Rp</span>
      <Input
        type="text"
        value={String(value ?? 0)}
        onChange={(e) => {
          const raw = e.target.value;
          const digits = raw.replace(/\D/g, "");
          const clean = digits.replace(/^0+(?=\d)/, "");
          onChange(Number(clean || 0));
        }}
        className="pl-10 h-10 border-gray-200 focus:border-primary focus:ring-1 focus:ring-primary/20 bg-white"
      />
    </div>
  );

  return (
    <div className="space-y-4">
      {/* Hanya Tebengan */}
      <Card className="border border-gray-200 shadow-sm">
        <CardHeader className="pb-3 border-b border-gray-100">
          <div className="flex items-center gap-2">
            <div className="p-1.5 bg-blue-50 rounded-lg">
              <Users className="w-4 h-4 text-blue-600" />
            </div>
            <CardTitle className="text-base font-semibold text-gray-900">Hanya Tebengan</CardTitle>
          </div>
        </CardHeader>
        <CardContent className="pt-5">
          <div className="grid grid-cols-3 gap-4">
            <div className="space-y-1.5">
              <Label className="text-sm text-gray-700">Harga Dasar</Label>
              {rpInput(config.hanya_tebengan.base_price, (v) =>
                setConfig({ ...config, hanya_tebengan: { ...config.hanya_tebengan, base_price: v } })
              )}
            </div>
            <div className="space-y-1.5">
              <Label className="text-sm text-gray-700">Harga per KM</Label>
              {rpInput(config.hanya_tebengan.price_per_km, (v) =>
                setConfig({ ...config, hanya_tebengan: { ...config.hanya_tebengan, price_per_km: v } })
              )}
            </div>
            <div className="space-y-1.5">
              <Label className="text-sm text-gray-700">Harga Minimum</Label>
              {rpInput(config.hanya_tebengan.min_price, (v) =>
                setConfig({ ...config, hanya_tebengan: { ...config.hanya_tebengan, min_price: v } })
              )}
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Hanya Barang */}
      <Card className="border border-gray-200 shadow-sm">
        <CardHeader className="pb-3 border-b border-gray-100">
          <div className="flex items-center gap-2">
            <div className="p-1.5 bg-amber-50 rounded-lg">
              <Package className="w-4 h-4 text-amber-600" />
            </div>
            <CardTitle className="text-base font-semibold text-gray-900">Hanya Barang</CardTitle>
          </div>
        </CardHeader>
        <CardContent className="pt-5">
          <WeightRulesSection
            rules={config.hanya_barang.weight_rules}
            onChange={(idx, val) => {
              const newRules = [...config.hanya_barang.weight_rules];
              newRules[idx].price_per_kg = val;
              setConfig({ ...config, hanya_barang: { weight_rules: newRules } });
            }}
          />
        </CardContent>
      </Card>

      {/* Tebengan dan Barang */}
      <Card className="border border-gray-200 shadow-sm">
        <CardHeader className="pb-3 border-b border-gray-100">
          <div className="flex items-center gap-2">
            <div className="p-1.5 bg-purple-50 rounded-lg">
              <LayoutGrid className="w-4 h-4 text-purple-600" />
            </div>
            <CardTitle className="text-base font-semibold text-gray-900">Tebengan dan Barang</CardTitle>
          </div>
        </CardHeader>
        <CardContent className="pt-5 space-y-5">
          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-1.5">
              <Label className="text-sm text-gray-700">Harga Dasar</Label>
              {rpInput(config.tebengan_dan_barang.base_price, (v) =>
                setConfig({ ...config, tebengan_dan_barang: { ...config.tebengan_dan_barang, base_price: v } })
              )}
            </div>
            <div className="space-y-1.5">
              <Label className="text-sm text-gray-700">Harga per KM</Label>
              {rpInput(config.tebengan_dan_barang.price_per_km, (v) =>
                setConfig({ ...config, tebengan_dan_barang: { ...config.tebengan_dan_barang, price_per_km: v } })
              )}
            </div>
          </div>
          <WeightRulesSection
            rules={config.tebengan_dan_barang.weight_rules}
            onChange={(idx, val) => {
              const newRules = [...config.tebengan_dan_barang.weight_rules];
              newRules[idx].price_per_kg = val;
              setConfig({
                ...config,
                tebengan_dan_barang: { ...config.tebengan_dan_barang, weight_rules: newRules },
              });
            }}
          />
        </CardContent>
      </Card>

      <div className="flex justify-end pt-1">
        <Button onClick={handleSave} disabled={saving} className="gap-2 px-6">
          <Save className="w-4 h-4" />
          {saving ? "Menyimpan..." : "Simpan Konfigurasi"}
        </Button>
      </div>
    </div>
  );
};

export default MobilConfig;