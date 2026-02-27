import { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { MapPin, Users, ChevronDown, ChevronUp, Eye } from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { locationsApi, posmitraUsersApi } from "@/services/api";

interface Location {
  id: number;
  name: string;
  city: string;
  address: string;
  latitude: string;
  longitude: string;
}

interface PosMitra {
  id: number;
  name: string;
  email: string;
  phone: string;
  verifikasi_nama: string;
  verifikasi_status: string;
  location_id: number;
}

const PosMitraByLocation = () => {
  const navigate = useNavigate();
  const [locations, setLocations] = useState<Location[]>([]);
  const [expandedLocation, setExpandedLocation] = useState<number | null>(null);
  const [posMitraByLocation, setPosMitraByLocation] = useState<{
    [key: number]: PosMitra[];
  }>({});
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    setIsLoading(true);
    try {
      // Fetch all locations
      const locationsResponse = await locationsApi.getAll();
      setLocations(locationsResponse.data);

      // Fetch all posmitra users dengan verifikasi data
      const posmitraUsersResponse = await posmitraUsersApi.getAll();
      const posmitraUsersData = posmitraUsersResponse.data;

      // Group posmitra by location_id
      const grouped: { [key: number]: PosMitra[] } = {};
      posmitraUsersData.forEach((pos: any) => {
        const locationId = pos.location_id;
        
        if (!grouped[locationId]) {
          grouped[locationId] = [];
        }

        grouped[locationId].push({
          id: pos.id,
          name: pos.name || "-",
          email: pos.email || "-",
          phone: pos.phone || "-",
          verifikasi_nama: pos.verifikasi_nama || "-",
          verifikasi_status: pos.verifikasi_status || "pending",
          location_id: locationId,
        });
      });

      setPosMitraByLocation(grouped);
    } catch (error) {
      console.error("Error loading data:", error);
    } finally {
      setIsLoading(false);
    }
  };

  const toggleLocation = (locationId: number) => {
    setExpandedLocation(expandedLocation === locationId ? null : locationId);
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case "approved":
        return "bg-green-100 text-green-800";
      case "pending":
        return "bg-yellow-100 text-yellow-800";
      case "rejected":
        return "bg-red-100 text-red-800";
      default:
        return "bg-gray-100 text-gray-800";
    }
  };

  const handleViewDetail = (posId: number) => {
    navigate(`/dashboard/pos-mitra/${posId}`);
  };

  if (isLoading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="text-lg text-gray-600">Loading...</div>
      </div>
    );
  }

  return (
    <div className="flex flex-col gap-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Pos Mitra by Terminal</h1>
          <p className="text-gray-500 mt-2">
            Kelola posmitra berdasarkan lokasi terminal
          </p>
        </div>
      </div>

      {/* Locations List */}
      <div className="space-y-4">
        {locations.map((location) => {
          const posmitraList = posMitraByLocation[location.id] || [];
          const isExpanded = expandedLocation === location.id;

          return (
            <Card key={location.id} className="overflow-hidden">
              <div
                onClick={() => toggleLocation(location.id)}
                className="cursor-pointer hover:bg-gray-50"
              >
                <CardHeader className="pb-3">
                  <div className="flex items-start justify-between">
                    <div className="flex items-start gap-4 flex-1">
                      <MapPin className="w-6 h-6 text-blue-600 mt-1 flex-shrink-0" />
                      <div className="flex-1">
                        <CardTitle className="text-lg mb-2">
                          {location.name}
                        </CardTitle>
                        <div className="grid grid-cols-1 md:grid-cols-2 gap-2 text-sm text-gray-600">
                          <div>
                            <span className="font-medium">Kota:</span> {location.city}
                          </div>
                          <div>
                            <span className="font-medium">Alamat:</span>{" "}
                            {location.address}
                          </div>
                          <div>
                            <span className="font-medium">Koordinat:</span>{" "}
                            {location.latitude}, {location.longitude}
                          </div>
                        </div>
                      </div>
                    </div>

                    <div className="flex items-center gap-4 flex-shrink-0">
                      <div className="flex items-center gap-2 bg-blue-50 px-3 py-2 rounded-lg">
                        <Users size={18} className="text-blue-600" />
                        <span className="font-bold text-blue-600">
                          {posmitraList.length}
                        </span>
                      </div>
                      <button className="text-gray-400 hover:text-gray-600 p-2">
                        {isExpanded ? (
                          <ChevronUp size={24} />
                        ) : (
                          <ChevronDown size={24} />
                        )}
                      </button>
                    </div>
                  </div>
                </CardHeader>
              </div>

              {/* Expanded Content */}
              {isExpanded && (
                <CardContent className="pt-0 border-t">
                  {posmitraList.length > 0 ? (
                    <div className="space-y-3 mt-4">
                      {posmitraList.map((pos, index) => (
                        <div
                          key={pos.id}
                          className="flex items-center justify-between p-4 bg-gray-50 rounded-lg hover:bg-gray-100 transition"
                        >
                          <div className="flex-1">
                            <div className="flex items-center gap-3">
                              <span className="text-sm font-medium text-gray-500 w-6">
                                {index + 1}.
                              </span>
                              <div className="flex-1">
                                <div className="font-medium text-gray-900">
                                  {pos.name}
                                </div>
                                <div className="text-sm text-gray-600">
                                  {pos.email}
                                </div>
                                <div className="text-sm text-gray-500">
                                  {pos.phone}
                                </div>
                              </div>
                            </div>
                          </div>

                          <div className="flex items-center gap-3">
                            <span
                              className={`px-3 py-1 rounded-full text-xs font-medium ${getStatusColor(
                                pos.verifikasi_status
                              )}`}
                            >
                              {pos.verifikasi_status}
                            </span>
                            <Button
                              variant="outline"
                              size="sm"
                              onClick={() => handleViewDetail(pos.id)}
                              className="gap-2"
                            >
                              <Eye size={16} />
                              Detail
                            </Button>
                          </div>
                        </div>
                      ))}
                    </div>
                  ) : (
                    <div className="py-8 text-center text-gray-500">
                      <p>Tidak ada posmitra di lokasi ini</p>
                    </div>
                  )}
                </CardContent>
              )}
            </Card>
          );
        })}
      </div>

      {/* Empty State */}
      {locations.length === 0 && (
        <Card>
          <CardContent className="py-12 text-center text-gray-500">
            <MapPin size={48} className="mx-auto mb-4 text-gray-400" />
            <p>Tidak ada lokasi terminal tersedia</p>
          </CardContent>
        </Card>
      )}
    </div>
  );
};

export default PosMitraByLocation;
