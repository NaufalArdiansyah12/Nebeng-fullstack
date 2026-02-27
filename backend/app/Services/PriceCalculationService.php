<?php

namespace App\Services;

use App\Models\PricePerKg;
use Illuminate\Support\Facades\Log;

class PriceCalculationService
{
    /**
     * Calculate price for a booking based on weight and ride details
     * 
     * @param string $serviceType antar_barang or antar_penumpang
     * @param string $rideType motor, mobil, barang, titip_barang
     * @param float $weight Weight in kg
     * @param int|null $bagasiCapacity Only for antar_barang: 5, 10, or 20
     * @return array ['success' => bool, 'price' => float, 'breakdown' => array, 'message' => string]
     */
    public static function calculatePrice(
        string $serviceType,
        string $rideType,
        float $weight,
        ?int $bagasiCapacity = null
    ): array {
        try {
            // Get active price rate
            $priceRate = PricePerKg::getActivePrice($serviceType, $rideType, $bagasiCapacity);

            if (!$priceRate) {
                Log::warning('No active price found', [
                    'service_type' => $serviceType,
                    'ride_type' => $rideType,
                    'bagasi_capacity' => $bagasiCapacity,
                ]);

                return [
                    'success' => false,
                    'price' => 0,
                    'breakdown' => [],
                    'message' => 'Tarif tidak ditemukan untuk kombinasi layanan ini. Silakan hubungi admin.',
                ];
            }

            // Calculate price using model method
            $finalPrice = $priceRate->calculatePrice($weight);

            $breakdown = [
                'service_type' => $serviceType,
                'ride_type' => $rideType,
                'bagasi_capacity' => $bagasiCapacity,
                'weight' => $weight,
                'rate_per_kg' => $priceRate->rate_per_kg,
                'calculated_price' => $weight * $priceRate->rate_per_kg,
                'min_charge' => $priceRate->min_charge,
                'final_price' => $finalPrice,
                'price_id' => $priceRate->id,
            ];

            Log::info('Price calculated successfully', $breakdown);

            return [
                'success' => true,
                'price' => $finalPrice,
                'breakdown' => $breakdown,
                'message' => 'Harga berhasil dihitung',
            ];
        } catch (\Exception $e) {
            Log::error('Price calculation failed', [
                'error' => $e->getMessage(),
                'service_type' => $serviceType,
                'ride_type' => $rideType,
                'weight' => $weight,
            ]);

            return [
                'success' => false,
                'price' => 0,
                'breakdown' => [],
                'message' => 'Gagal menghitung harga: ' . $e->getMessage(),
            ];
        }
    }

    /**
     * Get service type from ride type
     * 
     * @param string $rideType
     * @param string $serviceTypeFromRide From ride.service_type field
     * @return string antar_barang or antar_penumpang
     */
    public static function determineServiceType(string $rideType, string $serviceTypeFromRide): string
    {
        // If ride is specifically for barang/titip_barang type
        if (in_array($rideType, ['barang', 'titip_barang'])) {
            return 'antar_barang';
        }

        // For motor/mobil, check the service_type field
        if ($serviceTypeFromRide === 'barang') {
            return 'antar_barang';
        }

        // Default to antar_penumpang for 'tebengan' or 'both'
        return 'antar_penumpang';
    }
}
