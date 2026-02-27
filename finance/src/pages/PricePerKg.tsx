// PricePerKg page has been removed and archived in:
// finance/src/deprecated/removed_price_system/
// This stub prevents imports from failing while removal is in progress.

// export default function PricePerKg() {
//   return null;
// }
// import {
//   AlertDialog,
//   AlertDialogAction,
//   AlertDialogCancel,
//   AlertDialogContent,
//   AlertDialogDescription,
//   AlertDialogFooter,
//   AlertDialogHeader,
//   AlertDialogTitle,
// } from "@/components/ui/alert-dialog";

// interface PriceRate {
//   id: number;
//   service_type: string;
//   ride_type: string;
//   bagasi_capacity?: number | null;
//   rate_per_kg: number;
//   min_charge: number;
//   is_active: boolean;
//   effective_from: string;
// }

// const PricePerKg = () => {
//   const [priceData, setPriceData] = useState<PriceRate[]>([]);
//   const [loading, setLoading] = useState(true);
//   const [search, setSearch] = useState("");
//   const [serviceFilter, setServiceFilter] = useState("all");
//   const [rideTypeFilter, setRideTypeFilter] = useState("all");
//   const [dialogOpen, setDialogOpen] = useState(false);
//   const [editData, setEditData] = useState<PriceRate | null>(null);
//   const [deleteId, setDeleteId] = useState<number | null>(null);

//   useEffect(() => {
//     fetchPrices();
//   }, []);

//   const fetchPrices = async () => {
//     try {
//       setLoading(true);
//       const response = await api.get('/price-per-kg');
//       if (response.data.success) {
//         setPriceData(response.data.data);
//       }
//     } catch (error) {
//       console.error('Error fetching prices:', error);
//       toast.error('Gagal mengambil data tarif');
//     } finally {
//       setLoading(false);
//     }
//   };

//   const filteredData = priceData.filter((rate) => {
//     const matchSearch =
//       rate.service_type.toLowerCase().includes(search.toLowerCase()) ||
//       rate.ride_type.toLowerCase().includes(search.toLowerCase());
//     const matchService =
//       serviceFilter === "all" || rate.service_type === serviceFilter;
//     const matchRideType = rideTypeFilter === "all" || rate.ride_type === rideTypeFilter;

//     return matchSearch && matchService && matchRideType;
//   });

//   const handleAdd = () => {
//     setEditData(null);
//     setDialogOpen(true);
//   };

//   const handleEdit = (rate: PriceRate) => {
//     setEditData(rate);
//     setDialogOpen(true);
//   };

//   const handleSave = async (data: Partial<PriceRate>) => {
//     try {
//       if (editData) {
//         // Update existing
//         const response = await api.put(`/price-per-kg/${editData.id}`, data);
//         if (response.data.success) {
//           toast.success(response.data.message);
//           fetchPrices();
//         }
//       } else {
//         // Add new
//         const response = await api.post('/price-per-kg', data);
//         if (response.data.success) {
//           toast.success(response.data.message);
//           fetchPrices();
//         }
//       }
//       setDialogOpen(false);
//     } catch (error: any) {
//       console.error('Error saving price:', error);
//       const errorMessage = error.response?.data?.message || 'Gagal menyimpan tarif';
//       toast.error(errorMessage);
//     }
//   };

//   const handleToggleStatus = async (id: number, isActive: boolean) => {
//     try {
//       const response = await api.post(`/price-per-kg/${id}/toggle-status`);
//       if (response.data.success) {
//         toast.success(response.data.message);
//         fetchPrices();
//       }
//     } catch (error: any) {
//       console.error('Error toggling status:', error);
//       toast.error('Gagal mengubah status tarif');
//     }
//   };

//   const handleDeleteConfirm = async () => {
//     if (deleteId) {
//       try {
//         const response = await api.delete(`/price-per-kg/${deleteId}`);
//         if (response.data.success) {
//           toast.success(response.data.message);
//           fetchPrices();
//         }
//         setDeleteId(null);
//       } catch (error: any) {
//         console.error('Error deleting price:', error);
//         toast.error('Gagal menghapus tarif');
//       }
//     }
//   };

//   return (
//     <DashboardLayout title="Tarif per Kg">
//       <div className="bg-background border border-border rounded-xl overflow-hidden">
//         {/* Header */}
//         <div className="p-5 border-b border-border flex items-center justify-between">
//           <h3 className="font-semibold">Daftar Tarif per Kg</h3>

//           <div className="flex items-center gap-3">
//             <ServiceFilter
//               value={serviceFilter}
//               onChange={setServiceFilter}
//             />
//             <RideTypeFilter value={rideTypeFilter} onChange={setRideTypeFilter} />
//             <PriceSearch value={search} onChange={setSearch} />

//             <Button onClick={handleAdd} className="gap-2">
//               <Plus className="w-4 h-4" />
//               Tambah Tarif
//             </Button>
//           </div>
//         </div>

//         {/* Table */}
//         {loading ? (
//           <div className="flex items-center justify-center py-12">
//             <p className="text-muted-foreground">Loading...</p>
//           </div>
//         ) : (
//           <PriceTable
//             data={filteredData}
//             onEdit={handleEdit}
//             onDelete={(id) => setDeleteId(id)}
//             onToggleStatus={handleToggleStatus}
//           />
//         )}
//       </div>

//       {/* Form Dialog */}
//       <PriceFormDialog
//         open={dialogOpen}
//         onOpenChange={setDialogOpen}
//         editData={editData}
//         onSave={handleSave}
//       />

//       {/* Delete Confirmation Dialog */}
//       <AlertDialog
//         open={deleteId !== null}
//         onOpenChange={(open) => !open && setDeleteId(null)}
//       >
//         <AlertDialogContent>
//           <AlertDialogHeader>
//             <AlertDialogTitle>Hapus Tarif?</AlertDialogTitle>
//             <AlertDialogDescription>
//               Apakah Anda yakin ingin menghapus tarif ini? Tindakan ini tidak
//               dapat dibatalkan.
//             </AlertDialogDescription>
//           </AlertDialogHeader>
//           <AlertDialogFooter>
//             <AlertDialogCancel>Batal</AlertDialogCancel>
//             <AlertDialogAction
//               onClick={handleDeleteConfirm}
//               className="bg-red-600 hover:bg-red-700"
//             >
//               Hapus
//             </AlertDialogAction>
//           </AlertDialogFooter>
//         </AlertDialogContent>
//       </AlertDialog>
//     </DashboardLayout>
//   );
// };

// export default PricePerKg;
