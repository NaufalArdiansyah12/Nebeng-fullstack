import { Edit, Camera } from "lucide-react";
import { Button } from "@/components/ui/button";
import { useRef } from "react";

interface ProfileHeaderProps {
  name: string;
  role: string;
  badge: string;
  onEdit: () => void;
  profileImage?: string;
  onImageChange?: (file: File) => void;
}

export const ProfileHeader = ({ name, role, badge, onEdit, profileImage, onImageChange }: ProfileHeaderProps) => {
  const fileInputRef = useRef<HTMLInputElement>(null);

  const handleImageClick = () => {
    fileInputRef.current?.click();
  };

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file && onImageChange) {
      onImageChange(file);
    }
  };

  return (
    <div className="bg-background border border-border rounded-xl p-6 mb-6 flex items-center justify-between">
      <div className="flex items-center gap-4">
        <div className="relative group">
          <div className="w-16 h-16 rounded-full bg-gradient-to-br from-blue-400 to-blue-600 flex items-center justify-center overflow-hidden">
            {profileImage ? (
              <img src={profileImage} alt="Profile" className="w-full h-full object-cover" />
            ) : (
              <svg viewBox="0 0 100 100" className="w-12 h-12">
                <circle cx="50" cy="35" r="15" fill="#FFF" />
                <path d="M 30 70 Q 30 50 50 50 Q 70 50 70 70 Z" fill="#FFF" />
              </svg>
            )}
          </div>
          <button
            onClick={handleImageClick}
            className="absolute -bottom-1 -right-1 w-7 h-7 bg-primary rounded-full flex items-center justify-center hover:bg-primary/90 transition-colors cursor-pointer shadow-md"
          >
            <Camera className="w-4 h-4 text-white" />
          </button>
          <input
            ref={fileInputRef}
            type="file"
            accept="image/*"
            onChange={handleFileChange}
            className="hidden"
          />
        </div>
        <div>
          <h2 className="font-semibold text-lg">{name}</h2>
          <p className="text-sm text-muted-foreground">{role}</p>
          <span className="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-blue-100 text-blue-800 mt-1">
            {badge}
          </span>
        </div>
      </div>
      <Button
        size="sm"
        variant="outline"
        className="gap-2"
        onClick={onEdit}
      >
        Edit <Edit className="w-4 h-4" />
      </Button>
    </div>
  );
};
