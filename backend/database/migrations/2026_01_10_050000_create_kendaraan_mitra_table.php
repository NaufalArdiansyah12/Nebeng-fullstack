<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up()
    {
        if (!Schema::hasTable('kendaraan_mitra')) {
            Schema::create('kendaraan_mitra', function (Blueprint $table) {
                $table->bigIncrements('id');
                $table->unsignedBigInteger('user_id')->nullable();
                $table->enum('vehicle_type', ['motor', 'mobil']);
                $table->string('name');
                $table->string('plate_number')->nullable();
                $table->string('brand')->nullable();
                $table->string('model')->nullable();
                $table->string('color')->nullable();
                $table->integer('year')->nullable();
                $table->integer('seats')->default(1);
                $table->boolean('is_active')->default(true);
                $table->timestamps();
            });
        }
    }

    public function down()
    {
        Schema::dropIfExists('kendaraan_mitra');
    }
};
