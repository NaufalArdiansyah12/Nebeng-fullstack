import { useState } from "react";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { Eye, EyeOff, Edit } from "lucide-react";

interface AccountInfoFormProps {
  currentPassword: string;
  isEdit: boolean;
  onEdit: () => void;
  onPasswordChange: (field: 'new' | 'confirm', value: string) => void;
  newPassword: string;
  confirmPassword: string;
}

export const AccountInfoForm = ({ 
  currentPassword, 
  isEdit, 
  onEdit,
  onPasswordChange,
  newPassword,
  confirmPassword 
}: AccountInfoFormProps) => {
  const [showCurrent, setShowCurrent] = useState(false);
  const [showNew, setShowNew] = useState(false);
  const [showConfirm, setShowConfirm] = useState(false);

  return (
    <div className="bg-background border border-border rounded-xl p-6">
      <h3 className="font-semibold text-base mb-5">Informasi Akun</h3>
      
      <div className="space-y-4">
        <div>
          <label className="text-xs font-medium text-muted-foreground mb-2 block">
            Password
          </label>
          <div className="flex items-center gap-3">
            <div className="relative flex-1">
              <Input
                type={showCurrent ? "text" : "password"}
                value={currentPassword}
                disabled
                className="bg-muted border-0"
              />
              <button
                type="button"
                onClick={() => setShowCurrent(!showCurrent)}
                className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground"
              >
                {showCurrent ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
              </button>
            </div>
            <Button
              size="sm"
              variant="outline"
              className="gap-2 bg-blue-50 text-blue-600 border-blue-200 hover:bg-blue-100"
              onClick={onEdit}
            >
              Edit <Edit className="w-3 h-3" />
            </Button>
          </div>
        </div>

        {isEdit && (
          <>
            <div>
              <label className="text-xs font-medium text-muted-foreground mb-2 block">
                Password Baru
              </label>
              <div className="relative">
                <Input
                  type={showNew ? "text" : "password"}
                  placeholder="Masukkan Password Baru"
                  value={newPassword}
                  onChange={(e) => onPasswordChange('new', e.target.value)}
                  className="bg-muted border-0"
                />
                <button
                  type="button"
                  onClick={() => setShowNew(!showNew)}
                  className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground"
                >
                  {showNew ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                </button>
              </div>
            </div>

            <div>
              <label className="text-xs font-medium text-muted-foreground mb-2 block">
                Konfirmasi Password Baru
              </label>
              <div className="relative">
                <Input
                  type={showConfirm ? "text" : "password"}
                  placeholder="Masukkan Password Baru"
                  value={confirmPassword}
                  onChange={(e) => onPasswordChange('confirm', e.target.value)}
                  className="bg-muted border-0"
                />
                <button
                  type="button"
                  onClick={() => setShowConfirm(!showConfirm)}
                  className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground"
                >
                  {showConfirm ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                </button>
              </div>
            </div>
          </>
        )}
      </div>
    </div>
  );
};
