<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Carbon\Carbon;

class NotificationSeeder extends Seeder
{
    public function run()
    {
        // Get first admin user
        $adminId = DB::table('users')
            ->where('role', 'like', '%admin%')
            ->first()->id ?? 1;

        $notifications = [
            [
                'user_id' => $adminId,
                'type' => 'verification',
                'title' => 'Inosuke mendaftar sebagai mitra',
                'body' => 'Menunggu verifikasi dari admin',
                'icon' => 'user_plus',
                'data' => json_encode(['action_url' => '/mitra']),
                'is_read' => false,
                'created_at' => Carbon::now()->subHours(12),
                'updated_at' => Carbon::now()->subHours(12),
            ],
            [
                'user_id' => $adminId,
                'type' => 'account',
                'title' => 'Tanjiro merubah informasi akun',
                'body' => 'Pada halaman mitra',
                'icon' => 'user',
                'data' => json_encode(['action_url' => '/mitra']),
                'is_read' => false,
                'created_at' => Carbon::now()->subHours(23),
                'updated_at' => Carbon::now()->subHours(23),
            ],
            [
                'user_id' => $adminId,
                'type' => 'cancellation',
                'title' => 'Tanjiro membatalkan tebengan',
                'body' => 'Pada halaman pesanan',
                'icon' => 'x',
                'data' => json_encode(['action_url' => '/transaksi']),
                'is_read' => false,
                'created_at' => Carbon::now()->subHours(2),
                'updated_at' => Carbon::now()->subHours(2),
            ],
            [
                'user_id' => $adminId,
                'type' => 'report',
                'title' => 'Nezuko melakukan pelaporan mitra',
                'body' => 'Pada halaman laporan',
                'icon' => 'alert',
                'data' => json_encode(['action_url' => '/mitra']),
                'is_read' => false,
                'created_at' => Carbon::now()->subDays(10),
                'updated_at' => Carbon::now()->subDays(10),
            ],
        ];

        foreach ($notifications as $notification) {
            DB::table('notifications')->insert($notification);
        }
    }
}
