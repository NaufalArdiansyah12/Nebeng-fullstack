import { ReadOnlyField } from "./readonly-field";

interface PersonalInfoSectionProps {
  data: {
    nama_lengkap: string;
    email: string;
    tempat_lahir: string | null;
    tanggal_lahir: string | null;
    jenis_kelamin: string | null;
    no_telepon: string;
  };
  formatDate: (date: string) => string;
  capitalizeGender: (gender: string | null) => string;
}

export function PersonalInfoSection({ data, formatDate, capitalizeGender }: PersonalInfoSectionProps) {
  return (
    <section>
      <h4 className="font-bold text-base text-gray-900 mb-4">Informasi Pribadi</h4>
      <div className="grid grid-cols-2 gap-x-6 gap-y-4">
        <ReadOnlyField label="Nama Lengkap" value={data.nama_lengkap} />
        <ReadOnlyField label="Email" value={data.email} />
        <ReadOnlyField label="Tempat Lahir" value={data.tempat_lahir || "-"} />
        <ReadOnlyField
          label="Tanggal Lahir"
          value={formatDate(data.tanggal_lahir || "")}
          type="date"
        />
        <ReadOnlyField
          label="Jenis Kelamin"
          value={capitalizeGender(data.jenis_kelamin)}
          type="select"
        />
        <ReadOnlyField label="No. Tlp" value={data.no_telepon} />
      </div>
    </section>
  );
}
