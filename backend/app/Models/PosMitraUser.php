<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;

class PosMitraUser extends Authenticatable
{
    use HasFactory, Notifiable;

    /**
     * The table associated with the model.
     *
     * @var string
     */
    protected $table = 'posmitra_users';

    /**
     * The attributes that are mass assignable.
     *
     * @var array<int, string>
     */
    protected $fillable = [
        'name',
        'email',
        'phone',
        'phone_verified',
        'phone_verified_at',
        'password',
        'profile_photo',
        'balance',
        'pin',
        'fcm_token',
        'location_id',
        'bank_name',
        'bank_account_number',
        'bank_account_name',
    ];

    /**
     * The attributes that should be hidden for serialization.
     *
     * @var array<int, string>
     */
    protected $hidden = [
        'password',
        'remember_token',
        'pin',
    ];

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'phone_verified' => 'boolean',
            'phone_verified_at' => 'datetime',
            'password' => 'hashed',
            'balance' => 'decimal:2',
        ];
    }

    /**
     * Relasi ke Location
     */
    public function location()
    {
        return $this->belongsTo(Location::class, 'location_id');
    }

    /**
     * Relasi ke Phone OTPs
     */
    public function phoneOtps()
    {
        return $this->hasMany(PhoneOtp::class, 'user_id');
    }

    /**
     * Relasi ke Verifikasi KTP PosMitra
     */
    public function verifikasiKtp()
    {
        return $this->hasOne(VerifikasiKtpPosmitra::class, 'posmitra_id');
    }

    /**
     * Relasi ke Withdrawal PosMitra
     */
    public function withdrawals()
    {
        return $this->hasMany(WithdrawalPosmitra::class, 'posmitra_id');
    }
}
