<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class ApiToken extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'posmitra_id',
        'user_type',
        'token',
        'expires_at',
    ];

    protected $casts = [
        'expires_at' => 'datetime',
    ];

    // relasi user biasa
    public function user()
    {
        return $this->belongsTo(User::class);
    }

    // relasi posmitra (PAKAI posmitra_id)
    public function posMitraUser()
    {
        return $this->belongsTo(PosMitraUser::class, 'posmitra_id');
    }

    /**
     * ambil user sesuai user_type
     */
    public function getAuthenticatedUser()
    {
        return $this->user_type === 'posmitra'
            ? $this->posMitraUser
            : $this->user;
    }
}
