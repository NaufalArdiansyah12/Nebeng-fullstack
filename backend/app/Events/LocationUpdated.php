<?php

namespace App\Events;

class LocationUpdated
{
    public $bookingId;
    public $payload;

    public function __construct($bookingId, $payload = [])
    {
        $this->bookingId = $bookingId;
        $this->payload = $payload;
    }
}
