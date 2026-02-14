<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        $tables = ['tebengan_motor', 'tebengan_mobil', 'tebengan_barang', 'tebengan_titip_barang'];

        foreach ($tables as $tableName) {
            if (Schema::hasTable($tableName) && Schema::hasColumn($tableName, 'jumlah_bagasi')) {
                // First, update any NULL values to 0
                DB::statement("UPDATE `{$tableName}` SET `jumlah_bagasi` = 0 WHERE `jumlah_bagasi` IS NULL");
                
                // Then, modify the column to ensure it has NOT NULL with default 0
                DB::statement("ALTER TABLE `{$tableName}` MODIFY COLUMN `jumlah_bagasi` SMALLINT UNSIGNED NOT NULL DEFAULT 0");
            }
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        // No need to reverse as this is a fix migration
    }
};
