<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class BookingTitipBarang extends Model
{
    protected $table = 'booking_titip_barang';

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
        'penerima',
    ];

    protected $casts = [
        'meta' => 'array',
    ];

    public function ride(): BelongsTo
    {
        // BookingTitipBarang references TebenganTitipBarang as the "ride"
        return $this->belongsTo(TebenganTitipBarang::class, 'ride_id');
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
