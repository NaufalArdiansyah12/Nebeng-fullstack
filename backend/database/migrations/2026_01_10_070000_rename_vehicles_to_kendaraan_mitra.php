<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\Schema;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;

return new class extends Migration {
    public function up()
    {
        // If vehicles exists and kendaraan_mitra does not, try to rename
        if (Schema::hasTable('vehicles') && !Schema::hasTable('kendaraan_mitra')) {
            Schema::rename('vehicles', 'kendaraan_mitra');
            return;
        }

        // If both tables exist, migrate data from vehicles to kendaraan_mitra then drop vehicles
        if (Schema::hasTable('vehicles') && Schema::hasTable('kendaraan_mitra')) {
            // copy in chunks to avoid large memory usage
            DB::table('vehicles')->orderBy('id')->chunkById(100, function ($rows) {
                $insert = [];
                foreach ($rows as $r) {
                    $insert[] = [
                        'id' => $r->id,
                        'user_id' => $r->user_id,
                        'vehicle_type' => $r->vehicle_type,
                        'name' => $r->name,
                        'plate_number' => $r->plate_number,
                        'brand' => $r->brand,
                        'model' => $r->model,
                        'color' => $r->color,
                        'year' => $r->year,
                        'seats' => $r->seats,
                        'is_active' => $r->is_active,
                        'created_at' => $r->created_at,
                        'updated_at' => $r->updated_at,
                    ];
                }
                if (!empty($insert)) {
                    DB::table('kendaraan_mitra')->insert($insert);
                }
            });

            Schema::dropIfExists('vehicles');
        }
    }

    public function down()
    {
        if (Schema::hasTable('kendaraan_mitra') && !Schema::hasTable('vehicles')) {
            Schema::rename('kendaraan_mitra', 'vehicles');
            return;
        }

        if (Schema::hasTable('kendaraan_mitra') && Schema::hasTable('vehicles')) {
            // If both exist, copy back
            DB::table('kendaraan_mitra')->orderBy('id')->chunkById(100, function ($rows) {
                $insert = [];
                foreach ($rows as $r) {
                    $insert[] = [
                        'id' => $r->id,
                        'user_id' => $r->user_id,
                        'vehicle_type' => $r->vehicle_type,
                        'name' => $r->name,
                        'plate_number' => $r->plate_number,
                        'brand' => $r->brand,
                        'model' => $r->model,
                        'color' => $r->color,
                        'year' => $r->year,
                        'seats' => $r->seats,
                        'is_active' => $r->is_active,
                        'created_at' => $r->created_at,
                        'updated_at' => $r->updated_at,
                    ];
                }
                if (!empty($insert)) {
                    DB::table('vehicles')->insert($insert);
                }
            });

            Schema::dropIfExists('kendaraan_mitra');
        }
    }
};
