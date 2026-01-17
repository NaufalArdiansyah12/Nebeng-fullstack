<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up()
    {
        if (Schema::hasTable('car_rides')) {
            Schema::dropIfExists('car_rides');
        }
    }

    public function down()
    {
        if (!Schema::hasTable('car_rides')) {
            Schema::create('car_rides', function (Blueprint $table) {
                $table->bigIncrements('id');
                $table->unsignedBigInteger('ride_id');
                $table->integer('available_seats')->default(1);
                $table->json('extra')->nullable();
                $table->timestamps();
            });
        }
    }
};
