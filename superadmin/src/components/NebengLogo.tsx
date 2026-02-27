const NebengLogo = ({ className = "" }: { className?: string }) => {
  return (
    <div className={`flex items-center gap-1 ${className}`}>
      <span className="text-2xl font-bold text-primary-foreground">Nebeng</span>
      <div className="relative">
        <div className="w-2 h-2 rounded-full bg-nebeng-blue" />
        <svg
          className="absolute -top-1 -left-1 w-4 h-4"
          viewBox="0 0 24 24"
          fill="none"
          xmlns="http://www.w3.org/2000/svg"
        >
          <path
            d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"
            fill="currentColor"
            className="text-nebeng-blue"
          />
        </svg>
      </div>
    </div>
  );
};

export default NebengLogo;
