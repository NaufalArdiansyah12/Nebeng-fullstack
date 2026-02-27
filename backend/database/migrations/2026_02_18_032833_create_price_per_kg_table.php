<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Migration stub: price_per_kg feature removed and archived to backend/deprecated/removed_price_system/
     * This migration intentionally does nothing to avoid altering production schema unexpectedly.
     */
    public function up(): void
    {
        // no-op
    }

    /**
     * Reverse the migrations (no-op)
     */
    public function down(): void
    {
        // no-op
    }
};
