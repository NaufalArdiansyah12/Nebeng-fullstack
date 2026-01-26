import { Toaster } from "@/components/ui/toaster";
import { Toaster as Sonner } from "@/components/ui/sonner";
import { TooltipProvider } from "@/components/ui/tooltip";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import Login from "./pages/Login";
import ForgotPassword from "./pages/ForgotPassword";
import ResetPassword from "./pages/ResetPassword";
import Dashboard from "./pages/Dashboard";
import Transaksi from "./pages/Transaksi";
import TransactionDetail from "./pages/detailTransaksi";
import Mitra from "./pages/Mitra";
import DetailMitra from "./pages/DetailMitra";
import PosMitra from "./pages/PosMitra";
import DetailPosMitra from "./pages/DetailPosMitra";
import PencairanDana from "./pages/PencairanDana";
import DetailPencairanDana  from "./pages/Detailpencairan";
import EditDetailPencairanDana from "./pages/editPencairan";
// import Pengaturan from "./pages/Pengaturan";
import NotFound from "./pages/NotFound";
import ProtectedRoute from "./components/ProtectedRoute";

const queryClient = new QueryClient();

const App = () => (
  <QueryClientProvider client={queryClient}>
    <TooltipProvider>
      <Toaster />
      <Sonner />
      <BrowserRouter>
        <Routes>
          <Route path="/" element={<Navigate to="/login-finance" replace />} />

          <Route path="/login-finance" element={<Login />} />
          <Route path="/forgot-password" element={<ForgotPassword />} />
          <Route path="/reset-password" element={<ResetPassword />} />
          <Route path="/dashboard" element={<ProtectedRoute><Dashboard /></ProtectedRoute>} />
          <Route path="/transaksi" element={<ProtectedRoute><Transaksi /></ProtectedRoute>} />
          <Route
  path="/transactions/:id"
  element={<ProtectedRoute><TransactionDetail /></ProtectedRoute>}
/>
          <Route path="/mitra" element={<ProtectedRoute><Mitra /></ProtectedRoute>} />
<Route path="/mitra/:id" element={<ProtectedRoute><DetailMitra /></ProtectedRoute>} />
<Route path="/pos-mitra" element={<ProtectedRoute><PosMitra /></ProtectedRoute>} />
<Route path="/pos-mitra/:id" element={<ProtectedRoute><DetailPosMitra /></ProtectedRoute>} />
<Route path="/pencairan-dana" element={<ProtectedRoute><PencairanDana /></ProtectedRoute>} />
<Route path="/pencairan/:id" element={<ProtectedRoute><DetailPencairanDana /></ProtectedRoute>} />
<Route path="/pencairan/:id/edit" element={<ProtectedRoute><EditDetailPencairanDana /></ProtectedRoute>} />
{/* <Route path="/pengaturan" element={<ProtectedRoute><Pengaturan /></ProtectedRoute>} /> */}






          {/* ADD ALL CUSTOM ROUTES ABOVE THE CATCH-ALL "*" ROUTE */}
          <Route path="*" element={<NotFound />} />
        </Routes>
      </BrowserRouter>
    </TooltipProvider>
  </QueryClientProvider>
);

export default App;
