import { useState } from "react";
import { Loader2 } from "lucide-react";
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from "@/components/ui/alert-dialog";

interface LogoutConfirmPopupProps {
  isOpen: boolean;
  onClose: () => void;
  onConfirm: () => void;
}

const LogoutConfirmPopup = ({ isOpen, onClose, onConfirm }: LogoutConfirmPopupProps) => {
  const [isLoading, setIsLoading] = useState(false);

  const handleConfirm = async () => {
    setIsLoading(true);
    // Simulate logout process
    await new Promise((resolve) => setTimeout(resolve, 1500));
    setIsLoading(false);
    onConfirm();
  };

  const handleClose = () => {
    if (!isLoading) {
      onClose();
    }
  };

  return (
    <AlertDialog open={isOpen} onOpenChange={handleClose}>
      <AlertDialogContent className="max-w-md">
        <AlertDialogHeader>
          <AlertDialogTitle className="text-center text-lg font-semibold">
            {isLoading ? "Sedang Logout..." : "Konfirmasi Logout"}
          </AlertDialogTitle>
          <AlertDialogDescription className="text-center text-muted-foreground">
            {isLoading 
              ? "Mohon tunggu, sedang memproses logout Anda." 
              : "Apakah Anda yakin ingin keluar dari akun ini?"}
          </AlertDialogDescription>
        </AlertDialogHeader>
        
        {isLoading ? (
          <div className="flex justify-center py-4">
            <Loader2 className="h-10 w-10 animate-spin text-primary" />
          </div>
        ) : (
          <AlertDialogFooter className="flex gap-3 sm:justify-center">
            <AlertDialogCancel 
              onClick={handleClose}
              className="flex-1 border-primary text-primary hover:bg-primary/10"
            >
              Batal
            </AlertDialogCancel>
            <AlertDialogAction 
              onClick={handleConfirm}
              className="flex-1 bg-primary hover:bg-primary/90"
            >
              Keluar
            </AlertDialogAction>
          </AlertDialogFooter>
        )}
      </AlertDialogContent>
    </AlertDialog>
  );
};

export default LogoutConfirmPopup;
