import { Copy } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { toast } from "sonner";

interface ProfileHeaderProps {
  name: string;
  profilePhoto: string | null;
  referralCode: string | null;
}

export const ProfileHeader = ({ name, profilePhoto, referralCode }: ProfileHeaderProps) => {
  const copyToClipboard = (text: string) => {
    navigator.clipboard.writeText(text);
    toast.success("Kode referral berhasil disalin");
  };

  return (
    <div className="flex items-center justify-between mb-8">
      <div className="flex items-center gap-4">
        <div className="relative">
          <Avatar className="w-16 h-16">
            <AvatarImage 
              src={
                profilePhoto
                  ? `${import.meta.env.VITE_API_URL}${profilePhoto}`
                  : undefined
              }
              alt={name}
            />
            <AvatarFallback className="text-lg font-semibold">
              {name.split(' ').map(n => n[0]).join('').toUpperCase().slice(0, 2)}
            </AvatarFallback>
          </Avatar>
        </div>
        <div>
          <p className="font-semibold text-lg">{name}</p>
          <p className="text-sm text-muted-foreground">Nebeng Motor</p>
        </div>
      </div>

      <div className="text-right">
        <p className="text-xs text-muted-foreground mb-1">KODE REFERRAL</p>
        <div className="flex items-center gap-2">
          <p className="font-semibold text-primary text-lg">
            {referralCode || "-"}
          </p>
          {referralCode && (
            <Button
              variant="ghost"
              size="icon"
              className="h-6 w-6 text-primary hover:text-primary/80"
              onClick={() => copyToClipboard(referralCode)}
            >
              <Copy className="h-4 w-4" />
            </Button>
          )}
        </div>
      </div>
    </div>
  );
};
