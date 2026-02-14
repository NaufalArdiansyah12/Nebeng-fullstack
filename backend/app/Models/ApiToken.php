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

    protected $dates = ['expires_at'];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function posMitraUser()
    {
        return $this->belongsTo(PosMitraUser::class, 'posmitra_id');
    }

    /**
     * Get the actual user model based on user_type
     */
    public function getAuthenticatedUser()
    {
        if ($this->user_type === 'posmitra') {
            return $this->posMitraUser;
        }
        return $this->user;
    }
}
