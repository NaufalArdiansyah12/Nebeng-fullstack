<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use App\Models\User;

class AuthenticateWithApiToken
{
    /**
     * Handle an incoming request.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \Closure  $next
     * @return mixed
     */
    public function handle(Request $request, Closure $next)
    {
        $token = $request->bearerToken();
        
        \Log::info('AuthenticateWithApiToken: Checking token', [
            'has_token' => $token !== null,
            'token_length' => $token ? strlen($token) : 0,
            'token_preview' => $token ? substr($token, 0, 10) . '...' : null,
        ]);

        if (!$token) {
            \Log::warning('AuthenticateWithApiToken: No token provided');
            return response()->json([
                'success' => false,
                'message' => 'Unauthorized - No token provided'
            ], 401);
        }

        // Hash the token to match database (same as CheckUserStatus middleware)
        $hashedToken = hash('sha256', $token);
        
        \Log::info('AuthenticateWithApiToken: Hashed token', [
            'hashed_preview' => substr($hashedToken, 0, 10) . '...',
        ]);

        // Check token in api_tokens table
        $apiToken = DB::table('api_tokens')
            ->where('token', $hashedToken)
            ->first();

        \Log::info('AuthenticateWithApiToken: Token lookup', [
            'found' => $apiToken !== null,
            'user_id' => $apiToken ? $apiToken->user_id : null,
        ]);

        if (!$apiToken) {
            \Log::warning('AuthenticateWithApiToken: Invalid token - not found in database');
            return response()->json([
                'success' => false,
                'message' => 'Unauthorized - Invalid token'
            ], 401);
        }

        // Get the user
        $user = User::find($apiToken->user_id);

        if (!$user) {
            \Log::warning('AuthenticateWithApiToken: User not found', [
                'user_id' => $apiToken->user_id,
            ]);
            return response()->json([
                'success' => false,
                'message' => 'Unauthorized - User not found'
            ], 401);
        }

        \Log::info('AuthenticateWithApiToken: User authenticated', [
            'user_id' => $user->id,
            'user_email' => $user->email,
            'user_role' => $user->role,
        ]);

        // Set the authenticated user
        $request->setUserResolver(function () use ($user) {
            return $user;
        });

        return $next($request);
    }
}
