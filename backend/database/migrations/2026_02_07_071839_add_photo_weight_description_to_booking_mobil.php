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
        if (!Schema::hasColumn('booking_mobil', 'photo') ||
            !Schema::hasColumn('booking_mobil', 'weight') ||
            !Schema::hasColumn('booking_mobil', 'description')) {
            Schema::table('booking_mobil', function (Blueprint $table) {
                if (!Schema::hasColumn('booking_mobil', 'photo')) {
                    $table->string('photo')->nullable()->after('meta');
                }
                if (!Schema::hasColumn('booking_mobil', 'weight')) {
                    $table->string('weight')->nullable()->after('photo');
                }
                if (!Schema::hasColumn('booking_mobil', 'description')) {
                    $table->text('description')->nullable()->after('weight');
                }
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('booking_mobil', function (Blueprint $table) {
            if (Schema::hasColumn('booking_mobil', 'description')) {
                $table->dropColumn('description');
            }
            if (Schema::hasColumn('booking_mobil', 'weight')) {
                $table->dropColumn('weight');
            }
            if (Schema::hasColumn('booking_mobil', 'photo')) {
                $table->dropColumn('photo');
            }
        });
    }
};
