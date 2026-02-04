<?php

namespace App\Http\Controllers\Mitra;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\Withdrawal;
use App\Models\VerifikasiBankMitra;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;

class WithdrawalController extends Controller
{
    /**
     * Get authenticated user from bearer token
     */
    private function getAuthenticatedUser(Request $request)
    {
        $token = $request->bearerToken();
        if (!$token) {
            return null;
        }

        $hashedToken = hash('sha256', $token);
        $apiToken = DB::table('api_tokens')
            ->where('token', $hashedToken)
            ->first();

        if (!$apiToken) {
            return null;
        }

        return User::find($apiToken->user_id);
    }

    /**
     * Get mitra balance and bank info
     */
    public function getBalanceInfo(Request $request)
    {
        try {
            $user = $this->getAuthenticatedUser($request);

            if (!$user) {
                return response()->json([
                    'success' => false,
                    'message' => 'Unauthorized'
                ], 401);
            }

            // Get bank verification info
            $bankInfo = VerifikasiBankMitra::where('user_id', $user->id)
                ->where('status', 'approved')
                ->first();

            if (!$bankInfo) {
                return response()->json([
                    'success' => false,
                    'message' => 'Anda belum memiliki rekening bank yang terverifikasi'
                ], 400);
            }

            return response()->json([
                'success' => true,
                'data' => [
                    'name' => $user->name,
                    'balance' => $user->balance ?? 0,
                    'bank_name' => $bankInfo->bank_name,
                    'bank_account_number' => $bankInfo->bank_account_number,
                    'bank_account_name' => $bankInfo->bank_account_name,
                ]
            ]);
        } catch (\Exception $e) {
            Log::error('Error getting balance info: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Gagal mengambil informasi saldo'
            ], 500);
        }
    }

    /**
     * Submit withdrawal request
     */
    public function submitRequest(Request $request)
    {
        try {
            $request->validate([
                'amount' => 'required|numeric|min:50000',
                'pin' => 'required|string|size:6',
            ]);

            $user = $this->getAuthenticatedUser($request);

            if (!$user) {
                return response()->json([
                    'success' => false,
                    'message' => 'Unauthorized'
                ], 401);
            }

            // Verify PIN
            if (!$user->pin) {
                return response()->json([
                    'success' => false,
                    'message' => 'PIN belum dibuat'
                ], 400);
            }

            // Check if PIN uses SHA-256 (old format) or Bcrypt (new format)
            $isPinValid = false;
            if (strlen($user->pin) === 64) {
                // Old format: SHA-256
                $isPinValid = hash('sha256', $request->pin) === $user->pin;
            } else {
                // New format: Bcrypt
                $isPinValid = Hash::check($request->pin, $user->pin);
            }

            if (!$isPinValid) {
                return response()->json([
                    'success' => false,
                    'message' => 'PIN yang Anda masukkan salah'
                ], 400);
            }

            // Check balance
            if ($user->balance < $request->amount) {
                return response()->json([
                    'success' => false,
                    'message' => 'Saldo tidak mencukupi'
                ], 400);
            }

            // Get bank info
            $bankInfo = VerifikasiBankMitra::where('user_id', $user->id)
                ->where('status', 'approved')
                ->first();

            if (!$bankInfo) {
                return response()->json([
                    'success' => false,
                    'message' => 'Rekening bank tidak ditemukan'
                ], 400);
            }

            DB::beginTransaction();

            try {
                // Calculate admin fee (0 for now)
                $adminFee = 0;
                $totalAmount = $request->amount - $adminFee;

                // Create withdrawal request
                $withdrawal = Withdrawal::create([
                    'user_id' => $user->id,
                    'transaction_id' => Withdrawal::generateTransactionId(),
                    'amount' => $request->amount,
                    'admin_fee' => $adminFee,
                    'total_amount' => $totalAmount,
                    'bank_name' => $bankInfo->bank_name,
                    'bank_account_number' => $bankInfo->bank_account_number,
                    'bank_account_name' => $bankInfo->bank_account_name,
                    'status' => 'pending',
                    'submitted_at' => now(),
                ]);

                // Deduct balance
                $user->decrement('balance', $request->amount);

                // Note: Status will remain 'pending' until admin approves
                // Admin will handle approval through admin panel

                DB::commit();

                return response()->json([
                    'success' => true,
                    'message' => 'Pengajuan pencairan berhasil diajukan',
                    'data' => [
                        'withdrawal_id' => $withdrawal->id,
                        'transaction_id' => $withdrawal->transaction_id,
                    ]
                ]);
            } catch (\Exception $e) {
                DB::rollBack();
                throw $e;
            }
        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Data tidak valid',
                'errors' => $e->errors()
            ], 422);
        } catch (\Exception $e) {
            Log::error('Error submitting withdrawal: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Gagal mengajukan pencairan'
            ], 500);
        }
    }

    /**
     * Simulate progress (for demo purposes) - DISABLED
     * Status will remain pending until admin manually approves
     */
    private function simulateProgress(Withdrawal $withdrawal)
    {
        // Disabled - Let admin handle approval manually
        // In production, admin will update status through admin panel
        return;
    }

    /**
     * Get withdrawal detail
     */
    public function getDetail(Request $request, $id)
    {
        try {
            $user = $this->getAuthenticatedUser($request);

            if (!$user) {
                return response()->json([
                    'success' => false,
                    'message' => 'Unauthorized'
                ], 401);
            }

            $withdrawal = Withdrawal::where('id', $id)
                ->where('user_id', $user->id)
                ->first();

            if (!$withdrawal) {
                return response()->json([
                    'success' => false,
                    'message' => 'Data penarikan tidak ditemukan'
                ], 404);
            }

            return response()->json([
                'success' => true,
                'data' => [
                    'id' => $withdrawal->id,
                    'transaction_id' => $withdrawal->transaction_id,
                    'amount' => $withdrawal->amount,
                    'admin_fee' => $withdrawal->admin_fee,
                    'total_amount' => $withdrawal->total_amount,
                    'bank_name' => $withdrawal->bank_name,
                    'bank_account_number' => $withdrawal->bank_account_number,
                    'bank_account_name' => $withdrawal->bank_account_name,
                    'status' => $withdrawal->status,
                    'submitted_at' => $withdrawal->submitted_at?->format('d M Y | H:i') . ' WIB',
                    'completed_at' => $withdrawal->completed_at?->format('d M Y | H:i') . ' WIB',
                    'rejected_at' => $withdrawal->rejected_at?->format('d M Y | H:i') . ' WIB',
                    'rejection_reason' => $withdrawal->rejection_reason,
                    'progress' => $withdrawal->getProgressTimeline(),
                    'estimated_duration' => $withdrawal->getEstimatedDuration(),
                ]
            ]);
        } catch (\Exception $e) {
            Log::error('Error getting withdrawal detail: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Gagal mengambil detail penarikan'
            ], 500);
        }
    }

    /**
     * Check withdrawal status and auto-complete if processing
     */
    public function checkStatus(Request $request, $id)
    {
        try {
            $user = $this->getAuthenticatedUser($request);

            if (!$user) {
                return response()->json([
                    'success' => false,
                    'message' => 'Unauthorized'
                ], 401);
            }

            $withdrawal = Withdrawal::where('id', $id)
                ->where('user_id', $user->id)
                ->first();

            if (!$withdrawal) {
                return response()->json([
                    'success' => false,
                    'message' => 'Data penarikan tidak ditemukan'
                ], 404);
            }

            // Auto-complete if still processing (for demo)
            // Disabled - manual approval only
            /*
            if ($withdrawal->status === 'processing' && $withdrawal->processing_at && $withdrawal->processing_at->diffInSeconds(now()) > 5) {
                $withdrawal->update([
                    'status' => 'completed',
                    'completed_at' => now(),
                ]);
            }
            */

            return response()->json([
                'success' => true,
                'data' => [
                    'status' => $withdrawal->status,
                    'is_completed' => $withdrawal->status === 'completed',
                    'progress' => $withdrawal->getProgressTimeline(),
                ]
            ]);
        } catch (\Exception $e) {
            Log::error('Error checking withdrawal status: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Gagal memeriksa status'
            ], 500);
        }
    }

    /**
     * Get withdrawal history
     */
    public function getHistory(Request $request)
    {
        try {
            $user = $this->getAuthenticatedUser($request);

            if (!$user) {
                return response()->json([
                    'success' => false,
                    'message' => 'Unauthorized'
                ], 401);
            }

            $status = $request->query('status'); // 'processing', 'completed', or null for all

            $query = Withdrawal::where('user_id', $user->id);

            if ($status === 'processing') {
                $query->whereIn('status', ['pending', 'processing']);
            } elseif ($status === 'completed') {
                $query->where('status', 'completed');
            }

            $withdrawals = $query->orderBy('created_at', 'desc')
                ->get()
                ->map(function ($withdrawal) {
                    return [
                        'id' => $withdrawal->id,
                        'transaction_id' => $withdrawal->transaction_id,
                        'amount' => $withdrawal->amount,
                        'status' => $withdrawal->status,
                        'status_label' => $this->getStatusLabel($withdrawal->status),
                        'bank_name' => $withdrawal->bank_name,
                        'bank_account_number' => $withdrawal->bank_account_number,
                        'submitted_at' => $withdrawal->submitted_at?->format('d M Y'),
                        'submitted_at_time' => $withdrawal->submitted_at?->format('H:i'),
                        'completed_at' => $withdrawal->completed_at?->format('d M Y'),
                        'completed_at_time' => $withdrawal->completed_at?->format('H:i'),
                    ];
                });

            return response()->json([
                'success' => true,
                'data' => $withdrawals
            ]);
        } catch (\Exception $e) {
            Log::error('Error getting withdrawal history: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Gagal mengambil riwayat penarikan'
            ], 500);
        }
    }

    /**
     * Get status label in Indonesian
     */
    private function getStatusLabel($status)
    {
        $labels = [
            'pending' => 'Proses',
            'processing' => 'Proses',
            'completed' => 'Berhasil',
            'failed' => 'Gagal',
            'rejected' => 'Ditolak',
        ];

        return $labels[$status] ?? $status;
    }

    /**
     * Set/Update PIN
     */
    public function setPin(Request $request)
    {
        try {
            $request->validate([
                'pin' => 'required|string|size:6|regex:/^[0-9]{6}$/',
                'pin_confirmation' => 'required|same:pin',
            ]);

            $user = $this->getAuthenticatedUser($request);

            if (!$user) {
                return response()->json([
                    'success' => false,
                    'message' => 'Unauthorized'
                ], 401);
            }

            $user->update([
                'pin' => Hash::make($request->pin)
            ]);

            return response()->json([
                'success' => true,
                'message' => 'PIN berhasil dibuat'
            ]);
        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Data tidak valid',
                'errors' => $e->errors()
            ], 422);
        } catch (\Exception $e) {
            Log::error('Error setting PIN: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Gagal membuat PIN'
            ], 500);
        }
    }

    /**
     * Verify PIN
     */
    public function verifyPin(Request $request)
    {
        try {
            $request->validate([
                'pin' => 'required|string|size:6',
            ]);

            $user = $this->getAuthenticatedUser($request);

            if (!$user) {
                return response()->json([
                    'success' => false,
                    'message' => 'Unauthorized'
                ], 401);
            }

            if (!$user->pin) {
                return response()->json([
                    'success' => false,
                    'message' => 'PIN belum dibuat'
                ], 400);
            }

            // Check if PIN uses SHA-256 (old format) or Bcrypt (new format)
            $isPinValid = false;
            if (strlen($user->pin) === 64) {
                // Old format: SHA-256
                $isPinValid = hash('sha256', $request->pin) === $user->pin;
            } else {
                // New format: Bcrypt
                $isPinValid = Hash::check($request->pin, $user->pin);
            }

            if (!$isPinValid) {
                return response()->json([
                    'success' => false,
                    'message' => 'PIN yang Anda masukkan salah'
                ], 400);
            }

            return response()->json([
                'success' => true,
                'message' => 'PIN valid'
            ]);
        } catch (\Exception $e) {
            Log::error('Error verifying PIN: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Gagal memverifikasi PIN'
            ], 500);
        }
    }

    /**
     * Reject withdrawal and refund balance (Admin only)
     */
    public function rejectWithdrawal(Request $request, $id)
    {
        try {
            $request->validate([
                'rejection_reason' => 'required|string|max:500',
            ]);

            $withdrawal = Withdrawal::findOrFail($id);

            // Check if withdrawal can be rejected
            if (in_array($withdrawal->status, ['completed', 'rejected', 'refunded'])) {
                return response()->json([
                    'success' => false,
                    'message' => 'Withdrawal tidak dapat ditolak karena sudah ' . $withdrawal->status
                ], 400);
            }

            DB::beginTransaction();

            try {
                // Return balance to user
                $user = User::findOrFail($withdrawal->user_id);
                $user->increment('balance', $withdrawal->amount);

                // Update withdrawal status
                $withdrawal->update([
                    'status' => 'rejected',
                    'rejected_at' => now(),
                    'rejection_reason' => $request->rejection_reason,
                    'processed_by' => $request->user()->id ?? null,
                ]);

                DB::commit();

                Log::info('Withdrawal rejected', [
                    'withdrawal_id' => $withdrawal->id,
                    'transaction_id' => $withdrawal->transaction_id,
                    'amount' => $withdrawal->amount,
                    'user_id' => $withdrawal->user_id,
                    'reason' => $request->rejection_reason,
                ]);

                return response()->json([
                    'success' => true,
                    'message' => 'Withdrawal ditolak dan saldo telah dikembalikan',
                    'data' => [
                        'withdrawal_id' => $withdrawal->id,
                        'transaction_id' => $withdrawal->transaction_id,
                        'refunded_amount' => $withdrawal->amount,
                        'new_balance' => $user->balance,
                    ]
                ]);
            } catch (\Exception $e) {
                DB::rollBack();
                throw $e;
            }
        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Withdrawal tidak ditemukan'
            ], 404);
        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Data tidak valid',
                'errors' => $e->errors()
            ], 422);
        } catch (\Exception $e) {
            Log::error('Error rejecting withdrawal: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Gagal menolak withdrawal'
            ], 500);
        }
    }
}
