import { Copy } from "lucide-react";
import { Button } from "../button";
import { toast } from "sonner";

interface TransactionHeaderProps {
  bookingNumber: string;
}

export function TransactionHeader({ bookingNumber }: TransactionHeaderProps) {
  const copyToClipboard = (text: string) => {
    navigator.clipboard.writeText(text);
    toast.success("ID berhasil disalin");
  };

  return (
    <div className="bg-background rounded-xl p-4 border mb-6 flex items-center justify-between">
      <div>
        <p className="text-sm text-muted-foreground mb-1">ID Pesanan :</p>
        <p className="text-lg font-semibold">{bookingNumber}</p>
      </div>
      <Button
        variant="ghost"
        size="icon"
        onClick={() => copyToClipboard(bookingNumber)}
      >
        <Copy className="h-5 w-5" />
      </Button>
    </div>
  );
}
