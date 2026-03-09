<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class LocationQRBypassSetting extends Model
{
    protected $fillable = [
        'location_id',
        'qr_bypass_enabled',
        'notes',
    ];

    protected $casts = [
        'qr_bypass_enabled' => 'boolean',
    ];

    /**
     * Get the location that owns this setting
     */
    public function location(): BelongsTo
    {
        return $this->belongsTo(Location::class);
    }
}
