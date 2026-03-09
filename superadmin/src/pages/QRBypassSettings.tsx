import { useState, useEffect, useMemo } from "react";
import { toast } from "sonner";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Switch } from "@/components/ui/switch";
import { Textarea } from "@/components/ui/textarea";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
} from "@/components/ui/dialog";
import { Loader2, MapPin, Save, Search, QrCode, FileEdit } from "lucide-react";

interface Location {
  id: number;
  name: string;
  city: string;
  address: string;
  qr_bypass_enabled: boolean;
  notes: string | null;
}

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || "http://localhost:3001";

export default function QRBypassSettings() {
  const [locations, setLocations] = useState<Location[]>([]);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState<number | null>(null);

  // Search
  const [searchTerm, setSearchTerm] = useState("");

  // Notes dialog
  const [notesDialogOpen, setNotesDialogOpen] = useState(false);
  const [selectedLocation, setSelectedLocation] = useState<Location | null>(null);
  const [draftNotes, setDraftNotes] = useState("");

  useEffect(() => {
    fetchLocations();
  }, []);

  const fetchLocations = async () => {
    try {
      setLoading(true);
      const token = localStorage.getItem("token");
      const response = await fetch(`${API_BASE_URL}/api/superadmin/location-qr-bypass`, {
        headers: {
          Authorization: `Bearer ${token}`,
          "Content-Type": "application/json",
        },
      });
      if (!response.ok) throw new Error("Failed to fetch locations");
      const data = await response.json();
      if (data.success) setLocations(data.data);
    } catch (error) {
      console.error("Error fetching locations:", error);
      toast.error("Gagal memuat data lokasi");
    } finally {
      setLoading(false);
    }
  };

  const handleToggle = async (locationId: number, enabled: boolean) => {
    // Optimistic UI update
    setLocations((prev) =>
      prev.map((loc) => (loc.id === locationId ? { ...loc, qr_bypass_enabled: enabled } : loc))
    );
    try {
      setSaving(locationId);
      const token = localStorage.getItem("token");
      const location = locations.find((loc) => loc.id === locationId);
      const response = await fetch(
        `${API_BASE_URL}/api/superadmin/location-qr-bypass/${locationId}`,
        {
          method: "PUT",
          headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json" },
          body: JSON.stringify({
            qr_bypass_enabled: enabled,
            notes: location?.notes || "",
          }),
        }
      );
      if (!response.ok) throw new Error("Failed to update setting");
      const data = await response.json();
      if (data.success) {
        toast.success(
          enabled
            ? "QR Bypass diaktifkan — mitra bisa selesaikan tebengan tanpa scan QR"
            : "QR Bypass dinonaktifkan — mitra harus scan QR di PosMitra"
        );
      }
    } catch (error) {
      // Revert on failure
      setLocations((prev) =>
        prev.map((loc) => (loc.id === locationId ? { ...loc, qr_bypass_enabled: !enabled } : loc))
      );
      console.error("Error updating setting:", error);
      toast.error("Gagal mengupdate pengaturan");
    } finally {
      setSaving(null);
    }
  };

  const openNotesDialog = (location: Location) => {
    setSelectedLocation(location);
    setDraftNotes(location.notes ?? "");
    setNotesDialogOpen(true);
  };

  const handleSaveNotes = async () => {
    if (!selectedLocation) return;
    const locationId = selectedLocation.id;
    try {
      setSaving(locationId);
      const token = localStorage.getItem("token");
      const response = await fetch(
        `${API_BASE_URL}/api/superadmin/location-qr-bypass/${locationId}`,
        {
          method: "PUT",
          headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json" },
          body: JSON.stringify({
            qr_bypass_enabled: selectedLocation.qr_bypass_enabled,
            notes: draftNotes,
          }),
        }
      );
      if (!response.ok) throw new Error("Failed to save notes");
      const data = await response.json();
      if (data.success) {
        setLocations((prev) =>
          prev.map((loc) => (loc.id === locationId ? { ...loc, notes: draftNotes } : loc))
        );
        toast.success("Catatan berhasil disimpan");
        setNotesDialogOpen(false);
        setSelectedLocation(null);
      }
    } catch (error) {
      console.error("Error saving notes:", error);
      toast.error("Gagal menyimpan catatan");
    } finally {
      setSaving(null);
    }
  };

  const filteredLocations = useMemo(() => {
    if (!searchTerm) return locations;
    const q = searchTerm.toLowerCase();
    return locations.filter(
      (loc) =>
        loc.name.toLowerCase().includes(q) ||
        loc.city.toLowerCase().includes(q) ||
        loc.address.toLowerCase().includes(q)
    );
  }, [locations, searchTerm]);

  const bypassActiveCount = locations.filter((l) => l.qr_bypass_enabled).length;

  if (loading) {
    return (
      <div className="flex items-center justify-center py-16">
        <Loader2 className="w-8 h-8 animate-spin text-primary" />
      </div>
    );
  }

  return (
    <div className="space-y-6">

      {/* ── Notes Dialog ── */}
      <Dialog open={notesDialogOpen} onOpenChange={(open) => { setNotesDialogOpen(open); if (!open) setSelectedLocation(null); }}>
        <DialogContent className="max-w-md">
          <DialogHeader>
            <DialogTitle className="text-lg font-semibold text-[#1e3a5f]">
              Catatan — {selectedLocation?.name}
            </DialogTitle>
          </DialogHeader>
          <div className="space-y-2 py-2">
            <Label className="text-sm font-medium">Alasan / catatan bypass QR</Label>
            <Textarea
              placeholder="Contoh: Tidak ada petugas PosMitra di wilayah ini"
              value={draftNotes}
              onChange={(e) => setDraftNotes(e.target.value)}
              rows={4}
              className="resize-none"
            />
          </div>
          <DialogFooter className="gap-2">
            <Button variant="outline" onClick={() => setNotesDialogOpen(false)} disabled={saving === selectedLocation?.id}>
              Batal
            </Button>
            <Button
              onClick={handleSaveNotes}
              disabled={saving === selectedLocation?.id}
              className="bg-[#1e3a5f] hover:bg-[#152a45] gap-2"
            >
              {saving === selectedLocation?.id ? <Loader2 size={16} className="animate-spin" /> : <Save size={16} />}
              Simpan
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* ── Summary chips ── */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <Card className="shadow-sm border-l-4 border-l-[#1e3a5f]">
          <CardContent className="flex items-center gap-4 py-4">
            <div className="w-10 h-10 rounded-full bg-[#1e3a5f]/10 flex items-center justify-center flex-shrink-0">
              <MapPin size={20} className="text-[#1e3a5f]" />
            </div>
            <div>
              <p className="text-2xl font-bold text-[#1e3a5f]">{locations.length}</p>
              <p className="text-xs text-muted-foreground">Total Terminal</p>
            </div>
          </CardContent>
        </Card>
        <Card className="shadow-sm border-l-4 border-l-green-500">
          <CardContent className="flex items-center gap-4 py-4">
            <div className="w-10 h-10 rounded-full bg-green-50 flex items-center justify-center flex-shrink-0">
              <QrCode size={20} className="text-green-600" />
            </div>
            <div>
              <p className="text-2xl font-bold text-green-600">{bypassActiveCount}</p>
              <p className="text-xs text-muted-foreground">Bypass Aktif</p>
            </div>
          </CardContent>
        </Card>
        <Card className="shadow-sm border-l-4 border-l-orange-400">
          <CardContent className="flex items-center gap-4 py-4">
            <div className="w-10 h-10 rounded-full bg-orange-50 flex items-center justify-center flex-shrink-0">
              <QrCode size={20} className="text-orange-500" />
            </div>
            <div>
              <p className="text-2xl font-bold text-orange-500">{locations.length - bypassActiveCount}</p>
              <p className="text-xs text-muted-foreground">Bypass Nonaktif</p>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* ── Main Table Card ── */}
      <Card className="shadow-sm">
        <CardHeader className="pb-4">
          <CardTitle className="text-xl font-semibold">Pengaturan QR Bypass</CardTitle>
        </CardHeader>
        <CardContent>
          {/* Info banner */}
          <div className="flex items-start gap-3 bg-blue-50 border border-blue-200 rounded-lg px-4 py-3 mb-6 text-sm text-blue-800">
            <QrCode size={18} className="flex-shrink-0 mt-0.5 text-blue-600" />
            <p>
              Aktifkan <strong>Bypass QR</strong> pada terminal yang tidak memiliki petugas PosMitra.
              Mitra dapat menyelesaikan tebengan langsung <strong>tanpa perlu scan QR</strong>.
            </p>
          </div>

          {/* Toolbar */}
          <div className="flex items-center justify-between mb-6">
            <div className="relative w-72">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-muted-foreground" size={18} />
              <Input
                placeholder="Cari terminal, kota, atau alamat..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="pl-10 h-10 bg-background border-border"
              />
            </div>
            <p className="text-sm text-muted-foreground">
              Menampilkan <span className="font-medium text-foreground">{filteredLocations.length}</span> dari {locations.length} terminal
            </p>
          </div>

          {/* Table */}
          <div className="overflow-x-auto rounded-lg border border-border">
            <table className="w-full text-sm">
              <thead>
                <tr className="bg-[#1e3a5f] text-white">
                  <th className="text-left py-3 px-4 font-medium rounded-tl-lg">NO</th>
                  <th className="text-left py-3 px-4 font-medium">NAMA TERMINAL</th>
                  <th className="text-left py-3 px-4 font-medium">KOTA</th>
                  <th className="text-left py-3 px-4 font-medium">ALAMAT</th>
                  <th className="text-center py-3 px-4 font-medium">STATUS</th>
                  <th className="text-center py-3 px-4 font-medium">BYPASS QR</th>
                  <th className="text-center py-3 px-4 font-medium rounded-tr-lg">CATATAN</th>
                </tr>
              </thead>
              <tbody>
                {filteredLocations.length > 0 ? (
                  filteredLocations.map((location, index) => (
                    <tr key={location.id} className="border-b border-border/50 hover:bg-muted/30 transition-colors">
                      <td className="py-4 px-4 text-muted-foreground">{index + 1}</td>
                      <td className="py-4 px-4">
                        <div className="flex items-center gap-2">
                          <MapPin size={15} className="text-[#1e3a5f] flex-shrink-0" />
                          <span className="font-medium text-primary">{location.name}</span>
                        </div>
                      </td>
                      <td className="py-4 px-4">{location.city}</td>
                      <td className="py-4 px-4 text-muted-foreground max-w-xs truncate" title={location.address}>
                        {location.address}
                      </td>
                      <td className="py-4 px-4 text-center">
                        {location.qr_bypass_enabled ? (
                          <Badge className="bg-green-500 hover:bg-green-600 text-white text-xs">Bypass Aktif</Badge>
                        ) : (
                          <Badge className="bg-gray-400 hover:bg-gray-500 text-white text-xs">Scan QR</Badge>
                        )}
                      </td>
                      <td className="py-4 px-4 text-center">
                        <div className="flex items-center justify-center">
                          {saving === location.id ? (
                            <Loader2 size={18} className="animate-spin text-primary" />
                          ) : (
                            <Switch
                              checked={location.qr_bypass_enabled}
                              onCheckedChange={(checked) => handleToggle(location.id, checked)}
                              disabled={saving !== null}
                            />
                          )}
                        </div>
                      </td>
                      <td className="py-4 px-4 text-center">
                        <Button
                          variant="ghost"
                          size="icon"
                          className="h-8 w-8 hover:bg-[#1e3a5f]/10"
                          onClick={() => openNotesDialog(location)}
                          title={location.notes ? "Edit catatan" : "Tambah catatan"}
                        >
                          <FileEdit size={16} className={location.notes ? "text-[#1e3a5f]" : "text-muted-foreground"} />
                        </Button>
                      </td>
                    </tr>
                  ))
                ) : (
                  <tr>
                    <td colSpan={7} className="py-16 text-center text-muted-foreground">
                      <MapPin size={36} className="mx-auto mb-3 text-gray-300" />
                      <p>{searchTerm ? "Tidak ada terminal yang cocok dengan pencarian" : "Tidak ada data terminal"}</p>
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
