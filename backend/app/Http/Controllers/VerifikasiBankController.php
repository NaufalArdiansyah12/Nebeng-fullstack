<?php

namespace App\Http\Controllers;

use App\Models\VerifikasiBankMitra;
use App\Models\MitraVerifikasi;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;

class VerifikasiBankController extends Controller
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

        $verification = VerifikasiBankMitra::where('user_id', $apiToken->user_id)->first();

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
            'bank_account_number' => 'required|string|max:255',
            'bank_account_name' => 'required|string|max:255',
            'bank_name' => 'required|string|max:255',
            'bank_account_photo' => 'required|image|mimes:jpeg,png,jpg|max:5120',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        $existing = VerifikasiBankMitra::where('user_id', $apiToken->user_id)->first();
        if ($existing) {
            return response()->json([
                'success' => false,
                'message' => 'Bank verification already exists'
            ], 400);
        }

        $photoPath = null;
        if ($request->hasFile('bank_account_photo')) {
            $photoPath = $request->file('bank_account_photo')->store('verifikasi/bank', 'public');
        }

        $verification = VerifikasiBankMitra::create([
            'user_id' => $apiToken->user_id,
            'bank_account_number' => $request->bank_account_number,
            'bank_account_name' => $request->bank_account_name,
            'bank_name' => $request->bank_name,
            'bank_account_photo' => $photoPath,
            'status' => 'pending',
        ]);

            // Ensure MitraVerifikasi links to this bank verification
            MitraVerifikasi::updateOrCreate(
                ['user_id' => $apiToken->user_id],
                ['bank_verification_id' => $verification->id]
            );

        return response()->json([
            'success' => true,
            'message' => 'Bank verification submitted successfully',
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
            'bank_account_number' => 'required|string|max:255',
            'bank_account_name' => 'required|string|max:255',
            'bank_name' => 'required|string|max:255',
            'bank_account_photo' => 'nullable|image|mimes:jpeg,png,jpg|max:5120',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        $verification = VerifikasiBankMitra::where('user_id', $apiToken->user_id)->first();

        if (!$verification) {
            return response()->json([
                'success' => false,
                'message' => 'Bank verification not found'
            ], 404);
        }

        $updateData = [
            'bank_account_number' => $request->bank_account_number,
            'bank_account_name' => $request->bank_account_name,
            'bank_name' => $request->bank_name,
            'status' => 'pending',
        ];

        if ($request->hasFile('bank_account_photo')) {
            if ($verification->bank_account_photo) {
                Storage::disk('public')->delete($verification->bank_account_photo);
            }
            $photoPath = $request->file('bank_account_photo')->store('verifikasi/bank', 'public');
            $updateData['bank_account_photo'] = $photoPath;
        }

        $verification->update($updateData);

            // Ensure MitraVerifikasi links to this bank verification
            MitraVerifikasi::updateOrCreate(
                ['user_id' => $apiToken->user_id],
                ['bank_verification_id' => $verification->id]
            );

        return response()->json([
            'success' => true,
            'message' => 'Bank verification updated successfully',
            'data' => $verification
        ]);
    }
}
