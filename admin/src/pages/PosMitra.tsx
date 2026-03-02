import { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { Search, Eye, Users, TrendingUp, CheckCircle, Clock, Plus } from "lucide-react";
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
import { posmitraUsersApi } from "@/services/api";

const StatusBadge = ({ item }: { item: any }) => {
  if (!item.verifikasi_id) {
    return (
      <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-semibold bg-slate-100 text-slate-500 border border-slate-200">
        <span className="w-1.5 h-1.5 rounded-full bg-slate-400" />
        Belum Ada
      </span>
    );
  }
  if (item.verifikasi_status === "approved") {
    return (
      <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-semibold bg-emerald-50 text-emerald-700 border border-emerald-200">
        <span className="w-1.5 h-1.5 rounded-full bg-emerald-500" />
        Terverifikasi
      </span>
    );
  }
  if (item.verifikasi_status === "rejected") {
    return (
      <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-semibold bg-red-50 text-red-700 border border-red-200">
        <span className="w-1.5 h-1.5 rounded-full bg-red-500" />
        Ditolak
      </span>
    );
  }
  return (
    <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-semibold bg-amber-50 text-amber-700 border border-amber-200">
      <span className="w-1.5 h-1.5 rounded-full bg-amber-500 animate-pulse" />
      Menunggu Verifikasi
    </span>
  );
};

const PosMitra = () => {
  const navigate = useNavigate();
  const [posMitraList, setPosMitraList] = useState<any[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState("");
  const [currentPage, setCurrentPage] = useState(1);
  const [itemsPerPage] = useState(10);

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    setIsLoading(true);
    try {
      const posmitraResponse = await posmitraUsersApi.getAll();
      setPosMitraList(posmitraResponse.data || []);
    } catch (error) {
      console.error("Error loading data:", error);
    } finally {
      setIsLoading(false);
    }
  };

  const filteredData = posMitraList.filter(
    (item) =>
      item.name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      item.email?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      item.phone?.toLowerCase().includes(searchTerm.toLowerCase())
  );

  const paginatedData = filteredData.slice(
    (currentPage - 1) * itemsPerPage,
    currentPage * itemsPerPage
  );

  const totalPages = Math.ceil(filteredData.length / itemsPerPage);

  const stats = {
    total: posMitraList.length,
    verified: posMitraList.filter((i) => i.verifikasi_status === "approved").length,
    pending: posMitraList.filter(
      (i) => i.verifikasi_id && i.verifikasi_status !== "approved" && i.verifikasi_status !== "rejected"
    ).length,
  };

  return (
    <div className="flex flex-col gap-6 p-1">
      {/* Header */}
      <div className="flex items-start justify-between">
        <div>
          <h1 className="text-2xl font-bold text-slate-900 tracking-tight">Pos Mitra</h1>
          <p className="text-sm text-slate-500 mt-1">Kelola dan pantau semua akun pos mitra Anda</p>
        </div>
        <Button
          onClick={() => navigate("/dashboard/pos-mitra/create")}
          className="flex items-center gap-2 bg-slate-900 hover:bg-slate-700 text-white rounded-lg px-4 py-2 text-sm font-medium transition-colors"
        >
          <Plus size={16} />
          Buat Akun Baru
        </Button>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-3 gap-4">
        <div className="bg-white rounded-xl border border-slate-200 p-4 flex items-center gap-4 shadow-sm">
          <div className="w-10 h-10 rounded-lg bg-blue-50 flex items-center justify-center">
            <Users size={20} className="text-blue-600" />
          </div>
          <div>
            <p className="text-xs text-slate-500 font-medium uppercase tracking-wide">Total Mitra</p>
            <p className="text-2xl font-bold text-slate-900">{stats.total}</p>
          </div>
        </div>

        <div className="bg-white rounded-xl border border-slate-200 p-4 flex items-center gap-4 shadow-sm">
          <div className="w-10 h-10 rounded-lg bg-emerald-50 flex items-center justify-center">
            <CheckCircle size={20} className="text-emerald-600" />
          </div>
          <div>
            <p className="text-xs text-slate-500 font-medium uppercase tracking-wide">Terverifikasi</p>
            <p className="text-2xl font-bold text-slate-900">{stats.verified}</p>
          </div>
        </div>

        <div className="bg-white rounded-xl border border-slate-200 p-4 flex items-center gap-4 shadow-sm">
          <div className="w-10 h-10 rounded-lg bg-amber-50 flex items-center justify-center">
            <Clock size={20} className="text-amber-600" />
          </div>
          <div>
            <p className="text-xs text-slate-500 font-medium uppercase tracking-wide">Menunggu</p>
            <p className="text-2xl font-bold text-slate-900">{stats.pending}</p>
          </div>
        </div>
      </div>

      {/* Table Card */}
      <div className="bg-white rounded-xl border border-slate-200 shadow-sm overflow-hidden">
        <div className="p-5 border-b border-slate-100 flex items-center justify-between gap-4">
          <h2 className="font-semibold text-slate-800">Daftar Akun Pos Mitra</h2>
          <div className="relative w-72">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" size={16} />
            <Input
              placeholder="Cari nama, email, telepon..."
              value={searchTerm}
              onChange={(e) => {
                setSearchTerm(e.target.value);
                setCurrentPage(1);
              }}
              className="pl-9 pr-4 py-2 text-sm border-slate-200 bg-slate-50 rounded-lg focus:bg-white transition-colors"
            />
          </div>
        </div>

        {isLoading ? (
          <div className="flex flex-col items-center justify-center py-20 gap-3">
            <div className="w-8 h-8 border-2 border-slate-200 border-t-slate-700 rounded-full animate-spin" />
            <p className="text-sm text-slate-400">Memuat data...</p>
          </div>
        ) : posMitraList.length === 0 ? (
          <div className="flex flex-col items-center justify-center py-20 gap-3">
            <div className="w-14 h-14 rounded-full bg-slate-100 flex items-center justify-center">
              <Users size={24} className="text-slate-400" />
            </div>
            <p className="text-sm text-slate-500 font-medium">Belum ada data pos mitra</p>
            <p className="text-xs text-slate-400">Mulai dengan membuat akun pos mitra baru</p>
          </div>
        ) : (
          <>
            <Table>
              <TableHeader>
                <TableRow className="bg-slate-50 hover:bg-slate-50">
                  <TableHead className="w-12 text-xs text-slate-500 font-semibold uppercase tracking-wide pl-5">No</TableHead>
                  <TableHead className="text-xs text-slate-500 font-semibold uppercase tracking-wide">Nama</TableHead>
                  <TableHead className="text-xs text-slate-500 font-semibold uppercase tracking-wide">Email</TableHead>
                  <TableHead className="text-xs text-slate-500 font-semibold uppercase tracking-wide">Telepon</TableHead>
                  <TableHead className="text-xs text-slate-500 font-semibold uppercase tracking-wide">Status</TableHead>
                  <TableHead className="text-xs text-slate-500 font-semibold uppercase tracking-wide text-center pr-5">Aksi</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {paginatedData.map((item, index) => (
                  <TableRow
                    key={item.id}
                    className="hover:bg-slate-50 transition-colors border-slate-100 group"
                  >
                    <TableCell className="text-slate-400 text-sm pl-5">
                      {(currentPage - 1) * itemsPerPage + index + 1}
                    </TableCell>
                    <TableCell>
                      <div className="flex items-center gap-3">
                        <div className="w-8 h-8 rounded-full bg-gradient-to-br from-slate-700 to-slate-900 flex items-center justify-center text-white text-xs font-bold flex-shrink-0">
                          {item.name?.charAt(0)?.toUpperCase() || "?"}
                        </div>
                        <span className="font-medium text-slate-800 text-sm">{item.name}</span>
                      </div>
                    </TableCell>
                    <TableCell className="text-slate-500 text-sm">{item.email}</TableCell>
                    <TableCell className="text-slate-500 text-sm">{item.phone || <span className="text-slate-300">—</span>}</TableCell>
                    <TableCell>
                      <StatusBadge item={item} />
                    </TableCell>
                    <TableCell className="pr-5">
                      <div className="flex items-center justify-center">
                        <button
                          onClick={() => navigate(`/dashboard/pos-mitra/${item.id}`)}
                          className="opacity-0 group-hover:opacity-100 inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-medium text-slate-600 bg-slate-100 hover:bg-slate-200 transition-all"
                        >
                          <Eye size={14} />
                          Detail
                        </button>
                      </div>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>

            {/* Pagination */}
            <div className="flex items-center justify-between px-5 py-4 border-t border-slate-100 bg-slate-50">
              <p className="text-xs text-slate-500">
                Menampilkan{" "}
                <span className="font-semibold text-slate-700">
                  {Math.min((currentPage - 1) * itemsPerPage + 1, filteredData.length)}–{Math.min(currentPage * itemsPerPage, filteredData.length)}
                </span>{" "}
                dari <span className="font-semibold text-slate-700">{filteredData.length}</span> entri
              </p>
              <div className="flex items-center gap-1">
                <button
                  onClick={() => setCurrentPage((prev) => Math.max(1, prev - 1))}
                  disabled={currentPage === 1}
                  className="px-3 py-1.5 rounded-lg text-xs font-medium text-slate-600 border border-slate-200 bg-white hover:bg-slate-50 disabled:opacity-40 disabled:cursor-not-allowed transition-colors"
                >
                  ‹ Sebelumnya
                </button>

                {Array.from({ length: totalPages }, (_, i) => i + 1)
                  .filter((page) => page === 1 || page === totalPages || Math.abs(page - currentPage) <= 1)
                  .reduce<(number | "...")[]>((acc, page, idx, arr) => {
                    if (idx > 0 && typeof arr[idx - 1] === "number" && (page as number) - (arr[idx - 1] as number) > 1) acc.push("...");
                    acc.push(page);
                    return acc;
                  }, [])
                  .map((page, idx) =>
                    page === "..." ? (
                      <span key={`ellipsis-${idx}`} className="px-2 text-slate-400 text-xs">…</span>
                    ) : (
                      <button
                        key={page}
                        onClick={() => setCurrentPage(page as number)}
                        className={`w-8 h-8 rounded-lg text-xs font-medium transition-colors ${
                          currentPage === page
                            ? "bg-slate-900 text-white"
                            : "text-slate-600 border border-slate-200 bg-white hover:bg-slate-50"
                        }`}
                      >
                        {page}
                      </button>
                    )
                  )}

                <button
                  onClick={() => setCurrentPage((prev) => Math.min(totalPages, prev + 1))}
                  disabled={currentPage === totalPages || totalPages === 0}
                  className="px-3 py-1.5 rounded-lg text-xs font-medium text-slate-600 border border-slate-200 bg-white hover:bg-slate-50 disabled:opacity-40 disabled:cursor-not-allowed transition-colors"
                >
                  Selanjutnya ›
                </button>
              </div>
            </div>
          </>
        )}
      </div>
    </div>
  );
};

export default PosMitra;