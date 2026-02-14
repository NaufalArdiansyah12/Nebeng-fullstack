import { X } from "lucide-react";

interface ImageModalProps {
  src: string;
  alt: string;
  onClose: () => void;
}

export function ImageModal({ src, alt, onClose }: ImageModalProps) {
  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/70 backdrop-blur-sm p-6"
      onClick={onClose}
    >
      <div
        className="relative bg-white rounded-2xl shadow-2xl overflow-hidden"
        style={{ maxWidth: "90vw", maxHeight: "90vh" }}
        onClick={(e) => e.stopPropagation()}
      >
        {/* Close button */}
        <button
          onClick={onClose}
          className="absolute top-3 right-3 z-10 bg-white/90 hover:bg-white rounded-full p-1.5 shadow-md transition-colors"
        >
          <X className="h-4 w-4 text-gray-600" />
        </button>

        {/* Label */}
        <div className="absolute top-3 left-3 z-10 bg-black/50 text-white text-xs px-2.5 py-1 rounded-full">
          {alt}
        </div>

        <img
          src={src}
          alt={alt}
          style={{
            display: "block",
            maxWidth: "85vw",
            maxHeight: "85vh",
            objectFit: "contain",
          }}
        />
      </div>
    </div>
  );
}
