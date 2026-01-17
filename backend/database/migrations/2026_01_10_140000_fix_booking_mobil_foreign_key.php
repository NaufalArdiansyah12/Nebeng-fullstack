<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up()
    {
        if (Schema::hasTable('booking_mobil')) {
            Schema::table('booking_mobil', function (Blueprint $table) {
                // Drop existing foreign key if present
                try {
                    $table->dropForeign(['ride_id']);
                } catch (\Exception $e) {
                    // ignore
                }

                // Add foreign key to tebengan_mobil (car rides)
                if (Schema::hasTable('tebengan_mobil')) {
                    $table->foreign('ride_id')->references('id')->on('tebengan_mobil')->onDelete('cascade');
                } else if (Schema::hasTable('rides')) {
                    // fallback if tebengan_mobil not present
                    $table->foreign('ride_id')->references('id')->on('rides')->onDelete('cascade');
                }
            });
        }
    }

    public function down()
    {
        if (Schema::hasTable('booking_mobil')) {
            Schema::table('booking_mobil', function (Blueprint $table) {
                try {
                    $table->dropForeign(['ride_id']);
                } catch (\Exception $e) {
                }

                // restore to rides/tebengan_motor if exists
                if (Schema::hasTable('rides')) {
                    $table->foreign('ride_id')->references('id')->on('rides')->onDelete('cascade');
                }
            });
        }
    }
};
