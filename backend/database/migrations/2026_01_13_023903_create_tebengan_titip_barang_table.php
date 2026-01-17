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
        Schema::create('tebengan_titip_barang', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('user_id'); // user_id of mitra
            
            $table->unsignedBigInteger('origin_location_id');
            $table->unsignedBigInteger('destination_location_id');
            $table->date('departure_date');
            $table->time('departure_time');
            
            $table->string('transportation_type'); // kereta, pesawat, bus
            $table->integer('bagasi_capacity'); // 5, 10, 20 (kg)
            $table->decimal('price', 12, 2);
            
            $table->string('status')->default('active'); // active, inactive, completed
            $table->timestamps();
            
            // Foreign keys
            $table->foreign('user_id')->references('id')->on('users')->onDelete('cascade');
            $table->foreign('origin_location_id')->references('id')->on('locations')->onDelete('cascade');
            $table->foreign('destination_location_id')->references('id')->on('locations')->onDelete('cascade');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('tebengan_titip_barang');
    }
};
