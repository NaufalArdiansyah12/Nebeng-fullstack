import {
  Dialog,
  DialogContent,
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { User, FileText, Check } from "lucide-react";

interface SaveLaporanPopupProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
}

const SaveLaporanPopup = ({ open, onOpenChange }: SaveLaporanPopupProps) => {
  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-md p-8">
        <div className="flex flex-col items-center text-center">
          <h2 className="text-xl font-semibold text-foreground mb-8">
            Data terbaru berhasil disimpan
          </h2>
          
          {/* Illustration */}
          <div className="mb-8 relative flex items-center justify-center">
            <div className="flex items-end gap-1">
              {/* User icon */}
              <div className="w-12 h-14 bg-blue-500 rounded-lg flex items-center justify-center">
                <User className="w-8 h-8 text-white" />
              </div>
              {/* Document icon */}
              <div className="w-10 h-12 bg-green-100 rounded-lg flex items-center justify-center relative">
                <FileText className="w-6 h-6 text-green-600" />
                <div className="absolute -top-1 -right-1 w-5 h-5 bg-green-500 rounded-full flex items-center justify-center">
                  <Check className="w-3 h-3 text-white" strokeWidth={3} />
                </div>
              </div>
            </div>
            {/* Large checkmark */}
            <div className="absolute -top-2 -right-4 w-8 h-8 bg-green-500 rounded-full flex items-center justify-center">
              <Check className="w-5 h-5 text-white" strokeWidth={3} />
            </div>
          </div>
          
          <Button 
            className="w-32 bg-[#1e3a5f] hover:bg-[#152a45] text-white"
            onClick={() => onOpenChange(false)}
          >
            Oke
          </Button>
        </div>
      </DialogContent>
    </Dialog>
  );
};

export default SaveLaporanPopup;
