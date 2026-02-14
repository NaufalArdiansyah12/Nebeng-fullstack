import { ReadOnlyField } from "./readonly-field";
import { PhotoField } from "./photo-field";

interface SimInfoSectionProps {
  data: {
    nama_lengkap: string;
    nomor_sim: string;
    sim_type: string;
    sim_expiry_date: string;
    sim_photo: string | null;
  };
  formatDate: (date: string) => string;
}

export function SimInfoSection({ data, formatDate }: SimInfoSectionProps) {
  return (
    <section>
      <h4 className="font-bold text-base text-gray-900 mb-4">Informasi SIM</h4>
      <div className="grid grid-cols-2 gap-x-6 gap-y-4">
        <ReadOnlyField label="Nama Lengkap" value={data.nama_lengkap} />
        <ReadOnlyField label="Nomor SIM" value={data.nomor_sim} />
        <ReadOnlyField label="Jenis SIM" value={data.sim_type || "-"} />
        <ReadOnlyField
          label="Tanggal Kadaluarsa"
          value={formatDate(data.sim_expiry_date || "")}
          type="date"
        />
        <div className="col-span-2">
          <PhotoField
            label="Foto SIM"
            src={data.sim_photo ? `http://127.0.0.1:8000${data.sim_photo}` : null}
            alt="Foto SIM"
          />
        </div>
      </div>
    </section>
  );
}
