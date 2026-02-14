import { Avatar, AvatarFallback, AvatarImage } from "../avatar";

interface MitraProfileHeaderProps {
  name: string;
  photoUrl: string | null;
}

export function MitraProfileHeader({ name, photoUrl }: MitraProfileHeaderProps) {
  return (
    <div className="flex items-center gap-4 px-6 py-5 bg-gray-50 border-b border-gray-200">
      <Avatar className="w-16 h-16">
        <AvatarImage src={photoUrl || undefined} />
        <AvatarFallback className="text-xl font-semibold bg-orange-100 text-orange-600">
          {name.charAt(0)}
        </AvatarFallback>
      </Avatar>
      <div>
        <p className="font-semibold text-base text-gray-900">{name}</p>
      </div>
    </div>
  );
}
