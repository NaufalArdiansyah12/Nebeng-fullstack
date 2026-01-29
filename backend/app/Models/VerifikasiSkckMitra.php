<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class VerifikasiSkckMitra extends Model
{
    protected $table = 'verifikasi_skck_mitras';

    protected $fillable = [
        'user_id',
        'skck_number',
        'skck_name',
        'skck_expiry_date',
        'skck_photo',
        'status',
        'rejection_reason',
        'verified_at',
    ];

    protected $casts = [
        'skck_expiry_date' => 'date',
        'verified_at' => 'datetime',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
