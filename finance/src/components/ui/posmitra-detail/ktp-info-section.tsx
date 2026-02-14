import { Input } from "@/components/ui/input";

interface KtpData {
  nama_lengkap: string;
  nik: string;
  tanggal_lahir: string;
  jenis_kelamin: string | null;
  photo_ktp: string | null;
}

interface KtpInfoSectionProps {
  data: KtpData | null;
}

export const KtpInfoSection = ({ data }: KtpInfoSectionProps) => {
  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('id-ID', {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric'
    });
  };

  return (
    <section>
      <h4 className="font-semibold mb-4">Informasi KTP</h4>
      {data ? (
        <div className="grid grid-cols-3 gap-6 items-start">
          <div className="space-y-3">
            <div>
              <label className="text-xs text-muted-foreground mb-1.5 block">Nama Lengkap</label>
              <Input disabled value={data.nama_lengkap} className="bg-muted" />
            </div>
            <div>
              <label className="text-xs text-muted-foreground mb-1.5 block">NIK</label>
              <Input disabled value={data.nik} className="bg-muted" />
            </div>
            <div>
              <label className="text-xs text-muted-foreground mb-1.5 block">Jenis Kelamin</label>
              <Input disabled value={data.jenis_kelamin || "-"} className="bg-muted" />
            </div>
            <div>
              <label className="text-xs text-muted-foreground mb-1.5 block">Tanggal Lahir</label>
              <Input disabled value={formatDate(data.tanggal_lahir)} className="bg-muted" />
            </div>
          </div>

          <div className="col-span-2 flex justify-end">
            {data.photo_ktp ? (
              <div className="relative group">
                <img
                  src={`${import.meta.env.VITE_API_URL}${data.photo_ktp}`}
                  className="rounded-lg border max-w-sm w-full object-cover shadow-sm"
                  alt="KTP"
                />
              </div>
            ) : (
              <div className="rounded-lg border bg-muted flex items-center justify-center h-48 w-full max-w-sm">
                <p className="text-muted-foreground text-sm">Foto KTP tidak tersedia</p>
              </div>
            )}
          </div>
        </div>
      ) : (
        <div className="border border-dashed rounded-lg p-8 text-center">
          <p className="text-muted-foreground">Data KTP belum tersedia</p>
        </div>
      )}
    </section>
  );
};
