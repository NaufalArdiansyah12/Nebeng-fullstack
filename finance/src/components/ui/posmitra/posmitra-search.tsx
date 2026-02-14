import { Search } from "lucide-react";
import { Input } from "@/components/ui/input";

interface PosMitraSearchProps {
  value: string;
  onChange: (value: string) => void;
}

export const PosMitraSearch = ({ value, onChange }: PosMitraSearchProps) => {
  return (
    <div className="relative w-64">
      <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
      <Input
        placeholder="Search"
        className="pl-9"
        value={value}
        onChange={(e) => onChange(e.target.value)}
      />
    </div>
  );
};
