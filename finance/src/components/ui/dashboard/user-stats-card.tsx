import { Users, UsersRound, MoreVertical } from "lucide-react";

interface UserStatsCardProps {
  type: "mitra" | "customer";
  count: number;
}

export function UserStatsCard({ type, count }: UserStatsCardProps) {
  const Icon = type === "mitra" ? UsersRound : Users;
  const label = type === "mitra" ? "Total Pengguna Mitra" : "Total Pengguna Costumer";

  return (
    <div className="bg-background rounded-xl p-5 border relative">
      <div className="flex gap-4 items-start">
        <div className="bg-primary/10 p-3 rounded-lg">
          <Icon className="h-6 w-6 text-primary" />
        </div>
        <div className="flex-1">
          <p className="text-3xl font-bold">{count.toLocaleString()}</p>
          <p className="text-sm text-muted-foreground">{label}</p>
        </div>
        <button className="text-muted-foreground hover:text-foreground">
          <MoreVertical className="h-5 w-5" />
        </button>
      </div>
    </div>
  );
}
