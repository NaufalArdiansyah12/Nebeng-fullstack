<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use App\Models\Reward;

class RewardSeeder extends Seeder
{
    use WithoutModelEvents;

    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $items = [
            [
                'title' => 'Mug Nebeng',
                'description' => 'Mug cantik bertuliskan Nebeng',
                'points_cost' => 150,
                'image_url' => 'https://via.placeholder.com/600x300?text=Mug',
                'stock' => 50,
            ],
            [
                'title' => 'T-shirt Nebeng',
                'description' => 'Kaos keren edisi Nebeng',
                'points_cost' => 300,
                'image_url' => 'https://via.placeholder.com/600x300?text=T-shirt',
                'stock' => 30,
            ],
            [
                'title' => 'Tumbler Nebeng',
                'description' => 'Tumbler untuk menjaga kesegaran minumanmu',
                'points_cost' => 200,
                'image_url' => 'https://via.placeholder.com/600x300?text=Tumbler',
                'stock' => 40,
            ],
        ];

        foreach ($items as $it) {
            Reward::updateOrCreate([
                'title' => $it['title'],
            ], $it);
        }
    }
}
