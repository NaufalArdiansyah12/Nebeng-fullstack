import { useState } from "react";
import { useNavigate, useLocation } from "react-router-dom";
import LogoutConfirmPopup from "./LogoutConfirmPopup";
import {
  LayoutDashboard,
  ShieldCheck,
  Briefcase,
  Users,
  ShoppingCart,
  RotateCcw,
  BarChart3,
  Settings,
  LogOut,
  ChevronRight,
  ChevronDown,
} from "lucide-react";
import { cn } from "@/lib/utils";

interface MenuItem {
  title: string;
  icon: React.ElementType;
  path?: string;
  children?: { title: string; path: string }[];
}

const mainMenuItems: MenuItem[] = [
  { title: "Dashboard", icon: LayoutDashboard, path: "/dashboard" },
  {
    title: "Verifikasi Data",
    icon: ShieldCheck,
    children: [
      { title: "Verifikasi Mitra", path: "/dashboard/verifikasi-mitra" },
      { title: "Verifikasi Costumer", path: "/dashboard/verifikasi-costumer" },
    ],
  },
  {
    title: "Mitra",
    icon: Briefcase,
    children: [
      { title: "Daftar Mitra", path: "/dashboard/mitra" },
      { title: "Kendaraan Mitra", path: "/dashboard/mitra-kendaraan" },
      { title: "Blokir", path: "/dashboard/mitra-blokir" },
    ],
  },
  {
    title: "Costumer",
    icon: Users,
    children: [
      { title: "Daftar Costumer", path: "/dashboard/costumer" },
      { title: "Blokir", path: "/dashboard/costumer-blokir" },
    ],
  },
  { title: "Pesanan", icon: ShoppingCart, path: "/dashboard/pesanan" },
  { title: "Refund", icon: RotateCcw, path: "/dashboard/refund" },
  { title: "Laporan", icon: BarChart3, path: "/dashboard/laporan" },
];

const supportMenuItems: MenuItem[] = [
  { title: "Pengaturan", icon: Settings, path: "/dashboard/pengaturan" },
];

const DashboardSidebar = () => {
  const navigate = useNavigate();
  const location = useLocation();
  
  // Auto-expand menus that have active children
  const getInitialExpandedMenus = () => {
    const expanded: string[] = [];
    [...mainMenuItems, ...supportMenuItems].forEach((item) => {
      if (item.children?.some((child) => location.pathname === child.path)) {
        expanded.push(item.title);
      }
    });
    return expanded;
  };

  const [expandedMenus, setExpandedMenus] = useState<string[]>(getInitialExpandedMenus);
  const [showLogoutPopup, setShowLogoutPopup] = useState(false);

  const toggleMenu = (title: string) => {
    setExpandedMenus((prev) =>
      prev.includes(title)
        ? prev.filter((t) => t !== title)
        : [...prev, title]
    );
  };

  const isActive = (path?: string) => {
    if (!path) return false;
    return location.pathname === path;
  };

  const isParentActive = (children?: { title: string; path: string }[]) => {
    if (!children) return false;
    return children.some((child) => location.pathname === child.path);
  };

  const handleLogoutClick = () => {
    setShowLogoutPopup(true);
  };

  const handleLogoutConfirm = () => {
    setShowLogoutPopup(false);
    navigate("/");
  };

  const renderMenuItem = (item: MenuItem) => {
    const hasChildren = item.children && item.children.length > 0;
    const isExpanded = expandedMenus.includes(item.title);
    const active = isActive(item.path) || isParentActive(item.children);

    return (
      <div key={item.title}>
        <button
          onClick={() => {
            if (hasChildren) {
              toggleMenu(item.title);
            } else if (item.path) {
              navigate(item.path);
            }
          }}
          className={cn(
            "w-full flex items-center justify-between px-4 py-3 text-sm font-medium rounded-lg transition-colors",
            active
              ? "bg-white/10 text-white"
              : "text-white/70 hover:bg-white/5 hover:text-white"
          )}
        >
          <div className="flex items-center gap-3">
            <item.icon size={20} />
            <span>{item.title}</span>
          </div>
          {hasChildren && (
            isExpanded ? <ChevronDown size={16} /> : <ChevronRight size={16} />
          )}
        </button>

        {hasChildren && isExpanded && (
          <div className="ml-9 mt-1 space-y-1">
            {item.children?.map((child) => (
              <button
                key={child.path}
                onClick={() => navigate(child.path)}
                className={cn(
                  "w-full text-left px-4 py-2 text-sm rounded-lg transition-colors",
                  isActive(child.path)
                    ? "bg-white/10 text-white"
                    : "text-white/60 hover:bg-white/5 hover:text-white"
                )}
              >
                {child.title}
              </button>
            ))}
          </div>
        )}
      </div>
    );
  };

  return (
    <aside className="w-64 min-h-screen bg-[#1e3a5f] flex flex-col">
      {/* Logo */}
      <div className="p-6">
        <h1 className="text-2xl font-bold text-white">NEBENG</h1>
        <p className="text-xs text-white/60 mt-1">TRANSPORTASI MENJADI LEBIH MUDAH</p>
      </div>

      {/* Main Menu */}
      <div className="flex-1 px-4">
        <p className="text-xs font-semibold text-white/40 mb-3 px-4">MAIN MENU</p>
        <nav className="space-y-1">
          {mainMenuItems.map(renderMenuItem)}
        </nav>

        {/* Help & Support */}
        <p className="text-xs font-semibold text-white/40 mt-8 mb-3 px-4">HELP & SUPPORT</p>
        <nav className="space-y-1">
          {supportMenuItems.map(renderMenuItem)}
        </nav>
      </div>

      {/* Logout Button */}
      <div className="p-4">
        <button
          onClick={handleLogoutClick}
          className="w-full flex items-center gap-3 px-4 py-3 text-sm font-medium text-white bg-primary rounded-lg hover:bg-primary/90 transition-colors"
        >
          <LogOut size={20} />
          <span>Keluar</span>
        </button>
      </div>

      <LogoutConfirmPopup
        isOpen={showLogoutPopup}
        onClose={() => setShowLogoutPopup(false)}
        onConfirm={handleLogoutConfirm}
      />
    </aside>
  );
};

export default DashboardSidebar;
