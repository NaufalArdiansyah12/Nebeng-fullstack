<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class WeightCategory extends Model
{
    use HasFactory;

    protected $fillable = ['name', 'slug', 'min_weight', 'max_weight'];

    public function containsWeight($weight)
    {
        $min = (float) $this->min_weight;
        $max = $this->max_weight !== null ? (float) $this->max_weight : null;

        if ($max === null) {
            return $weight >= $min;
        }

        return $weight >= $min && $weight <= $max;
    }
}
