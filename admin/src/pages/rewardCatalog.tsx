import { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { Plus, Gift, Pencil, Package, Star, Search } from "lucide-react";
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
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { rewardApi } from "@/services/api";

const RewardCatalog = () => {
  const navigate = useNavigate();
  const [rewards, setRewards] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState("");

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
  const avgPoints = rewards.length
    ? Math.round(rewards.reduce((s, r) => s + (r.points_cost || 0), 0) / rewards.length)
    : null;

  const filteredRewards = rewards.filter((r) =>
    r.title?.toLowerCase().includes(searchTerm.toLowerCase()) ||
    r.description?.toLowerCase().includes(searchTerm.toLowerCase())
  );

  const getStockBadge = (stock: number) => {
    if (stock === 0)
      return <Badge className="bg-red-100 text-red-700 hover:bg-red-100 border-0">{stock}</Badge>;
    if (stock < 10)
      return <Badge className="bg-yellow-100 text-yellow-700 hover:bg-yellow-100 border-0">{stock}</Badge>;
    return <Badge className="bg-green-100 text-green-700 hover:bg-green-100 border-0">{stock}</Badge>;
  };

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Katalog Reward</h1>
          <p className="text-muted-foreground mt-1">
            Kelola master reward — produk &amp; promo yang dapat ditukar pengguna
          </p>
        </div>
        <Button onClick={() => navigate("/dashboard/reward/catalog/create")} className="gap-2">
          <Plus size={16} />
          Buat Reward
        </Button>
      </div>

      {/* Summary Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <Card className="shadow-sm">
          <CardContent className="pt-5 pb-5">
            <div className="flex items-center gap-4">
              <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-indigo-100">
                <Gift size={18} className="text-indigo-600" />
              </div>
              <div>
                <p className="text-sm text-muted-foreground">Total Reward</p>
                <p className="text-2xl font-bold">{rewards.length}</p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card className="shadow-sm">
          <CardContent className="pt-5 pb-5">
            <div className="flex items-center gap-4">
              <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-emerald-100">
                <Package size={18} className="text-emerald-600" />
              </div>
              <div>
                <p className="text-sm text-muted-foreground">Total Stok</p>
                <p className="text-2xl font-bold">{totalStock}</p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card className="shadow-sm">
          <CardContent className="pt-5 pb-5">
            <div className="flex items-center gap-4">
              <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-amber-100">
                <Star size={18} className="text-amber-600" />
              </div>
              <div>
                <p className="text-sm text-muted-foreground">Rata-rata Poin</p>
                <p className="text-2xl font-bold">{avgPoints !== null ? `${avgPoints} pts` : "—"}</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Table Card */}
      <Card className="shadow-sm">
        <CardHeader className="pb-4">
          <div className="flex items-center justify-between">
            <CardTitle className="text-xl font-semibold">Daftar Reward</CardTitle>
            <div className="relative w-64">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-muted-foreground" size={16} />
              <Input
                placeholder="Cari reward..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="pl-9 h-9"
              />
            </div>
          </div>
        </CardHeader>
        <CardContent className="p-0">
          {loading ? (
            <div className="flex flex-col items-center justify-center py-16 gap-3 text-muted-foreground">
              <div className="h-7 w-7 rounded-full border-2 border-border border-t-foreground animate-spin" />
              <p className="text-sm">Memuat data...</p>
            </div>
          ) : filteredRewards.length === 0 ? (
            <div className="flex flex-col items-center justify-center py-16 gap-2 text-muted-foreground">
              <Gift size={36} strokeWidth={1.5} />
              <p className="text-sm font-medium">
                {searchTerm ? "Reward tidak ditemukan" : "Belum ada reward"}
              </p>
              <p className="text-xs">
                {searchTerm ? "Coba kata kunci lain" : "Mulai dengan membuat reward pertama Anda"}
              </p>
            </div>
          ) : (
            <div className="border-t overflow-hidden">
              <Table>
                <TableHeader>
                  <TableRow className="bg-muted/50 hover:bg-muted/50">
                    <TableHead className="w-12">ID</TableHead>
                    <TableHead>Reward</TableHead>
                    <TableHead className="w-36">Poin</TableHead>
                    <TableHead className="w-28">Stok</TableHead>
                    <TableHead className="w-36">Dibuat</TableHead>
                    <TableHead className="w-20 text-center">Aksi</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {filteredRewards.map((r) => (
                    <TableRow key={r.id} className="hover:bg-muted/30">
                      <TableCell>
                        <span className="text-xs font-mono text-muted-foreground bg-muted px-1.5 py-0.5 rounded">
                          #{r.id}
                        </span>
                      </TableCell>

                      <TableCell>
                        <div className="flex items-center gap-3">
                          <div className="flex-shrink-0 rounded overflow-hidden bg-muted w-16 h-10">
                            {r.image_url ? (
                              <img
                                src={resolveImageUrl(r.image_url)}
                                alt={r.title}
                                className="w-full h-full object-cover"
                              />
                            ) : (
                              <div className="w-full h-full flex items-center justify-center">
                                <Gift size={14} className="text-muted-foreground" />
                              </div>
                            )}
                          </div>
                          <div>
                            <p className="font-medium text-sm">{r.title}</p>
                            {r.description && (
                              <p className="text-xs text-muted-foreground line-clamp-1 mt-0.5">
                                {r.description}
                              </p>
                            )}
                          </div>
                        </div>
                      </TableCell>

                      <TableCell>
                        <span className="inline-flex items-center gap-1 text-xs font-semibold px-2 py-1 rounded-full bg-amber-100 text-amber-700">
                          <Star size={11} />
                          {r.points_cost} pts
                        </span>
                      </TableCell>

                      <TableCell>{getStockBadge(r.stock ?? 0)}</TableCell>

                      <TableCell className="text-sm text-muted-foreground">
                        {new Date(r.created_at || r.createdAt || Date.now()).toLocaleDateString("id-ID", {
                          day: "numeric",
                          month: "short",
                          year: "numeric",
                        })}
                      </TableCell>

                      <TableCell className="text-center">
                        <Button
                          variant="ghost"
                          size="sm"
                          onClick={() => navigate(`/dashboard/reward/catalog/${r.id}/edit`)}
                          className="gap-1.5 h-8 px-3"
                        >
                          <Pencil size={13} />
                          Edit
                        </Button>
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
};

export default RewardCatalog;