<?php

namespace App\Http\Controllers\Finance;

use App\Http\Controllers\Controller;
use App\Models\Notification;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class NotificationController extends Controller
{
    public function index(Request $request)
    {
        try {
            // Get logged in user dari localStorage
            $userStr = $request->header('X-User-Data');
            $userId = 3; // Default admin id
            
            if ($userStr) {
                $userData = json_decode($userStr, true);
                $userId = $userData['id'] ?? 3;
            }

            $notifications = Notification::where('user_id', $userId)
                ->orderBy('created_at', 'desc')
                ->limit(50)
                ->get()
                ->map(function ($notif) {
                    return [
                        'id' => $notif->id,
                        'type' => $notif->type,
                        'title' => $notif->title,
                        'message' => $notif->body,
                        'action_url' => $notif->data['action_url'] ?? null,
                        'is_read' => $notif->is_read,
                        'created_at' => $notif->created_at->toDateTimeString(),
                    ];
                });

            return response()->json([
                'success' => true,
                'data' => $notifications
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Terjadi kesalahan pada server',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    public function markAsRead(Request $request, $id)
    {
        try {
            $notification = Notification::findOrFail($id);
            $notification->update([
                'is_read' => true,
                'read_at' => now()
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Notifikasi berhasil ditandai sebagai dibaca'
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Terjadi kesalahan pada server',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    public function markAllAsRead(Request $request)
    {
        try {
            $userId = $request->user_id ?? 4;
            
            Notification::where('user_id', $userId)
                ->where('is_read', false)
                ->update([
                    'is_read' => true,
                    'read_at' => now()
                ]);

            return response()->json([
                'success' => true,
                'message' => 'Semua notifikasi berhasil ditandai sebagai dibaca'
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Terjadi kesalahan pada server',
                'error' => $e->getMessage()
            ], 500);
        }
    }
}
