<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     * 
     * Add documentation/comments for weight field options.
     * Weight field now uses standardized values:
     * - 'Kecil' (Maksimal 5 Kg)
     * - 'Sedang' (Maksimal 10 Kg)
     * - 'Besar' (Maksimal 20 Kg)
     */
    public function up(): void
    {
        // Add comments to weight columns in booking tables
        $tables = [
            'booking_motor',
            'booking_mobil', 
            'booking_barang',
            'booking_titip_barang'
        ];

        foreach ($tables as $table) {
            if (Schema::hasTable($table) && Schema::hasColumn($table, 'weight')) {
                DB::statement("ALTER TABLE `{$table}` MODIFY COLUMN `weight` VARCHAR(255) NULL COMMENT 'Pilihan: Kecil (Maks. 5kg), Sedang (Maks. 10kg), Besar (Maks. 20kg)'");
            }
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        // Remove comments from weight columns
        $tables = [
            'booking_motor',
            'booking_mobil', 
            'booking_barang',
            'booking_titip_barang'
        ];

        foreach ($tables as $table) {
            if (Schema::hasTable($table) && Schema::hasColumn($table, 'weight')) {
                DB::statement("ALTER TABLE `{$table}` MODIFY COLUMN `weight` VARCHAR(255) NULL");
            }
        }
    }
};
