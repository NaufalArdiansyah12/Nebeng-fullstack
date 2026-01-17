<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up()
    {
        if (!Schema::hasTable('tebengan_barang')) {
            Schema::create('tebengan_barang', function (Blueprint $table) {
                $table->bigIncrements('id');
                $table->unsignedBigInteger('user_id')->nullable();
                // allow linking to mitra vehicle record
                $table->unsignedBigInteger('kendaraan_mitra_id')->nullable();

                $table->unsignedBigInteger('origin_location_id')->nullable();
                $table->unsignedBigInteger('destination_location_id')->nullable();
                $table->date('departure_date')->nullable();
                $table->time('departure_time')->nullable();

                $table->string('ride_type')->nullable();
                $table->string('service_type')->nullable();

                $table->decimal('price', 12, 2)->default(0);

                // vehicle details (kept for consistency with other tables)
                $table->string('vehicle_name')->nullable();
                $table->string('vehicle_plate')->nullable();
                $table->string('vehicle_brand')->nullable();
                $table->string('vehicle_type')->nullable();
                $table->string('vehicle_color')->nullable();

                // for barang we set available seats to 0 by default
                $table->integer('available_seats')->default(0);

                // bagasi capacity in liters/units (nullable)
                $table->integer('bagasi_capacity')->nullable();

                // optional extra information
                $table->text('extra')->nullable();

                $table->string('status')->default('active');

                $table->timestamps();

                // foreign keys if the referenced tables exist
                if (Schema::hasTable('kendaraan_mitra')) {
                    $table->foreign('kendaraan_mitra_id')->references('id')->on('kendaraan_mitra')->onDelete('set null');
                }
                if (Schema::hasTable('locations')) {
                    $table->foreign('origin_location_id')->references('id')->on('locations')->onDelete('set null');
                    $table->foreign('destination_location_id')->references('id')->on('locations')->onDelete('set null');
                }
                if (Schema::hasTable('users')) {
                    $table->foreign('user_id')->references('id')->on('users')->onDelete('cascade');
                }
            });
        }
    }

    public function down()
    {
        if (Schema::hasTable('tebengan_barang')) {
            Schema::table('tebengan_barang', function (Blueprint $table) {
                // drop foreign keys if they exist
                if (Schema::hasColumn('tebengan_barang', 'kendaraan_mitra_id')) {
                    $sm = Schema::getConnection()->getDoctrineSchemaManager();
                    $sm->getDatabasePlatform()->registerDoctrineTypeMapping('enum', 'string');
                    // attempt to drop foreign key by conventional name
                    try {
                        $table->dropForeign(['kendaraan_mitra_id']);
                    } catch (\Exception $e) {
                        // ignore if constraint not present
                    }
                }
                try {
                    $table->dropForeign(['origin_location_id']);
                } catch (\Exception $e) {}
                try {
                    $table->dropForeign(['destination_location_id']);
                } catch (\Exception $e) {}
                try {
                    $table->dropForeign(['user_id']);
                } catch (\Exception $e) {}
            });

            Schema::dropIfExists('tebengan_barang');
        }
    }
};
