import { useEffect, useRef } from "react";
import { MapContainer, TileLayer, Marker, useMapEvents } from "react-leaflet";
import L from "leaflet";

// Fix leaflet default icon path (Vite/webpack asset issue)
delete (L.Icon.Default.prototype as any)._getIconUrl;
L.Icon.Default.mergeOptions({
  iconRetinaUrl: "https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon-2x.png",
  iconUrl: "https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png",
  shadowUrl: "https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png",
});

interface MapPickerProps {
  lat: number | null;
  lng: number | null;
  onChange: (lat: number, lng: number) => void;
}

/** Inner component — listens for map clicks and updates marker */
function ClickHandler({ onChange }: { onChange: (lat: number, lng: number) => void }) {
  useMapEvents({
    click(e) {
      onChange(e.latlng.lat, e.latlng.lng);
    },
  });
  return null;
}

const DEFAULT_CENTER: [number, number] = [-2.5489, 118.0149]; // center of Indonesia
const DEFAULT_ZOOM = 5;

export default function MapPicker({ lat, lng, onChange }: MapPickerProps) {
  const markerPos: [number, number] | null =
    lat !== null && lng !== null ? [lat, lng] : null;

  return (
    <div className="w-full h-64 rounded-lg overflow-hidden border border-border">
      <MapContainer
        center={markerPos ?? DEFAULT_CENTER}
        zoom={markerPos ? 14 : DEFAULT_ZOOM}
        style={{ height: "100%", width: "100%" }}
        scrollWheelZoom
      >
        <TileLayer
          attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
          url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
        />
        <ClickHandler onChange={onChange} />
        {markerPos && <Marker position={markerPos} />}
      </MapContainer>
    </div>
  );
}
