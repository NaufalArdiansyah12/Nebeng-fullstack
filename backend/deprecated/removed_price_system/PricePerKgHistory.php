<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class PricePerKgHistory extends Model
{
    protected $table = 'price_per_kg_history';

    protected $fillable = [
        'price_per_kg_id',
        'action',
        'service_type',
        'ride_type',
        'bagasi_capacity',
        'rate_per_kg',
        'min_charge',
        'is_active',
        'effective_from',
        'changed_by',
        'notes',
    ];

    protected $casts = [
        'rate_per_kg' => 'decimal:2',
        'min_charge' => 'decimal:2',
        'is_active' => 'boolean',
        'effective_from' => 'date',
        'changed_at' => 'datetime',
    ];

    /**
     * Get the price that this history belongs to
     */
    public function pricePerKg()
    {
        return $this->belongsTo(PricePerKg::class);
    }

    /**
     * Get the user who made the change
     */
    public function changedByUser()
    {
        return $this->belongsTo(User::class, 'changed_by');
    }
}
