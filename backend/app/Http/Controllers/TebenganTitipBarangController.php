<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\TebenganTitipBarang;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Str;
use App\Services\PriceCalculationService;
use Illuminate\Support\Facades\Log;

class TebenganTitipBarangController extends Controller
{
    private function generateQrCode($rideId)
    {
        $random = Str::upper(Str::random(8));
        return "RIDE-TITIP-{$rideId}-{$random}";
    }

    public function index(Request $request)
    {
        try {
            $query = TebenganTitipBarang::with(['user', 'originLocation', 'destinationLocation']);

            if ($request->has('status')) {
                $query->where('status', $request->status);
            }

            if ($request->has('user_id')) {
                $query->where('user_id', $request->user_id);
            }

            if ($request->has('origin_location_id')) {
                $query->where('origin_location_id', $request->origin_location_id);
            }

            if ($request->has('destination_location_id')) {
                $query->where('destination_location_id', $request->destination_location_id);
            }

            if ($request->has('departure_date')) {
                $query->whereDate('departure_date', $request->departure_date);
            }

            if ($request->has('transportation_type')) {
                $query->where('transportation_type', $request->transportation_type);
            }

            $tebengan = $query->orderBy('created_at', 'desc')->paginate(20);

            // Compute calculated price for each tebengan item if possible
            try {
                $collection = $tebengan->getCollection();
                $collection->transform(function ($item) {
                    try {
                        if (!empty($item->bagasi_capacity)) {
                            $transportation = $item->transportation_type ?? null;
                            $transportMap = [
                                'bus' => 'titip-barang-bus',
                                'kereta' => 'titip-barang-kereta',
                                'pesawat' => 'titip-barang-pesawat',
                            ];
                            $transportSlug = $transportMap[$transportation] ?? 'titip-barang-bus';

                            $serviceType = PriceCalculationService::determineServiceType('titip_barang', $item->service_type ?? 'tebengan');
                            $numericWeight = floatval($item->bagasi_capacity);

                            $calculator = app(\App\Services\PriceCalculator::class);
                            $priceResult = $calculator->calculate($transportSlug, $numericWeight, $serviceType, 0.0);
                            if (is_array($priceResult) && array_key_exists('total', $priceResult)) {
                                $item->calculated_price = $priceResult['total'];
                                $item->price_breakdown = $priceResult;
                            }
                        }
                    } catch (\Throwable $e) {
                        Log::warning('Failed to compute calculated_price for tebengan list', ['error' => $e->getMessage(), 'id' => $item->id]);
                    }
                    return $item;
                });
                $tebengan->setCollection($collection);
            } catch (\Throwable $e) {
                Log::warning('Failed to attach calculated prices to tebengan paginator', ['error' => $e->getMessage()]);
            }

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

    public function show($id)
    {
        try {
            $tebengan = TebenganTitipBarang::with(['user', 'originLocation', 'destinationLocation'])
                ->findOrFail($id);

            // Try to compute calculated price for this tebengan if bagasi_capacity exists
            try {
                if (!empty($tebengan->bagasi_capacity)) {
                    $transportation = $tebengan->transportation_type ?? null;
                    $transportMap = [
                        'bus' => 'titip-barang-bus',
                        'kereta' => 'titip-barang-kereta',
                        'pesawat' => 'titip-barang-pesawat',
                    ];
                    $transportSlug = $transportMap[$transportation] ?? 'titip-barang-bus';

                    $serviceType = PriceCalculationService::determineServiceType('titip_barang', $tebengan->service_type ?? 'tebengan');
                    $numericWeight = floatval($tebengan->bagasi_capacity);

                    $calculator = app(\App\Services\PriceCalculator::class);
                    $priceResult = $calculator->calculate($transportSlug, $numericWeight, $serviceType, 0.0);
                    if (is_array($priceResult) && array_key_exists('total', $priceResult)) {
                        $tebengan->calculated_price = $priceResult['total'];
                        $tebengan->price_breakdown = $priceResult;
                    }
                }
            } catch (\Throwable $e) {
                Log::warning('Failed to compute calculated_price for tebengan show', ['error' => $e->getMessage(), 'id' => $tebengan->id]);
            }

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

    public function store(Request $request)
    {
        try {
            $bearer = $request->bearerToken();
            if (!$bearer) {
                return response()->json([
                    'success' => false,
                    'message' => 'Token not provided',
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

            $validator = Validator::make($request->all(), [
                'origin_location_id' => 'required|exists:locations,id',
                'destination_location_id' => 'required|exists:locations,id',
                'departure_date' => 'required|date',
                'departure_time' => 'required',
                'transportation_type' => 'required|in:kereta,pesawat,bus',
                'bagasi_capacity' => 'required|integer|in:5,10,20',
                'jumlah_bagasi' => 'nullable|integer|min:0',
                'price' => 'nullable|numeric|min:0',
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Validation error',
                    'errors' => $validator->errors()
                ], 422);
            }

            $data = [
                'user_id' => $apiToken->user_id,
                'origin_location_id' => $request->origin_location_id,
                'destination_location_id' => $request->destination_location_id,
                'departure_date' => $request->departure_date,
                'departure_time' => $request->departure_time,
                'transportation_type' => $request->transportation_type,
                'bagasi_capacity' => $request->bagasi_capacity,
                'price' => $request->price ?? null,
                'status' => 'active',
                'jumlah_bagasi' => $request->jumlah_bagasi ?? 0,
            ];

            $tebengan = TebenganTitipBarang::create($data);

            $qrCode = $this->generateQrCode($tebengan->id);
            $tebengan->qr_code_data = $qrCode;
            $tebengan->save();

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

    public function update(Request $request, $id)
    {
        try {
            $tebengan = TebenganTitipBarang::findOrFail($id);

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
                'jumlah_bagasi' => 'nullable|integer|min:0',
                'jumlah_bagasi' => 'sometimes|integer|min:0',
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

            $update = $request->only([
                'origin_location_id',
                'destination_location_id',
                'departure_date',
                'departure_time',
                'transportation_type',
                'bagasi_capacity',
                'jumlah_bagasi',
                'price',
                'status',
            ]);

            $tebengan->update($update);

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

    public function destroy($id)
    {
        try {
            $tebengan = TebenganTitipBarang::findOrFail($id);

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

    public function myTebengan(Request $request)
    {
        try {
            $query = TebenganTitipBarang::with(['originLocation', 'destinationLocation'])
                ->where('user_id', Auth::id());

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
