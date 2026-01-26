import { ChevronLeft } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import DashboardLayout from "@/components/DashboardLayout";
import { useNavigate } from "react-router-dom";

const DetailPosMitra = () => {
  const navigate = useNavigate();
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
        <div className="flex items-center justify-between mb-6">
          <div className="flex items-center gap-4">
            <img
              src="https://i.pravatar.cc/100?img=12"
              className="w-14 h-14 rounded-full"
            />
            <div>
              <p className="font-semibold">Muhammad Abdul</p>
              <p className="text-sm text-muted-foreground">Nebeng Motor</p>
            </div>
          </div>

          <div className="text-right">
            <p className="text-xs text-muted-foreground">KODE REFERRAL</p>
            <p className="font-semibold text-primary">sssd23</p>
          </div>
        </div>

        {/* Informasi Pribadi */}
        <section className="mb-6">
          <h4 className="font-semibold mb-4">Informasi Pribadi</h4>
          <div className="grid grid-cols-3 gap-4">
            <Input disabled value="Muhammad Abdul Kadir" />
            <Input disabled value="posmitra@gmail.com" />
            <Input disabled value="Laki - Laki" />
            <Input disabled value="Terminal 1" />
            <Input disabled value="089563245757" />
            <Input disabled value="01-02-1999" />
          </div>
        </section>

        {/* Alamat Terminal */}
        <section className="mb-6">
          <h4 className="font-semibold mb-3">Alamat Terminal</h4>
          <textarea
            disabled
            className="w-full h-28 rounded-md border border-input bg-muted p-3 text-sm"
            value="Jl. Jend. Sudirman No.296, Pereng, Sokarengga, Kec. Purwokerto Tim., Kabupaten Banyumas, Jawa Tengah 53116"
          />
        </section>

        {/* Informasi KTP */}
        <section>
          <h4 className="font-semibold mb-4">Informasi KTP</h4>
          <div className="grid grid-cols-3 gap-6 items-center">
            <div className="space-y-3">
              <Input disabled value="Muhammad Abdul Kadir" />
              <Input disabled value="10009836400719" />
              <Input disabled value="Laki - Laki" />
              <Input disabled value="01-02-1999" />
            </div>

            <div className="col-span-2 flex justify-end">
              <img
                src="https://dummyimage.com/160x220/ddd/000.png&text=KTP"
                className="rounded-lg border"
              />
            </div>
          </div>
        </section>
      </div>
    </DashboardLayout>
  );
};

export default DetailPosMitra;
