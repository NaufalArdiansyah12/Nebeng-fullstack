interface Refund {
  id: number;
  status: "pending" | "approved" | "processing" | "completed" | "rejected";
}

interface StatisticsCardsProps {
  refunds: Refund[];
}

export const StatisticsCards = ({ refunds }: StatisticsCardsProps) => {
  const stats = [
    { label: "Menunggu", status: "pending" as const, count: refunds.filter(r => r.status === "pending").length },
    { label: "Disetujui", status: "approved" as const, count: refunds.filter(r => r.status === "approved").length },
    { label: "Diproses", status: "processing" as const, count: refunds.filter(r => r.status === "processing").length },
    { label: "Selesai", status: "completed" as const, count: refunds.filter(r => r.status === "completed").length },
    { label: "Ditolak", status: "rejected" as const, count: refunds.filter(r => r.status === "rejected").length },
  ];

  return (
    <div className="grid grid-cols-5 gap-3">
      {stats.map((stat) => (
        <div
          key={stat.status}
          className="bg-muted/30 rounded-lg p-3 text-center"
        >
          <p className="text-2xl font-bold">{stat.count}</p>
          <p className="text-xs text-muted-foreground">{stat.label}</p>
        </div>
      ))}
    </div>
  );
};
