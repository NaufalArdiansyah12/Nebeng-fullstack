<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\Vehicle;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class MitraController extends Controller
{
    /**
     * Get all mitra
     * GET /api/admin/mitra
     */
    public function index(Request $request)
    {
        $perPage = $request->input('per_page', 10);
        $status = $request->input('status'); // pending, verified, rejected, blocked
        $search = $request->input('search');

        $query = User::where('role', 'mitra');

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

        $mitra = $query->orderBy('created_at', 'desc')
                      ->paginate($perPage);

        return response()->json([
            'success' => true,
            'data' => $mitra->items(),
            'pagination' => [
                'current_page' => $mitra->currentPage(),
                'per_page' => $mitra->perPage(),
                'total' => $mitra->total(),
                'last_page' => $mitra->lastPage(),
            ]
        ], 200);
    }

    /**
     * Get mitra detail
     * GET /api/admin/mitra/{id}
     */
    public function show($id)
    {
        $mitra = User::where('role', 'mitra')->find($id);

        if (!$mitra) {
            return response()->json([
                'success' => false,
                'message' => 'Mitra tidak ditemukan'
            ], 404);
        }

        // Get vehicles
        $vehicles = Vehicle::where('user_id', $id)->get();

        return response()->json([
            'success' => true,
            'data' => [
                'id' => $mitra->id,
                'name' => $mitra->name,
                'email' => $mitra->email,
                'phone' => $mitra->phone,
                'address' => $mitra->address,
                'status' => $mitra->status,
                'blocked_reason' => $mitra->blocked_reason,
                'blocked_at' => $mitra->blocked_at,
                'profile_photo' => $mitra->profile_photo ? url('storage/' . $mitra->profile_photo) : null,
                'balance' => $mitra->balance,
                'reward_points' => $mitra->reward_points,
                'created_at' => $mitra->created_at->format('d M Y H:i'),
                'vehicles' => $vehicles
            ]
        ], 200);
    }

    /**
     * Verify mitra
     * POST /api/admin/mitra/{id}/verify
     */
    public function verify($id)
    {
        $mitra = User::where('role', 'mitra')->find($id);

        if (!$mitra) {
            return response()->json([
                'success' => false,
                'message' => 'Mitra tidak ditemukan'
            ], 404);
        }

        $mitra->status = 'active';
        $mitra->save();

        return response()->json([
            'success' => true,
            'message' => 'Mitra berhasil diverifikasi',
            'data' => $mitra
        ], 200);
    }

    /**
     * Reject mitra
     * POST /api/admin/mitra/{id}/reject
     */
    public function reject(Request $request, $id)
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

        $mitra = User::where('role', 'mitra')->find($id);

        if (!$mitra) {
            return response()->json([
                'success' => false,
                'message' => 'Mitra tidak ditemukan'
            ], 404);
        }

        $mitra->status = 'rejected';
        $mitra->blocked_reason = $request->reason;
        $mitra->save();

        return response()->json([
            'success' => true,
            'message' => 'Mitra berhasil ditolak',
            'data' => $mitra
        ], 200);
    }

    /**
     * Block mitra
     * POST /api/admin/mitra/{id}/block
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

        $mitra = User::where('role', 'mitra')->find($id);

        if (!$mitra) {
            return response()->json([
                'success' => false,
                'message' => 'Mitra tidak ditemukan'
            ], 404);
        }

        $mitra->status = 'blocked';
        $mitra->blocked_reason = $request->reason;
        $mitra->blocked_at = now();
        $mitra->save();

        return response()->json([
            'success' => true,
            'message' => 'Mitra berhasil diblokir',
            'data' => $mitra
        ], 200);
    }

    /**
     * Unblock mitra
     * POST /api/admin/mitra/{id}/unblock
     */
    public function unblock($id)
    {
        $mitra = User::where('role', 'mitra')->find($id);

        if (!$mitra) {
            return response()->json([
                'success' => false,
                'message' => 'Mitra tidak ditemukan'
            ], 404);
        }

        $mitra->status = 'active';
        $mitra->blocked_reason = null;
        $mitra->blocked_at = null;
        $mitra->save();

        return response()->json([
            'success' => true,
            'message' => 'Mitra berhasil diunblock',
            'data' => $mitra
        ], 200);
    }

    /**
     * Get mitra vehicles
     * GET /api/admin/mitra/{id}/vehicles
     */
    public function vehicles($id)
    {
        $mitra = User::where('role', 'mitra')->find($id);

        if (!$mitra) {
            return response()->json([
                'success' => false,
                'message' => 'Mitra tidak ditemukan'
            ], 404);
        }

        $vehicles = Vehicle::where('user_id', $id)->get();

        return response()->json([
            'success' => true,
            'data' => $vehicles
        ], 200);
    }

    /**
     * Get all vehicles
     * GET /api/admin/vehicles
     */
    public function allVehicles(Request $request)
    {
        $perPage = $request->input('per_page', 10);
        $search = $request->input('search');

        $query = Vehicle::with('user:id,name,email');

        if ($search) {
            $query->where(function($q) use ($search) {
                $q->where('vehicle_type', 'like', "%{$search}%")
                  ->orWhere('brand', 'like', "%{$search}%")
                  ->orWhere('model', 'like', "%{$search}%")
                  ->orWhere('license_plate', 'like', "%{$search}%");
            });
        }

        $vehicles = $query->orderBy('created_at', 'desc')
                         ->paginate($perPage);

        return response()->json([
            'success' => true,
            'data' => $vehicles->items(),
            'pagination' => [
                'current_page' => $vehicles->currentPage(),
                'per_page' => $vehicles->perPage(),
                'total' => $vehicles->total(),
                'last_page' => $vehicles->lastPage(),
            ]
        ], 200);
    }

    /**
     * Get vehicle detail
     * GET /api/admin/vehicles/{id}
     */
    public function vehicleDetail($id)
    {
        $vehicle = Vehicle::with('user:id,name,email,phone')->find($id);

        if (!$vehicle) {
            return response()->json([
                'success' => false,
                'message' => 'Kendaraan tidak ditemukan'
            ], 404);
        }

        return response()->json([
            'success' => true,
            'data' => $vehicle
        ], 200);
    }
}
