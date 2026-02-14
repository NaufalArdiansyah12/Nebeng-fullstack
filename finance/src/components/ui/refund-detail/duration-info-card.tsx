import { Loader2 } from "lucide-react";

export const DurationInfoCard = () => {
  return (
    <div className="bg-gradient-to-br from-blue-50 to-blue-100 border border-blue-200 rounded-xl p-5 shadow-sm">
      <div className="flex items-start gap-3">
        <div className="bg-blue-600 rounded-full p-2">
          <Loader2 className="w-5 h-5 text-white" />
        </div>
        <div className="flex-1">
          <p className="font-bold text-sm text-blue-900 mb-1">
            Durasi Proses Refund
          </p>
          <p className="text-xs text-blue-800 leading-relaxed">
            Proses refund membutuhkan waktu 3-5 hari kerja setelah disetujui
          </p>
        </div>
      </div>
    </div>
  );
};
