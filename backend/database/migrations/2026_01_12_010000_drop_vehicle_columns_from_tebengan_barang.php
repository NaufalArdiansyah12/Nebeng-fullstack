<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up()
    {
        if (Schema::hasTable('tebengan_barang')) {
            Schema::table('tebengan_barang', function (Blueprint $table) {
                // Drop vehicle columns if they exist
                if (Schema::hasColumn('tebengan_barang', 'vehicle_name')) {
                    $table->dropColumn('vehicle_name');
                }
                if (Schema::hasColumn('tebengan_barang', 'vehicle_plate')) {
                    $table->dropColumn('vehicle_plate');
                }
                if (Schema::hasColumn('tebengan_barang', 'vehicle_brand')) {
                    $table->dropColumn('vehicle_brand');
                }
                if (Schema::hasColumn('tebengan_barang', 'vehicle_type')) {
                    $table->dropColumn('vehicle_type');
                }
                if (Schema::hasColumn('tebengan_barang', 'vehicle_color')) {
                    $table->dropColumn('vehicle_color');
                }
            });
        }
    }

    public function down()
    {
        if (Schema::hasTable('tebengan_barang')) {
            Schema::table('tebengan_barang', function (Blueprint $table) {
                // Recreate columns if missing
                if (!Schema::hasColumn('tebengan_barang', 'vehicle_name')) {
                    $table->string('vehicle_name')->nullable()->after('price');
                }
                if (!Schema::hasColumn('tebengan_barang', 'vehicle_plate')) {
                    $table->string('vehicle_plate')->nullable()->after('vehicle_name');
                }
                if (!Schema::hasColumn('tebengan_barang', 'vehicle_brand')) {
                    $table->string('vehicle_brand')->nullable()->after('vehicle_plate');
                }
                if (!Schema::hasColumn('tebengan_barang', 'vehicle_type')) {
                    $table->string('vehicle_type')->nullable()->after('vehicle_brand');
                }
                if (!Schema::hasColumn('tebengan_barang', 'vehicle_color')) {
                    $table->string('vehicle_color')->nullable()->after('vehicle_type');
                }
            });
        }
    }
};
