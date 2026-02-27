import { Toaster } from "@/components/ui/toaster";
import { Toaster as Sonner } from "@/components/ui/sonner";
import { TooltipProvider } from "@/components/ui/tooltip";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import Login from "./pages/Login";
import ForgotPassword from "./pages/ForgotPassword";
import VerifyOTP from "./pages/VerifyOTP";
import ResetPassword from "./pages/ResetPassword";
import Dashboard from "./pages/Dashboard";
import Transaksi from "./pages/Transaksi";
import TransactionDetail from "./pages/DetailTransaksi";
import DetailTransaksi from "./pages/DetailTransaksi";
import Mitra from "./pages/Mitra";
import DetailMitra from "./pages/DetailMitra";
import PosMitra from "./pages/PosMitra";
import DetailPosMitra from "./pages/DetailPosMitra";
import Withdrawal from "./pages/Withdrawal";
import DetailWithdrawal from "./pages/DetailWithdrawal";
import Refund from "./pages/Refund";
import DetailRefund from "./pages/DetailRefund";
import Pengaturan from "./pages/Pengaturan";
import Fees from "./pages/Fees";
import Pricing from "./pages/Pricing";
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
          <Route path="/" element={<Navigate to="/login" replace />} />
          <Route path="/login" element={<Login />} />
          <Route path="/login-finance" element={<Navigate to="/login" replace />} />
          <Route path="/forgot-password" element={<ForgotPassword />} />
          <Route path="/verify-otp" element={<VerifyOTP />} />
          <Route path="/reset-password" element={<ResetPassword />} />
          <Route path="/dashboard" element={<ProtectedRoute><Dashboard /></ProtectedRoute>} />
          <Route path="/transaksi" element={<ProtectedRoute><Transaksi /></ProtectedRoute>} />
          <Route
  path="/transactions/:id"
  element={<ProtectedRoute><DetailTransaksi /></ProtectedRoute>}
/>
          <Route path="/mitra" element={<ProtectedRoute><Mitra /></ProtectedRoute>} />
<Route path="/mitra/:id" element={<ProtectedRoute><DetailMitra /></ProtectedRoute>} />
<Route path="/pos-mitra" element={<ProtectedRoute><PosMitra /></ProtectedRoute>} />
<Route path="/pos-mitra/:id" element={<ProtectedRoute><DetailPosMitra /></ProtectedRoute>} />
<Route path="/withdrawals" element={<ProtectedRoute><Withdrawal /></ProtectedRoute>} />
<Route path="/withdrawals/:id" element={<ProtectedRoute><DetailWithdrawal /></ProtectedRoute>} />
<Route path="/refund" element={<ProtectedRoute><Refund /></ProtectedRoute>} />
<Route path="/refund/:id" element={<ProtectedRoute><DetailRefund /></ProtectedRoute>} />
<Route path="/pengaturan" element={<ProtectedRoute><Pengaturan /></ProtectedRoute>} />
          <Route path="/pengaturan/biaya" element={<ProtectedRoute><Fees /></ProtectedRoute>} />
          <Route path="/tarif-per-kg" element={<ProtectedRoute><Pricing /></ProtectedRoute>} />

          {/* ADD ALL CUSTOM ROUTES ABOVE THE CATCH-ALL "*" ROUTE */}
          <Route path="*" element={<NotFound />} />
        </Routes>
      </BrowserRouter>
    </TooltipProvider>
  </QueryClientProvider>
);

export default App;
