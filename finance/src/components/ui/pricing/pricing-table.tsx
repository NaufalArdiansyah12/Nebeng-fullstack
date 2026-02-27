import { useState } from "react";
import { Button } from "@/components/ui/button";
import api from "@/lib/api";
import { toast } from "sonner";
import PricingFormDialog from "./pricing-form-dialog";

const PricingTable = ({ profiles, loading, onUpdated }: any) => {
  const [selected, setSelected] = useState<any | null>(null);
  const [open, setOpen] = useState(false);

  const handleDelete = async (id: number) => {
    if (!confirm("Hapus profil tarif ini?")) return;
    try {
      await api.delete(`/finance/pricing-profiles/${id}`);
      toast.success("Profil tarif berhasil dihapus");
      onUpdated();
    } catch (err: any) {
      console.error(err);
      toast.error(err.response?.data?.message || "Gagal menghapus profil");
    }
  };

  return (
    <div className="bg-white rounded-lg shadow p-6">
      <div className="flex justify-between items-center mb-4">
        <h3 className="text-lg font-semibold">Daftar Profil Tarif</h3>
        <Button onClick={() => { setSelected(null); setOpen(true); }}>
          Tambah Profil Tarif
        </Button>
      </div>

      <div className="overflow-x-auto">
        <table className="w-full">
          <thead className="bg-gray-50">
            <tr>
              <th className="px-4 py-3 text-left text-sm font-medium text-gray-700">Nama</th>
              <th className="px-4 py-3 text-left text-sm font-medium text-gray-700">Deskripsi</th>
              <th className="px-4 py-3 text-left text-sm font-medium text-gray-700">Jenis Transportasi</th>
              <th className="px-4 py-3 text-left text-sm font-medium text-gray-700">Harga Dasar</th>
              <th className="px-4 py-3 text-left text-sm font-medium text-gray-700">Per KM</th>
              <th className="px-4 py-3 text-left text-sm font-medium text-gray-700">Per KG</th>
              <th className="px-4 py-3 text-left text-sm font-medium text-gray-700">Status</th>
              <th className="px-4 py-3 text-left text-sm font-medium text-gray-700">Aksi</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-200">
            {loading ? (
              <tr>
                <td colSpan={8} className="px-4 py-8 text-center text-gray-500">
                  Memuat data...
                </td>
              </tr>
            ) : profiles.length === 0 ? (
              <tr>
                <td colSpan={8} className="px-4 py-8 text-center text-gray-500">
                  Belum ada profil tarif
                </td>
              </tr>
            ) : (
              profiles.map((p: any) => (
                <tr key={p.id} className="hover:bg-gray-50">
                  <td className="px-4 py-3 text-sm">{p.name}</td>
                  <td className="px-4 py-3 text-sm text-gray-600">{p.description || '-'}</td>
                  <td className="px-4 py-3 text-sm">{p.transport_mode?.name || '-'}</td>
                  <td className="px-4 py-3 text-sm">Rp {Number(p.base_price || 0).toLocaleString('id-ID')}</td>
                  <td className="px-4 py-3 text-sm">Rp {Number(p.price_per_km || 0).toLocaleString('id-ID')}</td>
                  <td className="px-4 py-3 text-sm">Rp {Number(p.price_per_kg || 0).toLocaleString('id-ID')}</td>
                  <td className="px-4 py-3 text-sm">
                    <span className={`px-2 py-1 rounded-full text-xs ${p.active ? 'bg-green-100 text-green-800' : 'bg-gray-100 text-gray-800'}`}>
                      {p.active ? 'Aktif' : 'Nonaktif'}
                    </span>
                  </td>
                  <td className="px-4 py-3 text-sm space-x-2">
                    <Button size="sm" variant="outline" onClick={() => { setSelected(p); setOpen(true); }}>
                      Edit
                    </Button>
                    <Button size="sm" variant="destructive" onClick={() => handleDelete(p.id)}>
                      Hapus
                    </Button>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>

      <PricingFormDialog open={open} onOpenChange={setOpen} profile={selected} onSaved={onUpdated} />
    </div>
  );
};

export default PricingTable;
