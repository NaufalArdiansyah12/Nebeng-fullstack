<?php

namespace App\Services;

use App\Models\Notification;
use Illuminate\Support\Facades\DB;

class NotificationService
{
    /**
     * Create notification for finance admin when new refund is submitted
     */
    public static function createRefundNotification($refund)
    {
        // Get all finance admins
        $financeAdmins = DB::table('users')
            ->where('role', 'finance')
            ->get();

        foreach ($financeAdmins as $admin) {
            Notification::create([
                'user_id' => $admin->id,
                'type' => 'refund',
                'title' => 'Permintaan Refund Baru',
                'body' => "Refund baru dari {$refund->customer_name} sebesar Rp " . number_format($refund->refund_amount, 0, ',', '.'),
                'icon' => 'refund',
                'booking_id' => $refund->booking_id,
                'booking_number' => $refund->booking_id,
                'data' => [
                    'refund_id' => $refund->id,
                    'action_url' => "/refund/{$refund->id}",
                ],
                'is_read' => false,
            ]);
        }
    }

    /**
     * Create notification for finance admin when new withdrawal is submitted
     */
    public static function createWithdrawalNotification($withdrawal, $type = 'mitra')
    {
        $financeAdmins = DB::table('users')
            ->where('role', 'finance')
            ->get();

        foreach ($financeAdmins as $admin) {
            Notification::create([
                'user_id' => $admin->id,
                'type' => 'withdrawal',
                'title' => 'Permintaan Penarikan Dana Baru',
                'body' => "Penarikan dana {$type} sebesar Rp " . number_format($withdrawal->amount, 0, ',', '.') . " dari {$withdrawal->user_name}",
                'icon' => 'withdrawal',
                'data' => [
                    'withdrawal_id' => $withdrawal->id,
                    'action_url' => "/withdrawals/{$withdrawal->id}",
                ],
                'is_read' => false,
            ]);
        }
    }

    /**
     * Create notification for new mitra registration
     */
    public static function createMitraRegistrationNotification($user)
    {
        $financeAdmins = DB::table('users')
            ->where('role', 'finance')
            ->get();

        foreach ($financeAdmins as $admin) {
            Notification::create([
                'user_id' => $admin->id,
                'type' => 'verification',
                'title' => "{$user->name} mendaftar sebagai mitra",
                'body' => "Menunggu verifikasi dari admin",
                'icon' => 'user_plus',
                'data' => [
                    'user_id' => $user->id,
                    'action_url' => "/mitra/{$user->id}",
                ],
                'is_read' => false,
            ]);
        }
    }

    /**
     * Create notification for booking cancellation
     */
    public static function createCancellationNotification($booking, $userName)
    {
        $financeAdmins = DB::table('users')
            ->where('role', 'finance')
            ->get();

        foreach ($financeAdmins as $admin) {
            Notification::create([
                'user_id' => $admin->id,
                'type' => 'cancellation',
                'title' => "{$userName} membatalkan tebengan",
                'body' => "Pada halaman pesanan",
                'icon' => 'x',
                'booking_id' => $booking->id,
                'data' => [
                    'booking_id' => $booking->id,
                    'action_url' => "/transaksi",
                ],
                'is_read' => false,
            ]);
        }
    }

    /**
     * Create notification for new transaction/payment
     */
    public static function createTransactionNotification($payment)
    {
        $financeAdmins = DB::table('users')
            ->where('role', 'finance')
            ->get();

        foreach ($financeAdmins as $admin) {
            Notification::create([
                'user_id' => $admin->id,
                'type' => 'transaction',
                'title' => 'Transaksi Baru',
                'body' => "Pembayaran baru sebesar Rp " . number_format($payment->total_amount, 0, ',', '.'),
                'icon' => 'receipt',
                'data' => [
                    'payment_id' => $payment->id,
                    'action_url' => "/transaksi",
                ],
                'is_read' => false,
            ]);
        }
    }

    /**
     * Get unread notifications count for user
     */
    public static function getUnreadCount($userId)
    {
        return Notification::where('user_id', $userId)
            ->where('is_read', false)
            ->count();
    }

    /**
     * Get latest notifications for user
     */
    public static function getLatestNotifications($userId, $limit = 10)
    {
        return Notification::where('user_id', $userId)
            ->orderBy('created_at', 'desc')
            ->limit($limit)
            ->get();
    }
}
