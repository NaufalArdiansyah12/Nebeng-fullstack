<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\TebenganTitipBarang;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Auth;

class TebenganTitipBarangController extends Controller
{
    /**
     * Get all tebengan titip barang (with filters)
     */
    public function index(Request $request)
    {
        try {
            $query = TebenganTitipBarang::with(['user', 'originLocation', 'destinationLocation']);

            // Filter by status
            if ($request->has('status')) {
                $query->where('status', $request->status);
            }

            // Filter by user (mitra)
            if ($request->has('user_id')) {
                $query->where('user_id', $request->user_id);
            }

            // Filter by origin location
            if ($request->has('origin_location_id')) {
                $query->where('origin_location_id', $request->origin_location_id);
            }

            // Filter by destination location
            if ($request->has('destination_location_id')) {
                $query->where('destination_location_id', $request->destination_location_id);
            }

            // Filter by date
            if ($request->has('departure_date')) {
                $query->whereDate('departure_date', $request->departure_date);
            }

            // Filter by transportation type
            if ($request->has('transportation_type')) {
                $query->where('transportation_type', $request->transportation_type);
            }

            $tebengan = $query->orderBy('created_at', 'desc')->paginate(20);

            return response()->json([
                'success' => true,
                'data' => $tebengan
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch tebengan titip barang',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get single tebengan titip barang by ID
     */
    public function show($id)
    {
        try {
            $tebengan = TebenganTitipBarang::with(['user', 'originLocation', 'destinationLocation'])
                ->findOrFail($id);

            return response()->json([
                'success' => true,
                'data' => $tebengan
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Tebengan titip barang not found',
                'error' => $e->getMessage()
            ], 404);
        }
    }

    /**
     * Create new tebengan titip barang
     */
    public function store(Request $request)
    {
        try {
            // Extract Bearer token from Authorization header
            $bearer = $request->bearerToken();
            if (!$bearer) {
                return response()->json([
                    'success' => false,
                    'message' => 'Token not provided',
                ], 401);
            }

            // Hash and find API token
            $hashed = hash('sha256', $bearer);
            $apiToken = \App\Models\ApiToken::where('token', $hashed)->first();
            
            if (!$apiToken) {
                return response()->json([
                    'success' => false,
                    'message' => 'Invalid token',
                ], 401);
            }

            $validator = Validator::make($request->all(), [
                'origin_location_id' => 'required|exists:locations,id',
                'destination_location_id' => 'required|exists:locations,id',
                'departure_date' => 'required|date',
                'departure_time' => 'required',
                'transportation_type' => 'required|in:kereta,pesawat,bus',
                'bagasi_capacity' => 'required|integer|in:5,10,20',
                'price' => 'required|numeric|min:0',
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Validation error',
                    'errors' => $validator->errors()
                ], 422);
            }

            $tebengan = TebenganTitipBarang::create([
                'user_id' => $apiToken->user_id,
                'origin_location_id' => $request->origin_location_id,
                'destination_location_id' => $request->destination_location_id,
                'departure_date' => $request->departure_date,
                'departure_time' => $request->departure_time,
                'transportation_type' => $request->transportation_type,
                'bagasi_capacity' => $request->bagasi_capacity,
                'price' => $request->price,
                'status' => 'active',
            ]);

            $tebengan->load(['user', 'originLocation', 'destinationLocation']);

            return response()->json([
                'success' => true,
                'message' => 'Tebengan titip barang created successfully',
                'data' => $tebengan
            ], 201);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to create tebengan titip barang',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Update tebengan titip barang
     */
    public function update(Request $request, $id)
    {
        try {
            $tebengan = TebenganTitipBarang::findOrFail($id);

            // Check if user is the owner
            if ($tebengan->user_id !== Auth::id()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Unauthorized'
                ], 403);
            }

            $validator = Validator::make($request->all(), [
                'origin_location_id' => 'sometimes|exists:locations,id',
                'destination_location_id' => 'sometimes|exists:locations,id',
                'departure_date' => 'sometimes|date',
                'departure_time' => 'sometimes',
                'transportation_type' => 'sometimes|in:kereta,pesawat,bus',
                'bagasi_capacity' => 'sometimes|integer|in:5,10,20',
                'price' => 'sometimes|numeric|min:0',
                'status' => 'sometimes|in:active,inactive,completed',
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Validation error',
                    'errors' => $validator->errors()
                ], 422);
            }

            $tebengan->update($request->only([
                'origin_location_id',
                'destination_location_id',
                'departure_date',
                'departure_time',
                'transportation_type',
                'bagasi_capacity',
                'price',
                'status',
            ]));

            $tebengan->load(['mitra', 'originLocation', 'destinationLocation']);

            return response()->json([
                'success' => true,
                'message' => 'Tebengan titip barang updated successfully',
                'data' => $tebengan
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to update tebengan titip barang',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Delete tebengan titip barang
     */
    public function destroy($id)
    {
        try {
            $tebengan = TebenganTitipBarang::findOrFail($id);

            // Check if user is the owner
            if ($tebengan->user_id !== Auth::id()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Unauthorized'
                ], 403);
            }

            $tebengan->delete();

            return response()->json([
                'success' => true,
                'message' => 'Tebengan titip barang deleted successfully'
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to delete tebengan titip barang',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get mitra's own tebengan titip barang
     */
    public function myTebengan(Request $request)
    {
        try {
            $query = TebenganTitipBarang::with(['originLocation', 'destinationLocation'])
                ->where('user_id', Auth::id());

            // Filter by status
            if ($request->has('status')) {
                $query->where('status', $request->status);
            }

            $tebengan = $query->orderBy('created_at', 'desc')->paginate(20);

            return response()->json([
                'success' => true,
                'data' => $tebengan
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch your tebengan',
                'error' => $e->getMessage()
            ], 500);
        }
    }
}
