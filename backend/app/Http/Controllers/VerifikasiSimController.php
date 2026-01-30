<?php

namespace App\Http\Controllers;

use App\Models\VerifikasiSimMitra;
use App\Models\MitraVerifikasi;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;

class VerifikasiSimController extends Controller
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

        $verification = VerifikasiSimMitra::where('user_id', $apiToken->user_id)->first();

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
            'sim_number' => 'required|string|max:255',
            'sim_type' => 'required|in:A,B1,B2,C',
            'sim_expiry_date' => 'required|date|after:today',
            'sim_photo' => 'required|image|mimes:jpeg,png,jpg|max:5120',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        $existing = VerifikasiSimMitra::where('user_id', $apiToken->user_id)->first();
        if ($existing) {
            return response()->json([
                'success' => false,
                'message' => 'SIM verification already exists'
            ], 400);
        }

        $photoPath = null;
        if ($request->hasFile('sim_photo')) {
            $photoPath = $request->file('sim_photo')->store('verifikasi/sim', 'public');
        }

        $verification = VerifikasiSimMitra::create([
            'user_id' => $apiToken->user_id,
            'sim_number' => $request->sim_number,
            'sim_type' => $request->sim_type,
            'sim_expiry_date' => $request->sim_expiry_date,
            'sim_photo' => $photoPath,
            'status' => 'pending',
        ]);

            // Ensure MitraVerifikasi links to this sim verification
            MitraVerifikasi::updateOrCreate(
                ['user_id' => $apiToken->user_id],
                ['sim_verification_id' => $verification->id]
            );

        return response()->json([
            'success' => true,
            'message' => 'SIM verification submitted successfully',
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
            'sim_number' => 'required|string|max:255',
            'sim_type' => 'required|in:A,B1,B2,C',
            'sim_expiry_date' => 'required|date|after:today',
            'sim_photo' => 'nullable|image|mimes:jpeg,png,jpg|max:5120',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        $verification = VerifikasiSimMitra::where('user_id', $apiToken->user_id)->first();

        if (!$verification) {
            return response()->json([
                'success' => false,
                'message' => 'SIM verification not found'
            ], 404);
        }

        $updateData = [
            'sim_number' => $request->sim_number,
            'sim_type' => $request->sim_type,
            'sim_expiry_date' => $request->sim_expiry_date,
            'status' => 'pending',
        ];

        if ($request->hasFile('sim_photo')) {
            if ($verification->sim_photo) {
                Storage::disk('public')->delete($verification->sim_photo);
            }
            $photoPath = $request->file('sim_photo')->store('verifikasi/sim', 'public');
            $updateData['sim_photo'] = $photoPath;
        }

        $verification->update($updateData);

            // Ensure MitraVerifikasi links to this sim verification
            MitraVerifikasi::updateOrCreate(
                ['user_id' => $apiToken->user_id],
                ['sim_verification_id' => $verification->id]
            );

        return response()->json([
            'success' => true,
            'message' => 'SIM verification updated successfully',
            'data' => $verification
        ]);
    }
}
