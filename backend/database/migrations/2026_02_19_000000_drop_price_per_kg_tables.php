<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // Drop history table first (FK -> price_per_kg)
        if (Schema::hasTable('price_per_kg_history')) {
            Schema::dropIfExists('price_per_kg_history');
        }

        if (Schema::hasTable('price_per_kg')) {
            Schema::dropIfExists('price_per_kg');
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        // Intentionally left blank. The original table definitions are archived
        // at backend/deprecated/removed_price_system/ if you need to recreate them.
    }
};
