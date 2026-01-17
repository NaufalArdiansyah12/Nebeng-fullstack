<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // Add to rides if exists
        if (Schema::hasTable('rides')) {
            Schema::table('rides', function (Blueprint $table) {
                if (!Schema::hasColumn('rides', 'bagasi_capacity')) {
                    $table->integer('bagasi_capacity')->nullable()->after('available_seats');
                }
            });
        }

        // Also add to tebengan_motor if project uses that table
        if (Schema::hasTable('tebengan_motor')) {
            Schema::table('tebengan_motor', function (Blueprint $table) {
                if (!Schema::hasColumn('tebengan_motor', 'bagasi_capacity')) {
                    $table->integer('bagasi_capacity')->nullable()->after('available_seats');
                }
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        if (Schema::hasTable('rides') && Schema::hasColumn('rides', 'bagasi_capacity')) {
            Schema::table('rides', function (Blueprint $table) {
                $table->dropColumn('bagasi_capacity');
            });
        }

        if (Schema::hasTable('tebengan_motor') && Schema::hasColumn('tebengan_motor', 'bagasi_capacity')) {
            Schema::table('tebengan_motor', function (Blueprint $table) {
                $table->dropColumn('bagasi_capacity');
            });
        }
    }
};
