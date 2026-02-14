import { ReadOnlyField } from "./readonly-field";
import { PhotoField } from "./photo-field";

interface KtpInfoSectionProps {
  data: {
    nama_lengkap: string;
    nik: string;
    tanggal_lahir: string;
    jenis_kelamin: string | null;
    photo_ktp: string | null;
  };
  formatDate: (date: string) => string;
  capitalizeGender: (gender: string | null) => string;
}

export function KtpInfoSection({ data, formatDate, capitalizeGender }: KtpInfoSectionProps) {
  return (
    <section>
      <h4 className="font-bold text-base text-gray-900 mb-4">Informasi KTP</h4>
      <div className="grid grid-cols-2 gap-x-6 gap-y-4">
        <ReadOnlyField label="Nama Lengkap" value={data.nama_lengkap} />
        <ReadOnlyField label="NIK" value={data.nik} />
        <ReadOnlyField
          label="Jenis Kelamin"
          value={capitalizeGender(data.jenis_kelamin)}
          type="select"
        />
        <ReadOnlyField
          label="Tanggal Lahir"
          value={formatDate(data.tanggal_lahir)}
          type="date"
        />
        <div className="col-span-2">
          <PhotoField
            label="Foto KTP"
            src={data.photo_ktp ? `http://127.0.0.1:8000${data.photo_ktp}` : null}
            alt="Foto KTP"
          />
        </div>
      </div>
    </section>
  );
}
