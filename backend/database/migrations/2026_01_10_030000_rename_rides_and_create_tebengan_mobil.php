<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up()
    {
        // Rename existing `rides` to `tebengan_motor` if present
        if (Schema::hasTable('rides') && !Schema::hasTable('tebengan_motor')) {
            Schema::rename('rides', 'tebengan_motor');
        }

        // Create `tebengan_mobil` with same structure as the original `rides` table
        if (!Schema::hasTable('tebengan_mobil')) {
            Schema::create('tebengan_mobil', function (Blueprint $table) {
                $table->bigIncrements('id');
                $table->unsignedBigInteger('user_id')->nullable();
                $table->unsignedBigInteger('origin_location_id')->nullable();
                $table->unsignedBigInteger('destination_location_id')->nullable();
                $table->date('departure_date')->nullable();
                $table->time('departure_time')->nullable();
                $table->string('ride_type')->nullable();
                $table->string('service_type')->nullable();
                $table->decimal('price', 12, 2)->default(0);
                $table->string('vehicle_name')->nullable();
                $table->string('vehicle_plate')->nullable();
                $table->string('vehicle_brand')->nullable();
                $table->string('vehicle_type')->nullable();
                $table->string('vehicle_color')->nullable();
                $table->integer('available_seats')->default(1);
                $table->string('status')->default('active');
                $table->timestamps();

                // optional: foreign keys are not added here to avoid migration ordering issues
            });
        }
    }

    public function down()
    {
        if (Schema::hasTable('tebengan_mobil')) {
            Schema::dropIfExists('tebengan_mobil');
        }

        if (Schema::hasTable('tebengan_motor') && !Schema::hasTable('rides')) {
            Schema::rename('tebengan_motor', 'rides');
        }
    }
};
