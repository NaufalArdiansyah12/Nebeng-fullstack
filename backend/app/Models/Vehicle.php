<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Vehicle extends Model
{
    use HasFactory;

    // Vehicles table has been renamed to `kendaraan_mitra`.
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

    protected $casts = [
        'is_active' => 'boolean',
        'year' => 'integer',
        'seats' => 'integer',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function rides()
    {
        return $this->hasMany(Ride::class);
    }
}
