<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use App\Models\User;
use App\Models\ApiToken;
use App\Enums\UserRole;

class AdminAuthMiddleware
{
    /**
     * Handle an incoming request.
     */
    public function handle(Request $request, Closure $next)
    {
        $token = $request->bearerToken();

        if (!$token) {
            return response()->json([
                'success' => false,
                'message' => 'Token tidak ditemukan'
            ], 401);
        }

        // Cek token di api_tokens table
        $apiToken = ApiToken::where('token', $token)
                           ->where('expires_at', '>', now())
                           ->first();

        if (!$apiToken) {
            return response()->json([
                'success' => false,
                'message' => 'Token tidak valid atau sudah expired'
            ], 401);
        }
        
        // Ambil user dari token
        $user = User::where('id', $apiToken->user_id)
                    ->where('status', 'active')
                    ->first();

        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => 'User tidak ditemukan'
            ], 401);
        }

        // Cek apakah role adalah admin atau superadmin
        if ($user->role !== UserRole::ADMIN && $user->role !== UserRole::SUPERADMIN) {
            return response()->json([
                'success' => false,
                'message' => 'User bukan admin'
            ], 401);
        }

        // Set user ke request
        $request->merge(['user' => $user]);
        $request->setUserResolver(function () use ($user) {
            return $user;
        });

        return $next($request);
    }
}
