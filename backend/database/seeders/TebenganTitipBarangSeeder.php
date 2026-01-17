<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\TebenganTitipBarang;
use App\Models\User;
use App\Models\Location;
use Carbon\Carbon;

class TebenganTitipBarangSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $mitra = User::where('role', 'mitra')->first();
        $locations = Location::all();
        
        if (!$mitra || $locations->count() < 2) {
            $this->command->warn('Please run UserSeeder and LocationSeeder first.');
            return;
        }

        $tebenganData = [
            // Berangkat hari ini
            [
                'user_id' => $mitra->id,
                'origin_location_id' => $locations[0]->id,
                'destination_location_id' => $locations[1]->id,
                'departure_date' => Carbon::today()->format('Y-m-d'),
                'departure_time' => '08:00:00',
                'transportation_type' => 'kereta',
                'bagasi_capacity' => 10,
                'price' => 50000,
                'status' => 'active',
            ],
            [
                'user_id' => $mitra->id,
                'origin_location_id' => $locations[1]->id,
                'destination_location_id' => $locations[2]->id,
                'departure_date' => Carbon::today()->format('Y-m-d'),
                'departure_time' => '15:30:00',
                'transportation_type' => 'pesawat',
                'bagasi_capacity' => 20,
                'price' => 150000,
                'status' => 'active',
            ],
            // Berangkat besok
            [
                'user_id' => $mitra->id,
                'origin_location_id' => $locations[2]->id,
                'destination_location_id' => $locations[0]->id,
                'departure_date' => Carbon::tomorrow()->format('Y-m-d'),
                'departure_time' => '10:30:00',
                'transportation_type' => 'bus',
                'bagasi_capacity' => 5,
                'price' => 35000,
                'status' => 'active',
            ],
            [
                'user_id' => $mitra->id,
                'origin_location_id' => $locations[0]->id,
                'destination_location_id' => $locations[2]->id,
                'departure_date' => Carbon::tomorrow()->format('Y-m-d'),
                'departure_time' => '18:00:00',
                'transportation_type' => 'kereta',
                'bagasi_capacity' => 15,
                'price' => 75000,
                'status' => 'active',
            ],
            // Sudah selesai (kemarin)
            [
                'user_id' => $mitra->id,
                'origin_location_id' => $locations[0]->id,
                'destination_location_id' => $locations[1]->id,
                'departure_date' => Carbon::yesterday()->format('Y-m-d'),
                'departure_time' => '09:00:00',
                'transportation_type' => 'bus',
                'bagasi_capacity' => 8,
                'price' => 40000,
                'status' => 'completed',
            ],
        ];

        foreach ($tebenganData as $data) {
            TebenganTitipBarang::create($data);
        }

        $this->command->info('Created ' . count($tebenganData) . ' titip barang rides successfully.');
    }
}
