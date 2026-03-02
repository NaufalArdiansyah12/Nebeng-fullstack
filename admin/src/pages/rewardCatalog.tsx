import { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { Plus, Gift, Pencil, Package, Star } from "lucide-react";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { rewardApi } from "@/services/api";

const RewardCatalog = () => {
  const navigate = useNavigate();
  const [rewards, setRewards] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  const resolveImageUrl = (url?: string) => {
    if (!url) return url;
    if (url.startsWith('data:')) return url;
    try {
      if (url.startsWith('/uploads')) {
        const apiBase = (import.meta.env.VITE_API_URL as string) || 'http://localhost:3001/api';
        const origin = apiBase.replace(/\/api\/?$/, '');
        return `${origin}${url}`;
      }
      if (url.includes('10.0.2.2')) {
        return url.replace(/https?:\/\/10\.0\.2\.2(:\d+)?/, `${window.location.protocol}//localhost$1`);
      }
    } catch (e) {}
    return url;
  };

  useEffect(() => {
    loadRewards();
  }, []);

  const loadRewards = async () => {
    setLoading(true);
    try {
      const res = await rewardApi.getAllRewards();
      setRewards(res.data || []);
    } catch (err) {
      console.error("Failed loading rewards", err);
    } finally {
      setLoading(false);
    }
  };

  const totalStock = rewards.reduce((sum, r) => sum + (r.stock ?? 0), 0);

  return (
    <div
      className="min-h-screen p-6 md:p-8 bg-white"
      style={{ fontFamily: "'DM Sans', 'Helvetica Neue', sans-serif" }}
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
            Katalog Reward
          </h1>
          <p className="mt-1 text-sm" style={{ color: "#6b7280" }}>
            Kelola master reward — produk &amp; promo yang dapat ditukar pengguna
          </p>
        </div>

        <Button
          onClick={() => navigate("/dashboard/reward/catalog/create")}
          className="self-start md:self-auto flex items-center gap-2 px-5 py-2.5 rounded-xl text-sm font-semibold shadow-none transition-all"
          style={{
            backgroundColor: "#1a1a2e",
            color: "#fff",
            border: "none",
          }}
        >
          <Plus size={15} />
          Buat Reward
        </Button>
      </div>

      {/* Summary Cards */}
      <div className="grid grid-cols-2 md:grid-cols-3 gap-4 mb-6">
        {[
          {
            icon: <Gift size={18} />,
            label: "Total Reward",
            value: rewards.length,
            accent: "#e0e7ff",
            iconColor: "#4f46e5",
          },
          {
            icon: <Package size={18} />,
            label: "Total Stok",
            value: totalStock,
            accent: "#d1fae5",
            iconColor: "#059669",
          },
          {
            icon: <Star size={18} />,
            label: "Rata-rata Poin",
            value: rewards.length
              ? Math.round(rewards.reduce((s, r) => s + (r.points_cost || 0), 0) / rewards.length) + " pts"
              : "—",
            accent: "#fef3c7",
            iconColor: "#d97706",
          },
        ].map((stat, i) => (
          <div
            key={i}
            className="rounded-2xl p-4 flex items-center gap-4"
            style={{ backgroundColor: "#fff", border: "1px solid #ebebed" }}
          >
            <span
              className="flex items-center justify-center rounded-xl p-2.5"
              style={{ backgroundColor: stat.accent, color: stat.iconColor }}
            >
              {stat.icon}
            </span>
            <div>
              <p className="text-xs font-medium" style={{ color: "#9ca3af" }}>
                {stat.label}
              </p>
              <p className="text-xl font-bold" style={{ color: "#0f0f1a", letterSpacing: "-0.02em" }}>
                {stat.value}
              </p>
            </div>
          </div>
        ))}
      </div>

      {/* Table Card */}
      <div
        className="rounded-2xl overflow-hidden"
        style={{ backgroundColor: "#fff", border: "1px solid #ebebed" }}
      >
        {/* Card Header */}
        <div
          className="flex items-center justify-between px-6 py-4"
          style={{ borderBottom: "1px solid #f0f0f2" }}
        >
          <h2 className="text-sm font-semibold" style={{ color: "#0f0f1a" }}>
            Daftar Reward
          </h2>
          <span className="text-xs px-2.5 py-1 rounded-full font-medium" style={{ backgroundColor: "#f0f0f2", color: "#6b7280" }}>
            {rewards.length} item
          </span>
        </div>

        {loading ? (
          <div className="py-20 flex flex-col items-center gap-3" style={{ color: "#c4c4cc" }}>
            <div
              className="w-8 h-8 rounded-full border-2 animate-spin"
              style={{ borderColor: "#e5e5ea", borderTopColor: "#1a1a2e" }}
            />
            <p className="text-sm">Memuat data…</p>
          </div>
        ) : rewards.length === 0 ? (
          <div className="py-20 flex flex-col items-center gap-3" style={{ color: "#c4c4cc" }}>
            <Gift size={36} strokeWidth={1.5} />
            <p className="text-sm font-medium">Belum ada reward</p>
            <p className="text-xs">Mulai dengan membuat reward pertama Anda</p>
          </div>
        ) : (
          <Table>
            <TableHeader>
              <TableRow style={{ backgroundColor: "#fafafa" }}>
                <TableHead className="w-12 text-xs font-semibold pl-6" style={{ color: "#9ca3af" }}>
                  ID
                </TableHead>
                <TableHead className="text-xs font-semibold" style={{ color: "#9ca3af" }}>
                  Reward
                </TableHead>
                <TableHead className="w-36 text-xs font-semibold" style={{ color: "#9ca3af" }}>
                  Poin
                </TableHead>
                <TableHead className="w-28 text-xs font-semibold" style={{ color: "#9ca3af" }}>
                  Stok
                </TableHead>
                <TableHead className="w-36 text-xs font-semibold" style={{ color: "#9ca3af" }}>
                  Dibuat
                </TableHead>
                <TableHead className="w-24 text-xs font-semibold text-center pr-6" style={{ color: "#9ca3af" }}>
                  Aksi
                </TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {rewards.map((r, idx) => (
                <TableRow
                  key={r.id}
                  className="group transition-colors"
                  style={{
                    borderTop: idx === 0 ? "none" : "1px solid #f5f5f7",
                  }}
                >
                  <TableCell className="pl-6">
                    <span
                      className="text-xs font-mono px-2 py-0.5 rounded-md"
                      style={{ backgroundColor: "#f5f5f7", color: "#9ca3af" }}
                    >
                      #{r.id}
                    </span>
                  </TableCell>

                  <TableCell>
                    <div className="flex items-center gap-3">
                      <div className="flex-shrink-0">
                        {r.image_url ? (
                          <img
                            src={resolveImageUrl(r.image_url)}
                            alt={r.title}
                            className="w-16 h-10 object-cover rounded"
                          />
                        ) : (
                          <div className="w-16 h-10 bg-gray-100 rounded" />
                        )}
                      </div>
                      <div>
                        <p className="font-semibold text-sm" style={{ color: "#0f0f1a" }}>
                          {r.title}
                        </p>
                        {r.description && (
                          <p className="text-xs mt-0.5 line-clamp-1" style={{ color: "#9ca3af" }}>
                            {r.description}
                          </p>
                        )}
                      </div>
                    </div>
                  </TableCell>

                  <TableCell>
                    <span
                      className="inline-flex items-center gap-1 text-xs font-semibold px-2.5 py-1 rounded-full"
                      style={{ backgroundColor: "#fef3c7", color: "#b45309" }}
                    >
                      <Star size={11} />
                      {r.points_cost} pts
                    </span>
                  </TableCell>

                  <TableCell>
                    <Badge
                      className="text-xs font-semibold rounded-full border-0"
                      style={
                        (r.stock ?? 0) === 0
                          ? { backgroundColor: "#fee2e2", color: "#dc2626" }
                          : (r.stock ?? 0) < 10
                          ? { backgroundColor: "#fef3c7", color: "#d97706" }
                          : { backgroundColor: "#d1fae5", color: "#059669" }
                      }
                    >
                      {r.stock ?? 0}
                    </Badge>
                  </TableCell>

                  <TableCell className="text-xs" style={{ color: "#9ca3af" }}>
                    {new Date(r.created_at || r.createdAt || Date.now()).toLocaleDateString("id-ID", {
                      day: "numeric",
                      month: "short",
                      year: "numeric",
                    })}
                  </TableCell>

                  <TableCell className="text-center pr-6">
                    <Button
                      variant="ghost"
                      size="sm"
                      onClick={() => navigate(`/dashboard/reward/catalog/${r.id}/edit`)}
                      className="flex items-center gap-1.5 text-xs font-semibold rounded-lg px-3 h-8 transition-colors"
                      style={{ color: "#4f46e5" }}
                    >
                      <Pencil size={12} />
                      Edit
                    </Button>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        )}
      </div>
    </div>
  );
};

export default RewardCatalog;