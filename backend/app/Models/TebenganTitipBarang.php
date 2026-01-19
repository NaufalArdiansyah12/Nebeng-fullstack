<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class TebenganTitipBarang extends Model
{
    protected $table = 'tebengan_titip_barang';
    
    protected $fillable = [
        'user_id',
        'origin_location_id',
        'destination_location_id',
        'departure_date',
        'departure_time',
        'transportation_type',
        'bagasi_capacity',
        'jumlah_bagasi',
        'price',
        'status',
    ];

    protected $casts = [
        'departure_date' => 'date',
        'departure_time' => 'datetime:H:i:s',
        'price' => 'decimal:2',
        'bagasi_capacity' => 'integer',
        'jumlah_bagasi' => 'integer',
    ];

    protected $attributes = [
        'jumlah_bagasi' => 0,
    ];

    // Relationships
    public function user()
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    public function originLocation()
    {
        return $this->belongsTo(Location::class, 'origin_location_id');
    }

    public function destinationLocation()
    {
        return $this->belongsTo(Location::class, 'destination_location_id');
    }

    public function kendaraanMitra(): BelongsTo
    {
        return $this->belongsTo(\App\Models\KendaraanMitra::class, 'kendaraan_mitra_id');
    }
}
