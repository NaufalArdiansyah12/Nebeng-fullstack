import { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { MapPin, Users, ChevronDown, ChevronUp, Eye, Plus, TrendingUp, Building2, CheckCircle, Edit, Trash2 } from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { locationsApi, posmitraUsersApi } from "@/services/api";
import { Badge } from "@/components/ui/badge";
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from "@/components/ui/alert-dialog";

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
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [locationToDelete, setLocationToDelete] = useState<{ id: number; name: string } | null>(null);
  const [isDeleting, setIsDeleting] = useState(false);

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
        return "bg-emerald-50 text-emerald-700 border-emerald-200";
      case "pending":
        return "bg-amber-50 text-amber-700 border-amber-200";
      case "rejected":
        return "bg-red-50 text-red-700 border-red-200";
      default:
        return "bg-slate-50 text-slate-700 border-slate-200";
    }
  };

  const getStatusLabel = (status: string) => {
    switch (status) {
      case "approved":
        return "Terverifikasi";
      case "pending":
        return "Pending";
      case "rejected":
        return "Ditolak";
      default:
        return "Belum Ada";
    }
  };

  const handleViewDetail = (posId: number) => {
    navigate(`/dashboard/pos-mitra/${posId}`);
  };

  const handleEditLocation = (locationId: number, e: React.MouseEvent) => {
    e.stopPropagation();
    navigate(`/dashboard/pos-mitra-by-location/edit/${locationId}`);
  };

  const handleDeleteLocation = async (locationId: number, locationName: string, e: React.MouseEvent) => {
    e.stopPropagation();
    
    const posMitraCount = posMitraByLocation[locationId]?.length || 0;
    
    if (posMitraCount > 0) {
      alert(`Tidak dapat menghapus terminal "${locationName}" karena masih memiliki ${posMitraCount} pos mitra. Hapus pos mitra terlebih dahulu.`);
      return;
    }

    // Open confirmation dialog
    setLocationToDelete({ id: locationId, name: locationName });
    setDeleteDialogOpen(true);
  };

  const confirmDelete = async () => {
    if (!locationToDelete) return;

    setIsDeleting(true);
    try {
      await locationsApi.delete(locationToDelete.id);
      setDeleteDialogOpen(false);
      setLocationToDelete(null);
      alert('Terminal berhasil dihapus');
      loadData(); // Reload data
    } catch (error: any) {
      console.error('Failed to delete location:', error);
      const msg = error?.response?.data?.message || error?.message || 'Gagal menghapus terminal';
      alert(msg);
    } finally {
      setIsDeleting(false);
    }
  };

  if (isLoading) {
    return (
      <div className="flex items-center justify-center min-h-[60vh]">
        <div className="text-center">
          <div className="w-16 h-16 border-4 border-primary border-t-transparent rounded-full animate-spin mx-auto mb-4" />
          <p className="text-muted-foreground">Memuat data...</p>
        </div>
      </div>
    );
  }

  const totalPosMitra = Object.values(posMitraByLocation).flat().length;
  const verifiedCount = Object.values(posMitraByLocation).flat().filter(p => p.verifikasi_status === "approved").length;

  return (
    <div className="flex flex-col gap-6 p-1">
      {/* Header */}
      <div className="flex items-start justify-between">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Terminal Pos Mitra</h1>
          <p className="text-muted-foreground mt-2">
            Kelola lokasi terminal dan pos mitra berdasarkan wilayah
          </p>
        </div>
        <Button onClick={() => navigate('/dashboard/pos-mitra-by-location/create')} className="gap-2">
          <Plus size={18} />
          Buat Terminal Baru
        </Button>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <Card className="border-l-4 border-l-blue-500">
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-muted-foreground">Total Terminal</p>
                <p className="text-3xl font-bold mt-2">{locations.length}</p>
              </div>
              <div className="h-12 w-12 bg-blue-50 rounded-full flex items-center justify-center">
                <Building2 className="h-6 w-6 text-blue-600" />
              </div>
            </div>
          </CardContent>
        </Card>

        <Card className="border-l-4 border-l-purple-500">
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-muted-foreground">Total Pos Mitra</p>
                <p className="text-3xl font-bold mt-2">{totalPosMitra}</p>
              </div>
              <div className="h-12 w-12 bg-purple-50 rounded-full flex items-center justify-center">
                <Users className="h-6 w-6 text-purple-600" />
              </div>
            </div>
          </CardContent>
        </Card>

        <Card className="border-l-4 border-l-emerald-500">
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-muted-foreground">Terverifikasi</p>
                <p className="text-3xl font-bold mt-2">{verifiedCount}</p>
              </div>
              <div className="h-12 w-12 bg-emerald-50 rounded-full flex items-center justify-center">
                <CheckCircle className="h-6 w-6 text-emerald-600" />
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Locations List */}
      <div className="space-y-4">
        {locations.map((location) => {
          const posmitraList = posMitraByLocation[location.id] || [];
          const isExpanded = expandedLocation === location.id;

          return (
            <Card key={location.id} className="overflow-hidden hover:shadow-md transition-shadow">
              <div
                onClick={() => toggleLocation(location.id)}
                className="cursor-pointer"
              >
                <CardHeader className="pb-4 hover:bg-muted/50 transition-colors">
                  <div className="flex items-start justify-between">
                    <div className="flex items-start gap-4 flex-1">
                      <div className="h-12 w-12 bg-blue-50 rounded-xl flex items-center justify-center flex-shrink-0">
                        <MapPin className="w-6 h-6 text-blue-600" />
                      </div>
                      <div className="flex-1">
                        <div className="flex items-center gap-2 mb-2">
                          <CardTitle className="text-xl">
                            {location.name}
                          </CardTitle>
                          <Badge variant="secondary" className="text-xs">
                            {location.city}
                          </Badge>
                        </div>
                        <div className="space-y-1.5 text-sm text-muted-foreground">
                          <div className="flex items-center gap-2">
                            <span className="font-medium text-foreground">📍</span>
                            {location.address}
                          </div>
                          {location.latitude && location.longitude && (
                            <div className="flex items-center gap-2">
                              <span className="font-medium text-foreground">🗺️</span>
                              <span className="font-mono text-xs">
                                {parseFloat(location.latitude).toFixed(4)}, {parseFloat(location.longitude).toFixed(4)}
                              </span>
                              <a 
                                href={`https://www.google.com/maps?q=${location.latitude},${location.longitude}`}
                                target="_blank"
                                rel="noopener noreferrer"
                                onClick={(e) => e.stopPropagation()}
                                className="text-primary hover:underline text-xs"
                              >
                                Lihat di Maps →
                              </a>
                            </div>
                          )}
                        </div>
                      </div>
                    </div>

                    <div className="flex items-center gap-3 flex-shrink-0">
                      <div className="flex items-center gap-2 bg-primary/10 px-4 py-2 rounded-lg">
                        <Users size={18} className="text-primary" />
                        <div className="text-center">
                          <div className="font-bold text-primary text-lg">
                            {posmitraList.length}
                          </div>
                          <div className="text-xs text-muted-foreground">Mitra</div>
                        </div>
                      </div>
                      <Button 
                        variant="outline" 
                        size="icon" 
                        className="h-9 w-9"
                        onClick={(e) => handleEditLocation(location.id, e)}
                        title="Edit Terminal"
                      >
                        <Edit size={16} />
                      </Button>
                      <Button 
                        variant="outline" 
                        size="icon" 
                        className="h-9 w-9 text-red-600 hover:text-red-700 hover:bg-red-50"
                        onClick={(e) => handleDeleteLocation(location.id, location.name, e)}
                        title="Hapus Terminal"
                      >
                        <Trash2 size={16} />
                      </Button>
                      <Button variant="ghost" size="icon" className="h-10 w-10">
                        {isExpanded ? (
                          <ChevronUp size={20} />
                        ) : (
                          <ChevronDown size={20} />
                        )}
                      </Button>
                    </div>
                  </div>
                </CardHeader>
              </div>

              {/* Expanded Content */}
              {isExpanded && (
                <CardContent className="pt-0 border-t bg-muted/30">
                  {posmitraList.length > 0 ? (
                    <div className="space-y-2 mt-4">
                      {posmitraList.map((pos, index) => (
                        <div
                          key={pos.id}
                          className="flex items-center justify-between p-4 bg-background rounded-lg hover:shadow-sm transition-all border"
                        >
                          <div className="flex items-center gap-4 flex-1">
                            <div className="h-10 w-10 bg-muted rounded-full flex items-center justify-center flex-shrink-0 font-semibold text-muted-foreground">
                              {index + 1}
                            </div>
                            <div className="flex-1 min-w-0">
                              <div className="font-semibold text-foreground mb-1">
                                {pos.name}
                              </div>
                              <div className="flex flex-wrap items-center gap-4 text-sm text-muted-foreground">
                                <span className="flex items-center gap-1">
                                  📧 {pos.email}
                                </span>
                                <span className="flex items-center gap-1">
                                  📱 {pos.phone}
                                </span>
                              </div>
                            </div>
                          </div>

                          <div className="flex items-center gap-3 flex-shrink-0">
                            <span
                              className={`inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-semibold border ${getStatusColor(
                                pos.verifikasi_status
                              )}`}
                            >
                              <span className="w-1.5 h-1.5 rounded-full bg-current" />
                              {getStatusLabel(pos.verifikasi_status)}
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
                    <div className="py-12 text-center">
                      <div className="h-16 w-16 bg-muted rounded-full flex items-center justify-center mx-auto mb-4">
                        <Users size={32} className="text-muted-foreground" />
                      </div>
                      <p className="text-muted-foreground font-medium">Belum ada pos mitra di terminal ini</p>
                      <p className="text-sm text-muted-foreground mt-1">Tambahkan pos mitra baru untuk terminal ini</p>
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
        <Card className="border-dashed">
          <CardContent className="py-16 text-center">
            <div className="h-20 w-20 bg-muted rounded-full flex items-center justify-center mx-auto mb-6">
              <MapPin size={40} className="text-muted-foreground" />
            </div>
            <h3 className="text-lg font-semibold mb-2">Belum Ada Terminal</h3>
            <p className="text-muted-foreground mb-6">Mulai dengan membuat terminal pertama Anda</p>
            <Button onClick={() => navigate('/dashboard/pos-mitra-by-location/create')} className="gap-2">
              <Plus size={18} />
              Buat Terminal Pertama
            </Button>
          </CardContent>
        </Card>
      )}

      {/* Delete Confirmation Dialog */}
      <AlertDialog open={deleteDialogOpen} onOpenChange={setDeleteDialogOpen}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle className="flex items-center gap-2">
              <div className="h-10 w-10 bg-red-100 rounded-full flex items-center justify-center">
                <Trash2 className="h-5 w-5 text-red-600" />
              </div>
              Hapus Terminal
            </AlertDialogTitle>
            <AlertDialogDescription className="text-base pt-2">
              Apakah Anda yakin ingin menghapus terminal{" "}
              <span className="font-semibold text-foreground">"{locationToDelete?.name}"</span>?
              <div className="mt-3 p-3 bg-red-50 border border-red-200 rounded-lg">
                <p className="text-sm text-red-800">
                  ⚠️ <strong>Peringatan:</strong> Tindakan ini tidak dapat dibatalkan.
                </p>
              </div>
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel disabled={isDeleting}>Batal</AlertDialogCancel>
            <AlertDialogAction
              onClick={confirmDelete}
              disabled={isDeleting}
              className="bg-red-600 hover:bg-red-700 focus:ring-red-600"
            >
              {isDeleting ? (
                <>
                  <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin mr-2" />
                  Menghapus...
                </>
              ) : (
                <>
                  <Trash2 className="w-4 h-4 mr-2" />
                  Ya, Hapus Terminal
                </>
              )}
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  );
};

export default PosMitraByLocation;
