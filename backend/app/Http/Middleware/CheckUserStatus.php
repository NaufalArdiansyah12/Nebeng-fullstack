<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;
use Illuminate\Support\Facades\DB;

class CheckUserStatus
{
    public function handle(Request $request, Closure $next): Response
    {
        $token = $request->bearerToken();

        if (!$token) {
            return $next($request);
        }

        $hashedToken = hash('sha256', $token);

        $apiToken = DB::table('api_tokens')
            ->where('token', $hashedToken)
            ->first();

        if (!$apiToken) {
            return $next($request);
        }

        $user = null;
        $status = null;
        $blockedReason = null;
        $blockedAt = null;

        /**
         * ================= USER BIASA =================
         */
        if (!empty($apiToken->user_id)) {
            $user = DB::table('users')
                ->where('id', $apiToken->user_id)
                ->first();

            if ($user) {
                // sesuaikan dengan kolom yang BENAR-BENAR ADA
                $status = $user->status ?? null;
                $blockedReason = $user->blocked_reason ?? null;
                $blockedAt = $user->blocked_at ?? null;
            }
        }

        /**
         * ================= POSMITRA =================
         */
        elseif (!empty($apiToken->posmitra_id)) {
            $user = DB::table('posmitra_users')
                ->where('id', $apiToken->posmitra_id)
                ->first();

            if ($user) {
                // POSMITRA SERING TIDAK PUNYA status
                // GANTI sesuai struktur tabel kamu
                $status = $user->status
                    ?? $user->verification_status
                    ?? null;

                $blockedReason = $user->blocked_reason ?? null;
                $blockedAt = $user->blocked_at ?? null;
            }
        }

        /**
         * ================= CEK BLOCKED =================
         */
        if ($status === 'blocked') {
            return response()->json([
                'success' => false,
                'message' => 'Akun Anda telah diblokir',
                'blocked' => true,
                'data' => [
                    'status' => 'blocked',
                    'reason' => $blockedReason ?? 'Tidak ada alasan yang diberikan',
                    'blocked_at' => $blockedAt,
                ]
            ], 403);
        }

        return $next($request);
    }
}