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
        'seats',
        'status',
        'meta',
    ];

    protected $casts = [
        'meta' => 'array',
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
