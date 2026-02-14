// Withdrawal status utilities
export const statusColors: Record<string, string> = {
  pending: "bg-yellow-100 text-yellow-800 border-yellow-200",
  verifying: "bg-blue-100 text-blue-800 border-blue-200",
  approved: "bg-green-100 text-green-800 border-green-200",
  processing: "bg-purple-100 text-purple-800 border-purple-200",
  transferring: "bg-indigo-100 text-indigo-800 border-indigo-200",
  completed: "bg-green-100 text-green-800 border-green-200",
  rejected: "bg-red-100 text-red-800 border-red-200",
};

export const statusLabels: Record<string, string> = {
  pending: "Menunggu",
  verifying: "Verifikasi",
  approved: "Disetujui",
  processing: "Diproses",
  transferring: "Dikirim",
  completed: "Selesai",
  rejected: "Ditolak",
};

// Format currency to Indonesian Rupiah
export const formatCurrency = (amount: number) => {
  return new Intl.NumberFormat("id-ID", {
    style: "currency",
    currency: "IDR",
    minimumFractionDigits: 0,
  }).format(amount);
};

// Format date to Indonesian format  
export const formatDate = (dateString: string | null) => {
  if (!dateString) return "-";
  return new Date(dateString).toLocaleDateString("id-ID", {
    day: "2-digit",
    month: "long",
    year: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  });
};

// Format date for list view (shorter format)
export const formatDateShort = (dateString: string) => {
  return new Date(dateString).toLocaleDateString("id-ID", {
    day: "2-digit",
    month: "short",
    year: "numeric",
  });
};
