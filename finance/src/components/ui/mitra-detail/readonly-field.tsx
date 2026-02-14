import { Calendar, ChevronDown } from "lucide-react";

interface ReadOnlyFieldProps {
  label: string;
  value: string;
  type?: "text" | "date" | "select";
}

export function ReadOnlyField({ label, value, type = "text" }: ReadOnlyFieldProps) {
  return (
    <div className="flex flex-col gap-1">
      <label className="text-sm text-gray-600">{label}</label>
      <div className="flex items-center justify-between px-4 py-2.5 rounded-lg bg-gray-100 border border-transparent text-sm text-gray-700 min-h-[42px]">
        <span>{value || "-"}</span>
        {type === "date" && <Calendar className="h-4 w-4 text-gray-400 flex-shrink-0" />}
        {type === "select" && <ChevronDown className="h-4 w-4 text-gray-400 flex-shrink-0" />}
      </div>
    </div>
  );
}
