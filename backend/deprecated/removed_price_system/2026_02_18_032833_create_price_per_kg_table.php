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
        Schema::create('price_per_kg', function (Blueprint $table) {
            $table->id();
            $table->enum('service_type', ['antar_barang', 'antar_penumpang'])->comment('Jenis layanan');
            $table->enum('ride_type', ['motor', 'mobil', 'barang', 'titip_barang'])->comment('Jenis tebengan');
            $table->decimal('rate_per_kg', 10, 2)->comment('Harga per kilogram dalam rupiah');
            $table->decimal('min_charge', 10, 2)->default(0)->comment('Minimum biaya yang dikenakan');
            $table->boolean('is_active')->default(true)->comment('Status aktif tarif');
            $table->date('effective_from')->comment('Berlaku mulai tanggal');
            $table->timestamps();
            $table->softDeletes();

            // Index untuk pencarian cepat
            $table->index(['service_type', 'ride_type', 'is_active']);
            $table->index('effective_from');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('price_per_kg');
    }
};
