<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class VerifikasiSimMitra extends Model
{
    protected $table = 'verifikasi_sim_mitras';

    protected $fillable = [
        'user_id',
        'sim_number',
        'sim_type',
        'sim_expiry_date',
        'sim_photo',
        'status',
        'rejection_reason',
        'verified_at',
    ];

    protected $casts = [
        'sim_expiry_date' => 'date',
        'verified_at' => 'datetime',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
