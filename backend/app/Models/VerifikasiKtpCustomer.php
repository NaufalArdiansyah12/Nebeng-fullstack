<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class VerifikasiKtpCustomer extends Model
{
    protected $table = 'verifikasi_ktp_customers';

    protected $fillable = [
        'user_id',
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

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    public function reviewer(): BelongsTo
    {
        return $this->belongsTo(User::class, 'reviewer_id');
    }
}
