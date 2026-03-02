import { useState, useRef } from "react";
import { useNavigate } from "react-router-dom";
import { MapContainer, TileLayer, Marker, useMapEvents } from "react-leaflet";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { locationsApi } from "@/services/api";
import { MapPin } from "lucide-react";
import L from "leaflet";
import "leaflet/dist/leaflet.css";

// Fix default marker icon issue with webpack
import icon from "leaflet/dist/images/marker-icon.png";
import iconShadow from "leaflet/dist/images/marker-shadow.png";

const DefaultIcon = L.icon({
  iconUrl: icon,
  shadowUrl: iconShadow,
  iconSize: [25, 41],
  iconAnchor: [12, 41],
});

L.Marker.prototype.options.icon = DefaultIcon;

// Component to handle map clicks
function LocationMarker({ position, setPosition }: { 
  position: [number, number] | null; 
  setPosition: (pos: [number, number]) => void;
}) {
  useMapEvents({
    click(e) {
      const { lat, lng } = e.latlng;
      setPosition([lat, lng]);
    },
  });

  return position === null ? null : <Marker position={position} />;
}

const CreateLocation = () => {
  const navigate = useNavigate();
  const [name, setName] = useState("");
  const [city, setCity] = useState("");
  const [address, setAddress] = useState("");
  const [latitude, setLatitude] = useState("");
  const [longitude, setLongitude] = useState("");
  const [loading, setLoading] = useState(false);
  const [mapPosition, setMapPosition] = useState<[number, number] | null>(null);
  const [mapCenter, setMapCenter] = useState<[number, number]>([-6.2088, 106.8456]); // Jakarta default

  const handleMapPositionChange = (pos: [number, number]) => {
    setMapPosition(pos);
    setLatitude(pos[0].toString());
    setLongitude(pos[1].toString());
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!name || !city || !address) {
      alert("Nama, kota, dan alamat harus diisi");
      return;
    }

    // Validate coordinates if provided
    if (latitude && isNaN(parseFloat(latitude))) {
      alert("Latitude harus berupa angka");
      return;
    }
    if (longitude && isNaN(parseFloat(longitude))) {
      alert("Longitude harus berupa angka");
      return;
    }

    setLoading(true);
    try {
      const payload: any = {
        name,
        city,
        address,
      };

      // Only include coordinates if provided
      if (latitude) payload.latitude = parseFloat(latitude);
      if (longitude) payload.longitude = parseFloat(longitude);

      await locationsApi.create(payload);
      alert("Lokasi terminal berhasil dibuat");
      navigate("/dashboard/pos-mitra-by-location");
    } catch (err: any) {
      console.error("Failed to create location:", err);
      const msg = err?.response?.data?.message || err?.message || "Gagal membuat lokasi";
      alert(msg);
    } finally {
      setLoading(false);
    }
  };

  const handleGetCurrentLocation = () => {
    if ("geolocation" in navigator) {
      navigator.geolocation.getCurrentPosition(
        (position) => {
          const lat = position.coords.latitude;
          const lng = position.coords.longitude;
          setLatitude(lat.toString());
          setLongitude(lng.toString());
          setMapPosition([lat, lng]);
          setMapCenter([lat, lng]);
          alert("Koordinat berhasil diambil dari lokasi Anda");
        },
        (error) => {
          console.error("Error getting location:", error);
          alert("Gagal mendapatkan lokasi. Pastikan izin lokasi diaktifkan.");
        }
      );
    } else {
      alert("Browser Anda tidak mendukung geolocation");
    }
  };

  const handleLatLngInputChange = () => {
    const lat = parseFloat(latitude);
    const lng = parseFloat(longitude);
    if (!isNaN(lat) && !isNaN(lng)) {
      setMapPosition([lat, lng]);
      setMapCenter([lat, lng]);
    }
  };

  return (
    <div className="p-6 max-w-7xl mx-auto">
      {/* Header */}
      <div className="mb-6">
        <div className="flex items-center gap-3 mb-2">
          <Button 
            variant="ghost" 
            size="icon"
            onClick={() => navigate('/dashboard/pos-mitra-by-location')}
            className="h-8 w-8"
          >
            ←
          </Button>
          <div>
            <h1 className="text-2xl font-bold">Buat Terminal Baru</h1>
            <p className="text-sm text-muted-foreground mt-1">
              Tambahkan lokasi terminal baru untuk pos mitra
            </p>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Form Section */}
        <Card className="lg:sticky lg:top-6 h-fit">
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <div className="h-8 w-8 bg-primary/10 rounded-lg flex items-center justify-center">
                <MapPin className="h-4 w-4 text-primary" />
              </div>
              Informasi Terminal
            </CardTitle>
          </CardHeader>
          <CardContent>
            <form onSubmit={handleSubmit} className="space-y-5">
              <div className="space-y-2">
                <Label htmlFor="name" className="text-sm font-medium">
                  Nama Terminal <span className="text-red-500">*</span>
                </Label>
                <Input 
                  id="name"
                  value={name} 
                  onChange={(e) => setName(e.target.value)}
                  placeholder="Contoh: Terminal Blok M"
                  className="h-11"
                />
              </div>

              <div className="space-y-2">
                <Label htmlFor="city" className="text-sm font-medium">
                  Kota <span className="text-red-500">*</span>
                </Label>
                <Input 
                  id="city"
                  value={city} 
                  onChange={(e) => setCity(e.target.value)}
                  placeholder="Contoh: Jakarta"
                  className="h-11"
                />
              </div>

              <div className="space-y-2">
                <Label htmlFor="address" className="text-sm font-medium">
                  Alamat Lengkap <span className="text-red-500">*</span>
                </Label>
                <Textarea 
                  id="address"
                  value={address} 
                  onChange={(e) => setAddress(e.target.value)}
                  placeholder="Contoh: Jl. Blok M No.1, Kebayoran Baru"
                  rows={3}
                  className="resize-none"
                />
              </div>

              <div className="border-t pt-5">
                <div className="flex items-center justify-between mb-4">
                  <div>
                    <Label className="text-sm font-semibold">Koordinat Peta</Label>
                    <p className="text-xs text-muted-foreground mt-1">
                      Klik pada peta atau gunakan lokasi saat ini
                    </p>
                  </div>
                  <Button 
                    type="button" 
                    variant="outline" 
                    size="sm"
                    onClick={handleGetCurrentLocation}
                    className="gap-2"
                  >
                    <MapPin size={14} />
                    GPS Saya
                  </Button>
                </div>

                <div className="grid grid-cols-2 gap-3">
                  <div className="space-y-2">
                    <Label htmlFor="latitude" className="text-xs font-medium text-muted-foreground">
                      Latitude
                    </Label>
                    <Input 
                      id="latitude"
                      value={latitude} 
                      onChange={(e) => setLatitude(e.target.value)}
                      onBlur={handleLatLngInputChange}
                      placeholder="-6.2088"
                      type="text"
                      className="h-10 font-mono text-sm"
                    />
                  </div>

                  <div className="space-y-2">
                    <Label htmlFor="longitude" className="text-xs font-medium text-muted-foreground">
                      Longitude
                    </Label>
                    <Input 
                      id="longitude"
                      value={longitude} 
                      onChange={(e) => setLongitude(e.target.value)}
                      onBlur={handleLatLngInputChange}
                      placeholder="106.8456"
                      type="text"
                      className="h-10 font-mono text-sm"
                    />
                  </div>
                </div>

                {latitude && longitude && (
                  <div className="mt-3 p-3 bg-muted/50 rounded-lg border">
                    <div className="flex items-start justify-between gap-2">
                      <div className="flex-1">
                        <p className="text-xs font-medium text-muted-foreground mb-1">Preview Koordinat</p>
                        <p className="text-xs font-mono">{latitude}, {longitude}</p>
                      </div>
                      <a 
                        href={`https://www.google.com/maps?q=${latitude},${longitude}`}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="text-xs text-primary hover:underline flex items-center gap-1 whitespace-nowrap"
                      >
                        Google Maps →
                      </a>
                    </div>
                  </div>
                )}
              </div>

              <div className="flex gap-3 pt-4 border-t">
                <Button type="submit" disabled={loading} className="flex-1 h-11">
                  {loading ? 'Menyimpan...' : 'Buat Terminal'}
                </Button>
                <Button 
                  type="button" 
                  variant="outline" 
                  onClick={() => navigate('/dashboard/pos-mitra-by-location')}
                  className="h-11"
                >
                  Batal
                </Button>
              </div>
            </form>
          </CardContent>
        </Card>

        {/* Map Section */}
        <Card className="overflow-hidden">
          <CardHeader className="pb-3">
            <CardTitle className="text-base flex items-center gap-2">
              <div className="h-7 w-7 bg-blue-50 rounded-lg flex items-center justify-center">
                🗺️
              </div>
              Pilih Lokasi di Peta
            </CardTitle>
            <p className="text-xs text-muted-foreground">
              Klik pada peta untuk menentukan koordinat terminal secara presisi
            </p>
          </CardHeader>
          <CardContent className="p-0">
            <div className="relative" style={{ height: '600px' }}>
              <MapContainer 
                center={mapCenter} 
                zoom={13} 
                style={{ height: '100%', width: '100%' }}
                key={`${mapCenter[0]}-${mapCenter[1]}`}
              >
                <TileLayer
                  attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
                  url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
                />
                <LocationMarker position={mapPosition} setPosition={handleMapPositionChange} />
              </MapContainer>
              
              {!mapPosition && (
                <div className="absolute inset-0 flex items-center justify-center pointer-events-none z-[1000]">
                  <div className="bg-background/95 backdrop-blur-sm px-4 py-3 rounded-lg border shadow-lg">
                    <p className="text-sm font-medium text-center">
                      👆 Klik pada peta untuk menentukan lokasi
                    </p>
                  </div>
                </div>
              )}
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
};

export default CreateLocation;
