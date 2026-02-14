<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class UserManagementController extends Controller
{
    /**
     * Block a user
     */
    public function blockUser(Request $request, $userId)
    {
        $validator = Validator::make($request->all(), [
            'reason' => 'required|string|max:1000',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validasi gagal',
                'errors' => $validator->errors(),
            ], 422);
        }

        $user = User::find($userId);

        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => 'User tidak ditemukan',
            ], 404);
        }

        // Don't allow blocking admin or finance users
        if (in_array($user->role->value ?? $user->role, ['admin', 'finance'])) {
            return response()->json([
                'success' => false,
                'message' => 'Tidak dapat memblokir user dengan role admin atau finance',
            ], 403);
        }

        $user->update([
            'status' => 'blocked',
            'blocked_reason' => $request->reason,
            'blocked_at' => now(),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'User berhasil diblokir',
            'data' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'status' => $user->status,
                'blocked_reason' => $user->blocked_reason,
                'blocked_at' => $user->blocked_at,
            ]
        ]);
    }

    /**
     * Unblock a user
     */
    public function unblockUser($userId)
    {
        $user = User::find($userId);

        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => 'User tidak ditemukan',
            ], 404);
        }

        $user->update([
            'status' => 'active',
            'blocked_reason' => null,
            'blocked_at' => null,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'User berhasil dibuka blokirnya',
            'data' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'status' => $user->status,
            ]
        ]);
    }

    /**
     * Get user block status
     */
    public function getUserStatus($userId)
    {
        $user = User::find($userId);

        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => 'User tidak ditemukan',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'data' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'role' => $user->role,
                'status' => $user->status ?? 'active',
                'blocked_reason' => $user->blocked_reason,
                'blocked_at' => $user->blocked_at,
            ]
        ]);
    }

    /**
     * Get all blocked users
     */
    public function getBlockedUsers(Request $request)
    {
        $perPage = $request->input('per_page', 15);
        
        $users = User::where('status', 'blocked')
            ->orderBy('blocked_at', 'desc')
            ->paginate($perPage);

        return response()->json([
            'success' => true,
            'data' => $users->items(),
            'pagination' => [
                'current_page' => $users->currentPage(),
                'per_page' => $users->perPage(),
                'total' => $users->total(),
                'last_page' => $users->lastPage(),
            ]
        ]);
    }
}
