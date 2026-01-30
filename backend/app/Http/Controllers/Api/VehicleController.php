<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Vehicle;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;

class VehicleController extends Controller
{
    public function index(Request $request)
    {
        // Get authenticated user from bearer token
        $token = $request->bearerToken();
        if (!$token) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthorized',
            ], 401);
        }

        $hashedToken = hash('sha256', $token);
        $apiToken = DB::table('api_tokens')
            ->where('token', $hashedToken)
            ->first();

        if (!$apiToken) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid token',
            ], 401);
        }

        $vehicles = Vehicle::where('user_id', $apiToken->user_id)
            ->where('is_active', true)
            ->where(function($query) {
                $query->where('deletion_status', '!=', 'approved')
                      ->orWhereNull('deletion_status');
            })
            ->orderBy('created_at', 'desc')
            ->get()
            ->map(function ($vehicle) {
                return [
                    'id' => $vehicle->id,
                    'user_id' => $vehicle->user_id,
                    'vehicle_type' => $vehicle->vehicle_type,
                    'name' => $vehicle->name,
                    'plate_number' => $vehicle->plate_number,
                    'brand' => $vehicle->brand,
                    'model' => $vehicle->model,
                    'color' => $vehicle->color,
                    'year' => $vehicle->year,
                    'is_active' => $vehicle->is_active,
                    'status' => $vehicle->status ?? 'pending',
                    'rejection_reason' => $vehicle->rejection_reason,
                    'approved_at' => $vehicle->approved_at,
                    'deletion_status' => $vehicle->deletion_status ?? 'none',
                    'deletion_reason' => $vehicle->deletion_reason,
                    'deletion_requested_at' => $vehicle->deletion_requested_at,
                    'deletion_approved_at' => $vehicle->deletion_approved_at,
                    'created_at' => $vehicle->created_at,
                    'updated_at' => $vehicle->updated_at,
                ];
            });

        return response()->json([
            'success' => true,
            'data' => $vehicles,
        ]);
    }

    public function store(Request $request)
    {
        // Get authenticated user
        $token = $request->bearerToken();
        if (!$token) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthorized',
            ], 401);
        }

        $hashedToken = hash('sha256', $token);
        $apiToken = DB::table('api_tokens')
            ->where('token', $hashedToken)
            ->first();

        if (!$apiToken) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid token',
            ], 401);
        }

        $validator = Validator::make($request->all(), [
            'vehicle_type' => 'required|in:motor,mobil',
            'name' => 'required|string|max:255',
            'plate_number' => 'required|string|max:255',
            'brand' => 'required|string|max:255',
            'model' => 'required|string|max:255',
            'color' => 'required|string|max:255',
            'year' => 'nullable|integer|min:1900|max:' . (date('Y') + 1),
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation error',
                'errors' => $validator->errors(),
            ], 422);
        }

        $vehicle = Vehicle::create([
            'user_id' => $apiToken->user_id,
            'vehicle_type' => $request->vehicle_type,
            'name' => $request->name,
            'plate_number' => $request->plate_number,
            'brand' => $request->brand,
            'model' => $request->model,
            'color' => $request->color,
            'year' => $request->year,
            'is_active' => true,
            'status' => 'pending', // Default status is pending approval
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Vehicle created successfully. Waiting for admin approval.',
            'data' => $vehicle,
        ], 201);
    }

    public function show($id)
    {
        $vehicle = Vehicle::find($id);

        if (!$vehicle) {
            return response()->json([
                'success' => false,
                'message' => 'Vehicle not found',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'data' => $vehicle,
        ]);
    }

    public function update(Request $request, $id)
    {
        $vehicle = Vehicle::find($id);

        if (!$vehicle) {
            return response()->json([
                'success' => false,
                'message' => 'Vehicle not found',
            ], 404);
        }

        // Verify ownership
        $token = $request->bearerToken();
        if (!$token) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthorized',
            ], 401);
        }

        $hashedToken = hash('sha256', $token);
        $apiToken = DB::table('api_tokens')
            ->where('token', $hashedToken)
            ->first();

        if (!$apiToken || $apiToken->user_id !== $vehicle->user_id) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthorized',
            ], 403);
        }

        $validator = Validator::make($request->all(), [
            'vehicle_type' => 'sometimes|in:motor,mobil',
            'name' => 'sometimes|string|max:255',
            'plate_number' => 'sometimes|string|max:255',
            'brand' => 'sometimes|string|max:255',
            'model' => 'sometimes|string|max:255',
            'color' => 'sometimes|string|max:255',
            'year' => 'nullable|integer|min:1900|max:' . (date('Y') + 1),
            'is_active' => 'sometimes|boolean',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation error',
                'errors' => $validator->errors(),
            ], 422);
        }

        $vehicle->update($request->all());

        return response()->json([
            'success' => true,
            'message' => 'Vehicle updated successfully',
            'data' => $vehicle,
        ]);
    }

    public function destroy(Request $request, $id)
    {
        $vehicle = Vehicle::find($id);

        if (!$vehicle) {
            return response()->json([
                'success' => false,
                'message' => 'Vehicle not found',
            ], 404);
        }

        // Verify ownership
        $token = $request->bearerToken();
        if (!$token) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthorized',
            ], 401);
        }

        $hashedToken = hash('sha256', $token);
        $apiToken = DB::table('api_tokens')
            ->where('token', $hashedToken)
            ->first();

        if (!$apiToken || $apiToken->user_id !== $vehicle->user_id) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthorized',
            ], 403);
        }

        // Validate deletion reason
        $validator = Validator::make($request->all(), [
            'deletion_reason' => 'required|string|max:255',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation error',
                'errors' => $validator->errors(),
            ], 422);
        }

        // Instead of deleting, mark as pending deletion
        $vehicle->update([
            'deletion_status' => 'pending',
            'deletion_reason' => $request->deletion_reason,
            'deletion_requested_at' => now(),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Deletion request submitted successfully. Waiting for admin approval.',
            'data' => $vehicle,
        ]);
    }

    /**
     * Approve vehicle by admin
     */
    public function approve(Request $request, $id)
    {
        $vehicle = Vehicle::find($id);

        if (!$vehicle) {
            return response()->json([
                'success' => false,
                'message' => 'Vehicle not found',
            ], 404);
        }

        // Get authenticated user (should be admin)
        $token = $request->bearerToken();
        if (!$token) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthorized',
            ], 401);
        }

        $hashedToken = hash('sha256', $token);
        $apiToken = DB::table('api_tokens')
            ->where('token', $hashedToken)
            ->first();

        if (!$apiToken) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid token',
            ], 401);
        }

        // Get user and check if admin
        $user = DB::table('users')->where('id', $apiToken->user_id)->first();
        if (!$user || $user->role !== 'admin') {
            return response()->json([
                'success' => false,
                'message' => 'Only admin can approve vehicles',
            ], 403);
        }

        $vehicle->update([
            'status' => 'approved',
            'approved_at' => now(),
            'approved_by' => $user->id,
            'rejection_reason' => null,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Vehicle approved successfully',
            'data' => $vehicle,
        ]);
    }

    /**
     * Reject vehicle by admin
     */
    public function reject(Request $request, $id)
    {
        $vehicle = Vehicle::find($id);

        if (!$vehicle) {
            return response()->json([
                'success' => false,
                'message' => 'Vehicle not found',
            ], 404);
        }

        // Get authenticated user (should be admin)
        $token = $request->bearerToken();
        if (!$token) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthorized',
            ], 401);
        }

        $hashedToken = hash('sha256', $token);
        $apiToken = DB::table('api_tokens')
            ->where('token', $hashedToken)
            ->first();

        if (!$apiToken) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid token',
            ], 401);
        }

        // Get user and check if admin
        $user = DB::table('users')->where('id', $apiToken->user_id)->first();
        if (!$user || $user->role !== 'admin') {
            return response()->json([
                'success' => false,
                'message' => 'Only admin can reject vehicles',
            ], 403);
        }

        $validator = Validator::make($request->all(), [
            'rejection_reason' => 'required|string|max:500',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation error',
                'errors' => $validator->errors(),
            ], 422);
        }

        $vehicle->update([
            'status' => 'rejected',
            'approved_at' => now(),
            'approved_by' => $user->id,
            'rejection_reason' => $request->rejection_reason,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Vehicle rejected',
            'data' => $vehicle,
        ]);
    }

    /**
     * Approve vehicle deletion by admin
     */
    public function approveDeletion(Request $request, $id)
    {
        $vehicle = Vehicle::find($id);

        if (!$vehicle) {
            return response()->json([
                'success' => false,
                'message' => 'Vehicle not found',
            ], 404);
        }

        // Get authenticated user (should be admin)
        $token = $request->bearerToken();
        if (!$token) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthorized',
            ], 401);
        }

        $hashedToken = hash('sha256', $token);
        $apiToken = DB::table('api_tokens')
            ->where('token', $hashedToken)
            ->first();

        if (!$apiToken) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid token',
            ], 401);
        }

        // Get user and check if admin
        $user = DB::table('users')->where('id', $apiToken->user_id)->first();
        if (!$user || $user->role !== 'admin') {
            return response()->json([
                'success' => false,
                'message' => 'Only admin can approve vehicle deletion',
            ], 403);
        }

        if ($vehicle->deletion_status !== 'pending') {
            return response()->json([
                'success' => false,
                'message' => 'No pending deletion request for this vehicle',
            ], 400);
        }

        // Update deletion status and actually delete the vehicle
        $vehicle->update([
            'deletion_status' => 'approved',
            'deletion_approved_at' => now(),
            'deletion_approved_by' => $user->id,
        ]);

        // Actually delete the vehicle
        $vehicle->delete();

        return response()->json([
            'success' => true,
            'message' => 'Vehicle deletion approved and deleted successfully',
        ]);
    }

    /**
     * Reject vehicle deletion by admin
     */
    public function rejectDeletion(Request $request, $id)
    {
        $vehicle = Vehicle::find($id);

        if (!$vehicle) {
            return response()->json([
                'success' => false,
                'message' => 'Vehicle not found',
            ], 404);
        }

        // Get authenticated user (should be admin)
        $token = $request->bearerToken();
        if (!$token) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthorized',
            ], 401);
        }

        $hashedToken = hash('sha256', $token);
        $apiToken = DB::table('api_tokens')
            ->where('token', $hashedToken)
            ->first();

        if (!$apiToken) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid token',
            ], 401);
        }

        // Get user and check if admin
        $user = DB::table('users')->where('id', $apiToken->user_id)->first();
        if (!$user || $user->role !== 'admin') {
            return response()->json([
                'success' => false,
                'message' => 'Only admin can reject vehicle deletion',
            ], 403);
        }

        if ($vehicle->deletion_status !== 'pending') {
            return response()->json([
                'success' => false,
                'message' => 'No pending deletion request for this vehicle',
            ], 400);
        }

        // Reset deletion status
        $vehicle->update([
            'deletion_status' => 'rejected',
            'deletion_approved_at' => now(),
            'deletion_approved_by' => $user->id,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Vehicle deletion request rejected',
            'data' => $vehicle,
        ]);
    }
}
