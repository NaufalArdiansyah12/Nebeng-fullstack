<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class PricingRule extends Model
{
    use HasFactory;

    protected $fillable = ['pricing_profile_id', 'weight_category_id', 'service_type', 'price'];

    public function profile()
    {
        return $this->belongsTo(PricingProfile::class, 'pricing_profile_id');
    }

    public function weightCategory()
    {
        return $this->belongsTo(WeightCategory::class, 'weight_category_id');
    }
}
