<?php

namespace App\Http\Controllers\Finance;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\PricingProfile;
use App\Models\PricingRule;
use App\Models\WeightCategory;
use App\Services\PriceCalculator;

class PricingController extends Controller
{
    public function index()
    {
        $profiles = PricingProfile::with(['transportMode', 'rules.weightCategory'])->get();
        return response()->json(['success' => true, 'data' => $profiles]);
    }

    public function show($id)
    {
        $profile = PricingProfile::with(['transportMode', 'rules.weightCategory'])->findOrFail($id);
        return response()->json(['success' => true, 'data' => $profile]);
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'name' => 'required|string',
            'description' => 'nullable|string',
            'transport_mode_id' => 'nullable|integer',
            'active' => 'boolean',
            'base_price' => 'nullable|numeric',
            'price_per_km' => 'nullable|numeric',
            'price_per_kg' => 'nullable|numeric',
            'min_price' => 'nullable|numeric',
        ]);

        $profile = PricingProfile::create($data);
        return response()->json(['success' => true, 'data' => $profile], 201);
    }

    public function update(Request $request, $id)
    {
        $profile = PricingProfile::findOrFail($id);
        $data = $request->validate([
            'name' => 'sometimes|string',
            'description' => 'nullable|string',
            'transport_mode_id' => 'nullable|integer',
            'active' => 'boolean',
            'base_price' => 'nullable|numeric',
            'price_per_km' => 'nullable|numeric',
            'price_per_kg' => 'nullable|numeric',
            'min_price' => 'nullable|numeric',
        ]);

        $profile->update($data);
        return response()->json(['success' => true, 'data' => $profile]);
    }

    public function destroy($id)
    {
        $profile = PricingProfile::findOrFail($id);
        $profile->delete();
        return response()->json(['success' => true]);
    }

    // Calculate endpoint: accepts transport_mode, weight, service_type, distance
    public function calculate(Request $request, PriceCalculator $calculator)
    {
        $data = $request->validate([
            'transport_mode' => 'required|string',
            'weight' => 'required|numeric',
            'service_type' => 'nullable|string',
            'distance' => 'nullable|numeric'
        ]);

        $transportMode = $data['transport_mode'];
        $weight = (float)$data['weight'];
        $serviceType = $data['service_type'] ?? null;
        $distance = (float)($data['distance'] ?? 0);

        $result = $calculator->calculate($transportMode, $weight, $serviceType, $distance);
        
        // Add extra info for frontend display
        $result['transport_mode'] = $transportMode;
        $result['weight'] = $weight;
        $result['distance'] = $distance;
        $result['service_type'] = $serviceType;

        return response()->json(['success' => true, 'data' => $result]);
    }
}
