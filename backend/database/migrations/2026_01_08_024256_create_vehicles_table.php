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
        Schema::create('vehicles', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->enum('vehicle_type', ['motor', 'mobil']);
            $table->string('name'); // Nama kendaraan/mitra
            $table->string('plate_number'); // Nomor plat
            $table->string('brand'); // Merk
            $table->string('model'); // Tipe/Model
            $table->string('color'); // Warna
            $table->integer('year')->nullable(); // Tahun pembuatan
            $table->integer('seats')->default(1); // Jumlah kursi tersedia
            $table->boolean('is_active')->default(true); // Status aktif
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('vehicles');
    }
};
