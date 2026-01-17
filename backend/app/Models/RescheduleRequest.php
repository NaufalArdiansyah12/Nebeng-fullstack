<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class RescheduleRequest extends Model
{
    protected $table = 'reschedule_requests';

    protected $fillable = [
        'booking_id',
        'booking_type',
        'requested_ride_id',
        'requested_target_type',
        'requested_target_id',
        'requested_by',
        'status',
        'price_before',
        'price_after',
        'price_diff',
        'payment_txn_id',
        'reason',
        'meta',
        'processed_at',
    ];

    protected $casts = [
        'meta' => 'array',
        'processed_at' => 'datetime',
    ];

    public function booking(): BelongsTo
    {
        // booking can be polymorphic; default relation to BookingMobil for legacy compatibility
        return $this->belongsTo(BookingMobil::class, 'booking_id');
    }

    public function requestedRide(): BelongsTo
    {
        // legacy helper - requested target may be polymorphic
        return $this->belongsTo(CarRide::class, 'requested_target_id');
    }

    public function requestedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'requested_by');
    }
}
