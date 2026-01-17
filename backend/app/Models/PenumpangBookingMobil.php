<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class PenumpangBookingMobil extends Model
{
    protected $table = 'penumpang_booking_mobil';

    protected $fillable = [
        'booking_mobil_id',
        'nama',
        'nik',
        'no_telepon',
        'jenis_kelamin',
    ];

    public function bookingMobil(): BelongsTo
    {
        return $this->belongsTo(BookingMobil::class, 'booking_mobil_id');
    }
}
