<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Withdrawal extends Model
{
    protected $fillable = [
        'user_id',
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

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function processor(): BelongsTo
    {
        return $this->belongsTo(User::class, 'processed_by');
    }

    /**
     * Generate unique transaction ID
     */
    public static function generateTransactionId(): string
    {
        return 'WD' . date('YmdHis') . rand(1000, 9999);
    }

    /**
     * Get progress timeline
     */
    public function getProgressTimeline(): array
    {
        // If rejected, show rejection timeline
        if ($this->status === 'rejected') {
            return [
                [
                    'title' => 'Pengajuan Telah Diajukan',
                    'description' => 'Proses Pencairan dana sedang berlangsung dan akan dikonfirmasi dalam 3-5 hari kerja',
                    'date' => $this->submitted_at?->format('D, d M'),
                    'time' => $this->submitted_at?->format('H:i') . ' WIB',
                    'completed' => true,
                ],
                [
                    'title' => 'Pengajuan Ditolak',
                    'description' => $this->rejection_reason ?? 'Pengajuan pencairan dana Anda ditolak. Saldo telah dikembalikan ke akun Anda.',
                    'date' => $this->rejected_at?->format('D, d M'),
                    'time' => $this->rejected_at?->format('H:i') . ' WIB',
                    'completed' => true,
                ],
            ];
        }

        $timeline = [
            [
                'title' => 'Pengajuan Telah Diajukan',
                'description' => 'Proses Pencairan dana sedang berlangsung dan akan dikonfirmasi dalam 3-5 hari kerja',
                'date' => $this->submitted_at?->format('D, d M'),
                'time' => $this->submitted_at?->format('H:i') . ' WIB',
                'completed' => (bool) $this->submitted_at,
            ],
            [
                'title' => 'Memeriksa Pengajuan Anda',
                'description' => 'Santai dulu, Admin kami sedang memeriksa informasi yang telah Anda kirimkan',
                'date' => $this->verified_at?->format('D, d M'),
                'time' => $this->verified_at?->format('H:i') . ' WIB',
                'completed' => (bool) $this->verified_at,
            ],
            [
                'title' => 'Pengajuan Disetujui',
                'description' => 'Permintaan Pencairan dana Anda telah disetujui. Dana Anda akan segera ditransfer ke rekening Anda yang terdaftar',
                'date' => $this->approved_at?->format('D, d M'),
                'time' => $this->approved_at?->format('H:i') . ' WIB',
                'completed' => (bool) $this->approved_at,
            ],
            [
                'title' => 'Pencairan Sedang Dikirim',
                'description' => 'Pencairan dana Anda sedang diproses. Hanya berlatanan dana akan segera masuk ke rekening Anda',
                'date' => $this->processing_at?->format('D, d M'),
                'time' => $this->processing_at?->format('H:i') . ' WIB',
                'completed' => (bool) $this->processing_at,
            ],
            [
                'title' => 'Pencairan Telah DiTransfer',
                'description' => 'Pencairan dana Anda sebelah telah berhasil kami proses dan akan segera masuk ke rekening Anda. Terima kasih!',
                'date' => $this->completed_at?->format('D, d M'),
                'time' => $this->completed_at?->format('H:i') . ' WIB',
                'completed' => (bool) $this->completed_at,
            ],
        ];

        return $timeline;
    }

    /**
     * Get estimated completion time in days
     */
    public function getEstimatedDuration(): string
    {
        if ($this->status === 'completed') {
            return 'Selesai';
        }

        if ($this->status === 'rejected') {
            return 'Ditolak - Saldo Dikembalikan';
        }

        return 'Durasi Proses Refund';
    }
}
