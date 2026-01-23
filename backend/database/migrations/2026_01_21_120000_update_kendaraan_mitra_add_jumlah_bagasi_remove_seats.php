<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up()
    {
        if (Schema::hasTable('kendaraan_mitra')) {
            Schema::table('kendaraan_mitra', function (Blueprint $table) {
                if (!Schema::hasColumn('kendaraan_mitra', 'jumlah_bagasi')) {
                    $table->integer('jumlah_bagasi')->default(0)->after('year');
                }

                if (Schema::hasColumn('kendaraan_mitra', 'seats')) {
                    // dropping column may require doctrine/dbal depending on DB driver
                    $table->dropColumn('seats');
                }
            });
        }
    }

    public function down()
    {
        if (Schema::hasTable('kendaraan_mitra')) {
            Schema::table('kendaraan_mitra', function (Blueprint $table) {
                if (!Schema::hasColumn('kendaraan_mitra', 'seats')) {
                    $table->integer('seats')->default(1)->after('year');
                }
                if (Schema::hasColumn('kendaraan_mitra', 'jumlah_bagasi')) {
                    $table->dropColumn('jumlah_bagasi');
                }
            });
        }
    }
};
