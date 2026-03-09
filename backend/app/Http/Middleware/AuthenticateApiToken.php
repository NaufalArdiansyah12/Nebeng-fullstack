<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;
use App\Models\User;
use Illuminate\Support\Facades\DB;

class AuthenticateApiToken
{
    /**
     * Handle an incoming request.
     *
     * @param  \Closure(\Illuminate\Http\Request): (\Symfony\Component\HttpFoundation\Response)  $next
     */
    public function handle(Request $request, Closure $next): Response
    {
        $token = $request->bearerToken();

        if (!$token) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthenticated - No token provided'
            ], 401);
        }

        // Find user by token in api_tokens table
        $apiToken = DB::table('api_tokens')
            ->where('token', $token)
            ->first();

        if (!$apiToken) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthenticated - Invalid token'
            ], 401);
        }

        // Get the user
        $user = User::find($apiToken->user_id);

        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthenticated - User not found'
            ], 401);
        }

        // Set the authenticated user
        $request->setUserResolver(function () use ($user) {
            return $user;
        });

        return $next($request);
    }
}
