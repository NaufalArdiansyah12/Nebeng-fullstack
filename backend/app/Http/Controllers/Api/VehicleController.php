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
            ->orderBy('created_at', 'desc')
            ->get();

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
            'seats' => 'required|integer|min:1',
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
            'seats' => $request->seats,
            'is_active' => true,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Vehicle created successfully',
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
            'seats' => 'sometimes|integer|min:1',
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

        $vehicle->delete();

        return response()->json([
            'success' => true,
            'message' => 'Vehicle deleted successfully',
        ]);
    }
}
