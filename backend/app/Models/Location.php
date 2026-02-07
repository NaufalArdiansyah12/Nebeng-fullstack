<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Location extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'city',
        'address',
        'latitude',
        'longitude',
        'created_by_role',
    ];

    /**
     * Get all PosMitra users assigned to this location
     */
    public function posMitraUsers()
    {
        return $this->hasMany(PosMitraUser::class, 'location_id');
    }
}
