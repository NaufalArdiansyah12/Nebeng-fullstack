import { ReactNode } from "react";
import { useEffect, useState } from "react";
import { useNavigate, useLocation } from "react-router-dom";
import api from "@/lib/api";
import {
  LayoutDashboard, Receipt,
  Users,
  MapPin,
  Wallet,
  Settings,
  LogOut,
  Search,
  Eye,
  ChevronDown
} from "lucide-react";
import {
  AlertDialog,
  AlertDialogTrigger,
  AlertDialogContent,
  AlertDialogHeader,
  AlertDialogTitle,
  AlertDialogFooter,
  AlertDialogCancel,
  AlertDialogAction,
} from "@/components/ui/alert-dialog";

import { Input } from "@/components/ui/input";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger
} from "@/components/ui/dropdown-menu";
import { toast } from "sonner";
import UserDropdown from "./UserDropdown";

const menuItems = [
  { icon: LayoutDashboard, label: "Dashboard", path: "/dashboard" },
  { icon: Receipt, label: "Transaksi", path: "/transaksi" },
  { icon: Users, label: "Mitra", path: "/mitra" },
  { icon: MapPin, label: "Pos Mitra", path: "/pos-mitra" },
  { icon: Wallet, label: "Pencairan Dana", path: "/pencairan-dana" },
];

const helpItems = [
  { icon: Settings, label: "Pengaturan", path: "/pengaturan" },
];

interface DashboardLayoutProps {
  children: ReactNode;
  title: string;
}

