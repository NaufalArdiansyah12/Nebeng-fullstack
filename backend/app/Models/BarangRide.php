<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class BarangRide extends Model
{
    protected $table = 'tebengan_barang';

    protected $fillable = [
        'user_id',
        'origin_location_id',
        'destination_location_id',
        'departure_date',
        'departure_time',
        'ride_type',
        'service_type',
        'price',
        'available_seats',
        'bagasi_capacity',
        'jumlah_bagasi',
        'kendaraan_mitra_id',
        'extra',
        'status',
    ];

    protected $casts = [
        'departure_date' => 'date',
        'price' => 'decimal:2',
        'extra' => 'array',
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

    public function kendaraanMitra(): BelongsTo
    {
        return $this->belongsTo(\App\Models\KendaraanMitra::class, 'kendaraan_mitra_id');
    }
}
