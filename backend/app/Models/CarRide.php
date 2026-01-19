<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class CarRide extends Model
{
    // After schema split, mobil-specific rides live in `tebengan_mobil`.
    // Keep model name `CarRide` for compatibility but map to new table.
    protected $table = 'tebengan_mobil';

    // Allow full ride fields so we can store complete mobil rows in tebengan_mobil
    protected $fillable = [
        'id',
        'user_id',
        'origin_location_id',
        'destination_location_id',
        'departure_date',
        'departure_time',
        'ride_type',
        'service_type',
        'price',
        'vehicle_name',
        'vehicle_plate',
        'vehicle_brand',
        'vehicle_type',
        'vehicle_color',
        'available_seats',
        'status',
        'bagasi_capacity',
        'jumlah_bagasi',
        'kendaraan_mitra_id',
    ];

    protected $casts = [
        'departure_date' => 'date',
        'price' => 'decimal:2',
    ];

    protected $attributes = [
        'jumlah_bagasi' => 0,
    ];

    public function ride(): BelongsTo
    {
        // tebengan_mobil uses the same primary id as the main ride id
        return $this->belongsTo(Ride::class, 'id', 'id');
    }

    public function kendaraanMitra(): BelongsTo
    {
        return $this->belongsTo(\App\Models\KendaraanMitra::class, 'kendaraan_mitra_id');
    }

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
}
