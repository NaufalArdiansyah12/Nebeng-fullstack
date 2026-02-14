import { Input } from "@/components/ui/input";

interface CustomerInfoCardProps {
  customerName: string;
  customerEmail: string;
  customerPhone: string;
  bookingType: string;
}

export const CustomerInfoCard = ({ 
  customerName, 
  customerEmail, 
  customerPhone, 
  bookingType 
}: CustomerInfoCardProps) => {
  return (
    <div className="bg-background border border-border rounded-xl p-6">
      <h3 className="font-semibold mb-4">Informasi Customer</h3>
      <div className="grid grid-cols-2 gap-4">
        <div>
          <label className="text-xs text-muted-foreground mb-1.5 block">Nama</label>
          <Input disabled value={customerName} className="bg-muted" />
        </div>
        <div>
          <label className="text-xs text-muted-foreground mb-1.5 block">Email</label>
          <Input disabled value={customerEmail} className="bg-muted" />
        </div>
        <div>
          <label className="text-xs text-muted-foreground mb-1.5 block">No. Telepon</label>
          <Input disabled value={customerPhone} className="bg-muted" />
        </div>
        <div>
          <label className="text-xs text-muted-foreground mb-1.5 block">Tipe Booking</label>
          <Input disabled value={bookingType} className="bg-muted capitalize" />
        </div>
      </div>
    </div>
  );
};
