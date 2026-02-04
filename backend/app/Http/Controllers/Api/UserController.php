<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class UserController extends Controller
{
    /**
     * Display a listing of users.
     */
    public function index()
    {
        return response()->json([
            'success' => true,
            'message' => 'Data users berhasil diambil',
            'data' => [
                [
                    'id' => 1,
                    'name' => 'John Doe',
                    'email' => 'john@example.com',
                    'created_at' => now(),
                ],
                [
                    'id' => 2,
                    'name' => 'Jane Smith',
                    'email' => 'jane@example.com',
                    'created_at' => now(),
                ],
            ]
        ]);
    }

    /**
     * Display the specified user.
     */
    public function show($id)
    {
        $user = \App\Models\User::find($id);

        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => 'User tidak ditemukan',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'message' => 'Data user berhasil diambil',
            'data' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'phone' => $user->phone ?? null,
                'photo_url' => $user->photo_url ?? null,
                'profile_photo' => $user->profile_photo ?? null,
                'role' => $user->role ?? null,
                'created_at' => $user->created_at,
            ]
        ]);
    }

    /**
     * Store a newly created user.
     */
    public function store(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|email',
        ]);

        return response()->json([
            'success' => true,
            'message' => 'User berhasil dibuat',
            'data' => [
                'id' => rand(1, 100),
                'name' => $request->name,
                'email' => $request->email,
                'created_at' => now(),
            ]
        ], 201);
    }

    /**
     * Get balance for authenticated user.
     */
    public function getBalance(Request $request)
    {
        // Get authenticated user from bearer token
        $bearer = $request->bearerToken();
        if (!$bearer) {
            return response()->json([
                'success' => false,
                'message' => 'Token tidak ditemukan',
            ], 401);
        }

        // Try both hashed and plain token lookup (project uses both methods)
        $hashed = hash('sha256', $bearer);
        $apiToken = \App\Models\ApiToken::where('token', $hashed)
            ->orWhere('token', $bearer)
            ->first();
        
        if (!$apiToken) {
            return response()->json([
                'success' => false,
                'message' => 'Token tidak valid',
            ], 401);
        }

        $user = \App\Models\User::find($apiToken->user_id);

        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => 'User tidak ditemukan',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'message' => 'Saldo berhasil diambil',
            'data' => [
                'balance' => (float) $user->balance,
                'formatted_balance' => 'Rp ' . number_format($user->balance, 0, ',', '.'),
            ]
        ]);
    }
}
