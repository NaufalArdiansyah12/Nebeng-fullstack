import { ChevronDown } from "lucide-react";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger
} from "@/components/ui/dropdown-menu";

interface StatusFilterDropdownProps {
  statusFilter: string;
  onStatusChange: (status: string) => void;
}

export const StatusFilterDropdown = ({ statusFilter, onStatusChange }: StatusFilterDropdownProps) => {
  return (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <button className="flex items-center gap-2 text-sm hover:text-foreground transition-colors">
          <span className="text-muted-foreground">Status</span>
          <ChevronDown className="h-4 w-4" />
        </button>
      </DropdownMenuTrigger>
      <DropdownMenuContent align="end" className="w-40">
        {["Semua", "PROSES", "SELESAI", "BATAL"].map((s) => (
          <DropdownMenuItem
            key={s}
            onClick={() => onStatusChange(s)}
            className="cursor-pointer"
          >
            {s}
          </DropdownMenuItem>
        ))}
      </DropdownMenuContent>
    </DropdownMenu>
  );
};
