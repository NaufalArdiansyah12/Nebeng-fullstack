import { Dialog, DialogContent } from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Lock, UserCheck } from "lucide-react";

interface BlockMitraPopupProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  onConfirm: () => void;
  type: "confirm" | "success";
}

const BlockMitraPopup = ({ open, onOpenChange, onConfirm, type }: BlockMitraPopupProps) => {
  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-md p-0 border-0 overflow-hidden">
        {/* Top accent border */}
        <div className="h-1.5 bg-[#6B5B7A]" />
        
        <div className="p-8 flex flex-col items-center text-center">
          {type === "confirm" ? (
            <>
              {/* Title */}
              <h2 className="text-xl font-bold text-foreground mb-6">
                Apakah Anda Yakin Ingin<br />Memblock Akun Ini
              </h2>
              
              {/* Lock icon */}
              <div className="mb-8">
                <div className="relative w-20 h-20 flex items-center justify-center">
                  <svg
                    viewBox="0 0 64 64"
                    fill="none"
                    xmlns="http://www.w3.org/2000/svg"
                    className="w-20 h-20"
                  >
                    {/* Lock body */}
                    <rect
                      x="14"
                      y="28"
                      width="36"
                      height="28"
                      rx="4"
                      fill="#EF4444"
                    />
                    {/* Lock shackle */}
                    <path
                      d="M20 28v-8a12 12 0 1124 0v8"
                      stroke="#EF4444"
                      strokeWidth="4"
                      strokeLinecap="round"
                      fill="none"
                    />
                    {/* Keyhole circle */}
                    <circle cx="32" cy="42" r="5" fill="white" />
                    {/* Keyhole line */}
                    <rect x="30" y="42" width="4" height="8" rx="2" fill="white" />
                  </svg>
                </div>
              </div>
              
              {/* Buttons */}
              <div className="flex gap-4">
                <Button 
                  variant="outline" 
                  className="px-8 bg-gray-200 hover:bg-gray-300 text-gray-700 border-0"
                  onClick={() => onOpenChange(false)}
                >
                  Kembali
                </Button>
                <Button 
                  className="px-8 bg-[#B91C1C] hover:bg-[#991B1B] text-white"
                  onClick={onConfirm}
                >
                  Yakin
                </Button>
              </div>
            </>
          ) : (
            <>
              {/* Title */}
              <h2 className="text-xl font-bold text-foreground mb-6">
                Block Akun Berhasil
              </h2>
              
              {/* Success icon - User card with checkmark */}
              <div className="mb-8">
                <div className="relative">
                  <div className="w-20 h-16 bg-gray-100 rounded-lg flex items-center p-3 gap-2">
                    <div className="w-8 h-8 bg-[#1e3a5f] rounded-full flex items-center justify-center">
                      <svg viewBox="0 0 24 24" className="w-5 h-5 text-white" fill="currentColor">
                        <path d="M12 12c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm0 2c-2.67 0-8 1.34-8 4v2h16v-2c0-2.66-5.33-4-8-4z"/>
                      </svg>
                    </div>
                    <div className="flex flex-col gap-1">
                      <div className="w-8 h-1.5 bg-gray-300 rounded"></div>
                      <div className="w-6 h-1.5 bg-gray-300 rounded"></div>
                      <div className="w-7 h-1.5 bg-gray-300 rounded"></div>
                    </div>
                  </div>
                  {/* Checkmark badge */}
                  <div className="absolute -top-2 -right-2 w-8 h-8 bg-green-500 rounded-full flex items-center justify-center">
                    <svg viewBox="0 0 24 24" className="w-5 h-5 text-white" fill="none" stroke="currentColor" strokeWidth="3">
                      <path d="M5 12l5 5L19 7" strokeLinecap="round" strokeLinejoin="round"/>
                    </svg>
                  </div>
                </div>
              </div>
              
              {/* Button */}
              <Button 
                className="px-8 bg-[#1e3a5f] hover:bg-[#152a45] text-white"
                onClick={() => onOpenChange(false)}
              >
                Oke
              </Button>
            </>
          )}
        </div>
      </DialogContent>
    </Dialog>
  );
};

export default BlockMitraPopup;
