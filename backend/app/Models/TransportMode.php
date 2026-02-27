<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class TransportMode extends Model
{
    use HasFactory;

    protected $fillable = ['name', 'slug'];

    public function pricingProfiles()
    {
        return $this->hasMany(PricingProfile::class);
    }
}
