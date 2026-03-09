<?php

namespace App\Models;

// use Illuminate\Contracts\Auth\MustVerifyEmail;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use App\Enums\UserRole;

class User extends Authenticatable
{
    /** @use HasFactory<\Database\Factories\UserFactory> */
    use HasFactory, Notifiable;

    /**
     * The attributes that are mass assignable.
     *
     * @var list<string>
     */
    protected $fillable = [
        'name',
        'email',
        'password',
        'role',
        'status',
        'blocked_reason',
        'blocked_at',
        'fcm_token',
        'address',
        'phone',
        'phone_verified',
        'phone_verified_at',
        'profile_photo',
        'balance',
        'pin',
        'reward_points',
        'gender',
        'google_id',
        'google_avatar',
    ];

    /**
     * The attributes that should be hidden for serialization.
     *
     * @var list<string>
     */
    protected $hidden = [
        'password',
        'remember_token',
        'pin',
    ];

    /**
     * The accessors to append to the model's array form.
     *
     * @var array
     */
    protected $appends = [
        'photo_url',
    ];

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'phone_verified_at' => 'datetime',
            'phone_verified' => 'boolean',
            'password' => 'hashed',
            'balance' => 'decimal:2',
            'role' => UserRole::class,
        ];
    }

    /**
     * Relasi ke Phone OTPs
     */
    public function phoneOtps()
    {
        return $this->hasMany(PhoneOtp::class);
    }

    /**
     * Get full URL for profile photo
     */
    public function getPhotoUrlAttribute(): ?string
    {
        if (empty($this->profile_photo)) {
            return null;
        }

        // If already full URL, return as is
        if (str_starts_with($this->profile_photo, 'http://') || str_starts_with($this->profile_photo, 'https://')) {
            return $this->profile_photo;
        }

        // Return relative storage path instead of absolute URL so client
        // can resolve it using its configured API base URL.
        // Example: '/storage/profile_photos/..jpg'
        $photo = ltrim($this->profile_photo, '/');
        // Avoid duplicating 'storage' if the stored path already contains it
        if (str_starts_with($photo, 'storage/')) {
            return '/' . $photo;
        }
        return '/storage/' . $photo;
    }
}
