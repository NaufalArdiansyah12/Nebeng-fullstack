<?php

namespace App\Http\Controllers;

use App\Models\VerifikasiSkckMitra;
use App\Models\MitraVerifikasi;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;

class VerifikasiSkckController extends Controller
{
    public function show(Request $request)
    {
        $bearer = $request->bearerToken();
        if (!$bearer) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthorized',
            ], 401);
        }

        $hashed = hash('sha256', $bearer);
        $apiToken = \App\Models\ApiToken::where('token', $hashed)->first();
        
        if (!$apiToken) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid token',
            ], 401);
        }

        $verification = VerifikasiSkckMitra::where('user_id', $apiToken->user_id)->first();

        return response()->json([
            'success' => true,
            'data' => $verification
        ]);
    }

    public function store(Request $request)
    {
        $bearer = $request->bearerToken();
        if (!$bearer) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthorized',
            ], 401);
        }

        $hashed = hash('sha256', $bearer);
        $apiToken = \App\Models\ApiToken::where('token', $hashed)->first();
        
        if (!$apiToken) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid token',
            ], 401);
        }

        $validator = Validator::make($request->all(), [
            'skck_number' => 'required|string|max:255',
            'skck_name' => 'required|string|max:255',
            'skck_expiry_date' => 'required|date|after:today',
            'skck_photo' => 'required|image|mimes:jpeg,png,jpg|max:5120',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        $existing = VerifikasiSkckMitra::where('user_id', $apiToken->user_id)->first();
        if ($existing) {
            return response()->json([
                'success' => false,
                'message' => 'SKCK verification already exists'
            ], 400);
        }

        $photoPath = null;
        if ($request->hasFile('skck_photo')) {
            $photoPath = $request->file('skck_photo')->store('verifikasi/skck', 'public');
        }

        $verification = VerifikasiSkckMitra::create([
            'user_id' => $apiToken->user_id,
            'skck_number' => $request->skck_number,
            'skck_name' => $request->skck_name,
            'skck_expiry_date' => $request->skck_expiry_date,
            'skck_photo' => $photoPath,
            'status' => 'pending',
        ]);

        return response()->json([
            'success' => true,
            'message' => 'SKCK verification submitted successfully',
            'data' => $verification
        ], 201);
    }

    public function update(Request $request)
    {
        $bearer = $request->bearerToken();
        if (!$bearer) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthorized',
            ], 401);
        }

        $hashed = hash('sha256', $bearer);
        $apiToken = \App\Models\ApiToken::where('token', $hashed)->first();
        
        if (!$apiToken) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid token',
            ], 401);
        }

        $validator = Validator::make($request->all(), [
            'skck_number' => 'required|string|max:255',
            'skck_name' => 'required|string|max:255',
            'skck_expiry_date' => 'required|date|after:today',
            'skck_photo' => 'nullable|image|mimes:jpeg,png,jpg|max:5120',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        $verification = VerifikasiSkckMitra::where('user_id', $apiToken->user_id)->first();

        if (!$verification) {
            return response()->json([
                'success' => false,
                'message' => 'SKCK verification not found'
            ], 404);
        }

        if ($request->hasFile('skck_photo')) {
            if ($verification->skck_photo) {
                Storage::disk('public')->delete($verification->skck_photo);
            }
            $photoPath = $request->file('skck_photo')->store('verifikasi/skck', 'public');
            $verification->skck_photo = $photoPath;
        }

        $verification->update([
            'skck_number' => $request->skck_number,
            'skck_name' => $request->skck_name,
            'skck_expiry_date' => $request->skck_expiry_date,
            'status' => 'pending',
        ]);

        return response()->json([
            'success' => true,
            'message' => 'SKCK verification updated successfully',
            'data' => $verification
        ]);
    }
}
