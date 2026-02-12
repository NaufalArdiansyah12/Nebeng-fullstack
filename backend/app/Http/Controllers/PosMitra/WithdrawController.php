<?php

namespace App\Http\Controllers\PosMitra;

use App\Http\Controllers\Controller;
use App\Models\PosMitraUser;
use App\Models\ApiToken;
use App\Models\WithdrawalPosmitra;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\DB;

class WithdrawController extends Controller
{
    /**
     * Submit withdrawal request
     */
    public function withdraw(Request $request)
    {
        // 1. Ambil user yang login
        $user = $this->getAuthenticatedUser($request);
        if ($user instanceof \Illuminate\Http\JsonResponse) return $user;

        // 2. Validasi input
        $validator = Validator::make($request->all(), [
            'amount' => 'required|numeric|min:50000',
            'bank_name' => 'required|string|max:100',
            'account_number' => 'required|string|max:50',
            'pin' => 'required|string|size:6',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validasi gagal',
                'errors' => $validator->errors(),
            ], 422);
        }

    // 3. Cek PIN (PLAIN TEXT, bukan Hash)
    if ($request->pin !== $user->pin) {
        return response()->json([
            'success' => false,
            'message' => 'PIN salah',
        ], 401);
    }


        // 4. Cek saldo cukup
        if ($user->balance < $request->amount) {
            return response()->json([
                'success' => false,
                'message' => 'Saldo tidak mencukupi',
            ], 400);
        }

