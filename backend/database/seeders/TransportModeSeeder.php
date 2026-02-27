<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\TransportMode;

class TransportModeSeeder extends Seeder
{
    public function run(): void
    {
        $modes = [
            ['name' => 'Motor', 'slug' => 'motor'],
            ['name' => 'Mobil', 'slug' => 'mobil'],
            ['name' => 'Barang', 'slug' => 'barang'],
            ['name' => 'Titip Barang - Bus', 'slug' => 'titip-barang-bus'],
            ['name' => 'Titip Barang - Kereta', 'slug' => 'titip-barang-kereta'],
            ['name' => 'Titip Barang - Pesawat', 'slug' => 'titip-barang-pesawat'],
        ];

        foreach ($modes as $mode) {
            TransportMode::updateOrCreate(
                ['slug' => $mode['slug']],
                $mode
            );
        }

        $this->command->info('Transport modes seeded successfully!');
    }
}
