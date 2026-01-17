<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up()
    {
        if (Schema::hasTable('tebengan_motor') && !Schema::hasColumn('tebengan_motor', 'kendaraan_mitra_id')) {
            Schema::table('tebengan_motor', function (Blueprint $table) {
                $table->unsignedBigInteger('kendaraan_mitra_id')->nullable()->after('user_id');
                $table->foreign('kendaraan_mitra_id')->references('id')->on('kendaraan_mitra')->onDelete('set null');
            });
        }

        if (Schema::hasTable('tebengan_mobil') && !Schema::hasColumn('tebengan_mobil', 'kendaraan_mitra_id')) {
            Schema::table('tebengan_mobil', function (Blueprint $table) {
                $table->unsignedBigInteger('kendaraan_mitra_id')->nullable()->after('user_id');
                $table->foreign('kendaraan_mitra_id')->references('id')->on('kendaraan_mitra')->onDelete('set null');
            });
        }
    }

    public function down()
    {
        if (Schema::hasTable('tebengan_motor') && Schema::hasColumn('tebengan_motor', 'kendaraan_mitra_id')) {
            Schema::table('tebengan_motor', function (Blueprint $table) {
                $table->dropForeign(['kendaraan_mitra_id']);
                $table->dropColumn('kendaraan_mitra_id');
            });
        }

        if (Schema::hasTable('tebengan_mobil') && Schema::hasColumn('tebengan_mobil', 'kendaraan_mitra_id')) {
            Schema::table('tebengan_mobil', function (Blueprint $table) {
                $table->dropForeign(['kendaraan_mitra_id']);
                $table->dropColumn('kendaraan_mitra_id');
            });
        }
    }
};
