import { ChevronLeft } from "lucide-react";
import { Button } from "@/components/ui/button";
import DashboardLayout from "@/components/DashboardLayout";
import { useNavigate, useParams } from "react-router-dom";
import { useEffect, useState } from "react";
import api from "@/lib/api";
import { toast } from "sonner";
import { MitraProfileHeader } from "@/components/ui/mitra-detail/profile-header";
import { PersonalInfoSection } from "@/components/ui/mitra-detail/personal-info-section";
import { KtpInfoSection } from "@/components/ui/mitra-detail/ktp-info-section";
import { SimInfoSection } from "@/components/ui/mitra-detail/sim-info-section";

interface MitraDetail {
  id: number;
  name: string;
  email: string;
  phone: string;
  profile_photo: string | null;
  service_type: string;
  pribadi: {
    nama_lengkap: string;
    email: string;
    tempat_lahir: string | null;
    tanggal_lahir: string | null;
    jenis_kelamin: string | null;
    no_telepon: string;
  };
  ktp: {
    nama_lengkap: string;
    nik: string;
    tanggal_lahir: string;
    jenis_kelamin: string | null;
    photo_ktp: string | null;
  } | null;
  sim: {
    nama_lengkap: string;
    nomor_sim: string;
    sim_type: string;
    sim_expiry_date: string;
    sim_photo: string | null;
  } | null;
}

const DetailMitra = () => {
  const navigate = useNavigate();
  const { id } = useParams();
  const [mitra, setMitra] = useState<MitraDetail | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (id) fetchMitraDetail();
  }, [id]);

  const fetchMitraDetail = async () => {
    try {
      const response = await api.get(`/finance/users/mitra/${id}`);
      setMitra(response.data);
    } catch (error) {
      console.error("Error fetching mitra:", error);
      toast.error("Gagal memuat detail mitra");
    } finally {
      setLoading(false);
    }
  };

  const copyToClipboard = (text: string) => {
    navigator.clipboard.writeText(text);
    toast.success("ID berhasil disalin");
  };

  const formatDate = (date: string) => {
    if (!date) return "-";
    const d = new Date(date);
    return d.toLocaleDateString("id-ID", {
      day: "2-digit",
      month: "2-digit",
      year: "numeric",
    });
  };

  const capitalizeGender = (gender: string | null) => {
    if (!gender) return "-";
    const g = gender.toLowerCase();
    if (g === "laki-laki" || g === "laki") return "Laki - Laki";
    if (g === "perempuan") return "Perempuan";
    return gender.charAt(0).toUpperCase() + gender.slice(1);
  };

  if (loading) {
    return (
      <DashboardLayout title="Detail Data Mitra">
        <div className="flex items-center justify-center h-64">
          <p>Loading...</p>
        </div>
      </DashboardLayout>
    );
  }

  if (!mitra) {
    return (
      <DashboardLayout title="Detail Data Mitra">
        <div className="flex items-center justify-center h-64">
          <p>Mitra tidak ditemukan</p>
        </div>
      </DashboardLayout>
    );
  }

  return (
    <DashboardLayout title="Detail Data Mitra">
      {/* Page header */}
      <div className="flex items-center gap-3 mb-6">
        <Button variant="ghost" size="icon" onClick={() => navigate(-1)}>
          <ChevronLeft />
        </Button>
        <h2 className="font-semibold text-lg">Detail Data Mitra</h2>
      </div>

      <div className="bg-white border border-gray-200 rounded-2xl overflow-hidden">
        {/* Profile strip */}
        <MitraProfileHeader
          name={mitra.name}
          photoUrl={mitra.profile_photo ? `http://127.0.0.1:8000${mitra.profile_photo}` : null}
        />

        {/* Content */}
        <div className="px-6 py-6 space-y-8">
          {/* Informasi Pribadi */}
          <PersonalInfoSection
            data={mitra.pribadi}
            formatDate={formatDate}
            capitalizeGender={capitalizeGender}
          />

          {/* Informasi KTP */}
          {mitra.ktp && (
            <KtpInfoSection
              data={mitra.ktp}
              formatDate={formatDate}
              capitalizeGender={capitalizeGender}
            />
          )}

          {/* Informasi SIM */}
          {mitra.sim && (
            <SimInfoSection
              data={mitra.sim}
              formatDate={formatDate}
            />
          )}
        </div>
      </div>
    </DashboardLayout>
  );
};

export default DetailMitra;