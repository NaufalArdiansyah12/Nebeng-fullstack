<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class KendaraanMitra extends Model
{
    protected $table = 'kendaraan_mitra';

    protected $fillable = [
        'user_id',
        'vehicle_type',
        'name',
        'plate_number',
        'brand',
        'model',
        'color',
        'year',
        'seats',
        'is_active',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function motorRides(): HasMany
    {
        return $this->hasMany(Ride::class, 'kendaraan_mitra_id');
    }

    public function mobilRides(): HasMany
    {
        return $this->hasMany(CarRide::class, 'kendaraan_mitra_id');
    }
}
