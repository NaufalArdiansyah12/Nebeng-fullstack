<?php

namespace App\Http\Controllers;

use App\Models\VerifikasiKtpMitra;
use App\Models\MitraVerifikasi;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;

class VerifikasiKtpController extends Controller
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

        $verification = VerifikasiKtpMitra::where('mitra_id', $apiToken->user_id)->first();

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
            'ktp_number' => 'required|string|size:16',
            'ktp_name' => 'required|string|max:255',
            'ktp_birth_date' => 'required|date',
            'ktp_photo' => 'required|image|mimes:jpeg,png,jpg|max:5120',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        $existing = VerifikasiKtpMitra::where('mitra_id', $apiToken->user_id)->first();
        if ($existing) {
            return response()->json([
                'success' => false,
                'message' => 'KTP verification already exists'
            ], 400);
        }

        $photoPath = null;
        if ($request->hasFile('ktp_photo')) {
            $photoPath = $request->file('ktp_photo')->store('verifikasi/ktp', 'public');
        }

        $verification = VerifikasiKtpMitra::create([
            'mitra_id' => $apiToken->user_id,
            'nik' => $request->ktp_number,
            'nama_lengkap' => $request->ktp_name,
            'tanggal_lahir' => $request->ktp_birth_date,
            'photo_ktp' => $photoPath,
            'status' => 'pending',
        ]);

        return response()->json([
            'success' => true,
            'message' => 'KTP verification submitted successfully',
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
            'ktp_number' => 'required|string|size:16',
            'ktp_name' => 'required|string|max:255',
            'ktp_birth_date' => 'required|date',
            'ktp_photo' => 'nullable|image|mimes:jpeg,png,jpg|max:5120',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        $verification = VerifikasiKtpMitra::where('mitra_id', $apiToken->user_id)->first();

        if (!$verification) {
            return response()->json([
                'success' => false,
                'message' => 'KTP verification not found'
            ], 404);
        }

        if ($request->hasFile('ktp_photo')) {
            if ($verification->photo_ktp) {
                Storage::disk('public')->delete($verification->photo_ktp);
            }
            $photoPath = $request->file('ktp_photo')->store('verifikasi/ktp', 'public');
            $verification->photo_ktp = $photoPath;
        }

        $verification->update([
            'nik' => $request->ktp_number,
            'nama_lengkap' => $request->ktp_name,
            'tanggal_lahir' => $request->ktp_birth_date,
            'status' => 'pending',
        ]);

        return response()->json([
            'success' => true,
            'message' => 'KTP verification updated successfully',
            'data' => $verification
        ]);
    }
}
