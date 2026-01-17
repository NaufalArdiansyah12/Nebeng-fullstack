<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up()
    {
        if (Schema::hasTable('tebengan_mobil')) {
            Schema::table('tebengan_mobil', function (Blueprint $table) {
                if (!Schema::hasColumn('tebengan_mobil', 'vehicle_name')) {
                    $table->string('vehicle_name')->nullable()->after('price');
                }
                if (!Schema::hasColumn('tebengan_mobil', 'vehicle_plate')) {
                    $table->string('vehicle_plate')->nullable()->after('vehicle_name');
                }
                if (!Schema::hasColumn('tebengan_mobil', 'vehicle_brand')) {
                    $table->string('vehicle_brand')->nullable()->after('vehicle_plate');
                }
                if (!Schema::hasColumn('tebengan_mobil', 'vehicle_type')) {
                    $table->string('vehicle_type')->nullable()->after('vehicle_brand');
                }
                if (!Schema::hasColumn('tebengan_mobil', 'vehicle_color')) {
                    $table->string('vehicle_color')->nullable()->after('vehicle_type');
                }
                if (!Schema::hasColumn('tebengan_mobil', 'extra')) {
                    $table->text('extra')->nullable()->after('kendaraan_mitra_id');
                }
            });
        }
    }

    public function down()
    {
        if (Schema::hasTable('tebengan_mobil')) {
            Schema::table('tebengan_mobil', function (Blueprint $table) {
                if (Schema::hasColumn('tebengan_mobil', 'vehicle_name')) {
                    $table->dropColumn(['vehicle_name','vehicle_plate','vehicle_brand','vehicle_type','vehicle_color','extra']);
                }
            });
        }
    }
};
