<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up()
    {
        $tables = ['tebengan_motor', 'tebengan_mobil', 'tebengan_barang', 'tebengan_titip_barang'];

        foreach ($tables as $tableName) {
            if (Schema::hasTable($tableName)) {
                Schema::table($tableName, function (Blueprint $table) use ($tableName) {
                    if (!Schema::hasColumn($tableName, 'jumlah_bagasi')) {
                        $table->unsignedSmallInteger('jumlah_bagasi')->default(0);
                    }
                });
            }
        }
    }

    public function down()
    {
        $tables = ['tebengan_motor', 'tebengan_mobil', 'tebengan_barang', 'tebengan_titip_barang'];

        foreach ($tables as $tableName) {
            if (Schema::hasTable($tableName) && Schema::hasColumn($tableName, 'jumlah_bagasi')) {
                Schema::table($tableName, function (Blueprint $table) {
                    $table->dropColumn('jumlah_bagasi');
                });
            }
        }
    }
};
