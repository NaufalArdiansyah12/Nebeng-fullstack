interface JourneyCardProps {
  journey: {
    date: string;
    distance: string;
    duration: string;
    pickup_location: string;
    pickup_time: string;
    pickup_address: string;
    destination_location: string;
    destination_time: string;
    destination_address: string;
  };
}

export function JourneyCard({ journey }: JourneyCardProps) {
  return (
    <div className="bg-background rounded-xl p-6 border shadow-sm">
      <h3 className="font-semibold text-lg mb-4">Rincian Perjalanan</h3>

      <div className="flex items-center justify-between text-sm mb-6">
        <p className="font-medium">{journey.date}</p>
      </div>

      <div className="space-y-0">
        {/* Titik Jemput */}
        <div className="flex gap-4">
          <div className="flex flex-col items-center">
            <div className="h-3 w-3 rounded-full bg-primary mt-1"></div>
            <div className="w-0.5 flex-1 bg-border my-2" style={{ minHeight: '80px' }}></div>
          </div>
          <div className="flex-1 pb-6">
            <p className="text-sm text-muted-foreground mb-1">Titik Jemput</p>
            <p className="font-semibold mb-1">{journey.pickup_location}</p>
            <p className="text-xs text-muted-foreground mb-1">{journey.pickup_address}</p>
          </div>
        </div>

        {/* Tujuan */}
        <div className="flex gap-4">
          <div className="flex flex-col items-center">
            <div className="h-3 w-3 rounded-full bg-destructive"></div>
          </div>
          <div className="flex-1 pb-6">
            <p className="text-sm text-muted-foreground mb-1">Tujuan</p>
            <p className="font-semibold mb-1">{journey.destination_location}</p>
            <p className="text-xs text-muted-foreground mb-1">{journey.destination_address}</p>
          </div>
        </div>
      </div>
    </div>
  );
}
