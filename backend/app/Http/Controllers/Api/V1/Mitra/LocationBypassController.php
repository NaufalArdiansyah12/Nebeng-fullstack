<?php

namespace App\Http\Controllers\Api\V1\Mitra;

use App\Http\Controllers\Controller;
use App\Models\Location;
use App\Models\LocationQRBypassSetting;
use Illuminate\Http\Request;

class LocationBypassController extends Controller
{
    /**
     * Check if a location has QR bypass enabled
     */
    public function checkBypass($locationId)
    {
        $location = Location::with('qrBypassSetting')->find($locationId);
        
        if (!$location) {
            return response()->json([
                'success' => false,
                'message' => 'Location not found',
            ], 404);
        }

        $bypassEnabled = $location->qrBypassSetting?->qr_bypass_enabled ?? false;

        return response()->json([
            'success' => true,
            'data' => [
                'location_id' => $locationId,
                'location_name' => $location->name,
                'qr_bypass_enabled' => $bypassEnabled,
            ],
        ]);
    }
}
