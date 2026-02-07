<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class WithdrawalPosmitra extends Model
{
    protected $table = 'withdrawal_posmitra';

    protected $fillable = [
        'posmitra_id',
        'transaction_id',
        'amount',
        'admin_fee',
        'total_amount',
        'bank_name',
        'bank_account_number',
        'bank_account_name',
        'status',
        'submitted_at',
        'verified_at',
        'approved_at',
        'processing_at',
        'completed_at',
        'rejected_at',
        'rejection_reason',
        'notes',
        'processed_by',
    ];

    protected $casts = [
        'amount' => 'decimal:2',
        'admin_fee' => 'decimal:2',
        'total_amount' => 'decimal:2',
        'submitted_at' => 'datetime',
        'verified_at' => 'datetime',
        'approved_at' => 'datetime',
        'processing_at' => 'datetime',
        'completed_at' => 'datetime',
        'rejected_at' => 'datetime',
    ];

    public function posmitra(): BelongsTo
    {
        return $this->belongsTo(PosMitraUser::class, 'posmitra_id');
    }

    public function processor(): BelongsTo
    {
        return $this->belongsTo(User::class, 'processed_by');
    }
}
