<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;
use Illuminate\Support\Facades\DB;

class CheckUserStatus
{
    /**
     * Handle an incoming request.
     *
     * @param  \Closure(\Illuminate\Http\Request): (\Symfony\Component\HttpFoundation\Response)  $next
     */
    public function handle(Request $request, Closure $next): Response
    {
        // Get token from Authorization header
        $token = $request->bearerToken();
        
        if ($token) {
            // Hash the token to match database
            $hashedToken = hash('sha256', $token);
            
            // Get user from api_tokens table
            $apiToken = DB::table('api_tokens')
                ->where('token', $hashedToken)
                ->first();
            
            if ($apiToken && $apiToken->user_id) {
                // Get user status
                $user = DB::table('users')
                    ->where('id', $apiToken->user_id)
                    ->first();
                
                if ($user && $user->status === 'blocked') {
                    return response()->json([
                        'success' => false,
                        'message' => 'Akun Anda telah diblokir',
                        'blocked' => true,
                        'data' => [
                            'status' => 'blocked',
                            'reason' => $user->blocked_reason ?? 'Tidak ada alasan yang diberikan',
                            'blocked_at' => $user->blocked_at,
                        ]
                    ], 403);
                }
            }
        }
        
        return $next($request);
    }
}
