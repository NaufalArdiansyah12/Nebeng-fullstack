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
        if (Schema::hasTable('booking_motor')) {
            Schema::table('booking_motor', function (Blueprint $table) {
                if (!Schema::hasColumn('booking_motor', 'tracking_window_hours')) {
                    $table->smallInteger('tracking_window_hours')->nullable()->default(2)->after('scheduled_at')->comment('Hours before scheduled time when tracking/map becomes active');
                }
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        if (Schema::hasTable('booking_motor')) {
            Schema::table('booking_motor', function (Blueprint $table) {
                if (Schema::hasColumn('booking_motor', 'tracking_window_hours')) {
                    $table->dropColumn('tracking_window_hours');
                }
            });
        }
    }
};
