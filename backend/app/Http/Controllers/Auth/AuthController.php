<?php

namespace App\Http\Controllers\Auth;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use App\Models\User;

class AuthController extends Controller
{
    /**
     * Handle API login and return token + redirect URL based on role.
     */
    public function login(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
            'password' => 'required|string',
        ]);

        $user = User::where('email', $request->email)->first();

        if (! $user || ! Hash::check($request->password, $user->password)) {
            return response()->json([
                'success' => false,
                'message' => 'Credentials not match'
            ], 401);
        }

        $token = $user->createToken('api-token')->plainTextToken;

        // Determine redirect URL for front-end
        $redirectUrl = '/';
        if ($user->role === 'customer') {
            $redirectUrl = '/customer/home';
        } elseif ($user->role === 'mitra') {
            $redirectUrl = '/mitra/home';
        } 

        return response()->json([
            'success' => true,
            'message' => 'Login successful',
            'data' => [
                'user' => [
                    'id' => $user->id,
                    'name' => $user->name,
                    'email' => $user->email,
                    'role' => $user->role,
                ],
                'token' => $token,
                'redirect_url' => $redirectUrl,
            ]
        ]);
    }
}