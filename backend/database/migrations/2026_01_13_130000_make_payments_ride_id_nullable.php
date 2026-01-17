<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('payments', function (Blueprint $table) {
            // Drop existing foreign key if exists
            try {
                $table->dropForeign(['ride_id']);
            } catch (\Exception $e) {
                // Ignore if FK doesn't exist
            }
            
            // Make ride_id nullable
            $table->unsignedBigInteger('ride_id')->nullable()->change();
        });
    }

    public function down(): void
    {
        Schema::table('payments', function (Blueprint $table) {
            $table->unsignedBigInteger('ride_id')->nullable(false)->change();
        });
    }
};
