import { ChevronLeft } from "lucide-react";
import { Button } from "@/components/ui/button";
import DashboardLayout from "@/components/DashboardLayout";
import { useNavigate } from "react-router-dom";

const DetailMitra = () => {
  const navigate = useNavigate();
  return (
    <DashboardLayout title="Detail Data Mitra">
      {/* Header */}
      <div className="flex items-center gap-3 mb-6">
<Button variant="ghost" size="icon" onClick={() => navigate(-1)}>
          <ChevronLeft />
        </Button>
        <h2 className="font-semibold text-lg">Detail Data Mitra</h2>
      </div>

      <div className="bg-background border border-border rounded-xl p-6">
        {/* Profile */}
        <div className="flex items-center gap-4 mb-6">
          <img
            src="https://i.pravatar.cc/100?img=12"
            className="w-16 h-16 rounded-full"
          />
          <div>
            <p className="font-semibold">Muhammad Abdul</p>
            <p className="text-sm text-muted-foreground">Nebeng Motor</p>
          </div>

          <div className="ml-auto text-right">
            <p className="text-xs text-muted-foreground">ID MITRA</p>
            <p className="font-semibold">001235</p>
          </div>
        </div>

        {/* Informasi Pribadi */}
        <section className="mb-6">
          <h4 className="font-semibold mb-3">Informasi Pribadi</h4>
          <div className="grid grid-cols-2 gap-4 text-sm">
            <div>
              <p className="text-muted-foreground">Nama Lengkap</p>
              <p className="font-medium">Muhammad Abdul Kadir</p>
            </div>
            <div>
              <p className="text-muted-foreground">Email</p>
              <p className="font-medium">MITRA@GMAIL.COM</p>
            </div>
            <div>
              <p className="text-muted-foreground">Tempat Lahir</p>
              <p className="font-medium">London</p>
            </div>
            <div>
              <p className="text-muted-foreground">Tanggal Lahir</p>
              <p className="font-medium">01-02-1999</p>
            </div>
            <div>
              <p className="text-muted-foreground">Jenis Kelamin</p>
              <p className="font-medium">Laki - Laki</p>
            </div>
            <div>
              <p className="text-muted-foreground">No. Tlp</p>
              <p className="font-medium">089563245757</p>
            </div>
          </div>
        </section>

        {/* Informasi KTP */}
        <section className="mb-6">
          <h4 className="font-semibold mb-3">Informasi KTP</h4>
          <div className="grid grid-cols-3 gap-4 text-sm items-center">
            <div>
              <p className="text-muted-foreground">Nama Lengkap</p>
              <p className="font-medium">Muhammad Abdul Kadir</p>
            </div>
            <div>
              <p className="text-muted-foreground">NIK</p>
              <p className="font-medium">10009836400719</p>
            </div>
            <div className="row-span-2">
              <img
                src="https://dummyimage.com/120x160/ddd/000.png&text=KTP"
                className="rounded-lg border"
              />
            </div>
            <div>
              <p className="text-muted-foreground">Jenis Kelamin</p>
              <p className="font-medium">Laki - Laki</p>
            </div>
            <div>
              <p className="text-muted-foreground">Tanggal Lahir</p>
              <p className="font-medium">01-02-1999</p>
            </div>
          </div>
        </section>

        {/* Informasi SIM */}
        <section>
          <h4 className="font-semibold mb-3">Informasi SIM</h4>
          <div className="grid grid-cols-3 gap-4 text-sm items-center">
            <div>
              <p className="text-muted-foreground">Nama Lengkap</p>
              <p className="font-medium">Muhammad Abdul Kadir</p>
            </div>
            <div>
              <p className="text-muted-foreground">Nomor SIM</p>
              <p className="font-medium">10009836400719</p>
            </div>
            <div>
              <img
                src="https://dummyimage.com/120x160/ddd/000.png&text=SIM"
                className="rounded-lg border"
              />
            </div>
          </div>
        </section>
      </div>
    </DashboardLayout>
  );
};

export default DetailMitra;
