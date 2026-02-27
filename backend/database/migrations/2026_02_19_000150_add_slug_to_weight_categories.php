<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('weight_categories', function (Blueprint $table) {
            $table->string('slug')->nullable()->after('name');
        });

        // Update existing records with slug values
        DB::table('weight_categories')->update([
            'slug' => DB::raw("LOWER(REPLACE(name, ' ', '-'))")
        ]);

        // Update specific slugs to match expected values
        DB::table('weight_categories')->where('name', 'Kecil')->update(['slug' => 'kecil']);
        DB::table('weight_categories')->where('name', 'Sedang')->update(['slug' => 'sedang']);
        DB::table('weight_categories')->where('name', 'Besar')->update(['slug' => 'besar']);

        // Make slug unique after populating values
        Schema::table('weight_categories', function (Blueprint $table) {
            $table->unique('slug');
        });
    }

    public function down(): void
    {
        Schema::table('weight_categories', function (Blueprint $table) {
            $table->dropColumn('slug');
        });
    }
};
