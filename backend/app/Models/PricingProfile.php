<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class PricingProfile extends Model
{
    use HasFactory;

    protected $fillable = ['name', 'description', 'transport_mode_id', 'active', 'base_price', 'price_per_km', 'price_per_kg', 'min_price', 'price_category_kecil', 'price_category_sedang', 'price_category_besar'];

    public function transportMode()
    {
        return $this->belongsTo(TransportMode::class);
    }

    public function rules()
    {
        return $this->hasMany(PricingRule::class);
    }
}
