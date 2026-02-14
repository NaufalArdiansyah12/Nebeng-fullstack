import { Input } from "@/components/ui/input";

interface PersonalInfoFormProps {
  formData: {
    nama_lengkap: string;
    email: string;
    alamat: string;
    no_tlp: string;
  };
  isEdit: boolean;
  onChange: (field: string, value: string) => void;
}

export const PersonalInfoForm = ({ formData, isEdit, onChange }: PersonalInfoFormProps) => {
  return (
    <div className="bg-background border border-border rounded-xl p-6">
      <h3 className="font-semibold text-base mb-5">Informasi Pribadi</h3>
      
      <div className="grid grid-cols-2 gap-x-6 gap-y-4">
        <div>
          <label className="text-xs font-medium text-muted-foreground mb-2 block">
            Nama Lengkap
          </label>
          <Input
            value={formData.nama_lengkap}
            onChange={(e) => onChange('nama_lengkap', e.target.value)}
            disabled={!isEdit}
            className="bg-muted border-0"
          />
        </div>

        <div>
          <label className="text-xs font-medium text-muted-foreground mb-2 block">
            Email
          </label>
          <Input
            type="email"
            value={formData.email}
            onChange={(e) => onChange('email', e.target.value)}
            disabled={!isEdit}
            className="bg-muted border-0"
          />
        </div>

        <div>
          <label className="text-xs font-medium text-muted-foreground mb-2 block">
            Alamat
          </label>
          <Input
            value={formData.alamat}
            onChange={(e) => onChange('alamat', e.target.value)}
            disabled={!isEdit}
            className="bg-muted border-0"
            placeholder="Masukkan alamat lengkap"
          />
        </div>

        <div>
          <label className="text-xs font-medium text-muted-foreground mb-2 block">
            No. Tlp
          </label>
          <Input
            value={formData.no_tlp}
            onChange={(e) => onChange('no_tlp', e.target.value)}
            disabled={!isEdit}
            className="bg-muted border-0"
          />
        </div>
      </div>
    </div>
  );
};
