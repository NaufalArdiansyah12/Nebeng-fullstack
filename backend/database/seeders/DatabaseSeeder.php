<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        // Seed users with different roles
        $this->call(\Database\Seeders\UserSeeder::class);

        // Seed default locations
        $this->call(\Database\Seeders\LocationSeeder::class);

        // Seed vehicles for mitra
        $this->call(\Database\Seeders\VehicleSeeder::class);

        // Seed rides for all types
        $this->call(\Database\Seeders\RideSeeder::class);
        $this->call(\Database\Seeders\CarRideSeeder::class);
        $this->call(\Database\Seeders\BarangRideSeeder::class);
        $this->call(\Database\Seeders\TebenganTitipBarangSeeder::class);
    }
}
