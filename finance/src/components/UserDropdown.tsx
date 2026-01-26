import { forwardRef, ButtonHTMLAttributes } from "react";
import { ChevronDown } from "lucide-react";

interface UserDropdownProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  userName?: string;
}

const UserDropdown = forwardRef<HTMLButtonElement, UserDropdownProps>(
  ({ userName, ...props }, ref) => {
    return (
      <button
        ref={ref}
        type="button"
        {...props}
        className="flex items-center gap-2 hover:opacity-80 transition-opacity"
      >
        <div className="w-8 h-8 rounded-full bg-primary flex items-center justify-center text-primary-foreground text-sm font-medium">
          {userName?.charAt(0).toUpperCase() || "?"}
        </div>
        <span className="text-sm font-medium text-foreground">
          {userName || "Guest"}
        </span>
        <ChevronDown className="h-4 w-4 text-muted-foreground" />
      </button>
    );
  }
);

UserDropdown.displayName = "UserDropdown";

export default UserDropdown;
