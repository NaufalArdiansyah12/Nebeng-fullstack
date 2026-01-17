<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up()
    {
        if (Schema::hasTable('tebengan_mobil')) {
            Schema::table('tebengan_mobil', function (Blueprint $table) {
                if (!Schema::hasColumn('tebengan_mobil', 'bagasi_capacity')) {
                    $table->integer('bagasi_capacity')->nullable()->after('available_seats');
                }
            });
        }
    }

    public function down()
    {
        if (Schema::hasTable('tebengan_mobil')) {
            Schema::table('tebengan_mobil', function (Blueprint $table) {
                if (Schema::hasColumn('tebengan_mobil', 'bagasi_capacity')) {
                    $table->dropColumn('bagasi_capacity');
                }
            });
        }
    }
};
