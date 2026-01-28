import {
  Dialog,
  DialogContent,
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Save, FileCheck, CheckCircle } from "lucide-react";

interface SavePengaturanPopupProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  onConfirm: () => void;
  onCancel: () => void;
  showSuccess: boolean;
  onSuccessClose: () => void;
}

const SavePengaturanPopup = ({
  open,
  onOpenChange,
  onConfirm,
  onCancel,
  showSuccess,
  onSuccessClose,
}: SavePengaturanPopupProps) => {
  if (showSuccess) {
    return (
      <Dialog open={open} onOpenChange={onOpenChange}>
        <DialogContent className="sm:max-w-md text-center p-8">
          <div className="space-y-6">
            <h2 className="text-xl font-bold text-foreground">
              Data terbaru berhasil disimpan
            </h2>
            
            <div className="flex justify-center">
              <div className="relative">
                <div className="bg-primary/10 rounded-lg p-4">
                  <div className="flex items-center gap-2">
                    <div className="bg-primary rounded-full p-2">
                      <svg className="h-6 w-6 text-primary-foreground" fill="currentColor" viewBox="0 0 24 24">
                        <path d="M12 12c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm0 2c-2.67 0-8 1.34-8 4v2h16v-2c0-2.66-5.33-4-8-4z"/>
                      </svg>
                    </div>
                    <div className="space-y-1">
                      <div className="h-2 w-16 bg-muted rounded"></div>
                      <div className="h-2 w-12 bg-muted rounded"></div>
                      <div className="h-2 w-14 bg-muted rounded"></div>
                    </div>
                  </div>
                </div>
                <div className="absolute -top-1 -right-1 bg-green-500 rounded-full p-1">
                  <CheckCircle className="h-4 w-4 text-white" />
                </div>
              </div>
            </div>

            <Button 
              onClick={onSuccessClose}
              className="px-8"
            >
              Oke
            </Button>
          </div>
        </DialogContent>
      </Dialog>
    );
  }

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-md text-center p-8 border-2 border-primary">
        <div className="space-y-6">
          <h2 className="text-xl font-bold text-foreground">
            Apakah yakin ingin menyimpan<br />perubahan?
          </h2>
          
          <div className="flex justify-center">
            <div className="bg-primary/10 rounded-full p-4">
              <Save className="h-10 w-10 text-primary" />
            </div>
          </div>

          <div className="space-y-3">
            <Button 
              variant="outline" 
              className="w-full"
              onClick={onCancel}
            >
              Batal
            </Button>
            <Button 
              className="w-full"
              onClick={onConfirm}
            >
              Simpan
            </Button>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  );
};

export default SavePengaturanPopup;
