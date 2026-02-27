import { ChevronLeft } from "lucide-react";
import { Button } from "@/components/ui/button";
import DashboardLayout from "@/components/DashboardLayout";
import { useNavigate, useParams } from "react-router-dom";
import { useEffect, useState } from "react";
import api from "@/lib/api";
import { toast } from "sonner";
import { ProfileHeader } from "@/components/ui/posmitra-detail/profile-header";
import { PersonalInfoSection } from "@/components/ui/posmitra-detail/personal-info-section";
import { AddressSection } from "@/components/ui/posmitra-detail/address-section";
import { KtpInfoSection } from "@/components/ui/posmitra-detail/ktp-info-section";

interface PosMitraDetail {
  id: number;
  name: string;
  email: string;
  phone: string;
  profile_photo: string | null;
  balance: number;
  location: {
    id: number | null;
    terminal: string | null;
    address: string | null;
    code: string | null;
  };
  ktp: {
    nama_lengkap: string;
    nik: string;
    tanggal_lahir: string;
    jenis_kelamin: string | null;
    photo_ktp: string | null;
  } | null;
}

const DetailPosMitra = () => {
  const navigate = useNavigate();
  const { id } = useParams<{ id: string }>();
  const [posMitra, setPosMitra] = useState<PosMitraDetail | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (id) {
      fetchPosMitraDetail();
    }
  }, [id]);

  const fetchPosMitraDetail = async () => {
    try {
      setLoading(true);
      const response = await api.get(`/finance/users/pos-mitra/${id}`);
      setPosMitra(response.data);
    } catch (error) {
      console.error("Error fetching pos mitra detail:", error);
      toast.error("Gagal mengambil detail Pos Mitra");
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <DashboardLayout title="Detail Pos Mitra">
        <div className="flex items-center justify-center py-12">
          <p className="text-muted-foreground">Memuat data...</p>
        </div>
      </DashboardLayout>
    );
  }

  if (!posMitra) {
    return (
      <DashboardLayout title="Detail Pos Mitra">
        <div className="flex items-center justify-center py-12">
          <p className="text-muted-foreground">Data tidak ditemukan</p>
        </div>
      </DashboardLayout>
    );
  }

  return (
    <DashboardLayout title="Detail Pos Mitra">
      {/* Header */}
      <div className="flex items-center gap-3 mb-6">
        <Button variant="ghost" size="icon" onClick={() => navigate(-1)}>
          <ChevronLeft />
        </Button>
        <h2 className="font-semibold text-lg">Detail Pos Mitra</h2>
      </div>

      <div className="bg-background border border-border rounded-xl p-6">
        {/* Profile */}
        <ProfileHeader
          name={posMitra.name}
          profilePhoto={posMitra.profile_photo}
          referralCode={posMitra.location.code}
        />

        {/* Informasi Pribadi */}
        <PersonalInfoSection
          name={posMitra.ktp?.nama_lengkap || posMitra.name}
          email={posMitra.email}
          phone={posMitra.phone}
          terminal={posMitra.location.terminal}
          gender={posMitra.ktp?.jenis_kelamin}
          birthDate={posMitra.ktp?.tanggal_lahir}
        />

        {/* Alamat Terminal */}
        <AddressSection address={posMitra.location.address} />

        {/* Informasi KTP */}
        <KtpInfoSection data={posMitra.ktp} />
      </div>
    </DashboardLayout>
  );
};

export default DetailPosMitra;
