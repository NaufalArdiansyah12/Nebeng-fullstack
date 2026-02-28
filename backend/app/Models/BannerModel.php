<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class BannerModel extends Model
{
    protected $table = 'banners';
    protected $fillable = [
        'title',
        'image_url',
        'is_active',
        'position',
        'order',
    ];
}
