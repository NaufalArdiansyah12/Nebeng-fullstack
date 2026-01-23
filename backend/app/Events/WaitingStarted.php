<?php

namespace App\Events;

class WaitingStarted
{
    public $bookingId;
    public $payload;

    public function __construct($bookingId, $payload = [])
    {
        $this->bookingId = $bookingId;
        $this->payload = $payload;
    }
}
<?php

namespace App\Events;

use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Queue\SerializesModels;

class WaitingStarted implements ShouldBroadcastNow
{
    use InteractsWithSockets, SerializesModels;

    public $bookingId;
    public $payload;

    public function __construct($bookingId, array $payload = [])
    {
        $this->bookingId = $bookingId;
        $this->payload = $payload;
    }

    public function broadcastOn()
    {
        return new PrivateChannel('booking.' . $this->bookingId);
    }

    public function broadcastWith()
    {
        return $this->payload;
    }
}
