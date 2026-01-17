<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration {
    public function up()
    {
        if (Schema::hasTable('booking_mobil')) {
            // Ensure tebengan_mobil exists
            if (Schema::hasTable('tebengan_mobil')) {
                Schema::table('booking_mobil', function (Blueprint $table) {
                    // Drop existing FK if exists
                    try {
                        $table->dropForeign(['ride_id']);
                    } catch (\Exception $e) {
                        // ignore if does not exist
                    }
                    
                    // Add FK pointing to tebengan_mobil
                    try {
                        $table->foreign('ride_id')
                            ->references('id')
                            ->on('tebengan_mobil')
                            ->onDelete('cascade');
                    } catch (\Exception $e) {
                        // ignore if already exists
                    }
                });
            }
        }
    }

    public function down()
    {
        if (Schema::hasTable('booking_mobil')) {
            Schema::table('booking_mobil', function (Blueprint $table) {
                try {
                    $table->dropForeign(['ride_id']);
                } catch (\Exception $e) {
                    // ignore
                }
            });
        }
    }
};