const DashboardLayout = ({ children, title }: DashboardLayoutProps) => {
  const navigate = useNavigate();
  const location = useLocation();

  const [user, setUser] = useState<{ name: string } | null>(null);
  const [openLogoutDialog, setOpenLogoutDialog] = useState(false);


  useEffect(() => {
    const stored = localStorage.getItem("user");
    if (!stored) return;

    const parsed = JSON.parse(stored);

    // kalau ingin fetch dari backend:
    api.get(`/users/${parsed.id}`)
      .then(res => setUser(res.data))
      .catch(() => setUser(parsed)); // fallback ke localStorage
  }, []);

  const handleLogout = () => {
    localStorage.removeItem("user");
    toast.success("Berhasil logout");
    navigate("/login-finance");
  };

  const isActive = (path: string) => location.pathname === path;

  return (
    <div className="min-h-screen flex bg-muted/30">
      {/* Sidebar */}
      <aside className="w-64 bg-login-sidebar flex flex-col min-h-screen fixed left-0 top-0">
        {/* Logo */}
        <div className="p-6">
          <div className="flex items-center gap-2">
            <span className="text-xl font-bold text-login-sidebar-foreground">NEBENG</span>
            <span className="text-login-highlight text-xl">✦</span>
          </div>
          <p className="text-login-sidebar-foreground/60 text-xs mt-1">
            TRANSPORTASI MENJADI LEBIH MUDAH
          </p>
        </div>

        {/* Main Menu */}
        <div className="flex-1 px-4">
          <p className="text-login-sidebar-foreground/50 text-xs font-medium mb-3 px-3">MAIN MENU</p>
          <nav className="space-y-1">
            {menuItems.map((item) => (
              <button
                key={item.label}
                onClick={() => navigate(item.path)}
                className={`w-full flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm transition-colors ${isActive(item.path)
                    ? "bg-login-sidebar-foreground/20 text-login-sidebar-foreground"
                    : "text-login-sidebar-foreground/70 hover:bg-login-sidebar-foreground/10 hover:text-login-sidebar-foreground"
                  }`}
              >
                <item.icon className="h-5 w-5" />
                {item.label}
              </button>
            ))}
          </nav>

          <p className="text-login-sidebar-foreground/50 text-xs font-medium mb-3 px-3 mt-8">HELP & SUPPORT</p>
          <nav className="space-y-1">
            {helpItems.map((item) => (
              <button
                key={item.label}
                onClick={() => navigate(item.path)}
                className={`w-full flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm transition-colors ${isActive(item.path)
                    ? "bg-login-sidebar-foreground/20 text-login-sidebar-foreground"
                    : "text-login-sidebar-foreground/70 hover:bg-login-sidebar-foreground/10 hover:text-login-sidebar-foreground"
                  }`}
              >
                <item.icon className="h-5 w-5" />
                {item.label}
              </button>
            ))}
          </nav>
        </div>

        {/* Logout Button */}
        <div className="p-4">
<AlertDialog>
  <AlertDialogTrigger asChild>
    <button
      className="w-full flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm bg-login-sidebar-foreground/10 text-login-sidebar-foreground hover:bg-login-sidebar-foreground/20 transition-colors"
    >
      <LogOut className="h-5 w-5" />
      Keluar
    </button>
  </AlertDialogTrigger>

  <AlertDialogContent className="max-w-md">
    <AlertDialogHeader className="text-center">
      <AlertDialogTitle>
        Apakah yakin ingin keluar dari akun Anda?
      </AlertDialogTitle>
    </AlertDialogHeader>

    <div className="flex justify-center my-4">
      <LogOut className="h-10 w-10 text-primary" />
    </div>

    <AlertDialogFooter className="flex-col gap-2">
      <AlertDialogCancel className="w-full">
        Batal
      </AlertDialogCancel>
      <AlertDialogAction
        className="w-full bg-primary text-white"
        onClick={handleLogout}
      >
        Keluar
      </AlertDialogAction>
    </AlertDialogFooter>
  </AlertDialogContent>
</AlertDialog>

        </div>
      </aside>

      {/* Main Content */}
      <main className="flex-1 ml-64">
        {/* Header */}
        <header className="bg-background border-b border-border px-6 py-4 flex items-center justify-between sticky top-0 z-10">
          <h1 className="text-xl font-semibold text-foreground">{title}</h1>

          <div className="flex items-center gap-4">
            {/* Search */}
            <div className="relative">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
              <Input
                placeholder="Search"
                className="pl-9 w-64 h-10 bg-muted/50 border-0"
              />
            </div>

            {/* User Menu */}
<DropdownMenu modal={false}>
  <DropdownMenuTrigger asChild>
    <UserDropdown userName={user?.name} />
  </DropdownMenuTrigger>

  <DropdownMenuContent align="end" sideOffset={5} className="w-48">
    <DropdownMenuItem onClick={() => navigate("/pengaturan")}>
      <Eye className="h-4 w-4 mr-2" />
      View Profile
    </DropdownMenuItem>

    <DropdownMenuItem
      onSelect={(e) => {
        e.preventDefault();
        setOpenLogoutDialog(true);
      }}
    >
      <LogOut className="h-4 w-4 mr-2" />
      Log out
    </DropdownMenuItem>
  </DropdownMenuContent>
</DropdownMenu>

<AlertDialog
  open={openLogoutDialog}
  onOpenChange={setOpenLogoutDialog}
>
  <AlertDialogContent className="max-w-md">
    <AlertDialogHeader className="text-center">
      <AlertDialogTitle>
        Apakah yakin ingin keluar dari akun Anda?
      </AlertDialogTitle>
    </AlertDialogHeader>

    <div className="flex justify-center my-4">
      <LogOut className="h-10 w-10 text-primary" />
    </div>

    <AlertDialogFooter className="flex-col gap-2">
      <AlertDialogCancel className="w-full">
        Batal
      </AlertDialogCancel>

      <AlertDialogAction
        className="w-full bg-primary text-white"
        onClick={handleLogout}
      >
        Keluar
      </AlertDialogAction>
    </AlertDialogFooter>
  </AlertDialogContent>
</AlertDialog>




          </div>
        </header>

        {/* Page Content */}
        <div className="p-6">
          {children}
        </div>
      </main>
    </div>
  );
};

export default DashboardLayout;
