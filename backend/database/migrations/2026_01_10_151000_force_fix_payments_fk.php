<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration {
    public function up()
    {
        if (Schema::hasTable('payments')) {
            Schema::table('payments', function (Blueprint $table) {
                // Drop existing FK if present
                try {
                    $table->dropForeign(['ride_id']);
                } catch (\Exception $e) {
                    // ignore
                }
            });

            // Recreate FK to point to tebengan_mobil if exists
            if (Schema::hasTable('tebengan_mobil')) {
                Schema::table('payments', function (Blueprint $table) {
                    try {
                        $table->foreign('ride_id')
                            ->references('id')
                            ->on('tebengan_mobil')
                            ->onDelete('cascade');
                    } catch (\Exception $e) {
                        // ignore
                    }
                });
            } else if (Schema::hasTable('rides')) {
                Schema::table('payments', function (Blueprint $table) {
                    try {
                        $table->foreign('ride_id')
                            ->references('id')
                            ->on('rides')
                            ->onDelete('cascade');
                    } catch (\Exception $e) {
                        // ignore
                    }
                });
            }
        }
    }

    public function down()
    {
        if (Schema::hasTable('payments')) {
            Schema::table('payments', function (Blueprint $table) {
                try {
                    $table->dropForeign(['ride_id']);
                } catch (\Exception $e) {
                    // ignore
                }
            });
        }
    }
};
