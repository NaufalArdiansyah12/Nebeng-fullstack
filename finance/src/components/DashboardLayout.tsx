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
  ChevronDown,
  RefreshCcw,
  Bell,
  X,
  AlertTriangle,
  UserPlus
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
import {
  Popover,
  PopoverContent,
  PopoverTrigger,
} from "@/components/ui/popover";
import {
  Dialog,
  DialogContent,
  DialogTrigger,
} from "@/components/ui/dialog";
import {
  Command,
  CommandEmpty,
  CommandGroup,
  CommandInput,
  CommandItem,
  CommandList,
} from "@/components/ui/command";
import { ScrollArea } from "@/components/ui/scroll-area";
import { Badge } from "@/components/ui/badge";
import { toast } from "sonner";
import UserDropdown from "./UserDropdown";

const menuItems = [
  { icon: LayoutDashboard, label: "Dashboard", path: "/dashboard" },
  { icon: Receipt, label: "Transaksi", path: "/transaksi" },
  { icon: Users, label: "Mitra", path: "/mitra" },
  { icon: MapPin, label: "Pos Mitra", path: "/pos-mitra" },
  { icon: Wallet, label: "Pencairan Dana", path: "/withdrawals" },
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
  const [notifications, setNotifications] = useState<any[]>([]);
  const [unreadCount, setUnreadCount] = useState(0);
  const [openNotifications, setOpenNotifications] = useState(false);
  const [openSearch, setOpenSearch] = useState(false);

  // Keyboard shortcut for search
  useEffect(() => {
    const down = (e: KeyboardEvent) => {
      if (e.key === "k" && (e.metaKey || e.ctrlKey)) {
        e.preventDefault();
        setOpenSearch((open) => !open);
      }
    };
    document.addEventListener("keydown", down);
    return () => document.removeEventListener("keydown", down);
  }, []);

  useEffect(() => {
    const stored = localStorage.getItem("user");
    if (!stored) return;

    const parsed = JSON.parse(stored);

    // kalau ingin fetch dari backend:
    api.get(`/users/${parsed.id}`)
      .then(res => setUser(res.data))
      .catch(() => setUser(parsed)); // fallback ke localStorage
  }, []);

  // Fetch notifications
  useEffect(() => {
    fetchNotifications();
    // Poll every 30 seconds
    const interval = setInterval(fetchNotifications, 30000);
    return () => clearInterval(interval);
  }, []);

  const fetchNotifications = async () => {
    try {
      const res = await api.get('/notifications');
      const notifs = res.data.data || res.data || [];
      
      // Check for new notifications
      if (notifications.length > 0) {
        const newNotifs = notifs.filter((n: any) => 
          !notifications.find((existing: any) => existing.id === n.id)
        );
        
        // Show toast for new notifications
        newNotifs.forEach((notif: any) => {
          toast(notif.title, {
            description: notif.message,
            duration: 5000,
          });
        });
      }
      
      setNotifications(notifs);
      setUnreadCount(notifs.filter((n: any) => !n.is_read).length);
    } catch (error) {
      console.error('Error fetching notifications:', error);
    }
  };

  const markAsRead = async (id: number) => {
    try {
      await api.put(`/notifications/${id}/read`);
      setNotifications(prev => 
        prev.map(n => n.id === id ? { ...n, is_read: true } : n)
      );
      setUnreadCount(prev => Math.max(0, prev - 1));
    } catch (error) {
      console.error('Error marking notification as read:', error);
    }
  };

  const getNotificationIcon = (type: string) => {
    switch (type) {
      case 'verification':
        return <UserPlus className="w-5 h-5" />;
      case 'cancellation':
        return <X className="w-5 h-5" />;
      case 'report':
        return <AlertTriangle className="w-5 h-5" />;
      case 'account':
        return <Users className="w-5 h-5" />;
      default:
        return <Bell className="w-5 h-5" />;
    }
  };

  const getNotificationIconBg = (type: string) => {
    switch (type) {
      case 'verification':
        return 'bg-green-100';
      case 'cancellation':
        return 'bg-red-100';
      case 'report':
        return 'bg-red-100';
      case 'account':
        return 'bg-yellow-100';
      default:
        return 'bg-blue-100';
    }
  };

  const formatNotificationTime = (date: string) => {
    const now = new Date();
    const notifDate = new Date(date);
    const diffMs = now.getTime() - notifDate.getTime();
    const diffMins = Math.floor(diffMs / 60000);
    const diffHours = Math.floor(diffMs / 3600000);
    const diffDays = Math.floor(diffMs / 86400000);

    if (diffMins < 60) return `${diffMins} menit lalu`;
    if (diffHours < 24) return `${diffHours} jam lalu`;
    return `${diffDays} hari lalu`;
  };

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

          <div className="flex items-center gap-3">
            {/* Search */}

            {/* Notifications */}
            <Popover open={openNotifications} onOpenChange={setOpenNotifications}>
              <PopoverTrigger asChild>
                <button className="relative p-2 hover:bg-muted rounded-lg transition-colors">
                  <Bell className="h-5 w-5 text-muted-foreground" />
                  {unreadCount > 0 && (
                    <span className="absolute -top-1 -right-1 h-5 w-5 flex items-center justify-center bg-red-500 text-white text-xs font-semibold rounded-full">
                      {unreadCount > 9 ? '9+' : unreadCount}
                    </span>
                  )}
                </button>
              </PopoverTrigger>
              <PopoverContent className="w-[420px] p-0" align="end" sideOffset={8}>
                <div className="flex items-center justify-between p-4 border-b bg-muted/30">
                  <div>
                    <h3 className="font-semibold text-base">Notifikasi</h3>
                    {unreadCount > 0 && (
                      <p className="text-xs text-muted-foreground mt-0.5">
                        {unreadCount} notifikasi belum dibaca
                      </p>
                    )}
                  </div>
                  <button 
                    onClick={() => setOpenNotifications(false)}
                    className="p-1.5 hover:bg-muted rounded-md transition-colors"
                  >
                    <X className="h-4 w-4 text-muted-foreground" />
                  </button>
                </div>
                <ScrollArea className="h-[450px]">
                  {notifications.length === 0 ? (
                    <div className="flex flex-col items-center justify-center py-12 px-6 text-center">
                      <div className="w-16 h-16 rounded-full bg-muted flex items-center justify-center mb-3">
                        <Bell className="h-8 w-8 text-muted-foreground" />
                      </div>
                      <p className="text-sm font-medium text-foreground">Tidak ada notifikasi</p>
                      <p className="text-xs text-muted-foreground mt-1">Anda akan menerima notifikasi di sini</p>
                    </div>
                  ) : (
                    <div className="divide-y">
                      {notifications.map((notif) => (
                        <div
                          key={notif.id}
                          className={`p-4 hover:bg-muted/50 cursor-pointer transition-all ${
                            !notif.is_read ? 'bg-blue-50/50 dark:bg-blue-950/20 border-l-2 border-l-blue-500' : ''
                          }`}
                          onClick={() => {
                            if (!notif.is_read) markAsRead(notif.id);
                            if (notif.action_url) {
                              navigate(notif.action_url);
                              setOpenNotifications(false);
                            }
                          }}
                        >
                          <div className="flex gap-3">
                            <div className={`flex-shrink-0 w-10 h-10 rounded-full flex items-center justify-center ${
                              getNotificationIconBg(notif.type)
                            }`}>
                              {getNotificationIcon(notif.type)}
                            </div>
                            <div className="flex-1 min-w-0">
                              <div className="flex items-start justify-between gap-2 mb-1">
                                <h4 className={`font-medium text-sm ${!notif.is_read ? 'text-foreground' : 'text-foreground/80'}`}>
                                  {notif.title}
                                </h4>
                                {!notif.is_read && (
                                  <span className="flex-shrink-0 w-2 h-2 bg-blue-500 rounded-full mt-1.5"></span>
                                )}
                              </div>
                              <p className="text-sm text-muted-foreground leading-snug mb-2">
                                {notif.message}
                              </p>
                              <span className="text-xs text-muted-foreground/70">
                                {formatNotificationTime(notif.created_at)}
                              </span>
                            </div>
                          </div>
                        </div>
                      ))}
                    </div>
                  )}
                </ScrollArea>
              </PopoverContent>
            </Popover>

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
