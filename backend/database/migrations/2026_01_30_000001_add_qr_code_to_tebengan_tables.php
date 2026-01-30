<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // Add qr_code_data column to tebengan_motor
        if (Schema::hasTable('tebengan_motor') && !Schema::hasColumn('tebengan_motor', 'qr_code_data')) {
            Schema::table('tebengan_motor', function (Blueprint $table) {
                $table->string('qr_code_data', 500)->nullable()->after('status');
                $table->index('qr_code_data');
            });
        }

        // Add qr_code_data column to tebengan_mobil
        if (Schema::hasTable('tebengan_mobil') && !Schema::hasColumn('tebengan_mobil', 'qr_code_data')) {
            Schema::table('tebengan_mobil', function (Blueprint $table) {
                $table->string('qr_code_data', 500)->nullable()->after('status');
                $table->index('qr_code_data');
            });
        }

        // Add qr_code_data column to tebengan_barang
        if (Schema::hasTable('tebengan_barang') && !Schema::hasColumn('tebengan_barang', 'qr_code_data')) {
            Schema::table('tebengan_barang', function (Blueprint $table) {
                $table->string('qr_code_data', 500)->nullable()->after('status');
                $table->index('qr_code_data');
            });
        }

        // Add qr_code_data column to tebengan_titip_barang
        if (Schema::hasTable('tebengan_titip_barang') && !Schema::hasColumn('tebengan_titip_barang', 'qr_code_data')) {
            Schema::table('tebengan_titip_barang', function (Blueprint $table) {
                $table->string('qr_code_data', 500)->nullable()->after('status');
                $table->index('qr_code_data');
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        if (Schema::hasColumn('tebengan_motor', 'qr_code_data')) {
            Schema::table('tebengan_motor', function (Blueprint $table) {
                $table->dropIndex(['qr_code_data']);
                $table->dropColumn('qr_code_data');
            });
        }

        if (Schema::hasColumn('tebengan_mobil', 'qr_code_data')) {
            Schema::table('tebengan_mobil', function (Blueprint $table) {
                $table->dropIndex(['qr_code_data']);
                $table->dropColumn('qr_code_data');
            });
        }

        if (Schema::hasColumn('tebengan_barang', 'qr_code_data')) {
            Schema::table('tebengan_barang', function (Blueprint $table) {
                $table->dropIndex(['qr_code_data']);
                $table->dropColumn('qr_code_data');
            });
        }

        if (Schema::hasColumn('tebengan_titip_barang', 'qr_code_data')) {
            Schema::table('tebengan_titip_barang', function (Blueprint $table) {
                $table->dropIndex(['qr_code_data']);
                $table->dropColumn('qr_code_data');
            });
        }
    }
};
