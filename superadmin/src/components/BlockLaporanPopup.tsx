import {
  Dialog,
  DialogContent,
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { RadioGroup, RadioGroupItem } from "@/components/ui/radio-group";
import { Label } from "@/components/ui/label";
import { useState } from "react";

interface BlockLaporanPopupProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  onConfirm: (blockType: "mitra" | "customer") => void;
  type: "confirm" | "success";
  mitraName?: string;
  customerName?: string;
}

const BlockLaporanPopup = ({ 
  open, 
  onOpenChange, 
  onConfirm, 
  type,
  mitraName = "Mitra",
  customerName = "Customer"
}: BlockLaporanPopupProps) => {
  const [selectedType, setSelectedType] = useState<"mitra" | "customer">("mitra");

  if (type === "confirm") {
    return (
      <Dialog open={open} onOpenChange={onOpenChange}>
        <DialogContent className="sm:max-w-md p-8">
          <div className="flex flex-col items-center text-center">
            <h2 className="text-xl font-semibold text-foreground mb-6">
              Pilih Akun Yang Ingin Di Block
            </h2>
            
            {/* Selection */}
            <div className="w-full mb-6">
              <RadioGroup 
                value={selectedType} 
                onValueChange={(value) => setSelectedType(value as "mitra" | "customer")}
                className="space-y-3"
              >
                <div className="flex items-center space-x-3 p-3 border rounded-lg hover:bg-muted/50 cursor-pointer">
                  <RadioGroupItem value="mitra" id="mitra" />
                  <Label htmlFor="mitra" className="flex-1 cursor-pointer">
                    <div className="font-medium">Block Mitra</div>
                    <div className="text-sm text-muted-foreground">{mitraName}</div>
                  </Label>
                </div>
                <div className="flex items-center space-x-3 p-3 border rounded-lg hover:bg-muted/50 cursor-pointer">
                  <RadioGroupItem value="customer" id="customer" />
                  <Label htmlFor="customer" className="flex-1 cursor-pointer">
                    <div className="font-medium">Block Customer</div>
                    <div className="text-sm text-muted-foreground">{customerName}</div>
                  </Label>
                </div>
              </RadioGroup>
            </div>

            {/* Illustration */}
            <div className="mb-8 relative">
              <div className="w-24 h-20 bg-amber-100 rounded-lg flex items-center justify-center relative">
                <div className="absolute -top-2 -right-2 w-8 h-8 bg-red-500 rounded-full flex items-center justify-center">
                  <svg className="w-5 h-5 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                  </svg>
                </div>
                <div className="absolute -bottom-1 -right-3">
                  <div className="w-12 h-16 relative">
                    <div className="absolute bottom-0 w-10 h-12 bg-orange-200 rounded-t-full"></div>
                    <div className="absolute bottom-8 left-1/2 -translate-x-1/2 w-6 h-6 bg-orange-100 rounded-full"></div>
                    <div className="absolute bottom-3 left-1/2 -translate-x-1/2 w-5 h-5 bg-red-400 rounded-full flex items-center justify-center">
                      <svg className="w-3 h-3 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <circle cx="12" cy="12" r="10" strokeWidth={2} />
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4.93 4.93l14.14 14.14" />
                      </svg>
                    </div>
                  </div>
                </div>
              </div>
            </div>
            
            <div className="flex gap-4 w-full">
              <Button 
                variant="outline"
                className="flex-1 bg-gray-200 hover:bg-gray-300 text-gray-700 border-0"
                onClick={() => onOpenChange(false)}
              >
                Kembali
              </Button>
              <Button 
                className="flex-1 bg-red-500 hover:bg-red-600 text-white"
                onClick={() => {
                  onConfirm(selectedType);
                  onOpenChange(false);
                }}
              >
                Block
              </Button>
            </div>
          </div>
        </DialogContent>
      </Dialog>
    );
  }

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-md p-8">
        <div className="flex flex-col items-center text-center">
          <h2 className="text-xl font-semibold text-foreground mb-6">
            Akun Ini Berhasil Di Banned
          </h2>
          
          {/* Success illustration */}
          <div className="mb-8 relative">
            <div className="w-24 h-24 bg-purple-100 rounded-full flex items-center justify-center">
              <div className="w-16 h-16 relative">
                {/* Character illustration */}
                <div className="absolute bottom-0 left-1/2 -translate-x-1/2 w-12 h-10 bg-purple-200 rounded-t-full"></div>
                <div className="absolute bottom-6 left-1/2 -translate-x-1/2 w-10 h-10 bg-amber-100 rounded-full flex items-center justify-center">
                  <div className="w-8 h-4 bg-amber-800 rounded-t-full absolute top-0"></div>
                </div>
              </div>
              {/* Checkmark */}
              <div className="absolute -bottom-1 -right-1 w-8 h-8 bg-green-500 rounded-full flex items-center justify-center">
                <svg className="w-5 h-5 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={3} d="M5 13l4 4L19 7" />
                </svg>
              </div>
            </div>
          </div>
          
          <Button 
            className="w-32 bg-[#1e3a5f] hover:bg-[#152a45] text-white"
            onClick={() => onOpenChange(false)}
          >
            Kembali
          </Button>
        </div>
      </DialogContent>
    </Dialog>
  );
};

export default BlockLaporanPopup;
