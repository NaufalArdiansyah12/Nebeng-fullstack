<?php

namespace Database\Seeders;

use App\Models\CarRide;
use App\Models\User;
use App\Models\Location;
use App\Models\KendaraanMitra;
use Illuminate\Database\Seeder;
use Carbon\Carbon;

class CarRideSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $mitra = User::where('role', 'mitra')->first();
        $locations = Location::all();
        $cars = KendaraanMitra::where('vehicle_type', 'mobil')->get();
        
        if (!$mitra || $locations->count() < 2 || $cars->isEmpty()) {
            $this->command->warn('Please run UserSeeder, LocationSeeder, and VehicleSeeder first.');
            return;
        }

        $rides = [
            // Rides hari ini
            [
                'user_id' => $mitra->id,
                'kendaraan_mitra_id' => $cars[0]->id,
                'origin_location_id' => $locations[0]->id,
                'destination_location_id' => $locations[1]->id,
                'departure_date' => Carbon::today()->format('Y-m-d'),
                'departure_time' => '07:00:00',
                'available_seats' => 4,
                'price' => 50000, // Price per seat
                'ride_type' => 'mobil',
                'status' => 'active',
            ],
            [
                'user_id' => $mitra->id,
                'kendaraan_mitra_id' => $cars->count() > 1 ? $cars[1]->id : $cars[0]->id,
                'origin_location_id' => $locations[1]->id,
                'destination_location_id' => $locations[2]->id,
                'departure_date' => Carbon::today()->format('Y-m-d'),
                'departure_time' => '13:00:00',
                'available_seats' => 5,
                'price' => 60000,
                'ride_type' => 'mobil',
                'status' => 'active',
            ],
            // Rides besok
            [
                'user_id' => $mitra->id,
                'kendaraan_mitra_id' => $cars[0]->id,
                'origin_location_id' => $locations[2]->id,
                'destination_location_id' => $locations[0]->id,
                'departure_date' => Carbon::tomorrow()->format('Y-m-d'),
                'departure_time' => '08:30:00',
                'available_seats' => 3,
                'price' => 55000,
                'ride_type' => 'mobil',
                'status' => 'active',
            ],
            [
                'user_id' => $mitra->id,
                'kendaraan_mitra_id' => $cars->count() > 2 ? $cars[2]->id : $cars[0]->id,
                'origin_location_id' => $locations[0]->id,
                'destination_location_id' => $locations[2]->id,
                'departure_date' => Carbon::tomorrow()->format('Y-m-d'),
                'departure_time' => '16:00:00',
                'available_seats' => 3,
                'price' => 65000,
                'ride_type' => 'mobil',
                'status' => 'active',
            ],
            // Ride kemarin (untuk history)
            [
                'user_id' => $mitra->id,
                'kendaraan_mitra_id' => $cars[0]->id,
                'origin_location_id' => $locations[0]->id,
                'destination_location_id' => $locations[1]->id,
                'departure_date' => Carbon::yesterday()->format('Y-m-d'),
                'departure_time' => '10:00:00',
                'available_seats' => 0,
                'price' => 45000,
                'ride_type' => 'mobil',
                'status' => 'completed',
            ],
        ];

        foreach ($rides as $ride) {
            CarRide::create($ride);
        }

        $this->command->info('Created ' . count($rides) . ' car rides successfully.');
    }
}
