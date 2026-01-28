<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Rating extends Model
{
    protected $table = 'driver_ratings';
    
    protected $fillable = [
        'booking_id',
        'booking_type',
        'user_id',
        'driver_id',
        'rating',
        'review',
    ];

    protected $casts = [
        'rating' => 'integer',
    ];

    /**
     * Get the customer who gave the rating
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    /**
     * Get the driver being rated
     */
    public function driver(): BelongsTo
    {
        return $this->belongsTo(User::class, 'driver_id');
    }

    /**
     * Get the booking (polymorphic)
     */
    public function booking()
    {
        switch ($this->booking_type) {
            case 'motor':
                return $this->belongsTo(Booking::class, 'booking_id');
            case 'mobil':
                return $this->belongsTo(BookingMobil::class, 'booking_id');
            case 'barang':
                return $this->belongsTo(BookingBarang::class, 'booking_id');
            case 'titip_barang':
                return $this->belongsTo(BookingTitipBarang::class, 'booking_id');
            default:
                return null;
        }
    }
}
