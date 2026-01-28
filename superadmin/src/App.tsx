import { Toaster } from "@/components/ui/toaster";
import { Toaster as Sonner } from "@/components/ui/sonner";
import { TooltipProvider } from "@/components/ui/tooltip";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { BrowserRouter, Routes, Route } from "react-router-dom";
import Index from "./pages/Index";
import ForgotPassword from "./pages/ForgotPassword";
import ResetPassword from "./pages/ResetPassword";
import NotFound from "./pages/NotFound";
import DashboardLayout from "./layouts/DashboardLayout";
import Dashboard from "./pages/Dashboard";
import VerifikasiMitra from "./pages/VerifikasiMitra";
import DetailMitra from "./pages/DetailMitra";
import DaftarMitra from "./pages/DaftarMitra";
import KendaraanMitra from "./pages/KendaraanMitra";
import DetailKendaraanMitra from "./pages/DetailKendaraanMitra";
import BlokirMitra from "./pages/BlokirMitra";
import VerifikasiCustomer from "./pages/VerifikasiCustomer";
import DaftarCustomer from "./pages/DaftarCustomer";
import DetailCustomer from "./pages/DetailCustomer";
import BlokirCustomer from "./pages/BlokirCustomer";
import Pesanan from "./pages/Pesanan";
import DetailPesanan from "./pages/DetailPesanan";
import Refund from "./pages/Refund";
import DetailRefund from "./pages/DetailRefund";
import Laporan from "./pages/Laporan";
import DetailLaporan from "./pages/DetailLaporan";
import Pengaturan from "./pages/Pengaturan";
import PengaturanEdit from "./pages/PengaturanEdit";
import { MitraProvider } from "./contexts/MitraContext";
import { CustomerProvider } from "./contexts/CustomerContext";
import { PesananProvider } from "./contexts/PesananContext";
import { RefundProvider } from "./contexts/RefundContext";
import { LaporanProvider } from "./contexts/LaporanContext";
import { AdminProvider } from "./contexts/AdminContext";
import { VerifikasiProvider } from "./contexts/VerifikasiContext";
import { KendaraanMitraProvider } from "./contexts/KendaraanMitraContext";

const queryClient = new QueryClient();

const App = () => (
  <QueryClientProvider client={queryClient}>
    <TooltipProvider>
      <AdminProvider>
        <MitraProvider>
          <KendaraanMitraProvider>
            <CustomerProvider>
              <VerifikasiProvider>
                <PesananProvider>
                  <RefundProvider>
                    <LaporanProvider>
                      <Toaster />
                      <Sonner />
                      <BrowserRouter>
                        <Routes>
                          <Route path="/" element={<Index />} />
                          <Route path="/forgot-password" element={<ForgotPassword />} />
                          <Route path="/reset-password" element={<ResetPassword />} />
                        
                        {/* Dashboard Routes */}
                        <Route path="/dashboard" element={<DashboardLayout />}>
                          <Route index element={<Dashboard />} />
                          <Route path="verifikasi-mitra" element={<VerifikasiMitra />} />
                          <Route path="verifikasi-mitra/:id" element={<DetailMitra />} />
                          <Route path="mitra" element={<DaftarMitra />} />
                          <Route path="mitra/:id" element={<DetailMitra />} />
                          <Route path="mitra-kendaraan" element={<KendaraanMitra />} />
                          <Route path="mitra-kendaraan/:id" element={<DetailKendaraanMitra />} />
                          <Route path="mitra-blokir" element={<BlokirMitra />} />
                          <Route path="verifikasi-costumer" element={<VerifikasiCustomer />} />
                          <Route path="verifikasi-costumer/:id" element={<DetailCustomer />} />
                          <Route path="costumer" element={<DaftarCustomer />} />
                          <Route path="costumer/:id" element={<DetailCustomer />} />
                          <Route path="costumer-blokir" element={<BlokirCustomer />} />
                          <Route path="pesanan" element={<Pesanan />} />
                          <Route path="pesanan/:id" element={<DetailPesanan />} />
                          <Route path="refund" element={<Refund />} />
                          <Route path="refund/:id" element={<DetailRefund />} />
                          <Route path="laporan" element={<Laporan />} />
                          <Route path="laporan/:id" element={<DetailLaporan />} />
                          <Route path="pengaturan" element={<Pengaturan />} />
                          <Route path="pengaturan/edit" element={<PengaturanEdit />} />
                        </Route>
                        
                        {/* ADD ALL CUSTOM ROUTES ABOVE THE CATCH-ALL "*" ROUTE */}
                        <Route path="*" element={<NotFound />} />
                      </Routes>
                    </BrowserRouter>
                    </LaporanProvider>
                  </RefundProvider>
                </PesananProvider>
              </VerifikasiProvider>
            </CustomerProvider>
          </KendaraanMitraProvider>
        </MitraProvider>
      </AdminProvider>
    </TooltipProvider>
  </QueryClientProvider>
);

export default App;
