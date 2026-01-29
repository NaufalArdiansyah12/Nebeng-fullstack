<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class VerifikasiBankMitra extends Model
{
    protected $table = 'verifikasi_bank_mitras';

    protected $fillable = [
        'user_id',
        'bank_account_number',
        'bank_account_name',
        'bank_name',
        'bank_account_photo',
        'status',
        'rejection_reason',
        'verified_at',
    ];

    protected $casts = [
        'verified_at' => 'datetime',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
