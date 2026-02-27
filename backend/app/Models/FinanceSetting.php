<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class FinanceSetting extends Model
{
    use HasFactory;

    protected $table = 'finance_settings';

    protected $fillable = [
        'admin_fee',
        'reschedule_fee',
    ];

    protected $casts = [
        'admin_fee' => 'float',
        'reschedule_fee' => 'float',
    ];
}
