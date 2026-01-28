<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class BookingBarang extends Model
{
    protected $table = 'booking_barang';

    protected $fillable = [
        'ride_id',
        'user_id',
        'booking_number',
        'seats',
        'status',
        'cancellation_reason',
        'meta',
        'photo',
        'weight',
        'description',
    ];

    protected $casts = [
        'meta' => 'array',
    ];

    public function ride(): BelongsTo
    {
        return $this->belongsTo(BarangRide::class, 'ride_id');
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
