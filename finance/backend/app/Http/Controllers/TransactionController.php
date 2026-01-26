<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class TransactionController extends Controller
{
    /* =========================
       GET TRANSACTION BY ID
    ========================= */
    public function getById($id)
    {
        try {
            $transaction = DB::table('payments as t')
                ->select(
                    't.id',
                    't.booking_number',
                    't.payment_method',
                    't.amount',
                    't.admin_fee',
                    't.total_amount',
                    't.status',
                    't.external_id',
                    't.virtual_account_number',
                    't.bank_code',
                    't.expires_at',
                    't.paid_at',
                    't.created_at',
                    'u.name as customer_name',
                    'u.phone as customer_phone'
                )
                ->join('users as u', 't.user_id', '=', 'u.id')
                ->where('t.id', $id)
                ->first();

            if (!$transaction) {
                return response()->json([
                    'success' => false,
                    'message' => 'Transaksi tidak ditemukan'
                ], 404);
            }

            return response()->json([
                'success' => true,
                'data' => [
                    'id' => $transaction->id,
                    'booking_number' => $transaction->booking_number,
                    'payment_method' => $transaction->payment_method,
                    'amount' => $transaction->amount,
                    'admin_fee' => $transaction->admin_fee,
                    'total_amount' => $transaction->total_amount,
                    'status' => $transaction->status,
                    'created_at' => $transaction->created_at,
                    'payment_detail' => [
                        'external_id' => $transaction->external_id,
                        'virtual_account_number' => $transaction->virtual_account_number,
                        'bank_code' => $transaction->bank_code,
                        'expires_at' => $transaction->expires_at,
                        'paid_at' => $transaction->paid_at,
                    ],
                    'customer' => [
                        'name' => $transaction->customer_name,
                        'phone' => $transaction->customer_phone,
                    ],
                ],
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Terjadi kesalahan pada server',
                'error' => $e->getMessage()
            ], 500);
        }
    }
}

