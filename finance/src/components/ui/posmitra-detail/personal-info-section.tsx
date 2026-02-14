import { Input } from "@/components/ui/input";

interface PersonalInfoSectionProps {
  name: string;
  email: string;
  phone: string;
  terminal: string | null;
  gender: string | null;
  birthDate: string | null;
}

export const PersonalInfoSection = ({ 
  name, 
  email, 
  phone, 
  terminal, 
  gender, 
  birthDate 
}: PersonalInfoSectionProps) => {
  const formatDate = (dateString: string | null) => {
    if (!dateString) return "-";
    return new Date(dateString).toLocaleDateString('id-ID', {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric'
    });
  };

  return (
    <section className="mb-6">
      <h4 className="font-semibold mb-4">Informasi Pribadi</h4>
      <div className="grid grid-cols-3 gap-4">
        <div>
          <label className="text-xs text-muted-foreground mb-1.5 block">Nama Lengkap</label>
          <Input disabled value={name} className="bg-muted" />
        </div>
        <div>
          <label className="text-xs text-muted-foreground mb-1.5 block">Email</label>
          <Input disabled value={email} className="bg-muted" />
        </div>
        <div>
          <label className="text-xs text-muted-foreground mb-1.5 block">Jenis Kelamin</label>
          <Input disabled value={gender || "-"} className="bg-muted" />
        </div>
        <div>
          <label className="text-xs text-muted-foreground mb-1.5 block">Terminal</label>
          <Input disabled value={terminal || "-"} className="bg-muted" />
        </div>
        <div>
          <label className="text-xs text-muted-foreground mb-1.5 block">No. Tlp</label>
          <Input disabled value={phone} className="bg-muted" />
        </div>
        <div>
          <label className="text-xs text-muted-foreground mb-1.5 block">Tanggal Lahir</label>
          <Input disabled value={formatDate(birthDate)} className="bg-muted" />
        </div>
      </div>
    </section>
  );
};
