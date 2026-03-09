import { Outlet, useLocation } from "react-router-dom";
import DashboardSidebar from "@/components/DashboardSidebar";
import DashboardHeader from "@/components/DashboardHeader";

const pageTitles: Record<string, string> = {
  "/dashboard": "Selamat Datang",
  "/dashboard/profile": "Profile",
  "/dashboard/verifikasi-mitra": "Verifikasi Mitra",
  "/dashboard/verifikasi-costumer": "Verifikasi Costumer",
  "/dashboard/mitra": "Daftar Mitra",
  "/dashboard/costumer": "Daftar Costumer",
  "/dashboard/pesanan": "Pesanan",
  "/dashboard/refund": "Refund",
  "/dashboard/laporan": "Laporan",
  "/dashboard/pengaturan": "Pengaturan",
  "/dashboard/banners": "Banner",
  "/dashboard/reward/catalog": "Katalog Reward",
  "/dashboard/manajemen-admin": "Manajemen Admin",
  "/dashboard/pos-mitra": "Pos Mitra",
  "/dashboard/pos-mitra-by-location": "Terminal",
  "/dashboard/qr-bypass-settings": "Pengaturan QR Bypass",
};

const DashboardLayout = () => {
  const location = useLocation();
  const pageTitle = pageTitles[location.pathname] || "Dashboard";
  const isWelcomePage = location.pathname === "/dashboard";

  return (
    <div className="flex h-screen w-full overflow-hidden">
      <DashboardSidebar />
      <div className="flex-1 flex flex-col overflow-hidden ml-64">
        <DashboardHeader 
          pageTitle={pageTitle}
          showWelcome={isWelcomePage}
        />
        <main className="flex-1 bg-muted/30 p-6 overflow-y-auto">
          <Outlet />
        </main>
      </div>
    </div>
  );
};

export default DashboardLayout;
