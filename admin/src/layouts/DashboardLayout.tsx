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
};

const DashboardLayout = () => {
  const location = useLocation();
  const pageTitle = pageTitles[location.pathname] || "Dashboard";
  const isWelcomePage = location.pathname === "/dashboard";

  return (
    <div className="flex min-h-screen w-full">
      <DashboardSidebar />
      <div className="flex-1 flex flex-col">
        <DashboardHeader 
          pageTitle={pageTitle}
          showWelcome={isWelcomePage}
        />
        <main className="flex-1 bg-muted/30 p-6">
          <Outlet />
        </main>
      </div>
    </div>
  );
};

export default DashboardLayout;
