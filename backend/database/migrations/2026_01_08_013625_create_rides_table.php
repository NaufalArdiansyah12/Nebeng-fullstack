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
        Schema::create('rides', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->foreignId('origin_location_id')->constrained('locations')->onDelete('cascade');
            $table->foreignId('destination_location_id')->constrained('locations')->onDelete('cascade');
            $table->date('departure_date');
            $table->time('departure_time');
            $table->enum('ride_type', ['motor', 'mobil'])->default('motor');
            $table->enum('service_type', ['tebengan', 'barang', 'both'])->default('tebengan');
            $table->decimal('price', 10, 2);
            $table->string('vehicle_name')->nullable();
            $table->string('vehicle_plate')->nullable();
            $table->string('vehicle_brand')->nullable();
            $table->string('vehicle_type')->nullable();
            $table->string('vehicle_color')->nullable();
            $table->integer('available_seats')->default(1);
            $table->enum('status', ['active', 'full', 'completed', 'cancelled'])->default('active');
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('rides');
    }
};
