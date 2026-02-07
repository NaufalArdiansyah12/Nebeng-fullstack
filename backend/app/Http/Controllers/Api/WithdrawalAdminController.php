<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Withdrawal;
use App\Models\User;
use App\Services\MitraNotificationService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class WithdrawalAdminController extends Controller
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
     * Get all withdrawal requests (Admin only)
     */
    public function index(Request $request)
    {
        try {
            $user = $this->getAuthenticatedUser($request);

            if (!$user || $user->role !== 'admin') {
                return response()->json([
                    'success' => false,
                    'message' => 'Unauthorized. Only admin can access this.'
                ], 403);
            }

            $status = $request->get('status'); // pending, processing, completed, rejected
            $perPage = $request->get('per_page', 20);

            $query = Withdrawal::with('user');

            if ($status) {
                $query->where('status', $status);
            }

            $withdrawals = $query->orderBy('created_at', 'desc')->paginate($perPage);

            return response()->json([
                'success' => true,
                'data' => $withdrawals
            ]);
        } catch (\Exception $e) {
            Log::error('Error getting withdrawals: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Failed to get withdrawals'
            ], 500);
        }
    }

    /**
     * Approve withdrawal request (Admin only)
     */
    public function approve(Request $request, $id)
    {
        try {
            $user = $this->getAuthenticatedUser($request);

            if (!$user || $user->role !== 'admin') {
                return response()->json([
                    'success' => false,
                    'message' => 'Unauthorized. Only admin can approve withdrawals.'
                ], 403);
            }

            $withdrawal = Withdrawal::with('user')->findOrFail($id);

            if ($withdrawal->status !== 'pending') {
                return response()->json([
                    'success' => false,
                    'message' => 'Withdrawal is not in pending status'
                ], 400);
            }

            DB::beginTransaction();

            try {
                $withdrawal->update([
                    'status' => 'processing',
                    'approved_at' => now(),
                    'approved_by' => $user->id,
                ]);

                DB::commit();

                // Send notification to mitra
                MitraNotificationService::sendWithdrawalSuccessNotification($withdrawal);

                Log::info('Withdrawal approved', [
                    'withdrawal_id' => $withdrawal->id,
                    'transaction_id' => $withdrawal->transaction_id,
                    'approved_by' => $user->id,
                ]);

                return response()->json([
                    'success' => true,
                    'message' => 'Withdrawal approved successfully',
                    'data' => $withdrawal
                ]);
            } catch (\Exception $e) {
                DB::rollBack();
                throw $e;
            }
        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Withdrawal not found'
            ], 404);
        } catch (\Exception $e) {
            Log::error('Error approving withdrawal: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Failed to approve withdrawal'
            ], 500);
        }
    }

    /**
     * Complete withdrawal (mark as completed after transfer done) (Admin only)
     */
    public function complete(Request $request, $id)
    {
        try {
            $user = $this->getAuthenticatedUser($request);

            if (!$user || $user->role !== 'admin') {
                return response()->json([
                    'success' => false,
                    'message' => 'Unauthorized. Only admin can complete withdrawals.'
                ], 403);
            }

            $withdrawal = Withdrawal::with('user')->findOrFail($id);

            if (!in_array($withdrawal->status, ['pending', 'processing'])) {
                return response()->json([
                    'success' => false,
                    'message' => 'Withdrawal cannot be completed from current status'
                ], 400);
            }

            DB::beginTransaction();

            try {
                $withdrawal->update([
                    'status' => 'completed',
                    'completed_at' => now(),
                    'processed_by' => $user->id,
                ]);

                DB::commit();

                // Send success notification
                MitraNotificationService::sendWithdrawalSuccessNotification($withdrawal);

                Log::info('Withdrawal completed', [
                    'withdrawal_id' => $withdrawal->id,
                    'transaction_id' => $withdrawal->transaction_id,
                    'completed_by' => $user->id,
                ]);

                return response()->json([
                    'success' => true,
                    'message' => 'Withdrawal completed successfully',
                    'data' => $withdrawal
                ]);
            } catch (\Exception $e) {
                DB::rollBack();
                throw $e;
            }
        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Withdrawal not found'
            ], 404);
        } catch (\Exception $e) {
            Log::error('Error completing withdrawal: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Failed to complete withdrawal'
            ], 500);
        }
    }

    /**
     * Reject withdrawal and refund balance (Admin only)
     */
    public function reject(Request $request, $id)
    {
        try {
            $request->validate([
                'rejection_reason' => 'required|string|max:500',
            ]);

            $user = $this->getAuthenticatedUser($request);

            if (!$user || $user->role !== 'admin') {
                return response()->json([
                    'success' => false,
                    'message' => 'Unauthorized. Only admin can reject withdrawals.'
                ], 403);
            }

            $withdrawal = Withdrawal::with('user')->findOrFail($id);

            if (in_array($withdrawal->status, ['completed', 'rejected', 'refunded'])) {
                return response()->json([
                    'success' => false,
                    'message' => 'Withdrawal cannot be rejected from current status'
                ], 400);
            }

            DB::beginTransaction();

            try {
                // Return balance to user
                $mitraUser = $withdrawal->user;
                $mitraUser->increment('balance', $withdrawal->amount);

                // Update withdrawal status
                $withdrawal->update([
                    'status' => 'rejected',
                    'rejected_at' => now(),
                    'rejection_reason' => $request->rejection_reason,
                    'processed_by' => $user->id,
                ]);

                DB::commit();

                // Send failure notification
                MitraNotificationService::sendWithdrawalFailedNotification($withdrawal, $request->rejection_reason);

                Log::info('Withdrawal rejected', [
                    'withdrawal_id' => $withdrawal->id,
                    'transaction_id' => $withdrawal->transaction_id,
                    'rejected_by' => $user->id,
                    'reason' => $request->rejection_reason,
                ]);

                return response()->json([
                    'success' => true,
                    'message' => 'Withdrawal rejected and balance refunded',
                    'data' => [
                        'withdrawal' => $withdrawal,
                        'refunded_amount' => $withdrawal->amount,
                        'new_balance' => $mitraUser->balance,
                    ]
                ]);
            } catch (\Exception $e) {
                DB::rollBack();
                throw $e;
            }
        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Withdrawal not found'
            ], 404);
        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Validation error',
                'errors' => $e->errors()
            ], 422);
        } catch (\Exception $e) {
            Log::error('Error rejecting withdrawal: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Failed to reject withdrawal'
            ], 500);
        }
    }
}
