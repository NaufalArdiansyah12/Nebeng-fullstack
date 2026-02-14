<?php

namespace App\Enums;

/**
 * Weight Category Enum
 * 
 * Standardized weight categories for barang (goods) in booking system.
 * These categories are used in booking_motor, booking_mobil, booking_barang, 
 * and booking_titip_barang tables.
 */
enum WeightCategory: string
{
    case KECIL = 'Kecil';   // Small - Max 5 Kg
    case SEDANG = 'Sedang'; // Medium - Max 10 Kg
    case BESAR = 'Besar';   // Large - Max 20 Kg

    /**
     * Get weight limit in kilograms
     */
    public function getMaxWeight(): int
    {
        return match($this) {
            self::KECIL => 5,
            self::SEDANG => 10,
            self::BESAR => 20,
        };
    }

    /**
     * Get display label with weight
     */
    public function getLabel(): string
    {
        return match($this) {
            self::KECIL => 'Kecil - Maksimal 5 Kg',
            self::SEDANG => 'Sedang - Maksimal 10 Kg',
            self::BESAR => 'Besar - Maksimal 20 Kg',
        };
    }

    /**
     * Get all available options as array
     */
    public static function options(): array
    {
        return array_map(
            fn($case) => [
                'value' => $case->value,
                'label' => $case->getLabel(),
                'max_weight' => $case->getMaxWeight(),
            ],
            self::cases()
        );
    }

    /**
     * Validate if given weight string is valid
     */
    public static function isValid(?string $weight): bool
    {
        if ($weight === null) {
            return true; // nullable
        }
        
        return in_array($weight, array_column(self::cases(), 'value'));
    }
}
