import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";

interface StatusFilterProps {
  value: string;
  onChange: (value: string) => void;
}

export const StatusFilter = ({ value, onChange }: StatusFilterProps) => {
  return (
    <Select value={value} onValueChange={onChange}>
      <SelectTrigger className="w-40">
        <SelectValue placeholder="Status" />
      </SelectTrigger>
      <SelectContent>
        <SelectItem value="all">Semua Status</SelectItem>
        <SelectItem value="pending">Menunggu</SelectItem>
        <SelectItem value="verifying">Verifikasi</SelectItem>
        <SelectItem value="approved">Disetujui</SelectItem>
        <SelectItem value="processing">Diproses</SelectItem>
        <SelectItem value="completed">Selesai</SelectItem>
        <SelectItem value="rejected">Ditolak</SelectItem>
      </SelectContent>
    </Select>
  );
};
