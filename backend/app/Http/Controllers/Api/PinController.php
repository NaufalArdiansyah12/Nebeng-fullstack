<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ApiToken;
use App\Models\User;
use Illuminate\Http\Request;

class PinController extends Controller
{
    /**
     * Check if user has a PIN
     */
    public function checkPin(Request $request)
    {
        $user = $this->getUserFromToken($request);
        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => 'User tidak ditemukan',
            ], 401);
        }

        return response()->json([
            'success' => true,
            'has_pin' => !empty($user->pin),
        ]);
    }

    /**
     * Create or update PIN
     */
    public function createPin(Request $request)
    {
        $request->validate([
            'pin' => 'required|string|size:64', // SHA-256 hash is 64 characters
        ]);

        $user = $this->getUserFromToken($request);
        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => 'User tidak ditemukan',
            ], 401);
        }

        // Store the already hashed PIN from frontend
        $user->pin = $request->pin;
        $user->save();

        return response()->json([
            'success' => true,
            'message' => 'PIN berhasil dibuat',
        ]);
    }

    /**
     * Verify PIN
     */
    public function verifyPin(Request $request)
    {
        $request->validate([
            'pin' => 'required|string|size:64',
        ]);

        $user = $this->getUserFromToken($request);
        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => 'User tidak ditemukan',
            ], 401);
        }

        if (empty($user->pin)) {
            return response()->json([
                'success' => false,
                'message' => 'PIN belum dibuat',
            ], 400);
        }

        // Compare hashed PINs
        if ($user->pin === $request->pin) {
            return response()->json([
                'success' => true,
                'message' => 'PIN valid',
            ]);
        }

        return response()->json([
            'success' => false,
            'message' => 'PIN tidak valid',
        ], 400);
    }

    /**
     * Update PIN (requires old PIN verification)
     */
    public function updatePin(Request $request)
    {
        $request->validate([
            'old_pin' => 'required|string|size:64',
            'new_pin' => 'required|string|size:64',
        ]);

        $user = $this->getUserFromToken($request);
        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => 'User tidak ditemukan',
            ], 401);
        }

        if (empty($user->pin)) {
            return response()->json([
                'success' => false,
                'message' => 'PIN belum dibuat',
            ], 400);
        }

        // Verify old PIN
        if ($user->pin !== $request->old_pin) {
            return response()->json([
                'success' => false,
                'message' => 'PIN lama tidak valid',
            ], 400);
        }

        // Update to new PIN
        $user->pin = $request->new_pin;
        $user->save();

        return response()->json([
            'success' => true,
            'message' => 'PIN berhasil diubah',
        ]);
    }

    /**
     * Get user from bearer token
     */
    private function getUserFromToken(Request $request)
    {
        $bearer = $request->bearerToken();
        if (!$bearer) {
            return null;
        }

        $hashed = hash('sha256', $bearer);
        $apiToken = ApiToken::where('token', $hashed)
            ->where('expires_at', '>', now())
            ->first();

        if (!$apiToken) {
            return null;
        }

        return User::find($apiToken->user_id);
    }
}
