import DashboardLayout from "@/components/DashboardLayout";
import { useEffect, useState } from "react";
import api from "@/lib/api";
import { MitraSearch } from "@/components/ui/mitra/mitra-search";
import { MitraTable } from "@/components/ui/mitra/mitra-table";

interface Mitra {
  id: number;
  nama: string | null;
  email: string | null;
  telp: string | null;
}

const Mitra = () => {
  const [mitraData, setMitraData] = useState<Mitra[]>([]);
  const [search, setSearch] = useState("");

  useEffect(() => {
    api
      .get("/users/mitra")
      .then(res => {
        setMitraData(res.data);
      })
      .catch(err => {
        console.error("gagal ambil data mitra:", err);
      });
  }, []);

  const filteredData = mitraData.filter(m =>
    m.nama?.toLowerCase().includes(search.toLowerCase())
  );

  return (
    <DashboardLayout title="Mitra">
      <div className="bg-background border border-border rounded-xl overflow-hidden">
        {/* Header */}
        <div className="p-5 border-b border-border flex items-center justify-between">
          <h3 className="font-semibold">Daftar Mitra</h3>
          <MitraSearch value={search} onChange={setSearch} />
        </div>

        {/* Table */}
        <MitraTable data={filteredData} />
      </div>
    </DashboardLayout>
  );
};

export default Mitra;
