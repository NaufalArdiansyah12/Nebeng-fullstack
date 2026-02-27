<?php

namespace App\Http\Controllers\Finance;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\TransportMode;
use App\Models\WeightCategory;
use App\Models\PricingProfile;
use App\Models\PricingRule;
use Illuminate\Support\Facades\DB;

class PricingConfigController extends Controller
{
    /**
     * Get all transport modes with their pricing configurations
     */
    public function index()
    {
        $modes = TransportMode::with([
            'pricingProfiles' => function($q) {
                $q->where('active', true)->with(['rules.weightCategory']);
            }
        ])->get();

        return response()->json(['success' => true, 'data' => $modes]);
    }

    /**
     * Get pricing config for a specific transport mode
     */
    public function show($slug)
    {
        $mode = TransportMode::where('slug', $slug)
            ->with([
                'pricingProfiles' => function($q) {
                    $q->where('active', true)->with(['rules.weightCategory']);
                }
            ])
            ->first();

        if (!$mode) {
            return response()->json(['success' => false, 'message' => 'Transport mode not found'], 404);
        }

        return response()->json(['success' => true, 'data' => $mode]);
    }

    /**
     * Update pricing config for a transport mode
     */
    public function update(Request $request, $slug)
    {
        $mode = TransportMode::where('slug', $slug)->first();

        if (!$mode) {
            return response()->json(['success' => false, 'message' => 'Transport mode not found'], 404);
        }

        $data = $request->validate([
            'configs' => 'required|array',
            'configs.*.service_type' => 'nullable|string',
            'configs.*.base_price' => 'nullable|numeric',
            'configs.*.price_per_km' => 'nullable|numeric',
            'configs.*.min_price' => 'nullable|numeric',
            'configs.*.price_category_kecil' => 'nullable|numeric',
            'configs.*.price_category_sedang' => 'nullable|numeric',
            'configs.*.price_category_besar' => 'nullable|numeric',
            'configs.*.weight_rules' => 'nullable|array',
            'configs.*.weight_rules.*.category' => 'required|string',
            'configs.*.weight_rules.*.price_per_kg' => 'required|numeric',
        ]);

        DB::beginTransaction();
        try {
            foreach ($data['configs'] as $config) {
                $serviceType = $config['service_type'] ?? null;
                $profileName = $mode->name . ' - ' . ($serviceType ? ucfirst(str_replace('_', ' ', $serviceType)) : 'Default');

                // Helper: round to nearest 500
                $roundNearest = function ($value, $nearest = 500) {
                    if ($value === null) return null;
                    return round($value / $nearest) * $nearest;
                };

                // Create or update profile
                $updateData = [
                    'description' => 'Konfigurasi untuk ' . $profileName,
                    'active' => true,
                    'base_price' => $roundNearest($config['base_price'] ?? 0),
                    'price_per_km' => $roundNearest($config['price_per_km'] ?? 0),
                    'min_price' => $roundNearest($config['min_price'] ?? null),
                ];

                // Only set price_category_* if explicitly provided in the payload
                if (array_key_exists('price_category_kecil', $config)) {
                    $updateData['price_category_kecil'] = $config['price_category_kecil'];
                }
                if (array_key_exists('price_category_sedang', $config)) {
                    $updateData['price_category_sedang'] = $config['price_category_sedang'];
                }
                if (array_key_exists('price_category_besar', $config)) {
                    $updateData['price_category_besar'] = $config['price_category_besar'];
                }

                $profile = PricingProfile::updateOrCreate(
                    [
                        'transport_mode_id' => $mode->id,
                        'name' => $profileName
                    ],
                    $updateData
                );

                // Update weight rules if provided (untuk motor/mobil dengan service type hanya_barang/tebengan_dan_barang)
                if (isset($config['weight_rules']) && is_array($config['weight_rules'])) {
                    foreach ($config['weight_rules'] as $weightRule) {
                        $category = WeightCategory::where('slug', $weightRule['category'])->first();
                        if ($category) {
                            PricingRule::updateOrCreate(
                                [
                                    'pricing_profile_id' => $profile->id,
                                    'weight_category_id' => $category->id,
                                    'service_type' => $serviceType
                                ],
                                [
                                    'price' => $roundNearest($weightRule['price_per_kg'] ?? 0)
                                ]
                            );
                        }
                    }

                    // Also persist the weight category prices onto the profile columns
                    // to support UIs that expect price_category_kecil/sedang/besar to be populated.
                    $mapping = array_column($config['weight_rules'], 'price_per_kg', 'category');
                    $profileUpdate = [];
                    if (array_key_exists('kecil', $mapping)) {
                        $profileUpdate['price_category_kecil'] = $roundNearest($mapping['kecil']);
                    }
                    if (array_key_exists('sedang', $mapping)) {
                        $profileUpdate['price_category_sedang'] = $roundNearest($mapping['sedang']);
                    }
                    if (array_key_exists('besar', $mapping)) {
                        $profileUpdate['price_category_besar'] = $roundNearest($mapping['besar']);
                    }
                    if (!empty($profileUpdate)) {
                        $profile->update($profileUpdate);
                    }
                } else {
                    // For service types without weight rules (e.g., hanya_tebengan)
                    PricingRule::updateOrCreate(
                        [
                            'pricing_profile_id' => $profile->id,
                            'service_type' => $serviceType
                        ],
                        [
                            'weight_category_id' => null
                        ]
                    );
                }
            }

            DB::commit();

            return response()->json([
                'success' => true,
                'message' => 'Konfigurasi harga berhasil diperbarui'
            ]);
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json([
                'success' => false,
                'message' => 'Gagal memperbarui konfigurasi: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get weight categories
     */
    public function weightCategories()
    {
        $categories = WeightCategory::all();
        return response()->json(['success' => true, 'data' => $categories]);
    }
}