        DB::beginTransaction();
        try {
            // 5. Hitung admin fee dan total amount
            $amount = $request->amount;
            $adminFee = 2500; // Biaya admin Rp 2.500 (bisa disesuaikan)
            $totalAmount = $amount - $adminFee;

            // 6. Generate transaction ID
            $transactionId = WithdrawalPosmitra::generateTransactionId();

            // 7. Simpan withdrawal ke database
            $withdrawal = WithdrawalPosmitra::create([
                'posmitra_id' => $user->id,
                'transaction_id' => $transactionId,
                'amount' => $amount,
                'admin_fee' => $adminFee,
                'total_amount' => $totalAmount,
                'bank_name' => $request->bank_name,
                'bank_account_number' => $request->account_number,
                'bank_account_name' => $user->name, // Ambil dari nama user
                'status' => 'pending',
                'submitted_at' => now(),
            ]);

            DB::commit();

            return response()->json([
                'success' => true,
                'message' => 'Penarikan berhasil diajukan',
                'data' => [
                    'withdrawal_id' => $withdrawal->id,
                    'transaction_id' => $withdrawal->transaction_id,
                    'amount' => (float) $withdrawal->amount,
                    'admin_fee' => (float) $withdrawal->admin_fee,
                    'total_amount' => (float) $withdrawal->total_amount,
                    'bank_name' => $withdrawal->bank_name,
                    'bank_account_number' => $withdrawal->bank_account_number,
                    'status' => $withdrawal->status,
                    'submitted_at' => $withdrawal->submitted_at->format('Y-m-d H:i:s'),
                    'remaining_balance' => (float) $user->balance,
                ],
            ]);

        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json([
                'success' => false,
                'message' => 'Terjadi kesalahan: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Get withdrawal history
     */
    public function history(Request $request)
    {
        $user = $this->getAuthenticatedUser($request);
        if ($user instanceof \Illuminate\Http\JsonResponse) return $user;

        $withdrawals = WithdrawalPosmitra::where('posmitra_id', $user->id)
            ->orderBy('created_at', 'desc')
            ->get()
            ->map(function ($withdrawal) {
                return [
                    'id' => $withdrawal->id,
                    'transaction_id' => $withdrawal->transaction_id,
                    'amount' => (float) $withdrawal->amount,
                    'admin_fee' => (float) $withdrawal->admin_fee,
                    'total_amount' => (float) $withdrawal->total_amount,
                    'bank_name' => $withdrawal->bank_name,
                    'bank_account_number' => $withdrawal->bank_account_number,
                    'status' => $withdrawal->status,
                    'submitted_at' => $withdrawal->submitted_at?->format('Y-m-d H:i:s'),
                    'completed_at' => $withdrawal->completed_at?->format('Y-m-d H:i:s'),
                    'rejected_at' => $withdrawal->rejected_at?->format('Y-m-d H:i:s'),
                    'rejection_reason' => $withdrawal->rejection_reason,
                ];
            });

        return response()->json([
            'success' => true,
            'data' => $withdrawals,
        ]);
    }

    /**
     * Get withdrawal detail
     */
    public function detail(Request $request, $id)
    {
        $user = $this->getAuthenticatedUser($request);
        if ($user instanceof \Illuminate\Http\JsonResponse) return $user;

        $withdrawal = WithdrawalPosmitra::where('id', $id)
            ->where('posmitra_id', $user->id)
            ->first();

        if (!$withdrawal) {
            return response()->json([
                'success' => false,
                'message' => 'Data penarikan tidak ditemukan',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'data' => [
                'id' => $withdrawal->id,
                'transaction_id' => $withdrawal->transaction_id,
                'amount' => (float) $withdrawal->amount,
                'admin_fee' => (float) $withdrawal->admin_fee,
                'total_amount' => (float) $withdrawal->total_amount,
                'bank_name' => $withdrawal->bank_name,
                'bank_account_number' => $withdrawal->bank_account_number,
                'bank_account_name' => $withdrawal->bank_account_name,
                'status' => $withdrawal->status,
                'submitted_at' => $withdrawal->submitted_at?->format('Y-m-d H:i:s'),
                'verified_at' => $withdrawal->verified_at?->format('Y-m-d H:i:s'),
                'approved_at' => $withdrawal->approved_at?->format('Y-m-d H:i:s'),
                'processing_at' => $withdrawal->processing_at?->format('Y-m-d H:i:s'),
                'completed_at' => $withdrawal->completed_at?->format('Y-m-d H:i:s'),
                'rejected_at' => $withdrawal->rejected_at?->format('Y-m-d H:i:s'),
                'rejection_reason' => $withdrawal->rejection_reason,
                'notes' => $withdrawal->notes,
            ],
        ]);
    }

    /**
     * Complete withdrawal (for testing - ubah status ke completed dan kurangi saldo)
     */
    public function complete(Request $request, $id)
    {
        $user = $this->getAuthenticatedUser($request);
        if ($user instanceof \Illuminate\Http\JsonResponse) return $user;

        $withdrawal = WithdrawalPosmitra::where('id', $id)
            ->where('posmitra_id', $user->id)
            ->first();

        if (!$withdrawal) {
            return response()->json([
                'success' => false,
                'message' => 'Data penarikan tidak ditemukan',
            ], 404);
        }

        if ($withdrawal->status !== 'pending') {
            return response()->json([
                'success' => false,
                'message' => 'Withdrawal sudah diproses',
            ], 400);
        }

        DB::beginTransaction();
        try {
            // Kurangi saldo user saat completed
            $user->balance = (float) $user->balance - (float) $withdrawal->amount;
            $user->save();

            // Update status
            $withdrawal->update([
                'status' => 'completed',
                'completed_at' => now(),
            ]);

            DB::commit();

            return response()->json([
                'success' => true,
                'message' => 'Withdrawal completed',
                'data' => [
                    'withdrawal_id' => $withdrawal->id,
                    'status' => $withdrawal->status,
                    'remaining_balance' => (float) $user->balance,
                ],
            ]);

        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json([
                'success' => false,
                'message' => 'Terjadi kesalahan: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Helper: Get authenticated user
     */
    private function getAuthenticatedUser(Request $request)
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
            ->where('expires_at', '>', now())
            ->first();

        if (!$apiToken) {
            return response()->json([
                'success' => false,
                'message' => 'Token tidak valid atau kadaluarsa',
            ], 401);
        }

        $user = PosMitraUser::find($apiToken->posmitra_id);
        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => 'User tidak ditemukan',
            ], 404);
        }

        return $user;
    }


    /**
 * Set withdrawal status (untuk testing)
 */
public function setStatus(Request $request, $id)
{
    $user = $this->getAuthenticatedUser($request);
    if ($user instanceof \Illuminate\Http\JsonResponse) return $user;

    $validator = Validator::make($request->all(), [
        'status' => 'required|in:pending,completed,rejected',
        'rejection_reason' => 'nullable|string|max:255',
    ]);

    if ($validator->fails()) {
        return response()->json([
            'success' => false,
            'message' => 'Validasi gagal',
            'errors' => $validator->errors(),
        ], 422);
    }

    $withdrawal = WithdrawalPosmitra::where('id', $id)
        ->where('posmitra_id', $user->id)
        ->first();

    if (!$withdrawal) {
        return response()->json([
            'success' => false,
            'message' => 'Data penarikan tidak ditemukan',
        ], 404);
    }

    DB::beginTransaction();
    try {
        $newStatus = $request->status;

        // Jika status diubah ke completed, kurangi saldo user
        if ($newStatus === 'completed' && $withdrawal->status !== 'completed') {
            $user->balance -= $withdrawal->amount;
            $user->save();
            $withdrawal->completed_at = now();
        }

        // Jika status diubah ke rejected
        if ($newStatus === 'rejected') {
            $withdrawal->rejected_at = now();
            $withdrawal->rejection_reason = $request->rejection_reason ?? null;
        }

        $withdrawal->status = $newStatus;
        $withdrawal->save();

        DB::commit();

        return response()->json([
            'success' => true,
            'message' => 'Status withdrawal berhasil diubah',
            'data' => [
                'withdrawal_id' => $withdrawal->id,
                'status' => $withdrawal->status,
                'remaining_balance' => (float) $user->balance,
            ],
        ]);

    } catch (\Exception $e) {
        DB::rollBack();
        return response()->json([
            'success' => false,
            'message' => 'Terjadi kesalahan: ' . $e->getMessage(),
        ], 500);
    }
}

}