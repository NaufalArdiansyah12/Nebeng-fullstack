import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";

interface TypeFilterProps {
  value: string;
  onChange: (value: string) => void;
}

export const TypeFilter = ({ value, onChange }: TypeFilterProps) => {
  return (
    <Select value={value} onValueChange={onChange}>
      <SelectTrigger className="w-40">
        <SelectValue placeholder="Tipe" />
      </SelectTrigger>
      <SelectContent>
        <SelectItem value="all">Semua Tipe</SelectItem>
        <SelectItem value="mitra">Mitra</SelectItem>
        <SelectItem value="posmitra">Pos Mitra</SelectItem>
      </SelectContent>
    </Select>
  );
};
