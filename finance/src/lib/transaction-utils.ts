export const mapStatus = (status: string) => {
  const s = (status ?? "").toString().toLowerCase().replace(/_/g, " ").trim();
  if (!s) return "-";
  if (s.includes("sampai") && s.includes("tujuan")) return "SAMPAI TUJUAN";
  switch (s) {
    case "pending":
      return "PROSES";
    case "paid":
      return "SELESAI";
    case "cancelled":
      return "BATAL";
    default:
      return s.toUpperCase();
  }
};

export const getStatusColor = (status: string) => {
  const s = (status ?? "").toString().toLowerCase().replace(/_/g, " ").trim();
  if (!s) return "bg-gray-500 hover:bg-gray-600";
  if (s.includes("sampai") && s.includes("tujuan")) return "bg-green-600 hover:bg-green-700";
  // Accept already-mapped labels like 'PROSES', 'SELESAI', 'BATAL'
  if (s === 'proses') return "bg-yellow-500 hover:bg-yellow-600";
  if (s === 'selesai') return "bg-green-500 hover:bg-green-600";
  if (s === 'batal') return "bg-red-500 hover:bg-red-600";
  switch (s) {
    case "pending":
      return "bg-yellow-500 hover:bg-yellow-600";
    case "paid":
      return "bg-green-500 hover:bg-green-600";
    case "cancelled":
      return "bg-red-500 hover:bg-red-600";
    default:
      return "bg-gray-500 hover:bg-gray-600";
  }
};

export const formatDate = (dateString: string) => {
  const date = new Date(dateString);
  const days = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'];
  
  const dayName = days[date.getDay()];
  const day = date.getDate();
  const month = months[date.getMonth()];
  const year = date.getFullYear();
  
  return `${dayName}, ${day} ${month} ${year}`;
};

export const generateOrderNumber = (bookingNumber: string) => {
  const numbers = bookingNumber.replace(/\D/g, '');
  return `000${numbers}`.slice(-12);
};

export const getServiceType = (jenis: string, serviceTypeRaw?: string) => {
  if (serviceTypeRaw) {
    if (serviceTypeRaw === 'barang') {
      return 'Hanya Titip Barang';
    } else if (serviceTypeRaw === 'tebengan') {
      return 'Hanya Tebengan';
    } else if (serviceTypeRaw === 'both') {
      return 'Tebengan dan Titip Barang';
    }
  }
  
  const typeMap: Record<string, string> = {
    "Nebeng Motor": "Hanya Tebengan",
    "Nebeng Mobil": "Hanya Tebengan",
    "Nebeng Barang": "Tebengan dan Titip Barang",
    "Titip Barang": "Hanya Titip Barang"
  };
  return typeMap[jenis] || "Hanya Tebengan";
};

export const renderPageNumbers = (currentPage: number, totalPages: number) => {
  const pages: (number | string)[] = [];
  const maxVisible = 5;
  
  if (totalPages <= maxVisible) {
    for (let i = 1; i <= totalPages; i++) {
      pages.push(i);
    }
  } else {
    if (currentPage <= 3) {
      pages.push(1, 2, 3, '...', totalPages);
    } else if (currentPage >= totalPages - 2) {
      pages.push(1, '...', totalPages - 2, totalPages - 1, totalPages);
    } else {
      pages.push(1, '...', currentPage, '...', totalPages);
    }
  }
  
  return pages;
};
