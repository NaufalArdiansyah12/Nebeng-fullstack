import { Search, Bell, X, User, LogOut } from "lucide-react";
import { Input } from "@/components/ui/input";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import {
  Popover,
  PopoverContent,
  PopoverTrigger,
} from "@/components/ui/popover";
import { useNavigate } from "react-router-dom";
import { useState } from "react";
import { useAdmin } from "@/contexts/AdminContext";
import { useNotifications } from "@/hooks/useNotifications";

interface DashboardHeaderProps {
  pageTitle?: string;
  showWelcome?: boolean;
}

type NotifFilter = "all" | "laporan" | "mitra" | "customer";

const DashboardHeader = ({ pageTitle = "Dashboard", showWelcome = false }: DashboardHeaderProps) => {
  const navigate = useNavigate();
  const [notifOpen, setNotifOpen] = useState(false);
  const [notifFilter, setNotifFilter] = useState<NotifFilter>("all");
  const { profile } = useAdmin();
  const { notifications, unreadCount } = useNotifications();

  const filteredNotifications = notifFilter === "all" 
    ? notifications 
    : notifications.filter((n) => n.type === notifFilter);

  // Count notifications per category
  const notifCounts = {
    all: notifications.length,
    laporan: notifications.filter((n) => n.type === "laporan").length,
    mitra: notifications.filter((n) => n.type === "mitra").length,
    customer: notifications.filter((n) => n.type === "customer").length,
  };

  const getInitials = (name: string) => {
    return name
      .split(" ")
      .map((n) => n[0])
      .join("")
      .toUpperCase()
      .slice(0, 2);
  };

  // Get display name (first two words)
  const displayName = profile.namaLengkap.split(" ").slice(0, 2).join(" ");

  return (
    <header className="h-16 bg-background border-b flex items-center justify-between px-6">
      {/* Page Title */}
      <h1 className="text-xl font-semibold text-foreground">
        {showWelcome ? `Selamat Datang, ${displayName} 👋` : pageTitle}
      </h1>

      {/* Right Section */}
      <div className="flex items-center gap-4">
        {/* Search */}
        <div className="relative">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-muted-foreground" size={18} />
          <Input
            placeholder="Search"
            className="w-64 pl-10 h-10 bg-muted/50 border-border"
          />
        </div>

        {/* Notifications */}
        <Popover open={notifOpen} onOpenChange={setNotifOpen}>
          <PopoverTrigger asChild>
            <button className="relative p-2 text-muted-foreground hover:text-foreground transition-colors">
              <Bell size={20} />
              {unreadCount > 0 && (
                <span className="absolute -top-1 -right-1 min-w-[18px] h-[18px] bg-red-500 rounded-full flex items-center justify-center text-[10px] text-white font-medium">
                  {unreadCount > 9 ? "9+" : unreadCount}
                </span>
              )}
            </button>
          </PopoverTrigger>
          <PopoverContent align="end" className="w-96 p-0">
            {/* Header */}
            <div className="flex items-center justify-between p-4 border-b">
              <h3 className="text-lg font-semibold">Notifikasi ({unreadCount})</h3>
              <button
                onClick={() => setNotifOpen(false)}
                className="text-muted-foreground hover:text-foreground transition-colors"
              >
                <X size={20} />
              </button>
            </div>

            {/* Filter Tabs */}
            <div className="flex gap-1 p-2 border-b bg-muted/30">
              {[
                { key: "all", label: "Semua" },
                { key: "laporan", label: "Laporan" },
                { key: "mitra", label: "Mitra" },
                { key: "customer", label: "Customer" },
              ].map((filter) => {
                const count = notifCounts[filter.key as NotifFilter];
                return (
                  <button
                    key={filter.key}
                    onClick={() => setNotifFilter(filter.key as NotifFilter)}
                    className={`px-2.5 py-1.5 text-xs font-medium rounded-md transition-colors flex items-center gap-1.5 ${
                      notifFilter === filter.key
                        ? "bg-primary text-primary-foreground"
                        : "text-muted-foreground hover:bg-muted hover:text-foreground"
                    }`}
                  >
                    {filter.label}
                    {count > 0 && (
                      <span
                        className={`min-w-[18px] h-[18px] rounded-full flex items-center justify-center text-[10px] font-semibold ${
                          notifFilter === filter.key
                            ? "bg-primary-foreground/20 text-primary-foreground"
                            : "bg-muted-foreground/20 text-muted-foreground"
                        }`}
                      >
                        {count}
                      </span>
                    )}
                  </button>
                );
              })}
            </div>

            {/* Notification List */}
            <div className="max-h-72 overflow-y-auto">
              {filteredNotifications.length === 0 ? (
                <div className="p-4 text-center text-muted-foreground">
                  Tidak ada notifikasi
                </div>
              ) : (
                filteredNotifications.map((notif) => (
                  <div
                    key={notif.id}
                    onClick={() => {
                      if (notif.link) {
                        navigate(notif.link);
                        setNotifOpen(false);
                      }
                    }}
                    className="flex items-start gap-3 p-4 border-b last:border-b-0 hover:bg-muted/50 transition-colors cursor-pointer"
                  >
                    <div
                      className={`w-10 h-10 rounded-full ${notif.bgColor} flex items-center justify-center flex-shrink-0`}
                    >
                      <notif.icon size={20} className={notif.iconColor} />
                    </div>
                    <div className="flex-1 min-w-0">
                      <p className="font-medium text-sm text-foreground">
                        {notif.title}
                      </p>
                      <p className="text-xs text-muted-foreground mt-0.5">
                        {notif.description}
                      </p>
                    </div>
                    <span className="text-xs text-muted-foreground whitespace-nowrap">
                      {notif.time}
                    </span>
                  </div>
                ))
              )}
            </div>
          </PopoverContent>
        </Popover>

        {/* User Menu */}
        <DropdownMenu>
          <DropdownMenuTrigger asChild>
            <button className="flex items-center gap-2 hover:opacity-80 transition-opacity">
              <Avatar className="h-9 w-9">
                <AvatarImage src={profile.foto} />
                <AvatarFallback className="bg-primary text-primary-foreground text-sm">
                  {getInitials(profile.namaLengkap)}
                </AvatarFallback>
              </Avatar>
              <span className="text-sm font-medium text-foreground">{displayName}</span>
            </button>
          </DropdownMenuTrigger>
          <DropdownMenuContent align="end" className="w-44 p-2 bg-background shadow-lg border rounded-lg">
            <DropdownMenuItem 
              onClick={() => navigate("/dashboard/pengaturan")}
              className="flex items-center justify-between py-3 px-4 cursor-pointer"
            >
              <span>Pengaturan</span>
              <User size={18} className="text-muted-foreground" />
            </DropdownMenuItem>
            <DropdownMenuItem 
              onClick={() => navigate("/")} 
              className="flex items-center justify-between py-3 px-4 cursor-pointer"
            >
              <span>Log out</span>
              <LogOut size={18} className="text-muted-foreground" />
            </DropdownMenuItem>
          </DropdownMenuContent>
        </DropdownMenu>
      </div>
    </header>
  );
};

export default DashboardHeader;
