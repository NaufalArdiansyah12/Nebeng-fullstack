<?php

namespace App\Http\Controllers;

use App\Models\MitraVerifikasi;
use App\Models\VerifikasiKtpMitra;
use App\Models\VerifikasiSimMitra;
use App\Models\VerifikasiSkckMitra;
use App\Models\VerifikasiBankMitra;
use Illuminate\Http\Request;

class MitraVerifikasiController extends Controller
{
    public function linkVerifications(Request $request)
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

        // Get all verification IDs
        $ktpVerification = VerifikasiKtpMitra::where('mitra_id', $apiToken->user_id)->first();
        $simVerification = VerifikasiSimMitra::where('user_id', $apiToken->user_id)->first();
        $skckVerification = VerifikasiSkckMitra::where('user_id', $apiToken->user_id)->first();
        $bankVerification = VerifikasiBankMitra::where('user_id', $apiToken->user_id)->first();

        if (!$ktpVerification || !$simVerification || !$skckVerification || !$bankVerification) {
            return response()->json([
                'success' => false,
                'message' => 'Semua dokumen harus lengkap',
            ], 400);
        }

        // Create or update mitra_verifikasi
        $mitraVerifikasi = MitraVerifikasi::updateOrCreate(
            ['user_id' => $apiToken->user_id],
            [
                'ktp_verification_id' => $ktpVerification->id,
                'sim_verification_id' => $simVerification->id,
                'skck_verification_id' => $skckVerification->id,
                'bank_verification_id' => $bankVerification->id,
            ]
        );

        return response()->json([
            'success' => true,
            'message' => 'Verifikasi berhasil dihubungkan',
            'data' => $mitraVerifikasi
        ], 200);
    }

    public function getVerificationStatus(Request $request)
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

        // Get mitra verification with all relations
        $mitraVerifikasi = MitraVerifikasi::with([
            'ktpVerification',
            'simVerification',
            'skckVerification',
            'bankVerification'
        ])->where('user_id', $apiToken->user_id)->first();

        if (!$mitraVerifikasi) {
            return response()->json([
                'success' => true,
                'message' => 'Belum ada verifikasi',
                'data' => null,
                'status' => 'not_submitted'
            ], 200);
        }

        // Determine overall status
        $statuses = [
            $mitraVerifikasi->ktpVerification?->status,
            $mitraVerifikasi->simVerification?->status,
            $mitraVerifikasi->skckVerification?->status,
            $mitraVerifikasi->bankVerification?->status,
        ];

        // If all approved
        if (array_filter($statuses, fn($s) => $s === 'approved') === $statuses) {
            $overallStatus = 'approved';
        }
        // If any rejected
        elseif (in_array('rejected', $statuses)) {
            $overallStatus = 'rejected';
        }
        // If pending
        else {
            $overallStatus = 'pending';
        }

        return response()->json([
            'success' => true,
            'message' => 'Berhasil mendapatkan status verifikasi',
            'data' => [
                'overall_status' => $overallStatus,
                'ktp' => [
                    'status' => $mitraVerifikasi->ktpVerification?->status,
                    'photo' => $mitraVerifikasi->ktpVerification?->photo_ktp,
                    'reviewed_at' => $mitraVerifikasi->ktpVerification?->reviewed_at,
                ],
                'sim' => [
                    'status' => $mitraVerifikasi->simVerification?->status,
                    'photo' => $mitraVerifikasi->simVerification?->photo_sim,
                    'reviewed_at' => $mitraVerifikasi->simVerification?->reviewed_at,
                ],
                'skck' => [
                    'status' => $mitraVerifikasi->skckVerification?->status,
                    'photo' => $mitraVerifikasi->skckVerification?->photo_skck,
                    'reviewed_at' => $mitraVerifikasi->skckVerification?->reviewed_at,
                ],
                'bank' => [
                    'status' => $mitraVerifikasi->bankVerification?->status,
                    'photo' => $mitraVerifikasi->bankVerification?->photo_buku_tabungan,
                    'reviewed_at' => $mitraVerifikasi->bankVerification?->reviewed_at,
                ],
                'submitted_at' => $mitraVerifikasi->created_at,
                'verified_at' => $mitraVerifikasi->verified_at,
            ],
            'status' => $overallStatus
        ], 200);
    }
}
