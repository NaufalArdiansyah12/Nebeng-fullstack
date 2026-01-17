<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\MorphTo;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class VerifikasiKtp extends Model
{
    protected $table = 'verifikasi_ktp';

    protected $fillable = [
        'verifiable_id',
        'verifiable_type',
        'nama_lengkap',
        'nik',
        'tanggal_lahir',
        'alamat',
        'photo_wajah',
        'photo_ktp',
        'photo_ktp_wajah',
        'status',
        'reviewer_id',
        'reviewed_at',
        'meta',
    ];

    protected $casts = [
        'meta' => 'array',
        'reviewed_at' => 'datetime',
        'tanggal_lahir' => 'date',
    ];

    public function verifiable(): MorphTo
    {
        return $this->morphTo();
    }

    public function reviewer(): BelongsTo
    {
        return $this->belongsTo(User::class, 'reviewer_id');
    }
}
