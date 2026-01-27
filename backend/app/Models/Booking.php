<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Booking extends Model
{
    protected $table = 'booking_motor';
    protected $fillable = [
        'ride_id',
        'user_id',
        'booking_number',
        'driver_id',
        'seats',
        'status',
        'meta',
        'photo',
        'weight',
        'description',
    ];

    protected $casts = [
        'meta' => 'array',
        'scheduled_at' => 'datetime',
        'last_location_at' => 'datetime',
    ];

    public function ride(): BelongsTo
    {
        return $this->belongsTo(Ride::class);
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
