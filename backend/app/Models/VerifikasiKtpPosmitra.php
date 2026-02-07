<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class VerifikasiKtpPosmitra extends Model
{
    protected $table = 'verifikasi_ktp_posmitra';

    protected $fillable = [
        'posmitra_id',
        'nama_lengkap',
        'nik',
        'tanggal_lahir',
        'jenis_kelamin',
        'alamat',
        'photo_ktp',
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

    public function posmitra(): BelongsTo
    {
        return $this->belongsTo(PosMitraUser::class, 'posmitra_id');
    }

    public function reviewer(): BelongsTo
    {
        return $this->belongsTo(User::class, 'reviewer_id');
    }
}
