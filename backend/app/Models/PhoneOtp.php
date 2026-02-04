<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Carbon\Carbon;

class PhoneOtp extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'phone',
        'otp_code',
        'attempts',
        'expires_at',
        'is_used',
    ];

    protected $casts = [
        'expires_at' => 'datetime',
        'is_used' => 'boolean',
    ];

    /**
     * Relasi ke User
     */
    public function user()
    {
        return $this->belongsTo(User::class);
    }

    /**
     * Cek apakah OTP sudah expired
     */
    public function isExpired(): bool
    {
        return Carbon::now()->isAfter($this->expires_at);
    }

    /**
     * Cek apakah OTP masih valid (belum digunakan dan belum expired)
     */
    public function isValid(): bool
    {
        return !$this->is_used && !$this->isExpired();
    }

    /**
     * Increment attempts
     */
    public function incrementAttempts(): void
    {
        $this->increment('attempts');
    }

    /**
     * Cek apakah sudah mencapai max attempts
     */
    public function hasReachedMaxAttempts(): bool
    {
        return $this->attempts >= 3;
    }

    /**
     * Mark OTP sebagai used
     */
    public function markAsUsed(): void
    {
        $this->update(['is_used' => true]);
    }
}
