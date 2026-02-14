import { Input } from "@/components/ui/input";

interface UserInfoCardProps {
  userName: string;
  userEmail: string;
  userPhone: string;
  kodeReferral: string;
  type: "mitra" | "posmitra";
}

export const UserInfoCard = ({ userName, userEmail, userPhone, kodeReferral, type }: UserInfoCardProps) => {
  return (
    <div className="bg-background border border-border rounded-xl p-6 shadow-sm">
      <h3 className="font-semibold text-base mb-5 pb-3 border-b">
        Informasi {type === "posmitra" ? "Pos Mitra" : "Mitra"}
      </h3>
      <div className="grid grid-cols-2 gap-x-6 gap-y-4">
        <div>
          <label className="text-xs font-medium text-muted-foreground mb-2 block uppercase tracking-wide">
            Nama
          </label>
          <Input disabled value={userName} className="bg-muted border-0 font-medium" />
        </div>
        <div>
          <label className="text-xs font-medium text-muted-foreground mb-2 block uppercase tracking-wide">
            Email
          </label>
          <Input disabled value={userEmail} className="bg-muted border-0 font-medium" />
        </div>
        <div>
          <label className="text-xs font-medium text-muted-foreground mb-2 block uppercase tracking-wide">
            No. Telepon
          </label>
          <Input disabled value={userPhone} className="bg-muted border-0 font-medium" />
        </div>
        <div>
          <label className="text-xs font-medium text-muted-foreground mb-2 block uppercase tracking-wide">
            Kode Referral
          </label>
          <Input disabled value={kodeReferral} className="bg-muted border-0 font-medium" />
        </div>
      </div>
    </div>
  );
};
