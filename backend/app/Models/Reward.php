<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Reward extends Model
{
    use HasFactory;

    protected $fillable = [
        'title',
        'description',
        'points_cost',
        'image_url',
        'stock',
    ];

    public function redemptions()
    {
        return $this->hasMany(RewardRedemption::class);
    }
}
