<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class CustomerController extends Controller
{
    /**
     * Get all customers
     * GET /api/admin/customers
     */
    public function index(Request $request)
    {
        $perPage = $request->input('per_page', 10);
        $status = $request->input('status'); // verified, blocked
        $search = $request->input('search');

        $query = User::where('role', 'customer');

        if ($status) {
            $query->where('status', $status);
        }

        if ($search) {
            $query->where(function($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('email', 'like', "%{$search}%")
                  ->orWhere('phone', 'like', "%{$search}%");
            });
        }

        $customers = $query->orderBy('created_at', 'desc')
                          ->paginate($perPage);

        return response()->json([
            'success' => true,
            'data' => $customers->items(),
            'pagination' => [
                'current_page' => $customers->currentPage(),
                'per_page' => $customers->perPage(),
                'total' => $customers->total(),
                'last_page' => $customers->lastPage(),
            ]
        ], 200);
    }

    /**
     * Get customer detail
     * GET /api/admin/customers/{id}
     */
    public function show($id)
    {
        $customer = User::where('role', 'customer')->find($id);

        if (!$customer) {
            return response()->json([
                'success' => false,
                'message' => 'Customer tidak ditemukan'
            ], 404);
        }

        return response()->json([
            'success' => true,
            'data' => [
                'id' => $customer->id,
                'name' => $customer->name,
                'email' => $customer->email,
                'phone' => $customer->phone,
                'phone_verified' => $customer->phone_verified,
                'address' => $customer->address,
                'status' => $customer->status,
                'blocked_reason' => $customer->blocked_reason,
                'blocked_at' => $customer->blocked_at,
                'profile_photo' => $customer->profile_photo ? url('storage/' . $customer->profile_photo) : null,
                'balance' => $customer->balance,
                'reward_points' => $customer->reward_points,
                'created_at' => $customer->created_at->format('d M Y H:i'),
            ]
        ], 200);
    }

    /**
     * Verify customer
     * POST /api/admin/customers/{id}/verify
     */
    public function verify($id)
    {
        $customer = User::where('role', 'customer')->find($id);

        if (!$customer) {
            return response()->json([
                'success' => false,
                'message' => 'Customer tidak ditemukan'
            ], 404);
        }

        $customer->phone_verified = true;
        $customer->phone_verified_at = now();
        $customer->status = 'active';
        $customer->save();

        return response()->json([
            'success' => true,
            'message' => 'Customer berhasil diverifikasi',
            'data' => $customer
        ], 200);
    }

    /**
     * Block customer
     * POST /api/admin/customers/{id}/block
     */
    public function block(Request $request, $id)
    {
        $validator = Validator::make($request->all(), [
            'reason' => 'required|string|max:500'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        $customer = User::where('role', 'customer')->find($id);

        if (!$customer) {
            return response()->json([
                'success' => false,
                'message' => 'Customer tidak ditemukan'
            ], 404);
        }

        $customer->status = 'blocked';
        $customer->blocked_reason = $request->reason;
        $customer->blocked_at = now();
        $customer->save();

        return response()->json([
            'success' => true,
            'message' => 'Customer berhasil diblokir',
            'data' => $customer
        ], 200);
    }

    /**
     * Unblock customer
     * POST /api/admin/customers/{id}/unblock
     */
    public function unblock($id)
    {
        $customer = User::where('role', 'customer')->find($id);

        if (!$customer) {
            return response()->json([
                'success' => false,
                'message' => 'Customer tidak ditemukan'
            ], 404);
        }

        $customer->status = 'active';
        $customer->blocked_reason = null;
        $customer->blocked_at = null;
        $customer->save();

        return response()->json([
            'success' => true,
            'message' => 'Customer berhasil diunblock',
            'data' => $customer
        ], 200);
    }

    /**
     * Get pending verification customers
     * GET /api/admin/customers/pending-verification
     */
    public function pendingVerification(Request $request)
    {
        $perPage = $request->input('per_page', 10);

        $customers = User::where('role', 'customer')
                        ->where('phone_verified', false)
                        ->orderBy('created_at', 'desc')
                        ->paginate($perPage);

        return response()->json([
            'success' => true,
            'data' => $customers->items(),
            'pagination' => [
                'current_page' => $customers->currentPage(),
                'per_page' => $customers->perPage(),
                'total' => $customers->total(),
                'last_page' => $customers->lastPage(),
            ]
        ], 200);
    }

    /**
     * Get blocked customers
     * GET /api/admin/customers/blocked
     */
    public function blocked(Request $request)
    {
        $perPage = $request->input('per_page', 10);

        $customers = User::where('role', 'customer')
                        ->where('status', 'blocked')
                        ->orderBy('blocked_at', 'desc')
                        ->paginate($perPage);

        return response()->json([
            'success' => true,
            'data' => $customers->items(),
            'pagination' => [
                'current_page' => $customers->currentPage(),
                'per_page' => $customers->perPage(),
                'total' => $customers->total(),
                'last_page' => $customers->lastPage(),
            ]
        ], 200);
    }
}
