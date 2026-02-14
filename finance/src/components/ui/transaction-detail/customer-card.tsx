import { Avatar, AvatarFallback, AvatarImage } from "../avatar";
import { Badge } from "../badge";

interface CustomerCardProps {
  customer: {
    name: string;
    phone: string;
    photo: string;
  };
  serviceType: string;
  jenis: string;
  passengers?: {
    count: number;
    weight: string;
  };
  goods?: {
    description: string;
    weight: string;
    photo: string | null;
  };
  penumpangList?: Array<{
    nama: string;
    nik: string;
    no_telepon: string;
    jenis_kelamin: string;
  }>;
}

export function CustomerCard({ 
  customer, 
  serviceType, 
  jenis,
  passengers, 
  goods,
  penumpangList 
}: CustomerCardProps) {
  const getWeightLabel = (weight: string) => {
    const weightLower = weight.toLowerCase();
    if (weightLower === 'kecil') {
      return 'Kecil (maksimal 5kg)';
    } else if (weightLower === 'sedang') {
      return 'Sedang (maksimal 10kg)';
    } else if (weightLower === 'besar') {
      return 'Besar (maksimal 20kg)';
    }
    return weight;
  };

  return (
    <div className="bg-background rounded-xl p-6 border shadow-sm">
      <div className="flex items-start gap-4 mb-6">
        <Avatar className="h-16 w-16">
          <AvatarImage src={customer.photo ? `http://127.0.0.1:8000${customer.photo}` : undefined} />
          <AvatarFallback>{customer.name.charAt(0)}</AvatarFallback>
        </Avatar>
        <div className="flex-1">
          <h3 className="font-semibold text-lg">{customer.name}</h3>
          <p className="text-sm text-muted-foreground mb-2">Costumer</p>
        </div>
      </div>

      <div className="space-y-4">
        <h4 className="font-semibold">Informasi Costumer</h4>

        <div className="grid grid-cols-2 gap-4">
          <div>
            <label className="text-sm text-muted-foreground">Nama Lengkap</label>
            <div className="bg-muted/30 rounded-lg px-3 py-2.5 mt-1 border">
              <p className="text-sm">{customer.name}</p>
            </div>
          </div>
          <div>
            <label className="text-sm text-muted-foreground">No. Tlp</label>
            <div className="bg-muted/30 rounded-lg px-3 py-2.5 mt-1 border">
              <p className="text-sm">{customer.phone}</p>
            </div>
          </div>
        </div>

        {/* Separator */}
        {(serviceType === 'Hanya Tebengan' ||
          serviceType === 'Hanya Titip Barang' ||
          serviceType === 'Tebengan dan Titip Barang') && (
            <div className="border-t-2 pt-4 mt-4"></div>
          )}

        {/* Data Penumpang */}
        {(serviceType === 'Hanya Tebengan' || serviceType === 'Tebengan dan Titip Barang') && passengers && (
          <>
            <h5 className="font-semibold text-sm">Informasi Penumpang</h5>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="text-sm text-muted-foreground">Jumlah Penumpang</label>
                <div className="bg-muted/30 rounded-lg px-3 py-2.5 mt-1 border">
                  <p className="text-sm">{passengers.count} Orang</p>
                </div>
              </div>
              <div>
                <label className="text-sm text-muted-foreground">Berat Bawaan</label>
                <div className="bg-muted/30 rounded-lg px-3 py-2.5 mt-1 border">
                  <p className="text-sm">{passengers.weight}</p>
                </div>
              </div>
            </div>

            {/* Data Penumpang Mobil */}
            {jenis === 'Nebeng Mobil' && penumpangList && penumpangList.length > 0 && (
              <div className="space-y-3 mt-4">
                <h6 className="font-semibold text-sm">Data Penumpang ({penumpangList.length} orang)</h6>
                {penumpangList.map((penumpang, index) => (
                  <div key={index} className="bg-muted/30 rounded-lg p-4 border space-y-3">
                    <div className="flex items-center justify-between">
                      <p className="font-medium text-sm">Penumpang {index + 1}</p>
                      <Badge variant="outline" className="text-xs">{penumpang.jenis_kelamin}</Badge>
                    </div>
                    <div className="grid grid-cols-2 gap-3">
                      <div>
                        <label className="text-xs text-muted-foreground">Nama Lengkap</label>
                        <p className="text-sm font-medium">{penumpang.nama}</p>
                      </div>
                      <div>
                        <label className="text-xs text-muted-foreground">No. Telepon</label>
                        <p className="text-sm font-medium">{penumpang.no_telepon}</p>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </>
        )}

        {/* Data Barang */}
        {(serviceType === 'Hanya Titip Barang' || serviceType === 'Tebengan dan Titip Barang') && goods && (
          <>
            <h5 className="font-semibold text-sm">Informasi Barang</h5>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="text-sm text-muted-foreground">Berat Barang</label>
                <div className="bg-muted/30 rounded-lg px-3 py-2.5 mt-1 border">
                  <p className="text-sm">{getWeightLabel(goods.weight)}</p>
                </div>
              </div>
              <div>
                <label className="text-sm text-muted-foreground">Deskripsi Barang</label>
                <div className="bg-muted/30 rounded-lg px-3 py-2.5 mt-1 border">
                  <p className="text-sm">{goods.description}</p>
                </div>
              </div>
            </div>
            {goods.photo && (
              <div>
                <label className="text-sm text-muted-foreground">Foto Barang</label>
                <div className="mt-2">
                  <img
                    src={`http://127.0.0.1:8000${goods.photo}`}
                    alt="Foto Barang"
                    className="rounded-lg border w-full max-h-96 object-contain bg-muted/20"
                  />
                </div>
              </div>
            )}
          </>
        )}
      </div>
    </div>
  );
}
