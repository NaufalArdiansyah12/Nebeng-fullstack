<?php

namespace App\Events;

class BookingStatusChanged
{
    public $bookingId;
    public $status;

    public function __construct($bookingId, $status)
    {
        $this->bookingId = $bookingId;
        $this->status = $status;
    }
}
