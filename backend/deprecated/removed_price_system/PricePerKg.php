<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class PricePerKg extends Model
{
    use SoftDeletes;

    protected $table = 'price_per_kg';

    protected $fillable = [
        'service_type',
        'ride_type',
        'bagasi_capacity',
        'rate_per_kg',
        'min_charge',
        'is_active',
        'effective_from',
    ];

    protected $casts = [
        'rate_per_kg' => 'decimal:2',
        'min_charge' => 'decimal:2',
        'is_active' => 'boolean',
        'effective_from' => 'date',
    ];

    /**
     * Get history records for this price
     */
    public function history()
    {
        return $this->hasMany(PricePerKgHistory::class);
    }

    /**
     * Get active price for a specific service and ride type
     * For antar_barang, also filter by bagasi_capacity if provided
     */
    public static function getActivePrice($serviceType, $rideType, $bagasiCapacity = null)
    {
        $query = self::where('service_type', $serviceType)
            ->where('ride_type', $rideType)
            ->where('is_active', true)
            ->where('effective_from', '<=', now());
        
        // For antar_barang service, filter by bagasi_capacity if provided
        if ($serviceType === 'antar_barang' && $bagasiCapacity !== null) {
            $query->where('bagasi_capacity', $bagasiCapacity);
        }
        
        return $query->orderBy('effective_from', 'desc')->first();
    }

    /**
     * Calculate total price based on weight
     */
    public function calculatePrice($weight)
    {
        $calculated = $weight * $this->rate_per_kg;
        return max($calculated, $this->min_charge);
    }

    /**
     * Log changes to history
     */
    public function logChange($action, $changedBy = null, $notes = null)
    {
        return PricePerKgHistory::create([
            'price_per_kg_id' => $this->id,
            'action' => $action,
            'service_type' => $this->service_type,
            'ride_type' => $this->ride_type,
            'bagasi_capacity' => $this->bagasi_capacity,
            'rate_per_kg' => $this->rate_per_kg,
            'min_charge' => $this->min_charge,
            'is_active' => $this->is_active,
            'effective_from' => $this->effective_from,
            'changed_by' => $changedBy,
            'notes' => $notes,
        ]);
    }
}
