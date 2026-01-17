<?php

namespace Database\Seeders;

use App\Models\Ride;
use App\Models\User;
use App\Models\Location;
use App\Models\KendaraanMitra;
use Illuminate\Database\Seeder;
use Carbon\Carbon;

class RideSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $mitra = User::where('role', 'mitra')->first();
        $locations = Location::all();
        $motors = KendaraanMitra::where('vehicle_type', 'motor')->get();
        
        if (!$mitra || $locations->count() < 2 || $motors->isEmpty()) {
            $this->command->warn('Please run UserSeeder, LocationSeeder, and VehicleSeeder first.');
            return;
        }

        $rides = [
            // Rides untuk hari ini dan besok
            [
                'user_id' => $mitra->id,
                'kendaraan_mitra_id' => $motors[0]->id,
                'origin_location_id' => $locations[0]->id,
                'destination_location_id' => $locations[1]->id,
                'departure_date' => Carbon::today()->format('Y-m-d'),
                'departure_time' => '08:00:00',
                'available_seats' => 1,
                'price' => 25000,
                'ride_type' => 'motor',
                'status' => 'active',
            ],
            [
                'user_id' => $mitra->id,
                'kendaraan_mitra_id' => $motors->count() > 1 ? $motors[1]->id : $motors[0]->id,
                'origin_location_id' => $locations[1]->id,
                'destination_location_id' => $locations[2]->id,
                'departure_date' => Carbon::today()->format('Y-m-d'),
                'departure_time' => '14:00:00',
                'available_seats' => 1,
                'price' => 30000,
                'ride_type' => 'motor',
                'status' => 'active',
            ],
            [
                'user_id' => $mitra->id,
                'kendaraan_mitra_id' => $motors[0]->id,
                'origin_location_id' => $locations[2]->id,
                'destination_location_id' => $locations[0]->id,
                'departure_date' => Carbon::tomorrow()->format('Y-m-d'),
                'departure_time' => '09:00:00',
                'available_seats' => 1,
                'price' => 28000,
                'ride_type' => 'motor',
                'status' => 'active',
            ],
            [
                'user_id' => $mitra->id,
                'kendaraan_mitra_id' => $motors->count() > 2 ? $motors[2]->id : $motors[0]->id,
                'origin_location_id' => $locations[0]->id,
                'destination_location_id' => $locations[2]->id,
                'departure_date' => Carbon::tomorrow()->format('Y-m-d'),
                'departure_time' => '15:30:00',
                'available_seats' => 1,
                'price' => 35000,
                'ride_type' => 'motor',
                'status' => 'active',
            ],
            // Ride kemarin (untuk history)
            [
                'user_id' => $mitra->id,
                'kendaraan_mitra_id' => $motors[0]->id,
                'origin_location_id' => $locations[0]->id,
                'destination_location_id' => $locations[1]->id,
                'departure_date' => Carbon::yesterday()->format('Y-m-d'),
                'departure_time' => '10:00:00',
                'available_seats' => 0,
                'price' => 20000,
                'ride_type' => 'motor',
                'status' => 'completed',

            ],
        ];

        foreach ($rides as $ride) {
            Ride::create($ride);
        }

        $this->command->info('Created ' . count($rides) . ' motor rides successfully.');
    }
}
