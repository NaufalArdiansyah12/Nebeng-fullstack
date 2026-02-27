// price-form-dialog moved to finance/src/deprecated/removed_price_system/
// This stub prevents build failures while the old implementation is archived.

export function PriceFormDialog() {
  return null;
}

interface PriceRate {
  id: number;
  service_type: string;
  ride_type: string;
  bagasi_capacity?: number | null;
  rate_per_kg: number;
  min_charge: number;
  is_active: boolean;
  effective_from: string;
}

interface PriceFormDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  editData?: PriceRate | null;
  onSave: (data: Partial<PriceRate>) => void;
}

export function PriceFormDialog({
  open,
  onOpenChange,
  editData,
  onSave,
}: PriceFormDialogProps) {
  const [formData, setFormData] = useState({
    service_type: "",
    ride_type: "",
    bagasi_capacity: "",
    rate_per_kg: "",
    min_charge: "",
    effective_from: new Date().toISOString().split("T")[0],
    is_active: true,
  });

  useEffect(() => {
    if (editData) {
      setFormData({
        service_type: editData.service_type,
        ride_type: editData.ride_type,
        bagasi_capacity: editData.bagasi_capacity?.toString() || "",
        rate_per_kg: editData.rate_per_kg.toString(),
        min_charge: editData.min_charge.toString(),
        effective_from: editData.effective_from.split("T")[0],
        is_active: editData.is_active,
      });
    } else {
      setFormData({
        service_type: "",
        ride_type: "",
        bagasi_capacity: "",
        rate_per_kg: "",
        min_charge: "",
        effective_from: new Date().toISOString().split("T")[0],
        is_active: true,
      });
    }
  }, [editData, open]);

  const handleSubmit = () => {
    onSave({
      ...(editData && { id: editData.id }),
      service_type: formData.service_type,
      ride_type: formData.ride_type,
      bagasi_capacity: formData.bagasi_capacity ? parseInt(formData.bagasi_capacity) : null,
      rate_per_kg: parseFloat(formData.rate_per_kg),
      min_charge: parseFloat(formData.min_charge),
      effective_from: formData.effective_from,
      is_active: formData.is_active,
    });
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-md">
        <DialogHeader>
          <DialogTitle>
            {editData ? "Edit Tarif per Kg" : "Tambah Tarif per Kg"}
          </DialogTitle>
        </DialogHeader>

        <div className="space-y-4 py-4">
          <div className="space-y-2">
            <Label htmlFor="service_type">Jenis Layanan</Label>
            <Select
              value={formData.service_type}
              onValueChange={(value) =>
                setFormData({ ...formData, service_type: value })
              }
            >
              <SelectTrigger>
                <SelectValue placeholder="Pilih layanan" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="antar_barang">Antar Barang</SelectItem>
                <SelectItem value="antar_penumpang">Antar Penumpang</SelectItem>
              </SelectContent>
            </Select>
          </div>

          <div className="space-y-2">
            <Label htmlFor="ride_type">Jenis Tebengan</Label>
            <Select
              value={formData.ride_type}
              onValueChange={(value) =>
                setFormData({ ...formData, ride_type: value })
              }
            >
              <SelectTrigger>
                <SelectValue placeholder="Pilih jenis tebengan" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="motor">Tebengan Motor</SelectItem>
                <SelectItem value="mobil">Tebengan Mobil</SelectItem>
                <SelectItem value="barang">Tebengan Barang</SelectItem>
                <SelectItem value="titip_barang">Tebengan Titip Barang</SelectItem>
              </SelectContent>
            </Select>
          </div>

          {formData.service_type === "antar_barang" && (
            <div className="space-y-2">
              <Label htmlFor="bagasi_capacity">Kapasitas Bagasi</Label>
              <Select
                value={formData.bagasi_capacity}
                onValueChange={(value) =>
                  setFormData({ ...formData, bagasi_capacity: value })
                }
              >
                <SelectTrigger>
                  <SelectValue placeholder="Pilih kapasitas bagasi" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="5">Kecil - Maksimal 5 kg</SelectItem>
                  <SelectItem value="10">Sedang - Maksimal 10 kg</SelectItem>
                  <SelectItem value="20">Besar - Maksimal 20 kg</SelectItem>
                </SelectContent>
              </Select>
            </div>
          )}

          <div className="space-y-2">
            <Label htmlFor="rate_per_kg">Harga per Kg (Rp)</Label>
            <Input
              id="rate_per_kg"
              type="number"
              placeholder="0"
              value={formData.rate_per_kg}
              onChange={(e) =>
                setFormData({ ...formData, rate_per_kg: e.target.value })
              }
            />
          </div>

          <div className="space-y-2">
            <Label htmlFor="min_charge">Minimum Charge (Rp)</Label>
            <Input
              id="min_charge"
              type="number"
              placeholder="0"
              value={formData.min_charge}
              onChange={(e) =>
                setFormData({ ...formData, min_charge: e.target.value })
              }
            />
          </div>

          <div className="space-y-2">
            <Label htmlFor="effective_from">Berlaku Dari</Label>
            <Input
              id="effective_from"
              type="date"
              value={formData.effective_from}
              onChange={(e) =>
                setFormData({ ...formData, effective_from: e.target.value })
              }
            />
          </div>

          <div className="space-y-2">
            <Label htmlFor="is_active">Status</Label>
            <Select
              value={formData.is_active ? "active" : "inactive"}
              onValueChange={(value) =>
                setFormData({ ...formData, is_active: value === "active" })
              }
            >
              <SelectTrigger>
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="active">Aktif</SelectItem>
                <SelectItem value="inactive">Tidak Aktif</SelectItem>
              </SelectContent>
            </Select>
          </div>
        </div>

        <DialogFooter>
          <Button variant="outline" onClick={() => onOpenChange(false)}>
            Batal
          </Button>
          <Button onClick={handleSubmit}>
            {editData ? "Simpan Perubahan" : "Tambah Tarif"}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
