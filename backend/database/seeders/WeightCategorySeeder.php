<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\WeightCategory;

class WeightCategorySeeder extends Seeder
{
    public function run(): void
    {
        $categories = [
            ['name' => 'Kecil', 'slug' => 'kecil', 'min_weight' => 0, 'max_weight' => 5],
            ['name' => 'Sedang', 'slug' => 'sedang', 'min_weight' => 5, 'max_weight' => 10],
            ['name' => 'Besar', 'slug' => 'besar', 'min_weight' => 10, 'max_weight' => 20],
        ];

        foreach ($categories as $category) {
            WeightCategory::updateOrCreate(
                ['name' => $category['name']],
                $category
            );
        }

        $this->command->info('Weight categories seeded successfully!');
    }
}
