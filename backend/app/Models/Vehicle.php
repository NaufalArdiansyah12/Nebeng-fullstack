<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Vehicle extends Model
{
    use HasFactory;

    // Vehicles table has been renamed to `kendaraan_mitra`.
    protected $table = 'kendaraan_mitra';

    protected $fillable = [
        'user_id',
        'vehicle_type',
        'name',
        'plate_number',
        'brand',
        'model',
        'color',
        'year',
        'is_active',
        'status',
        'rejection_reason',
        'approved_at',
        'approved_by',
        'deletion_status',
        'deletion_reason',
        'deletion_requested_at',
        'deletion_approved_at',
        'deletion_approved_by',
    ];

    protected $casts = [
        'is_active' => 'boolean',
        'year' => 'integer',
        'approved_at' => 'datetime',
        'deletion_requested_at' => 'datetime',
        'deletion_approved_at' => 'datetime',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function rides()
    {
        return $this->hasMany(Ride::class);
    }

    public function approvedBy()
    {
        return $this->belongsTo(User::class, 'approved_by');
    }

    public function deletionApprovedBy()
    {
        return $this->belongsTo(User::class, 'deletion_approved_by');
    }
}
