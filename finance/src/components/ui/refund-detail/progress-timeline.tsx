import { CheckCircle } from "lucide-react";

interface ProgressStep {
  title: string;
  description: string;
  date: string | null;
  status: "completed" | "pending" | "rejected";
}

interface ProgressTimelineProps {
  progress: ProgressStep[];
  formatDate: (dateString: string | null) => string;
}

export const ProgressTimeline = ({ progress, formatDate }: ProgressTimelineProps) => {
  return (
    <div className="bg-background border border-border rounded-xl p-6 shadow-sm">
      <h3 className="font-semibold text-base mb-6 pb-3 border-b">Progress Refund</h3>
      <div className="space-y-6">
        {progress.map((step, index) => (
          <div key={index} className="flex gap-4">
            <div className="flex flex-col items-center">
              <div
                className={`w-10 h-10 rounded-full flex items-center justify-center ${
                  step.status === "completed"
                    ? "bg-primary text-white"
                    : step.status === "rejected"
                    ? "bg-red-500 text-white"
                    : "bg-gray-200 text-gray-400"
                }`}
              >
                <CheckCircle className="w-5 h-5" />
              </div>
              {index < progress.length - 1 && (
                <div
                  className={`w-0.5 h-16 mt-2 ${
                    step.status === "completed" ? "bg-primary" : "bg-gray-200"
                  }`}
                ></div>
              )}
            </div>
            <div className="flex-1 pb-6">
              <p
                className={`font-semibold text-sm mb-1 ${
                  step.status === "completed"
                    ? "text-primary"
                    : step.status === "rejected"
                    ? "text-red-600"
                    : "text-gray-400"
                }`}
              >
                {step.title}
              </p>
              <p className="text-xs text-muted-foreground mb-2">
                {step.description}
              </p>
              {step.date && (
                <p className="text-xs text-muted-foreground font-medium">
                  {formatDate(step.date)}
                </p>
              )}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};
