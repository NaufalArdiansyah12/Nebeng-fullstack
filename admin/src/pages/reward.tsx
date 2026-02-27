import { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { Search, Eye, Trash2, X } from "lucide-react";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { rewardApi } from "@/services/api";

const Reward = () => {
  const navigate = useNavigate();
  const [rewardList, setRewardList] = useState<any[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState("");
  const [currentPage, setCurrentPage] = useState(1);
  const [itemsPerPage] = useState(10);
  const [statusFilter, setStatusFilter] = useState("all");

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    setIsLoading(true);
    try {
      const response = await rewardApi.getAll();
      setRewardList(response.data || []);
    } catch (error) {
      console.error("Error loading data:", error);
    } finally {
      setIsLoading(false);
    }
  };

  const filteredData = rewardList.filter((item) => {
    const matchesSearch = 
      item.user_name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      item.reward_name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      item.user_email?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      String(item.user_id)?.includes(searchTerm);
    
    const matchesStatus = statusFilter === "all" || item.status === statusFilter;
    
    return matchesSearch && matchesStatus;
  });

  const paginatedData = filteredData.slice(
    (currentPage - 1) * itemsPerPage,
    currentPage * itemsPerPage
  );

  const totalPages = Math.ceil(filteredData.length / itemsPerPage);

  const handleViewDetail = (reward: any) => {
    navigate(`/dashboard/reward/${reward.id}`);
  };

  const handleDelete = async (reward: any) => {
    if (window.confirm(`Apakah Anda yakin ingin menghapus redeem "${reward.reward_name}"?`)) {
      try {
        await rewardApi.delete(reward.id);
        alert("Reward berhasil dihapus");
        loadData();
      } catch (error) {
        console.error("Error deleting reward:", error);
        alert("Gagal menghapus reward");
      }
    }
  };

  const handleStatusChange = async (rewardId: string, newStatus: string) => {
    try {
      await rewardApi.updateStatus(rewardId, newStatus);
      alert("Status berhasil diupdate");
      loadData();
    } catch (error) {
      console.error("Error updating status:", error);
      alert("Gagal mengupdate status");
    }
  };

  const getStatusBadge = (status: string) => {
    switch (status) {
      case "completed":
        return "bg-green-100 text-green-800";
      case "approved":
        return "bg-blue-100 text-blue-800";
      case "rejected":
        return "bg-red-100 text-red-800";
      case "pending":
        return "bg-yellow-100 text-yellow-800";
      default:
        return "bg-gray-100 text-gray-800";
    }
  };

  const getStatusLabel = (status: string) => {
    switch (status) {
      case "completed":
        return "Selesai";
      case "approved":
        return "Disetujui";
      case "rejected":
        return "Ditolak";
      case "pending":
        return "Menunggu";
      default:
        return status;
    }
  };

  const formatDate = (dateString: string) => {
    if (!dateString) return "-";
    const date = new Date(dateString);
    return date.toLocaleDateString("id-ID", {
      day: "2-digit",
      month: "2-digit",
      year: "numeric",
      hour: "2-digit",
      minute: "2-digit"
    });
  };

  return (
    <div className="flex flex-col gap-4">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Reward</h1>
          <p className="text-gray-500 mt-2">
            Kelola dan pantau semua penukaran reward pengguna
          </p>
        </div>
      </div>

      {/* Search and Filters */}
      <Card>
        <CardHeader>
          <CardTitle>Daftar Penukaran Reward</CardTitle>
        </CardHeader>
        <CardContent className="flex flex-col gap-4">
          <div className="flex gap-4">
            <div className="relative flex-1">
              <Search className="absolute left-3 top-3 text-gray-400" size={20} />
              <Input
                placeholder="Cari berdasarkan ID user, nama, email, atau nama reward..."
                value={searchTerm}
                onChange={(e) => {
                  setSearchTerm(e.target.value);
                  setCurrentPage(1);
                }}
                className="pl-10"
              />
            </div>
            <Select
              value={statusFilter}
              onValueChange={(value) => {
                setStatusFilter(value);
                setCurrentPage(1);
              }}
            >
              <SelectTrigger className="w-48">
                <SelectValue placeholder="Filter Status" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">Semua Status</SelectItem>
                <SelectItem value="pending">Menunggu</SelectItem>
                <SelectItem value="approved">Disetujui</SelectItem>
                <SelectItem value="rejected">Ditolak</SelectItem>
                <SelectItem value="completed">Selesai</SelectItem>
              </SelectContent>
            </Select>
          </div>

          {isLoading ? (
            <div className="flex items-center justify-center py-8">
              <p className="text-gray-500">Memuat data...</p>
            </div>
          ) : filteredData.length === 0 ? (
            <div className="flex items-center justify-center py-8">
              <p className="text-gray-500">Belum ada data reward</p>
            </div>
          ) : (
            <>
              {/* Table */}
              <div className="border rounded-lg overflow-hidden">
                <Table>
                  <TableHeader>
                    <TableRow className="bg-gray-50">
                      <TableHead className="w-12">NO</TableHead>
                      <TableHead>USER ID</TableHead>
                      <TableHead>REWARD</TableHead>
                      <TableHead>POINTS DIGUNAKAN</TableHead>
                      <TableHead>TOTAL POINTS</TableHead>
                      <TableHead>ALAMAT</TableHead>
                      <TableHead>STATUS</TableHead>
                      <TableHead>TANGGAL</TableHead>
                      <TableHead className="w-32 text-center">AKSI</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {paginatedData.map((item, index) => (
                      <TableRow key={item.id} className="hover:bg-gray-50">
                        <TableCell className="font-medium">
                          {(currentPage - 1) * itemsPerPage + index + 1}
                        </TableCell>
                        <TableCell>
                          <div>
                            <p className="font-medium">ID: {item.user_id}</p>
                            <p className="text-sm text-gray-500">{item.user_name || "-"}</p>
                            <p className="text-xs text-gray-400">{item.user_email || "-"}</p>
                          </div>
                        </TableCell>
                        <TableCell>
                          <div>
                            <p className="font-medium">{item.reward_name || "-"}</p>
                            <p className="text-sm text-gray-500">{item.reward_description || "-"}</p>
                          </div>
                        </TableCell>
                        <TableCell className="font-medium">
                          {item.points_spent || 0} pts
                        </TableCell>
                        <TableCell className="font-medium text-primary">
                          {item.user_total_points || 0} pts
                        </TableCell>
                        <TableCell className="text-sm max-w-xs truncate" title={item.user_address}>
                          {item.user_address || "-"}
                        </TableCell>
                        <TableCell>
                          <span
                            className={`px-3 py-1 rounded-full text-xs font-semibold ${getStatusBadge(item.status)}`}
                          >
                            {getStatusLabel(item.status)}
                          </span>
                        </TableCell>
                        <TableCell className="text-sm">
                          {formatDate(item.created_at)}
                        </TableCell>
                        <TableCell>
                          <div className="flex items-center justify-center gap-2">
                            <Button
                              variant="ghost"
                              size="sm"
                              onClick={() => handleViewDetail(item)}
                              title="Lihat Detail"
                            >
                              <Eye size={18} />
                            </Button>
                            <Button
                              variant="ghost"
                              size="sm"
                              className="text-red-600 hover:text-red-700 hover:bg-red-50"
                              onClick={() => handleDelete(item)}
                              title="Hapus"
                            >
                              <Trash2 size={18} />
                            </Button>
                          </div>
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </div>

              {/* Pagination */}
              <div className="flex items-center justify-between">
                <div className="text-sm text-gray-600">
                  Menampilkan{" "}
                  {Math.min((currentPage - 1) * itemsPerPage + 1, filteredData.length)}{" "}
                  sampai{" "}
                  {Math.min(currentPage * itemsPerPage, filteredData.length)} dari{" "}
                  {filteredData.length} entri
                </div>
                <div className="flex items-center gap-2">
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={() => setCurrentPage((prev) => Math.max(1, prev - 1))}
                    disabled={currentPage === 1}
                  >
                    Sebelumnya
                  </Button>

                  {Array.from({ length: totalPages }, (_, i) => i + 1).map(
                    (page) => (
                      <Button
                        key={page}
                        variant={currentPage === page ? "default" : "outline"}
                        size="sm"
                        onClick={() => setCurrentPage(page)}
                      >
                        {page}
                      </Button>
                    )
                  )}

                  <Button
                    variant="outline"
                    size="sm"
                    onClick={() =>
                      setCurrentPage((prev) => Math.min(totalPages, prev + 1))
                    }
                    disabled={currentPage === totalPages}
                  >
                    Selanjutnya
                  </Button>
                </div>
              </div>
            </>
          )}
        </CardContent>
      </Card>
    </div>
  );
};

export default Reward;
