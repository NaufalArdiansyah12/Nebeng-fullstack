<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class BookingMobil extends Model
{
    protected $table = 'booking_mobil';

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
        return $this->belongsTo(CarRide::class, 'ride_id');
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function penumpang(): HasMany
    {
        return $this->hasMany(PenumpangBookingMobil::class, 'booking_mobil_id');
    }
}
