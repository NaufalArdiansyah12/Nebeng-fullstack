<?php

namespace App\Http\Controllers\Api\V1\SuperAdmin;

use App\Http\Controllers\Controller;
use App\Models\Location;
use App\Models\LocationQRBypassSetting;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class LocationQRBypassController extends Controller
{
    /**
     * Get all locations with their QR bypass settings
     */
    public function index()
    {
        $locations = Location::with('qrBypassSetting')
            ->orderBy('city')
            ->orderBy('name')
            ->get()
            ->map(function ($location) {
                return [
                    'id' => $location->id,
                    'name' => $location->name,
                    'city' => $location->city,
                    'address' => $location->address,
                    'qr_bypass_enabled' => $location->qrBypassSetting?->qr_bypass_enabled ?? false,
                    'notes' => $location->qrBypassSetting?->notes,
                ];
            });

        return response()->json([
            'success' => true,
            'data' => $locations,
        ]);
    }

    /**
     * Update QR bypass setting for a location
     */
    public function update(Request $request, $locationId)
    {
        $validator = Validator::make($request->all(), [
            'qr_bypass_enabled' => 'required|boolean',
            'notes' => 'nullable|string|max:500',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors(),
            ], 422);
        }

        $location = Location::find($locationId);
        if (!$location) {
            return response()->json([
                'success' => false,
                'message' => 'Location not found',
            ], 404);
        }

        $setting = LocationQRBypassSetting::updateOrCreate(
            ['location_id' => $locationId],
            [
                'qr_bypass_enabled' => $request->qr_bypass_enabled,
                'notes' => $request->notes,
            ]
        );

        return response()->json([
            'success' => true,
            'message' => 'QR bypass setting updated successfully',
            'data' => [
                'location_id' => $locationId,
                'qr_bypass_enabled' => $setting->qr_bypass_enabled,
                'notes' => $setting->notes,
            ],
        ]);
    }
}
