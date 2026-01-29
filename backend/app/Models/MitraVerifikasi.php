<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class MitraVerifikasi extends Model
{
    protected $table = 'mitra_verifikasi';

    protected $fillable = [
        'user_id',
        'ktp_verification_id',
        'sim_verification_id',
        'skck_verification_id',
        'bank_verification_id',
        'verified_at',
    ];

    protected $casts = [
        'verified_at' => 'datetime',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function ktpVerification(): BelongsTo
    {
        return $this->belongsTo(VerifikasiKtpMitra::class, 'ktp_verification_id');
    }

    public function simVerification(): BelongsTo
    {
        return $this->belongsTo(VerifikasiSimMitra::class, 'sim_verification_id');
    }

    public function skckVerification(): BelongsTo
    {
        return $this->belongsTo(VerifikasiSkckMitra::class, 'skck_verification_id');
    }

    public function bankVerification(): BelongsTo
    {
        return $this->belongsTo(VerifikasiBankMitra::class, 'bank_verification_id');
    }
}
