<?php

namespace Database\Seeders;

use App\Models\Location;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class LocationSeeder extends Seeder
{
    use WithoutModelEvents;

    public function run(): void
    {
        $positions = [
            ['name' => 'Terminal Blok M - Jakarta', 'city' => 'Jakarta', 'address' => 'Jl. Blok M No.1', 'latitude' => -6.241243, 'longitude' => 106.800121],
            ['name' => 'Stasiun Gambir - Jakarta', 'city' => 'Jakarta', 'address' => 'Jl. Stasiun Gambir', 'latitude' => -6.174465, 'longitude' => 106.827170],
            ['name' => 'Stasiun Bandung - Bandung', 'city' => 'Bandung', 'address' => 'Jl. Stasiun Bandung', 'latitude' => -6.896444, 'longitude' => 107.620887],
        ];

        foreach ($positions as $pos) {
            Location::create(array_merge($pos, ['created_by_role' => 'seed']));
        }
    }
}
