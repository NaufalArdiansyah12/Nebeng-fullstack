import { useState } from "react";
import { ZoomIn, ImageOff } from "lucide-react";
import { ImageModal } from "./image-modal";

interface PhotoFieldProps {
  label: string;
  src: string | null;
  alt: string;
}

export function PhotoField({ label, src, alt }: PhotoFieldProps) {
  const [open, setOpen] = useState(false);

  return (
    <>
      <div className="flex flex-col gap-1">
        <label className="text-sm text-gray-600">{label}</label>

        {src ? (
          <button
            type="button"
            onClick={() => setOpen(true)}
            className="flex items-center justify-between px-4 py-2.5 rounded-lg bg-gray-100 border border-transparent text-sm text-gray-700 min-h-[42px] w-full text-left hover:bg-gray-200 transition-colors group"
          >
            <div className="flex items-center gap-3 min-w-0">
              <img
                src={src}
                alt={alt}
                className="h-7 w-12 rounded object-cover flex-shrink-0 border border-gray-300"
              />
              <span className="truncate text-gray-500 text-xs">{alt}</span>
            </div>
            <ZoomIn className="h-4 w-4 text-gray-400 flex-shrink-0 group-hover:text-blue-500 transition-colors" />
          </button>
        ) : (
          <div className="flex items-center gap-3 px-4 py-2.5 rounded-lg bg-gray-100 border border-transparent text-sm text-gray-400 min-h-[42px]">
            <ImageOff className="h-4 w-4 flex-shrink-0" />
            <span className="text-xs">Foto tidak tersedia</span>
          </div>
        )}
      </div>

      {open && src && (
        <ImageModal src={src} alt={alt} onClose={() => setOpen(false)} />
      )}
    </>
  );
}
