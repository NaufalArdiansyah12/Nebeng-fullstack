interface Statistics {
  total: number;
  pending: number;
  processing: number;
  completed: number;
  rejected: number;
}

interface StatisticsCardsProps {
  statistics: Statistics;
}

export const StatisticsCards = ({ statistics }: StatisticsCardsProps) => {
  return (
    <div className="grid grid-cols-5 gap-4 mb-6">
      <div className="bg-white border border-border rounded-xl p-4">
        <p className="text-xs text-muted-foreground mb-1">Total Pengajuan</p>
        <p className="text-2xl font-bold">{statistics.total}</p>
      </div>
      <div className="bg-white border border-border rounded-xl p-4">
        <p className="text-xs text-muted-foreground mb-1">Menunggu</p>
        <p className="text-2xl font-bold text-yellow-600">{statistics.pending}</p>
      </div>
      <div className="bg-white border border-border rounded-xl p-4">
        <p className="text-xs text-muted-foreground mb-1">Diproses</p>
        <p className="text-2xl font-bold text-purple-600">{statistics.processing}</p>
      </div>
      <div className="bg-white border border-border rounded-xl p-4">
        <p className="text-xs text-muted-foreground mb-1">Selesai</p>
        <p className="text-2xl font-bold text-green-600">{statistics.completed}</p>
      </div>
      <div className="bg-white border border-border rounded-xl p-4">
        <p className="text-xs text-muted-foreground mb-1">Ditolak</p>
        <p className="text-2xl font-bold text-red-600">{statistics.rejected}</p>
      </div>
    </div>
  );
};
