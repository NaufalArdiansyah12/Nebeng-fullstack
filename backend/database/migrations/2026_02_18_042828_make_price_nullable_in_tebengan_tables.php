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
        // Make price nullable in tebengan_motor
        Schema::table('tebengan_motor', function (Blueprint $table) {
            $table->decimal('price', 10, 2)->nullable()->change();
        });

        // Make price nullable in tebengan_mobil
        Schema::table('tebengan_mobil', function (Blueprint $table) {
            $table->decimal('price', 12, 2)->nullable()->change();
        });

        // Make price nullable in tebengan_barang
        Schema::table('tebengan_barang', function (Blueprint $table) {
            $table->decimal('price', 12, 2)->nullable()->change();
        });

        // Make price nullable in tebengan_titip_barang
        Schema::table('tebengan_titip_barang', function (Blueprint $table) {
            $table->decimal('price', 12, 2)->nullable()->change();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        // Revert price to not nullable in tebengan_motor
        Schema::table('tebengan_motor', function (Blueprint $table) {
            $table->decimal('price', 10, 2)->nullable(false)->change();
        });

        // Revert price to not nullable in tebengan_mobil
        Schema::table('tebengan_mobil', function (Blueprint $table) {
            $table->decimal('price', 12, 2)->default(0)->nullable(false)->change();
        });

        // Revert price to not nullable in tebengan_barang
        Schema::table('tebengan_barang', function (Blueprint $table) {
            $table->decimal('price', 12, 2)->default(0)->nullable(false)->change();
        });

        // Revert price to not nullable in tebengan_titip_barang
        Schema::table('tebengan_titip_barang', function (Blueprint $table) {
            $table->decimal('price', 12, 2)->nullable(false)->change();
        });
    }
};
