<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Refund extends Model
{
    protected $fillable = [
        'user_id',
        'booking_id',
        'booking_type',
        'refund_reason',
        'total_amount',
        'refund_amount',
        'admin_fee',
        'bank_name',
        'account_number',
        'account_holder_name',
        'status',
        'rejection_reason',
        'submitted_at',
        'approved_at',
        'processed_at',
        'completed_at',
    ];

    protected $casts = [
        'submitted_at' => 'datetime',
        'approved_at' => 'datetime',
        'processed_at' => 'datetime',
        'completed_at' => 'datetime',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    // Get booking dynamically based on booking_type
    public function booking()
    {
        switch ($this->booking_type) {
            case 'motor':
                return $this->belongsTo(Booking::class, 'booking_id');
            case 'mobil':
                return $this->belongsTo(BookingMobil::class, 'booking_id');
            case 'barang':
                return $this->belongsTo(BookingBarang::class, 'booking_id');
            case 'titip':
                return $this->belongsTo(BookingTitipBarang::class, 'booking_id');
            default:
                return null;
        }
    }
}
