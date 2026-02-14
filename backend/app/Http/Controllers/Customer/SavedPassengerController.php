<?php

namespace App\Http\Controllers\Customer;

use App\Http\Controllers\Controller;
use App\Models\SavedPassenger;
use App\Models\ApiToken;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class SavedPassengerController extends Controller
{
    /**
     * Get all saved passengers for authenticated user
     */
    public function index(Request $request)
    {
        $bearer = $request->bearerToken();
        if (!$bearer) {
            return response()->json([
                'success' => false,
                'message' => 'Token tidak ditemukan',
            ], 401);
        }

        // Try both hashed and plain token lookup
        $hashed = hash('sha256', $bearer);
        $apiToken = ApiToken::where('token', $hashed)
            ->orWhere('token', $bearer)
            ->first();
        
        if (!$apiToken) {
            return response()->json([
                'success' => false,
                'message' => 'Token tidak valid',
            ], 401);
        }

        $passengers = SavedPassenger::where('user_id', $apiToken->user_id)
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json([
            'success' => true,
            'message' => 'Data penumpang berhasil diambil',
            'data' => $passengers,
        ]);
    }

    /**
     * Store a new saved passenger
     */
    public function store(Request $request)
    {
        $bearer = $request->bearerToken();
        if (!$bearer) {
            return response()->json([
                'success' => false,
                'message' => 'Token tidak ditemukan',
            ], 401);
        }

        $hashed = hash('sha256', $bearer);
        $apiToken = ApiToken::where('token', $hashed)
            ->orWhere('token', $bearer)
            ->first();
        
        if (!$apiToken) {
            return response()->json([
                'success' => false,
                'message' => 'Token tidak valid',
            ], 401);
        }

        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'phone' => 'required|string|max:20',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validasi gagal',
                'errors' => $validator->errors(),
            ], 422);
        }

        // Check for duplicate
        $exists = SavedPassenger::where('user_id', $apiToken->user_id)
            ->where('name', $request->name)
            ->where('phone', $request->phone)
            ->exists();

        if ($exists) {
            return response()->json([
                'success' => false,
                'message' => 'Penumpang sudah tersimpan',
            ], 409);
        }

        $passenger = SavedPassenger::create([
            'user_id' => $apiToken->user_id,
            'name' => $request->name,
            'phone' => $request->phone,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Penumpang berhasil disimpan',
            'data' => $passenger,
        ], 201);
    }

    /**
     * Delete a saved passenger
     */
    public function destroy(Request $request, $id)
    {
        $bearer = $request->bearerToken();
        if (!$bearer) {
            return response()->json([
                'success' => false,
                'message' => 'Token tidak ditemukan',
            ], 401);
        }

        $hashed = hash('sha256', $bearer);
        $apiToken = ApiToken::where('token', $hashed)
            ->orWhere('token', $bearer)
            ->first();
        
        if (!$apiToken) {
            return response()->json([
                'success' => false,
                'message' => 'Token tidak valid',
            ], 401);
        }

        $passenger = SavedPassenger::where('id', $id)
            ->where('user_id', $apiToken->user_id)
            ->first();

        if (!$passenger) {
            return response()->json([
                'success' => false,
                'message' => 'Penumpang tidak ditemukan',
            ], 404);
        }

        $passenger->delete();

        return response()->json([
            'success' => true,
            'message' => 'Penumpang berhasil dihapus',
        ]);
    }
}
