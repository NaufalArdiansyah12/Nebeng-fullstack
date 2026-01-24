<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        if (Schema::hasTable('booking_motor') && Schema::hasColumn('booking_motor', 'tracking_window_hours')) {
            Schema::table('booking_motor', function (Blueprint $table) {
                $table->dropColumn('tracking_window_hours');
            });
        }
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        if (Schema::hasTable('booking_motor') && !Schema::hasColumn('booking_motor', 'tracking_window_hours')) {
            Schema::table('booking_motor', function (Blueprint $table) {
                $table->smallInteger('tracking_window_hours')->nullable()->default(2)->after('scheduled_at')->comment('Hours before scheduled time when tracking/map becomes active');
            });
        }
    }
};
