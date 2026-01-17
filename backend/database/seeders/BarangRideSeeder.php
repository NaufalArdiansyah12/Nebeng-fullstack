<?php

namespace Database\Seeders;

use App\Models\BarangRide;
use App\Models\User;
use App\Models\Location;
use App\Models\KendaraanMitra;
use Illuminate\Database\Seeder;
use Carbon\Carbon;

class BarangRideSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $mitra = User::where('role', 'mitra')->first();
        $locations = Location::all();
        // Ambil pickup/truck untuk barang
        $vehicles = KendaraanMitra::where('vehicle_type', 'mobil')
            ->whereIn('model', ['Carry Pickup', 'L300 Pickup'])
            ->get();
        
        if ($vehicles->isEmpty()) {
            // Fallback ke mobil biasa jika tidak ada pickup
            $vehicles = KendaraanMitra::where('vehicle_type', 'mobil')->get();
        }
        
        if (!$mitra || $locations->count() < 2 || $vehicles->isEmpty()) {
            $this->command->warn('Please run UserSeeder, LocationSeeder, and VehicleSeeder first.');
            return;
        }

        $rides = [
            // Rides hari ini
            [
                'user_id' => $mitra->id,
                'kendaraan_mitra_id' => $vehicles[0]->id,
                'origin_location_id' => $locations[0]->id,
                'destination_location_id' => $locations[1]->id,
                'departure_date' => Carbon::today()->format('Y-m-d'),
                'departure_time' => '06:00:00',
                'available_seats' => 1,
                'price' => 75000,
                'bagasi_capacity' => 500, // liters
                'ride_type' => 'barang',
                'status' => 'active',
            ],
            [
                'user_id' => $mitra->id,
                'kendaraan_mitra_id' => $vehicles->count() > 1 ? $vehicles[1]->id : $vehicles[0]->id,
                'origin_location_id' => $locations[1]->id,
                'destination_location_id' => $locations[2]->id,
                'departure_date' => Carbon::today()->format('Y-m-d'),
                'departure_time' => '11:00:00',
                'available_seats' => 1,
                'price' => 90000,
                'bagasi_capacity' => 800,
                'ride_type' => 'barang',
                'status' => 'active',
            ],
            // Rides besok
            [
                'user_id' => $mitra->id,
                'kendaraan_mitra_id' => $vehicles[0]->id,
                'origin_location_id' => $locations[2]->id,
                'destination_location_id' => $locations[0]->id,
                'departure_date' => Carbon::tomorrow()->format('Y-m-d'),
                'departure_time' => '07:30:00',
                'available_seats' => 1,
                'price' => 80000,
                'bagasi_capacity' => 600,
                'ride_type' => 'barang',
                'status' => 'active',
            ],
            [
                'user_id' => $mitra->id,
                'kendaraan_mitra_id' => $vehicles->count() > 1 ? $vehicles[1]->id : $vehicles[0]->id,
                'origin_location_id' => $locations[0]->id,
                'destination_location_id' => $locations[2]->id,
                'departure_date' => Carbon::tomorrow()->format('Y-m-d'),
                'departure_time' => '14:30:00',
                'available_seats' => 1,
                'price' => 95000,
                'bagasi_capacity' => 1000,
                'ride_type' => 'barang',
                'status' => 'active',
            ],
            // Ride kemarin (untuk history)
            [
                'user_id' => $mitra->id,
                'kendaraan_mitra_id' => $vehicles[0]->id,
                'origin_location_id' => $locations[0]->id,
                'destination_location_id' => $locations[1]->id,
                'departure_date' => Carbon::yesterday()->format('Y-m-d'),
                'departure_time' => '09:00:00',
                'available_seats' => 0,
                'price' => 70000,
                'bagasi_capacity' => 400,
                'ride_type' => 'barang',
                'status' => 'completed',
            ],
        ];

        foreach ($rides as $ride) {
            BarangRide::create($ride);
        }

        $this->command->info('Created ' . count($rides) . ' barang rides successfully.');
    }
}
