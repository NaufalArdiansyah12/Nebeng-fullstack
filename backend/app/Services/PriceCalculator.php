<?php

namespace App\Services;

use App\Models\PricingProfile;
use App\Models\WeightCategory;
use Illuminate\Support\Collection;

class PriceCalculator
{
    /**
     * Calculate price based on transport mode slug, weight (kg) and service type.
     * Returns array with detailed breakdown
     */
    public function calculate(string $transportModeSlug, float $weight, ?string $serviceType = null, float $distance = 0.0): array
    {
        // Find weight category matching weight (may be null for passenger calculations)
        $category = WeightCategory::all()->first(function ($c) use ($weight) {
            return $c->containsWeight($weight);
        });

        // Look for an active pricing profile scoped to transport mode, prefer exact transport match
        $profiles = PricingProfile::with('rules')->where('active', true)
            ->where(function ($q) use ($transportModeSlug) {
                $q->whereHas('transportMode', function ($q2) use ($transportModeSlug) {
                    $q2->where('slug', $transportModeSlug);
                })->orWhereNull('transport_mode_id');
            })->get();

        // Prefer profiles that best match the requested service_type and
        // business-priority fields (profiles that define a base_price or
        // explicit category prices). We score candidates so profiles that
        // include a base_price and category nominal win over a loose rule
        // match when both exist.
        if ($serviceType !== null) {
            $catSlug = $category->slug ?? null;
            $profiles = $profiles->sortByDesc(function ($p) use ($serviceType, $catSlug) {
                $score = 0;
                // give a strong priority for explicit rule matching service_type
                // so that a profile with a matching rule is preferred over a
                // profile that merely declares a base_price.
                foreach ($p->rules as $r) {
                    if ($r->service_type === $serviceType) {
                        $score += 20;
                        break;
                    }
                }

                // modest score for profiles that declare a base price
                if (isset($p->base_price) && $p->base_price > 0) {
                    $score += 5;
                }

                // additional score when profile has explicit category nominal
                if ($catSlug) {
                    $field = 'price_category_' . $catSlug;
                    if (isset($p->{$field}) && $p->{$field} !== null && $p->{$field} > 0) {
                        $score += 7;
                    }
                }

                return $score;
            })->values();
        }

        // Determine whether this service should be treated as flat-category
        // (barang / titip). If so, prefer profile-level category nominals
        // (base + price_category_*) over rule-level price matches.
        $isFlatCategoryRequest = false;
        if ($serviceType !== null) {
            $stLower = strtolower($serviceType);
            // Treat only pure 'hanya_barang' and any 'titip' variants as
            // flat-category (no distance charge). Do NOT treat combined
            // 'tebengan_dan_barang' as flat — it should include distance.
            if ($stLower === 'hanya_barang' || str_contains($stLower, 'titip')) {
                $isFlatCategoryRequest = true;
            }
        }

        // Search for a specific pricing rule first (weight category + service type) if category found
        foreach ($profiles as $profile) {
            if ($category) {
                // If this request is a flat-category type and the profile
                // defines explicit category nominals, use that first.
                $catSlug = $category->slug ?? null;
                if ($isFlatCategoryRequest && $catSlug) {
                    $field = 'price_category_' . $catSlug;
                    if (isset($profile->{$field}) && $profile->{$field} !== null && $profile->{$field} > 0) {
                        $base = (float) ($profile->base_price ?? 0);
                        $ppkm = (float) ($profile->price_per_km ?? 0);
                        $distanceCharge = $ppkm * $distance;
                        if ($isFlatCategoryRequest) {
                            $distanceCharge = 0;
                        }
                        $categoryPrice = (float) $profile->{$field};
                        $total = $base + $distanceCharge + $categoryPrice;
                        $min = isset($profile->min_price) ? (float)$profile->min_price : null;
                        if ($min !== null && $total < $min) $total = $min;

                        return [
                            'unit_price' => $categoryPrice,
                            'total' => round($total, 2),
                            'base_price' => $base,
                            'distance_charge' => round($distanceCharge, 2),
                            'category_price' => $categoryPrice,
                            'profile_name' => $profile->name,
                            'category' => $catSlug,
                        ];
                    }
                }

                $rule = $profile->rules()->where('weight_category_id', $category->id)
                    ->where(function ($q) use ($serviceType) {
                        if ($serviceType === null) {
                            $q->whereNull('service_type');
                        } else {
                            $q->where('service_type', $serviceType);
                        }
                    })->first();

                if ($rule) {
                    // If rule defines explicit columns, prefer them
                    // Use profile-level base and per-km values for distance/base
                    // charges, but use the rule's price for category/weight
                    // component. Rules typically only store 'price' (category
                    // nominal), so prefer profile fields for base/ppkm.
                    $base = (float) ($profile->base_price ?? 0);
                    $ppkm = (float) ($profile->price_per_km ?? 0);
                    // By default prefer rule->price, but if the profile
                    // declares an explicit category nominal (price_category_*),
                    // prefer that for combined services so category-level
                    // pricing from profile wins over a possibly different rule value.
                    $ppkg = (float) ($rule->price ?? $rule->price_per_kg ?? $profile->price_per_kg ?? 0);
                    $catSlugLocal = $category->slug ?? null;
                    if ($catSlugLocal) {
                        $fieldLocal = 'price_category_' . $catSlugLocal;
                        if (isset($profile->{$fieldLocal}) && $profile->{$fieldLocal} !== null && $profile->{$fieldLocal} > 0) {
                            // For tebengan_dan_barang we want profile-level category nominal
                            // to be used instead of rule->price so the larger profile
                            // category values (e.g., 15000) take effect.
                            if (strtolower($serviceType) === 'tebengan_dan_barang' || strtolower($serviceType) === 'hanya_barang') {
                                $ppkg = (float) $profile->{$fieldLocal};
                            }
                        }
                    }
                    $distanceCharge = $ppkm * $distance;

                    // For flat-category requests (barang/titip), distance
                    // charge should not apply — price is base + category nominal.
                    if ($isFlatCategoryRequest) {
                        $distanceCharge = 0;
                    }

                    // For certain 'barang' / 'titip' service types the rule->price
                    // represents a flat nominal for the selected weight category
                    // (not a per-kg rate). Treat 'hanya_barang' and any service
                    // type containing 'titip' as flat-category pricing.
                    $isFlatCategory = false;
                    if ($serviceType !== null) {
                        $st = strtolower($serviceType);
                        // Treat pure 'hanya_barang' and 'tebengan_dan_barang'
                        // as category-nominal for the rule price (flat), but
                        // only 'hanya_barang' and 'titip' requests will be
                        // considered fully flat (no distance charge).
                        if ($st === 'hanya_barang' || $st === 'tebengan_dan_barang' || str_contains($st, 'titip')) {
                            $isFlatCategory = true;
                        }
                    }

                    if ($isFlatCategory) {
                        $weightCharge = $ppkg; // flat nominal for category
                    } else {
                        // If ppkg was taken from profile category (flat nominal)
                        // but service is not flat, still treat it as flat nominal
                        // for category pricing (we don't multiply profile category
                        // by weight). Otherwise, use per-kg multiply.
                        $weightCharge = ($ppkg && isset($profile->{'price_category_' . ($category->slug ?? '')}) && $profile->{'price_category_' . ($category->slug ?? '')} > 0)
                            ? $ppkg
                            : $ppkg * $weight;
                    }

                    $total = $base + $distanceCharge + $weightCharge;
                    $min = isset($rule->min_price) ? (float)$rule->min_price : null;
                    if ($min !== null && $total < $min) $total = $min;

                    return [
                        'unit_price' => $ppkg, 
                        'total' => round($total, 2),
                        'base_price' => $base,
                        'distance_charge' => round($distanceCharge, 2),
                        'weight_charge' => round($weightCharge, 2),
                        'profile_name' => $profile->name
                    ];
                }

                // If profile defines explicit category prices (price_category_kecil/sedang/besar), prefer those
                $catSlug = $category->slug ?? null;
                if ($catSlug) {
                    $field = 'price_category_' . $catSlug;
                    if (isset($profile->{$field}) && $profile->{$field} !== null && $profile->{$field} > 0) {
                        $base = (float) ($profile->base_price ?? 0);
                        $ppkm = (float) ($profile->price_per_km ?? 0);
                        $distanceCharge = $ppkm * $distance;
                        if ($isFlatCategoryRequest) {
                            $distanceCharge = 0;
                        }
                        $categoryPrice = (float) $profile->{$field};
                        $total = $base + $distanceCharge + $categoryPrice;
                        $min = isset($profile->min_price) ? (float)$profile->min_price : null;
                        if ($min !== null && $total < $min) $total = $min;

                        return [
                            'unit_price' => $categoryPrice,
                            'total' => round($total, 2),
                            'base_price' => $base,
                            'distance_charge' => round($distanceCharge, 2),
                            'category_price' => $categoryPrice,
                            'profile_name' => $profile->name,
                            'category' => $catSlug,
                        ];
                    }
                }
            }

            // Fallback to profile-level pricing fields (works even if no category)
            $base = (float) ($profile->base_price ?? 0);
            $ppkm = (float) ($profile->price_per_km ?? 0);
            $ppkg = (float) ($profile->price_per_kg ?? 0);
            // Ensure flat-category requests do not incur distance charges
            if ($isFlatCategoryRequest) {
                $distanceCharge = 0;
            } else {
                $distanceCharge = $ppkm * $distance;
            }
            $weightCharge = $ppkg * $weight;
            $total = $base + $distanceCharge + $weightCharge;
            $min = isset($profile->min_price) ? (float)$profile->min_price : null;
            if ($min !== null && $total < $min) $total = $min;
            
            return [
                'unit_price' => $ppkg, 
                'total' => round($total, 2),
                'base_price' => $base,
                'distance_charge' => round($distanceCharge, 2),
                'weight_charge' => round($weightCharge, 2),
                'profile_name' => $profile->name
            ];
        }

        return [
            'unit_price' => 0, 
            'total' => 0,
            'base_price' => 0,
            'distance_charge' => 0,
            'weight_charge' => 0,
            'profile_name' => null
        ];
    }
}
