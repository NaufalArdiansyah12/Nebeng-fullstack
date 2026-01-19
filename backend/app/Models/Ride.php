<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasOne;
use App\Models\CarRide;

class Ride extends Model
{
    protected $table = 'tebengan_motor';
    protected $fillable = [
        'user_id',
        'origin_location_id',
        'destination_location_id',
        'departure_date',
        'departure_time',
        'ride_type',
        'service_type',
        'price',
        'bagasi_capacity',
        'jumlah_bagasi',
        'available_seats',
        'kendaraan_mitra_id',
        'status',
    ];

    protected $casts = [
        'departure_date' => 'date',
        'price' => 'decimal:2',
    ];

    protected $attributes = [
        'jumlah_bagasi' => 0,
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function originLocation(): BelongsTo
    {
        return $this->belongsTo(Location::class, 'origin_location_id');
    }

    public function destinationLocation(): BelongsTo
    {
        return $this->belongsTo(Location::class, 'destination_location_id');
    }

    public function carRide(): HasOne
    {
        // tebengan_mobil stores mobil rides as full rows whose `id` equals the ride id
        return $this->hasOne(CarRide::class, 'id', 'id');
    }

    public function kendaraanMitra(): BelongsTo
    {
        return $this->belongsTo(\App\Models\KendaraanMitra::class, 'kendaraan_mitra_id');
    }

    public function bookings()
    {
        return $this->hasMany(\App\Models\Booking::class, 'ride_id');
    }
}
