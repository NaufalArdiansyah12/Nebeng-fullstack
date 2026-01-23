<?php

namespace Database\Seeders;

use App\Models\KendaraanMitra;
use App\Models\User;
use Illuminate\Database\Seeder;

class VehicleSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // Get mitra user
        $mitra = User::where('role', 'mitra')->first();
        
        if (!$mitra) {
            $this->command->warn('No mitra user found. Please run UserSeeder first.');
            return;
        }

        $vehicles = [
            // Motor
            [
                'user_id' => $mitra->id,
                'vehicle_type' => 'motor',
                'brand' => 'Honda',
                'model' => 'Beat',
                'name' => 'Honda Beat',
                'plate_number' => 'B 1234 XYZ',
                'year' => 2022,
                'color' => 'Hitam',
                'jumlah_bagasi' => 1,
                'is_active' => true,
            ],
            [
                'user_id' => $mitra->id,
                'vehicle_type' => 'motor',
                'brand' => 'Yamaha',
                'model' => 'NMAX',
                'name' => 'Yamaha NMAX',
                'plate_number' => 'B 5678 ABC',
                'year' => 2023,
                'color' => 'Putih',
                'jumlah_bagasi' => 1,
                'is_active' => true,
            ],
            [
                'user_id' => $mitra->id,
                'vehicle_type' => 'motor',
                'brand' => 'Honda',
                'model' => 'Vario 160',
                'name' => 'Honda Vario',
                'plate_number' => 'B 9012 DEF',
                'year' => 2024,
                'color' => 'Merah',
                'jumlah_bagasi' => 1,
                'is_active' => true,
            ],
            
            // Mobil
            [
                'user_id' => $mitra->id,
                'vehicle_type' => 'mobil',
                'brand' => 'Toyota',
                'model' => 'Avanza',
                'name' => 'Toyota Avanza',
                'plate_number' => 'B 1342 XYZ',
                'year' => 2021,
                'color' => 'Silver',
                'jumlah_bagasi' => 3,
                'is_active' => true,
            ],
            [
                'user_id' => $mitra->id,
                'vehicle_type' => 'mobil',
                'brand' => 'Daihatsu',
                'model' => 'Xenia',
                'name' => 'Daihatsu Xenia',
                'plate_number' => 'B 7890 GHI',
                'year' => 2022,
                'color' => 'Hitam',
                'jumlah_bagasi' => 3,
                'is_active' => true,
            ],
            [
                'user_id' => $mitra->id,
                'vehicle_type' => 'mobil',
                'brand' => 'Honda',
                'model' => 'Brio',
                'name' => 'Honda Brio',
                'plate_number' => 'B 3456 JKL',
                'year' => 2023,
                'color' => 'Putih',
                'jumlah_bagasi' => 2,
                'is_active' => true,
            ],
            
            // Pickup untuk barang
            [
                'user_id' => $mitra->id,
                'vehicle_type' => 'mobil',
                'brand' => 'Suzuki',
                'model' => 'Carry Pickup',
                'name' => 'Suzuki Carry',
                'plate_number' => 'B 6543 MNO',
                'year' => 2020,
                'color' => 'Putih',
                'jumlah_bagasi' => 5,
                'is_active' => true,
            ],
            [
                'user_id' => $mitra->id,
                'vehicle_type' => 'mobil',
                'brand' => 'Mitsubishi',
                'model' => 'L300 Pickup',
                'name' => 'Mitsubishi L300',
                'plate_number' => 'B 8765 PQR',
                'year' => 2021,
                'color' => 'Biru',
                'jumlah_bagasi' => 6,
                'is_active' => true,
            ],
        ];

        foreach ($vehicles as $vehicle) {
            KendaraanMitra::create($vehicle);
        }

        $this->command->info('Created ' . count($vehicles) . ' vehicles successfully.');
    }
}
