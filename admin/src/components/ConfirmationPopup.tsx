import { Dialog, DialogContent } from "@/components/ui/dialog";
import { Mail, ShieldCheck } from "lucide-react";

interface ConfirmationPopupProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  type: "email-sent" | "password-changed";
  email?: string;
}

const ConfirmationPopup = ({ open, onOpenChange, type, email }: ConfirmationPopupProps) => {
  const maskEmail = (email: string) => {
    const [localPart, domain] = email.split("@");
    if (localPart.length <= 2) return email;
    const masked = localPart[0] + "*".repeat(localPart.length - 2) + localPart[localPart.length - 1];
    return `${masked}@${domain}`;
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-md p-0 border-0 overflow-hidden">
        {/* Top accent border */}
        <div className="h-1.5 bg-primary" />
        
        <div className="p-8 flex flex-col items-center text-center">
          {type === "email-sent" ? (
            <>
              {/* Email icon */}
              <div className="mb-6">
                <div className="relative">
                  <Mail className="w-16 h-16 text-muted-foreground" strokeWidth={1.5} />
                  <div className="absolute -top-1 -right-1 w-6 h-6 rounded-full bg-primary flex items-center justify-center">
                    <ShieldCheck className="w-4 h-4 text-primary-foreground" />
                  </div>
                </div>
              </div>
              
              {/* Text */}
              <p className="text-foreground text-sm leading-relaxed">
                Kami mengirimkan link verifikasi ke email{" "}
                <span className="font-semibold">{email ? maskEmail(email) : "F******3@gmail.com"}</span>
              </p>
            </>
          ) : (
            <>
              {/* Lock with refresh icon */}
              <div className="mb-6">
                <div className="relative w-16 h-16 flex items-center justify-center">
                  <svg
                    viewBox="0 0 64 64"
                    fill="none"
                    xmlns="http://www.w3.org/2000/svg"
                    className="w-16 h-16 text-muted-foreground"
                  >
                    {/* Circular arrows */}
                    <path
                      d="M32 8C18.745 8 8 18.745 8 32s10.745 24 24 24"
                      stroke="currentColor"
                      strokeWidth="2"
                      strokeLinecap="round"
                      fill="none"
                    />
                    <path
                      d="M32 56c13.255 0 24-10.745 24-24S45.255 8 32 8"
                      stroke="currentColor"
                      strokeWidth="2"
                      strokeLinecap="round"
                      fill="none"
                    />
                    {/* Arrow heads */}
                    <path
                      d="M28 4l4 4-4 4"
                      stroke="currentColor"
                      strokeWidth="2"
                      strokeLinecap="round"
                      strokeLinejoin="round"
                    />
                    <path
                      d="M36 52l-4 4 4 4"
                      stroke="currentColor"
                      strokeWidth="2"
                      strokeLinecap="round"
                      strokeLinejoin="round"
                    />
                    {/* Lock body */}
                    <rect
                      x="22"
                      y="28"
                      width="20"
                      height="16"
                      rx="2"
                      stroke="currentColor"
                      strokeWidth="2"
                      fill="none"
                    />
                    {/* Lock shackle */}
                    <path
                      d="M26 28v-4a6 6 0 1112 0v4"
                      stroke="currentColor"
                      strokeWidth="2"
                      strokeLinecap="round"
                      fill="none"
                    />
                    {/* Lock keyhole */}
                    <circle cx="32" cy="36" r="2" fill="currentColor" />
                  </svg>
                </div>
              </div>
              
              {/* Text */}
              <p className="text-foreground text-sm leading-relaxed">
                Kata sandi akun Anda baru saja diubah. Jika ini bukan Anda, segera hubungi kami.
              </p>
            </>
          )}
        </div>
      </DialogContent>
    </Dialog>
  );
};

export default ConfirmationPopup;
