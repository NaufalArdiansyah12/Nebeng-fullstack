<?php

namespace App\Services;

use App\Models\PosMitraUser;
use Illuminate\Support\Facades\Log;

/**
 * Service untuk mengirim notifikasi FCM ke user PosMitra (push notification).
 */
class PosMitraNotificationService
{
    /**
     * Kirim notifikasi FCM saat penarikan disetujui
     */
    public static function sendWithdrawalApprovedNotification($withdrawal, PosMitraUser $posmitra): void
    {
        Log::info('[FCM PosMitra] sendWithdrawalApprovedNotification', [
            'posmitra_id' => $posmitra->id,
            'withdrawal_id' => $withdrawal->id ?? null,
            'has_fcm_token' => !empty($posmitra->fcm_token),
        ]);

        if (empty($posmitra->fcm_token)) {
            Log::warning('[FCM PosMitra] Skipping withdrawal approved - no FCM token', [
                'posmitra_id' => $posmitra->id,
                'withdrawal_id' => $withdrawal->id ?? null,
            ]);
            return;
        }

        $amount = number_format($withdrawal->amount ?? 0, 0, ',', '.');
        $title = "Penarikan Disetujui ✓";
        $body = "Pengajuan penarikan saldo Rp {$amount} telah disetujui. Dana akan diproses dan ditransfer ke rekening Anda.";
        $data = [
            'type' => 'withdrawal_approved',
            'withdrawal_id' => (string) ($withdrawal->id ?? ''),
            'amount' => (string) ($withdrawal->amount ?? ''),
        ];

        self::sendFcm($posmitra->fcm_token, $title, $body, $data, 'withdrawal_approved');
    }

    /**
     * Kirim notifikasi FCM saat penarikan ditolak
     */
    public static function sendWithdrawalRejectedNotification($withdrawal, PosMitraUser $posmitra, string $reason = ''): void
    {
        Log::info('[FCM PosMitra] sendWithdrawalRejectedNotification', [
            'posmitra_id' => $posmitra->id,
            'withdrawal_id' => $withdrawal->id ?? null,
            'has_fcm_token' => !empty($posmitra->fcm_token),
        ]);

        if (empty($posmitra->fcm_token)) {
            Log::warning('[FCM PosMitra] Skipping withdrawal rejected - no FCM token', [
                'posmitra_id' => $posmitra->id,
                'withdrawal_id' => $withdrawal->id ?? null,
            ]);
            return;
        }

        $amount = number_format($withdrawal->amount ?? 0, 0, ',', '.');
        $reasonText = $reason ? " Alasan: {$reason}." : '';
        $title = "Penarikan Ditolak";
        $body = "Pengajuan penarikan saldo Rp {$amount} ditolak.{$reasonText} Silakan periksa data atau hubungi admin.";
        $data = [
            'type' => 'withdrawal_rejected',
            'withdrawal_id' => (string) ($withdrawal->id ?? ''),
            'amount' => (string) ($withdrawal->amount ?? ''),
            'rejection_reason' => $reason,
        ];

        self::sendFcm($posmitra->fcm_token, $title, $body, $data, 'withdrawal_rejected');
    }

    /**
     * Kirim notifikasi FCM saat penarikan sedang diproses
     */
    public static function sendWithdrawalProcessingNotification($withdrawal, PosMitraUser $posmitra): void
    {
        Log::info('[FCM PosMitra] sendWithdrawalProcessingNotification', [
            'posmitra_id' => $posmitra->id,
            'withdrawal_id' => $withdrawal->id ?? null,
            'has_fcm_token' => !empty($posmitra->fcm_token),
        ]);

        if (empty($posmitra->fcm_token)) {
            Log::warning('[FCM PosMitra] Skipping withdrawal processing - no FCM token', [
                'posmitra_id' => $posmitra->id,
                'withdrawal_id' => $withdrawal->id ?? null,
            ]);
            return;
        }

        $amount = number_format($withdrawal->amount ?? 0, 0, ',', '.');
        $title = "Penarikan Diproses";
        $body = "Dana Rp {$amount} sedang diproses untuk transfer ke rekening Anda. Mohon tunggu.";
        $data = [
            'type' => 'withdrawal_processing',
            'withdrawal_id' => (string) ($withdrawal->id ?? ''),
            'amount' => (string) ($withdrawal->amount ?? ''),
        ];

        self::sendFcm($posmitra->fcm_token, $title, $body, $data, 'withdrawal_processing');
    }

    /**
     * Kirim notifikasi FCM saat penarikan selesai (dana ditransfer)
     */
    public static function sendWithdrawalCompletedNotification($withdrawal, PosMitraUser $posmitra): void
    {
        Log::info('[FCM PosMitra] sendWithdrawalCompletedNotification', [
            'posmitra_id' => $posmitra->id,
            'withdrawal_id' => $withdrawal->id ?? null,
            'has_fcm_token' => !empty($posmitra->fcm_token),
        ]);

        if (empty($posmitra->fcm_token)) {
            Log::warning('[FCM PosMitra] Skipping withdrawal completed - no FCM token', [
                'posmitra_id' => $posmitra->id,
                'withdrawal_id' => $withdrawal->id ?? null,
            ]);
            return;
        }

        $amount = number_format($withdrawal->total_amount ?? $withdrawal->amount ?? 0, 0, ',', '.');
        $bankName = $withdrawal->bank_name ?? 'rekening';
        $title = "Penarikan Berhasil! 💰";
        $body = "Dana Rp {$amount} telah ditransfer ke {$bankName}. Dana akan masuk dalam 1-2 hari kerja.";
        $data = [
            'type' => 'withdrawal_completed',
            'withdrawal_id' => (string) ($withdrawal->id ?? ''),
            'amount' => (string) ($withdrawal->total_amount ?? $withdrawal->amount ?? ''),
        ];

        self::sendFcm($posmitra->fcm_token, $title, $body, $data, 'withdrawal_completed');
    }

    protected static function sendFcm(string $token, string $title, string $body, array $data, string $typeLabel = 'unknown'): void
    {
        try {
            Log::info('[FCM PosMitra] Sending FCM', [
                'type' => $typeLabel,
                'title' => $title,
                'token_preview' => substr($token, 0, 20) . '...',
            ]);
            $sent = FcmService::sendToToken($token, $title, $body, $data);
            if ($sent) {
                Log::info('[FCM PosMitra] FCM sent OK', ['type' => $typeLabel]);
            } else {
                Log::warning('[FCM PosMitra] FCM send failed', ['type' => $typeLabel]);
            }
        } catch (\Exception $e) {
            Log::error('[FCM PosMitra] FCM exception: ' . $e->getMessage(), ['type' => $typeLabel]);
        }
    }
}
