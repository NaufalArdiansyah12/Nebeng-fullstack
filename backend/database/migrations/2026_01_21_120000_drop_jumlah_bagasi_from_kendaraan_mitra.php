<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class DropJumlahBagasiFromKendaraanMitra extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        if (Schema::hasColumn('kendaraan_mitra', 'jumlah_bagasi')) {
            Schema::table('kendaraan_mitra', function (Blueprint $table) {
                $table->dropColumn('jumlah_bagasi');
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
        if (!Schema::hasColumn('kendaraan_mitra', 'jumlah_bagasi')) {
            Schema::table('kendaraan_mitra', function (Blueprint $table) {
                $table->integer('jumlah_bagasi')->nullable();
            });
        }
    }
}
