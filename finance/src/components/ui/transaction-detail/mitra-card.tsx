import { Avatar, AvatarFallback, AvatarImage } from "../avatar";

interface MitraCardProps {
  mitra: {
    id: string;
    name: string;
    phone: string;
    photo: string;
    vehicle_type: string;
    vehicle_brand: string;
    vehicle_plate: string;
  };
}

export function MitraCard({ mitra }: MitraCardProps) {
  return (
    <div className="bg-background rounded-xl p-6 border shadow-sm">
      <div className="flex items-start gap-4 mb-6">
        <Avatar className="h-16 w-16">
          <AvatarImage src={mitra.photo ? `http://127.0.0.1:8000${mitra.photo}` : undefined} />
          <AvatarFallback>{mitra.name.charAt(0)}</AvatarFallback>
        </Avatar>
        <div className="flex-1">
          <h3 className="font-semibold text-lg">{mitra.name}</h3>
          <p className="text-sm text-muted-foreground mb-2">Mitra</p>
        </div>
      </div>

      <div className="space-y-4">
        <h4 className="font-semibold">Informasi Mitra</h4>

        <div className="grid grid-cols-2 gap-4">
          <div>
            <label className="text-sm text-muted-foreground">Nama Lengkap</label>
            <div className="bg-muted/30 rounded-lg px-3 py-2.5 mt-1 border">
              <p className="text-sm">{mitra.name}</p>
            </div>
          </div>
          <div>
            <label className="text-sm text-muted-foreground">No. Tlp</label>
            <div className="bg-muted/30 rounded-lg px-3 py-2.5 mt-1 border">
              <p className="text-sm">{mitra.phone}</p>
            </div>
          </div>
        </div>

        <div className="grid grid-cols-2 gap-4">
          <div>
            <label className="text-sm text-muted-foreground">Kendaraan</label>
            <div className="bg-muted/30 rounded-lg px-3 py-2.5 mt-1 border">
              <p className="text-sm">{mitra.vehicle_type}</p>
            </div>
          </div>
          <div>
            <label className="text-sm text-muted-foreground">Merk Kendaraan</label>
            <div className="bg-muted/30 rounded-lg px-3 py-2.5 mt-1 border">
              <p className="text-sm">{mitra.vehicle_brand}</p>
            </div>
          </div>
        </div>

        <div className="grid grid-cols-2 gap-4">
          <div>
            <label className="text-sm text-muted-foreground">Plat Nomor Kendaraan</label>
            <div className="bg-muted/30 rounded-lg px-3 py-2.5 mt-1 border">
              <p className="text-sm">{mitra.vehicle_plate}</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
