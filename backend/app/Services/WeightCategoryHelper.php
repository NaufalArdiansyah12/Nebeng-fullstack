<?php

namespace App\Services;

use App\Models\WeightCategory;

class WeightCategoryHelper
{
    /**
     * Get weight category based on weight in kg
     */
    public static function getCategory(float $weight): ?WeightCategory
    {
        return WeightCategory::all()->first(function ($category) use ($weight) {
            return $category->containsWeight($weight);
        });
    }

    /**
     * Get weight category ID based on weight in kg
     */
    public static function getCategoryId(float $weight): ?int
    {
        $category = self::getCategory($weight);
        return $category ? $category->id : null;
    }

    /**
     * Get all weight categories with ranges
     */
    public static function getAllWithRanges(): array
    {
        return WeightCategory::all()->map(function ($category) {
            return [
                'id' => $category->id,
                'name' => $category->name,
                'slug' => $category->slug,
                'range' => $category->min_weight . ' - ' . $category->max_weight . ' kg',
                'min_weight' => $category->min_weight,
                'max_weight' => $category->max_weight,
            ];
        })->toArray();
    }
}
