import { useMemo } from "react";
import { useLaporan } from "@/contexts/LaporanContext";
import { useMitra } from "@/contexts/MitraContext";
import { useCustomer } from "@/contexts/CustomerContext";
import { UserCheck, AlertTriangle, UserPlus, LucideIcon } from "lucide-react";

export interface NotificationData {
  id: string;
  title: string;
  description: string;
  time: string;
  type: "laporan" | "mitra" | "customer";
  icon: LucideIcon;
  bgColor: string;
  iconColor: string;
  link?: string;
}

const getRelativeTime = (date: Date): string => {
  const now = new Date();
  const diffMs = now.getTime() - date.getTime();
  const diffHours = Math.floor(diffMs / (1000 * 60 * 60));
  const diffDays = Math.floor(diffMs / (1000 * 60 * 60 * 24));

  if (diffHours < 1) return "Baru saja";
  if (diffHours < 24) return `${diffHours} jam lalu`;
  if (diffDays === 1) return "1 hari lalu";
  if (diffDays < 30) return `${diffDays} hari lalu`;
  return `${Math.floor(diffDays / 30)} bulan lalu`;
};

export const useNotifications = () => {
  const { laporanList } = useLaporan();
  const { mitraList } = useMitra();
  const { customerList } = useCustomer();

  const notifications = useMemo(() => {
    const notifs: NotificationData[] = [];

    // Add safety check for laporanList
    if (Array.isArray(laporanList) && laporanList.length > 0) {
      laporanList.slice(0, 5).forEach((laporan) => {
        if (laporan && laporan.id) {
          notifs.push({
            id: `laporan-${laporan.id}`,
            title: `${laporan.namaCustomer || "Customer"} melaporkan ${laporan.namaMitra || "Mitra"}`,
            description: laporan.laporan && laporan.laporan.length > 50 
              ? laporan.laporan.substring(0, 50) + "..." 
              : (laporan.laporan || ""),
            time: getRelativeTime(laporan.tanggal),
            type: "laporan",
            icon: AlertTriangle,
            bgColor: "bg-orange-100",
            iconColor: "text-orange-500",
            link: `/dashboard/laporan/${laporan.id}`,
          });
        }
      });
    }

    // Add safety check for mitraList
    if (Array.isArray(mitraList) && mitraList.length > 0) {
      mitraList
        .filter((mitra) => mitra && mitra.status === "PENGAJUAN")
        .slice(0, 5)
        .forEach((mitra) => {
          if (mitra && mitra.id) {
            notifs.push({
              id: `mitra-${mitra.id}`,
              title: `${mitra.nama || "Mitra"} mendaftar sebagai mitra`,
              description: `Layanan ${mitra.layanan || "Unknown"} - Menunggu verifikasi`,
              time: getRelativeTime(mitra.tanggal),
              type: "mitra",
              icon: UserCheck,
              bgColor: "bg-green-100",
              iconColor: "text-green-600",
              link: `/dashboard/verifikasi-mitra/${mitra.id}`,
            });
          }
        });
    }

    // Add safety check for customerList
    if (Array.isArray(customerList) && customerList.length > 0) {
      customerList
        .filter((customer) => customer && customer.status === "PENGAJUAN")
        .slice(0, 5)
        .forEach((customer) => {
          if (customer && customer.id) {
            notifs.push({
              id: `customer-${customer.id}`,
              title: `${customer.nama || "Customer"} mendaftar sebagai customer`,
              description: "Menunggu verifikasi dari admin",
              time: getRelativeTime(customer.tanggal),
              type: "customer",
              icon: UserPlus,
              bgColor: "bg-blue-100",
              iconColor: "text-blue-600",
              link: `/dashboard/verifikasi-customer/${customer.id}`,
            });
          }
        });
    }

    return notifs.slice(0, 10);
  }, [laporanList, mitraList, customerList]);

  const unreadCount = notifications.length;

  return { notifications, unreadCount };
};