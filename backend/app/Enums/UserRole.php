<?php

namespace App\Enums;

enum UserRole: string
{
    case CUSTOMER = 'customer';
    case MITRA = 'mitra';
    case POSMITRA = 'posmitra';
    case FINANCE = 'finance';
    case ADMIN = 'admin';
    case SUPERADMIN = 'superadmin';

    /**
     * Get all role values as array
     */
    public static function values(): array
    {
        return array_column(self::cases(), 'value');
    }

    /**
     * Check if the role is customer
     */
    public function isCustomer(): bool
    {
        return $this === self::CUSTOMER;
    }

    /**
     * Check if the role is mitra
     */
    public function isMitra(): bool
    {
        return $this === self::MITRA;
    }

    /**
     * Check if the role is pos mitra
     */
    public function isPosMitra(): bool
    {
        return $this === self::POSMITRA;
    }

    /**
     * Check if the role is finance
     */
    public function isFinance(): bool
    {
        return $this === self::FINANCE;
    }

    /**
     * Check if the role is admin
     */
    public function isAdmin(): bool
    {
        return $this === self::ADMIN;
    }

    /**
     * Check if the role is superadmin
     */
    public function isSuperAdmin(): bool
    {
        return $this === self::SUPERADMIN;
    }

    /**
     * Get label for display
     */
    public function label(): string
    {
        return match($this) {
            self::CUSTOMER => 'Customer',
            self::MITRA => 'Mitra',
            self::POSMITRA => 'Pos Mitra',
            self::FINANCE => 'Finance',
            self::ADMIN => 'Admin',
            self::SUPERADMIN => 'Super Admin',
        };
    }
}
